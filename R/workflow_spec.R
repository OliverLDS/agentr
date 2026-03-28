#' Create a workflow node record
#'
#' @param id Node identifier.
#' @param label Human-readable node label.
#' @param confidence Provisional confidence score between 0 and 1.
#' @param human_required Whether human confirmation is required.
#' @param rule_spec Optional node-specific rule specification.
#' @param implementation_hint Optional implementation hint.
#' @param complete Whether the node is considered complete.
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
  complete = FALSE
) {
  data.frame(
    id = as.character(id),
    label = as.character(label),
    confidence = as.numeric(confidence),
    human_required = as.logical(human_required),
    rule_spec = as.character(rule_spec),
    implementation_hint = as.character(implementation_hint),
    complete = as.logical(complete),
    stringsAsFactors = FALSE
  )
}

#' Create a workflow edge record
#'
#' @param from Source node id.
#' @param to Target node id.
#' @param relation Edge relation label.
#'
#' @return One-row data frame.
#' @export
workflow_edge <- function(from, to, relation = "depends_on") {
  data.frame(
    from = as.character(from),
    to = as.character(to),
    relation = as.character(relation),
    stringsAsFactors = FALSE
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
    "rule_spec", "implementation_hint", "complete"
  )
  required_edges <- c("from", "to", "relation")

  if (!is.list(x) || !all(c("nodes", "edges", "task", "metadata") %in% names(x))) {
    stop("Workflow spec must contain nodes, edges, task, and metadata.", call. = FALSE)
  }
  if (!all(required_nodes %in% names(x$nodes))) {
    stop("Workflow spec nodes are missing required columns.", call. = FALSE)
  }
  if (!all(required_edges %in% names(x$edges))) {
    stop("Workflow spec edges are missing required columns.", call. = FALSE)
  }
  invisible(x)
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
