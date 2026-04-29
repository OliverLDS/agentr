#' @keywords internal
.jsonl_append <- function(record, path) {
  line <- jsonlite::toJSON(record, auto_unbox = TRUE, null = "null", na = "null")
  cat(line, "\n", file = path, append = TRUE)
  invisible(TRUE)
}

#' @keywords internal
.jsonl_read <- function(path) {
  if (!file.exists(path)) {
    return(list())
  }
  lines <- readLines(path, warn = FALSE)
  if (!length(lines)) {
    return(list())
  }
  lapply(lines, function(line) jsonlite::fromJSON(line, simplifyVector = FALSE))
}

#' Create a decision trace
#'
#' @param trace_id Trace identifier.
#' @param agent_id Agent identifier.
#' @param workflow_node_id Workflow node identifier.
#' @param context Optional context list.
#' @param human_decision Human decision text.
#' @param rationale Decision rationale.
#' @param outcome Optional outcome text.
#' @param reflection Optional reflection text.
#' @param candidate_knowledge_refs Optional candidate knowledge ids.
#' @param reusable_rule_candidate Whether this trace suggests a reusable rule.
#'
#' @return Trace list.
#' @export
create_decision_trace <- function(
  trace_id,
  agent_id,
  workflow_node_id,
  context = list(),
  human_decision,
  rationale,
  outcome = NULL,
  reflection = NULL,
  candidate_knowledge_refs = character(),
  reusable_rule_candidate = TRUE
) {
  list(
    trace_id = as.character(trace_id)[1],
    timestamp = Sys.time(),
    agent_id = as.character(agent_id)[1],
    workflow_node_id = as.character(workflow_node_id)[1],
    context = context,
    human_decision = as.character(human_decision)[1],
    rationale = as.character(rationale)[1],
    outcome = if (is.null(outcome)) NULL else as.character(outcome)[1],
    reflection = if (is.null(reflection)) NULL else as.character(reflection)[1],
    candidate_knowledge_refs = as.character(candidate_knowledge_refs),
    reusable_rule_candidate = isTRUE(reusable_rule_candidate)
  )
}

#' Append a decision trace
#'
#' @param trace Trace list.
#' @param path JSONL or RDS path.
#'
#' @return Invisibly returns `TRUE`.
#' @export
append_decision_trace <- function(trace, path) {
  if (grepl("\\.jsonl$", path, ignore.case = TRUE)) {
    return(.jsonl_append(trace, path))
  }
  traces <- if (file.exists(path)) .safe_read_rds(path) else list()
  traces[[length(traces) + 1L]] <- trace
  .safe_save_rds(traces, path)
  invisible(TRUE)
}

#' Read decision traces
#'
#' @param path JSONL or RDS path.
#'
#' @return List of traces.
#' @export
read_decision_traces <- function(path) {
  if (grepl("\\.jsonl$", path, ignore.case = TRUE)) {
    return(.jsonl_read(path))
  }
  if (!file.exists(path)) {
    return(list())
  }
  .safe_read_rds(path)
}

#' Create a reflection trace
#'
#' @param trace_id Trace identifier.
#' @param agent_id Agent identifier.
#' @param workflow_node_id Workflow node identifier.
#' @param reflection Reflection text.
#' @param outcome Optional outcome text.
#'
#' @return Trace list.
#' @export
create_reflection_trace <- function(trace_id, agent_id, workflow_node_id, reflection, outcome = NULL) {
  list(
    trace_id = as.character(trace_id)[1],
    timestamp = Sys.time(),
    agent_id = as.character(agent_id)[1],
    workflow_node_id = as.character(workflow_node_id)[1],
    reflection = as.character(reflection)[1],
    outcome = if (is.null(outcome)) NULL else as.character(outcome)[1]
  )
}

#' Append a reflection trace
#'
#' @param trace Trace list.
#' @param path JSONL or RDS path.
#'
#' @return Invisibly returns `TRUE`.
#' @export
append_reflection_trace <- function(trace, path) {
  append_decision_trace(trace, path)
}

#' Read reflection traces
#'
#' @param path JSONL or RDS path.
#'
#' @return List of traces.
#' @export
read_reflection_traces <- function(path) {
  read_decision_traces(path)
}

#' Set one workflow node owner
#'
#' @param workflow Workflow specification.
#' @param node_id Node identifier.
#' @param owner Owner value.
#'
#' @return Updated workflow specification.
#' @export
set_workflow_node_owner <- function(workflow, node_id, owner) {
  validate_workflow_spec(workflow)
  idx <- which(workflow$nodes$id == as.character(node_id)[1])
  if (!length(idx)) {
    stop("Unknown workflow node: ", node_id, call. = FALSE)
  }
  owner <- match.arg(as.character(owner)[1], choices = .workflow_owner_values())
  workflow$nodes$owner[idx] <- owner
  validate_workflow_spec(workflow)
  workflow
}

#' Set one workflow node automation status
#'
#' @param workflow Workflow specification.
#' @param node_id Node identifier.
#' @param automation_status Automation-status value.
#' @param target_automation_status Optional target automation-status value.
#'
#' @return Updated workflow specification.
#' @export
set_workflow_node_automation_status <- function(workflow, node_id, automation_status, target_automation_status = NULL) {
  validate_workflow_spec(workflow)
  idx <- which(workflow$nodes$id == as.character(node_id)[1])
  if (!length(idx)) {
    stop("Unknown workflow node: ", node_id, call. = FALSE)
  }
  automation_status <- match.arg(as.character(automation_status)[1], choices = .workflow_automation_status_values())
  workflow$nodes$automation_status[idx] <- automation_status
  if (!is.null(target_automation_status)) {
    workflow$nodes$target_automation_status[idx] <- match.arg(
      as.character(target_automation_status)[1],
      choices = .workflow_automation_status_values()
    )
  }
  validate_workflow_spec(workflow)
  workflow
}

#' Mark a workflow node as human-owned
#'
#' @param workflow Workflow specification.
#' @param node_id Node identifier.
#' @param reason Human-owned reason.
#' @param target_automation_status Optional target automation status.
#' @param trace_required Whether traces are required.
#'
#' @return Updated workflow specification.
#' @export
mark_node_human_owned <- function(workflow, node_id, reason, target_automation_status = NULL, trace_required = TRUE) {
  workflow <- set_workflow_node_owner(workflow, node_id, "human")
  workflow <- set_workflow_node_automation_status(workflow, node_id, "human_in_loop", target_automation_status = target_automation_status)
  idx <- which(workflow$nodes$id == as.character(node_id)[1])
  workflow$nodes$human_owned_reason[idx] <- as.character(reason)[1]
  workflow$nodes$trace_required[idx] <- isTRUE(trace_required)
  workflow
}

#' Mark a workflow node as agent-owned
#'
#' @param workflow Workflow specification.
#' @param node_id Node identifier.
#'
#' @return Updated workflow specification.
#' @export
mark_node_agent_owned <- function(workflow, node_id) {
  workflow <- set_workflow_node_owner(workflow, node_id, "agent")
  workflow <- set_workflow_node_automation_status(workflow, node_id, "agent_owned", target_automation_status = "validated_autonomous")
  idx <- which(workflow$nodes$id == as.character(node_id)[1])
  workflow$nodes$human_owned_reason[idx] <- NA_character_
  workflow
}

