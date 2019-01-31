const plot_dict = OrderedDict(
    "line plot" => plot,
    "scatter" => scatter,
    "bar" => groupedbar)
    #"boxplot" => boxplot,
    #"violin" => violin,
    #"histogram2d" => histogram2d,
    #"marginalhist" => marginalhist)

const saved_plot_analysis = ["density", "cumulative", "hazard"]

const x_type_dict = OrderedDict(
    "auto" => :auto,
    "discrete" => :discrete,
    "continuous" => :continuous)

const tracetype_dict = OrderedDict(
    "Raw" => "Raw",
    "Normalised" => "Normalised",
    "GLM" => "GLM")
