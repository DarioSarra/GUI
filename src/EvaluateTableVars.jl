function distinguish(data::IndexedTables.NextTable)
    categorical_vars = []
    continuous_vars = []
    for x in colnames(data)
        if x == :PokeSequence
            continue
        elseif eltype(select(data,x)) <: ShiftedArray
            continue
        elseif !(eltype(select(data,x)) <: Real) || (eltype(select(data,x)) == Bool)
            push!(categorical_vars,x)
        else
            push!(continuous_vars,x)
        end
    end
    return categorical_vars, continuous_vars
end

function buildvars(data::IndexedTables.NextTable)
    cat, con = distinguish(data)
    buildvars(cat, con, data)
end

function buildvars(cat::Array{Any}, con::Array{Any}, data::IndexedTables.NextTable)
    categorical_vars = Array{CategoricalVariable,1}(0)
    continuous_vars = Array{ContinuousVariable,1}(0)
    for x in cat
        values = unique(select(data,x))
        push!(categorical_vars,CategoricalVariable(x, values))
    end
    for x in con
        mask = @. !isnan.(select(data,x))
        lowest = minimum(select(data,x)[mask])
        highest = maximum(select(data,x)[mask])
        push!(continuous_vars,ContinuousVariable(Symbol(x), lowest,highest))
    end
    return categorical_vars, continuous_vars
end

function filterdf(data::UI_traces)
    df = data.or_data
    categorical = data.select_cat
    continouos = data.select_cont
    filterdf(df, categorical, continouos)
end

function filterdf(data::UI_bhvs)
    df = data.or_data
    categorical = data.select_cat
    continouos = data.select_cont
    filterdf(df, categorical, continouos)
end

function filterdf(df::IndexedTables.NextTable, categorical::Array{CategoricalVariable}, continouos::Array{ContinuousVariable})
    #filter for categorical and continouos variable options
    mask = map(t->true, df)
    active_cat = categorical[find(isselected(categorical))]
    for c in active_cat # go through every active variable
        mask .&= in.(select(df,c.name),(selecteditems(c),))
    end
    active_con = continouos[find(isselected(continouos))]
    for c in active_con
        mask .&= observe(c.start)[] .<= select(df,c.name).<= observe(c.stop)[]
    end
    return df[mask]
end

function filterdf(df::IndexedTables.NextTable,observation::Tuple{Array{CategoricalVariable,1},Array{ContinuousVariable,1}})
    filterdf(df,observation[1],observation[2])
end

function categorize(t::IndexedTables.NextTable,what::Symbol,n_of_bins)
    ongoing = sort(t, what)
    ongoing = pushcol(ongoing, :cumulative, collect(1:size(columns(ongoing,what),1)))
    binsize = maximum(columns(ongoing,:cumulative))/n_of_bins
    ongoing = pushcol(ongoing,:pre_bin,floor.(columns(ongoing,:cumulative)./binsize))
    result = @apply ongoing begin
        @transform_vec  (:pre_bin) flatten=true begin
            start = cols(what)[1]
            stop = cols(what)[end]
            bin_range = string(start)*":"*string(stop)
            {proto_binned = fill(bin_range, length(cols(what)))}
        end
        @transform_vec what flatten=true begin
            if length(union(:proto_binned))>1
                count = [length(@filter :proto_binned == x for x in union(:proto_binned))]
                idx = findmax(count)[2]
                {binned = fill(union(:proto_binned)[idx], length(_))}
            else
                {binned = :proto_binned}
            end
        end
    end
    dict_tab = @groupby result what {lemma = union(:binned)[1]}
    dict = Dict(select(dict_tab,what)[i] => select(dict_tab,:lemma)[i] for i = 1:length(dict_tab))
end
