#' @keywords internal
.scaffolder_next_workflow_proposal_id <- function(scaffolder) {
  paste0("proposal_", length(scaffolder$proposal_log) + 1L)
}

#' @keywords internal
.scaffolder_store_workflow_proposal <- function(scaffolder, proposal) {
  proposal <- .as_workflow_proposal_object(proposal)
  scaffolder$workflow_state$add_proposal(proposal)
  .scaffolder_sync_legacy_state(scaffolder)
  invisible(proposal)
}

#' @keywords internal
.scaffolder_edit_workflow <- function(
  scaffolder,
  add = NULL,
  insert = NULL,
  remove = NULL,
  add_edges = NULL,
  remove_edges = NULL,
  rule_specs = list(),
  confidence = list()
) {
  nodes <- scaffolder$workflow$nodes
  edges <- scaffolder$workflow$edges

  if (!is.null(remove) && length(remove)) {
    nodes <- nodes[!(nodes$id %in% remove), , drop = FALSE]
  }

  additions <- .coerce_node_records(add, nodes)
  if (nrow(additions)) {
    nodes <- rbind(nodes, additions)
  }

  inserted <- .insert_workflow_nodes(nodes, edges, insert)
  nodes <- inserted$nodes
  edges <- inserted$edges

  explicit_edges <- .coerce_edge_specs(add_edges)
  if (nrow(explicit_edges)) {
    edges <- rbind(edges, explicit_edges)
  }

  edges <- .remove_edge_specs(edges, remove_edges)
  nodes <- .apply_named_node_values(nodes, rule_specs, "rule_spec", as.character)
  nodes <- .apply_named_node_values(nodes, confidence, "confidence", function(x) {
    .as_optional_confidence(x)
  })

  edges <- edges[
    edges$from %in% nodes$id &
      edges$to %in% nodes$id,
    ,
    drop = FALSE
  ]
  edges <- .deduplicate_edges(edges)

  scaffolder$workflow <- new_workflow_spec(
    nodes = nodes,
    edges = edges,
    task = scaffolder$task,
    metadata = scaffolder$workflow$metadata
  )
  .scaffolder_sync_approved_workflow(scaffolder)

  scaffolder$workflow
}

#' @keywords internal
.scaffolder_implementation_spec <- function(scaffolder) {
  stopifnot(inherits(scaffolder, "Scaffolder"))
  nodes <- scaffolder$workflow_spec()$nodes
  list(
    task = scaffolder$task,
    nodes = nodes[, c("id", "label", "rule_spec", "implementation_hint"), drop = FALSE],
    human_required = nodes[nodes$human_required, "id", drop = TRUE]
  )
}

#' @keywords internal
.scaffolder_supersede_other_active_proposals <- function(
  scaffolder,
  approved_proposal_id,
  timestamp = Sys.time()
) {
  stopifnot(inherits(scaffolder, "Scaffolder"))
  invisible(scaffolder)
}

#' @keywords internal
.scaffolder_sync_legacy_state <- function(scaffolder) {
  stopifnot(inherits(scaffolder, "Scaffolder"))
  scaffolder$workflow <- scaffolder$workflow_state$approved_workflow
  scaffolder$proposal_log <- lapply(
    scaffolder$workflow_state$proposals,
    function(item) item$as_list()
  )
  invisible(scaffolder)
}

#' @keywords internal
.scaffolder_sync_approved_workflow <- function(scaffolder) {
  stopifnot(inherits(scaffolder, "Scaffolder"))
  scaffolder$workflow_state$set_approved_workflow(scaffolder$workflow)
  .scaffolder_sync_legacy_state(scaffolder)
}
