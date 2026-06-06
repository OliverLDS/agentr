#' @keywords internal
.knowledge_review_statuses <- function() {
  c("draft", "pending", "under_discussion", "approved", "rejected", "superseded")
}

#' @keywords internal
.knowledge_item_types <- function() {
  c(
    "concept",
    "causal_relation",
    "rule",
    "exception",
    "heuristic",
    "evaluation_criterion",
    "domain_constraint",
    "style_preference",
    "risk_warning"
  )
}

#' @keywords internal
.knowledge_confidence_values <- function() {
  c("low", "medium", "high")
}

#' @keywords internal
.normalize_knowledge_review_status <- function(x) {
  match.arg(as.character(x)[1], choices = .knowledge_review_statuses())
}

#' @keywords internal
.normalize_knowledge_item_type <- function(x) {
  match.arg(as.character(x)[1], choices = .knowledge_item_types())
}

#' @keywords internal
.coerce_knowledge_item <- function(item) {
  if (!is.list(item)) {
    stop("Knowledge items must be lists.", call. = FALSE)
  }
  item$id <- as.character(item$id)[1]
  item$type <- .normalize_knowledge_item_type(item$type)
  item$raw_statement <- as.character(item$raw_statement)[1]
  item$normalized_statement <- if (is.null(item$normalized_statement)) NA_character_ else as.character(item$normalized_statement)[1]
  item$domain <- if (is.null(item$domain)) NA_character_ else as.character(item$domain)[1]
  item$structure <- if (is.null(item$structure)) list() else item$structure
  item$conditions <- if (is.null(item$conditions)) character() else as.character(unlist(item$conditions, use.names = FALSE))
  item$exceptions <- if (is.null(item$exceptions)) character() else as.character(unlist(item$exceptions, use.names = FALSE))
  item$confidence <- if (is.null(item$confidence)) NA_character_ else as.character(item$confidence)[1]
  item$provenance <- if (is.null(item$provenance)) list(source = "human", created_at = Sys.time()) else item$provenance
  item$review <- if (is.null(item$review)) list(status = "draft", reviewer = "human", notes = NULL) else item$review
  item$conflicts <- if (is.null(item$conflicts)) list() else item$conflicts
  item
}

#' Validate a knowledge specification item
#'
#' @param item Knowledge-item list.
#'
#' @return Validated item, invisibly.
#' @export
validate_knowledge_item <- function(item) {
  item <- .coerce_knowledge_item(item)
  if (!nzchar(item$id)) {
    stop("Knowledge items require a non-empty `id`.", call. = FALSE)
  }
  if (!nzchar(item$raw_statement)) {
    stop("Knowledge items require a non-empty `raw_statement`.", call. = FALSE)
  }
  if (!is.list(item$structure)) {
    stop("Knowledge item `structure` must be a list.", call. = FALSE)
  }
  if (!is.list(item$provenance)) {
    stop("Knowledge item `provenance` must be a list.", call. = FALSE)
  }
  if (!is.list(item$review)) {
    stop("Knowledge item `review` must be a list.", call. = FALSE)
  }
  item$review$status <- .normalize_knowledge_review_status(item$review$status)
  if (identical(item$review$status, "approved") &&
      (is.na(item$normalized_statement) || !nzchar(item$normalized_statement))) {
    stop("Approved knowledge items require a non-empty `normalized_statement`.", call. = FALSE)
  }
  if (!is.na(item$confidence) && !(item$confidence %in% .knowledge_confidence_values())) {
    stop("Knowledge item `confidence` must be one of: low, medium, high.", call. = FALSE)
  }
  if (!is.list(item$conflicts)) {
    stop("Knowledge item `conflicts` must be a list.", call. = FALSE)
  }
  invisible(item)
}

