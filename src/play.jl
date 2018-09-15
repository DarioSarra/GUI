using GUI
GUI.launch()
gr()
##
dati = carica("/Users/dariosarra/Google Drive/Flipping/Datasets/Photometry/AAV_Gcamp_DRN/Struct_AAV_Gcamp_DRN.jld2");
or_data = GUI.extract_rawtraces(dati, :pokes,50)
GUI.UI_trace(dati,:pokes)
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
