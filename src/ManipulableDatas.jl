mutable struct Filterings
    bhv_type
    data  #::Array{Flipping.PhotometryStructure}
    categorical::AbstractArray{CategoricalVariable}
    continouos::AbstractArray{ContinuousVariable}
    bhv_data
    sub_data
    widget
    Button
end

function filterdf(df::Array{PhotometryStructure}, categorical::Array{CategoricalVariable}, continouos::Array{ContinuousVariable},field)
    #filter for categorical and continouos variable options
    subdata = deepcopy(df)
    active_cat = categorical[find(isselected(categorical))]
    for c in active_cat # go through every active variable
        for i = 1:size(subdata,1)
            session = getfield(subdata[i], field)
            session = session[in.(session[c.name],(selecteditems(c),)),:]
            if size(session,1)==0
                deleteat!(subdata, i)
            else
                setfield!(subdata[i],field,session)
            end
        end
    end
    active_con = continouos[find(isselected(continouos))]
    for c in active_con
        for i = 1:size(subdata,1)
            session = getfield(subdata[i], field)
            session = session[session[c.name] .>= observe(c.start)[],:]
            session = session[session[c.name] .<= observe(c.stop)[],:]
            setfield!(subdata[i],field,session)
        end
    end
    return subdata
end

function Filtering(data::Array{Flipping.PhotometryStructure},bhv_type::Symbol)
    categorical, continouos, names = buildvars(data,bhv_type)
    Button = button("Filter")
    filter = observe(Button)
    subdata = map(t -> filterdf(data,categorical,continouos,bhv_type),filter)
    bhv_data = map(t->convertin_DB(subdata[],bhv_type),subdata)
    widget = hbox(layout(categorical),layout(continouos), Button)
    mt = Filterings(bhv_type,data,categorical,continouos,
    bhv_data,subdata,widget,Button)
end

##
mutable struct Mutable_bhvs
    categorical
    continouos
    bins
    bhv_data
    splitby_cat
    splitby_cont
    compute_error
    x_axis
    y_axis
    axis_type
    smoother
    plot_type
    plt
    Button
    widget
end

function Mutable_bhv(data)
    categorical_vars, continuous_vars = distinguish(data)
    names = vcat(categorical_vars, continuous_vars)
    categorical = checkboxes(categorical_vars,label = "Split By Categorical")
    continouos = checkboxes(continuous_vars,label = "Split By Continouos")
    bins = spinbox(value = 2,label ="Number of Bins")
    plt = Observable{Any}(plot(rand(10)))
    Button = button("Plot");
    plotter = observe(Button)
    splitby_cat = checkboxes(categorical_vars,label = "Split By Category")
    splitby_cont = checkboxes(continuous_vars,label = "Split By Bins")
    compute_error = dropdown(vcat(["none","bootstrap","all"],names),label = "Compute_error")
    x_axis = dropdown(names,label = "X axis")
    y_axis = dropdown(vcat(["density", "cumulative"],names),label = "Y axis")
    axis_type = dropdown(x_type_dict,label = "X variable Type")
    smoother = slider(1:100,label = "Smoother")
    plot_type = dropdown(collect(keys(plot_dict)),label = "Plot Type")

    widget = hbox(splitby_cat,vbox(splitby_cont,bins),vbox(hbox(x_axis,y_axis,Button),plt,smoother),vbox(plot_type,axis_type,compute_error))
    mt = Mutable_bhvs(categorical,
    continouos,
    bins,
    data,
    splitby_cat,
    splitby_cont,
    compute_error,
    x_axis,
    y_axis,
    axis_type,
    smoother,
    plot_type,
    plt,
    Button,
    widget)
    map!(t -> makeplot(mt), plt, plotter)
    mt
end

function Mutable_bhv(filt::Filterings)
    data = filt.bhv_data[]
    m = Mutable_bhv(data)
end


