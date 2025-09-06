library(metabom8)

### reading and processing NMR experiments
exp_dir ='/Users/tk/rproj/rygb_selected/'

read1d_proc(exp_dir, exp_type = list(PULPROG='noesypr1d'))

Xcal = calibrate(X, ppm, type='tsp')
matspec(Xcal, ppm, shift=c(-0.1, 0.1))

idc_water = get_idx(c(4.7, 5.), ppm)
idc_upfield = get_idx(c(min(ppm), 0.25), ppm)
idc_downfield = get_idx(c(10., max(ppm)), ppm)

idc_rm = c(idc_upfield, idc_water, idc_downfield)
Xcut = Xcal[,-idc_rm]
ppmc = ppm[-idc_rm]
spec(Xcut[1,], ppmc, shift=range(ppmc))

Xbl = bline(Xcut)
spec(Xcut[1,], ppmc, shift=range(ppmc))
spec(Xbline[1,], ppmc, shift=range(ppmc), add=T)

X.pqn = pqn(Xbl, bin=NULL)
ppm = ppmc

### import sample annotation data
an_path = file.path(exp_dir, 'annots.csv')
an = read.csv(an_path)


### save list in rdata file
bariatric = list(X.pqn, ppm, meta, an)
save(bariatric, file='bariatric.rdata')
