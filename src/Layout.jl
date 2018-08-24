function adjust_layout!(w)
    v = props(InteractBase.scope(w).dom)[:attributes]
    println(typeof(v))
    props(InteractBase.scope(w).dom)[:attributes] =
        merge(Dict(v),
        Dict("style" => "flex: 0 1 auto; display:flex; margin: 0; flex-wrap: wrap;"))
    w
end
