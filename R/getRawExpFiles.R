#' Get raw NMR experiment directory (folder name derived from tar.gz)
#'
#' During development this downloads the archive from Zenodo into a persistent
#' per-user cache and unpacks it **beside the tarball** (i.e., into
#' `file.path(dirname(tar_path), <top-level-from-tar>)`). The top-level directory
#' name is detected from the archive contents; if the archive does not contain a
#' single top-level directory, a folder named after the tarball (without the
#' extension) is created and used as the root. After ExperimentHub onboarding,
#' flip the internal `USE_HUB` flag and set `EH_ID_TAR` to prefer Hub.
#'
#' The function is idempotent: it downloads and unpacks only once unless you set
#' `redownload = TRUE` and/or `reuntar = TRUE`.
#'
#' @param cache_dir Optional cache directory (default:
#'   `tools::R_user_dir("nmrdata", "cache")`), used only for the Zenodo path.
#' @param quiet Logical; suppress messages (default `FALSE`).
#' @param redownload Logical; force re-download of the tar.gz (default `FALSE`).
#' @param reuntar Logical; force re-unpack even if an unpack exists (default `FALSE`).
#'
#' @return Character scalar: normalized path to the unpacked dataset directory
#'   located at `file.path(dirname(tar_path), <derived-root>)`.
#'
#' @examples
#' \dontrun{
#' exp_dir <- getRawExpDir()
#' list.files(exp_dir, recursive = TRUE)[1:10]
#' }
#' @keywords internal
getRawExpDir <- function(cache_dir = NULL, quiet = FALSE, redownload = FALSE, reuntar = FALSE) {
  ## ---- flip to TRUE + set EH_ID_TAR once Hub is live ----
  USE_HUB   <- FALSE
  EH_ID_TAR <- "EHXXXXX"

  ## ---- Zenodo source (direct file URL; case must match the filename on Zenodo) ----
  ZENODO_URL <- "https://zenodo.org/records/17053118/files/bruker_exp.tar.gz?download=1"

  # choose a persistent cache for the Zenodo tarball
  if (is.null(cache_dir)) cache_dir <- tools::R_user_dir("nmrdata", which = "cache")
  if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE)

  tar_path <- NULL

  ## ---- Prefer ExperimentHub when enabled and ID set ----
  if (isTRUE(USE_HUB) && grepl("^EH\\d+$", EH_ID_TAR) &&
      requireNamespace("ExperimentHub", quietly = TRUE)) {
    eh <- try(ExperimentHub::ExperimentHub(), silent = TRUE)
    if (!inherits(eh, "try-error")) {
      tar_path <- tryCatch(eh[[EH_ID_TAR]], error = function(e) NULL)
      if (!is.null(tar_path) && !quiet) message("getRawExpDir(): source = ExperimentHub")
    }
  }

  ## ---- Zenodo download (development path) ----
  if (is.null(tar_path)) {
    local_tar <- basename(sub("\\?.*$", "", ZENODO_URL))  # strip ?download=1
    tar_path  <- file.path(cache_dir, local_tar)

    need_download <- isTRUE(redownload) || !file.exists(tar_path) || isTRUE(file.info(tar_path)$size == 0L)
    if (!need_download) {
      # sanity-check the archive is readable
      ok <- tryCatch({
        utils::untar(tar_path, list = TRUE)
        TRUE
      }, error = function(e) FALSE)
      if (!ok) need_download <- TRUE
    }

    if (need_download) {
      if (!quiet) message("getRawExpDir(): downloading from Zenodo to ", tar_path)
      old <- getOption("download.file.method"); options(download.file.method = "libcurl")
      on.exit(options(download.file.method = old), add = TRUE)
      utils::download.file(ZENODO_URL, tar_path, mode = "wb", quiet = quiet)
      if (!file.exists(tar_path) || file.info(tar_path)$size == 0L)
        stop("Zenodo download failed: ", ZENODO_URL)
    } else if (!quiet) {
      message("getRawExpDir(): using cached tarball: ", tar_path)
    }
  }

  ## ---- Derive the desired root folder name from the archive ----
  paths <- tryCatch(utils::untar(tar_path, list = TRUE), error = function(e) character(0))
  paths <- sub("^\\./", "", paths)                    # drop leading "./" if present
  roots <- unique(sub("/.*", "", paths))              # first path component
  roots <- roots[nzchar(roots)]                       # drop empty
  single_root <- if (length(roots) == 1L) roots else NA_character_

  # Fallback: use tar filename (without extension) if no single top-level dir
  fallback_root <- sub("\\.(tar\\.(gz|bz2|xz)|tgz|tbz2|txz)$", "", basename(tar_path), ignore.case = TRUE)
  wanted_root   <- if (!is.na(single_root)) single_root else fallback_root

  parent_dir <- dirname(tar_path)
  dest_dir   <- file.path(parent_dir, wanted_root)

  ## ---- Unpack beside the tarball, avoiding double nesting ----
  # If the archive already has <wanted_root>/..., untar to parent_dir to land at parent/<wanted_root>.
  # Otherwise untar into dest_dir to create that root.
  has_root_in_archive <- !is.na(single_root) && identical(single_root, wanted_root)

  # decide if we need to (re)unpack
  populated <- dir.exists(dest_dir) && length(list.files(dest_dir, recursive = TRUE)) > 0L
  need_unpack <- isTRUE(reuntar) || !populated

  if (need_unpack) {
    if (isTRUE(reuntar) && dir.exists(dest_dir)) {
      # clean stale contents to avoid mixing versions
      unlink(dest_dir, recursive = TRUE, force = TRUE)
    }
    if (!quiet) message("getRawExpDir(): unpacking to ", if (has_root_in_archive) parent_dir else dest_dir)
    dir.create(if (has_root_in_archive) parent_dir else dest_dir, showWarnings = FALSE, recursive = TRUE)
    utils::untar(tar_path, exdir = if (has_root_in_archive) parent_dir else dest_dir)
  } else if (!quiet) {
    message("getRawExpDir(): using cached unpack at ", dest_dir)
  }

  return(normalizePath(dest_dir, winslash = "/"))
}
