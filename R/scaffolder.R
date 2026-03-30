# Internal scaffolder helpers support 0.1.6's discussion, review, and graph
# editing APIs while keeping the exported R6 class concise.

.default_decomposition_candidates <- function() {
  c(
    "Clarify objectives",
    "Identify decision points",
    "Capture human rules",
    "Draft implementation handoff"
  )
}

#' @keywords internal
.normalize_scaffolder_source <- function(source) {
  source <- match.arg(source, choices = c("human", "model", "system"))
  source
}

#' @keywords internal
.normalize_review_status <- function(status) {
  match.arg(status, choices = c("pending", "needs_revision", "approved"))
}

#' @keywords internal
.as_optional_confidence <- function(confidence) {
  if (is.null(confidence) || length(confidence) == 0L || is.na(confidence)) {
    return(NA_real_)
  }

  confidence <- suppressWarnings(as.numeric(confidence))
  if (length(confidence) != 1L || is.na(confidence) || confidence < 0 || confidence > 1) {
    stop("Confidence values must be numeric in [0, 1].", call. = FALSE)
  }
  confidence
}

#' @keywords internal
.new_node_id <- function(existing_ids, index) {
  candidate <- paste0("node_", index)
  while (candidate %in% existing_ids) {
    index <- index + 1L
    candidate <- paste0("node_", index)
  }
  candidate
}

#' @keywords internal
.coerce_workflow_node_item <- function(item, existing_ids, index) {
  if (is.character(item) && length(item) == 1L) {
    item <- list(label = item)
  }
  if (!is.list(item) || !is.character(item$label) || length(item$label) != 1L || !nzchar(item$label)) {
    stop("Workflow node suggestions must include a non-empty `label`.", call. = FALSE)
  }

  id <- if (!is.null(item$id) && nzchar(as.character(item$id))) {
    as.character(item$id)
  } else {
    .new_node_id(existing_ids, index)
  }

  record <- workflow_node(
    id = id,
    label = item$label,
    confidence = item$confidence %||% max(0.3, 0.85 - (index - 1) * 0.1),
    human_required = item$human_required %||% TRUE,
    rule_spec = item$rule_spec %||% NA_character_,
    implementation_hint = item$implementation_hint %||% NA_character_,
    complete = item$complete %||% FALSE,
    review_status = item$review_status %||% "pending",
    review_notes = item$review_notes %||% NA_character_,
    review_confidence = item$review_confidence %||% NA_real_
  )

  list(record = record, raw = item)
}

#' @keywords internal
.coerce_workflow_edge_item <- function(item) {
  if (!is.list(item)) {
    stop("Workflow edge specifications must be lists.", call. = FALSE)
  }
  if (!is.character(item$from) || length(item$from) != 1L || !nzchar(item$from)) {
    stop("Workflow edges require a non-empty `from` id.", call. = FALSE)
  }
  if (!is.character(item$to) || length(item$to) != 1L || !nzchar(item$to)) {
    stop("Workflow edges require a non-empty `to` id.", call. = FALSE)
  }

  workflow_edge(
    from = item$from,
    to = item$to,
    relation = item$relation %||% "depends_on",
    confidence = item$confidence %||% NA_real_,
    notes = item$notes %||% NA_character_
  )
}

#' @keywords internal
.deduplicate_edges <- function(edges) {
  if (!nrow(edges)) {
    return(edges)
  }
  edges[!duplicated(edges[, c("from", "to", "relation")]), , drop = FALSE]
}

