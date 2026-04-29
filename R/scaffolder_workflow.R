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
.agent_spec_proposal_statuses <- function() {
  c("draft", "under_discussion", "approved", "superseded", "rejected")
}

#' @keywords internal
.normalize_agent_spec_proposal_status <- function(status) {
  match.arg(status, choices = .agent_spec_proposal_statuses())
}

#' @keywords internal
.next_agent_spec_proposal_id <- function(scaffolder) {
  proposals <- scaffolder$agent_state$proposal_state$proposals %||% list()
  paste0("agent_proposal_", length(proposals) + 1L)
}

#' @keywords internal
.new_agent_spec_proposal <- function(
  id,
  agent_spec,
  status = "draft",
  source = "model",
  notes = NULL,
  workflow_proposal_id = NULL,
  discussion_rounds = list(),
  created_at = Sys.time(),
  updated_at = created_at,
  approved_at = as.POSIXct(NA),
  superseded_by = NA_character_,
  supersedes = NA_character_,
  rejected_at = as.POSIXct(NA)
) {
  if (!inherits(agent_spec, "AgentSpec")) {
    stop("`agent_spec` must be an `AgentSpec`.", call. = FALSE)
  }
  agent_spec$validate()
  proposal <- list(
    id = as.character(id)[1],
    status = .normalize_agent_spec_proposal_status(status),
    source = .normalize_scaffolder_source(source),
    notes = if (is.null(notes)) NA_character_ else as.character(notes)[1],
    agent_spec = agent_spec,
    workflow_proposal_id = if (is.null(workflow_proposal_id)) NA_character_ else as.character(workflow_proposal_id)[1],
    discussion_rounds = discussion_rounds %||% list(),
    created_at = as.POSIXct(created_at)[1],
    updated_at = as.POSIXct(updated_at)[1],
    approved_at = .proposal_time_or_na(approved_at),
    superseded_by = if (is.null(superseded_by)) NA_character_ else as.character(superseded_by)[1],
    supersedes = if (is.null(supersedes)) NA_character_ else as.character(supersedes)[1],
    rejected_at = .proposal_time_or_na(rejected_at)
  )
  class(proposal) <- c("agentr_agent_spec_proposal", class(proposal))
  .validate_agent_spec_proposal(proposal)
}

#' @keywords internal
.validate_agent_spec_proposal <- function(x) {
  required_fields <- c(
    "id", "status", "source", "notes", "agent_spec", "workflow_proposal_id",
    "discussion_rounds", "created_at", "updated_at", "approved_at",
    "superseded_by", "supersedes", "rejected_at"
  )
  if (!is.list(x) || !all(required_fields %in% names(x))) {
    stop("Agent spec proposal must contain the required proposal fields.", call. = FALSE)
  }
  if (!is.character(x$id) || length(x$id) != 1L || !nzchar(x$id)) {
    stop("Agent spec proposal `id` must be a non-empty string.", call. = FALSE)
  }
  .normalize_agent_spec_proposal_status(x$status)
  if (!inherits(x$agent_spec, "AgentSpec")) {
    stop("Agent spec proposal `agent_spec` must be an `AgentSpec`.", call. = FALSE)
  }
  x$agent_spec$validate()
  if (!is.list(x$discussion_rounds)) {
    stop("Agent spec proposal `discussion_rounds` must be a list.", call. = FALSE)
  }
  invisible(x)
}

#' @keywords internal
.agent_spec_proposal_summary <- function(x) {
  .validate_agent_spec_proposal(x)
  data.frame(
    id = x$id,
    status = x$status,
    source = x$source,
    notes = x$notes,
    agent_name = x$agent_spec$agent_name,
    selected_subsystems = paste(x$agent_spec$selected_subsystems(), collapse = ", "),
    workflow_nodes = if (is.null(x$agent_spec$workflow)) 0L else nrow(x$agent_spec$workflow$nodes),
    workflow_proposal_id = x$workflow_proposal_id,
    created_at = x$created_at,
    updated_at = x$updated_at,
    approved_at = x$approved_at,
    superseded_by = x$superseded_by,
    supersedes = x$supersedes,
    stringsAsFactors = FALSE
  )
}

#' @keywords internal
.agent_spec_proposal_can_transition <- function(proposal, to_status) {
  .validate_agent_spec_proposal(proposal)
  to_status <- .normalize_agent_spec_proposal_status(to_status)
  if (identical(proposal$status, to_status)) {
    return(TRUE)
  }
  allowed <- list(
    draft = c("under_discussion", "approved", "superseded", "rejected"),
    under_discussion = c("approved", "superseded", "rejected"),
    approved = character(),
    superseded = character(),
    rejected = character()
  )
  to_status %in% allowed[[proposal$status]]
}