mutable struct Mutable_traces
    bhv_type
    data  #::Array{Flipping.PhotometryStructure}
    Button
    plotter
    plt
    subdata
    plotdata
    rate
    fibers #taken from the data
    tracetype #dictionary of options
    x_allignment #dictionary of function
    compute_error #dictionary of function
    norm_window
    plot_window
    smoother
    splitby_cat
    splitby_cont
    widget
end

function get_option_allignments(data::Flipping.PhotometryStructure,bhv_type::Symbol)
    provisory = getfield(data,bhv_type)
    Cols = names(provisory)
    Columns = string.(Cols);
    result = Columns[(contains.(Columns,"In").|contains.(Columns,"Out")).& .!contains.(Columns,"Poke")]
    lista = OrderedDict()
    for name in result
        lista[name] = Symbol(name)
    end
    return lista
end

function get_option_allignments(data::Array{Flipping.PhotometryStructure,1},bhv_type::Symbol)
    checkup = verify_names(data,bhv_type)
    if isempty(checkup)
        get_option_allignments(data[1],bhv_type)
    else
        error("inconsistent naming across tables")
    end
end


function filter_norm_window(df::PhotometryStructure,Norm_window::ContinuousVariable, rate)
    data  = df.streaks
    fps = observe(rate)[]
    start,stop = selecteditems(Norm_window)
    sel = Array{Bool}(0) #boolean array to filter streaks
    slen = []# Array of valid streaks to filter corrisponding pokes
    for i = 2:size(data,1)
        v = data[i,:In]/fps + start >= data[i-1,:Out]/fps
        push!(sel,v)
        if !v
        #= if there isn't enought time push the streak number
        to remove the pokes in that streak=#
            push!(slen,i)
        end
    end
    #=sel has one value less than streaks num,
    we assume first streak to have enough time before start=#
    unshift!(sel,true)
    df.streaks = df.streaks[sel,:]
    for i in slen
        pokes_rows = find(df.pokes[:Streak_n].==i)
        deleterows!(df.pokes,pokes_rows)
    end
end


function filter_norm_window(df::Array{PhotometryStructure},Norm_window::ContinuousVariable,rate)
    subdata = deepcopy(df)
    for i = 1:size(subdata,1)
        if isempty(subdata[i].streaks)
            continue
        else
            filter_norm_window(subdata[i], Norm_window, rate)
        end
    end
    return subdata
end

function extract_rawtraces(data::Observable, bhv_type::Symbol,shift::Widget)
    o_data = observe(data)[]
    o_shift = Symbol(observe(shift)[])
    extract_rawtraces(o_data, bhv_type,o_shift)
end

function extract_rawtraces(data::Array{PhotometryStructure}, bhv_type::Symbol,shift::Symbol)
    provisory = []
    for i = 1:size(data,1)
        if isempty(getfield(data[i],bhv_type))
            continue
        else
            ongoing = extract_rawtraces(data[i],bhv_type,shift)
            if isempty(provisory)
                provisory = ongoing
            else
                provisory = JuliaDB.merge(provisory,ongoing)
            end
        end
    end
    return provisory
end

function extract_rawtraces(data::PhotometryStructure, bhv_type::Symbol,shift::Symbol)
    bhv_data = getfield(data, bhv_type)
    ongoing = extract_rawtraces(bhv_data,data.traces,shift)
    return ongoing
end

function extract_rawtraces(bhv_data::AbstractDataFrame, traces_data::AbstractDataFrame,shift::Symbol)
    ongoing = JuliaDB.table(bhv_data)
    for name in names(traces_data)
        provisory = [ShiftedArray(traces_data[name], -i) for i in bhv_data[shift]]
        ongoing = setcol(ongoing, name, provisory)
    end
    return ongoing
end