#' @keywords internal
.coerce_decomposition_plan <- function(candidates = NULL, suggestions = NULL) {
  if (is.null(suggestions)) {
    candidates <- candidates %||% .default_decomposition_candidates()
    suggestions <- as.list(candidates)
  }

  if (is.character(suggestions)) {
    suggestions <- as.list(suggestions)
  }

  if (!is.list(suggestions)) {
    stop("`suggestions` must be NULL, character, or a list.", call. = FALSE)
  }

  node_specs <- suggestions$nodes %||% suggestions
  edge_specs <- suggestions$edges %||% list()
  notes <- suggestions$notes %||% NULL

  if (!length(node_specs)) {
    stop("At least one workflow node suggestion is required.", call. = FALSE)
  }

  existing_ids <- character()
  built_nodes <- vector("list", length(node_specs))
  raw_nodes <- vector("list", length(node_specs))
  for (i in seq_along(node_specs)) {
    built <- .coerce_workflow_node_item(node_specs[[i]], existing_ids = existing_ids, index = i)
    built_nodes[[i]] <- built$record
    raw_nodes[[i]] <- built$raw
    existing_ids <- c(existing_ids, built$record$id[[1]])
  }

  nodes <- do.call(rbind, built_nodes)

  inferred_edges <- list()
  edge_index <- 1L
  for (i in seq_along(raw_nodes)) {
    node_id <- nodes$id[[i]]
    item <- raw_nodes[[i]]

    if (!is.null(item$depends_on)) {
      for (dep in unlist(item$depends_on, use.names = FALSE)) {
        inferred_edges[[edge_index]] <- workflow_edge(as.character(dep), node_id)
        edge_index <- edge_index + 1L
      }
    }
    if (!is.null(item$after)) {
      inferred_edges[[edge_index]] <- workflow_edge(as.character(item$after), node_id)
      edge_index <- edge_index + 1L
    }
    if (!is.null(item$before)) {
      inferred_edges[[edge_index]] <- workflow_edge(node_id, as.character(item$before))
      edge_index <- edge_index + 1L
    }
  }

  explicit_edges <- if (length(edge_specs)) {
    do.call(rbind, lapply(edge_specs, .coerce_workflow_edge_item))
  } else {
    .empty_workflow_edges()
  }
  inferred_edges <- if (length(inferred_edges)) {
    do.call(rbind, inferred_edges)
  } else {
    .empty_workflow_edges()
  }

  edges <- rbind(inferred_edges, explicit_edges)
  if (!nrow(edges) && nrow(nodes) > 1L) {
    edges <- do.call(
      rbind,
      lapply(seq_len(nrow(nodes) - 1L), function(i) {
        workflow_edge(nodes$id[[i]], nodes$id[[i + 1L]])
      })
    )
  }

  list(
    nodes = nodes,
    edges = .deduplicate_edges(edges),
    notes = notes
  )
}

#' @keywords internal
.append_metadata_history <- function(metadata, key, item) {
  history_key <- paste0(key, "_history")
  metadata[[history_key]] <- c(metadata[[history_key]] %||% list(), list(item))
  metadata
}

#' @keywords internal
.append_discussion_round <- function(metadata, round) {
  metadata$discussion_rounds <- c(metadata$discussion_rounds %||% list(), list(round))
  metadata
}

#' @keywords internal
.coerce_node_records <- function(items, nodes) {
  if (is.null(items) || !length(items)) {
    return(.empty_workflow_nodes())
  }

  existing_ids <- nodes$id
  out <- vector("list", length(items))
  for (i in seq_along(items)) {
    built <- .coerce_workflow_node_item(items[[i]], existing_ids = existing_ids, index = nrow(nodes) + i)
    out[[i]] <- built$record
    existing_ids <- c(existing_ids, built$record$id[[1]])
  }
  do.call(rbind, out)
}

#' @keywords internal
.apply_named_node_values <- function(nodes, values, column, coercer = identity) {
  if (is.null(values) || !length(values)) {
    return(nodes)
  }

  for (node_id in names(values)) {
    idx <- which(nodes$id == node_id)
    if (length(idx)) {
      nodes[[column]][idx] <- coercer(values[[node_id]])
    }
  }
  nodes
}

#' @keywords internal
.coerce_edge_specs <- function(items) {
  if (is.null(items) || !length(items)) {
    return(.empty_workflow_edges())
  }
  do.call(rbind, lapply(items, .coerce_workflow_edge_item))
}

