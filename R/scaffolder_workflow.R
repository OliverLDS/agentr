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
    agent_name = if (is.null(scaffolder$agent_state$approved_agent_spec)) {
      NA_character_
    } else {
      scaffolder$agent_state$approved_agent_spec$agent_name
    },
    selected_subsystems = scaffolder$selected_subsystems(),
    node_subsystems = scaffolder$workflow$metadata$node_subsystems %||% list(),
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
  if (!is.null(scaffolder$agent_state$approved_agent_spec)) {
    scaffolder$agent_state$approved_agent_spec$workflow <- scaffolder$workflow
    scaffolder$agent_state$approved_agent_spec$metadata$node_subsystems <-
      scaffolder$workflow$metadata$node_subsystems %||% list()
    scaffolder$agent_state$approved_agent_spec$validate()
  }
  .scaffolder_sync_legacy_state(scaffolder)
}

#' @keywords internal
.default_subsystem_config <- function(name) {
  switch(
    name,
    rwm = RWMConfig$new(cognitive = CognitiveConfig$new(), affective = NULL),
    pg = PGConfig$new(),
    ae = AEConfig$new(),
    iac = IACConfig$new(),
    la = LAConfig$new(),
    stop("Unsupported subsystem: ", name, call. = FALSE)
  )
}

#' @keywords internal
.coerce_subsystem_selection <- function(subsystems) {
  allowed <- c("rwm", "pg", "ae", "iac", "la")

  if (inherits(subsystems, "SubsystemSpec")) {
    return(subsystems)
  }

  if (is.character(subsystems) && is.null(names(subsystems))) {
    selected <- unique(as.character(subsystems))
    invalid <- setdiff(selected, allowed)
    if (length(invalid)) {
      stop("Unsupported subsystem names: ", paste(invalid, collapse = ", "), call. = FALSE)
    }
    payload <- stats::setNames(vector("list", length(allowed)), allowed)
    for (name in selected) {
      payload[[name]] <- .default_subsystem_config(name)
    }
    return(do.call(SubsystemSpec$new, payload))
  }

  if (!is.list(subsystems)) {
    stop(
      "`subsystems` must be a `SubsystemSpec`, a character vector, or a named list.",
      call. = FALSE
    )
  }

  if (is.null(names(subsystems)) || any(!nzchar(names(subsystems)))) {
    stop("Named subsystem lists must use subsystem names as list names.", call. = FALSE)
  }
  invalid <- setdiff(names(subsystems), allowed)
  if (length(invalid)) {
    stop("Unsupported subsystem names: ", paste(invalid, collapse = ", "), call. = FALSE)
  }

  payload <- stats::setNames(vector("list", length(allowed)), allowed)
  for (name in allowed) {
    value <- subsystems[[name]]
    if (is.null(value) || identical(value, FALSE)) {
      payload[[name]] <- NULL
      next
    }
    if (identical(value, TRUE)) {
      payload[[name]] <- .default_subsystem_config(name)
      next
    }
    payload[[name]] <- value
  }

  do.call(SubsystemSpec$new, payload)
}

#' @keywords internal
.scaffolder_draft_subsystems <- function(scaffolder) {
  draft <- scaffolder$agent_state$metadata$draft_subsystems
  if (inherits(draft, "SubsystemSpec")) {
    return(draft)
  }
  if (!is.null(scaffolder$agent_state$approved_agent_spec)) {
    return(scaffolder$agent_state$approved_agent_spec$subsystems)
  }
  SubsystemSpec$new()
}

#' @keywords internal
.scaffolder_recommend_subsystems <- function(scaffolder, task = scaffolder$task) {
  stopifnot(inherits(scaffolder, "Scaffolder"))
  text <- paste(
    task %||% "",
    paste(scaffolder$workflow$nodes$label, collapse = " "),
    paste(scaffolder$workflow$nodes$rule_spec, collapse = " ")
  )
  text <- tolower(text)

  recommendations <- list()
  recommendations$pg <- list(
    recommended = TRUE,
    confidence = if (nrow(scaffolder$workflow$nodes)) 0.9 else 0.7,
    rationale = "Workflow decomposition benefits from explicit planning and goal tracking."
  )
  recommendations$ae <- list(
    recommended = TRUE,
    confidence = 0.8,
    rationale = "Task execution requires an action-oriented subsystem by default."
  )

  memory_terms <- c("memory", "remember", "history", "persistent", "profile", "context")
  affect_terms <- c("emotion", "affect", "empat", "companion", "sentiment", "mood")
  iac_terms <- c("api", "interface", "communicat", "channel", "tool", "integration", "message")
  learning_terms <- c("learn", "adapt", "feedback", "improve", "optimi")

  if (any(grepl(paste(memory_terms, collapse = "|"), text))) {
    recommendations$rwm <- list(
      recommended = TRUE,
      confidence = 0.78,
      rationale = "The task suggests persistent or structured working memory."
    )
  }
  if (any(grepl(paste(affect_terms, collapse = "|"), text))) {
    recommendations$rwm <- recommendations$rwm %||% list(
      recommended = TRUE,
      confidence = 0.7,
      rationale = "The task suggests non-trivial reflective state."
    )
    recommendations$rwm$rationale <- paste(
      recommendations$rwm$rationale,
      "An affective layer appears justified."
    )
  }
  if (any(grepl(paste(iac_terms, collapse = "|"), text))) {
    recommendations$iac <- list(
      recommended = TRUE,
      confidence = 0.74,
      rationale = "The task references external interfaces or communication channels."
    )
  }
  if (any(grepl(paste(learning_terms, collapse = "|"), text))) {
    recommendations$la <- list(
      recommended = TRUE,
      confidence = 0.72,
      rationale = "The task references adaptation or feedback-driven improvement."
    )
  }

  scaffolder$agent_state$metadata$subsystem_recommendations <- recommendations
  recommendations
}
