
##
CNO = UI_bhv(data[]);
make_ui(CNO)
##
a_pokes = Analysis(pokes)
process(a_pokes)
##
pokes_t = UI_trace(data,:pokes);
w = Window()
body!(w, pokes_t.ui)
##
make_ui(pokes_t)
##
streaks_t = UI_trace(data,:streaks);
w = Window()
body!(w, streaks_t.ui)
##
make_ui(streaks_t)
##
