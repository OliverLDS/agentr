#' Return standard `agentr` workspace paths
#'
#' @param workspace Workspace root directory.
#'
#' @return Named list of workspace paths.
#' @export
agentr_workspace_paths <- function(workspace) {
  workspace <- .workspace_root(workspace)
  list(
    root = workspace,
    specs = file.path(workspace, "specs"),
    proposal_states = file.path(workspace, "proposal_states"),
    prompts = file.path(workspace, "prompts"),
    initial_prompts = file.path(workspace, "prompts", "initial"),
    revision_prompts = file.path(workspace, "prompts", "revision"),
    implementation_prompts = file.path(workspace, "prompts", "implementation"),
    reviews = file.path(workspace, "reviews"),
    traces = file.path(workspace, "traces"),
    responses = file.path(workspace, "responses"),
    handoffs = file.path(workspace, "handoffs"),
    agent_spec = file.path(workspace, "specs", "agent_spec.rds"),
    scaffolder_state = file.path(workspace, "proposal_states", "scaffolder_state.rds"),
    workflow_state = file.path(workspace, "proposal_states", "workflow_state.rds"),
    memory_state = file.path(workspace, "proposal_states", "memory_state.rds"),
    knowledge_state = file.path(workspace, "proposal_states", "knowledge_state.rds")
  )
}

#' Initialize a generic `agentr` lifecycle workspace
#'
#' Creates workspace-scoped directories for specs, proposal states, prompts,
#' reviews, traces, responses, and handoff prompts. It does not seed
#' domain-specific content.
#'
#' @param workspace Workspace root directory.
#' @param comment Optional workspace note.
#' @param create_readme Whether to create a minimal workspace README.
#'
#' @return Named list of created workspace paths.
#' @export
init_agentr_workspace <- function(workspace, comment = NULL, create_readme = TRUE) {
  paths <- agentr_workspace_paths(workspace)
  dirs <- unlist(paths[c(
    "root", "specs", "proposal_states", "prompts", "initial_prompts",
    "revision_prompts", "implementation_prompts", "reviews", "traces",
    "responses", "handoffs"
  )], use.names = FALSE)
  for (dir in dirs) {
    if (!dir.exists(dir)) {
      dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    }
  }

  if (isTRUE(create_readme)) {
    readme <- c(
      "# agentr workspace",
      "",
      "This workspace stores design artifacts created by the agentr scaffolding lifecycle.",
      "",
      "- `specs/`: approved design specs.",
      "- `proposal_states/`: workflow, memory, knowledge, graph, and scaffolder proposal states.",
      "- `prompts/`: prompt files for manual LLM calls.",
      "- `responses/`: JSON responses saved from external LLM calls.",
      "- `reviews/`: exported design-review HTML.",
      "- `traces/`: optional decision and reflection traces.",
      "- `handoffs/`: implementation handoff prompts.",
      "",
      "agentr does not execute the agent runtime from this workspace; it stores scaffolding and review artifacts."
    )
    if (!is.null(comment) && nzchar(as.character(comment)[1])) {
      readme <- c(readme, "", "## Workspace Note", "", as.character(comment)[1])
    }
    writeLines(readme, file.path(paths$root, "README.md"), useBytes = TRUE)
  }

  invisible(paths)
}

