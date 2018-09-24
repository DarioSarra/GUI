function sliding_norm(t::IndexedTables.NextTable,selected_trace::Symbol,sliding_range::Range)
    plot_data = @apply t begin
            @transform_vec (:Session) flatten=true begin
                v = cols(selected_trace)
                adjusted = sliding_f0(v[1].parent,sliding_range)
                {sliding_trace = [ShiftedArray(adjusted, -i,default = NaN) for i in :In]}
            #@transform {corr_trace = ShiftedArray(:sliding_trace[plot_range], plot_range.start, default = NaN)}
            end
        end;
end

function sliding_f0(ongoing_trace::Vector,norm_range::Range)
    sliding_start = - (norm_range.start + norm_range.stop)
    transformed_trace = repmat([0.0],sliding_start)
    for i = sliding_start+1:size(ongoing_trace,1)
        interval_stop = i + norm_range.stop
        interval_start =  interval_stop + norm_range.start
        interval_range = interval_start:interval_stop
        ongoing_interval = ongoing_trace[interval_range]
        mask = ongoing_interval.<median(ongoing_interval)
        ongoing_f0 = mean(ongoing_interval[mask])
        normalised_value = (ongoing_trace[i] - ongoing_f0)/ongoing_f0
        push!(transformed_trace,normalised_value)
    end
    return transformed_trace
end

function collect_raw(t::IndexedTables.NextTable,selected_trace::Symbol,plot_range::Range)
    plot_data = @apply t begin
        JuliaDBMeta.@transform {corr_trace = ShiftedArray(cols(selected_trace)[plot_range], plot_range.start, default = NaN)}
    end;
end

# function sliding_f0(t::IndexedTables.NextTable,selected_trace::Symbol,norm_range::Range)
#     sliding_start = - (norm_range.start + norm_range.stop)
#     ongoing_trace = select(t,selected_trace)#each row contains a shifted array of the entire session
#     transformed_trace = repmat([0.0],sliding_start)
#     for i = sliding_start+1:size(ongoing_trace,1)
#         interval_stop = i + norm_range.stop
#         interval_start =  interval_stop + norm_range.start
#         interval_range = interval_start:interval_stop
#         ongoing_interval = ongoing_trace[interval_range]
#         mask = ongoing_interval.<median(ongoing_interval)
#         ongoing_f0 = mean(ongoing_interval[mask])
#         normalised_value = ongoing_trace[i] - ongoing_f0
#         push!(transformed_trace,normalised_value)
#     end
#     return transformed_trace
# end

"""
`normalise_streak`

Method1: need to specify the symbol of the trace to normalise
Method2: expect to find a column called corr_trace to be analized
"""

function normalise_streak(t::IndexedTables.NextTable,bhv_type::Symbol,selected_trace::Symbol,norm_range::Range,plot_range::Range)
    if bhv_type == :pokes
        plot_data = @apply t begin
            @transform_vec (:Session, :Streak_n) flatten=true begin
                v = cols(selected_trace)
                m = NaNMath.mean(v[1][norm_range])
                {mean = fill(m, length(v))}
            end
            JuliaDBMeta.@transform {corr_trace = ShiftedArray((cols(selected_trace)[plot_range]-:mean) / :mean, plot_range.start, default = NaN)}
        end;
        return plot_data
    elseif  bhv_type == :streaks
        plot_data = @apply t begin
            JuliaDBMeta.@transform {mean = NaNMath.mean(cols(selected_trace)[norm_range])}
            JuliaDBMeta.@transform {corr_trace = ShiftedArray((cols(selected_trace)[plot_range]-:mean) / :mean, plot_range.start, default = NaN)}
        end;
        return plot_data
    else
        println("bhv type not recognized")
    end
end

function normalise_streak(t::IndexedTables.NextTable,bhv_type::Symbol,norm_range::Range,plot_range::Range)
    t = renamecol(t, :corr_trace, :to_analyze)
    if bhv_type == :pokes
        plot_data = @apply t begin
            @transform_vec (:Session, :Streak_n) flatten=true begin
                v = cols(selected_trace)
                m = NaNMath.mean(v[1][norm_range])
                {mean = fill(m, length(v))}
            end
            JuliaDBMeta.@transform {corr_trace = ShiftedArray((:to_analyze[plot_range]-:mean) / :mean, plot_range.start, default = NaN)}
        end;
        return plot_data
    elseif  bhv_type == :streaks
        plot_data = @apply t begin
            JuliaDBMeta.@transform {mean = NaNMath.mean(cols(selected_trace)[norm_range])}
            JuliaDBMeta.@transform {corr_trace = ShiftedArray((:to_analyze[plot_range]-:mean) / :mean, plot_range.start, default = NaN)}
        end;
        return plot_data
    else
        println("bhv type not recognized")
    end
end



"""
`regress_traces`
"""

function regress_traces(t::IndexedTables.NextTable,bhv_type::Symbol,selected_trace::Symbol,norm_range::Range,plot_range::Range)
    # y_name = String(selected_trace)
    # ref = Symbol(replace(y_name,"sig","ref",1))
    # t = normalise_streak(t,bhv_type,selected_trace,norm_range,plot_range);
    # t = renamecol(t, :corr_trace, :sig)
    # t = normalise_streak(t,bhv_type,ref,norm_range,plot_range);
    # t = renamecol(t, :corr_trace, :ref)

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
##
