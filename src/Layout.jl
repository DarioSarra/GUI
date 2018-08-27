function adjust_layout!(w)
    v = props(InteractBase.scope(w).dom)[:attributes]
    println(typeof(v))
    props(InteractBase.scope(w).dom)[:attributes] =
        merge(Dict(v),
        Dict("style" => "flex: 0 1 auto; display:flex; margin: 0; flex-wrap: wrap;"))
    w
end

function make_ui(df::UI_bhvs)
    Save_button = button("Save")
    saver = observe(Save_button)
    pltname = textbox(hint = "remember to put the file extension")

    path = map(t->joinpath(df.dir,t),observe(pltname))
    on(t->println(path[]),saver)
    on(t->savefig(df.plt[],path[]),saver)

    filter_widg = hbox(layout(df.select_cat),layout(df.select_cont))
    splitter_widg = vbox("Split by category",adjust_layout!(df.split_cat),vskip(1em),
    "Split by continuous",adjust_layout!(df.split_cont))
    actions = hbox(df.PLT_button,hskip(1em),Save_button,pltname)
    plot_options = vbox(df.plot_type,df.y_axis,df.x_axis,df.axis_type,df.compute_error,"Number of Bins",df.bins)
    ui = hbox(filter_widg,vbox(actions,df.plt,df.smoother,splitter_widg),plot_options)
    w = Window()
    body!(w, ui)
end

function make_ui(df::UI_traces)
    Save_button = button("Save")
    saver = observe(Save_button)
    pltname = textbox(hint = "remember to put the file extension")

    path = map(t->joinpath(df.dir,t),observe(pltname))
    on(t->println(path[]),saver)
    on(t->savefig(df.plt[],path[]),saver)

    filter_widg = hbox(layout(df.select_cat),layout(df.select_cont))
    splitter_widg = vbox("Split by category",adjust_layout!(df.split_cat),vskip(1em),
    "Split by continuous",adjust_layout!(df.split_cont))
    plot_options = vbox(df.plot_bhv,df.plot_type,df.y_axis,df.x_axis,
    df.axis_type,df.compute_error,"Number of Bins",df.bins)
    trace_options = hbox(df.tracetype,df.traces,df.x_allignment,vbox("Frame per Seconds",df.fps))
    actions = hbox(df.plot_trace,hskip(1em),Save_button,pltname)
    windows_options = hbox(df.norm_window.widget,hskip(1em),df.plot_window.widget)

    ui = hbox(filter_widg,vbox(df.plot_trace,windows_options,df.plt,trace_options,df.smoother,splitter_widg),plot_options)

    w = Window()
    body!(w, ui)
end
