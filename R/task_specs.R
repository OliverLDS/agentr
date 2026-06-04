#' Return conventional task-local spec paths
#'
#' Coding-assistant workflows commonly keep editable `agentr` specs under a
#' task-local `docs/` directory. This helper returns the conventional paths
#' without creating or modifying files.
#'
#' @param task_dir Task root directory.
#' @param docs_dir Documentation/spec directory relative to `task_dir`, or an
#'   absolute path.
#'
#' @return Named list of task-local paths.
#' @export
task_spec_paths <- function(task_dir, docs_dir = "docs") {
  task_dir <- path.expand(as.character(task_dir)[1])
  docs_dir <- path.expand(as.character(docs_dir)[1])
  if (!.is_absolute_path(docs_dir)) {
    docs_dir <- file.path(task_dir, docs_dir)
  }

  list(
    task_dir = task_dir,
    docs_dir = docs_dir,
    workflow = file.path(docs_dir, "workflow_spec.yaml"),
    memory = file.path(docs_dir, "memory_spec.yaml"),
    knowledge = file.path(docs_dir, "knowledge_spec.yaml"),
    knowledge_graph = file.path(docs_dir, "knowledge_graph_spec.yaml"),
    review = file.path(docs_dir, "review.html"),
    inference_notes = file.path(docs_dir, "inference_notes.md")
  )
}

#' Discover task-local spec files
#'
#' @param task_dir Task root directory.
#' @param docs_dir Documentation/spec directory relative to `task_dir`, or an
#'   absolute path.
#'
#' @return Data frame with spec type, path, and existence flag.
#' @export
discover_task_specs <- function(task_dir, docs_dir = "docs") {
  paths <- task_spec_paths(task_dir, docs_dir = docs_dir)
  types <- c("workflow", "memory", "knowledge", "knowledge_graph")
  spec_paths <- unlist(paths[types], use.names = TRUE)
  data.frame(
    type = names(spec_paths),
    path = unname(spec_paths),
    exists = file.exists(unname(spec_paths)),
    stringsAsFactors = FALSE
  )
}

#' Load task-local specs
#'
#' Loads conventional task-local YAML specs when present. Missing specs are
#' returned as `NULL` unless `missing = "error"` is requested.
#'
#' @param task_dir Task root directory.
#' @param docs_dir Documentation/spec directory relative to `task_dir`, or an
#'   absolute path.
#' @param missing How to handle missing spec files.
#'
#' @return Named list containing loaded specs, path metadata, and discovery
#'   manifest.
#' @export
load_task_specs <- function(task_dir, docs_dir = "docs", missing = c("null", "error")) {
  missing <- match.arg(missing)
  manifest <- discover_task_specs(task_dir, docs_dir = docs_dir)
  paths <- task_spec_paths(task_dir, docs_dir = docs_dir)

  if (identical(missing, "error") && any(!manifest$exists)) {
    missing_types <- manifest$type[!manifest$exists]
    stop(
      "Missing task-local spec file(s): ",
      paste(missing_types, collapse = ", "),
      call. = FALSE
    )
  }

  out <- list(
    workflow = NULL,
    memory = NULL,
    knowledge = NULL,
    knowledge_graph = NULL,
    paths = paths,
    manifest = manifest
  )
  loaders <- .task_spec_loaders()
  for (type in names(loaders)) {
    path <- paths[[type]]
    if (file.exists(path)) {
      out[[type]] <- loaders[[type]](path)
    }
  }

  structure(out, class = c("agentr_task_specs", "list"))
}

#' Validate task-local specs
#'
#' Validates conventional task-local YAML specs when present and reports missing
#' or invalid files without mutating the task directory.
#'
#' @param task_dir Task root directory.
#' @param docs_dir Documentation/spec directory relative to `task_dir`, or an
#'   absolute path.
#' @param require Character vector of spec types that must exist. Supported
#'   values are `workflow`, `memory`, `knowledge`, and `knowledge_graph`.
#' @param stop_on_error Whether to stop when required or present specs are
#'   invalid.
#'
#' @return Data frame with one row per spec type.
#' @export
validate_task_specs <- function(
  task_dir,
  docs_dir = "docs",
  require = character(),
  stop_on_error = FALSE
) {
  supported <- names(.task_spec_loaders())
  require <- as.character(require)
  unknown <- require[!(require %in% supported)]
  if (length(unknown)) {
    stop("Unknown required task spec type(s): ", paste(unknown, collapse = ", "), call. = FALSE)
  }

  manifest <- discover_task_specs(task_dir, docs_dir = docs_dir)
  loaders <- .task_spec_loaders()
  result <- manifest
  result$required <- result$type %in% require
  result$valid <- FALSE
  result$message <- ""

  for (i in seq_len(nrow(result))) {
    type <- result$type[i]
    path <- result$path[i]
    if (!isTRUE(result$exists[i])) {
      result$message[i] <- if (isTRUE(result$required[i])) "missing required spec" else "missing optional spec"
      next
    }

    check <- tryCatch(
      {
        loaders[[type]](path)
        TRUE
      },
      error = function(error) error
    )
    if (identical(check, TRUE)) {
      result$valid[i] <- TRUE
      result$message[i] <- "valid"
    } else {
      result$message[i] <- conditionMessage(check)
    }
  }

  if (isTRUE(stop_on_error)) {
    failing <- result[(result$required | result$exists) & !result$valid, , drop = FALSE]
    if (nrow(failing)) {
      details <- paste(paste0(failing$type, ": ", failing$message), collapse = "; ")
      stop("Task-local spec validation failed: ", details, call. = FALSE)
    }
  }

  result
}

#' @keywords internal
.task_spec_loaders <- function() {
  list(
    workflow = load_workflow_spec_yaml,
    memory = load_memory_spec_yaml,
    knowledge = load_knowledge_spec_yaml,
    knowledge_graph = load_knowledge_graph_spec_yaml
  )
}

#' @keywords internal
.is_absolute_path <- function(path) {
  grepl("^(/|[A-Za-z]:[\\\\/])", path)
}