function extract_rawtraces_table(bhv_data::AbstractDataFrame, traces_data::AbstractDataFrame,shift::Symbol)
    ongoing = JuliaDB.table(bhv_data)
    ns = names(traces_data)
    ts = [table((ShiftedArray(traces_data[name], -i) for name in ns)...; names = ns, copy=false) for i in bhv_data[shift]]
    @transform_vec ongoing {tracce = ts};
end


function Mutable_trace(data::Array{Flipping.PhotometryStructure},bhv_type::Symbol)
    categorical_vars, continuous_vars = distinguish(data,bhv_type)
    var_names  = vcat(categorical_vars,categorical_vars)
    Button = button("Plot")
    plotter = observe(Button)
    rate = spinbox(value = 50,label ="Frames per second")
    fibers = dropdown(names(data[1].traces),label = "Traces")
    tracetype = dropdown(tracetype_dict,label = "Trace Type")
    x_allignment_dict = get_option_allignments(data,bhv_type)
    x_allignment = dropdown(x_allignment_dict, label = "Allign on")
    compute_error = dropdown(vcat(["none","bootstrap","all"],var_names),label = "Compute_error")
    norm_window = ContinuousVariable(:NormalisationPeriod,-1.5,-0.5) #use function selecteditems to retrieve values
    plot_window = ContinuousVariable(:VisualisationPeriod,-2,2) #use function selecteditems to retrieve values
    smoother = slider(1:100,label = "Smoother")

    splitby_cat = checkboxes(categorical_vars,label = "Split By Category")
    splitby_cont = checkboxes(continuous_vars,label = "Split By Bins")
    plt = Observable{Any}(plot(rand(10)))

    settings = vbox(Button,compute_error,rate)
    visualization = vbox(hbox(norm_window.widget,plot_window.widget),plt,hbox(tracetype,fibers,x_allignment))
    selection = hbox(splitby_cat,splitby_cont)
    widget = hbox(settings,visualization,selection)

    subdata = map(t->filter_norm_window(data,norm_window,rate),plotter)
    plotdata = map((t, v)->extract_rawtraces(t,bhv_type,v), subdata, observe(x_allignment))
    # plotdata = @map extract_rawtraces(&subdata, bhv_type, &x_allignment)
    mtr = Mutable_traces(bhv_type,data,
    Button,plotter,plt,subdata,plotdata,rate,fibers,
    tracetype,x_allignment,compute_error,norm_window,
    plot_window,smoother,splitby_cat,splitby_cont,widget)
    map!(t -> makeplot(mtr), plt, plotter)
    mtr
end

function Mutable_trace(f::Filterings)
    data = f.sub_data[]
    bhv_type = f.bhv_type
    Mutable_trace(data,bhv_type)
end

mutable struct Mutable_Guis
    filter
    bhv
    traces
    widget
end

function Mutable_Gui()
    filepath = filepicker();
    filename = observe(filepath);
    initial = DataFrame(categorical = [true, false], continouos = [1,2],
    In = [1,2], Out = [1,2], Streak_n = [1,2])
    initialtrace = DataFrame(Sig = [1,2,3], Ref = [1,2,3])
    fillerPhoto=PhotometryStructure(initial,initial,initialtrace)
    filler = [fillerPhoto,fillerPhoto]

    data = Observable{Any}(Array{PhotometryStructure, 1}(0))
    data[] = filler
    map!(carica, data, filename)

    filter = Observable{Filterings}
    d = observe(data)
    map!(Filtering,filter,d[],:pokes)

    bhv = Observable{Mutable_bhvs}
    map!(Mutable_bhv,bhv,filter)

    traces = Observable{Mutable_trace}
    map!(Mutable_trace,traces,filter)

    w_dict = Observable{Any}(OrderedDict("File" => filepath,
    "Filter" => filter[].widget,
    "Behaviour" => bhv[].widget,
    "Traces" => trace[].widget))
    widget = map(tabulator,w_dict)

    MutableGuis(fileloader,
    filter,
    bhv,
    traces,
    widget)
end
