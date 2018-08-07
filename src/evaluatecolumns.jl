function distinguish(data::IndexedTables.NextTable)
    print("YEP")
    categorical_vars = []
    continuous_vars = []
    for x in colnames(data)
        if x == :PokeSequence
            continue
        elseif !(eltype(select(data,x)) <: Real) || (eltype(select(data,x)) == Bool)
            push!(categorical_vars,x)
        else
            push!(continuous_vars,x)
        end
    end
    return categorical_vars, continuous_vars
end

function distinguish(data::Array{PhotometryStructure,1},field::Symbol)
    println("processing variables")
    set = getfield(data[1],field)
    categorical_vars = []
    continuous_vars = []
    for x in names(set)
        if x == :PokeSequence
            continue
        elseif !(eltype(set[Symbol(x)]) <: Real) || (eltype(set[Symbol(x)]) == Bool)
            push!(categorical_vars,Symbol(x))
        else
            push!(continuous_vars,Symbol(x))
        end
    end
    return categorical_vars, continuous_vars
end

function buildvars(data::Array{PhotometryStructure,1},field::Symbol)
    cat, con = distinguish(data,field)
    names = vcat(cat,con)
    categorical_vars = Array{CategoricalVariable,1}(0)
    continuous_vars = Array{ContinuousVariable,1}(0)
    for x in cat
        values = unique(data,x,field)
        push!(categorical_vars,CategoricalVariable(x, values))
    end
    for x in con
        lowest = minimum(data,Symbol(x),field)
        highest = maximum(data,Symbol(x),field)
        push!(continuous_vars,ContinuousVariable(Symbol(x), lowest,highest))
    end
    return categorical_vars, continuous_vars, names
end


function list_selectors(Variables::AbstractVariable)
    vars = []
    for i = 1:size(Cat_list[],1)
        if isselected(Cat_list[][i])
            push!(vars,i)
        end
    end
    return(vars)
end
