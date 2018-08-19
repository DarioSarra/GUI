bhv_type = :pokes
or_data = map(t->convertin(t,:pokes),data)
PLT_button = button("Plot")

# cat_n, con_n = distinguish(or_data[])
# categorical, continouos = buildvars(cat_n, con_n, or_data[])
categorical, continuous = buildvars(or_data[])
# obs = map(t->buildvars(t),or_data)
# categorical, continuous = map(t->t[1], obs), map(t->t[2], obs)
filt_widg = hbox(layout(categorical),layout(continuous))
filt_data = map(t->filterdf(or_data[],categorical,continuous),observe(PLT_button))
# subdata = map(t -> filterdf(data,categorical,continouos),filter)
ui = hbox(PLT_button,filt_widg)
w = Window()
body!(w, ui)

##
unique(select(filt_data[],:Reward))
##

#filt_data = map(t-> filterdf(or_data[],t),obs)
filt_data = Observable{Any}
map!(t->filterdf(or_data,obs),filt_data,plt)



filterdf(or_data[],obs[])
map(t->filterdf(or_data[],t),categorical)
filt_data = map(t->filterdf(or_data[],t),continuous)


unique(select(filt_data[],:Reward))
