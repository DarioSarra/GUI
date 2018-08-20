"""
'calc_f0'
"""
function calc_f0(bhv_kind::Symbol,norm_window::Range,or_data::IndexedTables.NextTable)
    if bhv_kind == :streaks
        f0 = NaNMath.mean(raw_ar[norm_interval])
    elseif bhv_kind == :pokes
        
    end
end

"""
Add normalised traces to Indexed table
"""

function normalise(or_data::IndexedTables.NextTable, norm_interval::Range)
    lista = String.(colnames(or_data))
    selection = lista[contains.(lista,"_sig") | contains.(lista,"_ref") | contains.(lista,"Pokes")]
    columns = Symbol.(selection)
end

function normalise(raw_ar::ShiftedArray,norm_interval::Range)
    f0 = NaNMath.mean(raw_ar[norm_interval])
    normalised = (raw_ar-f0)/f0
end
