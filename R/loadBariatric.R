#' Load processed dataset (.RData) — Zenodo now, Hub later
#'
#' During development this function downloads/caches from Zenodo only,
#' avoiding ExperimentHub/BiocFileCache chatter. After EH IDs exist,
#' set `USE_HUB <- TRUE` and fill EH_ID_RDATA to prefer ExperimentHub.
#'
#' @param as One of c("list","env","names","path").
#' @param objects Optional character vector: subset which objects to load/return.
#' @param cache_dir Optional cache directory; defaults to a persistent per-user cache.
#' @param quiet Logical; suppress messages.
#' @param unwrap Logical; unnests list returned.
#' @return Named list, environment, names, or the cached file path.
#' @keywords internal
loadBariatric <- function(
    as = c("list","env","names","path"),
    objects = NULL,
    cache_dir = NULL,
    quiet = FALSE,
    unwrap = TRUE
) {
  as <- match.arg(as)

  USE_HUB        <- FALSE # <- upd when hub avail
  EH_ID_RDATA    <- "XXXXX"# <- upd when hub-id avail
  ZENODO_URL     <- "https://zenodo.org/records/17053134/files/bariatric.rdata?download=1"
  LOCAL_FILENAME <- basename(sub("\\?.*$", "", ZENODO_URL)) # excl query par


  if (is.null(cache_dir)) {
    cache_dir <- tools::R_user_dir("nmrdata", which = "cache")
  }
  if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE)

  ## try once DS avail on bioc hub (change USE_HUB above)
  rdata_path <- NULL
  if (USE_HUB && grepl("^EH\\d+$", EH_ID_RDATA, perl = TRUE)) {
    if (requireNamespace("ExperimentHub", quietly = TRUE)) {
      eh <- try(ExperimentHub::ExperimentHub(), silent = TRUE)
      if (!inherits(eh, "try-error")) {
        rdata_path <- tryCatch(eh[[EH_ID_RDATA]], error = function(e) NULL)
        if (!is.null(rdata_path) && !quiet) message("loadBariatric(): source=ExperimentHub")
      }
    }
  }

  ## Zenodo base-R
  if (is.null(rdata_path)) {
    dest <- file.path(cache_dir, LOCAL_FILENAME)
    if (!file.exists(dest) || isTRUE(file.info(dest)$size == 0L)) {
      if (!quiet) message("loadBariatric(): downloading from Zenodo to cache: ", cache_dir)
      old <- getOption("download.file.method"); options(download.file.method = "libcurl")
      on.exit(options(download.file.method = old), add = TRUE)
      utils::download.file(ZENODO_URL, dest, mode = "wb", quiet = quiet)
      if (!file.exists(dest) || file.info(dest)$size == 0L) {
        stop("Zenodo download failed: ", ZENODO_URL)
      }
    } else if (!quiet) {
      message("loadBariatric(): using cached file: ", dest)
    }
    rdata_path <- normalizePath(dest, winslash = "/")
  }

  if (as == "path") return(rdata_path)

  ## load rdata obj
  env <- new.env(parent = emptyenv())
  loaded <- base::load(rdata_path, envir = env)

  keep <- if (is.null(objects)) loaded else {
    missing <- setdiff(objects, loaded)
    if (length(missing) && !quiet) warning("Objects not in .RData: ", paste(missing, collapse = ", "))
    intersect(objects, loaded)
  }

  if (as == "names") return(keep)
  if (as == "env") {
    if (!is.null(objects)) {
      to_rm <- setdiff(ls(env, all.names = TRUE), keep)
      if (length(to_rm)) rm(list = to_rm, envir = env)
    }
    return(env)
  }
  out <- mget(keep, envir = env, inherits = FALSE)  # as == "list"

  if (isTRUE(unwrap) && length(out) == 1L) {
    return(out[[1L]])
  }
  out
}
