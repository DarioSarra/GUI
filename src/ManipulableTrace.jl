mutable struct ManipulableTrace
    bhv_type
    data  #::Array{Flipping.PhotometryStructure}
    subdata
    rate
    fibers #taken from the data
    tracetype #dictionary of options
    x_allignment #dictionary of function
    splitby #dictionary of function
    compute_error #dictionary of function
    norm_window
    plot_window
    #plotdata #convertin_ShiftedArray
    plt
    Button
    widget
end

function ManipulableTrace(df::ManipulableTable)
    bhv_type = df.bhv_type
    Button = button("Plot");
    plotter = observe(Button)
    data = map(t -> filterdf(df.subdata,df.categorical,df.continouos,df.bhv_type),plotter)
    rate = spinbox(value = 50,label ="Frames per second")
    fibers = dropdown(names(df.subdata[1].traces),label = "Traces")
    trace_type = dropdown(tracetype_dict,label = "Trace Type")
    x_allignment_dict = get_option_allignments(data[],df.bhv_type)
    x_allignment = dropdown(x_allignment_dict, label = "Allign on")
    cat, con = distinguish(data[],bhv_type)
    cat_dict = OrderedDict()
    for i in cat
        cat_dict[String(i)] = i
    end
    categorical, continouos = distinguish(data[],bhv_type)
    splitby = checkboxes(cat_dict,label="Split by categorical")
    compute_error = df.compute_error
    norm_window = ContinuousVariable(:NormalisationPeriod,-1.5,-0.5) #use function selecteditems to retrieve values
    plot_window = ContinuousVariable(:VisualisationPeriod,-2,2) #use function selecteditems to retrieve values
    plt = Observable{Any}(plot(rand(10)))
    subdata = map(t->filter_norm_window(data[],norm_window,rate),plotter)
    #plotdata
    widget = hbox(vbox(Button,compute_error,rate),splitby,
    vbox(hbox(norm_window.widget,plot_window.widget),
    plt,
    hbox(trace_type,fibers,x_allignment)))
    mtr = ManipulableTrace(
    bhv_type,
    data,
    subdata,
    rate,
    fibers,
    trace_type,
    x_allignment,
    splitby,
    compute_error,
    norm_window,
    plot_window,
    #plotdata,
    plt,
    Button,
    widget)
    #map!(t -> makeplot(mtr), plt, subdata)
    mtr
end


function process_traces(df::ManipulableTrace)
    bhv_type = df.bhv_type
    data = df.subdata
    trace_type = observe(df.trace_type)[]
    trace = observe(df.fibers)[]
    VisW = selecteditems(df.plot_window)
    rate = observe(df.rate)[]
    splitby = Symbol.(observe(df.splitby)[])
    # create new splitting system
    #once identified cat and con for con apply custom bin function
    for d in data
        ongoing = extract_traces(d,bhv_type,trace,VisW,rate)
    end
    result = DataFrame()
    for i = 1:size(sa,1)
        if tracetype == "Raw"
            return traces[Symbol(fiber)]
        elseif tracetype == "Normalised"
            for i = 1 size(bhv)
                start = bhv[i,:In] + NormW[1]
                stop = bhv[i,:In] + NormW[2]
                corr_range = start:stop
                v = mean(traces[corr_range,Symbol(fiber)])
                provisory = DataFrame(Trace = traces[bhv[i,:In]:bhv[i,:Out],Symbol(fiber)]./v)
                if isempty(result)
                    result = provisory
                else
                    append!(result,provisory)
                end
            end
            result
        end
    end
end


function convert_traces(df::DataFrame,splitby,sa::Array{ShiftedArray},VisW)
    coll_range = VisW[1]:VisW[2]
    provisory = DataFrame()
    if size(df,1) != size(sa,1)
        error("non matching data between bhv and collected shifted array")
    end
    for i = 1:size(df,1)
        trial = sar[i][coll_range]
        ongoing = DataFrame(trace = trial,time = 1:size(trial,1))
        for col in splitby#splitby needs to be a tuple of symbols
            ongoing[col] = df[i,col]
        end
        if isempty(provisory)
            provisory = ongoing
        else
            append!(provisory,ongoing)
        end
    end
    #converted = JuliaDB.table(provisory)
    return provisory
end




function adjust_F0(df::ManipulableTrace)
    start,stop = selecteditems(df.norm_window)
    rate = observe(df.rate)
    for t =1:size(df.subdata[],1)
        adjust_F0(df.subdata[][t],start,stop,rate)
    end
end

