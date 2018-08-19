"""
`convertin`
convert an Array of PhotometryStructure to a Indexed table
"""
function convertin(data::Array{Flipping.PhotometryStructure},field::Symbol)
    provisory = DataFrame()
    for i = 1:size(data,1)
        t = deepcopy(getfield(data[i],field))
        if isempty(provisory)
            provisory = t
        else
            Flipping.concat_data!(provisory,t)
        end
    end
    converted = JuliaDB.table(provisory)
    return converted
end


"""
'extract_rawtraces'
"""
function extract_rawtraces(data::Observable, bhv_type::Symbol,shift::Widget)
    o_data = observe(data)[]
    o_shift = Symbol(observe(shift)[])
    extract_rawtraces(o_data, bhv_type,o_shift)
end

function extract_rawtraces(data::Array{PhotometryStructure}, bhv_type::Symbol,shift::Symbol)
    provisory = []
    for i = 1:size(data,1)
        if isempty(getfield(data[i],bhv_type))
            continue
        else
            ongoing = extract_rawtraces(data[i],bhv_type,shift)
            if isempty(provisory)
                provisory = ongoing
            else
                provisory = JuliaDB.merge(provisory,ongoing)
            end
        end
    end
    return provisory
end

function extract_rawtraces(data::PhotometryStructure, bhv_type::Symbol,shift::Symbol)
    bhv_data = getfield(data, bhv_type)
    ongoing = extract_rawtraces(bhv_data,data.traces,shift)
    return ongoing
end

function extract_rawtraces(bhv_data::AbstractDataFrame, traces_data::AbstractDataFrame,shift::Symbol)
    ongoing = JuliaDB.table(bhv_data)
    col = Array{ShiftedArrays.ShiftedArray{Float64,Missings.Missing,1,Array{Float64,1}}}(size(bhv_data,1))
    for name in names(traces_data)
        next = bhv_data[2,:In]
        adjusted = bhv_data[1,:In]
        provisory = ShiftedArray(copy(traces_data[1:next,name]), - adjusted)
        col[1] = provisory
        previous = bhv_data[end-1,:Out]
        adjusted = bhv_data[end,:In] - previous
        provisory = ShiftedArray(copy(traces_data[previous:end,name]), - adjusted)
        col[end] = provisory
        for i = 2:size(bhv_data,1)-1
            previous = bhv_data[i-1,:Out]
            next = bhv_data[i+1,:In]
            adjusted = bhv_data[i,:In] - previous
            provisory = ShiftedArray(copy(traces_data[previous:next,name]), - adjusted)
            col[i] = provisory
        end
        ongoing = setcol(ongoing, name, col)
    end
    return ongoing
end
function extract_rawtraces_bho(bhv_data::AbstractDataFrame, traces_data::AbstractDataFrame,shift::Symbol)
    ongoing = JuliaDB.table(bhv_data)
    ns = names(traces_data)
    ts = [table((ShiftedArray(traces_data[name], -i) for name in ns)...; names = ns, copy=false) for i in bhv_data[shift]];
    println(size(ts))
    @transform_vec ongoing {tracce = ts};
end
