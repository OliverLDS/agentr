#' List LLM-callable knowledge graph methods
#'
#' @return Character vector of allowed graph-knowledge methods.
#' @export
knowledge_graph_action_methods <- function() {
  c(
    "discuss_knowledge_graph_context",
    "propose_knowledge_graph",
    "revise_knowledge_graph_proposal",
    "discuss_knowledge_graph_proposal",
    "approve_knowledge_graph_proposal",
    "reject_knowledge_graph_proposal",
    "ask_human_graph_node",
    "ask_human_graph_relation",
    "ask_human_graph_scope"
  )
}

#' Build a knowledge graph extraction prompt
#'
#' @param context Source text or context to extract graph knowledge from.
#' @param current_graph Optional existing `agentr_knowledge_graph_spec`.
#' @param format Output format, `"markdown"` or `"json"`.
#'
#' @return Prompt string.
#' @export
build_knowledge_graph_extraction_prompt <- function(context = NULL, current_graph = NULL, format = c("markdown", "json")) {
  format <- match.arg(format)
  graph_payload <- if (is.null(current_graph)) NULL else .as_knowledge_graph_spec_object(current_graph)
  payload <- list(
    role = "knowledge_graph_extractor",
    context = context,
    current_graph = graph_payload,
    memory_types = memory_types(),
    allowed_actions = knowledge_graph_action_methods(),
    instructions = c(
      "Extract graph knowledge as nodes and typed relations.",
      "Use graph triples when the source asserts concept relationships, components, mechanisms, constraints, or missing capabilities.",
      "Return constrained JSON actions only."
    ),
    relation_examples = list(
      "ACT-R --is_a--> cognitive architecture",
      "BDI --has_component--> Belief",
      "ReAct --implements_part_of--> observe-decide-act"
    ),
    response_schema = list(
      actions = list(list(
        method = "propose_knowledge_graph",
        args = list(
          graph = list(
            nodes = list(list(id = "act_r", label = "ACT-R", node_type = "concept", memory_type = "semantic")),
            edges = list(list(from = "act_r", to = "cognitive_architecture", relation = "is_a", relation_type = "is_a", memory_type = "semantic")),
            metadata = list(graph_mode = "curated")
          )
        )
      ))
    )
  )
  if (identical(format, "json")) {
    return(.prompt_json(payload))
  }
  paste("# Knowledge Graph Extraction Prompt", "", .prompt_json(payload), sep = "\n")
}

#' Build a knowledge graph revision prompt
#'
#' @param graph_state A [`KnowledgeGraphProposalState`] object.
#' @param feedback Optional human feedback text or structured list.
#' @param format Output format, `"markdown"` or `"json"`.
#'
#' @return Prompt string.
#' @export
build_knowledge_graph_revision_prompt <- function(graph_state, feedback = NULL, format = c("markdown", "json")) {
  format <- match.arg(format)
  if (!inherits(graph_state, "KnowledgeGraphProposalState")) {
    stop("`graph_state` must be a `KnowledgeGraphProposalState`.", call. = FALSE)
  }
  payload <- list(
    role = "knowledge_graph_reviser",
    graph_state = graph_state$as_list(),
    feedback = feedback,
    allowed_actions = knowledge_graph_action_methods(),
    instructions = c(
      "Revise graph-knowledge proposals using the human feedback.",
      "Keep node ids stable when possible.",
      "Return constrained JSON actions only."
    )
  )
  if (identical(format, "json")) {
    return(.prompt_json(payload))
  }
  paste("# Knowledge Graph Revision Prompt", "", .prompt_json(payload), sep = "\n")
}

#' @keywords internal
.graph_df_from_message <- function(items, kind = c("nodes", "edges")) {
  kind <- match.arg(kind)
  if (is.null(items) || !length(items)) {
    return(if (identical(kind, "nodes")) .empty_knowledge_graph_nodes() else .empty_knowledge_graph_edges())
  }
  rows <- lapply(items, function(item) {
    if (identical(kind, "nodes")) {
      do.call(knowledge_graph_node, item)
    } else {
      do.call(knowledge_graph_edge, item)
    }
  })
  do.call(rbind, rows)
}

