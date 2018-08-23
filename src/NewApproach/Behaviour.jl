mutable struct UI_bhvs
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
    filtered_data
    ui
end

function makeplot(df::UI_bhvs)
    a = Analysis(df)
    process(a)
end

function UI_bhv(data::Observable, x...)#keywar arg ask pietro
    df = observe(data)[]
    UI_bhv(df,x...)
end

function UI_bhv(data::AbstractDataFrame)
    df = JuliaDB.table(data)
    UI_bhv(df)
end

# function UI_bhv(data::Observable,bhv_kind::Symbol)
#
# end

function UI_bhv(data::PhotometryStructure,bhv_kind::Symbol)
    df = convertin(data,bhv_kind)
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
    split_cat = checkboxes(categorical_vars,label = "Split By Categorical")
    split_cont = checkboxes(continuous_vars,label = "Split By Continouos")

    bins = spinbox(value = 2,label ="Number of Bins")
    compute_error = dropdown(vcat(["none","bootstrap","all"],cols),label = "Compute_error")
    x_axis = dropdown(cols,label = "X axis")
    y_axis = dropdown(vcat(["density", "cumulative"],cols),label = "Y axis")
    axis_type = dropdown(x_type_dict,label = "X variable Type")
    smoother = slider(1:100,label = "Smoother")
    plot_type = dropdown(collect(keys(plot_dict)),label = "Plot Type")

    filter_widg = hbox(layout(select_cat),layout(select_cont))
    splitter_widg = hbox(split_cat,split_cont)
    plot_options = vbox(plot_type,y_axis,x_axis,axis_type,compute_error,bins)
    filtered_data = map(t->filterdf(or_data,select_cat,select_cont),plotter)
    ui = hbox(filter_widg,vbox(PLT_button,plt,smoother,splitter_widg),plot_options)
    processed = UI_bhvs(
    or_data,
    select_cat,
    select_cont,
    split_cat,
    split_cont,
    bins,
    compute_error,
    x_axis,
    y_axis,
    axis_type,
    smoother,
    plot_type,
    filtered_data,
    ui)
    map!(t -> makeplot(processed), plt, plotter)
    processed
    return processed
end