#' KnowledgeSpec
#'
#' Curated domain and epistemic knowledge used to guide agent behavior.
#' `items` stores narrative knowledge items, `graph` stores an optional
#' graph-shaped representation, and `vector_refs` reserves references to
#' external vector stores.
#'
#' @field items Named list of narrative knowledge items.
#' @field graph Optional graph representation list with `nodes` and `edges`.
#' @field vector_refs List of external vector-knowledge references.
#' @field metadata Free-form metadata list.
#' @param items List of narrative knowledge items.
#' @param graph Optional graph representation list with `nodes` and `edges`.
#' @param vector_refs List of external vector-knowledge references.
#' @param metadata Free-form metadata list.
#' @param item Knowledge item used by `$add_item()`.
#' @param id Knowledge item id used by `$get_item()`.
#' @param type Optional knowledge type filter used by `$list_items()`.
#' @param domain Optional domain filter used by `$list_items()`.
#' @param ... Unused print arguments.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(items = list(), graph = NULL, vector_refs = list(), metadata = list())`}{Create a knowledge specification.}
#'   \item{`$add_item(item)`}{Add a narrative knowledge item.}
#'   \item{`$get_item(id)`}{Return a narrative knowledge item by id.}
#'   \item{`$list_items(type = NULL, domain = NULL)`}{List narrative knowledge items, optionally filtered.}
#'   \item{`$validate()`}{Validate the knowledge specification.}
#'   \item{`$to_list()`}{Return a serializable list.}
#'   \item{`$print(...)`}{Print a compact summary.}
#' }
#' @export
KnowledgeSpec <- R6::R6Class(
  classname = "KnowledgeSpec",
  public = list(
    items = NULL,
    graph = NULL,
    vector_refs = NULL,
    metadata = NULL,

    #' @description
    #' Create a knowledge specification.
    initialize = function(items = list(), graph = NULL, vector_refs = list(), metadata = list()) {
      self$items <- list()
      self$graph <- .coerce_graph_representation_or_null(graph)
      self$vector_refs <- if (is.null(vector_refs)) list() else vector_refs
      self$metadata <- metadata
      if (length(items)) {
        for (item in items) {
          self$add_item(item)
        }
      }
      self$validate()
    },

    #' @description
    #' Add a knowledge item.
    add_item = function(item) {
      item <- .coerce_knowledge_item(item)
      validate_knowledge_item(item)
      if (!is.null(self$items[[item$id]])) {
        stop("Knowledge item ids must be unique. Duplicate id: ", item$id, call. = FALSE)
      }
      self$items[[item$id]] <- item
      invisible(self)
    },

    #' @description
    #' Return a knowledge item by id.
    get_item = function(id) {
      item <- self$items[[as.character(id)[1]]]
      if (is.null(item)) {
        stop("Unknown knowledge item: ", id, call. = FALSE)
      }
      item
    },

    #' @description
    #' List knowledge items with optional filters.
    list_items = function(type = NULL, domain = NULL) {
      items <- unname(self$items)
      if (!is.null(type)) {
        type <- .normalize_knowledge_item_type(type)
        items <- Filter(function(item) identical(item$type, type), items)
      }
      if (!is.null(domain)) {
        domain <- as.character(domain)[1]
        items <- Filter(function(item) identical(item$domain, domain), items)
      }
      items
    },

    #' @description
    #' Validate the knowledge specification.
    validate = function() {
      .validate_metadata_list(self$metadata)
      ids <- names(self$items)
      if (length(ids) && (is.null(ids) || any(!nzchar(ids)))) {
        stop("KnowledgeSpec items must be named by knowledge id.", call. = FALSE)
      }
      if (anyDuplicated(ids)) {
        stop("KnowledgeSpec item ids must be unique.", call. = FALSE)
      }
      for (item in self$items) {
        validate_knowledge_item(item)
      }
      self$graph <- .coerce_graph_representation_or_null(self$graph)
      .validate_metadata_list(self$vector_refs, "vector_refs")
      invisible(self)
    },

    #' @description
    #' Return a serializable representation.
    to_list = function() {
      self$validate()
      list(
        items = unname(self$items),
        graph = self$graph,
        vector_refs = self$vector_refs,
        metadata = self$metadata
      )
    },

    #' @description
    #' Print a compact summary.
    print = function(...) {
      self$validate()
      cat("<KnowledgeSpec>\n")
      cat("Narrative items:", length(self$items), "\n")
      graph_nodes <- if (is.null(self$graph)) 0L else length(self$graph$nodes)
      cat("Graph nodes:", graph_nodes, "\n")
      cat("Vector refs:", length(self$vector_refs), "\n")
      invisible(self)
    }
  )
)

#' Validate a knowledge specification
#'
#' @param x A [`KnowledgeSpec`] object.
#'
#' @return The validated object, invisibly.
#' @export
validate_knowledge_spec <- function(x) {
  if (!inherits(x, "KnowledgeSpec")) {
    stop("`x` must be a `KnowledgeSpec`.", call. = FALSE)
  }
  x$validate()
}

#' @keywords internal
.knowledge_spec_from_list <- function(x) {
  x <- .normalize_spec_arrays(x)
  if (!is.list(x) || !all(c("items", "graph", "vector_refs", "metadata") %in% names(x))) {
    stop("Knowledge spec JSON must contain top-level `items`, `graph`, `vector_refs`, and `metadata` fields.", call. = FALSE)
  }
  KnowledgeSpec$new(
    items = x$items,
    graph = x$graph,
    vector_refs = x$vector_refs,
    metadata = x$metadata
  )
}
