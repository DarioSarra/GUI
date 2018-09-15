function collect_raw(t::IndexedTables.NextTable,selected_trace::Symbol,plot_range::Range)
    plot_data = @apply t begin
        JuliaDBMeta.@transform {corr_trace = ShiftedArray(cols(selected_trace)[plot_range], plot_range.start, default = NaN)}
    end;
end

function normalise_f0(t::IndexedTables.NextTable,bhv_type::Symbol,selected_trace::Symbol,norm_range::Range,plot_range::Range)
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

function regress_traces(t::IndexedTables.NextTable,bhv_type::Symbol,selected_trace::Symbol,norm_range::Range,plot_range::Range)
    y_name = String(selected_trace)
    ref = Symbol(replace(y_name,"sig","ref",1))
    t = normalise_f0(t,bhv_type,selected_trace,norm_range,plot_range);
    t = renamecol(t, :corr_trace, :sig)
    t = normalise_f0(t,bhv_type,ref,norm_range,plot_range);
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
##
