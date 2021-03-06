@inline tuplejoin(x) = x
@inline tuplejoin(x, y) = (x..., y...)
@inline tuplejoin(x, y, z...) = tuplejoin(tuplejoin(x, y), z...)


@with_kw struct Analysis
    data #indexed table
    splitby = () #tupla of symbols
    compute_error = nothing #tupla (:none, ) (:across, :MouseID) (:bootstrap, 100) (:across, :all)
    x = nothing #:Symbol
    y = nothing #:Symbol
    z = nothing
    xfunc = nothing
    yfunc = nothing
    zfunc = nothing
    axis_type = nothing #:Symbol :auto, :discrete, :continouos
    smoother = nothing #:Number 1:100
    package = GroupedError()
    plot = nothing #function plot, groupedbar,
    plot_kwargs = [] # [(:color, :red), (:legend, :bottom)]
end

function Analysis(a::Analysis; kwargs...)
    d = Dict(kwargs)
    Analysis((get(d, f, getfield(a, f)) for f in fieldnames(a))...)
end


function Analysis_b(df::UI_traces)
    data = deepcopy(df.filtered_data[])#indexed table
    s = Symbol.(observe(df.split_cont)[])
    bin = observe(df.bins)[]
    if !isempty(s)
        for i = 1:size(s,1)
            data = JuliaDBMeta.@with data setcol(_, s[i], CategoricalArrays.cut(cols(s[i]),bin))
        end
    end
    splitby = Tuple(vcat(observe(df.split_cont)[],observe(df.split_cat)[])) #tupla of symbols
    compute_error = get_error(df) #tupla (:none, ) (:across, :MouseID) (:bootstrap, 100) (:across, :all)
    x = Symbol(observe(df.x_axis)[])
    y = Symbol(observe(df.y_axis)[])
    axis_type = Symbol(observe(df.axis_type)[]) #:Symbol :auto, :discrete, :continouos
    smoother = observe(df.smoother)[]
    package = GroupedError()
    plot = plot_dict[observe(df.plot_type)[]] #function plot, groupedbar,
    plot_kwargs = []
    Analysis(data = data, splitby = splitby, compute_error = compute_error,
    x=x,y=y, axis_type = axis_type,smoother = smoother,package = package,
    plot=plot,plot_kwargs = plot_kwargs, xfunc = mean, yfunc = mean)
end

function Analysis_t(data::UI_traces)
    selected_trace = observe(data.traces)[]
    regressor = Symbol(which_regressor(data))
    trace_type = observe(data.tracetype)[]
    fps = observe(data.fps)[]
    norm_window = selecteditems(data.norm_window)
    norm_range = Int64(norm_window[1]*fps):Int64(norm_window[2]*fps)
    plot_window = selecteditems(data.plot_window)
    plot_range = Int64(plot_window[1])*fps:Int64(plot_window[2]*fps)
    splitby = Tuple(vcat(observe(data.split_cont)[],observe(data.split_cat)[])) #tupla of symbols
    bhv_type = data.bhv_type #data.bhv_type#observe(data.bhv_type)
    compute_error = get_error(data)
    t = data.filtered_data[];
    s = Symbol.(observe(data.split_cont)[])
    bin = observe(data.bins)[]
    if !isempty(s)
        t = categorize_cols(t,s,bin)
        # for i = 1:size(s,1)
        #     vocabulary = categorize(t, s[i],bin)
        #     t = @transform t {binned =  get(vocabulary,s[i],0)}
        #     t = setcol(t, s[i] => cols(t,:binned))
        # end
    end

    if !is_regression(data)
        plot_data = pushcol(t,:correctedTrace,collect_traces(data,selected_trace))
    else
        t = pushcol(t,:sig,collect_traces(data,selected_trace))
        t = pushcol(t,:ref,collect_traces(data,regressor))
        plot_data = regress_traces(t)
    end
    allignment = observe(data.x_allignment)[]
    if allignment != :In
        plot_data = renamecol(plot_data, :correctedTrace, :pre_shift)
        plot_data = @apply plot_data begin
            JuliaDBMeta.@filter !isnan.(cols(allignment))
            @transform {difference = :In - cols(allignment)}
            @transform {correctedTrace = lag(:pre_shift,:difference,default = NaN)}
        end
    end
    y = :correctedTrace #:Symbol
    axis_type = :discrete #Symbol(observe(df.axis_type)[]) #:Symbol :auto, :discrete, :continouos
    time_range = collect(plot_range)./fps
    smoother = observe(data.smoother)[]
    package = GroupedError()
    plot = plot_dict["line plot"] #function plot, groupedbar,
    plot_kwargs = []

    Analysis(data = plot_data, splitby = splitby, compute_error = compute_error,
    x = plot_range, y = y, axis_type = axis_type, smoother=smoother, package=package,
    plot = plot,plot_kwargs = plot_kwargs, xfunc = mean, yfunc = mean)

end


function get_error(df::UI_traces)
    inputvalue = observe(df.compute_error)[]
    if inputvalue == "none"
        return nothing
    elseif inputvalue == "bootstrap"
        return (:bootstrap,observe(df.smoother)[])
    else
        return(:across, Symbol(inputvalue))
    end
end

function Analysis(df::UI_bhvs)
    data = deepcopy(df.filtered_data[])#indexed table
    s = Symbol.(observe(df.split_cont)[])
    bin = observe(df.bins)[]
    if !isempty(s)
        for i = 1:size(s,1)
            data = JuliaDBMeta.@with data setcol(_, s[i], CategoricalArrays.cut(cols(s[i]),bin))
        end
    end
    splitby = Tuple(vcat(observe(df.split_cont)[],observe(df.split_cat)[])) #tupla of symbols
    compute_error = get_error(df) #tupla (:none, ) (:across, :MouseID) (:bootstrap, 100) (:across, :all)
    x = Symbol(observe(df.x_axis)[])
    y = Symbol(observe(df.y_axis)[])
    axis_type = Symbol(observe(df.axis_type)[]) #:Symbol :auto, :discrete, :continouos
    smoother = observe(df.smoother)[]
    package = GroupedError()
    plot = plot_dict[observe(df.plot_type)[]] #function plot, groupedbar,
    plot_kwargs = []
    Analysis(data = data, splitby = splitby, compute_error = compute_error,
    x=x,y=y, axis_type = axis_type,smoother = smoother,package = package,
    plot=plot,plot_kwargs = plot_kwargs, xfunc = mean, yfunc = mean)
end

function get_error(df::UI_bhvs)
    inputvalue = observe(df.compute_error)[]
    if inputvalue == "none"
        return nothing
    elseif inputvalue == "bootstrap"
        return (:bootstrap,observe(df.smoother)[])
    else
        return(:across, Symbol(inputvalue))
    end
end

struct StatPlotsRecipe; end
struct GroupedError; end

function analysistype(a)
    a.package != nothing && return a.package
    a.plot in [boxplot, violin, histogram2d, marginalhist] && return StatPlotsRecipe
    a.compute_error !== nothing && return GroupedError
    (a.y in colnames(a.data.table) || a.y === nothing) ? StatPlotsRecipe : GroupedError
end

process(a::Analysis) = process(analysistype(a), a)
splitby(a::Analysis) = a.splitby
# orderby(a::Analysis) = orderby(a.data)
