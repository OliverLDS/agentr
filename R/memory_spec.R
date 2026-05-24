#' Memory types
#'
#' @return Character vector of supported memory type labels.
#' @export
memory_types <- function() {
  c("context", "semantic", "episodic", "procedural")
}

#' Memory persistence policies
#'
#' @return Character vector of supported memory persistence policies.
#' @export
memory_persistence_policies <- function() {
  c("session", "cold_start_rds", "jsonl_trace", "external_store", "none")
}

#' @keywords internal
.memory_review_statuses <- function() {
  c("draft", "pending", "under_discussion", "approved", "rejected", "superseded")
}

#' @keywords internal
.normalize_memory_type <- function(x) {
  match.arg(as.character(x)[1], choices = memory_types())
}

#' @keywords internal
.normalize_memory_persistence <- function(x) {
  match.arg(as.character(x)[1], choices = memory_persistence_policies())
}

#' @keywords internal
.normalize_memory_review <- function(review) {
  if (is.null(review)) {
    review <- list(status = "draft", reviewer = "human", notes = NULL)
  }
  if (!is.list(review)) {
    stop("Memory field `review` must be a list.", call. = FALSE)
  }
  if (is.null(review$status)) {
    review$status <- "draft"
  }
  review$status <- match.arg(as.character(review$status)[1], choices = .memory_review_statuses())
  review
}

#' Create a memory field record
#'
#' @param id Memory field identifier.
#' @param label Human-readable field label.
#' @param memory_type Memory type: `context`, `semantic`, `episodic`, or
#'   `procedural`.
#' @param description Optional field description.
#' @param schema Structured schema constraints for the field.
#' @param persistence Persistence policy.
#' @param update_policy Free-form update-policy description or list.
#' @param source Optional source label.
#' @param review Review metadata list.
#' @param provenance Provenance metadata list.
#' @param metadata Additional metadata list.
#'
#' @return A validated memory field list.
#' @export
memory_field <- function(
  id,
  label,
  memory_type = c("context", "semantic", "episodic", "procedural"),
  description = NA_character_,
  schema = list(),
  persistence = c("session", "cold_start_rds", "jsonl_trace", "external_store", "none"),
  update_policy = list(),
  source = NA_character_,
  review = list(status = "draft"),
  provenance = list(),
  metadata = list()
) {
  field <- list(
    id = as.character(id)[1],
    label = as.character(label)[1],
    memory_type = .normalize_memory_type(memory_type),
    description = if (is.null(description)) NA_character_ else as.character(description)[1],
    schema = if (is.null(schema)) list() else schema,
    persistence = .normalize_memory_persistence(persistence),
    update_policy = if (is.null(update_policy)) list() else update_policy,
    source = if (is.null(source)) NA_character_ else as.character(source)[1],
    review = .normalize_memory_review(review),
    provenance = if (is.null(provenance)) list() else provenance,
    metadata = if (is.null(metadata)) list() else metadata
  )
  validate_memory_field(field)
  class(field) <- c("agentr_memory_field", class(field))
  field
}

#' Validate a memory field
#'
#' @param x Memory field list.
#'
#' @return The validated field, invisibly.
#' @export
validate_memory_field <- function(x) {
  required <- c(
    "id", "label", "memory_type", "description", "schema", "persistence",
    "update_policy", "source", "review", "provenance", "metadata"
  )
  if (!is.list(x) || !all(required %in% names(x))) {
    stop("Memory field must contain the required memory-field entries.", call. = FALSE)
  }
  if (!is.character(x$id) || length(x$id) != 1L || is.na(x$id) || !nzchar(x$id)) {
    stop("Memory field `id` must be a non-empty string.", call. = FALSE)
  }
  if (!is.character(x$label) || length(x$label) != 1L || is.na(x$label) || !nzchar(x$label)) {
    stop("Memory field `label` must be a non-empty string.", call. = FALSE)
  }
  x$memory_type <- .normalize_memory_type(x$memory_type)
  x$persistence <- .normalize_memory_persistence(x$persistence)
  .validate_metadata_list(x$schema, "schema")
  .validate_metadata_list(x$update_policy, "update_policy")
  x$review <- .normalize_memory_review(x$review)
  .validate_metadata_list(x$provenance, "provenance")
  .validate_metadata_list(x$metadata, "metadata")
  invisible(x)
}

#' @keywords internal
.normalize_memory_field <- function(x) {
  if (!is.list(x)) {
    stop("Memory fields must be lists.", call. = FALSE)
  }
  if (inherits(x, "agentr_memory_field")) {
    validate_memory_field(x)
    return(x)
  }
  field <- memory_field(
    id = x$id,
    label = x$label,
    memory_type = if (is.null(x$memory_type)) "context" else x$memory_type,
    description = if (is.null(x$description)) NA_character_ else x$description,
    schema = if (is.null(x$schema)) list() else x$schema,
    persistence = if (is.null(x$persistence)) "session" else x$persistence,
    update_policy = if (is.null(x$update_policy)) list() else x$update_policy,
    source = if (is.null(x$source)) NA_character_ else x$source,
    review = if (is.null(x$review)) list(status = "draft") else x$review,
    provenance = if (is.null(x$provenance)) list() else x$provenance,
    metadata = if (is.null(x$metadata)) list() else x$metadata
  )
  class(field) <- c("agentr_memory_field", class(field))
  field
}

