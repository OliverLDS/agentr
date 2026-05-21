#' Create task-family metadata
#'
#' Task-family metadata describes a parent design space whose root workflow
#' contains child-task nodes. It is stored under `workflow$metadata$task_family`
#' so the workflow remains a normal `agentr_workflow_spec`.
#'
#' @param id Task-family identifier.
#' @param label Human-readable task-family label.
#' @param objective Family-level objective.
#' @param child_tasks Character vector of child-task node ids.
#' @param dependency_policy Description of how root-level child nodes should be
#'   interpreted.
#' @param shared_inputs Character vector of shared input names.
#' @param shared_review_concerns Character vector of shared review concerns.
#' @param task_tags Optional named list mapping child-task ids to tags.
#' @param metadata Additional metadata.
#'
#' @return List suitable for `workflow$metadata$task_family`.
#' @export
task_family_metadata <- function(
  id,
  label,
  objective,
  child_tasks = character(),
  dependency_policy = "independent_children_no_root_edges",
  shared_inputs = character(),
  shared_review_concerns = character(),
  task_tags = list(),
  metadata = list()
) {
  if (!is.character(id) || length(id) != 1L || !nzchar(id)) {
    stop("`id` must be a non-empty string.", call. = FALSE)
  }
  if (!is.character(label) || length(label) != 1L || !nzchar(label)) {
    stop("`label` must be a non-empty string.", call. = FALSE)
  }
  if (!is.character(objective) || length(objective) != 1L || !nzchar(objective)) {
    stop("`objective` must be a non-empty string.", call. = FALSE)
  }
  if (!is.list(task_tags)) {
    stop("`task_tags` must be a named list.", call. = FALSE)
  }
  if (length(task_tags) && (is.null(names(task_tags)) || any(!nzchar(names(task_tags))))) {
    stop("`task_tags` must be a named list.", call. = FALSE)
  }
  if (!is.list(metadata)) {
    stop("`metadata` must be a list.", call. = FALSE)
  }

  c(
    list(
      id = id,
      label = label,
      objective = objective,
      child_tasks = as.character(child_tasks),
      dependency_policy = as.character(dependency_policy)[1],
      shared_inputs = as.character(shared_inputs),
      shared_review_concerns = as.character(shared_review_concerns),
      task_tags = lapply(task_tags, as.character)
    ),
    metadata
  )
}

#' Create a child-task workflow node
#'
#' Creates a workflow node that represents one child task inside a parent
#' task-family workflow. The child task can point to a saved workflow through
#' `subworkflow_ref` and/or embed a reviewable `nested_workflow`.
#'
#' @param id Child-task node id.
#' @param label Child-task label.
#' @param subworkflow_ref Optional reference to a saved child workflow.
#' @param nested_workflow Optional embedded child workflow.
#' @param input_schema Structured input schema for the child task.
#' @param output_schema Structured output schema for the child task.
#' @param human_required Whether the child task requires human review.
#' @param owner Current child-task owner.
#' @param automation_status Current child-task automation status.
#' @param target_automation_status Target automation status.
#' @param implementation_hint Optional implementation hint.
#' @param rule_spec Optional child-task rule.
#' @param knowledge_refs Character vector of related knowledge ids.
#' @param trace_required Whether trace collection is required.
#'
#' @return One-row workflow node data frame.
#' @export
child_task_node <- function(
  id,
  label,
  subworkflow_ref = NA_character_,
  nested_workflow = NULL,
  input_schema = list(),
  output_schema = list(),
  human_required = TRUE,
  owner = "human",
  automation_status = "human_in_loop",
  target_automation_status = NA_character_,
  implementation_hint = NA_character_,
  rule_spec = NA_character_,
  knowledge_refs = character(),
  trace_required = NA
) {
  workflow_node(
    id = id,
    label = label,
    human_required = human_required,
    rule_spec = rule_spec,
    implementation_hint = implementation_hint,
    owner = owner,
    automation_status = automation_status,
    target_automation_status = target_automation_status,
    trace_required = trace_required,
    knowledge_refs = knowledge_refs,
    subworkflow_ref = subworkflow_ref,
    input_schema = input_schema,
    output_schema = output_schema,
    nested_workflow = nested_workflow
  )
}

