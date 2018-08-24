mutable struct UI_traces
    fps
    bhv_type
    or_data
    select_cat
    select_cont
    split_cat
    split_cont
    bins
    compute_error
    x_axis
    y_axis
    axis_type
    smoother
    plot_type
    traces #taken from data
    tracetype #dictionary of options
    x_allignment #dictionary of function
    norm_window
    plot_window
    plot_bhv
    plot_trace
    plt
    filtered_data
    ui
end

function UI_trace(data::Observable,bhv_kind::Symbol)
    fps = spinbox(value = 50)
    bhv_type = bhv_kind
    or_data = extract_rawtraces(data, bhv_kind,fps)
    plot_bhv = button("Plot Behaviour")
    plotter_bhv = observe(plot_bhv);
    plot_trace = button("Plot Signal")
    plotter_trace = observe(plot_trace);
    plt = Observable{Any}(plot(rand(10)))

    #println("ok before variables options")
    categorical_vars, continuous_vars = distinguish(or_data)
    cols =  vcat(categorical_vars, continuous_vars)
    select_cat, select_cont = buildvars(categorical_vars,continuous_vars,or_data)
    split_cat = checkboxes(categorical_vars)#,label = "Split By Categorical",stack = false)
    adjust_layout!(split_cat)
    split_cont = checkboxes(continuous_vars)#,label = "Split By Continouos",stack = false)
    adjust_layout!(split_cont)

    #println("ok before plot options")
    bins = spinbox(value = 2)
    compute_error = dropdown(vcat(["none","bootstrap","all"],cols),label = "Compute_error")
    x_axis = dropdown(cols,label = "X axis")
    y_axis = dropdown(vcat(["density", "cumulative"],cols),label = "Y axis")
    axis_type = dropdown(x_type_dict,label = "X variable Type")
    smoother = slider(1:100,label = "Smoother")
    plot_type = dropdown(collect(keys(plot_dict)),label = "Plot Type")

    #println("ok before traces options")
    traces  = dropdown(available_traces(or_data),label = "Traces")
    tracetype = dropdown(tracetype_dict,label = "Trace Type")#dictionary of options
    x_allignment = dropdown(available_allingments(or_data), label = "Allign on")#dictionary of function
    norm_window = ContinuousVariable(:NormalisationPeriod,-1.5,-0.5) #use function selecteditems to retrieve values
    plot_window = ContinuousVariable(:VisualisationPeriod,-2,2) #use function selecteditems to retrieve values

    #println("ok before ui")
    filter_widg = hbox(layout(select_cat),layout(select_cont))
    splitter_widg = vbox("Categorical", split_cat, vskip(1em), "Continuous", split_cont)
    plot_options = vbox(plot_bhv,plot_type,y_axis,x_axis,axis_type,compute_error,"Number of Bins",bins)
    trace_options = hbox(tracetype,traces,x_allignment,vbox("Frame per Seconds",fps))
    windows_options = hbox(norm_window.widget,hskip(1em),plot_window.widget)
    #println("ok before filter")
    filtered_data = Observable{Any}(JuliaDB.table([1,2],[3,4],names = [:x,:y]))

    ui = hbox(filter_widg,vbox(hbox(plot_trace, hskip(1em),windows_options),plt,trace_options,smoother,splitter_widg),plot_options)

    processed = UI_traces(
    fps,bhv_type,or_data,select_cat,select_cont,split_cat,
    split_cont,bins,compute_error,x_axis,y_axis,axis_type,smoother,
    plot_type,traces,tracetype, x_allignment,norm_window,
    plot_window,plot_bhv,plot_trace,plt,filtered_data,ui)
    map!(t->filterdf(processed),filtered_data,plotter_trace)
    map!(t->filterdf(processed),filtered_data,plotter_bhv)
    map!(t -> makeplot_t(processed), plt, plotter_trace)
    map!(t -> makeplot_b(processed), plt, plotter_bhv)
    return processed
end

function available_traces(or_data::Observable)
    available_traces(or_data[])
end

function available_traces(or_data::IndexedTables.NextTable)
    name_list = String.(colnames(or_data))
    selection = name_list[contains.(name_list,"_sig") | contains.(name_list,"_ref") | contains.(name_list,"Pokes")]
    lista = OrderedDict()
    for name in selection
        lista[name] = Symbol(name)
    end
    return lista
end

function available_allingments(or_data::Observable)
    available_allingments(or_data[])
end

function available_allingments(or_data::IndexedTables.NextTable)
    Columns = String.(colnames(or_data))
    result = Columns[(contains.(Columns,"In").|contains.(Columns,"Out")).& .!contains.(Columns,"Poke")]
    lista = OrderedDict()
    for name in result
        lista[name] = Symbol(name)
    end
    return lista
end
