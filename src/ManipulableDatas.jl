mutable struct Filterings
    bhv_type
    data  #::Array{Flipping.PhotometryStructure}
    categorical::AbstractArray{CategoricalVariable}
    continouos::AbstractArray{ContinuousVariable}
    bhv_data
    widget
    Button
end

function Filtering(data::Array{Flipping.PhotometryStructure},bhv_type::Symbol)
    Button = button("Filter");
    filter = observe(Button)
    categorical, continouos, names = buildvars(data,bhv_type)
    subdata = map(t -> filterdf(data,categorical,continouos,bhv_type),filter)
    bhv_data = map(t->convertin_DB(subdata[],bhv_type),subdata)
    widget = hbox(layout(categorical),layout(continouos), Button)
    mt = Filterings(bhv_type,data,categorical,continouos,bhv_data,widget,Button)
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
