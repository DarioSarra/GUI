@with_kw mutable struct UI_bhvs
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
    PLT_button
    plt
    dir = joinpath(dirname(@__DIR__), "Plots")
    filtered_data
end

function makeplot(df::UI_bhvs)
    a = Analysis(df)
    process(a)
end

function UI_bhv(data::Observable, x...)#keywar arg ask pietro
    df = observe(data)[]
    UI_bhv(df,x...)
end

function UI_bhv(data::DataFrames.AbstractDataFrame)
    df = JuliaDB.table(data)
    UI_bhv(df)
end

function UI_bhv(data::Array{Flipping.PhotometryStructure,1},bhv_kind::Symbol)
    df = convertin_DB(data,bhv_kind)
    UI_bhv(df)
end

function UI_bhv(data::IndexedTables.NextTable)
    or_data = data
    PLT_button = button("Plot")
    plotter = observe(PLT_button);
    plt = Observable{Any}(plot(rand(10)))

    categorical_vars, continuous_vars = distinguish(or_data)
    cols =  vcat(categorical_vars, continuous_vars)
    select_cat, select_cont = buildvars(categorical_vars,continuous_vars,or_data)
    split_cat = checkboxes(categorical_vars)
    split_cont = checkboxes(continuous_vars)

    compute_error = dropdown(vcat(["none","bootstrap","all"],cols),label = "Compute_error")
    x_axis = dropdown(cols,label = "X axis")
    y_axis = dropdown(vcat(saved_plot_analysis,cols),label = "Y axis")

    filtered_data = map(t->filterdf(or_data,select_cat,select_cont),plotter)

    processed = UI_bhvs(or_data = or_data, select_cat = select_cat,select_cont = select_cont,
    split_cat = split_cat,split_cont = split_cont,compute_error = compute_error,x_axis = x_axis,
    y_axis = y_axis,PLT_button = PLT_button,plt = plt,filtered_data = filtered_data)
    map!(t->filterdf(processed),filtered_data,plotter)
    map!(t -> makeplot(processed), plt, plotter)

    processed
    return processed
end
