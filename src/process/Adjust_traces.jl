"""
`collect_raw`

from an Array of ShiftedArrays collects values around an interval starting from the plot range start until
the frame value identified by the column :Out
"""

function collect_raw(t::IndexedTables.NextTable,selected_trace::Symbol,plot_range::Range)
    plot_data = JuliaDBMeta.@apply t begin
        JuliaDBMeta.@transform {ending = (:Out - :In)}
        JuliaDBMeta.@transform {new_range = (colon(plot_range.start,:ending+1))}
        JuliaDBMeta.@transform {new_array = (cols(selected_trace)[:new_range])}
        JuliaDBMeta.@transform {corr_trace = ShiftedArray(:new_array, plot_range.start, default = NaN)}
    end;
    return columns(plot_data,:corr_trace)
end

"""
`normalise_streak`

Method1: need to specify the symbol of the trace to normalise
Method2: expect to find a column called corr_trace to be analized
"""

function normalise_streak(t::IndexedTables.NextTable,bhv_type::Symbol,selected_trace::Symbol,norm_range::Range,plot_range::Range)
    if bhv_type == :pokes
        plot_data = @apply t begin
            @transform_vec (:Session, :Streak) flatten=true begin
                v = cols(selected_trace)
                m = NaNMath.mean(v[1][norm_range])
                {mean = fill(m, length(v))}
            end
            JuliaDBMeta.@transform {ending = (:Out - :In)}
            JuliaDBMeta.@transform {new_range = (colon(plot_range.start,:ending+1))}
            JuliaDBMeta.@transform {corr_trace = ShiftedArray((cols(selected_trace)[:new_range]-:mean) / :mean, plot_range.start, default = NaN)}
        end;
        return columns(plot_data,:corr_trace)
    elseif  bhv_type == :streaks
        plot_data = @apply t begin
            JuliaDBMeta.@transform {mean = NaNMath.mean(cols(selected_trace)[norm_range])}
            JuliaDBMeta.@transform {ending = (:Out - :In)}
            JuliaDBMeta.@transform {new_range = (colon(plot_range.start,:ending+1))}
            JuliaDBMeta.@transform {corr_trace = ShiftedArray((cols(selected_trace)[:new_range]-:mean) / :mean, plot_range.start, default = NaN)}
        end;
        return columns(plot_data,:corr_trace)
    else
        println("bhv type not recognized")
    end
end

function normalise_streak(t::IndexedTables.NextTable,bhv_type::Symbol,norm_range::Range,plot_range::Range)
    t = renamecol(t, :corr_trace, :to_analyze)
    if bhv_type == :pokes
        plot_data = @apply t begin
            @transform_vec (:Session, :Streak) flatten=true begin
                v = cols(selected_trace)
                m = NaNMath.mean(v[1][norm_range])
                {mean = fill(m, length(v))}
            end
            JuliaDBMeta.@transform {corr_trace = ShiftedArray((:to_analyze[plot_range]-:mean) / :mean, plot_range.start, default = NaN)}
        end;
        return columns(plot_data,:corr_trace)
    elseif  bhv_type == :streaks
        plot_data = @apply t begin
            JuliaDBMeta.@transform {mean = NaNMath.mean(cols(selected_trace)[norm_range])}
            JuliaDBMeta.@transform {corr_trace = ShiftedArray((:to_analyze[plot_range]-:mean) / :mean, plot_range.start, default = NaN)}
        end;
        return columns(plot_data,:corr_trace)
    else
        println("bhv type not recognized")
    end
end

"""
`regress_traces`
"""
function regress_traces(t::IndexedTables.NextTable)
    res = @apply t begin
        JuliaDB.groupby(_, :Session, flatten = true) do tt
            ref, sig = columns(tt, (:ref, :sig))
            ref_flat = vcat((parent(r) for r in ref)...)
            sig_flat = vcat((parent(r) for r in sig)...)
            mask = @. !isnan.(ref_flat) & !isnan.(sig_flat)
            a, b = linreg(ref_flat[mask], sig_flat[mask])
            @NT(intercept = a, slope = b)
        end
        JuliaDB.join(t, _, lkey = :Session, rkey = :Session)
        @transform {corr_trace = ShiftedArray(parent(:sig) .- (:intercept .+ :slope .* parent(:ref)), shifts(:sig), default = NaN)}
    end;
    return res
end


