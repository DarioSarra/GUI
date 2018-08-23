traces = []
for i = 1:size(data[],1)
    prova = data[][i];
    prova.streaks[:In]
    trace = [ShiftedArray(prova.traces[:Pokes],-i,default = NaN) for i in prova.streaks[:In]];
    if isempty(traces)
        traces = trace
    else
        traces = vcat(traces,trace)
    end
end
m = reduce_vec(mean,traces,-50:50)
plot(m)
##
p = extract_rawtraces(data[], :streaks,50);
m2 = reduce_vec(mean,select(p,:Pokes),-50:50);
plot(m2)

##
r = [4,7]
d = [3,4]
[(i[1]:i[2]) for i in zip(r,d)]
