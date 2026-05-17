#' @keywords internal
.design_review_id <- function(prefix = "design_review") {
  paste0(prefix, "_", format(Sys.time(), "%Y%m%d%H%M%S"))
}

#' @keywords internal
.design_review_severities <- function() {
  c("low", "medium", "high")
}

#' @keywords internal
.design_review_feedback_targets <- function() {
  c(
    "workflow_node",
    "workflow_edge",
    "memory_schema",
    "knowledge_item",
    "knowledge_edge",
    "subsystem_assignment",
    "review_gate",
    "implementation_hint",
    "interface_schema",
    "agent_summary",
    "workflow_graph",
    "memory_field",
    "narrative_knowledge",
    "graph_knowledge",
    "graph_node",
    "graph_edge",
    "proposal_state",
    "feedback_schema",
    "design_bundle"
  )
}

#' @keywords internal
.design_review_issue_types <- function() {
  c(
    "missing",
    "unclear",
    "incorrect",
    "inconsistent",
    "unsafe",
    "too_broad",
    "too_narrow",
    "duplicate",
    "conflicting_assumption",
    "needs_human_gate",
    "needs_automation_status",
    "needs_trace",
    "implementation_gap"
  )
}

#' @keywords internal
.design_review_feedback_statuses <- function() {
  c("open", "accepted", "rejected", "resolved", "superseded")
}

#' @keywords internal
.normalize_design_review_severity <- function(x) {
  match.arg(as.character(x)[1], choices = .design_review_severities())
}

#' @keywords internal
.normalize_design_review_target <- function(x) {
  match.arg(as.character(x)[1], choices = .design_review_feedback_targets())
}

#' @keywords internal
.normalize_design_review_issue_type <- function(x) {
  match.arg(as.character(x)[1], choices = .design_review_issue_types())
}

#' @keywords internal
.normalize_design_feedback_status <- function(x) {
  match.arg(as.character(x)[1], choices = .design_review_feedback_statuses())
}