function regress_traces(t::IndexedTables.NextTable,selected_trace::Symbol,plot_range::Range)
    y_name = String(selected_trace)
    ref = Symbol(replace(y_name,"sig","ref",1))
    t = collect_raw(t,selected_trace,plot_range);
    t = renamecol(t, :corr_trace, :sig)
    t = collect_raw(t,ref,plot_range);
    t = renamecol(t, :corr_trace, :ref)

    res = @apply t begin
        JuliaDB.groupby(_, :Session, flatten = true) do tt
            ref, sig = columns(tt, (:ref, :sig))
            ref_flat = vcat((parent(r) for r in ref)...)
            sig_flat = vcat((parent(r) for r in sig)...)
            mask = @. !isnan.(ref_flat) & !isnan.(sig_flat)
            a, b = linreg(ref_flat[mask], sig_flat[mask])
            @NT(intercept = a, slope = b)
        end
        JuliaDB.join(t, _, lkey = :Session, rkey = :Session)
        @transform {corr_trace = ShiftedArray(parent(:sig) .- (:intercept .+ :slope .* parent(:ref)), shifts(:sig))}
    end;
    return res
end

function regress_traces(t::IndexedTables.NextTable,bhv_type::Symbol,selected_trace::Symbol,norm_range::Range,plot_range::Range)
    y_name = String(selected_trace)
    ref = Symbol(replace(y_name,"sig","ref",1))
    t = normalise_streak(t,bhv_type,selected_trace,norm_range,plot_range);
    t = renamecol(t, :corr_trace, :sig)
    t = normalise_streak(t,bhv_type,ref,norm_range,plot_range);
    t = renamecol(t, :corr_trace, :ref)

    res = @apply t begin
        JuliaDB.groupby(_, :Session, flatten = true) do tt
            ref, sig = columns(tt, (:ref, :sig))
            ref_flat = vcat((parent(r) for r in ref)...)
            sig_flat = vcat((parent(r) for r in sig)...)
            mask = @. !isnan.(ref_flat) & !isnan.(sig_flat)
            a, b = linreg(ref_flat[mask], sig_flat[mask])
            @NT(intercept = a, slope = b)
        end
        JuliaDB.join(t, _, lkey = :Session, rkey = :Session)
        @transform {corr_trace = ShiftedArray(parent(:sig) .- (:intercept .+ :slope .* parent(:ref)), shifts(:sig))}
    end;
    return res
end

"""
`diff_traces`
"""
function diff_traces(t::IndexedTables.NextTable,selected_trace::Symbol,plot_range::Range)
    plot_data = JuliaDBMeta.@apply t begin
        JuliaDBMeta.@transform {ending = (:Out - :In)}
        JuliaDBMeta.@transform {new_range = (colon(plot_range.start,:ending+1))}
        JuliaDBMeta.@transform {new_array = (cols(selected_trace)[:new_range])}
        JuliaDBMeta.@transform {diff_array = (:new_array .-lag(:new_array,default = NaN) )}
        JuliaDBMeta.@transform {corr_trace = ShiftedArray(:diff_array, plot_range.start, default = NaN)}
    end;
    return columns(plot_data,:corr_trace)
end

"""
`collect_traces`
"""

function collect_traces(data::UI_traces,selected_trace::Symbol)
    t = data.filtered_data[]
    fps = observe(data.fps)[]
    norm_window = selecteditems(data.norm_window)
    norm_range = Int64(norm_window[1]*fps):Int64(norm_window[2]*fps)
    plot_window = selecteditems(data.plot_window)
    p_start = Int64(plot_window[1]*fps)
    p_stop = Int64(plot_window[2]*fps)
    plot_range = p_start:p_stop
    bhv_type = observe(data.bhv_type)

    if selected_norm(data) == "Raw"
        plot_data = collect_raw(t,selected_trace,plot_range)
    elseif selected_norm(data) == "Sliding_Norm"
        sel_t = Symbol("sn_"*String(selected_trace))
        plot_data = collect_raw(t,sel_t,plot_range)
    elseif selected_norm(data) == "Streak_Norm"
    #elseif trace_type == "Normalised"
        plot_data = normalise_streak(t,bhv_type,selected_trace,norm_range,plot_range);
    elseif selected_norm(data) == "Differential_Norm"
        plot_data = diff_traces(t,selected_trace,plot_range)
    end;
    return plot_data
end
