mutable struct ManipulableTable
    bhv_type::Symbol
    subdata#::Array{Flipping.PhotometryStructure}
    categorical::AbstractArray{CategoricalVariable}
    continouos::AbstractArray{ContinuousVariable}
    plotdata
    splitby
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

function ManipulableTable(data::Array{Flipping.PhotometryStructure},bhv_type::Symbol)
    categorical, continouos, names = buildvars(data,bhv_type)
    plt = Observable{Any}(plot(rand(10)))
    Button = button("Plot")
    plotter = observe(Button)
    subdata = map(t -> filterdf(data,categorical,continouos,bhv_type),plotter)
    #subdata = Observable{Any}(deepcopy(data))
    #subdata = Observable{Any}(Array{Flipping.PhotometryStructure})
    #map!(t -> filterdf(data,categorical,continouos,bhv_type),subdata,plotter)
    plotdata = map(t->convertin_DB(subdata[],bhv_type),subdata)
    splitby = checkboxes(names,label = "Split By")
    compute_error = dropdown(vcat(["none","bootstrap","all"],names),label = "Compute_error")
    x_axis = dropdown(names,label = "X axis")
    y_axis = dropdown(vcat(["density", "cumulative"],names),label = "Y axis")
    axis_type = dropdown(x_type_dict,label = "X variable Type")
    smoother = slider(1:100,label = "Smoother")
    plot_type = dropdown(collect(keys(plot_dict)),label = "Plot Type")
    widget = hbox(layout(categorical),layout(continouos),vbox(hbox(x_axis,y_axis,Button),plt,smoother),vbox(plot_type,axis_type,compute_error,splitby))
    mt = ManipulableTable(bhv_type, subdata[], categorical, continouos,
    plotdata,splitby,compute_error,x_axis,y_axis,axis_type,smoother,plot_type,
    plt,Button,widget)
    map!(t -> makeplot(mt), plt, subdata)
    mt
end