#' @keywords internal
.remove_edge_specs <- function(edges, remove_edges) {
  if (is.null(remove_edges) || !length(remove_edges) || !nrow(edges)) {
    return(edges)
  }

  for (spec in remove_edges) {
    from <- as.character(spec$from %||% "")
    to <- as.character(spec$to %||% "")
    relation <- spec$relation %||% NULL
    keep <- !(edges$from == from & edges$to == to)
    if (!is.null(relation)) {
      keep <- !(edges$from == from & edges$to == to & edges$relation == relation)
    }
    edges <- edges[keep, , drop = FALSE]
  }
  edges
}

#' @keywords internal
.insert_workflow_nodes <- function(nodes, edges, insert) {
  if (is.null(insert) || !length(insert)) {
    return(list(nodes = nodes, edges = edges))
  }

  for (i in seq_along(insert)) {
    spec <- insert[[i]]
    node_spec <- spec$node %||% spec
    addition <- .coerce_node_records(list(node_spec), nodes)
    new_id <- addition$id[[1]]
    nodes <- rbind(nodes, addition)

    if (!is.null(spec$between)) {
      between <- unlist(spec$between, use.names = FALSE)
      if (length(between) != 2L) {
        stop("Insert `between` must contain exactly two node ids.", call. = FALSE)
      }
      edges <- edges[!(edges$from == between[[1]] & edges$to == between[[2]]), , drop = FALSE]
      edges <- rbind(
        edges,
        workflow_edge(between[[1]], new_id, relation = spec$relation %||% "depends_on"),
        workflow_edge(new_id, between[[2]], relation = spec$relation %||% "depends_on")
      )
      next
    }

    if (!is.null(spec$after)) {
      edges <- rbind(edges, workflow_edge(spec$after, new_id, relation = spec$relation %||% "depends_on"))
    }
    if (!is.null(spec$before)) {
      edges <- rbind(edges, workflow_edge(new_id, spec$before, relation = spec$relation %||% "depends_on"))
    }
  }

  list(nodes = nodes, edges = .deduplicate_edges(edges))
}

