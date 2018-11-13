using GUI
omg = GUI.launch();
##
gr(xflip=false,xtick = :out,legend=true,markerstrokecolor = :black,
color = :auto,background_color = RGBA(1,1,1,0),
ylim=:auto,xlim = :auto)

##
function carica2(filename)
    file = FileIO.load(filename)
    if isa(file, Dict)
        data = file[collect(keys(file))[1]]
    else
        data = FileIO.load(filename) |> DataFrame
    end
    return data
end
##
d = filepicker()
observe(d)[]
carica2(observe(d)[])
##
dati = carica("/Users/dariosarra/Google Drive/Flipping/Datasets/Photometry/AAV_Gcamp_DRN/Struct_AAV_Gcamp_DRN.jld2");
uip  = GUI.UI_trace(dati,:pokes);
String(observe(uip.traces)[])
selected_trace =observe(uip.traces)[]
observe(uip.trace_analysis.over)[]
sel_t = "sn_"*String(selected_trace)
GUI.selected_norm(uip) == "Raw"
GUI.is_regression(uip)

or_data = GUI.extract_rawtraces(dati, :pokes,50)

uip.trace_analysis.widget
GUI.selecteditems(uip.trace_analysis)
columns(uip.or_data,:In)
columns(uip.or_data,:Out)
##
norm_type = dropdown(["Sliding", "Streak"])
norm_w = InteractBase.rangepicker(-50.0:0.1:50.0)
notifications(["bella","per","te"])
###
@with_kw mutable struct UI_setting
    norm_type = radiobuttons(OrderedDict("Raw"=>1, "Sliding_Norm"=>2, "Streak_Norm"=>9001));
    reg_adjustment = checkbox("Regression");
    traccie = Observable{Any}([])
    x = dropdown(traccie,label = "X");
    y = dropdown(traccie, label = "Y");
    widget = vbox(norm_type,hbox(vbox(vskip(1.5em),reg_adjustment),x,y))
end

function UI_setting(tracelist::Array{String})
    UI_setting(traccie = tracelist)
end
##
p = radiobuttons(["d","e","f"])
observe(p)[]
p = UI_setting(["Drn"])
p.widget
observe(p.reg_adjustment)[]
##
r = OrderedDict("HG"=>"G","HF"=>"F")
typeof(collect(keys(r)))
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
