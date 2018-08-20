const plot_dict = OrderedDict(
    "line plot" => plot,
    "scatter" => scatter,
    "bar" => groupedbar,
    #"boxplot" => boxplot,
    #"violin" => violin,
    #"histogram2d" => histogram2d,
    #"marginalhist" => marginalhist,
)

const x_type_dict = OrderedDict(
    "auto" => :auto,
    "discrete" => :discrete,
    "continouos" => :continouos,
)

const tracetype_dict = OrderedDict(
    "Raw" => "Raw",
    "Normalised" => "Normalised",
    "GLM" => "GLM"
    )