#' Initialize proposal-state artifacts for an `agentr` workspace
#'
#' @param workspace Workspace root directory.
#' @param agent_spec_path Optional path to an approved [`AgentSpec`] `.rds`.
#'
#' @return Named list containing initialized state objects.
#' @export
init_agentr_proposal_states <- function(workspace, agent_spec_path = NULL) {
  paths <- init_agentr_workspace(workspace, create_readme = FALSE)
  spec <- .workspace_load_agent_spec(agent_spec_path, paths)
  workflow <- .workspace_agent_workflow(spec)
  knowledge_spec <- .workspace_agent_knowledge(spec)
  memory_spec <- .workspace_agent_memory(spec)

  workflow_state <- WorkflowProposalState$new(approved_workflow = workflow)
  memory_state <- MemoryProposalState$new(approved_memory_spec = memory_spec)
  knowledge_state <- KnowledgeProposalState$new(approved_knowledge_spec = knowledge_spec)
  scaffolder <- .workspace_scaffolder(spec, workflow_state)

  saveRDS(workflow_state, paths$workflow_state)
  saveRDS(memory_state, paths$memory_state)
  saveRDS(knowledge_state, paths$knowledge_state)
  saveRDS(scaffolder, paths$scaffolder_state)
  if (!is.null(spec) && !file.exists(paths$agent_spec)) {
    save_agent_spec(spec, paths$agent_spec)
  }

  invisible(list(
    workflow_state = workflow_state,
    memory_state = memory_state,
    knowledge_state = knowledge_state,
    scaffolder = scaffolder
  ))
}

#' Build an initial design prompt into a workspace
#'
#' @param workspace Workspace root directory.
#' @param target Prompt target: workflow, agent, memory, or knowledge.
#' @param comment Natural-language task or design context.
#' @param out Optional output file path.
#' @param format Prompt payload format.
#'
#' @return Output prompt path.
#' @export
build_initial_spec_prompt <- function(
  workspace,
  target = c("workflow", "agent", "memory", "knowledge"),
  comment,
  out = NULL,
  format = c("markdown", "json")
) {
  target <- match.arg(target)
  format <- match.arg(format)
  paths <- init_agentr_workspace(workspace, create_readme = FALSE)
  comment <- .workspace_read_text(comment)

  prompt <- switch(
    target,
    workflow = {
      scaffolder <- Scaffolder$new()
      scaffolder$evaluate_task(comment)
      build_scaffolder_prompt(scaffolder, format = format)
    },
    agent = {
      scaffolder <- Scaffolder$new()
      scaffolder$evaluate_task(comment)
      scaffolder$recommend_subsystems(comment)
      build_agent_design_prompt(scaffolder, format = format)
    },
    memory = build_memory_schema_prompt(context = comment, current_memory = NULL, format = format),
    knowledge = build_knowledge_elicitation_prompt(context = comment, format = format)
  )

  if (is.null(out)) {
    ext <- if (identical(format, "json")) ".json" else ".md"
    out <- file.path(paths$initial_prompts, paste0(target, "_initial_prompt", ext))
  }
  .workspace_write_text(prompt, out)
  invisible(out)
}

