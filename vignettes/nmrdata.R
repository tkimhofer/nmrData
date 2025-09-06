## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(message = FALSE, warning = FALSE)
mm8_available <- requireNamespace("metabom8", quietly = TRUE)


## ----eval=FALSE---------------------------------------------------------------
# # Install from Bioconductor
# if (!require("BiocManager")) install.packages("BiocManager")
# BiocManager::install("nmrdata")

## ----load-processed, eval=FALSE-----------------------------------------------
# library(nmrdata)
# 
# # load pre-processed data (returns a named list)
# bariatric <- loadBariatric(as = "list", quiet = TRUE)
# 
# str(bariatric, max.level = 1)
# 
# # visualise the first NMR spectrum
# plot(bariatric$ppm, bariatric$X.pqn[1, ], type = "l",
#      xlab = "Chemical shift (ppm)", ylab = "Intensity")

## ----raw-dir, eval=FALSE------------------------------------------------------
# # download once, unpack once; returns the directory path
# exp_dir <- getRawExpDir(quiet = TRUE)
# 
# # show top-level contents
# list.files(exp_dir)

