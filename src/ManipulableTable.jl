mutable struct ManipulableTable
    bhv_type::Symbol
    subdata::Array{Flipping.PhotometryStructure}
    categorical::AbstractArray{CategoricalVariable}
    continouos::AbstractArray{ContinuousVariable}
    x_axis
    y_axis
    plt
    Button
    widget
    #data::AbstractDataFrame
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
    active_con = continouos[find(isselected(categorical))]
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



makeplot(x, y, df, cat, cont) =
    makeplot(x, y, filter(df, cat, cont))

function makeplot(x, y, df)
    xcol, ycol = # extract columns columns(df[], (Symbol(x[]), Symbol(y[])))
    plot(xcol, ycol)
end

function ManipulableTable(data::Array{Flipping.PhotometryStructure},bhv_type::Symbol)
    categorical, continouos, names = buildvars(data,bhv_type)
    x_axis = dropdown(names,label = "X axis")
    y_axis = dropdown(names,label = "Y axis")
    plt = Observable{Any}(plot(rand(10)))
    Button = button("Plot");
    plotter = observe(Button)
    subdata = map(t -> filterdf(data,categorical,continouos,bhv_type),plotter)
    map!(t -> makeplot(observe(x_axis)[], observe(y_axis)[], t, bhv_type), plt, subdata)
    widget = hbox(layout(categorical),layout(continouos),vbox(hbox(x_axis,y_axis,Button),plt))
    ManipulableTable(bhv_type, subdata[], categorical, continouos,x_axis,y_axis,plt,Button,widget)
end
# autocomplete(["ire","oro"])