#' @keywords internal
.design_json_ready <- function(x) {
  if (inherits(x, "POSIXt")) {
    return(format(as.POSIXct(x), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
  }
  if (inherits(x, "Date")) {
    return(as.character(x))
  }
  if (is.factor(x)) {
    return(as.character(x))
  }
  if (is.data.frame(x)) {
    return(.design_df_records(x))
  }
  if (is.list(x)) {
    return(lapply(x, .design_json_ready))
  }
  if (length(x) == 1L && is.na(x)) {
    return(NULL)
  }
  x
}

#' @keywords internal
.design_df_records <- function(x) {
  if (!is.data.frame(x)) {
    stop("Expected a data frame.", call. = FALSE)
  }
  if (!nrow(x)) {
    return(list())
  }
  lapply(seq_len(nrow(x)), function(i) {
    row <- list()
    for (name in names(x)) {
      value <- if (is.list(x[[name]])) x[[name]][[i]] else x[[name]][i]
      row[[name]] <- .design_json_ready(value)
    }
    row
  })
}

#' @keywords internal
.workflow_review_section <- function(workflow) {
  if (is.null(workflow)) {
    return(list(
      nodes = list(),
      edges = list(),
      task = NULL,
      metadata = list(),
      counts = list(nodes = 0L, edges = 0L)
    ))
  }
  validate_workflow_spec(workflow)
  list(
    nodes = .design_df_records(workflow$nodes),
    edges = .design_df_records(workflow$edges),
    task = workflow$task,
    metadata = .design_json_ready(workflow$metadata),
    counts = list(nodes = nrow(workflow$nodes), edges = nrow(workflow$edges))
  )
}

#' @keywords internal
.memory_review_section <- function(memory_spec) {
  if (is.null(memory_spec)) {
    return(list(fields = list(), metadata = list(), counts = list(fields = 0L)))
  }
  memory_spec <- .as_memory_spec_object(memory_spec)
  list(
    fields = .design_json_ready(unname(memory_spec$fields)),
    metadata = .design_json_ready(memory_spec$metadata),
    counts = list(fields = length(memory_spec$fields))
  )
}

#' @keywords internal
.narrative_knowledge_review_section <- function(knowledge_spec) {
  if (is.null(knowledge_spec)) {
    return(list(
      items = list(),
      vector_refs = list(),
      metadata = list(),
      counts = list(items = 0L, vector_refs = 0L)
    ))
  }
  knowledge_spec <- .coerce_knowledge_spec_or_null(knowledge_spec)
  knowledge_spec$validate()
  list(
    items = .design_json_ready(unname(knowledge_spec$items)),
    vector_refs = .design_json_ready(knowledge_spec$vector_refs),
    metadata = .design_json_ready(knowledge_spec$metadata),
    counts = list(items = length(knowledge_spec$items), vector_refs = length(knowledge_spec$vector_refs))
  )
}

#' @keywords internal
.graph_knowledge_review_section <- function(graph_spec = NULL, knowledge_spec = NULL) {
  if (is.null(graph_spec) && inherits(knowledge_spec, "KnowledgeSpec")) {
    graph_spec <- knowledge_spec$graph
  }
  if (is.null(graph_spec)) {
    return(list(nodes = list(), edges = list(), metadata = list(), counts = list(nodes = 0L, edges = 0L)))
  }
  graph_spec <- .as_knowledge_graph_spec_object(graph_spec)
  list(
    nodes = .design_df_records(graph_spec$nodes),
    edges = .design_df_records(graph_spec$edges),
    metadata = .design_json_ready(graph_spec$metadata),
    counts = list(nodes = nrow(graph_spec$nodes), edges = nrow(graph_spec$edges))
  )
}

#' @keywords internal
.proposal_state_snapshot <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  if (inherits(x, "WorkflowProposalState")) {
    return(.design_json_ready(x$as_list()))
  }
  if (inherits(x, "KnowledgeProposalState")) {
    return(.design_json_ready(x$as_list()))
  }
  if (inherits(x, "MemoryProposalState")) {
    return(.design_json_ready(x$as_list()))
  }
  if (inherits(x, "KnowledgeGraphProposalState")) {
    return(.design_json_ready(x$as_list()))
  }
  if (inherits(x, "AgentScaffoldState")) {
    return(.design_json_ready(x$as_list()))
  }
  if (is.list(x)) {
    return(.design_json_ready(x))
  }
  stop("Proposal-state snapshots must be supported proposal-state objects or lists.", call. = FALSE)
}

#' @keywords internal
.design_review_feedback_schema <- function() {
  list(
    version = "agentr_design_feedback_v1",
    targets = .design_review_feedback_targets(),
    issue_types = .design_review_issue_types(),
    severities = .design_review_severities(),
    statuses = .design_review_feedback_statuses(),
    required_fields = c("target", "field", "issue_type", "issue", "suggestion", "severity"),
    optional_fields = c("id", "target_id", "item_id", "location", "status", "source", "created_at", "metadata"),
    example = design_feedback_item(
      target = "memory_schema",
      target_id = "agent.memory.state",
      field = "agent.memory.state",
      issue_type = "unclear",
      issue = "State names are unclear.",
      suggestion = "Separate lifecycle_state from task_state.",
      severity = "medium"
    )
  )
}

#' Create a structured design-feedback item
#'
#' Feedback items are the machine-readable output expected from a future
#' JS/HTML review layer. They are intentionally structured rather than free
#' text so they can be routed into workflow, memory, knowledge, or graph
#' revision prompts.
#'
#' @param target Review target, such as `"workflow_node"`, `"memory_schema"`,
#'   `"knowledge_item"`, or `"graph_edge"`.
#' @param field Field path or semantic field name being reviewed.
#' @param issue_type Issue type.
#' @param issue Concise issue description.
#' @param suggestion Concise suggested change.
#' @param severity Severity label: `low`, `medium`, or `high`.
#' @param id Optional feedback id.
#' @param target_id Optional target identifier, such as a node id or
#'   memory-field id.
#' @param item_id Optional target item id, such as a node id or memory-field id.
#' @param location Optional structured location metadata.
#' @param status Feedback status.
#' @param source Feedback source.
#' @param created_at Creation timestamp.
#' @param metadata Additional metadata list.
#'
#' @return A validated design-feedback item list.
#' @export
design_feedback_item <- function(
  target,
  field,
  issue,
  suggestion,
  severity = "medium",
  issue_type = "unclear",
  id = NULL,
  target_id = NULL,
  item_id = NA_character_,
  location = list(),
  status = "open",
  source = "human",
  created_at = Sys.time(),
  metadata = list()
) {
  item <- list(
    id = if (is.null(id)) .design_review_id("feedback") else as.character(id)[1],
    target = .normalize_design_review_target(target),
    target_id = if (is.null(target_id)) {
      if (is.null(item_id)) NA_character_ else as.character(item_id)[1]
    } else {
      as.character(target_id)[1]
    },
    field = as.character(field)[1],
    item_id = if (is.null(item_id)) NA_character_ else as.character(item_id)[1],
    issue_type = .normalize_design_review_issue_type(issue_type),
    issue = as.character(issue)[1],
    suggestion = as.character(suggestion)[1],
    severity = .normalize_design_review_severity(severity),
    location = if (is.null(location)) list() else location,
    status = .normalize_design_feedback_status(status),
    source = if (is.null(source)) "human" else as.character(source)[1],
    created_at = as.POSIXct(created_at)[1],
    metadata = if (is.null(metadata)) list() else metadata
  )
  validate_design_feedback(item)
  class(item) <- c("agentr_design_feedback_item", class(item))
  item
}

#' Validate structured design feedback
#'
#' @param x A feedback item, list of feedback items, or parsed feedback bundle
#'   containing a `feedback` field.
#' @param review_spec Optional [`DesignReviewSpec`] or review-spec list used to
#'   warn when feedback target ids no longer exist in the reviewed design.
#'
#' @return The validated feedback, invisibly.
#' @export
validate_design_feedback <- function(x, review_spec = NULL) {
  if (is.data.frame(x)) {
    x <- .design_df_records(x)
  }
  if (is.list(x) && "feedback" %in% names(x) && is.list(x$feedback)) {
    x <- x$feedback
    if (is.data.frame(x)) {
      x <- .design_df_records(x)
    }
  }
  if (is.list(x) && all(c("target", "field", "issue", "suggestion", "severity") %in% names(x))) {
    if (is.null(x$issue_type)) {
      x$issue_type <- "unclear"
    }
    if (is.null(x$target_id) && !is.null(x$item_id)) {
      x$target_id <- x$item_id
    }
    if (!is.character(x$field) || length(x$field) != 1L || is.na(x$field) || !nzchar(x$field)) {
      stop("Design feedback `field` must be a non-empty string.", call. = FALSE)
    }
    if (!is.character(x$issue) || length(x$issue) != 1L || is.na(x$issue) || !nzchar(x$issue)) {
      stop("Design feedback `issue` must be a non-empty string.", call. = FALSE)
    }
    if (!is.character(x$suggestion) || length(x$suggestion) != 1L || is.na(x$suggestion) || !nzchar(x$suggestion)) {
      stop("Design feedback `suggestion` must be a non-empty string.", call. = FALSE)
    }
    .normalize_design_review_target(x$target)
    .normalize_design_review_issue_type(x$issue_type)
    .normalize_design_review_severity(x$severity)
    if (!is.null(x$status)) {
      .normalize_design_feedback_status(x$status)
    }
    if (!is.null(x$location) && !is.list(x$location)) {
      stop("Design feedback `location` must be a list.", call. = FALSE)
    }
    if (!is.null(x$metadata)) {
      .validate_metadata_list(x$metadata)
    }
    .warn_missing_design_feedback_target(x, review_spec)
    return(invisible(x))
  }
  if (is.list(x) && length(x)) {
    for (item in x) {
      validate_design_feedback(item, review_spec = review_spec)
    }
    return(invisible(x))
  }
  stop("Design feedback must be a feedback item or a non-empty list of feedback items.", call. = FALSE)
}

#' Parse design feedback JSON
#'
#' @param x JSON string, parsed list, or `.json` file path.
#'
#' @return A list of validated design-feedback items.
#' @export
parse_design_feedback_json <- function(x) {
  x <- .parse_workflow_json_input(x, label = "Design feedback JSON")
  if (is.list(x) && "feedback" %in% names(x)) {
    feedback <- x$feedback
  } else {
    feedback <- x
  }
  if (is.data.frame(feedback)) {
    feedback <- .design_df_records(feedback)
  }
  if (is.list(feedback) && all(c("target", "field", "issue", "suggestion", "severity") %in% names(feedback))) {
    feedback <- list(feedback)
  }
  validate_design_feedback(feedback)
  feedback
}

#' @keywords internal
.design_review_target_ids <- function(review_spec) {
  if (is.null(review_spec)) {
    return(list())
  }
  if (inherits(review_spec, "DesignReviewSpec")) {
    review_spec <- review_spec$to_list()
  }
  if (!is.list(review_spec)) {
    return(list())
  }
  ids_from_records <- function(records, field = "id") {
    if (!length(records)) {
      return(character())
    }
    out <- vapply(records, function(record) {
      value <- record[[field]]
      if (is.null(value) || length(value) != 1L || is.na(value)) "" else as.character(value)
    }, character(1))
    out[nzchar(out)]
  }
  list(
    workflow_node = ids_from_records(review_spec$workflow_graph$nodes),
    workflow_edge = paste(
      ids_from_records(review_spec$workflow_graph$edges, "from"),
      ids_from_records(review_spec$workflow_graph$edges, "to"),
      sep = "->"
    ),
    memory_schema = c("memory_schema", ids_from_records(review_spec$memory_schema$fields)),
    memory_field = ids_from_records(review_spec$memory_schema$fields),
    knowledge_item = ids_from_records(review_spec$narrative_knowledge$items),
    knowledge_edge = paste(
      ids_from_records(review_spec$graph_knowledge$edges, "from"),
      ids_from_records(review_spec$graph_knowledge$edges, "to"),
      sep = "->"
    ),
    graph_node = ids_from_records(review_spec$graph_knowledge$nodes),
    graph_edge = paste(
      ids_from_records(review_spec$graph_knowledge$edges, "from"),
      ids_from_records(review_spec$graph_knowledge$edges, "to"),
      sep = "->"
    ),
    interface_schema = c("interface_schema", names(review_spec$metadata$interface_spec)),
    agent_summary = c("agent_summary", review_spec$agent_name)
  )
}

#' @keywords internal
.warn_missing_design_feedback_target <- function(item, review_spec = NULL) {
  if (is.null(review_spec) || is.null(item$target_id) || is.na(item$target_id) || !nzchar(item$target_id)) {
    return(invisible(NULL))
  }
  ids <- .design_review_target_ids(review_spec)
  valid_ids <- ids[[as.character(item$target)[1]]]
  if (!is.null(valid_ids) && length(valid_ids) && !(item$target_id %in% valid_ids)) {
    warning(
      "Design feedback target id not found in review spec: ",
      item$target_id,
      call. = FALSE
    )
  }
  invisible(NULL)
}

#' Create a design-review specification
#'
#' Convenience constructor matching the public plan API.
#'
#' @param ... Arguments passed to [`DesignReviewSpec`]`$new()`.
#'
#' @return A [`DesignReviewSpec`] object.
#' @export
new_design_review_spec <- function(...) {
  DesignReviewSpec$new(...)
}

#' DesignReviewSpec
#'
#' Data contract for a future JS/HTML human review layer. It packages the
#' current design artifacts into stable sections that can be rendered,
#' commented on, and converted back into structured feedback.
#'
#' @field review_id Review bundle identifier.
#' @field agent_name Agent name.
#' @field task Source task.
#' @field generated_at Bundle creation timestamp.
#' @field workflow_graph Workflow graph section.
#' @field memory_schema Memory schema section.
#' @field narrative_knowledge Narrative knowledge section.
#' @field graph_knowledge Graph-knowledge section.
#' @field proposal_states Proposal-state snapshots.
#' @field feedback_schema Structured feedback schema.
#' @field metadata Free-form metadata.
#' @param review_id Review bundle identifier.
#' @param agent_name Agent name.
#' @param task Source task.
#' @param generated_at Bundle creation timestamp.
#' @param workflow_graph Workflow graph section.
#' @param memory_schema Memory schema section.
#' @param narrative_knowledge Narrative knowledge section.
#' @param graph_knowledge Graph-knowledge section.
#' @param proposal_states Proposal-state snapshots.
#' @param feedback_schema Structured feedback schema.
#' @param metadata Free-form metadata.
#' @param ... Unused print arguments.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(...)`}{Create a design-review data bundle.}
#'   \item{`$validate()`}{Validate the bundle sections.}
#'   \item{`$to_list()`}{Return a JSON-ready list.}
#'   \item{`$print(...)`}{Print a compact summary.}
#' }
#' @export
DesignReviewSpec <- R6::R6Class(
  classname = "DesignReviewSpec",
  public = list(
    review_id = NULL,
    agent_name = NULL,
    task = NULL,
    generated_at = NULL,
    workflow_graph = NULL,
    memory_schema = NULL,
    narrative_knowledge = NULL,
    graph_knowledge = NULL,
    proposal_states = NULL,
    feedback_schema = NULL,
    metadata = NULL,

    #' @description
    #' Create a design-review data bundle.
    initialize = function(
      review_id = .design_review_id(),
      agent_name = NA_character_,
      task = NA_character_,
      generated_at = Sys.time(),
      workflow_graph = .workflow_review_section(NULL),
      memory_schema = .memory_review_section(NULL),
      narrative_knowledge = .narrative_knowledge_review_section(NULL),
      graph_knowledge = .graph_knowledge_review_section(NULL),
      proposal_states = list(),
      feedback_schema = .design_review_feedback_schema(),
      metadata = list()
    ) {
      self$review_id <- as.character(review_id)[1]
      self$agent_name <- if (is.null(agent_name)) NA_character_ else as.character(agent_name)[1]
      self$task <- if (is.null(task)) NA_character_ else as.character(task)[1]
      self$generated_at <- as.POSIXct(generated_at)[1]
      self$workflow_graph <- workflow_graph
      self$memory_schema <- memory_schema
      self$narrative_knowledge <- narrative_knowledge
      self$graph_knowledge <- graph_knowledge
      self$proposal_states <- if (is.null(proposal_states)) list() else proposal_states
      self$feedback_schema <- feedback_schema
      self$metadata <- if (is.null(metadata)) list() else metadata
      self$validate()
    },

    #' @description
    #' Validate the design-review bundle.
    validate = function() {
      validate_design_review_spec(self)
      invisible(self)
    },

    #' @description
    #' Return a JSON-ready list.
    to_list = function() {
      self$validate()
      .design_json_ready(list(
        review_id = self$review_id,
        agent_name = self$agent_name,
        task = self$task,
        generated_at = self$generated_at,
        workflow_graph = self$workflow_graph,
        memory_schema = self$memory_schema,
        narrative_knowledge = self$narrative_knowledge,
        graph_knowledge = self$graph_knowledge,
        proposal_states = self$proposal_states,
        feedback_schema = self$feedback_schema,
        metadata = self$metadata
      ))
    },

    #' @description
    #' Print a compact summary.
    print = function(...) {
      self$validate()
      cat("<DesignReviewSpec>\n")
      cat("Review id:", self$review_id, "\n")
      cat("Agent:", if (is.na(self$agent_name)) "<unspecified>" else self$agent_name, "\n")
      cat("Workflow nodes:", length(self$workflow_graph$nodes), "\n")
      cat("Memory fields:", length(self$memory_schema$fields), "\n")
      cat("Knowledge items:", length(self$narrative_knowledge$items), "\n")
      cat("Graph nodes:", length(self$graph_knowledge$nodes), "\n")
      invisible(self)
    }
  )
)

#' Validate a design-review specification
#'
#' @param x A [`DesignReviewSpec`] object or serializable design-review list.
#'
#' @return The validated object, invisibly.
#' @export
validate_design_review_spec <- function(x) {
  if (inherits(x, "DesignReviewSpec")) {
    x <- list(
      review_id = x$review_id,
      agent_name = x$agent_name,
      task = x$task,
      generated_at = x$generated_at,
      workflow_graph = x$workflow_graph,
      memory_schema = x$memory_schema,
      narrative_knowledge = x$narrative_knowledge,
      graph_knowledge = x$graph_knowledge,
      proposal_states = x$proposal_states,
      feedback_schema = x$feedback_schema,
      metadata = x$metadata
    )
  }
  required <- c(
    "review_id", "agent_name", "task", "generated_at",
    "workflow_graph", "memory_schema", "narrative_knowledge",
    "graph_knowledge", "proposal_states", "feedback_schema", "metadata"
  )
  if (!is.list(x) || !all(required %in% names(x))) {
    stop("DesignReviewSpec must contain all required review sections.", call. = FALSE)
  }
  if (!is.character(x$review_id) || length(x$review_id) != 1L || is.na(x$review_id) || !nzchar(x$review_id)) {
    stop("DesignReviewSpec `review_id` must be a non-empty string.", call. = FALSE)
  }
  for (section in c("workflow_graph", "memory_schema", "narrative_knowledge", "graph_knowledge", "proposal_states", "feedback_schema", "metadata")) {
    if (!is.list(x[[section]])) {
      stop("DesignReviewSpec section `", section, "` must be a list.", call. = FALSE)
    }
  }
  if (!all(c("nodes", "edges") %in% names(x$workflow_graph))) {
    stop("DesignReviewSpec `workflow_graph` must contain nodes and edges.", call. = FALSE)
  }
  if (!"fields" %in% names(x$memory_schema)) {
    stop("DesignReviewSpec `memory_schema` must contain fields.", call. = FALSE)
  }
  if (!"items" %in% names(x$narrative_knowledge)) {
    stop("DesignReviewSpec `narrative_knowledge` must contain items.", call. = FALSE)
  }
  if (!all(c("nodes", "edges") %in% names(x$graph_knowledge))) {
    stop("DesignReviewSpec `graph_knowledge` must contain nodes and edges.", call. = FALSE)
  }
  if (!all(c("version", "targets", "issue_types", "severities", "required_fields", "example") %in% names(x$feedback_schema))) {
    stop("DesignReviewSpec `feedback_schema` is incomplete.", call. = FALSE)
  }
  invalid_targets <- setdiff(x$feedback_schema$targets, .design_review_feedback_targets())
  invalid_issue_types <- setdiff(x$feedback_schema$issue_types, .design_review_issue_types())
  invalid_severities <- setdiff(x$feedback_schema$severities, .design_review_severities())
  if (length(invalid_targets) || length(invalid_issue_types) || length(invalid_severities)) {
    stop("DesignReviewSpec `feedback_schema` contains unsupported values.", call. = FALSE)
  }
  validate_design_feedback(x$feedback_schema$example)
  .validate_metadata_list(x$metadata)
  invisible(x)
}

#' Build design-review data
#'
#' Packages an agent design and optional proposal states into a stable,
#' JSON-ready review bundle. This prepares the data contract for a future
#' JS/HTML review interface; it does not render a UI.
#'
#' @param x Optional [`AgentSpec`], [`IntelligentAgent`], [`Scaffolder`],
#'   `agentr_workflow_spec`, [`WorkflowProposal`], or [`KnowledgeSpec`].
#' @param workflow Optional workflow spec overriding the workflow inferred from
#'   `x`.
#' @param memory_spec Optional [`MemorySpec`] overriding memory inferred from
#'   `x`.
#' @param knowledge_spec Optional [`KnowledgeSpec`] overriding knowledge
#'   inferred from `x`.
#' @param graph_spec Optional `agentr_knowledge_graph_spec` overriding graph
#'   knowledge inferred from `knowledge_spec`.
#' @param workflow_state Optional [`WorkflowProposalState`].
#' @param knowledge_state Optional [`KnowledgeProposalState`].
#' @param memory_state Optional [`MemoryProposalState`].
#' @param graph_state Optional [`KnowledgeGraphProposalState`].
#' @param proposal_states Additional named proposal-state snapshots.
#' @param review_id Optional review bundle id.
#' @param metadata Additional metadata list.
#'
#' @return A [`DesignReviewSpec`] object.
#' @export
build_design_review_data <- function(
  x = NULL,
  workflow = NULL,
  memory_spec = NULL,
  knowledge_spec = NULL,
  graph_spec = NULL,
  workflow_state = NULL,
  knowledge_state = NULL,
  memory_state = NULL,
  graph_state = NULL,
  proposal_states = list(),
  review_id = .design_review_id(),
  metadata = list()
) {
  agent_name <- NA_character_
  task <- NA_character_

  if (inherits(x, "IntelligentAgent")) {
    x <- x$spec
  }
  if (inherits(x, "WorkflowProposal")) {
    if (is.null(workflow)) {
      workflow <- x$workflow
    }
    task <- workflow$task
    proposal_states$workflow_proposal <- x$as_list()
    x <- NULL
  }
  if (inherits(x, "agentr_workflow_spec")) {
    if (is.null(workflow)) {
      workflow <- x
    }
    task <- x$task
    x <- NULL
  }
  if (inherits(x, "KnowledgeSpec")) {
    if (is.null(knowledge_spec)) {
      knowledge_spec <- x
    }
    x <- NULL
  }
  if (inherits(x, "Scaffolder")) {
    if (is.null(workflow)) {
      workflow <- x$workflow()
    }
    if (is.null(workflow_state)) {
      workflow_state <- x$workflow_state
    }
    agent <- x$agent_spec()
    agent_name <- agent$agent_name
    task <- agent$task
    if (is.null(memory_spec)) {
      memory_spec <- agent$memory_spec
    }
    if (is.null(knowledge_spec)) {
      knowledge_spec <- agent$knowledge_spec
    }
  }
  if (inherits(x, "AgentSpec")) {
    x$validate()
    agent_name <- x$agent_name
    task <- x$task
    if (is.null(workflow)) {
      workflow <- x$workflow
    }
    if (is.null(memory_spec)) {
      memory_spec <- x$memory_spec
    }
    if (is.null(knowledge_spec)) {
      knowledge_spec <- x$knowledge_spec
    }
    metadata <- c(list(
      state_spec = .design_json_ready(x$state_spec),
      interface_spec = .design_json_ready(x$interface_spec),
      autonomy_spec = .design_json_ready(x$autonomy_spec),
      autonomy_stage = x$autonomy_stage
    ), metadata)
  } else if (!is.null(x) && !inherits(x, "Scaffolder")) {
    stop("`x` must be NULL, AgentSpec, IntelligentAgent, Scaffolder, workflow spec, WorkflowProposal, or KnowledgeSpec.", call. = FALSE)
  }

  proposal_states_out <- list(
    workflow = .proposal_state_snapshot(workflow_state),
    knowledge = .proposal_state_snapshot(knowledge_state),
    memory = .proposal_state_snapshot(memory_state),
    graph = .proposal_state_snapshot(graph_state)
  )
  if (length(proposal_states)) {
    for (name in names(proposal_states)) {
      proposal_states_out[[name]] <- .proposal_state_snapshot(proposal_states[[name]])
    }
  }

  DesignReviewSpec$new(
    review_id = review_id,
    agent_name = agent_name,
    task = task,
    workflow_graph = .workflow_review_section(workflow),
    memory_schema = .memory_review_section(memory_spec),
    narrative_knowledge = .narrative_knowledge_review_section(knowledge_spec),
    graph_knowledge = .graph_knowledge_review_section(graph_spec, knowledge_spec),
    proposal_states = proposal_states_out,
    feedback_schema = .design_review_feedback_schema(),
    metadata = metadata
  )
}

#' Save a design-review specification
#'
#' @param x A [`DesignReviewSpec`] object.
#' @param path Output `.rds` path.
#'
#' @return Invisibly returns `TRUE`.
#' @export
save_design_review_spec <- function(x, path) {
  if (!inherits(x, "DesignReviewSpec")) {
    stop("`x` must be a `DesignReviewSpec`.", call. = FALSE)
  }
  x$validate()
  saveRDS(x, path)
  invisible(TRUE)
}

#' Load a design-review specification
#'
#' @param path Input `.rds` path.
#'
#' @return A [`DesignReviewSpec`] object.
#' @export
load_design_review_spec <- function(path) {
  x <- readRDS(path)
  if (!inherits(x, "DesignReviewSpec")) {
    stop("Loaded object is not a `DesignReviewSpec`.", call. = FALSE)
  }
  x$validate()
  x
}

#' Save structured design feedback
#'
#' @param x A design-feedback item or list of items.
#' @param path Output `.rds` path.
#'
#' @return Invisibly returns `TRUE`.
#' @export
save_design_feedback <- function(x, path) {
  validate_design_feedback(x)
  saveRDS(x, path)
  invisible(TRUE)
}

#' Load structured design feedback
#'
#' @param path Input `.rds` path.
#'
#' @return A design-feedback item or list of items.
#' @export
load_design_feedback <- function(path) {
  x <- readRDS(path)
  validate_design_feedback(x)
  x
}

#' @keywords internal
.design_feedback_items <- function(feedback) {
  if (is.data.frame(feedback)) {
    feedback <- .design_df_records(feedback)
  }
  if (is.list(feedback) && "feedback" %in% names(feedback) && is.list(feedback$feedback)) {
    feedback <- feedback$feedback
  }
  if (is.list(feedback) && all(c("target", "field", "issue", "suggestion", "severity") %in% names(feedback))) {
    return(list(feedback))
  }
  feedback
}

#' Preview design feedback application
#'
#' @param x A [`Scaffolder`] or design object.
#' @param feedback Feedback item or list of items.
#' @param review_spec Optional review spec used for target-id warnings.
#'
#' @return A non-mutating preview list.
#' @export
preview_design_feedback <- function(x, feedback, review_spec = NULL) {
  items <- .design_feedback_items(feedback)
  validate_design_feedback(items, review_spec = review_spec)
  list(
    action_count = length(items),
    mutates = FALSE,
    actions = lapply(items, function(item) {
      target <- as.character(item$target)[1]
      route <- if (target %in% c("workflow_node", "review_gate", "implementation_hint")) {
        "scaffolder_node_review"
      } else if (target %in% c("workflow_edge", "subsystem_assignment", "agent_summary")) {
        "scaffolder_discussion"
      } else {
        "structured_design_discussion"
      }
      list(
        feedback_id = item$id,
        target = target,
        target_id = item$target_id,
        issue_type = item$issue_type,
        route = route,
        summary = paste(item$issue, item$suggestion, sep = " Suggestion: ")
      )
    })
  )
}

#' Apply structured design feedback
#'
#' Applies feedback through existing scaffolder review/discussion mechanisms
#' when a scaffolder is supplied. Non-workflow feedback is preserved as
#' structured design discussion metadata; it is not auto-executed.
#'
#' @param x A [`Scaffolder`] object.
#' @param feedback Feedback item or list of items.
#' @param review_spec Optional review spec used for target-id warnings.
#'
#' @return The mutated `Scaffolder` object.
#' @export
apply_design_feedback <- function(x, feedback, review_spec = NULL) {
  if (!inherits(x, "Scaffolder")) {
    stop("`x` must be a `Scaffolder`.", call. = FALSE)
  }
  items <- .design_feedback_items(feedback)
  validate_design_feedback(items, review_spec = review_spec)
  for (item in items) {
    target <- as.character(item$target)[1]
    message <- paste0(
      "[", item$target, "] ",
      item$field,
      " (", item$issue_type, ", ", item$severity, "): ",
      item$issue,
      " Suggestion: ",
      item$suggestion
    )
    if (target %in% c("workflow_node", "review_gate", "implementation_hint") &&
        !is.null(item$target_id) && !is.na(item$target_id) && nzchar(item$target_id) &&
        item$target_id %in% x$workflow$nodes$id) {
      x$review_node(
        node_id = item$target_id,
        status = "needs_revision",
        notes = message
      )
    } else {
      x$discuss_task(
        feedback = message,
        source = "human",
        node_id = if (!is.null(item$target_id) && item$target_id %in% x$workflow$nodes$id) item$target_id else NULL
      )
    }
    x$workflow$metadata$design_feedback <- c(
      x$workflow$metadata$design_feedback,
      list(.design_json_ready(item))
    )
    x$record_interaction("apply_design_feedback", .design_json_ready(item))
  }
  invisible(x)
}
