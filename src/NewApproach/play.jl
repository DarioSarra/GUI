dataset = FileIO.load(filename[]) |> DataFrame;
dataset
##
CNO = UI_bhv(data[]);
w = Window()
body!(w, CNO.ui)
##
a_pokes = Analysis(pokes)
process(a_pokes)
##
pokes_t = UI_trace(data,:pokes);
w = Window()
body!(w, pokes_t.ui)
##
select(pokes_t.or_data,(:Streak_n,:Reward,:Poke_h))
##
streaks_t = UI_trace(data,:streaks);
w = Window()
body!(w, streaks_t.ui)
##
selected_trace = observe(pokes_t.traces)[]
fps = observe(pokes_t.fps)[]
norm_window = selecteditems(pokes_t.norm_window)
norm_range = Int64(norm_window[1]*fps):Int64(norm_window[2]*fps)
plot_window = selecteditems(pokes_t.plot_window)
plot_range = Int64(plot_window[1])*fps:Int64(plot_window[2]*fps)
bhv_type = pokes_t.bhv_type

t = pokes_t.or_data;
y_name = String(selected_trace)
ref = Symbol(replace(y_name,"sig","ref",1))
t = normalise_f0(t,bhv_type,selected_trace,norm_range,plot_range);
t = renamecol(t, :corr_trace, :sig);
t = normalise_f0(t,bhv_type,ref,norm_range,plot_range);
t = renamecol(t, :corr_trace, :ref);
##
@apply t begin
    JuliaDB.groupby(_, :Session, flatten = true) do tt
        ref, sig = columns(tt, (:ref, :sig))
        ref_flat = vcat((parent(r) for r in ref)...)
        sig_flat = vcat((parent(r) for r in sig)...)
        mask = @. !isnan(ref_flat) & !isnan(sig_flat)
        a, b = linreg(ref_flat[mask], sig_flat[mask])
        @NT(intercept = a, slope = b)
    end
end


res = @apply t begin
    JuliaDB.groupby(_, :Session, flatten = true) do tt
        ref, sig = columns(tt, (:ref, :sig))
        ref_flat = vcat((parent(r) for r in ref)...)
        sig_flat = vcat((parent(r) for r in sig)...)
        mask = @. !isnan(ref_flat) & !isnan(sig_flat)
        a, b = linreg(ref_flat[mask], sig_flat[mask])
        @NT(intercept = a, slope = b)
    end
    JuliaDB.join(t, _, lkey = :Session, rkey = :Session)
    @transform {corr_trace = ShiftedArray(parent(:sig) .- (:intercept .+ :slope .* parent(:ref)), shifts(:sig))}
end;
##
prova = Analysis(pokes_t);
prova.data
colnames(prova.data)
process(prova)

using ShiftedArrays

reduce_vec(mean, column(tt, :norm_sig), -10:10, filter = !isnan)
using GroupedErrors

@> tt begin
    @x -50:50 :discrete
    @splitby _.Reward
    @across _.MouseID
    @y _.norm_sig
    @plot plot() :ribbon
end
sel = :LeftNac_sig