#' Build a revision prompt into a workspace
#'
#' @param workspace Workspace root directory.
#' @param target Revision target: workflow, agent, memory, or knowledge.
#' @param comment Human revision feedback.
#' @param out Optional output file path.
#' @param agent_spec_path Optional path to approved [`AgentSpec`] `.rds`.
#' @param node_id Optional workflow node id. When supplied for workflow targets,
#'   the prompt is constrained to node schema and nested-workflow revision.
#' @param format Prompt payload format.
#'
#' @return Output prompt path.
#' @export
build_revision_prompt <- function(
  workspace,
  target = c("workflow", "agent", "memory", "knowledge"),
  comment,
  out = NULL,
  agent_spec_path = NULL,
  node_id = NULL,
  format = c("markdown", "json")
) {
  target <- match.arg(target)
  if (!is.null(node_id) && !identical(target, "workflow")) {
    stop("`node_id` is only supported when `target = \"workflow\"`.", call. = FALSE)
  }
  format <- match.arg(format)
  paths <- init_agentr_workspace(workspace, create_readme = FALSE)
  comment <- .workspace_read_text(comment)
  spec <- .workspace_load_agent_spec(agent_spec_path, paths)

  prompt <- switch(
    target,
    workflow = {
      workflow_state <- .workspace_load_or_default(
        paths$workflow_state,
        WorkflowProposalState$new(approved_workflow = .workspace_agent_workflow(spec))
      )
      scaffolder <- .workspace_scaffolder(spec, workflow_state)
      scaffolder$discuss_task(comment, source = "human")
      if (!is.null(node_id)) {
        build_node_detail_prompt(
          scaffolder$workflow_spec(),
          node_id = node_id,
          feedback = comment,
          include_nested_workflow = TRUE,
          format = format
        )
      } else {
        build_scaffolder_prompt(scaffolder, format = format)
      }
    },
    agent = {
      workflow_state <- .workspace_load_or_default(
        paths$workflow_state,
        WorkflowProposalState$new(approved_workflow = .workspace_agent_workflow(spec))
      )
      scaffolder <- .workspace_scaffolder(spec, workflow_state)
      scaffolder$discuss_task(comment, source = "human")
      build_agent_design_prompt(scaffolder, format = format)
    },
    memory = {
      memory_state <- .workspace_load_or_default(
        paths$memory_state,
        MemoryProposalState$new(approved_memory_spec = .workspace_agent_memory(spec))
      )
      build_memory_revision_prompt(memory_state, feedback = comment, format = format)
    },
    knowledge = {
      knowledge_state <- .workspace_load_or_default(
        paths$knowledge_state,
        KnowledgeProposalState$new(approved_knowledge_spec = .workspace_agent_knowledge(spec))
      )
      base <- build_knowledge_design_prompt(knowledge_state, format = format)
      if (identical(format, "json")) {
        paste(
          "{",
          '"human_feedback":',
          jsonlite::toJSON(comment, auto_unbox = TRUE),
          ', "knowledge_design_prompt":',
          jsonlite::toJSON(base, auto_unbox = TRUE),
          "}",
          sep = "\n"
        )
      } else {
        paste("# Knowledge Revision Prompt", "", "Human feedback:", comment, "", base, sep = "\n")
      }
    }
  )

  if (is.null(out)) {
    ext <- if (identical(format, "json")) ".json" else ".md"
    out <- file.path(paths$revision_prompts, paste0(target, "_revision_prompt", ext))
  }
  .workspace_write_text(prompt, out)
  invisible(out)
}

#' Apply an initial LLM response into a workspace proposal state
#'
#' @param workspace Workspace root directory.
#' @param target Target state: workflow, agent, memory, or knowledge.
#' @param message JSON string, parsed list, or path to a JSON response file.
#' @param comment Optional initial task context for workflow or agent targets.
#'
#' @return Mutated state object.
#' @export
apply_initial_spec_message <- function(
  workspace,
  target = c("workflow", "agent", "memory", "knowledge"),
  message,
  comment = NULL
) {
  target <- match.arg(target)
  paths <- init_agentr_workspace(workspace, create_readme = FALSE)
  if (identical(target, "workflow")) {
    scaffolder <- Scaffolder$new()
    task <- if (is.null(comment)) "Workspace design imported from initial LLM response" else .workspace_read_text(comment)
    scaffolder$evaluate_task(task)
    result <- preview_scaffolder_message(
      scaffolder,
      message,
      store_proposal = TRUE,
      source = "model",
      proposal_notes = "Workspace initial workflow proposal"
    )
    saveRDS(scaffolder, paths$scaffolder_state)
    saveRDS(scaffolder$workflow_state, paths$workflow_state)
    return(invisible(result))
  }

  if (identical(target, "agent")) {
    scaffolder <- Scaffolder$new()
    task <- if (is.null(comment)) "Workspace design imported from initial LLM response" else .workspace_read_text(comment)
    scaffolder$evaluate_task(task)
    result <- apply_scaffolder_message(scaffolder, message)
    saveRDS(scaffolder, paths$scaffolder_state)
    saveRDS(scaffolder$workflow_state, paths$workflow_state)
    approved <- scaffolder$agent_state$approved_agent_spec
    if (!is.null(approved)) {
      save_agent_spec(approved, paths$agent_spec)
    }
    return(invisible(result))
  }

  if (identical(target, "memory")) {
    state <- MemoryProposalState$new()
    apply_memory_message(state, message)
    saveRDS(state, paths$memory_state)
    return(invisible(state))
  }

  state <- KnowledgeProposalState$new()
  apply_knowledge_message(state, message)
  saveRDS(state, paths$knowledge_state)
  invisible(state)
}

