## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(message = FALSE, warning = FALSE)
mm8_available <- requireNamespace("metabom8", quietly = TRUE)


## ----eval=FALSE---------------------------------------------------------------
# # Install from Bioconductor
if (!require("BiocManager")) install.packages("BiocManager")
library(ExperimentHub)
library(nmrdata)

eh <- ExperimentHub()   # indexes available resources and sets up a local cache
query(eh, "nmrdata")

## ----load-processed, eval=TRUE-----------------------------------------------
library(ExperimentHub)

# indexes available resources and sets up a local cache
eh <- ExperimentHub()
query(eh, "nmrdata")

# load pre-processed NMR data (`bariatric`)
bariatric <- eh[['EH9905']]
str(bariatric, max.level = 1)

# visualise a single spectrum
plot(bariatric$ppm, bariatric$X.pqn[1, ], type = "l",
     xlab = "Chemical shift (ppm)", ylab = "Intensity")

# sample annotation data
head(bariatric$an)

# TopSpin acquisition and processing status parameters
print(colnames(bariatric$meta))


## ----raw-dir, eval=TRUE------------------------------------------------------
library(nmrdata)

# load raw 1D NMR experiment data
exp_dir <- getRawExpDir(quiet = TRUE)
list.files(exp_dir, recursive = TRUE)[1:10]

# experiment data are located in path `exp_dir` and can be
# imported and further processed with the library `metabom8` (pronounced me-ta-bo-mate)

## ----mm8-import, eval=mm8_available-------------------------------------------
# Example import `metabom8`
library(metabom8)

# import noesypr1d
read1d_proc(exp_dir, exp_type=list(PULPROG='noesypr1d'))

# visualise first spectrum
spec(X[1,], ppm)

# TopSpin acquisition status parameters
meta$a_PROBHD[1] # probehead
meta$a_SFO1[1] # carrier frequency
meta$a_O1[1] # frequency offset from SF01
meta$a_NS[1] # number of scans
meta$a_RG[1] # receiver gain
meta$a_OVERFLW[1] # overflow


# TopSpin processing status parameters
meta$p_SI[1] # nb of points in spectrum (zero filled)
meta$p_LB[1] # line broadening factor
meta$p_PHC0[1] # zero order phasing
meta$p_PHC0[1] # first order phasing





