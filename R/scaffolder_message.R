#' List LLM-callable scaffolder methods
#'
#' Returns the method names that an external reasoning system is allowed to
#' request through a machine-readable scaffolding message.
#'
#' @return Character vector of allowed method names.
#' @export
scaffolder_action_methods <- function() {
  c(
    "evaluate_task",
    "discuss_task",
    "decompose_task",
    "review_workflow",
    "review_node",
    "edit_workflow",
    "set_node_schema",
    "set_node_nested_workflow",
    "recommend_subsystems",
    "select_subsystems",
    "label_workflow_subsystems",
    "edit_workflow_subsystems",
    "propose_agent_spec",
    "approve_agent_spec_proposal",
    "approve_agent_spec",
    "ask_human_complete",
    "ask_human_changes",
    "ask_human_rule",
    "apply_human_feedback"
  )
}

#' Normalize candidate values
#'
#' @param x Candidate container.
#'
#' @return Character vector.
#' @keywords internal
.normalize_candidate_values <- function(x) {
  if (is.null(x)) {
    return(character())
  }
  unlist(x, use.names = FALSE)
}

#' @keywords internal
.normalize_node_specs <- function(x) {
  if (is.null(x)) {
    return(list())
  }
  if (!is.list(x)) {
    stop("Node specifications must be lists.", call. = FALSE)
  }
  x
}

#' @keywords internal
.arg_get <- function(x, name) {
  x[[name, exact = TRUE]]
}

#' @keywords internal
.decompose_task_metadata_args <- function() {
  c(
    "branching_rules",
    "review_gates",
    "decision_points",
    "inputs",
    "outputs",
    "dependencies",
    "triggers",
    "checkpoints",
    "acceptance_criteria",
    "assumptions",
    "source",
    "summary",
    "state_variables",
    "memory_schema",
    "state_schema"
  )
}

