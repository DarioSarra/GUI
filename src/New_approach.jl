f = Filtering(data[],:pokes)
w = Window()
body!(w, f.widget)
unique(select(f.bhv_data[],:Gen))
##
b = Mutable_bhv(f)
w = Window()
body!(w, b.widget)
bA = Analysis(b)
unique(select(bA.data,:Gen))
##
unique(select(bA.data,:Gen))
##
that = @> bA.data begin
    @across (_.MouseID)
    @splitby (_.Gen)
    @x  _.PokeDur :discrete #Last_Reward
    @y :density
    #@plot groupedbar()
    @plot plot() :ribbon
end
##
df = Mutable_trace(f)
w = Window()
body!(w, df.widget)
##
bhv_data = data[][1].pokes
traces_data = data[][1].traces
ongoing = JuliaDB.table(bhv_data)
ns = names(traces_data)
shifting = :In
ts = [table((ShiftedArray(traces_data[name], -i) for name in ns)...; names = ns, copy=false) for i in bhv_data[shifting]]
ongoing

s = @transform_vec ongoing {tracce = ts};
function appiattiscilo(s, r = -10:10)
    @transform {tracce = Missings.skipmissing(view(:tracce, r))}
end
ttt = appiattiscilo(s);
##
tic()
dfA = Analysis(df)
toc()
process(dfA)
typeof(select(dfA.data,:dati))
unique(select(dfA.data,:Gen))
##

bA = Analysis(b)
process(bA)
typeof(bA.data)

##
tic()
split = Tuple(Symbol.(vcat(observe(df.splitby_cont)[],observe(df.splitby_cat)[]))) #tupla of symbols
calc_er =   observe(df.compute_error)[]
error = calc_er == "bootstrap" || calc_er == "all" || calc_er == "none"? () : [Symbol.(observe(df.compute_error)[])]
info_cols = tuplejoin([:trial],split,error)
norm_1 = selecteditems(df.norm_window)[1] #starting index for normalization
norm_2 = selecteditems(df.norm_window)[2] #ending index for normalization
rate = observe(df.rate)[] #frame per second
norm_int = Int64(norm_1*rate):Int64(norm_2*rate) #normalization range
x_1 = selecteditems(df.plot_window)[1] #starting index for visualization
x_2 = selecteditems(df.plot_window)[2] #ending index for visualization
x_interval  = Int64(x_1*rate):Int64(x_2*rate) #visualization range
x = :time
y = Symbol(observe(df.fibers)[])
tracetype = observe(df.tracetype)[]


if tracetype == "Raw"
    y = Symbol(observe(df.fibers)[])
    t = @apply df.plotdata[] begin
        @transform {view = collect_view(cols(y),x_interval)}
    end
elseif tracetype == "Normalised"
    y = Symbol(observe(df.fibers)[])
    # create normalised data
    t = @apply df.plotdata[] begin
        @transform {Normalise = normalise(cols(y),norm_int,x_interval)}
        @transform {view = collect_view(:Normalise,x_interval)}
    end
elseif tracetype == "GLM"
    try
        y_name = observe(df.fibers)[]
        yref = Symbol(replace(y_name,"sig","ref",1))
        t = @apply df.plotdata[] begin
            @transform {Normalise = normalise(cols(y),norm_int,x_interval)}
            @transform {view = collect_view(:Normalise,x_interval)}
            @transform {Normalise_ref = normalise(cols(yref),norm_int,x_interval)}
            @transform {view_ref = collect_view(:Normalise_ref,x_interval)}
        end
    catch
        println("can't find a reference for the selected trace ", y_name)
        y = Symbol(observe(df.fibers)[])
        # create normalised data
        t = @apply df.plotdata[] begin
            @transform {Normalise = normalise(cols(y),norm_int,x_interval)}
            @transform {view = collect_view(:Normalise,x_interval)}
        end
    end

end

# collect data in visualization interval
t = setcol(t,:trial,collect(1:length(t))) #add trial number to operate

info_vals = select(t, info_cols)
plot_data = []

for idx = 1:length(t)
    # create a Dataframe with each frame in a row
    ongoing = DataFrame(
    trial = copy(select(t,:trial)[idx]),
    frame = collect(x_interval),
    dati = copy(select(t,:view)[idx]))
    if isempty(plot_data)
        plot_data = ongoing
    else
        append!(plot_data,ongoing)
    end
end
plot_data = JuliaDB.table(plot_data)
plot_data = JuliaDB.join(plot_data, info_vals, lkey=:trial, rkey=:trial)
plot_data = @transform plot_data {time = :frame/rate}
toc()
##






##
for idx = 1:length(t)
    #split_vals = @where select(t,split) :trial ==idx
    dati = collect(select(t,y)[idx][x_interval])
    indici = collect(x_interval)
    trial = repmat([idx],size(indici,1))
    ongoing = table(trial,dati,indici, names = [:trial,:dati,:indici])
    #ongoing = JuliaDB.join(split_vals,ongoing,lkey=:trial, rkey=:trial)
    if isempty(plot_data)
        plot_data = ongoing
    else
        plot_data = JuliaDB.merge(plot_data,ongoing)
    end
end



##
tic()
dfA = Analysis(df)
toc()

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
