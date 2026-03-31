#' @keywords internal
.scaffolder_next_workflow_proposal_id <- function(scaffolder) {
  paste0("proposal_", length(scaffolder$proposal_log) + 1L)
}

#' @keywords internal
.scaffolder_store_workflow_proposal <- function(scaffolder, proposal) {
  validate_workflow_proposal(proposal)
  scaffolder$proposal_log[[proposal$id]] <- proposal
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

  active_ids <- names(scaffolder$proposal_log)
  for (proposal_id in active_ids) {
    if (identical(proposal_id, approved_proposal_id)) {
      next
    }
    proposal <- scaffolder$proposal_log[[proposal_id]]
    if (is.null(proposal) || !(proposal$status %in% c("pending", "under_discussion"))) {
      next
    }
    proposal <- transition_workflow_proposal(
      proposal,
      to_status = "superseded",
      timestamp = timestamp,
      superseded_by = approved_proposal_id
    )
    .scaffolder_store_workflow_proposal(scaffolder, proposal)
  }

  invisible(scaffolder)
}
