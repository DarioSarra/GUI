using Widgets
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

include("Constants.jl");
include("ColumnTypes.jl");
include("Layout.jl");
include("Behaviour.jl");
include("EvaluateTableVars.jl");
include("ConversionDFtoJDB.jl");
include(joinpath("Process","Analyse.jl"));
include(joinpath("Process","groupederrors.jl"));
