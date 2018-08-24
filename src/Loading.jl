filepath = filepicker();
filename = observe(filepath);
dir = dirname(observe(filepath)[])
map!(carica, data, filename)
filestuff = hbox(filepath)
w = Window()
body!(w, filestuff)