#' Scaffolder
#'
#' Human-in-the-loop scaffolding interface for iterative workflow elicitation.
#' A `Scaffolder` keeps a persistent task-evaluation artifact, supports
#' free-form discussion rounds before structured graph edits, separates
#' workflow-level and node-level review, and treats node/edge edits as
#' first-class operations.
#'
#' @field agent Optional [`AgentCore`] owner.
#' @field task Current task text.
#' @field workflow Current workflow specification.
#' @field interaction_log List of scaffolding interactions.
#' @field completion_threshold Threshold used to flag low-confidence nodes.
#' @param agent Optional [`AgentCore`] used by `$initialize()`.
#' @param completion_threshold Confidence threshold used by `$initialize()`.
#' @param task Task text used by `$evaluate_task()` and `$decompose_task()`.
#' @param summary Optional task summary used by `$evaluate_task()`.
#' @param workflow_complete Optional task-level completeness flag used by
#'   `$evaluate_task()`.
#' @param blockers Optional blocker strings used by `$evaluate_task()`.
#' @param next_focus Optional next-focus note used by `$evaluate_task()`.
#' @param candidates Optional candidate node labels used by `$decompose_task()`.
#' @param suggestions Optional free-form or structured graph suggestions used by
#'   `$decompose_task()`.
#' @param feedback Free-form discussion feedback used by `$discuss_task()`.
#' @param source Discussion source used by `$discuss_task()`.
#' @param node_id Workflow node identifier used by node-specific methods.
#' @param confidence Confidence value used by review/edit helpers.
#' @param status Review status used by `$review_workflow()` and
#'   `$review_node()`.
#' @param notes Optional review notes.
#' @param complete Optional node completion flag used by `$review_node()`.
#' @param add List of node records to add in `$edit_workflow()`.
#' @param insert List of insertion specs used by `$edit_workflow()`.
#' @param remove Character vector of node ids to remove in `$edit_workflow()`.
#' @param add_edges List of edge records to add in `$edit_workflow()`.
#' @param remove_edges List of edge specs to remove in `$edit_workflow()`.
#' @param rule_specs Named list of rule specs used by `$edit_workflow()`.
#' @param completeness Named list of completion flags used by
#'   `$apply_human_feedback()`.
#' @param type Interaction type used by `$record_interaction()`.
#' @param payload Interaction payload used by `$record_interaction()`.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(agent = NULL, completion_threshold = 0.75)`}{Create a scaffolder with empty workflow state and review metadata.}
#'   \item{`$evaluate_task(task, summary = NULL, workflow_complete = NA, blockers = NULL, next_focus = NULL)`}{Create or refresh the persistent task-evaluation artifact.}
#'   \item{`$discuss_task(feedback, source = "human", node_id = NULL, confidence = NA_real_)`}{Record a free-form human, model, or system discussion round.}
#'   \item{`$decompose_task(task = self$task, candidates = NULL, suggestions = NULL)`}{Create or replace the workflow from linear candidates or non-linear graph suggestions.}
#'   \item{`$ask_human_complete(node_id)`}{Create a prompt asking whether a workflow node is complete.}
#'   \item{`$ask_human_changes()`}{Create a prompt asking what workflow or edge changes should happen next.}
#'   \item{`$ask_human_rule(node_id)`}{Create a prompt requesting a node-specific rule.}
#'   \item{`$review_workflow(status = "pending", notes = NULL, confidence = NA_real_)`}{Store workflow-level completeness or revision review state.}
#'   \item{`$review_node(node_id, status = "pending", notes = NULL, confidence = NA_real_, complete = NULL)`}{Store node-level correctness or completion review state.}
#'   \item{`$edit_workflow(add = NULL, insert = NULL, remove = NULL, add_edges = NULL, remove_edges = NULL, rule_specs = list(), confidence = list())`}{Apply first-class node and edge edits to the current workflow.}
#'   \item{`$apply_human_feedback(completeness = NULL, add = NULL, remove = NULL, rule_specs = list(), confidence = list())`}{Compatibility wrapper for structured human workflow edits.}
#'   \item{`$workflow_spec()`}{Validate and return the current workflow specification.}
#'   \item{`$implementation_spec()`}{Return an implementation-facing summary of workflow nodes and rules.}
#'   \item{`$low_confidence_nodes()`}{Return workflow nodes below the completion threshold.}
#'   \item{`$get_node(node_id)`}{Return a single workflow node by identifier.}
#'   \item{`$record_interaction(type, payload)`}{Append an interaction event to the scaffolder log.}
#' }
#'
#' @export
Scaffolder <- R6::R6Class(
  classname = "Scaffolder",
  public = list(
    agent = NULL,
    task = NULL,
    workflow = NULL,
    interaction_log = NULL,
    completion_threshold = NULL,

    #' @description
    #' Create a `Scaffolder` with empty workflow, review, and discussion state.
    initialize = function(
      agent = NULL,
      completion_threshold = 0.75
    ) {
      if (!is.null(agent)) {
        stopifnot(inherits(agent, "AgentCore"))
      }
      self$agent <- agent
      self$completion_threshold <- completion_threshold
      self$workflow <- new_workflow_spec(
        nodes = .empty_workflow_nodes(),
        edges = .empty_workflow_edges(),
        task = NULL,
        metadata = list(
          evaluation = NULL,
          workflow_review = NULL,
          discussion_rounds = list()
        )
      )
      self$interaction_log <- list()
    },

    #' @description
    #' Create or refresh the persistent task-evaluation artifact.
    evaluate_task = function(
      task,
      summary = NULL,
      workflow_complete = NA,
      blockers = NULL,
      next_focus = NULL
    ) {
      if (!is.character(task) || length(task) != 1L || !nzchar(task)) {
        stop("`task` must be a non-empty string.", call. = FALSE)
      }

      self$task <- task
      self$workflow$task <- task

      if (!is.null(self$agent)) {
        self$agent$cognition$set_context(
          active_task = task,
          task_summary = summary %||% task
        )
      }

      assessment <- list(
        task = task,
        summary = summary %||% task,
        workflow_complete = if (isTRUE(workflow_complete)) TRUE else if (identical(workflow_complete, FALSE)) FALSE else NA,
        blockers = as.character(blockers %||% character()),
        next_focus = if (is.null(next_focus)) NA_character_ else as.character(next_focus),
        assessed_at = Sys.time()
      )

      self$workflow$metadata$evaluation <- assessment
      self$workflow$metadata <- .append_metadata_history(self$workflow$metadata, "evaluation", assessment)
      self$record_interaction("evaluate_task", assessment)
      invisible(assessment)
    },

    #' @description
    #' Record a free-form human, model, or system discussion round.
    discuss_task = function(
      feedback,
      source = "human",
      node_id = NULL,
      confidence = NA_real_
    ) {
      if (!is.character(feedback) || length(feedback) != 1L || !nzchar(feedback)) {
        stop("`feedback` must be a non-empty string.", call. = FALSE)
      }
      if (!is.null(node_id)) {
        self$get_node(node_id)
      }

      round <- list(
        source = .normalize_scaffolder_source(source),
        feedback = feedback,
        node_id = node_id %||% NA_character_,
        confidence = .as_optional_confidence(confidence),
        discussed_at = Sys.time()
      )

      self$workflow$metadata <- .append_discussion_round(self$workflow$metadata, round)
      self$record_interaction("discuss_task", round)
      invisible(round)
    },

    #' @description
    #' Replace the workflow with nodes and edges derived from task suggestions.
    decompose_task = function(task = self$task, candidates = NULL, suggestions = NULL) {
      if (is.null(task)) {
        stop("A task must be evaluated before decomposition.", call. = FALSE)
      }

      plan <- .coerce_decomposition_plan(candidates = candidates, suggestions = suggestions)
      metadata <- self$workflow$metadata
      metadata$source <- "scaffolder_decomposition"
      metadata$decomposition <- list(
        notes = plan$notes,
        updated_at = Sys.time()
      )

      self$workflow <- new_workflow_spec(
        nodes = plan$nodes,
        edges = plan$edges,
        task = task,
        metadata = metadata
      )

      self$record_interaction(
        "decompose_task",
        list(
          task = task,
          nodes = plan$nodes$id,
          edges = plan$edges[, c("from", "to", "relation"), drop = FALSE]
        )
      )
      invisible(self$workflow)
    },

    #' @description
    #' Build a prompt asking whether a node is complete.
    ask_human_complete = function(node_id) {
      node <- self$get_node(node_id)
      prompt <- list(
        type = "completeness_check",
        node_id = node_id,
        question = paste0("Is this node complete: ", node$label, "?")
      )
      self$record_interaction("ask_human_complete", prompt)
      prompt
    },

    #' @description
    #' Build a prompt asking what workflow or edge changes should happen next.
    ask_human_changes = function() {
      prompt <- list(
        type = "workflow_change_check",
        question = "What workflow or edge changes should be made next?"
      )
      self$record_interaction("ask_human_changes", prompt)
      prompt
    },

    #' @description
    #' Build a prompt asking for a node-specific rule.
    ask_human_rule = function(node_id) {
      node <- self$get_node(node_id)
      prompt <- list(
        type = "rule_request",
        node_id = node_id,
        question = paste0("What rule should govern node '", node$label, "'?")
      )
      self$record_interaction("ask_human_rule", prompt)
      prompt
    },

    #' @description
    #' Store workflow-level completeness or revision review state.
    review_workflow = function(status = "pending", notes = NULL, confidence = NA_real_) {
      artifact <- list(
        status = .normalize_review_status(status),
        notes = if (is.null(notes)) NA_character_ else as.character(notes),
        confidence = .as_optional_confidence(confidence),
        updated_at = Sys.time()
      )

      self$workflow$metadata$workflow_review <- artifact
      self$workflow$metadata <- .append_metadata_history(self$workflow$metadata, "workflow_review", artifact)
      self$record_interaction("review_workflow", artifact)
      invisible(artifact)
    },

    #' @description
    #' Store node-level review status, notes, confidence, and completion state.
    review_node = function(
      node_id,
      status = "pending",
      notes = NULL,
      confidence = NA_real_,
      complete = NULL
    ) {
      idx <- which(self$workflow$nodes$id == node_id)
      if (!length(idx)) {
        stop("Unknown workflow node: ", node_id, call. = FALSE)
      }

      self$workflow$nodes$review_status[idx] <- .normalize_review_status(status)
      self$workflow$nodes$review_notes[idx] <- if (is.null(notes)) NA_character_ else as.character(notes)
      self$workflow$nodes$review_confidence[idx] <- .as_optional_confidence(confidence)
      if (!is.null(complete)) {
        self$workflow$nodes$complete[idx] <- isTRUE(complete)
      }

      payload <- as.list(self$workflow$nodes[idx[1], , drop = FALSE])
      self$record_interaction("review_node", payload)
      invisible(self$workflow$nodes[idx[1], , drop = FALSE])
    },

    #' @description
    #' Apply first-class node and edge edits to the current workflow.
    edit_workflow = function(
      add = NULL,
      insert = NULL,
      remove = NULL,
      add_edges = NULL,
      remove_edges = NULL,
      rule_specs = list(),
      confidence = list()
    ) {
      nodes <- self$workflow$nodes
      edges <- self$workflow$edges

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

      self$workflow <- new_workflow_spec(
        nodes = nodes,
        edges = edges,
        task = self$task,
        metadata = self$workflow$metadata
      )

      self$record_interaction(
        "edit_workflow",
        list(
          add = add,
          insert = insert,
          remove = remove,
          add_edges = add_edges,
          remove_edges = remove_edges,
          rule_specs = rule_specs,
          confidence = confidence
        )
      )
      invisible(self$workflow)
    },

    #' @description
    #' Apply legacy structured human feedback to the workflow.
    apply_human_feedback = function(
      completeness = NULL,
      add = NULL,
      remove = NULL,
      rule_specs = list(),
      confidence = list()
    ) {
      self$edit_workflow(
        add = add,
        remove = remove,
        rule_specs = rule_specs,
        confidence = confidence
      )

      if (!is.null(completeness)) {
        for (node_id in names(completeness)) {
          status <- if (isTRUE(completeness[[node_id]])) "approved" else "needs_revision"
          self$review_node(
            node_id = node_id,
            status = status,
            notes = "Legacy completeness feedback applied.",
            complete = isTRUE(completeness[[node_id]])
          )
        }
      }

      self$record_interaction(
        "apply_human_feedback",
        list(
          completeness = completeness,
          add = add,
          remove = remove,
          rule_specs = rule_specs,
          confidence = confidence
        )
      )
      invisible(self$workflow)
    },

    #' @description
    #' Validate and return the current workflow specification.
    workflow_spec = function() {
      validate_workflow_spec(self$workflow)
    },

    #' @description
    #' Return an implementation-facing summary of workflow nodes and rules.
    implementation_spec = function() {
      nodes <- self$workflow$nodes
      list(
        task = self$task,
        nodes = nodes[, c("id", "label", "rule_spec", "implementation_hint"), drop = FALSE],
        human_required = nodes[nodes$human_required, "id", drop = TRUE]
      )
    },

    #' @description
    #' Return workflow nodes whose confidence falls below the completion threshold.
    low_confidence_nodes = function() {
      nodes <- self$workflow$nodes
      nodes[nodes$confidence < self$completion_threshold, , drop = FALSE]
    },

    #' @description
    #' Return a single workflow node by identifier.
    get_node = function(node_id) {
      idx <- which(self$workflow$nodes$id == node_id)
      if (!length(idx)) {
        stop("Unknown workflow node: ", node_id, call. = FALSE)
      }
      self$workflow$nodes[idx[1], , drop = FALSE]
    },

    #' @description
    #' Append an interaction record to the scaffolder log.
    record_interaction = function(type, payload) {
      self$interaction_log[[length(self$interaction_log) + 1]] <- list(
        type = type,
        payload = payload,
        timestamp = Sys.time()
      )
      invisible(self)
    }
  )
)
