function makeplot(df::ManipulableTable)
        a = Analysis(df)
        process(a)
end

function makeplot(df::ManipulableTrace)
        a = Analysis(df)
        process(a)
end
