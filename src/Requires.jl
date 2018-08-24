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
using NaNMath
using Flipping

include("Constants.jl");
include("ColumnTypes.jl");
include("Trace.jl");
include("Behaviour.jl");
include("Layout.jl");
include("EvaluateTableVars.jl");
include("ConversionDFtoJDB.jl");
include(joinpath("Process","Adjust_traces.jl"));
include(joinpath("Process","Analyse.jl"));
include(joinpath("Process","groupederrors.jl"));
include(joinpath("Process","Prepare_plot.jl"))
