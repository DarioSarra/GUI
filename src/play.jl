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
bA = Analysis(b)
dfA = Analysis(df)
##
a = bA
a.y
s = GroupedErrors.ColumnSelector(a.data)
s = GroupedErrors._splitby(s, Symbol[splitby(a)...])
s = compute_error(s, a.compute_error)
maybe_nbins = isbinned(a) ? (round(Int64, (120-a.smoother)/2),) : ()
s = GroupedErrors._x(s, a.x, a.axis_type, maybe_nbins...)
##
isdefined(column(a.data, a.y))
column(a.data, a.y)[1] isa ShiftedArray
column(a.data, :Reward)
##
bP = process(bA)
bP
##
selecteditems(df.plot_window)[1]:selecteditems(df.plot_window)[2]
-2:2
##
x = Symbol.(observe(df.splitby_cont)[])
if !isempty(x)
    for i = 1:size(x,1)
        bin = observe(b.bins)[]
        data = JuliaDBMeta.@with data setcol(_, x[i], CategoricalArrays.cut(cols(x[i]),bin))
    end
end
##
splitBy = Tuple(vcat(observe(df.splitby_cont)[],observe(df.splitby_cat)[]))
splitBy = Symbol.(splitBy)
pace = observe(df.rate)[]
fib = observe(df.fibers)[]
start = selecteditems(df.plot_window)[1]*pace
stop = selecteditems(df.plot_window)[2]*pace
window = start:stop
letsee = @apply df.plotdata[] splitBy begin
    JuliaDBMeta.@map collect(cols(fib)[window])
end
##
select(df.plotdata[],:Reward)

##
JuliaDBMeta.@map df.plotdata[] collect(cols(fib)[window])
##
dfs = df.plotdata[]
##
@> dfs begin
    @splitby _.Reward
    @across _.MouseID
    @x -100:100 :discrete
    @y _.DRN_sig
    @plot plot() :ribbon
end
