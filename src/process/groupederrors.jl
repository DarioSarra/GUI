function compute_error(s, cpt_err)
    if cpt_err[1] == :across
        GroupedErrors._across(s, cpt_err[2])
    elseif cpt_err[1] == :bootstrap
        GroupedErrors._bootstrap(s, cpt_err[2])
    else
        error("Compute error $cpt_err not supported")
    end
end

compute_error(s, ::Void) = s

function smoothing_kwargs(a::Analysis)
    iscontinuous(a) || return []
    a.y in colnames(a.data) && return [(:span, (a.smoother+1.0)/100)]
    a.y in [:density, :hazard] && return [(:bandwidth, (a.smoother+1.0)*std(column(a.data, a.x))/200)]
    return []
end

ispointbypoint(a::Analysis) =
    a.axis_type == :pointbypoint || (a.axis_type == :auto) && (a.y in colnames(a.data))

isdiscrete(a::Analysis) =
    a.axis_type == :discrete || (a.axis_type == :auto) && !(eltype(column(a.data, a.x))<:Real)

isbinned(a) = a.axis_type == :binned

iscontinuous(a) = !ispointbypoint(a) && !isdiscrete(a) && !isbinned(a)

function _t(s, f, args...)
    s.x = f
    kws = [:axis_type, :nbins]
	if args == () || isa(args[1], Symbol)
	    for (ind, val) in enumerate(args)
	        s2.kw[kws[ind]] = val
	    end
	else
		s.kw[:xreduce] = functionize(args[1])
	end
    return s
end

function process(::GroupedError, a::Analysis)
    s = GroupedErrors.ColumnSelector(a.data)
    s = GroupedErrors._splitby(s, Symbol[splitby(a)...])
    s = compute_error(s, a.compute_error)
    if !ispointbypoint(a)
        maybe_nbins = isbinned(a) ? (round(Int64, (120-a.smoother)/2),) : ()
        s = GroupedErrors._x(s, a.x, a.axis_type, maybe_nbins...)
        y = a.y in colnames(a.data) ? (:locreg, a.y) : (a.y,)
        s = GroupedErrors._y(s, y...; smoothing_kwargs(a)...)
    else
        s = GroupedErrors._x(s, a.x, a.xfunc)
        s = GroupedErrors._y(s, a.y, a.yfunc)
    end
    plot_closure(args...; kwargs...) = a.plot(args...; kwargs..., a.plot_kwargs...)
    (a.plot == plot) ? @plot(s, plot_closure(), :ribbon) : @plot(s, plot_closure())
end

function REprocess(::GroupedError, a::Analysis)
    s = GroupedErrors.ColumnSelector(a.data)
    s = GroupedErrors._splitby(s, Symbol[splitby(a)...])
    s = compute_error(s, a.compute_error)
    if !ispointbypoint(a)
        maybe_nbins = isbinned(a) ? (round(Int64, (120-a.smoother)/2),) : ()
        if column(a.data, a.y)[1] isa ShiftedArray
            s = _t(s, a.x, a.axis_type, maybe_nbins...)
        else
            s = GroupedErrors._x(s, a.x, a.axis_type, maybe_nbins...)
        end
        y = a.y in colnames(a.data) ? (:locreg, a.y) : (a.y,)
        s = GroupedErrors._y(s, y...; smoothing_kwargs(a)...)
    else
        s = GroupedErrors._x(s, a.x, a.xfunc)
        s = GroupedErrors._y(s, a.y, a.yfunc)
    end
    plot_closure(args...; kwargs...) = a.plot(args...; kwargs..., a.plot_kwargs...)
    (a.plot == plot) ? @plot(s, plot_closure(), :ribbon) : @plot(s, plot_closure())
end
