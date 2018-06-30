function adjust_tabulator_dict(behaviour_widget, traces_widget)
    OrderedDict("Behavior" => behaviour_widget, "Traces" => traces_widget)
end

pokes = Observable{Any}(ManipulableTable(data[],:pokes))
map!(ManipulableTable,pokes,data,:pokes)
pokes_traces = Observable(ManipulableTrace(pokes[]))
map!(ManipulableTrace,pokes_traces,pokes)
streaks = Observable{Any}(ManipulableTable(data[],:streaks))
map!(ManipulableTable,streaks,data,:streaks)
streaks_traces = Observable(ManipulableTrace(streaks[]))
map!(ManipulableTrace,streaks_traces,streaks)

pokeswidget = dom"div"(map(t->t.widget, pokes))
pokestraceswidget = dom"div"(map(t->t.widget, pokes_traces))
streakswidget = dom"div"(map(t->t.widget, streaks))
streakstraceswidget = dom"div"(map(t->t.widget, streaks_traces))


Pokes_dict = map(t->adjust_tabulator_dict(pokeswidget,pokestraceswidget),pokes)
Streaks_dict = map(t->adjust_tabulator_dict(streakswidget,streakstraceswidget),pokes)

Pokes_dict
# P = Observable{Any}(OrderedDict("Behavior" => pokeswidget, "Traces" => pokestraceswidget))
# S = Observable{Any}(OrderedDict("Behavior" => streakswidget, "Traces" => streakstraceswidget))

PL = map(tabulator,Pokes_dict)
SL = map(tabulator,Streaks_dict)
filestuff = hbox(filepath)
#main = Observable{Any}(OrderedDict("Loading"=>filestuff, "Pokes"=> pokeswidget, "Streaks" => streakswidget))
main = Observable{Any}(OrderedDict("Loading"=>filestuff, "Pokes"=> PL, "Streaks" => SL))

# main = Observable{Any}(OrderedDict())
# main[] = map(merge,file_dict,observe(pokes_dict)[],observe(streaks_dict)[])
ui = tabulator(main[])
w = Window()
body!(w, ui)

##

# ui # user interface
# ui[:pokes]
#
# @map ui merge(:pokes.widget, :streaks.widget)
# @map!
# @layout! ui hbox(:pokes, :streaks)
#
# dataset = ..
# createui(s::DarioStruct, sym::Symbol) = createui(getfield(s, sym))
# function createui(m::ManipulableTable)
#     ..
#
#     btn = button("Plot!")
#     on(observe(btn)) do t
#
#     end
#     ui = hbox(toggleconte)
#     return ui
# end
#
# main = OrderedDict("Load" => , "Pokes" => map(createui, pokedata), "Streaks => ")