#' @keywords internal
.knowledge_graph_from_message_payload <- function(x) {
  if (inherits(x, "agentr_knowledge_graph_spec")) {
    return(x)
  }
  if (!is.list(x)) {
    stop("Knowledge graph message `graph` must be a list or graph spec.", call. = FALSE)
  }
  new_knowledge_graph_spec(
    nodes = .graph_df_from_message(x$nodes, "nodes"),
    edges = .graph_df_from_message(x$edges, "edges"),
    metadata = if (is.null(x$metadata)) list() else x$metadata
  )
}

#' Parse a knowledge graph message
#'
#' @param x JSON string, parsed list, or `.json` file path.
#'
#' @return Parsed graph-knowledge message list.
#' @export
parse_knowledge_graph_message <- function(x) {
  x <- .parse_workflow_json_input(x, label = "Knowledge graph JSON")
  if (!is.list(x) || !is.list(x$actions)) {
    stop("Knowledge graph messages must contain an `actions` list.", call. = FALSE)
  }
  allowed <- knowledge_graph_action_methods()
  for (action in x$actions) {
    if (!is.list(action) || !is.character(action$method) || length(action$method) != 1L) {
      stop("Each knowledge graph action must contain a single `method` string.", call. = FALSE)
    }
    if (!(action$method %in% allowed)) {
      stop("Unsupported knowledge graph action: ", action$method, call. = FALSE)
    }
    if (grepl("code|eval|system|exec", action$method, ignore.case = TRUE)) {
      stop("Unsafe knowledge graph action rejected.", call. = FALSE)
    }
  }
  x
}

#' Preview a knowledge graph message
#'
#' @param state A [`KnowledgeGraphProposalState`] object.
#' @param message Parsed or raw graph-knowledge message.
#'
#' @return Preview list.
#' @export
preview_knowledge_graph_message <- function(state, message) {
  if (!inherits(state, "KnowledgeGraphProposalState")) {
    stop("`state` must be a `KnowledgeGraphProposalState`.", call. = FALSE)
  }
  message <- parse_knowledge_graph_message(message)
  list(
    actions = message$actions,
    proposal_count = length(state$proposals),
    approved_nodes = nrow(state$approved_graph$nodes),
    approved_edges = nrow(state$approved_graph$edges)
  )
}

#' Apply a knowledge graph message
#'
#' @param state A [`KnowledgeGraphProposalState`] object.
#' @param message Parsed or raw graph-knowledge message.
#'
#' @return Mutated state object.
#' @export
apply_knowledge_graph_message <- function(state, message) {
  if (!inherits(state, "KnowledgeGraphProposalState")) {
    stop("`state` must be a `KnowledgeGraphProposalState`.", call. = FALSE)
  }
  message <- parse_knowledge_graph_message(message)
  for (action in message$actions) {
    args <- if (is.null(action$args)) list() else action$args
    method <- action$method
    if (identical(method, "discuss_knowledge_graph_context")) {
      state$history <- c(state$history, list(list(event = "context_discussion", args = args)))
    } else if (identical(method, "propose_knowledge_graph")) {
      graph <- .knowledge_graph_from_message_payload(args$graph)
      proposal <- KnowledgeGraphProposal$new(
        graph = graph,
        id = if (is.null(args$proposal_id)) paste0("knowledge_graph_proposal_", length(state$proposals) + 1L) else args$proposal_id,
        notes = args$notes
      )
      state$add_proposal(proposal)
    } else if (identical(method, "revise_knowledge_graph_proposal")) {
      proposal <- state$get_proposal(args$proposal_id)
      proposal$graph <- .knowledge_graph_from_message_payload(args$graph)
      proposal$updated_at <- Sys.time()
      state$proposals[[proposal$id]] <- proposal
    } else if (identical(method, "discuss_knowledge_graph_proposal")) {
      state$discuss_proposal(args$proposal_id, note = args$note, source = if (is.null(args$source)) "human" else args$source)
    } else if (identical(method, "approve_knowledge_graph_proposal")) {
      state$approve_proposal(args$proposal_id, note = args$note)
    } else if (identical(method, "reject_knowledge_graph_proposal")) {
      state$reject_proposal(args$proposal_id, note = args$note)
    } else if (method %in% c("ask_human_graph_node", "ask_human_graph_relation", "ask_human_graph_scope")) {
      state$history <- c(state$history, list(list(event = "human_prompt", method = method, args = args)))
    }
  }
  state
}

