function makeplot(df::ManipulableTable)
        a = Analysis(df)
        process(a)
end

function makeplot(df::ManipulableTrace)
        a = Analysis(df)
        process(a)
end

function makeplot(df::Mutable_bhvs)
    a = Analysis(df)
    process(a)
end

function makeplot(df::Mutable_traces)
    a = Analysis(df)
    process(a)
end
