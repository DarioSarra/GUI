function datatoplot(x_axis, y_axis, t::Array{Flipping.PhotometryStructure},field::Symbol)
    x = Symbol(x_axis)
    y = Symbol(y_axis)
    x_values = []
    y_values =  []
    for i = 1:size(t,1)
        append!(x_values, getfield(t[i],field)[x])
        append!(y_values, getfield(t[i],field)[y])
    end
    return DataFrame(X = x_values, Y = y_values)
end


function makeplot(x_axis, y_axis, t::Array{Flipping.PhotometryStructure},field::Symbol)
        data = datatoplot(x_axis, y_axis, t::Array{Flipping.PhotometryStructure},field::Symbol)
        that = @> data begin
            #@across (_.Session)
            # @splitby (_.Side)
            @x _.X
            @y _.Y
            @plot
    end
end