#' Apply a revision LLM response into a workspace proposal state
#'
#' Workflow revisions are previewed and stored as proposals; approved specs are
#' not mutated by this function.
#'
#' @param workspace Workspace root directory.
#' @param target Target state: workflow, agent, memory, or knowledge.
#' @param message JSON string, parsed list, or path to a JSON response file.
#' @param agent_spec_path Optional path to approved [`AgentSpec`] `.rds`.
#' @param node_id Optional workflow node id. When supplied for workflow targets,
#'   only node-detail actions for this node are accepted.
#'
#' @return Mutated state object or preview result.
#' @export
apply_revision_message <- function(
  workspace,
  target = c("workflow", "agent", "memory", "knowledge"),
  message,
  agent_spec_path = NULL,
  node_id = NULL
) {
  target <- match.arg(target)
  if (!is.null(node_id) && !identical(target, "workflow")) {
    stop("`node_id` is only supported when `target = \"workflow\"`.", call. = FALSE)
  }
  paths <- init_agentr_workspace(workspace, create_readme = FALSE)
  spec <- .workspace_load_agent_spec(agent_spec_path, paths)

  if (identical(target, "workflow")) {
    workflow_state <- .workspace_load_or_default(
      paths$workflow_state,
      WorkflowProposalState$new(approved_workflow = .workspace_agent_workflow(spec))
    )
    scaffolder <- .workspace_scaffolder(spec, workflow_state)
    allowed_methods <- scaffolder_action_methods()
    proposal_notes <- "Workspace workflow revision preview"
    if (!is.null(node_id)) {
      allowed_methods <- c("set_node_schema", "set_node_nested_workflow", "discuss_task", "review_node")
      parsed <- if (is.character(message)) parse_scaffolder_message(message) else message
      parsed <- validate_scaffolder_message(parsed, allowed_methods = allowed_methods)
      .workspace_validate_node_detail_actions(parsed, node_id)
      message <- parsed
      proposal_notes <- paste0("Workspace node-detail revision preview for `", node_id, "`")
    }
    result <- preview_scaffolder_message(
      scaffolder,
      message,
      allowed_methods = allowed_methods,
      store_proposal = TRUE,
      source = "model",
      proposal_notes = proposal_notes
    )
    saveRDS(scaffolder, paths$scaffolder_state)
    saveRDS(scaffolder$workflow_state, paths$workflow_state)
    return(invisible(result))
  }

  if (identical(target, "agent")) {
    scaffolder <- .workspace_load_or_default(
      paths$scaffolder_state,
      .workspace_scaffolder(spec, .workspace_load_or_default(
        paths$workflow_state,
        WorkflowProposalState$new(approved_workflow = .workspace_agent_workflow(spec))
      ))
    )
    result <- apply_scaffolder_message(scaffolder, message)
    saveRDS(scaffolder, paths$scaffolder_state)
    saveRDS(scaffolder$workflow_state, paths$workflow_state)
    approved <- scaffolder$agent_state$approved_agent_spec
    if (!is.null(approved)) {
      save_agent_spec(approved, paths$agent_spec)
    }
    return(invisible(result))
  }

  if (identical(target, "memory")) {
    state <- .workspace_load_or_default(
      paths$memory_state,
      MemoryProposalState$new(approved_memory_spec = .workspace_agent_memory(spec))
    )
    apply_memory_message(state, message)
    saveRDS(state, paths$memory_state)
    return(invisible(state))
  }

  state <- .workspace_load_or_default(
    paths$knowledge_state,
    KnowledgeProposalState$new(approved_knowledge_spec = .workspace_agent_knowledge(spec))
  )
  apply_knowledge_message(state, message)
  saveRDS(state, paths$knowledge_state)
  invisible(state)
}

