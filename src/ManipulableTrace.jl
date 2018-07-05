mutable struct ManipulableTrace
    bhv_type
    data  #::Array{Flipping.PhotometryStructure}
    subdata
    rate
    fibers #taken from the data
    tracetype #dictionary of options
    x_allignment #dictionary of function
    splitby #dictionary of function
    compute_error #dictionary of function
    norm_window
    plot_window
    #plotdata #convertin_ShiftedArray
    plt
    Button
    widget
end

function ManipulableTrace(df::ManipulableTable)
    bhv_type = df.bhv_type
    Button = button("Plot");
    plotter = observe(Button)
    data = map(t -> filterdf(df.subdata,df.categorical,df.continouos,df.bhv_type),plotter)
    rate = spinbox(value = 50,label ="Frames per second")
    fibers = dropdown(names(df.subdata[1].traces),label = "Traces")
    trace_type = dropdown(tracetype_dict,label = "Trace Type")
    x_allignment_dict = get_option_allignments(data[],df.bhv_type)
    x_allignment = dropdown(x_allignment_dict, label = "Allign on")
    cat, con = distinguish(data[],bhv_type)
    cat_dict = OrderedDict()
    for i in cat
        cat_dict[String(i)] = i
    end
    categorical, continouos = distinguish(data[],bhv_type)
    splitby = checkboxes(cat_dict,label="Split by categorical")
    compute_error = df.compute_error
    norm_window = ContinuousVariable(:NormalisationPeriod,-1.5,-0.5) #use function selecteditems to retrieve values
    plot_window = ContinuousVariable(:VisualisationPeriod,-2,2) #use function selecteditems to retrieve values
    plt = Observable{Any}(plot(rand(10)))
    subdata = map(t->filter_norm_window(data[],norm_window,rate,bhv_type),plotter)
    #plotdata
    widget = hbox(vbox(Button,compute_error,rate),splitby,
    vbox(hbox(norm_window.widget,plot_window.widget),
    plt,
    hbox(trace_type,fibers,x_allignment)))
    mtr = ManipulableTrace(
    bhv_type,
    data,
    subdata,
    rate,
    fibers,
    trace_type,
    x_allignment,
    splitby,
    compute_error,
    norm_window,
    plot_window,
    #plotdata,
    plt,
    Button,
    widget)
    #map!(t -> makeplot(mtr), plt, subdata)
    mtr
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

function process_traces(df::ManipulableTrace)
    bhv_type = df.bhv_type
    data = df.subdata
    trace_type = observe(df.trace_type)[]
    trace = observe(df.fibers)[]
    VisW = selecteditems(df.plot_window)
    rate = observe(df.rate)[]
    splitby = Symbol.(observe(df.splitby)[])
    # create new splitting system
    #once identified cat and con for con apply custom bin function
    for d in data
        ongoing = extract_traces(d,bhv_type,trace,VisW,rate)

    end

    result = DataFrame()
    for i = 1:size(sa,1)
        if tracetype == "Raw"
            return traces[Symbol(fiber)]
        elseif tracetype == "Normalised"
            for i = 1 size(bhv)
                start = bhv[i,:In] + NormW[1]
                stop = bhv[i,:In] + NormW[2]
                corr_range = start:stop
                v = mean(traces[corr_range,Symbol(fiber)])
                provisory = DataFrame(Trace = traces[bhv[i,:In]:bhv[i,:Out],Symbol(fiber)]./v)
                if isempty(result)
                    result = provisory
                else
                    append!(result,provisory)
                end
            end
            result
        end
    end
end


function convert_traces(df::DataFrame,splitby,sa::Array{ShiftedArray},VisW)
    coll_range = VisW[1]:VisW[2]
    provisory = DataFrame()
    if size(df,1) != size(sa,1)
        error("non matching data between bhv and collected shifted array")
    end
    for i = 1:size(df,1)
        trial = sar[i][coll_range]
        ongoing = DataFrame(trace = trial,time = 1:size(trial,1))
        for col in splitby#splitby needs to be a tuple of symbols
            ongoing[col] = df[i,col]
        end
        if isempty(provisory)
            provisory = ongoning
        else
            append!(provisory,ongoing)
        end
    end
    #converted = JuliaDB.table(provisory)
    return provisory
end

function extract_traces(data::AbstractDataFrame, trace::Symbol, allignment,VisW,rate)
    start,stop = selecteditems(VisW)
    pace = observe(df.rate)[]
    start = allignment+(start*pace)
    stop = allignment+(stop*pace)
    collecting = start:stop
    Shiftedtrial = ShiftedArray(data[trace], - allignment, default = NaN)
end

function extract_traces(data::Flipping.PhotometryStructure,bhv_type::Symbol, trace::Symbol,VisW::ContinuousVariable,rate)
    bhv = getfield(data,bhv_type)
    provisory = Array{ShiftedArray}(0)
    for i = 1:size(bhv,1)
        allignment = bhv[i,:In]
        ongoing = extract_traces(data.traces,trace,allignment,VisW,rate)
        push!(provisory,ongoing)
    end
    provisory = convert(Array{typeof(provisory[1])},provisory)
end


function filter_norm_window(df,Norm_window::ContinuousVariable, rate,bhv_type)
    start,stop = selecteditems(Norm_window)
    pace = observe(rate)[]
    start = Int64(start*pace)
    stop = Int64(stop*pace)
    corr_range = start:stop
    norm = Array{ShiftedArray}(0)
    for idx =1:size(df.bhv_type,1)
        f0 = mean(df[idx][start:stop])
        ar = df[idx].parent
        ar = (ar-f0)/f0
        sh = df[idx].shifts[1]
        x = ShiftedArray(ar, sh, default = NaN)
        typeof(x)
        push!(norm,x)
    end
    return norm
end


function filter_norm_window(df::Array{PhotometryStructure},Norm_window::ContinuousVariable,rate)
    subdata = deepcopy(df)
    for i = 1:size(subdata,1)
        if isempty(subdata[i].streaks)
            println("empty")
            continue
        else
            filter_norm_window(subdata[i], Norm_window, rate)
        end
    end
    return subdata
end
