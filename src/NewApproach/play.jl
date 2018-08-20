##
pokes = UI_bhv(data,:pokes);
w = Window()
body!(w, pokes.ui)

##
a_pokes = Analysis(pokes)
process(a_pokes)
##
pokes_t = UI_trace(data,:pokes);
w = Window()
body!(w, pokes_t.ui)
##
println(colnames(pokes_t.or_data))
sel = :LeftNac_sig
norm_window = -150:-50
vis_window = -50:50
t = pokes_t.or_data;
tt = @apply t begin
    @transform_vec (:Session, :Streak_n) flatten=true begin
        v = cols(sel)
        m = NaNMath.mean(v[1][norm_window])
        {mean = fill(m, length(v))}
    end
    JuliaDBMeta.@transform {norm_sig = ShiftedArray((cols(sel)[vis_window]-:mean) / :mean, vis_window[1], default = NaN)}
end;
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
function normalise_pokes(norm_window::Range,sel_trace::Array{ShiftedArray})
end