#' Apply a node-detail LLM response into a workspace workflow proposal
#'
#' This is a convenience wrapper for `apply_revision_message(target =
#' "workflow", node_id = ...)`. It previews the proposed node schema or nested
#' workflow edits and stores them as a workflow proposal; approved workflow state
#' is not mutated until the proposal is explicitly approved.
#'
#' @param workspace Workspace root directory.
#' @param node_id Workflow node id to revise.
#' @param message JSON string, parsed list, or path to a JSON response file.
#' @param agent_spec_path Optional path to approved [`AgentSpec`] `.rds`.
#'
#' @return Preview result.
#' @export
apply_node_detail_message <- function(
  workspace,
  node_id,
  message,
  agent_spec_path = NULL
) {
  apply_revision_message(
    workspace = workspace,
    target = "workflow",
    message = message,
    agent_spec_path = agent_spec_path,
    node_id = node_id
  )
}

#' List workspace proposals
#'
#' @param workspace Workspace root directory.
#' @param type Proposal type: workflow, agent, memory, or knowledge.
#' @param status Optional status filter.
#'
#' @return Data frame summary.
#' @export
list_workspace_proposals <- function(
  workspace,
  type = c("workflow", "agent", "memory", "knowledge"),
  status = NULL
) {
  type <- match.arg(type)
  paths <- agentr_workspace_paths(workspace)
  switch(
    type,
    workflow = .workspace_load_required(paths$workflow_state)$list_proposals(status),
    agent = .workspace_load_required(paths$scaffolder_state)$list_agent_spec_proposals(status),
    memory = .workspace_proposal_table(.workspace_load_required(paths$memory_state)$list_proposals(status), "memory"),
    knowledge = .workspace_proposal_table(.workspace_load_required(paths$knowledge_state)$list_proposals(status), "knowledge")
  )
}

#' Approve a workspace proposal
#'
#' @param workspace Workspace root directory.
#' @param type Proposal type: workflow, agent, memory, or knowledge.
#' @param proposal_id Proposal identifier.
#' @param note Optional approval note.
#' @param agent_spec_path Optional path to approved [`AgentSpec`] `.rds`.
#'
#' @return Approved proposal or spec object.
#' @export
approve_workspace_proposal <- function(
  workspace,
  type = c("workflow", "agent", "memory", "knowledge"),
  proposal_id,
  note = NULL,
  agent_spec_path = NULL
) {
  type <- match.arg(type)
  paths <- agentr_workspace_paths(workspace)
  spec <- .workspace_load_agent_spec(agent_spec_path, paths)

  if (identical(type, "workflow")) {
    state <- .workspace_load_required(paths$workflow_state)
    proposal <- state$approve_proposal(proposal_id)
    saveRDS(state, paths$workflow_state)
    .workspace_update_agent_spec(paths, spec, workflow = state$approved_workflow)
    return(invisible(proposal))
  }

  if (identical(type, "agent")) {
    scaffolder <- .workspace_load_required(paths$scaffolder_state)
    approved <- scaffolder$approve_agent_spec_proposal(proposal_id, approve_linked_workflow = TRUE)
    saveRDS(scaffolder, paths$scaffolder_state)
    saveRDS(scaffolder$workflow_state, paths$workflow_state)
    save_agent_spec(approved, paths$agent_spec)
    return(invisible(approved))
  }

  if (identical(type, "memory")) {
    state <- .workspace_load_required(paths$memory_state)
    proposal <- state$approve_proposal(proposal_id, note = note)
    saveRDS(state, paths$memory_state)
    .workspace_update_agent_spec(paths, spec, memory_spec = state$approved_spec())
    return(invisible(proposal))
  }

  state <- .workspace_load_required(paths$knowledge_state)
  proposal <- state$approve_proposal(proposal_id, note = note)
  saveRDS(state, paths$knowledge_state)
  .workspace_update_agent_spec(paths, spec, knowledge_spec = state$approved_spec())
  invisible(proposal)
}

