using GUI
gr()
GUI.launch()

##
An_dict = ["Sliding_Norm", "Streak_Norm", "Regression"]
f = GUI.CategoricalVariable(:Analysis, ["Sliding_Norm", "Streak_Norm", "Regression"]);
f.widget
GUI.isselected(f)
GUI.selecteditems(f)
"Sliding_Norm" in GUI.selecteditems(f)
##
dati = carica("/Users/dariosarra/Google Drive/Flipping/Datasets/Photometry/AAV_Gcamp_DRN/Struct_AAV_Gcamp_DRN.jld2");
or_data = GUI.extract_rawtraces(dati, :pokes,50)
GUI.UI_trace(dati,:pokes)
##

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
