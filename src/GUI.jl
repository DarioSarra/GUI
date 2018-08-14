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
include("ManipulableDatas.jl")
include("Analysis_func.jl")
include("process.jl")
include("dropdownoptions.jl")
include("loader.jl")
include("plotter.jl")
include("evaluatecolumns.jl")
include(joinpath("process","groupederrors.jl"))
include(joinpath("layout","overall_layout.jl"))
