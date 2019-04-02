# filepath = filepicker();
# filename = observe(filepath);
# dir = dirname(observe(filepath)[])
# data = Observable{Any}(IndexedTables.IndexedTable)
# experiment_type = dropdown(experiment_type_dict, label)
# map!(carica, data, filename)
# filestuff = hbox(filepath)
# w = Window()
# body!(w, filestuff)

const experiment_type_dict = OrderedDict(
    "stimulation" => UI_bhv,
    "photometry" => UI_trace)

const behaviour_type_dict = OrderedDict(
    "Pokes" => :pokes,
    "Streaks" => :streaks)

@with_kw mutable struct loaders
    filepath = filepicker();
    experiment_type = dropdown(experiment_type_dict, label = "Experiment type")
    behaviour_type = dropdown(behaviour_type_dict, label = "Behaviour type")
    data = Observable{Any}(table(["a","b","c","d"],[1,2,3,4], names = names = [:x,:y]))
    ui = hbox(hskip(1em),vbox(vskip(1em),experiment_type,vskip(1em),behaviour_type,vskip(1em),filepath))
end


function loader()
    l = loaders()
    filename = observe(l.filepath)
    map!(carica, l.data, filename)
    filestuff = hbox(l.filepath)
    return l
end
