using GUI
GUI.launch()
##
c = GUI_ui();
c.data[] = process_table(c.loading)
c.ui
##
t = table(["a","b","c","d"],[1,2,3,4], names = [:x,:y])
##
DrnNac = UI_bhv(data[]);
make_ui(DrnNac)
##
a_pokes = Analysis(pokes)
process(a_pokes)
##
pokes_t = UI_trace(data,:pokes);
make_ui(pokes_t)
##
streaks_t = UI_trace(data,:streaks);
make_ui(streaks_t)
##
