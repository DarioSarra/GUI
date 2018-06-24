mutable struct ManipulableTraces
    sessiondata::Array{Flipping.PhotometryStructure}
    fibers #taken from the data
    tracetype #dictionary of options
    xallignment #dictionary of function
    splitby #dictionary of function
    compute_error #dictionary of function
    plotdata #convertin_ShiftedArray
    plt
    Button
    widget
end

function 

function ManipulableTraces(df::ManipulableTable)
    sessiondata = df
    fibers = dropdown(names(df.subdata[1].traces),label = "Traces")

end
