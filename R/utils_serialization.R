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
.safe_save_yaml <- function(object, path, wait = 5, max_attempts = 10) {
  lockfile <- paste0(path, ".lock")
  attempts <- 0

  repeat {
    if (!file.exists(lockfile)) {
      file.create(lockfile)

      if (file.exists(lockfile)) {
        on.exit(unlink(lockfile), add = TRUE)
        yaml::write_yaml(object, path)
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
.spec_file_format <- function(path, format = c("rds", "json", "yaml"), label = "spec") {
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
    if (grepl("\\.ya?ml$", path, ignore.case = TRUE)) {
      return("yaml")
    }
  }
  format
}

#' @keywords internal
.spec_yaml_or_json_list <- function(path, format, label = "Spec") {
  if (identical(format, "yaml")) {
    return(load_yaml_file(path))
  }
  if (identical(format, "json")) {
    return(load_json_file(path, simplifyVector = FALSE))
  }
  stop(label, " format must be `json` or `yaml`.", call. = FALSE)
}

#' @keywords internal
.as_json_array <- function(x) {
  if (is.null(x)) {
    return(I(list()))
  }
  if (is.list(x) && !is.data.frame(x)) {
    return(I(x))
  }
  I(as.vector(x))
}

#' @keywords internal
.preserve_spec_arrays <- function(x) {
  if (!is.list(x) || is.data.frame(x)) {
    return(x)
  }
  if (is.null(names(x))) {
    return(lapply(x, .preserve_spec_arrays))
  }
  item_names <- names(x)
  for (i in seq_along(x)) {
    name <- item_names[[i]]
    if (name %in% c("knowledge_refs", "required")) {
      x[i] <- list(.as_json_array(x[[i]]))
    } else {
      x[i] <- list(.preserve_spec_arrays(x[[i]]))
    }
  }
  x
}

#' @keywords internal
.normalize_spec_arrays <- function(x) {
  if (!is.list(x) || is.data.frame(x)) {
    return(x)
  }
  if (is.null(names(x))) {
    return(lapply(x, .normalize_spec_arrays))
  }
  item_names <- names(x)
  for (i in seq_along(x)) {
    name <- item_names[[i]]
    if (name %in% c("knowledge_refs", "required")) {
      if (is.null(x[[i]])) {
        x[i] <- list(character())
      } else {
        x[i] <- list(as.character(unlist(x[[i]], use.names = FALSE)))
      }
    } else {
      x[i] <- list(.normalize_spec_arrays(x[[i]]))
    }
  }
  x
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
