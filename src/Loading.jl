filepath = filepicker();
filename = observe(filepath);
dir = dirname(observe(filepath)[])
data = Observable{Any}(IndexedTables.NextTable)
map!(carica, data, filename)
filestuff = hbox(filepath)
w = Window()
body!(w, filestuff)
