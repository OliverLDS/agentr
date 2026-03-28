#' Scaffolder
#'
#' Minimal human-in-the-loop scaffolding interface for workflow elicitation.
#' A `Scaffolder` evaluates a task, creates candidate workflow nodes, tracks
#' provisional confidence, and records human feedback for iterative refinement.
#'
#' @field agent Optional [`AgentCore`] owner.
#' @field task Current task text.
#' @field workflow Current workflow specification.
#' @field interaction_log List of scaffolding interactions.
#' @field completion_threshold Threshold used to flag low-confidence nodes.
#' @param agent Optional [`AgentCore`] used by `$initialize()`.
#' @param completion_threshold Confidence threshold used by `$initialize()`.
#' @param task Task text used by `$evaluate_task()` and `$decompose_task()`.
#' @param candidates Optional candidate node labels used by `$decompose_task()`.
#' @param node_id Workflow node identifier used by node-specific prompt methods.
#' @param completeness Named list of completion flags used by
#'   `$apply_human_feedback()`.
#' @param add List of node records to add in `$apply_human_feedback()`.
#' @param remove Character vector of node ids to remove in
#'   `$apply_human_feedback()`.
#' @param rule_specs Named list of rule specs used by `$apply_human_feedback()`.
#' @param confidence Named list of confidence updates used by
#'   `$apply_human_feedback()`.
#' @param type Interaction type used by `$record_interaction()`.
#' @param payload Interaction payload used by `$record_interaction()`.
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
        nodes = data.frame(
          id = character(),
          label = character(),
          confidence = numeric(),
          human_required = logical(),
          rule_spec = character(),
          implementation_hint = character(),
          complete = logical(),
          stringsAsFactors = FALSE
        ),
        task = NULL
      )
      self$interaction_log <- list()
    },

    evaluate_task = function(task) {
      self$task <- task

      if (!is.null(self$agent)) {
        self$agent$cognition$set_context(
          active_task = task,
          task_summary = task
        )
      }

      assessment <- list(
        task = task,
        requires_human_input = TRUE,
        assessed_at = Sys.time()
      )

      self$record_interaction("evaluate_task", assessment)
      invisible(assessment)
    },

    decompose_task = function(task = self$task, candidates = NULL) {
      if (is.null(task)) {
        stop("A task must be evaluated before decomposition.", call. = FALSE)
      }

      if (is.null(candidates)) {
        candidates <- c(
          "Clarify objectives",
          "Identify decision points",
          "Capture human rules",
          "Draft implementation handoff"
        )
      }

      nodes <- do.call(
        rbind,
        lapply(seq_along(candidates), function(i) {
          workflow_node(
            id = paste0("node_", i),
            label = candidates[[i]],
            confidence = max(0.3, 0.85 - (i - 1) * 0.1),
            human_required = TRUE,
            implementation_hint = if (i == length(candidates)) {
              "Translate this workflow node into code-facing specifications."
            } else {
              NA_character_
            }
          )
        })
      )

      edges <- if (nrow(nodes) <= 1) {
        data.frame(
          from = character(),
          to = character(),
          relation = character(),
          stringsAsFactors = FALSE
        )
      } else {
        do.call(
          rbind,
          lapply(seq_len(nrow(nodes) - 1), function(i) {
            workflow_edge(nodes$id[[i]], nodes$id[[i + 1]])
          })
        )
      }

      self$workflow <- new_workflow_spec(
        nodes = nodes,
        edges = edges,
        task = task,
        metadata = list(source = "scaffolder_decomposition")
      )

      self$record_interaction("decompose_task", list(task = task, nodes = nodes$id))
      invisible(self$workflow)
    },

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

    ask_human_changes = function() {
      prompt <- list(
        type = "workflow_change_check",
        question = "Should any workflow nodes be added or removed?"
      )
      self$record_interaction("ask_human_changes", prompt)
      prompt
    },

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

    apply_human_feedback = function(
      completeness = NULL,
      add = NULL,
      remove = NULL,
      rule_specs = list(),
      confidence = list()
    ) {
      nodes <- self$workflow$nodes

      if (!is.null(completeness)) {
        for (node_id in names(completeness)) {
          idx <- which(nodes$id == node_id)
          if (length(idx)) {
            nodes$complete[idx] <- isTRUE(completeness[[node_id]])
          }
        }
      }

      if (!is.null(remove) && length(remove)) {
        nodes <- nodes[!(nodes$id %in% remove), , drop = FALSE]
      }

      if (!is.null(add) && length(add)) {
        additions <- do.call(
          rbind,
          lapply(seq_along(add), function(i) {
            item <- add[[i]]
            workflow_node(
              id = item$id %||% paste0("node_", nrow(nodes) + i),
              label = item$label,
              confidence = item$confidence %||% 0.5,
              human_required = item$human_required %||% TRUE,
              rule_spec = item$rule_spec %||% NA_character_,
              implementation_hint = item$implementation_hint %||% NA_character_,
              complete = item$complete %||% FALSE
            )
          })
        )
        nodes <- rbind(nodes, additions)
      }

      if (length(rule_specs)) {
        for (node_id in names(rule_specs)) {
          idx <- which(nodes$id == node_id)
          if (length(idx)) {
            nodes$rule_spec[idx] <- as.character(rule_specs[[node_id]])
          }
        }
      }

      if (length(confidence)) {
        for (node_id in names(confidence)) {
          idx <- which(nodes$id == node_id)
          if (length(idx)) {
            nodes$confidence[idx] <- as.numeric(confidence[[node_id]])
          }
        }
      }

      self$workflow$nodes <- nodes
      self$workflow$edges <- self$workflow$edges[
        self$workflow$edges$from %in% nodes$id &
          self$workflow$edges$to %in% nodes$id,
        ,
        drop = FALSE
      ]
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

    workflow_spec = function() {
      validate_workflow_spec(self$workflow)
    },

    implementation_spec = function() {
      nodes <- self$workflow$nodes
      list(
        task = self$task,
        nodes = nodes[, c("id", "label", "rule_spec", "implementation_hint"), drop = FALSE],
        human_required = nodes[nodes$human_required, "id", drop = TRUE]
      )
    },

    low_confidence_nodes = function() {
      nodes <- self$workflow$nodes
      nodes[nodes$confidence < self$completion_threshold, , drop = FALSE]
    },

    get_node = function(node_id) {
      idx <- which(self$workflow$nodes$id == node_id)
      if (!length(idx)) {
        stop("Unknown workflow node: ", node_id, call. = FALSE)
      }
      self$workflow$nodes[idx[1], , drop = FALSE]
    },

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
