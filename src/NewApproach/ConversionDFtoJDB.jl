"""
`convertin`
convert an Array of PhotometryStructure to a Indexed table
"""
function convertin(data::Array{Flipping.PhotometryStructure},field::Symbol)
    provisory = DataFrame()
    for i = 1:size(data,1)
        ongoing = deepcopy(getfield(data[i],field))
        if isempty(provisory)
            provisory = ongoing
        else
            Flipping.concat_data!(provisory,ongoing)
        end
    end
    converted = JuliaDB.table(provisory)
    return converted
end


"""
'extract_rawtraces' into shifted arrays and convert an Array of PhotometryStructure to a Indexed table
"""
function extract_rawtraces(data::Observable, bhv_type::Symbol,fps::Widget{:spinbox})
    o_data = observe(data)[]
    o_fps = observe(fps)[]
    extract_rawtraces(o_data, bhv_type,o_fps)
end

function extract_rawtraces(data::Array{PhotometryStructure}, bhv_type::Symbol,fps::Int64)
    provisory = []
    for i = 1:size(data,1)
        # if isempty(getfield(data[i],bhv_type))
        #     continue
        # else
            ongoing = extract_rawtraces(data[i],bhv_type,fps)
            if isempty(provisory)
                provisory = ongoing
            else
                try
                    provisory = JuliaDB.merge(provisory,ongoing)
                catch
                    println("impossible to merge session ",select(ongoing,:Session)[1])
                    println("index of data is ", i)
                end
            end
        # end
    end
    return provisory
end

function extract_rawtraces(data::PhotometryStructure, bhv_type::Symbol,fps::Int64)
    bhv_data = getfield(data, bhv_type)
    ongoing = extract_rawtraces(bhv_data,data.traces,fps)
    return ongoing
end

function extract_rawtraces(bhv_data::AbstractDataFrame, traces_data::AbstractDataFrame,fps::Int64)
    ongoing = JuliaDB.table(bhv_data)
    trial_range = []
    trial_start = []
    trial_end = []
    t_range = bhv_data[1,:In]-2*observe(fps)[]:bhv_data[1,:Out]
    push!(trial_range,t_range)
    t_start = bhv_data[1,:In] - t_range[1]
    t_stop = bhv_data[1,:Out] - t_range[1]
    push!(trial_start,t_start)
    push!(trial_end,t_stop)
    for idx = 2:size(bhv_data,1)
        t_range = bhv_data[idx-1,:Out]+1:bhv_data[idx,:Out]
        t_start = bhv_data[idx,:In] - t_range[1]
        t_stop = bhv_data[idx,:Out] - t_range[1]
        push!(trial_range,t_range)
        push!(trial_start,t_start)
        push!(trial_end,t_stop)
    end
    ongoing = setcol(ongoing, :In, trial_start)
    ongoing = setcol(ongoing, :Out, trial_end)
    for name in names(traces_data)
        provisory = [ShiftedArray(traces_data[name], -i,default = NaN) for i in select(ongoing,:In)]
        ongoing = setcol(ongoing, name, provisory)
    end
    return ongoing
end
