pokes = Observable{Any}(ManipulableTable(data[],:pokes))
map!(ManipulableTable,pokes,data,:pokes)
streaks = Observable{Any}(ManipulableTable(data[],:streaks))
map!(ManipulableTable,streaks,data,:streaks)

pokeswidget = dom"div"(map(t->t.widget, pokes))
streakswidget = dom"div"(map(t->t.widget, streaks))
P = Observable{Any}(OrderedDict("Behavior" => pokeswidget, "Traces" => button("bho")))
S = Observable{Any}(OrderedDict("Behavior" => streakswidget, "Traces" => button("bho")))
PL = map(tabulator,P)
SL = map(tabulator,S)
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
