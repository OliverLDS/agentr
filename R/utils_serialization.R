#' Load a JSON file
#'
#' @param path Path to a JSON file.
#' @param simplifyVector Passed to [jsonlite::fromJSON()].
#'
#' @return Parsed JSON content.
#' @export
load_json_file <- function(path, simplifyVector = TRUE) {
  jsonlite::fromJSON(path, simplifyVector = simplifyVector)
}

#' Save a JSON file safely
#'
#' @param object Object to serialize to JSON.
#' @param path Path to a JSON file.
#' @param wait Total wait time in seconds before giving up.
#' @param max_attempts Number of retry attempts.
#'
#' @return Invisibly returns `TRUE`.
#' @keywords internal
.safe_save_json <- function(object, path, wait = 5, max_attempts = 10) {
  lockfile <- paste0(path, ".lock")
  attempts <- 0

  repeat {
    if (!file.exists(lockfile)) {
      file.create(lockfile)

      if (file.exists(lockfile)) {
        on.exit(unlink(lockfile), add = TRUE)
        jsonlite::write_json(
          object,
          path,
          auto_unbox = TRUE,
          pretty = TRUE,
          null = "null",
          na = "null"
        )
        return(invisible(TRUE))
      }
    }

    attempts <- attempts + 1
    if (attempts >= max_attempts) {
      stop("Could not acquire lock on file after multiple attempts.")
    }
    Sys.sleep(wait / max_attempts)
  }
}

#' @keywords internal
.spec_file_format <- function(path, format = c("rds", "json"), label = "spec") {
  format <- match.arg(format)
  if (format != "rds") {
    return(format)
  }
  if (is.character(path) && length(path) == 1L) {
    if (grepl("\\.json$", path, ignore.case = TRUE)) {
      return("json")
    }
    if (grepl("\\.rds$", path, ignore.case = TRUE)) {
      return("rds")
    }
  }
  format
}

#' Load a YAML file
#'
#' @param path Path to a YAML file.
#'
#' @return Parsed YAML content.
#' @export
load_yaml_file <- function(path) {
  yaml::read_yaml(path)
}