#' Reject a workspace proposal
#'
#' @param workspace Workspace root directory.
#' @param type Proposal type: workflow, agent, memory, or knowledge.
#' @param proposal_id Proposal identifier.
#' @param note Optional rejection note.
#'
#' @return Rejected proposal.
#' @export
reject_workspace_proposal <- function(
  workspace,
  type = c("workflow", "agent", "memory", "knowledge"),
  proposal_id,
  note = NULL
) {
  type <- match.arg(type)
  paths <- agentr_workspace_paths(workspace)

  if (identical(type, "workflow")) {
    state <- .workspace_load_required(paths$workflow_state)
    proposal <- state$get_proposal(proposal_id)
    proposal$transition("rejected", timestamp = Sys.time())
    state$proposals[[proposal$id]] <- proposal
    saveRDS(state, paths$workflow_state)
    return(invisible(proposal))
  }

  if (identical(type, "agent")) {
    scaffolder <- .workspace_load_required(paths$scaffolder_state)
    proposal <- scaffolder$get_agent_spec_proposal(proposal_id)
    proposal <- .transition_agent_spec_proposal(proposal, to_status = "rejected", timestamp = Sys.time())
    .scaffolder_store_agent_spec_proposal(scaffolder, proposal)
    saveRDS(scaffolder, paths$scaffolder_state)
    return(invisible(proposal))
  }

  if (identical(type, "memory")) {
    state <- .workspace_load_required(paths$memory_state)
    proposal <- state$reject_proposal(proposal_id, note = note)
    saveRDS(state, paths$memory_state)
    return(invisible(proposal))
  }

  state <- .workspace_load_required(paths$knowledge_state)
  proposal <- state$reject_proposal(proposal_id, note = note)
  saveRDS(state, paths$knowledge_state)
  invisible(proposal)
}

#' Export workspace design-review HTML
#'
#' @param workspace Workspace root directory.
#' @param agent_spec_path Optional path to approved [`AgentSpec`] `.rds`.
#' @param out Optional output HTML path.
#' @param title Review title.
#' @param graph_layout Workflow graph layout passed to [design_review_html()].
#' @param edge_style Workflow edge style passed to [design_review_html()].
#'
#' @return Output HTML path.
#' @export
export_workspace_design_review <- function(
  workspace,
  agent_spec_path = NULL,
  out = NULL,
  title = "agentr design review",
  graph_layout = c("grid", "layered", "swimlane", "process"),
  edge_style = c("curved", "straight", "orthogonal")
) {
  graph_layout <- match.arg(graph_layout)
  edge_style <- match.arg(edge_style)
  paths <- init_agentr_workspace(workspace, create_readme = FALSE)
  spec <- .workspace_load_agent_spec(agent_spec_path, paths)
  if (is.null(out)) {
    out <- file.path(paths$reviews, "design_review.html")
  }
  workflow_state <- .workspace_load_or_null(paths$workflow_state)
  memory_state <- .workspace_load_or_null(paths$memory_state)
  knowledge_state <- .workspace_load_or_null(paths$knowledge_state)
  x <- spec
  if (is.null(x)) {
    workflow <- NULL
    if (!is.null(workflow_state)) {
      latest <- workflow_state$latest_proposal()
      workflow <- if (is.null(latest)) workflow_state$approved_workflow else latest$workflow
    }
    if (is.null(workflow)) {
      stop(
        "No AgentSpec or workflow proposal state found. Apply or approve a design before exporting review HTML.",
        call. = FALSE
      )
    }
    x <- workflow
  }
  export_design_review_html(
    x,
    path = out,
    workflow_state = workflow_state,
    memory_state = memory_state,
    knowledge_state = knowledge_state,
    title = title,
    graph_layout = graph_layout,
    edge_style = edge_style
  )
  invisible(out)
}

