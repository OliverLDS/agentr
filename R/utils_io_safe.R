#' Safely Save RDS File with Lock
#'
#' Saves an R object to an `.rds` file using a simple file-based lock to prevent 
#' concurrent writes. If the file is locked by another process, it retries until 
#' success or `max_attempts` is reached.
#'
#' @param object The R object to save.
#' @param path The file path to save the object to (should end in `.rds`).
#' @param wait Total wait time in seconds before giving up (default is 5).
#' @param max_attempts Number of retry attempts (default is 10).
#'
#' @return Invisibly returns TRUE on success.
#' @keywords internal
#'
#' @examples
#' \dontrun{
#'   .safe_save_rds(list(a = 1, b = 2), "my_file.rds")
#' }
.safe_save_rds <- function(object, path, wait = 5, max_attempts = 10) {
  lockfile <- paste0(path, ".lock")
  attempts <- 0

  repeat {
    if (!file.exists(lockfile)) {
      # Create lock
      file.create(lockfile)

      # Double-check in case of race
      if (file.exists(lockfile)) {
        on.exit(unlink(lockfile), add = TRUE)
        saveRDS(object, path)
        return(invisible(TRUE))
      }
    }

    # If locked, wait and retry
    attempts <- attempts + 1
    if (attempts >= max_attempts) {
      stop("Could not acquire lock on file after multiple attempts.")
    }
    Sys.sleep(wait / max_attempts)
  }
}

#' Safely Read RDS File with Lock Awareness
#'
#' Reads an `.rds` file safely by checking if a `.lock` file exists, indicating 
#' that another process may be writing. Retries until the lock disappears or 
#' `max_attempts` is exceeded.
#'
#' @param path The path to the `.rds` file.
#' @param wait Total wait time in seconds before giving up (default is 5).
#' @param max_attempts Number of retry attempts (default is 10).
#'
#' @return The deserialized R object.
#' @keywords internal
#'
#' @examples
#' \dontrun{
#'   data <- .safe_read_rds("my_file.rds")
#' }
.safe_read_rds <- function(path, wait = 5, max_attempts = 10) {
  lockfile <- paste0(path, ".lock")
  attempts <- 0

  repeat {
    if (!file.exists(lockfile)) {
      # No one is writing — safe to read
      return(readRDS(path))
    }

    # Wait and retry
    attempts <- attempts + 1
    if (attempts >= max_attempts) {
      stop("File is locked for too long — cannot read.")
    }
    Sys.sleep(wait / max_attempts)
  }
}