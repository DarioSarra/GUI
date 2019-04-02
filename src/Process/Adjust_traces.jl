"""
`collect_raw`

from an Array of ShiftedArrays collects values around an interval starting from the plot range start until
the frame value identified by the column :Out
"""

function collect_raw(t::IndexedTables.IndexedTable,selected_trace::Symbol,plot_range::UnitRange)
    plot_data = JuliaDBMeta.@apply t begin
        JuliaDBMeta.@transform {ending = (:Out - :In)}
        JuliaDBMeta.@transform {new_range = (range#=colon=#(plot_range.start,:ending+1))}
        JuliaDBMeta.@transform {new_array = (cols(selected_trace)[:new_range])}
        JuliaDBMeta.@transform {correctedTrace = ShiftedArray(:new_array, plot_range.start, default = NaN)}
    end;
    return columns(plot_data,:correctedTrace)
end

"""
`normalise_streak`

Method1: need to specify the symbol of the trace to normalise
Method2: expect to find a column called correctedTrace to be analized
"""

function normalise_streak(t::IndexedTables.IndexedTable,bhv_type::Symbol,selected_trace::Symbol,norm_range::UnitRange,plot_range::UnitRange)
    if bhv_type == :pokes
        plot_data = @apply t begin
            @transform_vec (:Session, :Streak) flatten=true begin
                v = cols(selected_trace)
                m = NaNMath.mean(v[1][norm_range])
                {mean = fill(m, length(v))}
            end
            JuliaDBMeta.@transform {ending = (:Out - :In)}
            JuliaDBMeta.@transform {new_range = (range#=colon=#(plot_range.start,:ending+1))}
            JuliaDBMeta.@transform {correctedTrace = ShiftedArray((cols(selected_trace)[:new_range].-:mean) / :mean, plot_range.start, default = NaN)}
        end;
        return columns(plot_data,:correctedTrace)
    elseif  bhv_type == :streaks
        plot_data = @apply t begin
            JuliaDBMeta.@transform {mean = NaNMath.mean(cols(selected_trace)[norm_range])}
            JuliaDBMeta.@transform {ending = (:Out - :In)}
            JuliaDBMeta.@transform {new_range = (range#=colon=#(plot_range.start,:ending+1))}
            JuliaDBMeta.@transform {correctedTrace = ShiftedArray((cols(selected_trace)[:new_range].-:mean) / :mean, plot_range.start, default = NaN)}
        end;
        return columns(plot_data,:correctedTrace)
    else
        println("bhv type not recognized")
    end
end

function normalise_streak(t::IndexedTables.IndexedTable,bhv_type::Symbol,norm_range::UnitRange,plot_range::UnitRange)
    t = renamecol(t, :correctedTrace, :to_analyze)
    if bhv_type == :pokes
        plot_data = @apply t begin
            @transform_vec (:Session, :Streak) flatten=true begin
                v = cols(selected_trace)
                m = NaNMath.mean(v[1][norm_range])
                {mean = fill(m, length(v))}
            end
            JuliaDBMeta.@transform {correctedTrace = ShiftedArray((:to_analyze[plot_range]-:mean) / :mean, plot_range.start, default = NaN)}
        end;
        return columns(plot_data,:correctedTrace)
    elseif  bhv_type == :streaks
        plot_data = @apply t begin
            JuliaDBMeta.@transform {mean = NaNMath.mean(cols(selected_trace)[norm_range])}
            JuliaDBMeta.@transform {correctedTrace = ShiftedArray((:to_analyze[plot_range]-:mean) / :mean, plot_range.start, default = NaN)}
        end;
        return columns(plot_data,:correctedTrace)
    else
        println("bhv type not recognized")
    end
end



"""
`regress_traces`
"""
function regress_traces(t::IndexedTables.IndexedTable)
    res = @groupby t :Session begin
        refFlat = vcat((parent(r) for r in :ref)...)
        sigFlat = vcat((parent(r) for r in :sig)...)
        mask = @. !isnan(refFlat) & !isnan(sigFlat)
        intercept, slope = linreg(refFlat[mask], sigFlat[mask])
        (intercept=intercept, slope=slope)
    end
    res = JuliaDB.join(t, res, lkey = :Session, rkey = :Session)
    res = @transform res {correctedTrace = ShiftedArray(parent(:sig) .- (:intercept .+ :slope .* parent(:ref)), shifts(:sig))}
end
# # function regress_traces(t::IndexedTables.IndexedTable)
# #     res = @apply t begin
# #         JuliaDB.groupby(_, :Session, flatten = true) do tt
# #             ref, sig = columns(tt, (:ref, :sig))
# #             refFlat = vcat((parent(r) for r in ref)...)
# #             sigFlat = vcat((parent(r) for r in sig)...)
# #             mask = @. !isnan.(refFlat) & !isnan.(sigFlat)
# #             a, b = linreg(refFlat[mask], sigFlat[mask])
# #             NamedTuple{(:intercept, :slope)}((a,b))
# #             # @NT(intercept = a, slope = b)
# #         end
# #         JuliaDB.join(t, _, lkey = :Session, rkey = :Session)
# #         @transform {correctedTrace = ShiftedArray(parent(:sig) .- (:intercept .+ :slope .* parent(:ref)), shifts(:sig))}
# #     end;
# #     return res
# # end
#
#
#
#
#
# function regress_traces(t::IndexedTables.IndexedTable,selected_trace::Symbol,plot_range::UnitRange)
#     y_name = String(selected_trace)
#     ref = Symbol(replace(y_name,"sig","ref",1))
#     t = collect_raw(t,selected_trace,plot_range);
#     t = renamecol(t, :correctedTrace, :sig)
#     t = collect_raw(t,ref,plot_range);
#     t = renamecol(t, :correctedTrace, :ref)
#
#     coefficients = regress_traces(t)
#     t = JuliaDB.join(t, coefficients, lkey = :Session, rkey = :Session)
#     res = @apply t begin
#         @transform {correctedTrace = ShiftedArray(parent(:sig) .- (:intercept .+ :slope .* parent(:ref)), shifts(:sig))}
#     end
#     # res = @apply t begin
#     #     JuliaDB.groupby(_, :Session, flatten = true) do tt
#     #         ref, sig = columns(tt, (:ref, :sig))
#     #         refFlat = vcat((parent(r) for r in ref)...)
#     #         sigFlat = vcat((parent(r) for r in sig)...)
#     #         mask = @. !isnan.(refFlat) & !isnan.(sigFlat)
#     #         a, b = linreg(refFlat[mask], sigFlat[mask])
#     #         NamedTuple{(:intercept, :slope)}((a,b))
#     #         # @NT(intercept = a, slope = b)
#     #     end
#     #     JuliaDB.join(t, _, lkey = :Session, rkey = :Session)
#     #     @transform {correctedTrace = ShiftedArray(parent(:sig) .- (:intercept .+ :slope .* parent(:ref)), shifts(:sig))}
#     # end;
#     return res
# end
#
# function regress_traces(t::IndexedTables.IndexedTable,bhv_type::Symbol,selected_trace::Symbol,norm_range::UnitRange,plot_range::UnitRange)
#     y_name = String(selected_trace)
#     ref = Symbol(replace(y_name,"sig","ref",1))
#     t = normalise_streak(t,bhv_type,selected_trace,norm_range,plot_range);
#     t = renamecol(t, :correctedTrace, :sig)
#     t = normalise_streak(t,bhv_type,ref,norm_range,plot_range);
#     t = renamecol(t, :correctedTrace, :ref)
#
#     coefficients = regress_traces(t)
#     t = JuliaDB.join(t, coefficients, lkey = :Session, rkey = :Session)
#     res = @transform t {correctedTrace = ShiftedArray(parent(:sig) .- (:intercept .+ :slope .* parent(:ref)), shifts(:sig))}
#
#     # res = @apply t begin
#     #     JuliaDB.groupby(_, :Session, flatten = true) do tt
#     #         ref, sig = columns(tt, (:ref, :sig))
#     #         refFlat = vcat((parent(r) for r in ref)...)
#     #         sigFlat = vcat((parent(r) for r in sig)...)
#     #         mask = @. !isnan.(refFlat) & !isnan.(sigFlat)
#     #         a, b = linreg(refFlat[mask], sigFlat[mask])
#     #         NamedTuple{(:intercept, :slope)}((a,b))
#     #         # @NT(intercept = a, slope = b)
#     #     end
#     #     JuliaDB.join(t, _, lkey = :Session, rkey = :Session)
#     #     @transform {correctedTrace = ShiftedArray(parent(:sig) .- (:intercept .+ :slope .* parent(:ref)), shifts(:sig))}
#     # end;
#     return res
# end

"""
`diff_traces`
"""
function diff_traces(t::IndexedTables.IndexedTable,selected_trace::Symbol,plot_range::UnitRange)
    plot_data = JuliaDBMeta.@apply t begin
        JuliaDBMeta.@transform {ending = (:Out - :In)}
        JuliaDBMeta.@transform {new_range = (range#=colon=#(plot_range.start,:ending+1))}
        JuliaDBMeta.@transform {new_array = (cols(selected_trace)[:new_range])}
        JuliaDBMeta.@transform {diff_array = (:new_array .-lag(:new_array,default = NaN) )}
        JuliaDBMeta.@transform {correctedTrace = ShiftedArray(:diff_array, plot_range.start, default = NaN)}
    end;
    return columns(plot_data,:correctedTrace)
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
    plot_range = Int64(plot_window[1])*fps:Int64(plot_window[2]*fps)
    bhv_type = data.bhv_type#observe(data.bhv_type)

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