#' @keywords internal
.transition_agent_spec_proposal <- function(
  proposal,
  to_status,
  timestamp = Sys.time(),
  superseded_by = NULL,
  supersedes = NULL
) {
  .validate_agent_spec_proposal(proposal)
  to_status <- .normalize_agent_spec_proposal_status(to_status)
  if (!.agent_spec_proposal_can_transition(proposal, to_status)) {
    stop(
      "Invalid agent spec proposal transition from `",
      proposal$status,
      "` to `",
      to_status,
      "`.",
      call. = FALSE
    )
  }
  timestamp <- as.POSIXct(timestamp)[1]
  proposal$status <- to_status
  proposal$updated_at <- timestamp
  if (identical(to_status, "approved")) {
    proposal$approved_at <- timestamp
    proposal$rejected_at <- as.POSIXct(NA)
  }
  if (identical(to_status, "rejected")) {
    proposal$rejected_at <- timestamp
  }
  if (identical(to_status, "superseded")) {
    proposal$superseded_by <- if (is.null(superseded_by)) NA_character_ else as.character(superseded_by)[1]
  }
  if (!is.null(supersedes)) {
    proposal$supersedes <- as.character(supersedes)[1]
  }
  .validate_agent_spec_proposal(proposal)
  proposal
}

#' @keywords internal
.append_agent_spec_proposal_discussion <- function(
  proposal,
  feedback,
  source = "human",
  confidence = NA_real_,
  timestamp = Sys.time()
) {
  .validate_agent_spec_proposal(proposal)
  if (!is.character(feedback) || length(feedback) != 1L || !nzchar(feedback)) {
    stop("`feedback` must be a non-empty string.", call. = FALSE)
  }
  if (identical(proposal$status, "approved")) {
    stop("Cannot discuss an approved agent spec proposal directly.", call. = FALSE)
  }
  round <- list(
    source = .normalize_scaffolder_source(source),
    feedback = feedback,
    confidence = .as_optional_confidence(confidence),
    discussed_at = as.POSIXct(timestamp)[1]
  )
  proposal$discussion_rounds <- c(proposal$discussion_rounds, list(round))
  proposal$updated_at <- round$discussed_at
  if (identical(proposal$status, "draft")) {
    proposal <- .transition_agent_spec_proposal(
      proposal,
      to_status = "under_discussion",
      timestamp = round$discussed_at
    )
  }
  list(proposal = proposal, round = round)
}

#' @keywords internal
.scaffolder_agent_spec_proposals <- function(scaffolder) {
  scaffolder$agent_state$proposal_state$proposals %||% list()
}

