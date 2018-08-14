f = Filtering(data[],:pokes)
w = Window()
body!(w, f.widget)
b = Mutable_bhv(f.bhv_data[])
w = Window()
body!(w, b.widget)
##
df = Mutable_trace(f.sub_data[],:pokes)
w = Window()
body!(w, df.widget)
##

##
bA = Analysis(b)
dfA = Analysis(df)
##
process(bA)
##
plot_closure(args...; kwargs...) = bA.plot(args...; kwargs..., a.plot_kwargs...)
(bA.plot == plot) ? @plot(s, plot_closure(), :ribbon) : @plot(s, plot_closure())
##
a = bA
a.y
s = GroupedErrors.ColumnSelector(a.data)
s = GroupedErrors._splitby(s, Symbol[splitby(a)...])
s = compute_error(s, a.compute_error)
maybe_nbins = isbinned(a) ? (round(Int64, (120-a.smoother)/2),) : ()
s = GroupedErrors._x(s, a.x, a.axis_type, maybe_nbins...)
s.x
s.x = 1:100
##
s2 = GroupedErrors.replace_selector(s, 1:10, :x)
##
s = GroupedErrors._x(s, a.x, a.axis_type, maybe_nbins...)
##
function _x(s::AbstractSelector, f, args...)
    s2 = replace_selector(s, f, :x)
    kws = [:axis_type, :nbins]
	if args == () || isa(args[1], Symbol)
	    for (ind, val) in enumerate(args)
	        s2.kw[kws[ind]] = val
	    end
	else
		s2.kw[:xreduce] = functionize(args[1])
	end
    return s2
end
##
function replace_selector(s::S, f, sym::Symbol) where {S<:AbstractSelector}
    fields = fieldnames(s)
    new_fields = Tuple(field == sym ? f : getfield(s, field) for field in fields)
	(S <: Selector) ? Selector(new_fields...) : ColumnSelector(new_fields...)
end
##
function replace_selector(s::S, f::UnitRange{Int64}, sym::Symbol) where {S<:AbstractSelector}
    fields = fieldnames(s)
    new_fields = Tuple(field == sym ? f : getfield(s, field) for field in fields)
	(S <: Selector) ? Selector(new_fields...) : ColumnSelector(new_fields...)
end

##
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
##
@> dfs begin
    @splitby _.Reward
    @across _.MouseID
    @x -100:100 :discrete
    @y _.DRN_sig
    @plot plot() :ribbon
end
