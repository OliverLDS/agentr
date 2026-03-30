#' Create a workflow node record
#'
#' @param id Node identifier.
#' @param label Human-readable node label.
#' @param confidence Provisional confidence score between 0 and 1.
#' @param human_required Whether human confirmation is required.
#' @param rule_spec Optional node-specific rule specification.
#' @param implementation_hint Optional implementation hint.
#' @param complete Whether the node is considered complete.
#' @param review_status Node-level review status.
#' @param review_notes Optional node-level review notes.
#' @param review_confidence Optional confidence attached to the latest review.
#'
#' @return One-row data frame.
#' @export
workflow_node <- function(
  id,
  label,
  confidence = NA_real_,
  human_required = TRUE,
  rule_spec = NA_character_,
  implementation_hint = NA_character_,
  complete = FALSE,
  review_status = "pending",
  review_notes = NA_character_,
  review_confidence = NA_real_
) {
  data.frame(
    id = as.character(id),
    label = as.character(label),
    confidence = as.numeric(confidence),
    human_required = as.logical(human_required),
    rule_spec = as.character(rule_spec),
    implementation_hint = as.character(implementation_hint),
    complete = as.logical(complete),
    review_status = as.character(review_status),
    review_notes = as.character(review_notes),
    review_confidence = as.numeric(review_confidence),
    stringsAsFactors = FALSE
  )
}

#' Create a workflow edge record
#'
#' @param from Source node id.
#' @param to Target node id.
#' @param relation Edge relation label.
#' @param confidence Optional edge confidence score between 0 and 1.
#' @param notes Optional edge notes.
#'
#' @return One-row data frame.
#' @export
workflow_edge <- function(
  from,
  to,
  relation = "depends_on",
  confidence = NA_real_,
  notes = NA_character_
) {
  data.frame(
    from = as.character(from),
    to = as.character(to),
    relation = as.character(relation),
    confidence = as.numeric(confidence),
    notes = as.character(notes),
    stringsAsFactors = FALSE
  )
}

#' @keywords internal
.empty_workflow_nodes <- function() {
  workflow_node(
    id = character(),
    label = character(),
    confidence = numeric(),
    human_required = logical(),
    rule_spec = character(),
    implementation_hint = character(),
    complete = logical(),
    review_status = character(),
    review_notes = character(),
    review_confidence = numeric()
  )
}

#' @keywords internal
.empty_workflow_edges <- function() {
  workflow_edge(
    from = character(),
    to = character(),
    relation = character(),
    confidence = numeric(),
    notes = character()
  )
}

#' Create a workflow specification
#'
#' Workflow specifications are outputs of reasoning and scaffolding rather than
#' fixed package logic. The object captures DAG-like workflow structure and the
#' minimal metadata needed for downstream implementation translation.
#'
#' @param nodes Data frame of workflow nodes.
#' @param edges Data frame of workflow edges.
#' @param task Optional source task text.
#' @param metadata Additional metadata list.
#'
#' @return An object of class `agentr_workflow_spec`.
#' @export
new_workflow_spec <- function(
  nodes = workflow_node("task", "Task"),
  edges = data.frame(
    from = character(),
    to = character(),
    relation = character(),
    stringsAsFactors = FALSE
  ),
  task = NULL,
  metadata = list()
) {
  spec <- list(
    nodes = nodes,
    edges = edges,
    task = task,
    metadata = metadata
  )
  class(spec) <- c("agentr_workflow_spec", class(spec))
  validate_workflow_spec(spec)
}

#' Validate a workflow specification
#'
#' @param x Workflow specification.
#'
#' @return The validated object, invisibly.
#' @export
validate_workflow_spec <- function(x) {
  required_nodes <- c(
    "id", "label", "confidence", "human_required",
    "rule_spec", "implementation_hint", "complete",
    "review_status", "review_notes", "review_confidence"
  )
  required_edges <- c("from", "to", "relation", "confidence", "notes")

  if (!is.list(x) || !all(c("nodes", "edges", "task", "metadata") %in% names(x))) {
    stop("Workflow spec must contain nodes, edges, task, and metadata.", call. = FALSE)
  }
  if (!is.data.frame(x$nodes)) {
    stop("Workflow spec `nodes` must be a data frame.", call. = FALSE)
  }
  if (!is.data.frame(x$edges)) {
    stop("Workflow spec `edges` must be a data frame.", call. = FALSE)
  }
  if (!all(required_nodes %in% names(x$nodes))) {
    stop("Workflow spec nodes are missing required columns.", call. = FALSE)
  }
  if (!all(required_edges %in% names(x$edges))) {
    stop("Workflow spec edges are missing required columns.", call. = FALSE)
  }
  if (anyDuplicated(x$nodes$id)) {
    stop("Workflow node ids must be unique.", call. = FALSE)
  }
  if (!is.null(x$task) && (!is.character(x$task) || length(x$task) != 1L)) {
    stop("Workflow task must be NULL or a single character string.", call. = FALSE)
  }
  if (!is.list(x$metadata)) {
    stop("Workflow metadata must be a list.", call. = FALSE)
  }

  numeric_fields <- c(
    x$nodes$confidence,
    x$nodes$review_confidence,
    x$edges$confidence
  )
  numeric_fields <- numeric_fields[!is.na(numeric_fields)]
  if (length(numeric_fields) && any(numeric_fields < 0 | numeric_fields > 1)) {
    stop("Workflow confidence values must be in [0, 1].", call. = FALSE)
  }

  edge_refs <- unique(c(x$edges$from, x$edges$to))
  edge_refs <- edge_refs[nzchar(edge_refs)]
  if (length(edge_refs) && any(!(edge_refs %in% x$nodes$id))) {
    stop("Workflow edges must reference existing node ids.", call. = FALSE)
  }
  invisible(x)
}

#' Save a workflow specification
#'
#' @param workflow Workflow specification.
#' @param file_path File path where the workflow should be saved.
#'
#' @return Invisibly returns `TRUE`.
#' @export
save_workflow_spec <- function(workflow, file_path) {
  validate_workflow_spec(workflow)
  .safe_save_rds(workflow, file_path)
  invisible(TRUE)
}

#' Load a workflow specification
#'
#' @param file_path File path from which to load the workflow.
#'
#' @return Workflow specification.
#' @export
load_workflow_spec <- function(file_path) {
  if (!file.exists(file_path)) {
    stop("File does not exist: ", file_path, call. = FALSE)
  }
  workflow <- .safe_read_rds(file_path)
  validate_workflow_spec(workflow)
}

#' Format a workflow specification
#'
#' @param x Workflow specification.
#' @param ... Unused.
#'
#' @export
print.agentr_workflow_spec <- function(x, ...) {
  cat("<agentr_workflow_spec>\n")
  cat("Task:", if (is.null(x$task)) "<unspecified>" else x$task, "\n")
  cat("Nodes:", nrow(x$nodes), "\n")
  cat("Edges:", nrow(x$edges), "\n")
  invisible(x)
}
