function extract_rawtraces(data::Array{PhotometryStructure}, bhv_type::Symbol)
    provisory = []
    for i = 1:size(data,1)
        if isempty(getfield(data[i],bhv_type))
            continue
        else
            ongoing = extract_rawtraces(data[i],bhv_type)
            if isempty(provisory)
                provisory = ongoing
            else
                provisory = JuliaDB.merge(provisory,ongoing)
            end
        end
    end
    return provisory
end

function extract_rawtraces(data::PhotometryStructure, bhv_type::Symbol)
    bhv_data = getfield(data, bhv_type)
    ongoing = extract_rawtraces(bhv_data,data.traces)
    return ongoing
end

function extract_rawtraces(bhv_data::AbstractDataFrame, traces_data::AbstractDataFrame)
    ongoing = JuliaDB.table(bhv_data)
    for name in names(traces_data)
        provisory = [ShiftedArray(traces_data[name], -i) for i in bhv_data[:In]]
        ongoing = setcol(ongoing, name, provisory)
    end
    return ongoing
end

function normalise(raw_ar,norm_interval,x_interval)
    f0 = mean(raw_ar[norm_interval])
    ar = copy(raw_ar[x_interval])
    ongoing = (ar.-f0)./f0
    return ongoing
end

function collect_view(raw_ar,x_interval)
    ongoing = copy(raw_ar[x_interval])
    return ongoing
end

tuplejoin(t1::Tuple, t2::Tuple, t3...) = tuplejoin((t1..., t2...), t3...)
tuplejoin(t::Tuple) = t
@inline tuplejoin(x) = x
@inline tuplejoin(x, y) = (x..., y...)
@inline tuplejoin(x, y, z...) = tuplejoin(tuplejoin(x, y), z...)


function get_trace(df::Mutable_traces,tracetype)
    y = observe(df.fibers)[]
    x_1 = selecteditems(df.plot_window)[1] #starting index for visualization
    x_2 = selecteditems(df.plot_window)[2] #ending index for visualization
    rate = observe(df.rate)[] #frame per second
    x_interval  = Int64(x_1*rate):Int64(x_2*rate) #visualization range
    if tracetype == "Raw"
        t = @apply df.plotdata[] begin
            @transform {view = collect_view(cols(y),x_interval)}
        end
        t = setcol(t,:trial,collect(1:length(t)))
    elseif tracetype == "Normalised"
        # create normalised data
        norm_1 = selecteditems(df.norm_window)[1] #starting index for normalization
        norm_2 = selecteditems(df.norm_window)[2] #ending index for normalization
        norm_int = Int64(norm_1*rate):Int64(norm_2*rate) #normalization range
        t = @apply df.plotdata[] begin
            @transform {view = normalise(cols(y),norm_int,x_interval)}
        end
        t = setcol(t,:trial,collect(1:length(t)))
    elseif tracetype == "GLM"
        #try
            y_name = String(observe(df.fibers)[])
            yref = Symbol(replace(y_name,"sig","ref",1))
            norm_1 = selecteditems(df.norm_window)[1] #starting index for normalization
            norm_2 = selecteditems(df.norm_window)[2] #ending index for normalization
            norm_int = Int64(norm_1*rate):Int64(norm_2*rate)
            t = @apply df.plotdata[] begin
                @transform {Normalise_sig = normalise(cols(y),norm_int,x_interval)}
                @transform {Normalise_ref = normalise(cols(yref),norm_int,x_interval)}
            end
            t = setcol(t,:trial,collect(1:length(t)))
        # catch
        #     y_name = observe(df.fibers)[]
        #     println("can't find a reference for the selected trace ", y_name)
        #     get_trace(df,"Normalise")
        # end
    end
    return t, x_interval, rate
end

function get_trace(df::Mutable_traces)
    tracetype = observe(df.tracetype)[]
    t = get_trace(df,tracetype)
end

function rotate_shifted(dati_ar::Array,x_interval::Range)
    ongoing = DataFrame(
    frame = collect(x_interval),
    dati = copy(dati_ar))
end

function rotate_shifted(sig_ar::Array,ref_ar::Array,x_interval::Range)
    ongoing = DataFrame(
    frame = collect(x_interval),
    sig = copy(sig_ar),
    ref = copy(ref_ar))
end

function table_data(t,x_interval::Range,tracetype)
    plot_data = []
    reg = tracetype == "GLM"
    if !reg
        for idx = 1:length(t)
            ongoing = rotate_shifted(select(t,:view)[idx],x_interval)
            ongoing[:trial] = idx
            if isempty(plot_data)
                plot_data = ongoing
            else
                append!(plot_data,ongoing)
            end
        end
    elseif reg
        for idx = 1:length(t)
            ongoing = rotate_shifted(select(t,:Normalise_sig)[idx],select(t,:Normalise_ref)[idx],x_interval)
            ongoing[:trial] = idx
            if isempty(plot_data)
                plot_data = ongoing
            else
                append!(plot_data,ongoing)
            end
        end
    end
    return plot_data
end

function table_data(df::Mutable_traces)
    split = Tuple(Symbol.(vcat(observe(df.splitby_cont)[],observe(df.splitby_cat)[]))) #tupla of symbols
    calc_er =   observe(df.compute_error)[]
    error = calc_er == "bootstrap" || calc_er == "all" || calc_er == "none"? () : [Symbol.(observe(df.compute_error)[])]
    info_cols = tuplejoin([:trial],split,error)
    tracetype = observe(df.tracetype)[]
    t,x_interval, rate = get_trace(df,tracetype)
    info_vals = select(t, info_cols)
    data = table_data(t,x_interval,tracetype)
    return data, info_vals, rate
end
