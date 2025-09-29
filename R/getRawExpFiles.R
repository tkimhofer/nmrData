#' Unpack and return path to raw NMR experiment directory
#'
#' Retrieves the raw NMR experiment archive (tar.gz) from ExperimentHub
#' and ensures it is unpacked once into a cache directory. If the unpacked
#' directory already exists and contains files, it is reused; otherwise the
#' tarball is extracted. Optionally, an existing unpack can be forced to be
#' replaced.
#'
#' This helper is idempotent: repeated calls return the same normalized path
#' without re-downloading or re-unpacking, unless explicitly instructed.
#'
#' @param quiet Logical; suppress progress messages (default `FALSE`).
#' @param reuntar Logical; force re-extraction even if the directory already
#'   exists and is populated (default `FALSE`).
#' @param tar_override Character path to a local `.tar.gz` file to use instead of
#'   ExperimentHub (for examples/tests; default `NULL`).
#'
#' @return A character scalar: normalized absolute path to the unpacked dataset
#'   directory inside the local ExperimentHub cache.
#'
#' @details
#'
#' - The function always uses the same internal ExperimentHub ID
#'   (`EH9906` by default in this package).
#' - The tarball is retrieved via [ExperimentHub::ExperimentHub()].
#' - The directory is created next to the cached tarball inside the EH cache.
#' - If the archive contains exactly one top-level folder, that name is reused.
#'   Otherwise a default folder name (`"nmrdata"`) is created.
#'
#' @examples
#' td <- tempfile(); dir.create(td)
#' dir.create(file.path(td, "tinydata"))
#' cat("ex data\n", file = file.path(td, "tinydata", "a.txt"))
#' tarfile <- file.path(td, "tinydata.tar.gz")
#' utils::tar(tarfile, files = "tinydata", compression = "gzip", tar = "internal")
#'
#' p <- getRawExpDir(tar_override = tarfile, quiet = TRUE)
#' basename(p)              # "tinydata"
#' list.files(p)            # "a.txt"
#'
#' \dontrun{
#' exp_dir <- getRawExpDir()
#' list.files(exp_dir, recursive = TRUE)[1:5]
#'
#' # Force re-unpack if you think the folder is corrupted
#' exp_dir <- getRawExpDir(reuntar = TRUE)
#' }
#'
#' @seealso [ExperimentHub::ExperimentHub()], [utils::untar()]
#'
#' @export
getRawExpDir <- function(quiet = FALSE, reuntar = FALSE, tar_override = NULL) {
  EH_ID_TAR <- "EH9906"
  fallback  <- "nmrdata"

  if (is.null(tar_override)) {
    tar_path <- ExperimentHub::ExperimentHub()[[EH_ID_TAR]]
    cache_dir <- dirname(tar_path)
  } else {
    tar_path <- tar_override
    cache_dir <- dirname(tar_path)
  }

  listing  <- tryCatch(utils::untar(tar_path, list = TRUE), error = function(e) character())
  top_dirs <- unique(sub("/.*$", "", listing))
  root     <- if (length(top_dirs) == 1L && nzchar(top_dirs)) top_dirs else fallback

  dest_dir <- file.path(cache_dir, root)

  already <- dir.exists(dest_dir) && length(list.files(dest_dir, recursive = TRUE)) > 0L
  if (already && !reuntar) {
    if (!quiet) message("Using cached unpack at ", dest_dir)
    return(normalizePath(dest_dir, winslash = "/"))
  }

  if (reuntar && dir.exists(dest_dir)) unlink(dest_dir, recursive = TRUE, force = TRUE)
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  if (!quiet) message("Unpacking to ", dest_dir)
  utils::untar(tar_path, exdir = dest_dir)

  normalizePath(dest_dir, winslash = "/")
}
