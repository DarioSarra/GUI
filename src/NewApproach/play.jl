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
observe(pokes_t.fps)[]
selecteditems(pokes_t.plot_window)
Symbol.(observe(pokes_t.split_cont)[])
colnames(pokes_t.or_data)

function Analysis(data::UI_traces)
    sel = observe(data.traces)[]
    norm_window = selecteditems(data.norm_window)
    fps = observe(data.fps)[]
    norm_range = Int64(norm_window[1]*fps):Int64(norm_window[2]*fps)
    plot_window = selecteditems(data.plot_window)
    plot_range = Int64(plot_window[1])*fps:Int64(plot_window[2]*fps)
    splitby = Tuple(Symbol.(vcat(observe(data.split_cont)[],observe(data.split_cat)[]))) #tupla of symbols
    calc_er = observe(data.compute_error)[]
    error = calc_er == "bootstrap" || calc_er == "all" || calc_er == "none"? () : [Symbol.(calc_er)]
    info_cols = tuplejoin([:trial],splitby,error)
    compute_error = get_error(data)
    t = data.or_data;
    s = Symbol.(observe(data.split_cont)[])
    bin = observe(data.bins)[]
    if !isempty(s)
        for i = 1:size(s,1)
            t = setcol(t, s[i] => CategoricalArrays.cut(column(t, s[i]),bin))
        end
    end

    plot_data = @apply t begin
        @transform_vec (:Session, :Streak_n) flatten=true begin
            v = cols(sel)
            m = NaNMath.mean(v[1][norm_range])
            {mean = fill(m, length(v))}
        end
        JuliaDBMeta.@transform {norm_sig = ShiftedArray((cols(sel)[plot_range]-:mean) / :mean, plot_range[1], default = NaN)}
    end;

    x = plot_range #:Symbol
    y = :norm_sig #:Symbol
    axis_type = :discrete #Symbol(observe(df.axis_type)[]) #:Symbol :auto, :discrete, :continouos
    smoother = observe(data.smoother)[]
    package = GroupedError()
    plot = plot_dict["line plot"] #function plot, groupedbar,
    plot_kwargs = []

    Analysis(data = plot_data, splitby = splitby, compute_error = compute_error,
    x=plot_range,y=y, axis_type = axis_type, smoother=smoother,package=package,
    plot=plot,plot_kwargs = plot_kwargs,xfunc = mean, yfunc = mean)

end
##
t = pokes_t.or_data
s = Symbol.(observe(pokes_t.split_cont)[])
bin = observe(pokes_t.bins)[]
if !isempty(s)
    for i = 1:size(s,1)
        t = setcol(t, s[i] => CategoricalArrays.cut(column(t, s[i]),bin))
    end
end;
t

plot_data = @apply t begin
    @transform_vec (:Session, :Streak_n) flatten=true begin
        v = cols(sel)
        m = NaNMath.mean(v[1][norm_range])
        {mean = fill(m, length(v))}
    end
    JuliaDBMeta.@transform {norm_sig = ShiftedArray((cols(sel)[plot_range]-:mean) / :mean, plot_range[1], default = NaN)}
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
