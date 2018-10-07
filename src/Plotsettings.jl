@with_kw mutable struct trace_plot_setting
    norm_type = radiobuttons(["Raw", "Sliding_Norm", "Streak_Norm", "Differential_Norm"]);
    reg_adjustment = checkbox("Regression");
    traccie = Observable{Any}([])
    over = dropdown(traccie,label = "over");
    widget = vbox(norm_type,hbox(vbox(vskip(1.5em),reg_adjustment),over))
end

function trace_plot_setting(tracelist::Array{String})
    trace_plot_setting(traccie = tracelist)
end

function trace_plot_setting(tracelist::DataStructures.OrderedDict{Any,Any})
    trace_plot_setting(traccie = collect(keys(tracelist)))
end


function selected_norm(settings::trace_plot_setting)
    observe(settings.norm_type)[]
end

function is_regression(settings::trace_plot_setting)
    observe(settings.reg_adjustment)[]
end
