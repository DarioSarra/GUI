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

function Analysis(df::ManipulableTable)
    data = observe(df.plotdata)[]#indexed table
    splitby = Tuple(observe(df.splitby)[]) #tupla of symbols
    compute_error = get_error(df) #tupla (:none, ) (:across, :MouseID) (:bootstrap, 100) (:across, :all)
    x = Symbol(observe(df.x_axis)[])
    y = Symbol(observe(df.y_axis)[])
    axis_type = Symbol(observe(df.axis_type)[]) #:Symbol :auto, :discrete, :continouos
    smoother = observe(df.smoother)[]
    package = GroupedError()
    plot = plot_dict[observe(df.plot_type)[]] #function plot, groupedbar,
    plot_kwargs = []
    Analysis(data = data, splitby = splitby, compute_error = compute_error,
    x=x,y=y, axis_type = axis_type,smoother=smoother,package=package,
    plot=plot,plot_kwargs = plot_kwargs, xfunc = mean, yfunc = mean)
end

function get_error(df::ManipulableTable)
    inputvalue = observe(df.compute_error)[]
    if inputvalue == "none"
        return nothing
    elseif inputvalue == "bootstrap"
        return (:bootstrap,observe(df.smoother)[])
    else
        return(:across, Symbol(inputvalue))
    end
end

function Analysis(df::ManipulableTrace)
    data = observe(df.plotdata)[]#indexed table
    splitby = Tuple(observe(df.splitby)[]) #tupla of symbols
    compute_error = get_error(df) #tupla (:none, ) (:across, :MouseID) (:bootstrap, 100) (:across, :all)
    x = Symbol(observe(df.x_axis)[])
    y = Symbol(observe(df.y_axis)[])
    axis_type = Symbol(observe(df.axis_type)[]) #:Symbol :auto, :discrete, :continouos
    smoother = observe(df.smoother)[]
    package = GroupedError()
    plot = plot_dict[observe(df.plot_type)[]] #function plot, groupedbar,
    plot_kwargs = []
    Analysis(data = data, splitby = splitby, compute_error = compute_error,
    x=x,y=y, axis_type = axis_type,smoother=smoother,package=package,
    plot=plot,plot_kwargs = plot_kwargs, xfunc = mean, yfunc = mean)
end

function get_error(df::ManipulableTrace)
    inputvalue = observe(df.compute_error)[]
    if inputvalue == "none"
        return nothing
    elseif inputvalue == "bootstrap"
        return (:bootstrap,observe(df.smoother)[])
    else
        return(:across, Symbol(inputvalue))
    end
end

function Analysis(df::Mutable_bhvs)
    data = deepcopy(df.bhv_data)#indexed table
    s = Symbol.(observe(df.splitby_cont)[])
    if !isempty(s)
        for i = 1:size(s,1)
            bin = observe(b.bins)[]
            data = JuliaDBMeta.@with data setcol(_, s[i], CategoricalArrays.cut(cols(s[i]),bin))
        end
    end
    splitby = Tuple(vcat(observe(df.splitby_cont)[],observe(df.splitby_cat)[])) #tupla of symbols
    compute_error = get_error(df) #tupla (:none, ) (:across, :MouseID) (:bootstrap, 100) (:across, :all)
    x = Symbol(observe(df.x_axis)[])
    y = Symbol(observe(df.y_axis)[])
    axis_type = Symbol(observe(df.axis_type)[]) #:Symbol :auto, :discrete, :continouos
    smoother = observe(df.smoother)[]
    package = GroupedError()
    plot = plot_dict[observe(df.plot_type)[]] #function plot, groupedbar,
    plot_kwargs = []
    Analysis(data = data, splitby = splitby, compute_error = compute_error,
    x=x,y=y, axis_type = axis_type,smoother=smoother,package=package,
    plot=plot,plot_kwargs = plot_kwargs, xfunc = mean, yfunc = mean)
end

function get_error(df::Mutable_bhvs)
    inputvalue = observe(df.compute_error)[]
    if inputvalue == "none"
        return nothing
    elseif inputvalue == "bootstrap"
        return (:bootstrap,observe(df.smoother)[])
    else
        return(:across, Symbol(inputvalue))
    end
end

function Analysis(df::Mutable_traces)
    splitby = Tuple(Symbol.(vcat(observe(df.splitby_cont)[],observe(df.splitby_cat)[]))) #tupla of symbols
    compute_error = get_error(df) #tupla (:none, ) (:across, :MouseID) (:bootstrap, 100) (:across, :all)
    y = Symbol(observe(df.fibers)[])
    yfunc = observe(df.rate)[]
    x_1 = selecteditems(df.plot_window)[1]
    x_2 = selecteditems(df.plot_window)[2]
    norm_1 = selecteditems(df.norm_window)[1]
    norm_2 = selecteditems(df.norm_window)[2]
    x_interval = Int64(x_1*yfunc):Int64(x_2*yfunc) #visualization interval
    x = :indici #name of th columns in the plot_data
    xfunc = Int64(norm_1*yfunc):Int64(norm_2*yfunc) #normalization interval
    zfunc = Symbol(observe(df.tracetype)[])
    axis_type = :discrete#Symbol(observe(df.axis_type)[]) #:Symbol :auto, :discrete, :continouos
    smoother = observe(df.smoother)[]
    package = GroupedError()
    plot = plot_dict["line plot"] #function plot, groupedbar,
    plot_kwargs = []

    data = deepcopy(df.plotdata[])#indexed table
    s = Symbol.(observe(df.splitby_cont)[])
    if !isempty(s)
        for i = 1:size(s,1)
            bin = observe(b.bins)[]
            data = JuliaDBMeta.@with data setcol(_, s[i], CategoricalArrays.cut(cols(s[i]),bin))
        end
    end

    selection = tuplejoin([y],splitby)
    t = select(data,selection)
    t = pushcol(t,:trial,collect(1:length(t)))
    split = tuplejoin([:trial],splitby)

    plot_data = []

     for idx = 1:length(t)
        split_vals = @where select(t,split) :trial ==idx
        dati = collect(select(t,y)[idx][x_interval])
        indici = collect(x_interval)
        trial = repmat([idx],size(indici,1))
        ongoing = table(trial,dati,indici, names = [:trial,:dati,:indici])
        ongoing = JuliaDB.join(split_vals,ongoing,lkey=:trial, rkey=:trial)
        if isempty(plot_data)
            plot_data = ongoing
        else
            plot_data = JuliaDB.merge(plot_data,ongoing)
        end
    end

    Analysis(data = plot_data, splitby = splitby, compute_error = compute_error,
    x=x,y=y, axis_type = axis_type,smoother=smoother,package=package,
    plot=plot,plot_kwargs = plot_kwargs, xfunc = xfunc, yfunc = yfunc,zfunc= zfunc)
end

function get_error(df::Mutable_traces)
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
