@with_kw mutable struct GUI_ui
    loading = loader()
    data = Observable{Any}(dom"div"())#loading.data#hbox(hskip(1em),vbox(vskip(1em),textbox("Waiting data")))
    ui = tabulator(OrderedDict("Load"=> loading.ui, "Plot" => data))
end

function process_table(l::loaders)
    fun = observe(l.experiment_type)[] #dictionary of functions
    kind = observe(l.behaviour_type)[] #dictionary of symbols
    if l.data[] isa AbstractArray{<:Flipping.PhotometryStructure}
        ongoingdata = fun(l.data[],kind)
    else
        ongoingdata = fun(l.data[])
    end
    make_ui(ongoingdata)
end

function launch()
    G = GUI_ui();
    map!(t->process_table(G.loading),G.data,G.loading.data)
    w = Window()
    body!(w, G.ui)
    return G
end