#' Build an implementation handoff prompt from workspace artifacts
#'
#' This creates a prompt for a coding assistant or implementation team. It does
#' not execute the approved design.
#'
#' @param workspace Workspace root directory.
#' @param agent_spec_path Optional path to approved [`AgentSpec`] `.rds`.
#' @param out Optional output prompt path.
#' @param language Target implementation language.
#' @param target_agent Target implementation agent.
#' @param runtime Optional runtime note.
#' @param style Optional implementation style note.
#' @param constraints Character vector of implementation constraints.
#' @param include_knowledge Include approved knowledge in the prompt.
#' @param knowledge_scope Knowledge inclusion scope.
#' @param format Prompt format.
#'
#' @return Output prompt path.
#' @export
build_workspace_implementation_prompt <- function(
  workspace,
  agent_spec_path = NULL,
  out = NULL,
  language = "R",
  target_agent = "coding_assistant",
  runtime = NULL,
  style = NULL,
  constraints = character(),
  include_knowledge = TRUE,
  knowledge_scope = c("referenced", "approved", "all"),
  format = c("markdown", "json")
) {
  knowledge_scope <- match.arg(knowledge_scope)
  format <- match.arg(format)
  paths <- init_agentr_workspace(workspace, create_readme = FALSE)
  spec <- .workspace_load_agent_spec(agent_spec_path, paths)
  input <- spec
  if (is.null(input)) {
    workflow_state <- .workspace_load_or_null(paths$workflow_state)
    if (is.null(workflow_state)) {
      stop("No AgentSpec or approved workflow state is available for handoff.", call. = FALSE)
    }
    input <- workflow_state$approved_workflow
  }
  prompt <- build_implementation_prompt(
    input,
    language = language,
    format = format,
    target_agent = target_agent,
    runtime = runtime,
    style = style,
    constraints = constraints,
    include_knowledge = include_knowledge,
    knowledge_scope = knowledge_scope
  )
  if (is.null(out)) {
    ext <- if (identical(format, "json")) ".json" else ".md"
    out <- file.path(paths$implementation_prompts, paste0("implementation_handoff", ext))
  }
  .workspace_write_text(prompt, out)
  invisible(out)
}

.workspace_root <- function(workspace) {
  if (!is.character(workspace) || length(workspace) != 1L || !nzchar(workspace)) {
    stop("`workspace` must be a non-empty path.", call. = FALSE)
  }
  path.expand(workspace)
}

.workspace_read_text <- function(x) {
  if (!is.character(x) || length(x) != 1L || !nzchar(x)) {
    stop("Expected a non-empty text value or file path.", call. = FALSE)
  }
  expanded <- path.expand(x)
  if (file.exists(expanded)) {
    return(paste(readLines(expanded, warn = FALSE), collapse = "\n"))
  }
  x
}

.workspace_write_text <- function(text, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(text, path, useBytes = TRUE)
  path
}

.workspace_validate_node_detail_actions <- function(message, node_id) {
  if (!is.character(node_id) || length(node_id) != 1L || !nzchar(node_id)) {
    stop("`node_id` must be a non-empty string.", call. = FALSE)
  }
  for (action in message$actions) {
    args <- action$args
    action_node_id <- if (is.null(args)) NULL else args$node_id
    if (!is.null(action_node_id) && !identical(as.character(action_node_id)[1], node_id)) {
      stop(
        "Node-detail messages may only target `", node_id, "`; found `",
        as.character(action_node_id)[1], "`.",
        call. = FALSE
      )
    }
  }
  invisible(TRUE)
}

.workspace_load_or_null <- function(path) {
  if (file.exists(path)) {
    return(readRDS(path))
  }
  NULL
}