#' MemorySpec
#'
#' First-class memory schema for an agent design. `MemorySpec` records which
#' memory fields exist, what type of memory they represent, how they persist
#' across cold-start runs, and how they are expected to update. It complements
#' legacy `state_spec` lists rather than replacing them abruptly.
#'
#' @field fields Named list of memory field records.
#' @field metadata Free-form metadata list.
#' @param fields List of memory field records.
#' @param metadata Free-form metadata list.
#' @param field Memory field record used by `$add_field()`.
#' @param id Memory field id used by `$get_field()`.
#' @param memory_type Optional memory type filter used by `$list_fields()`.
#' @param persistence Optional persistence-policy filter used by `$list_fields()`.
#' @param ... Unused print arguments.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(fields = list(), metadata = list())`}{Create a memory specification.}
#'   \item{`$add_field(field)`}{Add one memory field.}
#'   \item{`$get_field(id)`}{Return one memory field by id.}
#'   \item{`$list_fields(memory_type = NULL, persistence = NULL)`}{Return memory fields, optionally filtered.}
#'   \item{`$validate()`}{Validate the memory specification.}
#'   \item{`$to_list()`}{Return a serializable list.}
#'   \item{`$print(...)`}{Print a compact summary.}
#' }
#' @export
MemorySpec <- R6::R6Class(
  classname = "MemorySpec",
  public = list(
    fields = NULL,
    metadata = NULL,

    #' @description
    #' Create a memory specification.
    initialize = function(fields = list(), metadata = list()) {
      self$fields <- list()
      self$metadata <- if (is.null(metadata)) list() else metadata
      if (length(fields)) {
        for (field in fields) {
          self$add_field(field)
        }
      }
      self$validate()
    },

    #' @description
    #' Add one memory field.
    add_field = function(field) {
      field <- .normalize_memory_field(field)
      if (field$id %in% names(self$fields)) {
        stop("Duplicate memory field id: ", field$id, call. = FALSE)
      }
      self$fields[[field$id]] <- field
      invisible(self)
    },

    #' @description
    #' Return one memory field by id.
    get_field = function(id) {
      id <- as.character(id)[1]
      if (!id %in% names(self$fields)) {
        return(NULL)
      }
      self$fields[[id]]
    },

    #' @description
    #' Return memory fields, optionally filtered by type or persistence policy.
    list_fields = function(memory_type = NULL, persistence = NULL) {
      out <- self$fields
      if (!is.null(memory_type)) {
        memory_type <- .normalize_memory_type(memory_type)
        out <- Filter(function(field) identical(field$memory_type, memory_type), out)
      }
      if (!is.null(persistence)) {
        persistence <- .normalize_memory_persistence(persistence)
        out <- Filter(function(field) identical(field$persistence, persistence), out)
      }
      out
    },

    #' @description
    #' Validate the memory specification.
    validate = function() {
      if (!is.list(self$fields)) {
        stop("MemorySpec `fields` must be a list.", call. = FALSE)
      }
      if (length(self$fields)) {
        if (is.null(names(self$fields)) || any(!nzchar(names(self$fields)))) {
          stop("MemorySpec fields must be named by field id.", call. = FALSE)
        }
        ids <- character()
        for (field in self$fields) {
          validate_memory_field(field)
          ids <- c(ids, field$id)
        }
        if (anyDuplicated(ids) || !identical(names(self$fields), ids)) {
          stop("MemorySpec field names must match unique field ids.", call. = FALSE)
        }
      }
      .validate_metadata_list(self$metadata)
      invisible(self)
    },

    #' @description
    #' Return a serializable list.
    to_list = function() {
      self$validate()
      list(
        fields = self$fields,
        metadata = self$metadata
      )
    },

    #' @description
    #' Print a compact memory schema summary.
    print = function(...) {
      self$validate()
      cat("<MemorySpec>\n")
      cat("Fields:", length(self$fields), "\n")
      if (length(self$fields)) {
        types <- table(vapply(self$fields, function(field) field$memory_type, character(1)))
        cat(
          "Types:",
          paste(paste(names(types), as.integer(types), sep = "="), collapse = ", "),
          "\n"
        )
      }
      invisible(self)
    }
  )
)

#' Validate a MemorySpec
#'
#' @param x A [`MemorySpec`] object.
#'
#' @return The validated object, invisibly.
#' @export
validate_memory_spec <- function(x) {
  if (!inherits(x, "MemorySpec")) {
    stop("`x` must be a `MemorySpec`.", call. = FALSE)
  }
  x$validate()
}

#' @keywords internal
.memory_spec_from_list <- function(x) {
  x <- .normalize_spec_arrays(x)
  if (!is.list(x) || !all(c("fields", "metadata") %in% names(x))) {
    stop("Memory spec JSON must contain top-level `fields` and `metadata` fields.", call. = FALSE)
  }
  MemorySpec$new(
    fields = x$fields,
    metadata = x$metadata
  )
}
