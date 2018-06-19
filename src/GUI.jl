using InteractBulma
using GroupedErrors
using Plots
using Blink
using Observables
using CSSUtil
using DataStructures
using WebIO
using Query
using Parameters
using Flipping
#using JuliaDBMeta

include("ColumnTypes.jl")
include("ManipulableTable.jl")
include("loader.jl")
include("plotter.jl")
include("evaluatecolumns.jl")
include("plotter.jl")
include(joinpath("layout","overall_layout.jl"))


##
##
typeof(data[])
unique(data[],:Gen,:pokes)
typeof(data[][1].pokes[1,:Day])
eltype(data[][1].streaks[:PokeSequence])
##
categorical_vars, continuos_vars = distinguish(data[],:streaks)
##
x = categorical_vars[4].widget
w = Window()
body!(w, x)
##
layout(categorical_vars)
##
selecteditems(continuos_vars[1])
isselected(continuos_vars[1])
predicate()
##
selecteditems(categorical_vars[1])
isselected(categorical_vars[1])
predicate(categorical_vars[1])
##
c = 1.45:7.78
a = 3.2
a in c
##
