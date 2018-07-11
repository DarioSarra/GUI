using InteractBulma
using GroupedErrors
using StatPlots
using Plots
import GR
using Blink
using Observables
using CSSUtil
using DataStructures
using WebIO
using Query
using Parameters
using Flipping


include("ColumnTypes.jl")
include("ManipulableTable.jl")
include("ManipulableTrace.jl")
include("process.jl")
include("dropdownoptions.jl")
include("loader.jl")
include("plotter.jl")
include("evaluatecolumns.jl")
include(joinpath("process","groupederrors.jl"))
include(joinpath("layout","overall_layout.jl"))


##

df = pokes_traces[];
df.data[]
## filtering Norm wind cancels all data
len_s = []
len_p = []
for sess = 1:118
    p = size(df.data[][sess].pokes,1) > size(df.subdata[][sess].pokes,1)
    s = size(df.data[][sess].streaks,1)>size(df.subdata[][sess].streaks,1)
    push!(len_p,p)
    push!(len_s,s)
    for trial = 1:size(df.data[][sess].streaks,1)-1
        d = df.data[][sess].streaks
        if df.data[][sess].streaks[trial,:Travel_duration]<1
            #diff = d[trial+1,:In] -1.5 > d[trial,:Out]
            println(sess, " ",trial," ",diff)
        end
    end
end
names(df.data[][sess].streaks)
##
find(len_s)
find(len_p)
plot(df.subdata[][1].streaks[:Travel_duration])
df.norm_window
rate = observe(df.rate)[]
e = extract_traces(df.subdata[][1],:pokes,:DRN_sig,df.plot_window,df.rate)
size(e,1)
mean(e[1][-100:100])
start,stop = selecteditems(df.plot_window)
rate = observe(df.rate)[]
inds = start*rate:stop*rate
typeof(e)
c = reduce_vec(mean,e,inds,default = NaN)
typeof(f)
f = normalise_DeltaF0(e,df.norm_window, df.rate)
plot(inds,c)
f_mean = reduce_vec(mean,f,inds,default = NaN)
plot(inds,f_mean)
n = Normalise_GLM(df.data[][1],:pokes, :DRN_sig,df.plot_window,df.norm_window,df.rate)
n_mean = reduce_vec(mean,n,inds,default = NaN)
plot(inds,f_mean)
##
start,stop = selecteditems(df.plot_window)
typeof(start)
data[][1].pokes
pokes[].subdata[1].pokes
prova = convertin_DB(data[],:pokes)
size(pokes[].subdata[1].pokes)
prova = DataFrame(a=[1,2],b=[3,4]);
setfield!(pokes[].subdata[1],:streaks,prova)
filterdf(data[],pokes[].categorical,pokes[].continouos,:pokes)

pokes[].subdata
##
traces = Symbol(observe(pokes_traces[].fibers)[])
pokes_traces[].bhv_type
VisW = selecteditems(pokes_traces[].plot_window)
rate = observe(pokes_traces[].rate)[]
pokes_traces[].data[][1]
extract_traces(pokes[].subdata[1],pokes_traces[].bhv_type,traces,VisW,rate)

size(data[][1].streaks)
size(streaks[].subdata[1].streaks)
d = filterdf(data[],streaks[].categorical,streaks[].continouos,:streaks)
size(d[1].streaks)