function adjust_F0(df::PhotometryStructure,start::Float64, stop::Float64,rate)
    println(size(df.traces))
    Cols = df.traces[].names
    Columns = string.(Cols);
    traces = Columns[contains.(Columns,"_sig").|contains.(Columns,"_ref")]
    for trace in traces
        for trial = 1 size(df.straks)
        end
    end
end


function extract_traces(data::AbstractDataFrame, trace::Symbol, allignment,VisW,rate)
    start,stop = selecteditems(VisW)
    pace = observe(df.rate)[]
    start = allignment+(start*pace)
    stop = allignment+(stop*pace)
    collecting = start:stop
    Shiftedtrial = ShiftedArray(data[trace], - allignment, default = NaN)
end



function extract_traces(data::Flipping.PhotometryStructure,bhv_type::Symbol, trace::Symbol,VisW::ContinuousVariable,rate)
    bhv = getfield(data,bhv_type)
    provisory = Array{ShiftedArray}(0)
    for i = 1:size(bhv,1)
        allignment = bhv[i,:In]
        ongoing = extract_traces(data.traces,trace,allignment,VisW,rate)
        push!(provisory,ongoing)
    end
    provisory = convert(Array{typeof(provisory[1])},provisory)
end

function normalise_DeltaF0(data::Flipping.PhotometryStructure,bhv_type::Symbol, trace::Symbol,Norm_window::ContinuousVariable,VisW::ContinuousVariable,rate)
    df = extract_traces(data::Flipping.PhotometryStructure,bhv_type::Symbol, trace::Symbol,VisW::ContinuousVariable,rate)
    normalise = normalise_DeltaF0(df,Norm_window::ContinuousVariable, rate)
end

function normalise_DeltaF0(df,Norm_window::ContinuousVariable, rate)
    start,stop = selecteditems(Norm_window)
    pace = observe(rate)[]
    start = Int64(start*pace)
    stop = Int64(stop*pace)
    corr_range = start:stop
    provisory = Array{ShiftedArray}(0)
    for idx =1:size(df,1)
        f0 = mean(df[idx][start:stop])
        ar = df[idx].parent
        ar = (ar-f0)/f0
        sh = df[idx].shifts[1]
        ongoing = ShiftedArray(ar, sh, default = NaN)
        push!(provisory,ongoing)
    end
    provisory = convert(Array{typeof(provisory[1])},provisory)
    return provisory
end

"""
`Normalise_GLM`
"""

function  Normalise_GLM(data::Flipping.PhotometryStructure,bhv_type::Symbol, trace::Symbol,VisW::ContinuousVariable,Norm_window::ContinuousVariable,rate)
    shift_raw_sig = extract_traces(data,bhv_type,trace,df.plot_window,rate)
    trace_sig_name = String(trace)
    trace_ref_name = replace(trace_sig_name,"sig","ref")
    trace_ref = Symbol(trace_ref_name)
    shift_raw_ref = extract_traces(data,bhv_type,trace_ref,df.plot_window,rate)
    shift_norm_sig = normalise_DeltaF0(shift_raw_sig,Norm_window::ContinuousVariable, rate)
    shift_norm_ref = normalise_DeltaF0(shift_raw_ref,Norm_window::ContinuousVariable, rate)
    Reg_norm = Normalise_GLM(shift_norm_sig,shift_norm_ref)
end


function  Normalise_GLM(shifted_sig,shifted_ref)
    prov = DataFrame()
    sig_vector = Union{Float64,Missing}[]
    ref_vector = Union{Float64,Missing}[]
    for i = 1:size(shifted_sig,1)
        append!(sig_vector, shifted_sig[i].parent)
        append!(ref_vector, shifted_ref[i].parent)
    end
    prov = DataFrame(Sig=sig_vector,Ref = ref_vector)
    filter = .!ismissing.(sig_vector)
    OLS = lm(@formula(Sig ~ 0 + Ref), prov[filter,:])
    coefficient = coef(OLS)
    prov = DataFrame(Sig=sig_vector,Ref = ref_vector)
    filter = .!ismissing.(sig_vector)
    OLS = lm(@formula(Sig ~ 0 + Ref), prov[filter,:])
    coefficient = coef(OLS)
    Reg_norm =  Array{Any}(size(shifted_sig,1))
    for i in 1:size(shifted_sig,1)
        value = @.(shifted_sig[i].parent-shifted_ref[i].parent*coefficient)
        shift = shifted_sig[i].shifts[1]
        Reg_norm[i] = ShiftedArray(value,shift)
    end
    Reg_norm = convert(Array{typeof(Reg_norm[1])},Reg_norm)
    return Reg_norm
end
