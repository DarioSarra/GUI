@with_kw mutable struct UI_traces
    fps = spinbox(value = 50)
    bhv_type
    or_data
    select_cat
    select_cont
    split_cat
    split_cont
    bins = spinbox(value = 2)
    compute_error
    x_axis
    y_axis
    axis_type = dropdown(x_type_dict,label = "X variable Type")
    smoother = slider(1:100,label = "Smoother")
    plot_type = dropdown(collect(keys(plot_dict)),label = "Plot Type")
    traces #taken from data
    tracetype = dropdown(tracetype_dict,label = "Trace Type") #dictionary of options
    trace_analysis
    x_allignment #taken from data
    sliding_window = ContinuousVariable(:SlidingNormalisationPeriod,-5.5,-0.5) #use function selecteditems to retrieve values
    norm_window = ContinuousVariable(:StreakNormalisationPeriod,-1.5,-0.5) #use function selecteditems to retrieve values
    plot_window = ContinuousVariable(:VisualisationPeriod,-2,2) #use function selecteditems to retrieve values
    plot_bhv
    plot_trace
    plt
    dir = joinpath(dirname(@__DIR__), "Plots")
    filtered_data
end

function UI_trace(data::Observable,bhv_kind::Symbol,fps = 50)
    ob_data = observe(data)[]
    UI_trace(ob_data,bhv_kind,fps)
end

function UI_trace(data::Array{Flipping.PhotometryStructure,1},bhv_kind::Symbol, fps = 50)
    bhv_type = bhv_kind
    or_data = extract_rawtraces(data, bhv_kind,fps)
    plot_bhv = button("Plot Behaviour")
    plotter_bhv = observe(plot_bhv);
    plot_trace = button("Plot Signal")
    plotter_trace = observe(plot_trace);
    plt = Observable{Any}(plot(rand(10)))
    categorical_vars, continuous_vars = distinguish(or_data)
    cols =  vcat(categorical_vars, continuous_vars)
    select_cat, select_cont = buildvars(categorical_vars,continuous_vars,or_data)
    split_cat = checkboxes(categorical_vars)#,label = "Split By Categorical",stack = false)
    adjust_layout!(split_cat)
    split_cont = checkboxes(continuous_vars)#,label = "Split By Continouos",stack = false)
    adjust_layout!(split_cont)
    #println("ok before plot options")
    compute_error = dropdown(vcat(["none","bootstrap","all"],cols),label = "Compute_error")
    x_axis = dropdown(cols,label = "X axis")
    y_axis = dropdown(vcat(["density", "cumulative"],cols),label = "Y axis")

    #println("ok before traces options")
    traces  = dropdown(available_traces(or_data),label = "Traces")
    trace_analysis = trace_plot_setting(available_traces(or_data))
    x_allignment = dropdown(available_allingments(or_data), label = "Allign on")#dictionary of function
    filtered_data = Observable{Any}(JuliaDB.table([1,2],[3,4],names = [:x,:y]))

    # ui = hbox(filter_widg,vbox(hbox(plot_trace, hskip(1em),windows_options),plt,trace_options,smoother,splitter_widg),plot_options)

    processed = UI_traces(bhv_type = bhv_type,or_data = or_data,
    select_cat = select_cat,select_cont = select_cont,
    split_cat = split_cat,split_cont = split_cont,compute_error = compute_error,
    x_axis = x_axis,y_axis = y_axis,traces = traces, trace_analysis = trace_analysis,
    x_allignment = x_allignment,plot_trace = plot_trace,plot_bhv = plot_bhv,
    plt = plt,filtered_data = filtered_data)

    map!((s, t)->filterdf(processed), filtered_data, plotter_trace, plotter_bhv)
    # map!(t->filterdf(processed),filtered_data,plotter_bhv)
    map!(t -> makeplot_t(processed), plt, plotter_trace)
    map!(t -> makeplot_b(processed), plt, plotter_bhv)
    return processed
end

function available_traces(or_data::Observable)
    available_traces(or_data[])
end

function available_traces(or_data::IndexedTables.IndexedTable)
    name_list = String.(colnames(or_data))
    # selection = name_list[occursin.(name_list,"_sig") .| occursin.(name_list,"_ref") .| occursin.(name_list,"Pokes")]
    name_list =collect(name_list)
    selection = name_list[occursin.("_sig",name_list) .| occursin.("_ref",name_list) .| occursin.("Pokes",name_list)]
    lista = OrderedDict()
    for name in selection
        lista[name] = Symbol(name)
    end
    return lista
end

function available_allingments(or_data::Observable)
    available_allingments(or_data[])
end

function available_allingments(or_data::IndexedTables.IndexedTable)
    Columns = String.(colnames(or_data))
    # result = Columns[(occursin.(Columns,"In").|occursin.(Columns,"Out")).& .!occursin.(Columns,"Poke")]
    Columns = collect(Columns)
    result = Columns[(occursin.("In",Columns).|occursin.("Out",Columns)).& .!occursin.("Poke",Columns)]
    lista = OrderedDict()
    for name in result
        lista[name] = Symbol(name)
    end
    return lista
end

function selected_norm(UI_t::UI_traces)
    observe(UI_t.trace_analysis.norm_type)[]
end

function is_regression(UI_t::UI_traces)
    observe(UI_t.trace_analysis.reg_adjustment)[]
end

function which_regressor(UI_t::UI_traces)
    observe(UI_t.trace_analysis.over)[]
end
