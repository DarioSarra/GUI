function makeplot_t(df::UI_traces)
        a = Analysis_t(df)
        process(a)
end

function makeplot_b(df::UI_traces)
        a = Analysis_b(df)
        process(a)
end

function makeplot_(df::UI_bhvs)
        a = Analysis(df)
        process(a)
end