#' Create a task-family workflow
#'
#' Creates a root workflow whose nodes are child tasks. By default the root
#' workflow has no edges because sibling child tasks are interpreted as
#' independent unless explicit dependencies are supplied.
#'
#' @param id Task-family identifier.
#' @param label Task-family label.
#' @param objective Family-level objective.
#' @param nodes Data frame of child-task nodes.
#' @param edges Optional root-level dependency edges among child tasks.
#' @param shared_inputs Character vector of shared input names.
#' @param shared_review_concerns Character vector of shared review concerns.
#' @param task_tags Optional named list mapping child-task ids to tags.
#' @param metadata Additional root workflow metadata.
#'
#' @return `agentr_workflow_spec`.
#' @export
new_task_family_workflow <- function(
  id,
  label,
  objective,
  nodes = .empty_workflow_nodes(),
  edges = .empty_workflow_edges(),
  shared_inputs = character(),
  shared_review_concerns = character(),
  task_tags = list(),
  metadata = list()
) {
  if (!is.data.frame(nodes)) {
    stop("`nodes` must be a workflow-node data frame.", call. = FALSE)
  }
  if (!is.data.frame(edges)) {
    stop("`edges` must be a workflow-edge data frame.", call. = FALSE)
  }
  if (!is.list(metadata)) {
    stop("`metadata` must be a list.", call. = FALSE)
  }

  child_tasks <- if (nrow(nodes)) as.character(nodes$id) else character()
  metadata$task_family <- task_family_metadata(
    id = id,
    label = label,
    objective = objective,
    child_tasks = child_tasks,
    shared_inputs = shared_inputs,
    shared_review_concerns = shared_review_concerns,
    task_tags = task_tags
  )

  new_workflow_spec(
    nodes = nodes,
    edges = edges,
    task = objective,
    metadata = metadata
  )
}

#' Add a child task to a task-family workflow
#'
#' @param workflow Existing task-family workflow.
#' @param node One-row child-task node data frame.
#' @param tags Optional tags for the child task.
#'
#' @return Updated task-family workflow.
#' @export
add_child_task_node <- function(workflow, node, tags = character()) {
  workflow <- validate_workflow_spec(workflow)
  if (!is.data.frame(node) || nrow(node) != 1L) {
    stop("`node` must be a one-row workflow-node data frame.", call. = FALSE)
  }
  node <- .normalize_workflow_nodes_df(node)
  node_id <- as.character(node$id)[1]
  if (node_id %in% workflow$nodes$id) {
    stop("Workflow already contains child task: ", node_id, call. = FALSE)
  }

  nodes <- rbind(workflow$nodes, node)
  metadata <- workflow$metadata
  if (is.null(metadata$task_family)) {
    metadata$task_family <- task_family_metadata(
      id = "task_family",
      label = if (is.null(workflow$task)) "Task family" else workflow$task,
      objective = if (is.null(workflow$task)) "Task family" else workflow$task,
      child_tasks = character()
    )
  }
  metadata$task_family$child_tasks <- unique(c(
    as.character(metadata$task_family$child_tasks),
    node_id
  ))
  if (length(tags)) {
    current_tags <- metadata$task_family$task_tags
    if (is.null(current_tags) || !is.list(current_tags)) {
      current_tags <- list()
    }
    current_tags[[node_id]] <- as.character(tags)
    metadata$task_family$task_tags <- current_tags
  }

  new_workflow_spec(
    nodes = nodes,
    edges = workflow$edges,
    task = workflow$task,
    metadata = metadata
  )
}
