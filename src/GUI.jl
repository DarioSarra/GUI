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
cat, con = distinguish(df.subdata[],:pokes)
Symbol.(observe(df.splitby)[])
selecteditems(df.plot_window)
observe(df.rate)[]
observe(df.splitby)[]
##
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
