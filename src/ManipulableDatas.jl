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

function Mutable_trace(data::Array{Flipping.PhotometryStructure},bhv_type::Symbol)
    categorical_vars, continuous_vars = distinguish(data,bhv_type)
    var_names  = vcat(categorical_vars,categorical_vars)
    Button = button("Plot")
    plotter = observe(Button)
    rate = spinbox(value = 50,label ="Frames per second")
    fibers = dropdown(names(data[1].traces),label = "Traces")
    trace_type = dropdown(tracetype_dict,label = "Trace Type")
    x_allignment_dict = get_option_allignments(data[],bhv_type)
    x_allignment = dropdown(x_allignment_dict, label = "Allign on")
    compute_error = dropdown(vcat(["none","bootstrap","all"],var_names),label = "Compute_error")
    norm_window = ContinuousVariable(:NormalisationPeriod,-1.5,-0.5) #use function selecteditems to retrieve values
    plot_window = ContinuousVariable(:VisualisationPeriod,-2,2) #use function selecteditems to retrieve values
    smoother = slider(1:100,label = "Smoother")

    splitby_cat = checkboxes(categorical_vars,label = "Split By Category")
    splitby_cont = checkboxes(continuous_vars,label = "Split By Bins")
    plt = Observable{Any}(plot(rand(10)))

    settings = vbox(Button,compute_error,rate)
    visualization = vbox(hbox(norm_window.widget,plot_window.widget),plt,hbox(trace_type,fibers,x_allignment))
    selection = hbox(splitby_cat,splitby_cont)
    widget = hbox(settings,visualization,selection)

    subdata = map(t->filter_norm_window(data,norm_window,rate),plotter)
    plotdata = map(t->extract_rawtraces(subdata,bhv_type,x_allignment),subdata)
    mtr = Mutable_traces(bhv_type,data,
    Button,plotter,plt,subdata,plotdata,rate,fibers,
    trace_type,x_allignment,compute_error,norm_window,
    plot_window,smoother,splitby_cat,splitby_cont,widget)
    #
    # map!(filter_norm_window(data,norm_window,rate),subdata)
    # map!(extract_rawtraces(observe(subdata)[],bhv_type),plotdata)
    map!(t -> makeplot(mtr), plt, plotter)
    mtr
end
