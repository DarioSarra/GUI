abstract type AbstractVariable; end

mutable struct CategoricalVariable<:AbstractVariable
    name::Symbol
    widget
    items
end

function CategoricalVariable(name::Symbol, values::Vector; vskip = 0em, kwargs...)
    cb = checkboxes(values, value = values)
    ui = togglecontent(cb, label = string(name); vskip=vskip, kwargs...)
    CategoricalVariable(name, ui, cb)
end

selecteditems(col::CategoricalVariable) = observe(col.items)[]
isselected(col::CategoricalVariable) = observe(col.widget)[]

mutable struct ContinuousVariable<:AbstractVariable
    name::Symbol
    widget
    start
    stop
end

function ContinuousVariable(name::Symbol, lowest,highest,; vskip = 0em, kwargs...)
    start = spinbox(lowest:highest,label = "min";value = lowest)
    stop = spinbox(lowest:highest,label = "max";value = highest)
    ui = togglecontent(vbox(start,stop),label = string(name))
    ContinuousVariable(name, ui, start, stop)
end

selecteditems(col::ContinuousVariable) = (observe(col.start)[],observe(col.stop)[])
isselected(col::ContinuousVariable) = observe(col.widget)[]

function isselected(ar::AbstractArray{<:AbstractVariable})
    selected = []
    for i=1:size(ar,1)
        push!(selected,isselected(ar[i]))
    end
    return selected
end



name(s::CategoricalVariable) = s.name
name(s::ContinuousVariable) = s.name

name(s::T) where {T<:AbstractVariable} =
    error("No name method specified for AbstractVariable $T")

#=predicate only takes the selected values of a checkboxes so that operation run
on a CategoricalVariable would only take in to account the selected values=#
function predicate(s::CategoricalVariable)
    sel_items = selecteditems(s)
    t -> t in sel_items
end

# function predicate(s::ContinuousVariable)
#     sel_items = selecteditems(s)
#     t -> t >= sel_items[1] & t <= sel_items[2]
# end

predicate(s::T) where {T<:AbstractVariable} =
    error("No predicate method specified for AbstractVariable $T")



function Base.filter(vars::AbstractArray{<:AbstractVariable}, t::DataFrames.AbstractDataFrame)
    sel_idx = fill(true, length(t))
    for var in vars
        map!(var, sel_idx, t)
    end
    t[sel_idx]
end

function Base.filter(vars::AbstractArray{<:AbstractVariable}, data::Array{Flipping.PhotometryStructure,1})
    collection = []
    for session in data
        session.pokes = filter(vars, session.pokes)
        session.streaks = filter(vars,session.streaks)
        push!(collection,session)
    end
    return(collection)
end

Base.map(var::AbstractVariable, v) = map(predicate(var), v)
Base.map(var::AbstractVariable, v::DataFrame) =
    map(var, column(v, name(var)))

Base.map!(var::AbstractVariable, w, v) = map!(predicate(var), w, v)
Base.map!(var::AbstractVariable, w, v::DataFrames.AbstractDataFrame) =
    map!(var, w, column(v, name(var)))

layout(c::AbstractVariable) = dom"div.column"(c.widget)
layout(cs::AbstractArray{<:AbstractVariable}) = node(:div, className = "column")(layout.(cs)...)

##(var::AbstractVariable)(x) = predicate(var)(x)
