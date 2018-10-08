module GUI
using Reexport
@reexport using Flipping
@reexport using Widgets
@reexport using InteractBulma
@reexport using GroupedErrors
@reexport using StatPlots
@reexport using Plots
@reexport using Blink
@reexport using Observables
@reexport using CSSUtil
@reexport using DataStructures
@reexport using WebIO
@reexport using IndexedTables
@reexport using Parameters
import GR


include("Constants.jl");
include("ColumnTypes.jl");
include("Plotsettings.jl")
include("Trace.jl");
include("Behaviour.jl");
include("Loading.jl");
include("Layout.jl");
include("EvaluateTableVars.jl");
include("ConversionDFtoJDB.jl");
include(joinpath("Process","Adjust_traces.jl"));
include(joinpath("Process","Analyse.jl"));
include(joinpath("Process","groupederrors.jl"));
include(joinpath("Process","Prepare_plot.jl"))
include("Gui_struct.jl")

export launch

end
