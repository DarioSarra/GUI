function distinguish(data::IndexedTables.IndexedTable)
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

function buildvars(data::IndexedTables.IndexedTable)
    cat, con = distinguish(data)
    buildvars(cat, con, data)
end

function buildvars(cat::Array{Any}, con::Array{Any}, data::IndexedTables.IndexedTable)
    # categorical_vars = Array{CategoricalVariable,1}(0)
    # continuous_vars = Array{ContinuousVariable,1}(0)
    categorical_vars = Array{CategoricalVariable,1}(undef,0)
    continuous_vars = Array{ContinuousVariable,1}(undef,0)
    for x in cat
        values = unique(select(data,x))
        push!(categorical_vars,CategoricalVariable(x, values))
    end
    for x in con
        # mask = @. !isnan.(select(data,x))
        mask = .!isnan.(select(data,x))
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

function filterdf(df::IndexedTables.IndexedTable, categorical::Array{CategoricalVariable}, continouos::Array{ContinuousVariable})
    #filter for categorical and continouos variable options
    mask = map(t->true, df)
    active_cat = categorical[findall(isselected(categorical))]
    for c in active_cat # go through every active variable
        mask .&= in.(select(df,c.name),(selecteditems(c),))
    end
    active_con = continouos[findall(isselected(continouos))]
    for c in active_con
        mask .&= observe(c.start)[] .<= select(df,c.name).<= observe(c.stop)[]
    end
    return df[mask]
end

function filterdf(df::IndexedTables.IndexedTable,observation::Tuple{Array{CategoricalVariable,1},Array{ContinuousVariable,1}})
    filterdf(df,observation[1],observation[2])
end

function categorize(t::IndexedTables.IndexedTable,what::Symbol,n_of_bins)
    ongoing = sort(t, what)
    ongoing = pushcol(ongoing, :cumulative, collect(1:size(columns(ongoing,what),1)))
    binsize = maximum(columns(ongoing,:cumulative))/n_of_bins
    ongoing = pushcol(ongoing,:pre_bin,floor.(columns(ongoing,:cumulative)./binsize))
    result = @apply ongoing begin
        @transform_vec what flatten=true begin
            if length(union(:pre_bin))>1
                count = [length(@filter :pre_bin == x for x in union(:pre_bin))]
                idx = findmax(count)[2]
                {proto_binned = fill(union(:pre_bin)[idx], length(_))}
            else
                {proto_binned = :pre_bin}
            end
        end
        @transform_vec  (:proto_binned) flatten=true begin
            start = cols(what)[1]
            stop = cols(what)[end]
            bin_range = string(start)*":"*string(stop)
            {binned = fill(bin_range, length(cols(what)))}
        end
    end
    dict_tab = @groupby result what {lemma = union(:binned)[1]}
    dict = Dict(select(dict_tab,what)[i] => select(dict_tab,:lemma)[i] for i = 1:length(dict_tab))
end

function categorize_cols(t::IndexedTables.IndexedTable, s::AbstractVector{<:Symbol}, bin::Integer)
    for i = 1:length(s)
        vocabulary = GUI.categorize(t, s[i],bin)
        #binned = map(x->get(vocabulary,x,0),select(t,s[i]))
        binned = @map t get(vocabulary,cols(s[i]),0)
        t = setcol(t, s[i],binned)
    end
    return t
end