#' @keywords internal
.sanitize_scaffolder_action_args <- function(method, args) {
  if (is.null(args)) {
    return(list())
  }
  if (method %in% c("review_workflow", "review_node") && !is.null(args$status)) {
    status <- as.character(args$status)[1]
    status_aliases <- c(
      draft = "needs_revision",
      needs_review = "needs_revision",
      review_required = "needs_revision",
      under_review = "needs_revision",
      draft_decomposed_needs_review = "needs_revision",
      complete = "approved"
    )
    if (status %in% names(status_aliases)) {
      args$status <- unname(status_aliases[[status]])
    }
  }
  if (identical(method, "recommend_subsystems")) {
    args[intersect(names(args), c("recommendations", "sparse_selection", "rationale"))] <- NULL
    return(args)
  }
  if (identical(method, "select_subsystems")) {
    if (is.list(args$subsystems) && is.null(names(args$subsystems))) {
      args$subsystems <- unlist(args$subsystems, use.names = FALSE)
    }
    return(args)
  }
  if (identical(method, "label_workflow_subsystems")) {
    if (is.null(args$labels) && !is.null(args$node_subsystems)) {
      args$labels <- args$node_subsystems
    }
    args$node_subsystems <- NULL
    if (is.list(args$labels) && length(args$labels) && is.null(names(args$labels))) {
      if (all(vapply(args$labels, function(item) {
        is.list(item) && !is.null(item$node_id) && !is.null(item$subsystems)
      }, logical(1)))) {
        labels <- list()
        for (item in args$labels) {
          labels[[as.character(item$node_id)[1]]] <- unlist(item$subsystems, use.names = FALSE)
        }
        args$labels <- labels
      }
    }
    return(args)
  }
  if (identical(method, "propose_agent_spec")) {
    if (!is.null(args$autonomy_stage)) {
      if (is.null(args$metadata)) {
        args$metadata <- list()
      }
      args$metadata$autonomy_stage <- args$autonomy_stage
      args$autonomy_stage <- NULL
    }
    for (field in c("state_requirements", "interfaces", "implementation_targets")) {
      value <- args[[field]]
      if (is.list(value) && length(value) && (is.null(names(value)) || any(!nzchar(names(value))))) {
        args[[field]] <- list(items = unlist(value, use.names = FALSE))
      }
    }
    return(args)
  }
  if (!identical(method, "decompose_task")) {
    return(args)
  }

  metadata_names <- intersect(names(args), .decompose_task_metadata_args())
  if (!length(metadata_names)) {
    return(args)
  }

  metadata <- args[metadata_names]
  args[metadata_names] <- NULL
  metadata_note <- paste(
    "Additional workflow metadata supplied by model:",
    jsonlite::toJSON(metadata, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null"),
    sep = "\n"
  )
  if (is.null(args$notes) || !nzchar(as.character(args$notes)[1])) {
    args$notes <- metadata_note
  } else {
    args$notes <- paste(as.character(args$notes)[1], metadata_note, sep = "\n\n")
  }
  args
}

#' @keywords internal
.predict_node_ids <- function(current_ids, specs, start_index = length(current_ids) + 1L) {
  if (is.null(specs) || !length(specs)) {
    return(character())
  }

  predicted <- character(length(specs))
  for (i in seq_along(specs)) {
    item <- specs[[i]]
    if (!is.null(item$id) && nzchar(as.character(item$id))) {
      predicted[[i]] <- as.character(item$id)
      next
    }
    predicted[[i]] <- .new_node_id(c(current_ids, predicted[seq_len(i - 1L)]), start_index + i - 1L)
  }
  predicted
}

#' @keywords internal
.extract_edit_targets <- function(args, existing_ids) {
  add_specs <- .normalize_node_specs(.arg_get(args, "add"))
  insert_specs <- .normalize_node_specs(.arg_get(args, "insert"))
  added_ids <- .predict_node_ids(existing_ids, add_specs)
  insert_nodes <- lapply(insert_specs, function(item) item$node %||% item)
  inserted_ids <- .predict_node_ids(c(existing_ids, added_ids), insert_nodes, start_index = length(existing_ids) + length(added_ids) + 1L)

  list(
    add_specs = add_specs,
    insert_specs = insert_specs,
    added_ids = added_ids,
    inserted_ids = inserted_ids
  )
}

#' @keywords internal
.normalize_dispatch_args <- function(scaffolder, method, args) {
  if (!is.list(args)) {
    return(args)
  }

  if (!identical(method, "decompose_task")) {
    return(args)
  }

  method_formals <- names(formals(scaffolder[[method]]))
  if (all(c("nodes", "edges", "notes") %in% method_formals)) {
    return(args)
  }

  nodes_arg <- .arg_get(args, "nodes")
  edges_arg <- .arg_get(args, "edges")
  notes_arg <- .arg_get(args, "notes")
  suggestions_arg <- .arg_get(args, "suggestions")

  if (is.null(nodes_arg) && is.null(edges_arg) && is.null(notes_arg)) {
    return(args)
  }

  if (is.null(suggestions_arg)) {
    suggestions_arg <- list(
      nodes = nodes_arg %||% list(),
      edges = edges_arg %||% list(),
      notes = notes_arg
    )
  }

  args$nodes <- NULL
  args$edges <- NULL
  args$notes <- NULL
  args$suggestions <- suggestions_arg
  args
}

#' Validate scaffolder action arguments for a specific method
#'
#' @param method Scaffolder method name.
#' @param args Named list of action arguments.
#'
#' @return Validated argument list, invisibly.
#' @keywords internal
.validate_scaffolder_action_args <- function(method, args) {
  if (is.null(args)) {
    args <- list()
  }
  if (!is.list(args)) {
    stop("Each action `args` field must be a list.", call. = FALSE)
  }
  args <- .sanitize_scaffolder_action_args(method, args)

  known_args <- switch(
    method,
    evaluate_task = c("task", "summary", "workflow_complete", "blockers", "next_focus"),
    discuss_task = c("feedback", "source", "node_id", "confidence"),
    decompose_task = c("task", "candidates", "suggestions", "nodes", "edges", "notes"),
    review_workflow = c("status", "notes", "confidence"),
    review_node = c("node_id", "status", "notes", "confidence", "complete"),
    edit_workflow = c("add", "insert", "remove", "add_edges", "remove_edges", "rule_specs", "confidence"),
    set_node_schema = c("node_id", "input_schema", "output_schema"),
    set_node_nested_workflow = c("node_id", "subworkflow_ref", "nested_workflow"),
    recommend_subsystems = c("task"),
    select_subsystems = c("subsystems"),
    label_workflow_subsystems = c("labels"),
    edit_workflow_subsystems = c("set", "add", "remove", "clear"),
    propose_agent_spec = c(
      "agent_name",
      "summary",
      "subsystems",
      "workflow_proposal_id",
      "state_requirements",
      "interfaces",
      "implementation_targets",
      "metadata",
      "source",
      "notes"
    ),
    approve_agent_spec_proposal = c("proposal_id", "approve_linked_workflow"),
    approve_agent_spec = c(
      "agent_name",
      "summary",
      "state_requirements",
      "interfaces",
      "implementation_targets",
      "metadata"
    ),
    ask_human_complete = c("node_id"),
    ask_human_changes = character(),
    ask_human_rule = c("node_id"),
    apply_human_feedback = c("completeness", "add", "remove", "rule_specs", "confidence"),
    stop("Unsupported scaffolder method: ", method, call. = FALSE)
  )

  extra_args <- setdiff(names(args), known_args)
  if (length(extra_args)) {
    stop(
      "Unsupported argument(s) for method `", method, "`: ",
      paste(extra_args, collapse = ", "),
      call. = FALSE
    )
  }

  if (identical(method, "evaluate_task")) {
    task_arg <- .arg_get(args, "task")
    if (!is.character(task_arg) || length(task_arg) != 1L || !nzchar(task_arg)) {
      stop("`evaluate_task` requires a non-empty `task` string.", call. = FALSE)
    }
  }

  if (identical(method, "discuss_task")) {
    feedback_arg <- .arg_get(args, "feedback")
    if (!is.character(feedback_arg) || length(feedback_arg) != 1L || !nzchar(feedback_arg)) {
      stop("`discuss_task` requires a non-empty `feedback` string.", call. = FALSE)
    }
  }

  if (identical(method, "recommend_subsystems")) {
    task_arg <- .arg_get(args, "task")
    if (!is.null(task_arg) &&
        (!is.character(task_arg) || length(task_arg) != 1L || !nzchar(task_arg))) {
      stop("`recommend_subsystems.task` must be a non-empty string when provided.", call. = FALSE)
    }
  }

  if (identical(method, "select_subsystems")) {
    selected_arg <- .arg_get(args, "subsystems")
    if (is.null(selected_arg)) {
      stop("`select_subsystems` requires a `subsystems` argument.", call. = FALSE)
    }
    if (!inherits(selected_arg, "SubsystemSpec") &&
        !is.character(selected_arg) &&
        !is.list(selected_arg)) {
      stop(
        "`select_subsystems.subsystems` must be a `SubsystemSpec`, character vector, or named list.",
        call. = FALSE
      )
    }
  }

  if (identical(method, "label_workflow_subsystems")) {
    labels_arg <- .arg_get(args, "labels")
    if (!is.list(labels_arg)) {
      stop("`label_workflow_subsystems.labels` must be a named list.", call. = FALSE)
    }
  }

  if (identical(method, "edit_workflow_subsystems")) {
    for (name in c("set", "add", "remove")) {
      value <- .arg_get(args, name)
      if (!is.null(value) && !is.list(value)) {
        stop("`edit_workflow_subsystems.", name, "` must be a named list.", call. = FALSE)
      }
    }
    clear_arg <- .arg_get(args, "clear")
    if (!is.null(clear_arg) && !is.character(unlist(clear_arg, use.names = FALSE))) {
      stop("`edit_workflow_subsystems.clear` must be character.", call. = FALSE)
    }
  }

  if (identical(method, "propose_agent_spec")) {
    agent_name_arg <- .arg_get(args, "agent_name")
    if (!is.null(agent_name_arg) &&
        (!is.character(agent_name_arg) || length(agent_name_arg) != 1L || !nzchar(agent_name_arg))) {
      stop("`propose_agent_spec.agent_name` must be a non-empty string when provided.", call. = FALSE)
    }
    source_arg <- .arg_get(args, "source")
    if (!is.null(source_arg)) {
      .normalize_scaffolder_source(source_arg)
    }
    selected_arg <- .arg_get(args, "subsystems")
    if (!is.null(selected_arg) &&
        !inherits(selected_arg, "SubsystemSpec") &&
        !is.character(selected_arg) &&
        !is.list(selected_arg)) {
      stop(
        "`propose_agent_spec.subsystems` must be a `SubsystemSpec`, character vector, or named list.",
        call. = FALSE
      )
    }
  }

  if (identical(method, "decompose_task")) {
    task_arg <- .arg_get(args, "task")
    candidates_arg <- .arg_get(args, "candidates")
    suggestions_arg <- .arg_get(args, "suggestions")
    nodes_arg <- .arg_get(args, "nodes")
    edges_arg <- .arg_get(args, "edges")
    if (!is.null(task_arg) &&
        (!is.character(task_arg) || length(task_arg) != 1L || !nzchar(task_arg))) {
      stop("`decompose_task.task` must be a non-empty string when provided.", call. = FALSE)
    }
    if (!is.null(candidates_arg)) {
      if (!is.list(candidates_arg) && !is.character(candidates_arg)) {
        stop("`decompose_task.candidates` must be a character vector or list.", call. = FALSE)
      }
      candidate_values <- .normalize_candidate_values(candidates_arg)
      if (!is.character(candidate_values) || !length(candidate_values) || any(!nzchar(candidate_values))) {
        stop("`decompose_task.candidates` must contain non-empty strings.", call. = FALSE)
      }
    }
    if (!is.null(suggestions_arg) &&
        !is.list(suggestions_arg) &&
        !is.character(suggestions_arg)) {
      stop("`decompose_task.suggestions` must be a list or character vector.", call. = FALSE)
    }
    if (!is.null(nodes_arg) && !is.list(nodes_arg)) {
      stop("`decompose_task.nodes` must be a list of node specs.", call. = FALSE)
    }
    if (!is.null(edges_arg) && !is.list(edges_arg)) {
      stop("`decompose_task.edges` must be a list of edge specs.", call. = FALSE)
    }
  }

  if (method %in% c(
    "review_node",
    "set_node_schema",
    "set_node_nested_workflow",
    "ask_human_complete",
    "ask_human_rule"
  )) {
    node_id_arg <- .arg_get(args, "node_id")
    if (!is.character(node_id_arg) || length(node_id_arg) != 1L || !nzchar(node_id_arg)) {
      stop("`", method, "` requires a non-empty `node_id` string.", call. = FALSE)
    }
  }

  if (identical(method, "set_node_schema")) {
    input_schema_arg <- .arg_get(args, "input_schema")
    output_schema_arg <- .arg_get(args, "output_schema")
    if (!is.null(input_schema_arg) && !is.list(input_schema_arg)) {
      stop("`set_node_schema.input_schema` must be a list when provided.", call. = FALSE)
    }
    if (!is.null(output_schema_arg) && !is.list(output_schema_arg)) {
      stop("`set_node_schema.output_schema` must be a list when provided.", call. = FALSE)
    }
    if (is.null(input_schema_arg) && is.null(output_schema_arg)) {
      stop("`set_node_schema` requires `input_schema` or `output_schema`.", call. = FALSE)
    }
  }

  if (identical(method, "set_node_nested_workflow")) {
    subworkflow_ref_arg <- .arg_get(args, "subworkflow_ref")
    nested_workflow_arg <- .arg_get(args, "nested_workflow")
    if (!is.null(subworkflow_ref_arg) &&
        (!is.character(subworkflow_ref_arg) || length(subworkflow_ref_arg) != 1L || !nzchar(subworkflow_ref_arg))) {
      stop("`set_node_nested_workflow.subworkflow_ref` must be a non-empty string when provided.", call. = FALSE)
    }
    if (!is.null(nested_workflow_arg) && !is.list(nested_workflow_arg) &&
        !inherits(nested_workflow_arg, "agentr_workflow_spec")) {
      stop("`set_node_nested_workflow.nested_workflow` must be a workflow-like list when provided.", call. = FALSE)
    }
    if (is.null(subworkflow_ref_arg) && is.null(nested_workflow_arg)) {
      stop("`set_node_nested_workflow` requires `subworkflow_ref` or `nested_workflow`.", call. = FALSE)
    }
  }

  if (identical(method, "approve_agent_spec_proposal")) {
    proposal_id_arg <- .arg_get(args, "proposal_id")
    if (!is.character(proposal_id_arg) || length(proposal_id_arg) != 1L || !nzchar(proposal_id_arg)) {
      stop("`approve_agent_spec_proposal` requires a non-empty `proposal_id` string.", call. = FALSE)
    }
  }

  if (identical(method, "ask_human_changes") && length(args)) {
    stop("`ask_human_changes` does not accept arguments.", call. = FALSE)
  }

  if (method %in% c("review_workflow", "review_node")) {
    status_arg <- .arg_get(args, "status")
    if (!is.null(status_arg) &&
        !(as.character(status_arg) %in% c("pending", "needs_revision", "approved"))) {
      stop("Review status must be one of `pending`, `needs_revision`, or `approved`.", call. = FALSE)
    }
  }

  confidence_arg <- .arg_get(args, "confidence")
  confidence_like <- list(
    discuss_task = confidence_arg,
    review_workflow = confidence_arg,
    review_node = confidence_arg
  )
  if (method %in% names(confidence_like) && !is.null(confidence_like[[method]])) {
    value <- suppressWarnings(as.numeric(confidence_like[[method]]))
    if (length(value) != 1L || is.na(value) || value < 0 || value > 1) {
      stop("Confidence values must be numeric in [0, 1].", call. = FALSE)
    }
  }

  if (method %in% c("edit_workflow", "apply_human_feedback")) {
    remove_arg <- .arg_get(args, "remove")
    rule_specs_arg <- .arg_get(args, "rule_specs")
    add_arg <- .arg_get(args, "add")
    if (!is.null(remove_arg)) {
      remove_values <- unlist(remove_arg, use.names = FALSE)
      if (!is.character(remove_values)) {
        stop("`remove` values must be character.", call. = FALSE)
      }
    }
    if (!is.null(rule_specs_arg) && !is.list(rule_specs_arg)) {
      stop("`rule_specs` must be a named list.", call. = FALSE)
    }
    if (!is.null(confidence_arg)) {
      if (!is.list(confidence_arg)) {
        stop("`confidence` must be a named list.", call. = FALSE)
      }
      confidence_values <- suppressWarnings(as.numeric(unlist(confidence_arg, use.names = FALSE)))
      if (any(is.na(confidence_values)) || any(confidence_values < 0) || any(confidence_values > 1)) {
        stop("`confidence` values must be numeric in [0, 1].", call. = FALSE)
      }
    }
    if (!is.null(add_arg)) {
      if (!is.list(add_arg)) {
        stop("`add` must be a list of node records.", call. = FALSE)
      }
      for (item in add_arg) {
        if (!is.list(item) || !is.character(item$label) || length(item$label) != 1L || !nzchar(item$label)) {
          stop("Each added node must include a non-empty `label`.", call. = FALSE)
        }
      }
    }
  }

  insert_arg <- .arg_get(args, "insert")
  if (identical(method, "edit_workflow") && !is.null(insert_arg)) {
    if (!is.list(insert_arg)) {
      stop("`insert` must be a list of insertion specs.", call. = FALSE)
    }
    for (item in insert_arg) {
      node_item <- item$node %||% item
      if (!is.list(node_item) || !is.character(node_item$label) ||
          length(node_item$label) != 1L || !nzchar(node_item$label)) {
        stop("Each inserted node must include a non-empty `label`.", call. = FALSE)
      }
    }
  }

  if (identical(method, "edit_workflow")) {
    edge_groups <- list(
      add_edges = .arg_get(args, "add_edges"),
      remove_edges = .arg_get(args, "remove_edges")
    )
    for (group_name in names(edge_groups)) {
      group <- edge_groups[[group_name]]
      if (is.null(group)) {
        next
      }
      if (!is.list(group)) {
        stop("`", group_name, "` must be a list of edge specs.", call. = FALSE)
      }
      for (item in group) {
        if (!is.list(item) || !is.character(item$from) || !nzchar(item$from) ||
            !is.character(item$to) || !nzchar(item$to)) {
          stop("Each edge spec must include non-empty `from` and `to` ids.", call. = FALSE)
        }
      }
    }
  }

  invisible(args)
}

#' Validate scaffolder action references against current state
#'
#' @param scaffolder A [`Scaffolder`] instance.
#' @param method Scaffolder method name.
#' @param args Named list of action arguments.
#'
#' @return Invisibly returns `TRUE`.
#' @keywords internal
.validate_scaffolder_action_refs <- function(scaffolder, method, args) {
  if (is.null(args)) {
    return(invisible(TRUE))
  }

  existing_ids <- scaffolder$workflow$nodes$id

  if (method %in% c(
    "review_node",
    "set_node_schema",
    "set_node_nested_workflow",
    "ask_human_complete",
    "ask_human_rule"
  )) {
    node_id_arg <- .arg_get(args, "node_id")
    if (!(node_id_arg %in% existing_ids)) {
      stop("Unknown workflow node reference: ", node_id_arg, call. = FALSE)
    }
  }

  node_id_arg <- .arg_get(args, "node_id")
  if (identical(method, "discuss_task") && !is.null(node_id_arg) && !(node_id_arg %in% existing_ids)) {
    stop("Unknown workflow node reference: ", node_id_arg, call. = FALSE)
  }

  if (identical(method, "label_workflow_subsystems")) {
    labels_arg <- .arg_get(args, "labels")
    if (!is.null(labels_arg)) {
      .validate_node_subsystems(labels_arg, nodes = scaffolder$workflow$nodes)
    }
  }

  if (identical(method, "edit_workflow_subsystems")) {
    for (name in c("set", "add", "remove")) {
      value <- .arg_get(args, name)
      if (!is.null(value)) {
        .validate_node_subsystems(value, nodes = scaffolder$workflow$nodes)
      }
    }
    clear_arg <- .arg_get(args, "clear")
    if (!is.null(clear_arg)) {
      clear_ids <- unlist(clear_arg, use.names = FALSE)
      if (length(clear_ids) && any(!(clear_ids %in% existing_ids))) {
        stop("`clear` contains unknown workflow node ids.", call. = FALSE)
      }
    }
  }

  if (identical(method, "propose_agent_spec")) {
    workflow_proposal_id_arg <- .arg_get(args, "workflow_proposal_id")
    if (!is.null(workflow_proposal_id_arg) &&
        !is.null(scaffolder$workflow_state$proposals[[workflow_proposal_id_arg]])) {
      return(invisible(TRUE))
    }
    if (!is.null(workflow_proposal_id_arg)) {
      stop("Unknown workflow proposal reference: ", workflow_proposal_id_arg, call. = FALSE)
    }
  }

  if (identical(method, "approve_agent_spec_proposal")) {
    proposal_id_arg <- .arg_get(args, "proposal_id")
    proposal <- scaffolder$agent_state$proposal_state$proposals[[proposal_id_arg]] %||% NULL
    if (is.null(proposal)) {
      stop("Unknown agent spec proposal reference: ", proposal_id_arg, call. = FALSE)
    }
  }

  if (method %in% c("edit_workflow", "apply_human_feedback")) {
    targets <- .extract_edit_targets(args = args, existing_ids = existing_ids)
    combined_ids <- unique(c(existing_ids, targets$added_ids, targets$inserted_ids))

    if (anyDuplicated(combined_ids)) {
      stop("Added node ids must be unique within the workflow.", call. = FALSE)
    }

    remove_arg <- .arg_get(args, "remove")
    remove_ids <- if (is.null(remove_arg)) character() else unlist(remove_arg, use.names = FALSE)
    if (length(remove_ids) && any(!(remove_ids %in% combined_ids))) {
      stop("`remove` contains unknown node ids.", call. = FALSE)
    }

    remaining_ids <- setdiff(combined_ids, remove_ids)
    ref_groups <- list(
      rule_specs = if (is.null(.arg_get(args, "rule_specs"))) character() else names(.arg_get(args, "rule_specs")),
      confidence = if (is.null(.arg_get(args, "confidence"))) character() else names(.arg_get(args, "confidence")),
      completeness = if (is.null(.arg_get(args, "completeness"))) character() else names(.arg_get(args, "completeness"))
    )

    for (group_name in names(ref_groups)) {
      refs <- ref_groups[[group_name]]
      if (length(refs) && any(!(refs %in% remaining_ids))) {
        stop("`", group_name, "` references unknown or removed node ids.", call. = FALSE)
      }
    }

    if (identical(method, "edit_workflow")) {
      add_edges <- .arg_get(args, "add_edges") %||% list()
      remove_edges <- .arg_get(args, "remove_edges") %||% list()
      insert_specs <- targets$insert_specs

      for (item in add_edges) {
        if (!(item$from %in% remaining_ids) || !(item$to %in% remaining_ids)) {
          stop("Edge edits must reference existing node ids.", call. = FALSE)
        }
      }
      for (item in remove_edges) {
        if (!(item$from %in% combined_ids) || !(item$to %in% combined_ids)) {
          stop("Removed edges must reference known node ids.", call. = FALSE)
        }
      }
      for (i in seq_along(insert_specs)) {
        item <- insert_specs[[i]]
        if (!is.null(item$between)) {
          between <- unlist(item$between, use.names = FALSE)
          if (length(between) != 2L || any(!(between %in% combined_ids))) {
            stop("Inserted `between` anchors must reference known node ids.", call. = FALSE)
          }
        }
        if (!is.null(item$after) && !(item$after %in% combined_ids)) {
          stop("Inserted `after` anchors must reference known node ids.", call. = FALSE)
        }
        if (!is.null(item$before) && !(item$before %in% combined_ids)) {
          stop("Inserted `before` anchors must reference known node ids.", call. = FALSE)
        }
      }
    }
  }

  invisible(TRUE)
}

#' Build an LLM prompt for scaffolding decisions
#'
#' Creates a prompt that describes the scaffolder's available methods, the task
#' context, the current workflow state, and the required machine-readable JSON
#' response format.
#'
#' @param scaffolder A [`Scaffolder`] instance.
#' @param task Optional task text. Defaults to the scaffolder's current task.
#' @param format Prompt payload format. Use `"json"` for SDK-facing structured
#'   payloads and `"markdown"` for prompts that a human may paste into a chat
#'   interface.
#'
#' @return Character string prompt.
#' @export
build_scaffolder_prompt <- function(scaffolder, task = NULL, format = "json") {
  stopifnot(inherits(scaffolder, "Scaffolder"))

  format <- match.arg(format, choices = c("json", "markdown"))
  task <- task %||% scaffolder$task
  contract <- new_prompt_contract(
    input_type = "Scaffolder",
    target_role = "scaffolding_reasoner",
    expected_output = "JSON object with `actions` and optional `notes`."
  )

  workflow <- scaffolder$workflow_spec()
  workflow_payload <- list(
    task = workflow$task,
    nodes = workflow$nodes,
    edges = workflow$edges,
    metadata = workflow$metadata
  )
  agent_proposals <- scaffolder$list_agent_spec_proposals()
  agent_payload <- if (is.null(scaffolder$task) || !nzchar(scaffolder$task)) {
    list(
      task = NULL,
      agent_name = NULL,
      summary = NULL,
      subsystems = SubsystemSpec$new()$as_list(),
      workflow = workflow_payload,
      metadata = list(),
      recommendations = list(),
      proposals = list()
    )
  } else {
    c(
      scaffolder$agent_spec()$as_list(),
      list(
        recommendations = scaffolder$subsystem_recommendations(),
        proposals = if (nrow(agent_proposals)) agent_proposals else list()
      )
    )
  }

  action_schema <- list(
    actions = list(
      list(
        method = "discuss_task",
        args = list(
          feedback = "Human says the workflow needs a parallel QA branch.",
          source = "human"
        )
      ),
      list(
        method = "edit_workflow",
        args = list(
          insert = list(list(
            node = list(
              label = "Run QA review",
              confidence = 0.72,
              human_required = TRUE
            ),
            between = list("node_1", "node_2")
          ))
        )
      ),
      list(
        method = "review_workflow",
        args = list(
          status = "needs_revision",
          notes = "Parallel QA branch is still missing."
        )
      ),
      list(
        method = "set_node_schema",
        args = list(
          node_id = "node_1",
          input_schema = list(type = "object", required = c("source_text")),
          output_schema = list(type = "object", required = c("findings"))
        )
      ),
      list(
        method = "set_node_nested_workflow",
        args = list(
          node_id = "node_1",
          subworkflow_ref = "workflows/node_1_detail.json",
          nested_workflow = list(
            nodes = list(list(id = "node_1a", label = "Inspect source text")),
            edges = list()
          )
        )
      ),
      list(
        method = "select_subsystems",
        args = list(
          subsystems = c("pg", "ae")
        )
      ),
      list(
        method = "propose_agent_spec",
        args = list(
          agent_name = "qa-agent",
          summary = "Draft QA-oriented agent design.",
          source = "model"
        )
      ),
      list(
        method = "approve_agent_spec_proposal",
        args = list(
          proposal_id = "agent_proposal_1"
        )
      )
    ),
    notes = "Optional short reasoning note."
  )

  allowed_methods <- scaffolder_action_methods()
  workflow_json <- jsonlite::toJSON(
    workflow_payload,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null"
  )
  schema_json <- jsonlite::toJSON(
    action_schema,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null"
  )

  method_semantics <- list(
    evaluate_task = "Register or refresh the persistent task-evaluation artifact.",
    discuss_task = "Record a free-form human or model discussion round before structured edits.",
    decompose_task = "Propose workflow nodes and non-linear graph structure for the task.",
    review_workflow = "Record workflow-level completeness or revision status.",
    review_node = "Record node-level correctness or completion status.",
    edit_workflow = "Apply first-class node and edge edits, including insertions.",
    set_node_schema = "Set structured input and output schema metadata for one workflow node.",
    set_node_nested_workflow = "Attach a lower-level workflow reference or embedded nested workflow to one node.",
    recommend_subsystems = "Recommend a sparse subsystem set for the current task and workflow.",
    select_subsystems = "Store the selected subsystem configuration.",
    label_workflow_subsystems = "Assign subsystem owners to workflow nodes.",
    edit_workflow_subsystems = "Edit subsystem ownership on workflow nodes incrementally.",
    propose_agent_spec = "Store a draft agent-spec proposal from the current or proposed workflow state.",
    approve_agent_spec_proposal = "Approve a stored agent-spec proposal and optionally approve its linked workflow proposal.",
    approve_agent_spec = "Approve an agent spec from the current task, workflow, and subsystem state.",
    ask_human_complete = "Ask whether a node is complete.",
    ask_human_changes = "Ask what workflow or edge changes should happen next.",
    ask_human_rule = "Ask for a node-specific rule.",
    apply_human_feedback = "Legacy compatibility wrapper for structured node edits."
  )

  decision_policy <- c(
    "Use discuss_task to preserve free-form human or model reasoning before committing graph edits.",
    "Use decompose_task when the task has not yet been broken into useful workflow nodes or graph structure.",
    "Use review_workflow for workflow-level completeness and review_node for node-level correctness.",
    "Use edit_workflow for actual node and edge changes, including insertion between existing nodes.",
    "Ask the human only when ambiguity, missing rules, or review gaps block progress.",
    "Never invent methods outside the allowed method list."
  )

  if (identical(format, "json")) {
    payload <- .prompt_contract_payload(contract, list(
      role = "scaffolding_reasoner",
      task = if (is.null(task)) "<unspecified>" else task,
      available_methods = allowed_methods,
      method_semantics = method_semantics,
      decision_policy = decision_policy,
      current_workflow = workflow_payload,
      current_agent_design = agent_payload,
      response_requirements = list(
        format = "json",
        rules = c(
          "Return machine-readable JSON only.",
          "Do not include markdown fences or prose outside JSON.",
          "The top-level object must contain `actions` and may contain `notes`.",
          "Each action must contain `method` and `args`."
        ),
        schema = action_schema
      )
    ))

    return(.prompt_json(payload))
  }

  paste(
    "# Scaffolding Reasoning Prompt",
    "",
    "You are assisting a scaffolding-oriented agent framework.",
    "Your job is to decide what scaffolding action should happen next.",
    "",
    "## Task",
    if (is.null(task)) "<unspecified>" else task,
    "",
    "## Available Scaffolder Methods",
    paste(paste0("- `", allowed_methods, "`"), collapse = "\n"),
    "",
    "## Method Semantics",
    paste(paste0("- `", names(method_semantics), "`: ", unlist(method_semantics)), collapse = "\n"),
    "",
    "## Decision Policy",
    paste(paste0("- ", decision_policy), collapse = "\n"),
    "",
    "## Current Workflow State",
    "```json",
    workflow_json,
    "```",
    "",
    "## Current Agent Design State",
    "```json",
    jsonlite::toJSON(agent_payload, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null"),
    "```",
    "",
    "## Response Requirements",
    "- Produce the response as a downloadable `.json` file or attachment link for the user.",
    "- The file contents must be machine-readable JSON only.",
    "- Do not paste long JSON inline in the chat unless the UI cannot provide a file or attachment link.",
    "- If the UI cannot provide a file, then return raw JSON only with no markdown fences or explanatory prose.",
    "- The JSON must have an `actions` array and may have a `notes` string.",
    "- Each action must contain `method` and `args`.",
    "",
    "## Expected JSON Shape",
    "```json",
    schema_json,
    "```",
    sep = "\n"
  )
}

#' Build a node-detail revision prompt
#'
#' Creates a constrained prompt for revising only one workflow node's interface
#' schema or nested workflow detail. The expected response uses
#' `set_node_schema()` and/or `set_node_nested_workflow()` actions.
#'
#' @param workflow Workflow spec containing the target node.
#' @param node_id Workflow node id to revise.
#' @param include_nested_workflow Whether to include existing nested workflow
#'   payload in the prompt.
#' @param feedback Optional human revision feedback.
#' @param format Prompt payload format. Use `"json"` or `"markdown"`.
#'
#' @return Character string prompt.
#' @export
build_node_detail_prompt <- function(
  workflow,
  node_id,
  include_nested_workflow = TRUE,
  feedback = NULL,
  format = c("json", "markdown")
) {
  format <- match.arg(format)
  workflow <- validate_workflow_spec(workflow)
  if (!is.character(node_id) || length(node_id) != 1L || !nzchar(node_id)) {
    stop("`node_id` must be a non-empty string.", call. = FALSE)
  }

  idx <- which(workflow$nodes$id == node_id)
  if (!length(idx)) {
    stop("Unknown workflow node: ", node_id, call. = FALSE)
  }

  node <- as.list(workflow$nodes[idx[[1]], , drop = FALSE])
  for (field in c("input_schema", "output_schema", "nested_workflow")) {
    value <- node[[field]]
    if (is.list(value) && length(value) == 1L) {
      node[[field]] <- value[[1]]
    }
  }
  if (!isTRUE(include_nested_workflow)) {
    node$nested_workflow <- NULL
  }

  allowed_methods <- c("set_node_schema", "set_node_nested_workflow", "discuss_task", "review_node")
  action_schema <- list(
    actions = list(
      list(
        method = "set_node_schema",
        args = list(
          node_id = node_id,
          input_schema = list(
            type = "object",
            required = c("source_text"),
            properties = list(source_text = list(type = "string"))
          ),
          output_schema = list(
            type = "object",
            required = c("findings"),
            properties = list(findings = list(type = "array"))
          )
        )
      ),
      list(
        method = "set_node_nested_workflow",
        args = list(
          node_id = node_id,
          subworkflow_ref = paste0("workflows/", node_id, "_detail.json"),
          nested_workflow = list(
            nodes = list(
              list(id = paste0(node_id, "_a"), label = "Prepare node inputs"),
              list(id = paste0(node_id, "_b"), label = "Produce node outputs")
            ),
            edges = list(list(from = paste0(node_id, "_a"), to = paste0(node_id, "_b")))
          )
        )
      )
    ),
    notes = "Optional short reasoning note."
  )
  rules <- c(
    paste0("Revise only workflow node `", node_id, "`."),
    "Use `set_node_schema` for node input/output JSON-like schema metadata.",
    "Use `set_node_nested_workflow` for a lower-level workflow chart inside this node.",
    "Do not add, remove, rename, or reconnect top-level workflow nodes.",
    "Do not mutate the approved top-level workflow unless the resulting proposal is explicitly approved.",
    "Return only constrained JSON actions; do not include arbitrary R code."
  )

  contract <- new_prompt_contract(
    input_type = "WorkflowNode",
    target_role = "node_detail_reasoner",
    expected_output = "JSON object with node-detail `actions` and optional `notes`."
  )

  payload <- .prompt_contract_payload(contract, list(
    role = "node_detail_reasoner",
    target_node_id = node_id,
    human_feedback = feedback,
    available_methods = allowed_methods,
    decision_policy = rules,
    current_node = node,
    response_requirements = list(
      format = "json",
      rules = c(
        "Return machine-readable JSON only.",
        "Do not include markdown fences or prose outside JSON.",
        "Every action that has a `node_id` argument must use the target node id.",
        "The top-level object must contain `actions` and may contain `notes`."
      ),
      schema = action_schema
    )
  ))

  if (identical(format, "json")) {
    return(.prompt_json(payload))
  }

  paste(
    "# Node Detail Revision Prompt",
    "",
    "You are revising one workflow node's interface schema and optional nested workflow.",
    "",
    "## Target Node",
    node_id,
    "",
    "## Human Feedback",
    if (is.null(feedback) || !nzchar(as.character(feedback)[1])) "<none>" else as.character(feedback)[1],
    "",
    "## Current Node",
    "```json",
    jsonlite::toJSON(node, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null"),
    "```",
    "",
    "## Allowed Methods",
    paste(paste0("- `", allowed_methods, "`"), collapse = "\n"),
    "",
    "## Rules",
    paste(paste0("- ", rules), collapse = "\n"),
    "",
    "## Expected JSON Shape",
    "```json",
    jsonlite::toJSON(action_schema, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null"),
    "```",
    sep = "\n"
  )
}

#' Build an LLM prompt for agent design decisions
#'
#' Creates a prompt that targets subsystem-first agent design while keeping the
#' workflow as a nested component inside the proposed agent specification.
#'
#' @param scaffolder A [`Scaffolder`] instance.
#' @param format Prompt payload format. Use `"json"` or `"markdown"`.
#'
#' @return Character string prompt.
#' @export
build_agent_design_prompt <- function(scaffolder, format = "json") {
  stopifnot(inherits(scaffolder, "Scaffolder"))
  format <- match.arg(format, choices = c("json", "markdown"))

  agent_spec <- if (is.null(scaffolder$task) || !nzchar(scaffolder$task)) {
    list(
      task = NULL,
      agent_name = NULL,
      summary = NULL,
      subsystems = SubsystemSpec$new()$as_list(),
      workflow = NULL,
      metadata = list(),
      recommendations = list(),
      proposals = list()
    )
  } else {
    c(
      scaffolder$agent_spec()$as_list(),
      list(
        recommendations = scaffolder$subsystem_recommendations(),
        proposals = {
          proposals <- scaffolder$list_agent_spec_proposals()
          if (nrow(proposals)) proposals else list()
        }
      )
    )
  }
  workflow <- scaffolder$workflow_spec()
  contract <- new_prompt_contract(
    input_type = "Scaffolder",
    target_role = "agent_design_reasoner",
    expected_output = "JSON object with `actions` and optional `notes`."
  )
  allowed_methods <- intersect(
    scaffolder_action_methods(),
    c(
      "evaluate_task",
      "discuss_task",
      "decompose_task",
      "recommend_subsystems",
      "select_subsystems",
      "label_workflow_subsystems",
      "approve_agent_spec",
      "review_workflow",
      "review_node",
      "edit_workflow",
      "ask_human_complete",
      "ask_human_changes",
      "ask_human_rule"
    )
  )

  action_schema <- list(
    actions = list(
      list(method = "recommend_subsystems", args = list()),
      list(method = "select_subsystems", args = list(subsystems = c("pg", "ae"))),
      list(
        method = "edit_workflow_subsystems",
        args = list(add = list(node_1 = c("pg"), node_2 = c("ae")))
      ),
      list(
        method = "propose_agent_spec",
        args = list(
          agent_name = "release-agent",
          summary = "Sparse agent for release planning and execution."
        )
      ),
      list(
        method = "approve_agent_spec_proposal",
        args = list(proposal_id = "agent_proposal_1")
      )
    ),
    notes = "Optional short reasoning note."
  )

  instructions <- c(
      "Treat subsystem selection as a separate design axis from workflow structure.",
      "Default to sparse agents and avoid enabling subsystems without justification.",
      "Use RWM for reasoning, planning, inference, and world-model structure.",
      "Use PG for perception, grounding, source interpretation, and artifact understanding.",
      "Use IAC only for genuine inter-agent communication rather than generic human review.",
      "Model cognitive and affective layers inside RWM only when they are truly needed.",
      "Keep workflow-first compatibility by using the current workflow as a nested artifact inside the agent design.",
      "Use draft agent-spec proposals to preserve design iterations before final approval.",
      "Approve the agent spec only after subsystem selection and workflow ownership labels are coherent."
    )

  payload <- .prompt_contract_payload(contract, list(
    role = "agent_design_reasoner",
    task = scaffolder$task %||% "<unspecified>",
    available_methods = allowed_methods,
    instructions = instructions,
    current_agent_design = agent_spec,
    current_workflow = list(
      task = workflow$task,
      nodes = workflow$nodes,
      edges = workflow$edges,
      metadata = workflow$metadata
    ),
    response_requirements = list(
      format = "json",
      rules = c(
        "Return machine-readable JSON only.",
        "The top-level object must contain `actions` and may contain `notes`.",
        "Use only the provided method names.",
        "Prefer subsystem selection before approving the agent spec."
      ),
      schema = action_schema
    )
  ))

  if (identical(format, "json")) {
    return(.prompt_json(payload))
  }

  paste(
    "# Agent Design Prompt",
    "",
    "You are designing an intelligent agent, not only a workflow.",
    "Treat subsystem choice and workflow structure as separate axes.",
    "",
    "## Instructions",
    paste(paste0("- ", instructions), collapse = "\n"),
    "",
    "## Current Agent Design",
    "```json",
    jsonlite::toJSON(agent_spec, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null"),
    "```",
    "",
    "## Current Workflow",
    "```json",
    jsonlite::toJSON(
      list(task = workflow$task, nodes = workflow$nodes, edges = workflow$edges, metadata = workflow$metadata),
      auto_unbox = TRUE,
      pretty = TRUE,
      null = "null",
      na = "null"
    ),
    "```",
    "",
    "## Available Methods",
    paste(paste0("- `", allowed_methods, "`"), collapse = "\n"),
    "",
    "## Response Requirements",
    "- Return raw JSON only.",
    "- The JSON must contain an `actions` array.",
    "- Use sparse subsystem selections unless the task clearly justifies more.",
    "",
    "## Expected JSON Shape",
    "```json",
    jsonlite::toJSON(action_schema, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null"),
    "```",
    sep = "\n"
  )
}

#' Parse an LLM scaffolder message
#'
#' Parses a machine-readable scaffolder message from JSON text or a `.json`
#' file path into an R list.
#'
#' @param text Character string containing JSON or a path to a `.json` file.
#'
#' @return Parsed list.
#' @export
parse_scaffolder_message <- function(text) {
  if (!is.character(text) || length(text) != 1L || !nzchar(text)) {
    stop("`text` must be a non-empty JSON string or `.json` file path.", call. = FALSE)
  }

  if (file.exists(text)) {
    if (!grepl("\\.json$", text, ignore.case = TRUE)) {
      stop("Scaffolder message files must use a `.json` extension.", call. = FALSE)
    }
    text <- paste(readLines(text, warn = FALSE), collapse = "\n")
  }

  parsed <- tryCatch(
    jsonlite::fromJSON(text, simplifyVector = FALSE),
    error = function(e) {
      stop("Could not parse scaffolder message as JSON.", call. = FALSE)
    }
  )

  validate_scaffolder_message(parsed)
}

#' Validate a machine-readable scaffolder message
#'
#' @param x Parsed scaffolder message.
#' @param allowed_methods Character vector of allowed method names.
#'
#' @return The validated message, invisibly.
#' @export
validate_scaffolder_message <- function(
  x,
  allowed_methods = scaffolder_action_methods()
) {
  if (!is.list(x)) {
    stop("Scaffolder message must be a list.", call. = FALSE)
  }

  if (is.null(x$actions) || !is.list(x$actions)) {
    stop("Scaffolder message must contain an `actions` list.", call. = FALSE)
  }

  for (i in seq_along(x$actions)) {
    x$actions[[i]] <- .scaffolder_validate_message_action(
      x$actions[[i]],
      allowed_methods = allowed_methods
    )
  }

  invisible(x)
}

#' Apply a machine-readable scaffolder message
#'
#' Parses and dispatches a machine-readable scaffolder message into concrete
#' calls on a [`Scaffolder`] instance.
#'
#' @param scaffolder A [`Scaffolder`] instance.
#' @param message Parsed message list, JSON string, or path to a downloaded
#'   `.json` file.
#' @param allowed_methods Character vector of allowed method names.
#' @param stop_on_error Whether to stop on the first action error. When `FALSE`,
#'   errors are collected in the returned result object.
#'
#' @return A standardized list with `applied_actions`, `workflow_after`,
#'   `human_prompts`, and `errors`.
#' @export
apply_scaffolder_message <- function(
  scaffolder,
  message,
  allowed_methods = scaffolder_action_methods(),
  stop_on_error = TRUE
) {
  stopifnot(inherits(scaffolder, "Scaffolder"))

  if (is.character(message)) {
    message <- parse_scaffolder_message(message)
  }
  message <- validate_scaffolder_message(message, allowed_methods = allowed_methods)

  .scaffolder_apply_message_actions(
    scaffolder = scaffolder,
    actions = message$actions,
    stop_on_error = stop_on_error
  )
}

#' Preview a machine-readable scaffolder message without mutating live workflow
#'
#' Applies a message to a deep clone of the scaffolder, returns the preview
#' result, and optionally stores the resulting workflow as a proposal on the
#' original scaffolder for later approval or discussion.
#'
#' @param scaffolder A [`Scaffolder`] instance.
#' @param message Parsed message list, JSON string, or path to a downloaded
#'   `.json` file.
#' @param allowed_methods Character vector of allowed method names.
#' @param stop_on_error Whether to stop on the first action error. When `FALSE`,
#'   errors are collected in the returned result object.
#' @param store_proposal Whether to store the previewed workflow as a proposal on
#'   the original scaffolder.
#' @param source Proposal source label used when storing a proposal.
#' @param proposal_notes Optional proposal notes. Defaults to top-level
#'   `message$notes` when available.
#'
#' @return A standardized list with `proposal_id`, `proposal`, `preview_dispatch`,
#'   `workflow_after`, `human_prompts`, and `errors`.
#' @export
preview_scaffolder_message <- function(
  scaffolder,
  message,
  allowed_methods = scaffolder_action_methods(),
  stop_on_error = TRUE,
  store_proposal = TRUE,
  source = "model",
  proposal_notes = NULL
) {
  stopifnot(inherits(scaffolder, "Scaffolder"))

  parsed_message <- if (is.character(message)) parse_scaffolder_message(message) else message
  parsed_message <- validate_scaffolder_message(parsed_message, allowed_methods = allowed_methods)

  preview_scaffolder <- scaffolder$clone(deep = TRUE)
  preview_dispatch <- apply_scaffolder_message(
    preview_scaffolder,
    parsed_message,
    allowed_methods = allowed_methods,
    stop_on_error = stop_on_error
  )

  proposal <- NULL
  proposal_id <- NULL
  if (isTRUE(store_proposal)) {
    proposal <- scaffolder$propose_workflow(
      workflow = preview_dispatch$workflow_after,
      source = source,
      notes = proposal_notes %||% parsed_message$notes
    )
    proposal_id <- proposal$id
  }

  list(
    proposal_id = proposal_id,
    proposal = proposal,
    preview_dispatch = preview_dispatch,
    workflow_after = preview_dispatch$workflow_after,
    human_prompts = preview_dispatch$human_prompts,
    errors = preview_dispatch$errors
  )
}

#' Collect human-facing questions from scaffolding output
#'
#' Extracts pending human questions from a standardized dispatch result or, if no
#' dispatch result is supplied, from the scaffolder interaction log.
#'
#' @param scaffolder A [`Scaffolder`] instance.
#' @param dispatch_result Optional result object returned by
#'   [apply_scaffolder_message()].
#'
#' @return Data frame of human-facing prompts.
#' @export
collect_scaffolder_questions <- function(scaffolder, dispatch_result = NULL) {
  stopifnot(inherits(scaffolder, "Scaffolder"))

  if (!is.null(dispatch_result)) {
    prompts <- dispatch_result$human_prompts
    if (!length(prompts)) {
      return(data.frame(
        index = integer(),
        method = character(),
        node_id = character(),
        question = character(),
        stringsAsFactors = FALSE
      ))
    }

    return(do.call(rbind, lapply(prompts, function(item) {
      data.frame(
        index = item$index,
        method = item$method,
        node_id = item$prompt$node_id %||% NA_character_,
        question = item$prompt$question %||% NA_character_,
        stringsAsFactors = FALSE
      )
    })))
  }

  relevant_types <- c("ask_human_complete", "ask_human_changes", "ask_human_rule")
  log_items <- Filter(function(item) item$type %in% relevant_types, scaffolder$interaction_log)

  if (!length(log_items)) {
    return(data.frame(
      index = integer(),
      method = character(),
      node_id = character(),
      question = character(),
      stringsAsFactors = FALSE
    ))
  }

  do.call(rbind, lapply(seq_along(log_items), function(i) {
    item <- log_items[[i]]
    data.frame(
      index = i,
      method = item$type,
      node_id = item$payload$node_id %||% NA_character_,
      question = item$payload$question %||% NA_character_,
      stringsAsFactors = FALSE
    )
  }))
}
