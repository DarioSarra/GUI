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

# function filterdf(df::IndexedTables.NextTable, categorical::Array{CategoricalVariable}, continouos::Array{ContinuousVariable})
#     #filter for categorical and continouos variable options
#     subdata = deepcopy(df)
#     active_cat = categorical[find(isselected(categorical))]
#     for c in active_cat # go through every active variable
#         subdata = subdata[in.(select(subdata,c.name),(selecteditems(c),))]
#     end
#     active_con = continouos[find(isselected(continouos))]
#     for c in active_con
#         subdata = subdata[select(subdata,c.name).>= observe(c.start)[]]
#         subdata = subdata[select(subdata,c.name).<= observe(c.stop)[]]
#     end
#     return subdata
# end

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

# function filterdf(df::IndexedTables.NextTable, categorical::Array{CategoricalVariable})
#     #filter for categorical and continouos variable options
#     subdata = deepcopy(df)
#     active_cat = categorical[find(isselected(categorical))]
#     for c in active_cat # go through every active variable
#         subdata = subdata[in.(select(subdata,c.name),(selecteditems(c),))]
#     end
#     return subdata
# end
#
# function filterdf(df::IndexedTables.NextTable, continouos::Array{ContinuousVariable})
#     #filter for categorical and continouos variable options
#     subdata = deepcopy(df)
#     active_con = continouos[find(isselected(continouos))]
#     for c in active_con
#         subdata = subdata[select(subdata,c.name).>= observe(c.start)[]]
#         subdata = subdata[select(subdata,c.name).<= observe(c.stop)[]]
#     end
#     return subdata
# end

# function filtra(df::IndexedTables.NextTable,var::AbstractVariable)
#     subdata = deepcopy(df)
#     if typeof(var) == CategoricalVariable
#         println("type of var categorical")
#         subdata = subdata[in.(select(subdata,var.name),(selecteditems(var),))]
#     elseif typeof(var) == ContinuousVariable
#         println("type of var continuous")
#         subdata = subdata[select(subdata,var.name).>= observe(var.start)[]]
#         subdata = subdata[select(subdata,var.name).<= observe(var.stop)[]]
#     else
#         println("type of var not recognised")
#     end
#     return subdata
# end
