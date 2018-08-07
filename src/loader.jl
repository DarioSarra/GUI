filepath = filepicker();
filename = observe(filepath);

initial = DataFrame(categorical = [true, false], continouos = [1,2],
In = [1,2], Out = [1,2], Streak_n = [1,2])
initialtrace = DataFrame(Sig = [1,2,3], Ref = [1,2,3])
fillerPhoto=PhotometryStructure(initial,initial,initialtrace)
filler= [fillerPhoto,fillerPhoto]

data = Observable{Any}(Array{PhotometryStructure, 1}(0))
data[] = filler
map!(carica, data, filename)


messageboard = textbox("now what");
message = observe(messageboard);