.workspace_load_or_default <- function(path, default) {
  out <- .workspace_load_or_null(path)
  if (is.null(out)) {
    return(default)
  }
  out
}

.workspace_load_required <- function(path) {
  if (!file.exists(path)) {
    stop("Required workspace artifact is missing: ", path, call. = FALSE)
  }
  readRDS(path)
}

.workspace_load_agent_spec <- function(agent_spec_path = NULL, paths) {
  if (!is.null(agent_spec_path)) {
    return(load_agent_spec(path.expand(agent_spec_path)))
  }
  if (file.exists(paths$agent_spec)) {
    return(load_agent_spec(paths$agent_spec))
  }
  NULL
}

.workspace_agent_workflow <- function(spec) {
  if (!is.null(spec) && !is.null(spec$workflow)) {
    return(spec$workflow)
  }
  new_workflow_spec(
    nodes = .empty_workflow_nodes(),
    edges = .empty_workflow_edges(),
    task = NULL,
    metadata = list(evaluation = NULL, workflow_review = NULL, discussion_rounds = list())
  )
}

.workspace_agent_memory <- function(spec) {
  if (!is.null(spec) && !is.null(spec$memory_spec)) {
    return(spec$memory_spec)
  }
  MemorySpec$new()
}

.workspace_agent_knowledge <- function(spec) {
  if (!is.null(spec) && !is.null(spec$knowledge_spec)) {
    return(spec$knowledge_spec)
  }
  KnowledgeSpec$new()
}

.workspace_scaffolder <- function(spec = NULL, workflow_state = NULL) {
  scaffolder <- Scaffolder$new()
  if (is.null(workflow_state)) {
    workflow_state <- WorkflowProposalState$new(approved_workflow = .workspace_agent_workflow(spec))
  }
  scaffolder$workflow_state <- workflow_state
  scaffolder$workflow <- .workspace_current_workflow(workflow_state)
  if (!is.null(scaffolder$workflow$task)) {
    scaffolder$task <- scaffolder$workflow$task
  }
  scaffolder$agent_state$workflow_state <- workflow_state
  if (!is.null(spec)) {
    scaffolder$agent_state$set_approved_agent_spec(spec)
    scaffolder$agent_state$metadata$draft_agent_spec <- spec
  }
  scaffolder
}

.workspace_current_workflow <- function(workflow_state) {
  latest <- workflow_state$latest_proposal()
  if (!is.null(latest) && latest$status %in% c("pending", "under_discussion")) {
    return(validate_workflow_spec(latest$workflow))
  }
  validate_workflow_spec(workflow_state$approved_workflow)
}

.workspace_update_agent_spec <- function(paths, spec, workflow = NULL, memory_spec = NULL, knowledge_spec = NULL) {
  if (is.null(spec)) {
    return(invisible(NULL))
  }
  if (!is.null(workflow)) {
    spec$workflow <- workflow
  }
  if (!is.null(memory_spec)) {
    spec$memory_spec <- memory_spec
  }
  if (!is.null(knowledge_spec)) {
    spec$knowledge_spec <- knowledge_spec
  }
  save_agent_spec(spec, paths$agent_spec)
  invisible(spec)
}

.workspace_proposal_table <- function(proposals, type) {
  if (!length(proposals)) {
    return(data.frame(
      id = character(),
      status = character(),
      type = character(),
      notes = character(),
      created_at = as.POSIXct(character()),
      updated_at = as.POSIXct(character()),
      stringsAsFactors = FALSE
    ))
  }
  rows <- lapply(proposals, function(proposal) {
    list(
      id = proposal$id,
      status = proposal$status,
      type = type,
      notes = if (is.null(proposal$notes)) NA_character_ else as.character(proposal$notes)[1],
      created_at = proposal$created_at,
      updated_at = proposal$updated_at
    )
  })
  do.call(rbind, lapply(rows, as.data.frame, stringsAsFactors = FALSE))
}
