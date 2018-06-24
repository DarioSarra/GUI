mutable struct ManipulableTable
    bhv_type::Symbol
    subdata::Array{Flipping.PhotometryStructure}
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
    Button = button("Plot");
    plotter = observe(Button)
    subdata = map(t -> filterdf(data,categorical,continouos,bhv_type),plotter)
    plotdata = map(t->Flipping.convertin_DB(subdata[],bhv_type),subdata)
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


function filterdf(df::Array{PhotometryStructure}, categorical::Array{CategoricalVariable}, continouos::Array{ContinuousVariable},field)
    subdata = deepcopy(df)
    active_cat = categorical[find(isselected(categorical))]
    for c in active_cat
        for i = 1:size(subdata,1)
            session = getfield(subdata[i], field)
            session = session[in.(session[c.name],(selecteditems(c),)),:]
            setfield!(subdata[i],field,session)
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