#' @keywords internal
.scaffolder_store_agent_spec_proposal <- function(scaffolder, proposal) {
  .validate_agent_spec_proposal(proposal)
  proposals <- .scaffolder_agent_spec_proposals(scaffolder)
  proposals[[proposal$id]] <- proposal
  scaffolder$agent_state$proposal_state$proposals <- proposals
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
.node_subsystem_labels <- function(scaffolder) {
  scaffolder$workflow$metadata$node_subsystems %||% list()
}

#' @keywords internal
.scaffolder_edit_workflow_subsystems <- function(
  scaffolder,
  set = NULL,
  add = NULL,
  remove = NULL,
  clear = NULL
) {
  stopifnot(inherits(scaffolder, "Scaffolder"))
  labels <- .node_subsystem_labels(scaffolder)
  selected <- scaffolder$selected_subsystems()

  if (!is.null(set)) {
    labels <- .validate_node_subsystems(set, nodes = scaffolder$workflow$nodes)
  }

  if (!is.null(add)) {
    add <- .validate_node_subsystems(add, nodes = scaffolder$workflow$nodes)
    for (node_id in names(add)) {
      labels[[node_id]] <- unique(c(labels[[node_id]] %||% character(), add[[node_id]]))
    }
  }

  if (!is.null(remove)) {
    remove <- .validate_node_subsystems(remove, nodes = scaffolder$workflow$nodes)
    for (node_id in names(remove)) {
      current <- labels[[node_id]] %||% character()
      labels[[node_id]] <- setdiff(current, remove[[node_id]])
      if (!length(labels[[node_id]])) {
        labels[[node_id]] <- character()
      }
    }
  }

  if (!is.null(clear)) {
    clear <- as.character(unlist(clear, use.names = FALSE))
    if (length(clear) && any(!(clear %in% scaffolder$workflow$nodes$id))) {
      stop("`clear` contains unknown workflow node ids.", call. = FALSE)
    }
    for (node_id in clear) {
      labels[[node_id]] <- character()
    }
  }

  if (length(labels)) {
    invalid <- setdiff(unique(unlist(labels, use.names = FALSE)), selected)
    if (length(invalid)) {
      stop(
        "Workflow node ownership requires selected subsystems only: ",
        paste(invalid, collapse = ", "),
        call. = FALSE
      )
    }
  }

  scaffolder$workflow$metadata$node_subsystems <- labels
  if (!is.null(scaffolder$agent_state$approved_agent_spec)) {
    scaffolder$agent_state$approved_agent_spec$metadata$node_subsystems <- labels
  }
  labels
}

#' @keywords internal
.scaffolder_build_agent_spec <- function(
  scaffolder,
  agent_name = "agentr-agent",
  summary = NULL,
  subsystems = .scaffolder_draft_subsystems(scaffolder),
  workflow = scaffolder$workflow,
  state_requirements = list(),
  interfaces = list(),
  implementation_targets = list(),
  metadata = list()
) {
  if (is.null(scaffolder$task) || !nzchar(scaffolder$task)) {
    stop("A task must be evaluated before creating an agent spec.", call. = FALSE)
  }
  AgentSpec$new(
    task = scaffolder$task,
    agent_name = agent_name,
    summary = summary %||% scaffolder$workflow$metadata$evaluation$summary %||% scaffolder$task,
    subsystems = subsystems,
    workflow = workflow,
    state_requirements = state_requirements,
    interfaces = interfaces,
    implementation_targets = implementation_targets,
    metadata = utils::modifyList(
      list(
        node_subsystems = workflow$metadata$node_subsystems %||% list(),
        subsystem_recommendations = scaffolder$agent_state$metadata$subsystem_recommendations %||% list(),
        approved_at = Sys.time()
      ),
      metadata
    )
  )
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
    selected <- normalize_subsystem_key(subsystems)
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
  names(subsystems) <- normalize_subsystem_key(names(subsystems))
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
    rationale = "Most workflows require some perception and grounding of inputs, artifacts, or source claims."
  )
  recommendations$rwm <- list(
    recommended = TRUE,
    confidence = 0.82,
    rationale = "Most workflows require reasoning, strategy choice, or an internal world model."
  )
  recommendations$ae <- list(
    recommended = TRUE,
    confidence = 0.8,
    rationale = "Task execution requires an action-execution subsystem by default."
  )

  memory_terms <- c("memory", "remember", "history", "persistent", "profile", "context")
  reasoning_terms <- c("plan", "reason", "infer", "strategy", "forecast", "decide", "judge")
  affect_terms <- c("emotion", "affect", "empat", "companion", "sentiment", "mood")
  iac_terms <- c("multi-agent", "other agent", "handoff", "role negotiation", "agent message", "coordination")
  interface_terms <- c("api", "interface", "channel", "tool", "integration")
  learning_terms <- c("learn", "adapt", "feedback", "improve", "optimi")

  if (any(grepl(paste(c(memory_terms, reasoning_terms), collapse = "|"), text))) {
    recommendations$rwm <- list(
      recommended = TRUE,
      confidence = 0.78,
      rationale = "The task suggests explicit reasoning, planning, memory, or world-model structure."
    )
  }
  if (any(grepl(paste(affect_terms, collapse = "|"), text))) {
    if (is.null(recommendations$rwm)) {
      recommendations$rwm <- list(
        recommended = TRUE,
        confidence = 0.7,
        rationale = "The task suggests non-trivial reasoning or world-model state."
      )
    }
    recommendations$rwm$rationale <- paste(
      recommendations$rwm$rationale,
      "An affective layer appears justified."
    )
  }
  if (any(grepl(paste(interface_terms, collapse = "|"), text))) {
    recommendations$pg$rationale <- paste(
      recommendations$pg$rationale,
      "Interface-facing artifacts may also require stronger grounding."
    )
  }
  if (any(grepl(paste(iac_terms, collapse = "|"), text))) {
    recommendations$iac <- list(
      recommended = TRUE,
      confidence = 0.74,
      rationale = "The task references genuine inter-agent communication or multi-agent coordination."
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
