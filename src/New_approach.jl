f = Filtering(data[],:streaks)
w = Window()
body!(w, f.widget)
b = Mutable_bhv(f.bhv_data[])
w = Window()
body!(w, b.widget)
bA = Analysis(b)
##
unique(f.sub_data[],:MouseID,:streaks)
##
df = Mutable_trace(f.sub_data[],:streaks)
w = Window()
body!(w, df.widget)

##
dfA = Analysis(df)
selection = tuplejoin([dfA.y],dfA.splitby)
dataset = select(dfA.data,selection)
interval = Int64(dfA.xfunc[1]*dfA.yfunc):Int64(dfA.xfunc[2]*dfA.yfunc)
x = dfA.x[1]*dfA.yfunc:dfA.x[2]*dfA.yfunc
##
t = @apply dataset begin
    @transform {Normalise = normalise(cols(dfA.y),interval,x)}
end
##
idx = 1
# for idx = 1:size(select(t,selection[1]),1)
dati = collect(select(t,dfA.y)[idx][interval])
indici = collect(interval)
trial = repmat([idx],size(indici,1))
ongoing = table(trial,dati,indici, names = [:trial,:dati,:indici])
split = select(t,dfA.splitby)[2]
split[1]
split = table(ndsparse(@NT(select(t,dfA.splitby)[2])))
split = setcol(split, :trial, [idx])
ongoing = JuliaDB.join(split,ongoing,lkey=:trial, rkey=:trial)
if isempty(provisory)
    provisory = ongoing
else
    provisory = JuliaDB.merge(provisory,ongoing)
end
# end
provisory
##
that = @> provisory begin
    @across (_.MouseID)
    @splitby (_.AfterLast, _.Gen)
    @set_attr :label _[1] == 1.0 ? "Left" : "Right"
    @set_attr :color _[1] == 1.0 ?  :green : :red
    #@set_attr :linestyle _[1] ==1.0 ? :solid : :dash
    @x  _.AfterLast :discrete #Last_Reward
    @y :density
    #@plot groupedbar()
    @plot plot(

##
per =[4,5,NaN]
che = [6,7,8]
table(per, che, names=[:per, :che], chunks=2)
##
size(select(t,dfA.y),1)

##
provisory
##
plt = plot()
dfA.splitby
if dfA.splitby == ()
    avg = @with t reduce_vec(mean,cols(dfA.y),x,default = NaN)
    fiocco = @with t reduce_vec(std,cols(dfA.y),x,default = NaN)
    plot!(x,avg)
else
    prova = JuliaDB.groupby(@NT(avg= y->reduce_vec(mean,y,x,default = NaN),
    fiocco = y->reduce_vec(std,y,x,default = NaN)),
    t, dfA.splitby , select = dfA.y)
    plot!(x,select(prova,:avg))
end
##
dfA.splitby
##
provisory = Array{ShiftedArray}(0)
for idx = 1:size(select(dataset,:DRN_sig),1)
    ongoing = normalise(dataset[idx].DRN_sig,interval,x)
    push!(provisory,ongoing)
end
provisory = convert(Array{typeof(provisory[1])},provisory)
