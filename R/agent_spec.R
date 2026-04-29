#' @keywords internal
.is_scalar_character_or_null <- function(x) {
  is.null(x) || (is.character(x) && length(x) == 1L)
}

#' @keywords internal
.is_named_character <- function(x) {
  is.character(x) && !is.null(names(x)) && all(nzchar(names(x)))
}

#' @keywords internal
.normalize_character <- function(x) {
  if (is.null(x)) {
    return(character())
  }
  as.character(unlist(x, use.names = FALSE))
}

#' @keywords internal
.normalize_named_character <- function(x) {
  if (is.null(x)) {
    return(character())
  }
  out <- as.character(unlist(x, use.names = TRUE))
  if (is.null(names(out))) {
    stop("Expected a named character vector or named list.", call. = FALSE)
  }
  out
}

#' @keywords internal
.validate_metadata_list <- function(x, label = "metadata") {
  if (!is.list(x)) {
    stop("`", label, "` must be a list.", call. = FALSE)
  }
  invisible(x)
}

#' @keywords internal
.subsystem_names <- function() {
  c("rwm", "pg", "ae", "iac", "la")
}

#' Normalize subsystem keys
#'
#' Accepts canonical subsystem keys and legacy mixed-case variants, then returns
#' the canonical keys used throughout `agentr`.
#'
#' @param x Character vector of subsystem keys.
#'
#' @return Character vector containing canonical subsystem keys.
#' @export
normalize_subsystem_key <- function(x) {
  if (is.null(x)) {
    return(character())
  }
  x <- tolower(as.character(unlist(x, use.names = FALSE)))
  x <- trimws(x)
  aliases <- c(
    rwm = "rwm",
    reasoning_world_model = "rwm",
    reasoningandworldmodel = "rwm",
    pg = "pg",
    perception_grounding = "pg",
    perceptionandgrounding = "pg",
    ae = "ae",
    action_execution = "ae",
    actionandexecution = "ae",
    iac = "iac",
    inter_agent_communication = "iac",
    interagentcommunication = "iac",
    la = "la",
    learning_adaptation = "la",
    learningandadaptation = "la"
  )
  mapped <- unname(aliases[x])
  mapped[is.na(mapped)] <- x[is.na(mapped)]
  invalid <- setdiff(unique(mapped), .subsystem_names())
  if (length(invalid)) {
    stop(
      "Unsupported subsystem labels: ",
      paste(invalid, collapse = ", "),
      call. = FALSE
    )
  }
  unique(mapped)
}

#' @keywords internal
.subsystem_meanings <- function() {
  list(
    schema = "agentr_five_module_v1",
    meanings = list(
      rwm = "Reasoning & World Model",
      pg = "Perception & Grounding",
      ae = "Action Execution",
      la = "Learning & Adaptation",
      iac = "Inter-Agent Communication"
    )
  )
}

#' @keywords internal
.validate_node_subsystems <- function(labels, nodes = NULL) {
  if (is.null(labels)) {
    return(list())
  }
  if (!is.list(labels)) {
    stop("Node subsystem labels must be a named list.", call. = FALSE)
  }
  if (!length(labels)) {
    return(list())
  }
  if (is.null(names(labels)) || any(!nzchar(names(labels)))) {
    stop("Node subsystem labels must be named by workflow node id.", call. = FALSE)
  }
  if (!is.null(nodes)) {
    unknown <- setdiff(names(labels), nodes$id)
    if (length(unknown)) {
      stop(
        "Node subsystem labels reference unknown workflow nodes: ",
        paste(unknown, collapse = ", "),
        call. = FALSE
      )
    }
  }

  normalized <- lapply(labels, function(value) {
    value <- normalize_subsystem_key(.normalize_character(value))
    if (!length(value)) {
      return(character())
    }
    unique(value)
  })

  normalized
}

#' @keywords internal
.coerce_subsystem_config <- function(x, class_name, field_name) {
  if (is.null(x)) {
    return(NULL)
  }
  if (inherits(x, class_name)) {
    x$validate()
    return(x)
  }
  if (!is.list(x)) {
    stop("`", field_name, "` must be `NULL`, a list, or a `", class_name, "` object.", call. = FALSE)
  }
  generator <- get(class_name, inherits = TRUE)
  config <- do.call(generator$new, x)
  config$validate()
  config
}

#' @keywords internal
.validate_scalar_logical <- function(x, label) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    stop("`", label, "` must be a single non-missing logical value.", call. = FALSE)
  }
  invisible(x)
}

#' @keywords internal
.validate_non_empty_character <- function(x, label) {
  if (!is.character(x) || any(is.na(x)) || any(!nzchar(x))) {
    stop("`", label, "` must contain non-empty strings.", call. = FALSE)
  }
  invisible(x)
}

#' @keywords internal
.validate_named_list_fields <- function(x, label) {
  .validate_metadata_list(x, label = label)
  if (length(x) && (is.null(names(x)) || any(!nzchar(names(x))))) {
    stop("`", label, "` entries must be named.", call. = FALSE)
  }
  invisible(x)
}

#' @keywords internal
.coerce_workflow_or_null <- function(workflow) {
  if (is.null(workflow)) {
    return(NULL)
  }
  validate_workflow_spec(workflow)
}

#' @keywords internal
.coerce_knowledge_spec_or_null <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  if (inherits(x, "KnowledgeSpec")) {
    x$validate()
    return(x)
  }
  stop("`knowledge_spec` must be `NULL` or a `KnowledgeSpec`.", call. = FALSE)
}

#' @keywords internal
.normalize_autonomy_stage <- function(x) {
  match.arg(
    x,
    choices = c(
      "manual_scaffold",
      "scripted_tool",
      "human_in_loop",
      "llm_assisted",
      "agent_owned",
      "validated_autonomous"
    )
  )
}

#' CognitiveConfig
#'
#' Lightweight configuration for the cognitive layer inside `RWM`.
#'
#' @field enabled Whether the cognitive layer is enabled.
#' @field persistence Persistence mode for cognitive state.
#' @field memory_types Character vector of memory categories to keep.
#' @field summary Optional one-line summary.
#' @field metadata Free-form metadata list.
#' @param enabled Whether the cognitive layer is enabled.
#' @param persistence Persistence mode for cognitive state.
#' @param memory_types Character vector of memory categories to keep.
#' @param summary Optional one-line summary.
#' @param metadata Free-form metadata list.
#' @param ... Unused print arguments.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(enabled = TRUE, persistence = "session", memory_types = character(), summary = NULL, metadata = list())`}{Create a cognitive-layer config.}
#'   \item{`$validate()`}{Validate the config.}
#'   \item{`$as_list()`}{Return a serializable representation.}
#' }
#' @export
CognitiveConfig <- R6::R6Class(
  classname = "CognitiveConfig",
  public = list(
    enabled = NULL,
    persistence = NULL,
    memory_types = NULL,
    summary = NULL,
    metadata = NULL,

    #' @description
    #' Create a cognitive-layer config.
    initialize = function(
      enabled = TRUE,
      persistence = "session",
      memory_types = character(),
      summary = NULL,
      metadata = list()
    ) {
      self$enabled <- isTRUE(enabled)
      self$persistence <- as.character(persistence)[1]
      self$memory_types <- .normalize_character(memory_types)
      self$summary <- if (is.null(summary)) NA_character_ else as.character(summary)[1]
      self$metadata <- metadata
      self$validate()
    },

    #' @description
    #' Validate the config.
    validate = function() {
      .validate_scalar_logical(self$enabled, "enabled")
      allowed <- c("none", "session", "persistent")
      if (!(self$persistence %in% allowed)) {
        stop("Cognitive persistence must be one of: none, session, persistent.", call. = FALSE)
      }
      if (!is.character(self$memory_types) || any(is.na(self$memory_types))) {
        stop("`memory_types` must be a character vector without missing values.", call. = FALSE)
      }
      .validate_metadata_list(self$metadata)
      invisible(self)
    },

    #' @description
    #' Return a serializable representation.
    as_list = function() {
      self$validate()
      list(
        enabled = self$enabled,
        persistence = self$persistence,
        memory_types = self$memory_types,
        summary = self$summary,
        metadata = self$metadata
      )
    },

    #' @description
    #' Print a compact config summary.
    print = function(...) {
      self$validate()
      cat("<CognitiveConfig>\n")
      cat("Enabled:", self$enabled, "\n")
      cat("Persistence:", self$persistence, "\n")
      cat("Memory types:", if (length(self$memory_types)) paste(self$memory_types, collapse = ", ") else "<none>", "\n")
      invisible(self)
    }
  )
)

#' AffectiveConfig
#'
#' Lightweight configuration for the affective layer inside `RWM`.
#'
#' @field enabled Whether the affective layer is enabled.
#' @field style Affective modeling style.
#' @field persistence Persistence mode for affective state.
#' @field summary Optional one-line summary.
#' @field metadata Free-form metadata list.
#' @param enabled Whether the affective layer is enabled.
#' @param style Affective modeling style.
#' @param persistence Persistence mode for affective state.
#' @param summary Optional one-line summary.
#' @param metadata Free-form metadata list.
#' @param ... Unused print arguments.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(enabled = TRUE, style = "lightweight", persistence = "session", summary = NULL, metadata = list())`}{Create an affective-layer config.}
#'   \item{`$validate()`}{Validate the config.}
#'   \item{`$as_list()`}{Return a serializable representation.}
#' }
#' @export
AffectiveConfig <- R6::R6Class(
  classname = "AffectiveConfig",
  public = list(
    enabled = NULL,
    style = NULL,
    persistence = NULL,
    summary = NULL,
    metadata = NULL,

    #' @description
    #' Create an affective-layer config.
    initialize = function(
      enabled = TRUE,
      style = "lightweight",
      persistence = "session",
      summary = NULL,
      metadata = list()
    ) {
      self$enabled <- isTRUE(enabled)
      self$style <- as.character(style)[1]
      self$persistence <- as.character(persistence)[1]
      self$summary <- if (is.null(summary)) NA_character_ else as.character(summary)[1]
      self$metadata <- metadata
      self$validate()
    },

    #' @description
    #' Validate the config.
    validate = function() {
      .validate_scalar_logical(self$enabled, "enabled")
      if (!self$style %in% c("none", "lightweight", "expressive")) {
        stop("Affective style must be one of: none, lightweight, expressive.", call. = FALSE)
      }
      if (!self$persistence %in% c("none", "session", "persistent")) {
        stop("Affective persistence must be one of: none, session, persistent.", call. = FALSE)
      }
      .validate_metadata_list(self$metadata)
      invisible(self)
    },

    #' @description
    #' Return a serializable representation.
    as_list = function() {
      self$validate()
      list(
        enabled = self$enabled,
        style = self$style,
        persistence = self$persistence,
        summary = self$summary,
        metadata = self$metadata
      )
    },

    #' @description
    #' Print a compact config summary.
    print = function(...) {
      self$validate()
      cat("<AffectiveConfig>\n")
      cat("Enabled:", self$enabled, "\n")
      cat("Style:", self$style, "\n")
      cat("Persistence:", self$persistence, "\n")
      invisible(self)
    }
  )
)

#' RWMConfig
#'
#' Configuration for the Reasoning & World Model subsystem.
#'
#' @field cognitive A `CognitiveConfig` object or `NULL`.
#' @field affective An `AffectiveConfig` object or `NULL`.
#' @field persistence Persistence mode for the overall subsystem.
#' @field summary Optional one-line summary.
#' @field metadata Free-form metadata list.
#' @param cognitive A `CognitiveConfig` object or list payload.
#' @param affective An `AffectiveConfig` object or list payload.
#' @param persistence Persistence mode for the overall subsystem.
#' @param summary Optional one-line summary.
#' @param metadata Free-form metadata list.
#' @param ... Unused print arguments.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(cognitive = CognitiveConfig$new(), affective = NULL, persistence = "session", summary = NULL, metadata = list())`}{Create a Reasoning & World Model config.}
#'   \item{`$validate()`}{Validate the config.}
#'   \item{`$selected_layers()`}{Return the active inner layers.}
#'   \item{`$as_list()`}{Return a serializable representation.}
#' }
#' @export
RWMConfig <- R6::R6Class(
  classname = "RWMConfig",
  public = list(
    cognitive = NULL,
    affective = NULL,
    persistence = NULL,
    summary = NULL,
    metadata = NULL,

    #' @description
    #' Create an `RWM` config.
    initialize = function(
      cognitive = CognitiveConfig$new(),
      affective = NULL,
      persistence = "session",
      summary = NULL,
      metadata = list()
    ) {
      self$cognitive <- if (is.null(cognitive)) NULL else .coerce_subsystem_config(cognitive, "CognitiveConfig", "cognitive")
      self$affective <- if (is.null(affective)) NULL else .coerce_subsystem_config(affective, "AffectiveConfig", "affective")
      self$persistence <- as.character(persistence)[1]
      self$summary <- if (is.null(summary)) NA_character_ else as.character(summary)[1]
      self$metadata <- metadata
      self$validate()
    },

    #' @description
    #' Validate the config.
    validate = function() {
      if (is.null(self$cognitive) && is.null(self$affective)) {
        stop("`RWMConfig` requires at least one of `cognitive` or `affective`.", call. = FALSE)
      }
      if (!self$persistence %in% c("none", "session", "persistent")) {
        stop("RWM persistence must be one of: none, session, persistent.", call. = FALSE)
      }
      if (!length(self$selected_layers())) {
        stop("`RWMConfig` must enable at least one inner layer.", call. = FALSE)
      }
      .validate_metadata_list(self$metadata)
      invisible(self)
    },

    #' @description
    #' Return the active inner layers.
    selected_layers = function() {
      layers <- character()
      if (!is.null(self$cognitive) && isTRUE(self$cognitive$enabled)) {
        layers <- c(layers, "cognitive")
      }
      if (!is.null(self$affective) && isTRUE(self$affective$enabled)) {
        layers <- c(layers, "affective")
      }
      layers
    },

    #' @description
    #' Return a serializable representation.
    as_list = function() {
      self$validate()
      list(
        cognitive = if (is.null(self$cognitive)) NULL else self$cognitive$as_list(),
        affective = if (is.null(self$affective)) NULL else self$affective$as_list(),
        persistence = self$persistence,
        summary = self$summary,
        metadata = self$metadata
      )
    },

    #' @description
    #' Print a compact config summary.
    print = function(...) {
      self$validate()
      cat("<RWMConfig>\n")
      cat("Meaning: Reasoning & World Model\n")
      cat("Layers:", paste(self$selected_layers(), collapse = ", "), "\n")
      cat("Persistence:", self$persistence, "\n")
      invisible(self)
    }
  )
)

#' PGConfig
#'
#' Configuration for the Perception & Grounding subsystem.
#'
#' @field enabled Whether the subsystem is enabled.
#' @field planning_mode Legacy field name retained for compatibility; interpreted as a grounding/perception mode label.
#' @field decomposition_style Legacy field name retained for compatibility; interpreted as a representation-structuring style.
#' @field metadata Free-form metadata list.
#' @param enabled Whether the subsystem is enabled.
#' @param planning_mode Planning mode label.
#' @param decomposition_style Workflow decomposition style.
#' @param metadata Free-form metadata list.
#' @param ... Unused print arguments.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(enabled = TRUE, planning_mode = "task_decomposition", decomposition_style = "dag", metadata = list())`}{Create a Perception & Grounding config. Legacy field names are preserved for compatibility.}
#'   \item{`$validate()`}{Validate the config.}
#'   \item{`$as_list()`}{Return a serializable representation.}
#' }
#' @export
PGConfig <- R6::R6Class(
  classname = "PGConfig",
  public = list(
    enabled = NULL,
    planning_mode = NULL,
    decomposition_style = NULL,
    metadata = NULL,

    #' @description
    #' Create a Perception & Grounding config.
    initialize = function(
      enabled = TRUE,
      planning_mode = "task_decomposition",
      decomposition_style = "dag",
      metadata = list()
    ) {
      self$enabled <- isTRUE(enabled)
      self$planning_mode <- as.character(planning_mode)[1]
      self$decomposition_style <- as.character(decomposition_style)[1]
      self$metadata <- metadata
      self$validate()
    },

    #' @description
    #' Validate the config.
    validate = function() {
      .validate_scalar_logical(self$enabled, "enabled")
      .validate_metadata_list(self$metadata)
      invisible(self)
    },

    #' @description
    #' Return a serializable representation.
    as_list = function() {
      self$validate()
      list(
        enabled = self$enabled,
        planning_mode = self$planning_mode,
        decomposition_style = self$decomposition_style,
        metadata = self$metadata
      )
    },

    #' @description
    #' Print a compact config summary.
    print = function(...) {
      self$validate()
      cat("<PGConfig>\n")
      cat("Meaning: Perception & Grounding\n")
      cat("Enabled:", self$enabled, "\n")
      cat("Grounding mode:", self$planning_mode, "\n")
      cat("Representation style:", self$decomposition_style, "\n")
      invisible(self)
    }
  )
)

#' AEConfig
#'
#' Configuration for the action-execution subsystem.
#'
#' @field enabled Whether the subsystem is enabled.
#' @field execution_mode Execution-mode label.
#' @field tool_budget Optional tool budget label.
#' @field metadata Free-form metadata list.
#' @param enabled Whether the subsystem is enabled.
#' @param execution_mode Execution-mode label.
#' @param tool_budget Optional tool budget label.
#' @param metadata Free-form metadata list.
#' @param ... Unused print arguments.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(enabled = TRUE, execution_mode = "guided", tool_budget = "standard", metadata = list())`}{Create an action-execution config.}
#'   \item{`$validate()`}{Validate the config.}
#'   \item{`$as_list()`}{Return a serializable representation.}
#' }
#' @export
AEConfig <- R6::R6Class(
  classname = "AEConfig",
  public = list(
    enabled = NULL,
    execution_mode = NULL,
    tool_budget = NULL,
    metadata = NULL,

    #' @description
    #' Create an action-execution config.
    initialize = function(
      enabled = TRUE,
      execution_mode = "guided",
      tool_budget = "standard",
      metadata = list()
    ) {
      self$enabled <- isTRUE(enabled)
      self$execution_mode <- as.character(execution_mode)[1]
      self$tool_budget <- as.character(tool_budget)[1]
      self$metadata <- metadata
      self$validate()
    },

    #' @description
    #' Validate the config.
    validate = function() {
      .validate_scalar_logical(self$enabled, "enabled")
      .validate_metadata_list(self$metadata)
      invisible(self)
    },

    #' @description
    #' Return a serializable representation.
    as_list = function() {
      self$validate()
      list(
        enabled = self$enabled,
        execution_mode = self$execution_mode,
        tool_budget = self$tool_budget,
        metadata = self$metadata
      )
    },

    #' @description
    #' Print a compact config summary.
    print = function(...) {
      self$validate()
      cat("<AEConfig>\n")
      cat("Enabled:", self$enabled, "\n")
      cat("Execution mode:", self$execution_mode, "\n")
      cat("Tool budget:", self$tool_budget, "\n")
      invisible(self)
    }
  )
)

#' IACConfig
#'
#' Configuration for Inter-Agent Communication.
#'
#' @field enabled Whether the subsystem is enabled.
#' @field channels Character vector of communication channels.
#' @field structured_io Whether strongly structured I/O is required.
#' @field metadata Free-form metadata list.
#' @param enabled Whether the subsystem is enabled.
#' @param channels Character vector of communication channels.
#' @param structured_io Whether strongly structured I/O is required.
#' @param metadata Free-form metadata list.
#' @param ... Unused print arguments.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(enabled = TRUE, channels = character(), structured_io = TRUE, metadata = list())`}{Create an Inter-Agent Communication config.}
#'   \item{`$validate()`}{Validate the config.}
#'   \item{`$as_list()`}{Return a serializable representation.}
#' }
#' @export
IACConfig <- R6::R6Class(
  classname = "IACConfig",
  public = list(
    enabled = NULL,
    channels = NULL,
    structured_io = NULL,
    metadata = NULL,

    #' @description
    #' Create an Inter-Agent Communication config.
    initialize = function(
      enabled = TRUE,
      channels = character(),
      structured_io = TRUE,
      metadata = list()
    ) {
      self$enabled <- isTRUE(enabled)
      self$channels <- .normalize_character(channels)
      self$structured_io <- isTRUE(structured_io)
      self$metadata <- metadata
      self$validate()
    },

    #' @description
    #' Validate the config.
    validate = function() {
      .validate_scalar_logical(self$enabled, "enabled")
      if (!is.character(self$channels) || any(is.na(self$channels)) || any(!nzchar(self$channels))) {
        stop("`channels` must contain non-empty strings.", call. = FALSE)
      }
      .validate_scalar_logical(self$structured_io, "structured_io")
      .validate_metadata_list(self$metadata)
      invisible(self)
    },

    #' @description
    #' Return a serializable representation.
    as_list = function() {
      self$validate()
      list(
        enabled = self$enabled,
        channels = self$channels,
        structured_io = self$structured_io,
        metadata = self$metadata
      )
    },

    #' @description
    #' Print a compact config summary.
    print = function(...) {
      self$validate()
      cat("<IACConfig>\n")
      cat("Meaning: Inter-Agent Communication\n")
      cat("Enabled:", self$enabled, "\n")
      cat("Channels:", if (length(self$channels)) paste(self$channels, collapse = ", ") else "<none>", "\n")
      cat("Structured IO:", self$structured_io, "\n")
      invisible(self)
    }
  )
)

#' LAConfig
#'
#' Configuration for Learning & Adaptation.
#'
#' @field enabled Whether the subsystem is enabled.
#' @field learning_mode Learning-mode label.
#' @field feedback_sources Character vector of feedback sources.
#' @field persistence Persistence mode for learned artifacts.
#' @field metadata Free-form metadata list.
#' @param enabled Whether the subsystem is enabled.
#' @param learning_mode Learning-mode label.
#' @param feedback_sources Character vector of feedback sources.
#' @param persistence Persistence mode for learned artifacts.
#' @param metadata Free-form metadata list.
#' @param ... Unused print arguments.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(enabled = TRUE, learning_mode = "feedback_driven", feedback_sources = character(), persistence = "session", metadata = list())`}{Create a learning and adaptation config.}
#'   \item{`$validate()`}{Validate the config.}
#'   \item{`$as_list()`}{Return a serializable representation.}
#' }
#' @export
LAConfig <- R6::R6Class(
  classname = "LAConfig",
  public = list(
    enabled = NULL,
    learning_mode = NULL,
    feedback_sources = NULL,
    persistence = NULL,
    metadata = NULL,

    #' @description
    #' Create a learning and adaptation config.
    initialize = function(
      enabled = TRUE,
      learning_mode = "feedback_driven",
      feedback_sources = character(),
      persistence = "session",
      metadata = list()
    ) {
      self$enabled <- isTRUE(enabled)
      self$learning_mode <- as.character(learning_mode)[1]
      self$feedback_sources <- .normalize_character(feedback_sources)
      self$persistence <- as.character(persistence)[1]
      self$metadata <- metadata
      self$validate()
    },

    #' @description
    #' Validate the config.
    validate = function() {
      .validate_scalar_logical(self$enabled, "enabled")
      if (!self$persistence %in% c("none", "session", "persistent")) {
        stop("LA persistence must be one of: none, session, persistent.", call. = FALSE)
      }
      if (!is.character(self$feedback_sources) || any(is.na(self$feedback_sources))) {
        stop("`feedback_sources` must be a character vector without missing values.", call. = FALSE)
      }
      .validate_metadata_list(self$metadata)
      invisible(self)
    },

    #' @description
    #' Return a serializable representation.
    as_list = function() {
      self$validate()
      list(
        enabled = self$enabled,
        learning_mode = self$learning_mode,
        feedback_sources = self$feedback_sources,
        persistence = self$persistence,
        metadata = self$metadata
      )
    },

    #' @description
    #' Print a compact config summary.
    print = function(...) {
      self$validate()
      cat("<LAConfig>\n")
      cat("Enabled:", self$enabled, "\n")
      cat("Learning mode:", self$learning_mode, "\n")
      cat("Persistence:", self$persistence, "\n")
      invisible(self)
    }
  )
)

#' SubsystemSpec
#'
#' Sparse diagnostic inventory of the selected agent subsystems.
#'
#' @field rwm An `RWMConfig` object or `NULL`.
#' @field pg A `PGConfig` object or `NULL`.
#' @field ae An `AEConfig` object or `NULL`.
#' @field iac An `IACConfig` object or `NULL`.
#' @field la A `LAConfig` object or `NULL`.
#' @field metadata Free-form metadata list.
#' @param rwm An `RWMConfig` object or list payload.
#' @param pg A `PGConfig` object or list payload.
#' @param ae An `AEConfig` object or list payload.
#' @param iac An `IACConfig` object or list payload.
#' @param la A `LAConfig` object or list payload.
#' @param metadata Free-form metadata list.
#' @param ... Unused print arguments.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(rwm = NULL, pg = NULL, ae = NULL, iac = NULL, la = NULL, metadata = list())`}{Create a sparse subsystem diagnostic inventory.}
#'   \item{`$validate()`}{Validate the subsystem selection.}
#'   \item{`$selected_subsystems()`}{Return the selected subsystem names.}
#'   \item{`$persistence_requirements()`}{Return persistence requirements for selected subsystems.}
#'   \item{`$communication_requirements()`}{Return communication requirements for selected subsystems.}
#'   \item{`$summary()`}{Return a one-row summary table.}
#'   \item{`$as_list()`}{Return a serializable representation.}
#' }
#' @export
SubsystemSpec <- R6::R6Class(
  classname = "SubsystemSpec",
  public = list(
    rwm = NULL,
    pg = NULL,
    ae = NULL,
    iac = NULL,
    la = NULL,
    metadata = NULL,

    #' @description
    #' Create a sparse subsystem inventory.
    initialize = function(
      rwm = NULL,
      pg = NULL,
      ae = NULL,
      iac = NULL,
      la = NULL,
      metadata = list()
    ) {
      self$rwm <- if (is.null(rwm)) NULL else .coerce_subsystem_config(rwm, "RWMConfig", "rwm")
      self$pg <- if (is.null(pg)) NULL else .coerce_subsystem_config(pg, "PGConfig", "pg")
      self$ae <- if (is.null(ae)) NULL else .coerce_subsystem_config(ae, "AEConfig", "ae")
      self$iac <- if (is.null(iac)) NULL else .coerce_subsystem_config(iac, "IACConfig", "iac")
      self$la <- if (is.null(la)) NULL else .coerce_subsystem_config(la, "LAConfig", "la")
      self$metadata <- utils::modifyList(.subsystem_meanings(), metadata)
      self$validate()
    },

    #' @description
    #' Validate the subsystem selection.
    validate = function() {
      .validate_metadata_list(self$metadata)
      self$selected_subsystems()
      if (!is.null(self$iac)) {
        self$iac$validate()
      }
      invisible(self)
    },

    #' @description
    #' Return the selected subsystem names.
    selected_subsystems = function() {
      present <- c(
        rwm = !is.null(self$rwm),
        pg = !is.null(self$pg),
        ae = !is.null(self$ae),
        iac = !is.null(self$iac),
        la = !is.null(self$la)
      )
      names(present)[present]
    },

    #' @description
    #' Return persistence requirements for selected subsystems.
    persistence_requirements = function() {
      out <- character()
      if (!is.null(self$rwm) && !identical(self$rwm$persistence, "none")) {
        out[["rwm"]] <- self$rwm$persistence
      }
      if (!is.null(self$la) && !identical(self$la$persistence, "none")) {
        out[["la"]] <- self$la$persistence
      }
      out
    },

    #' @description
    #' Return communication requirements for selected subsystems.
    communication_requirements = function() {
      if (is.null(self$iac)) {
        return(character())
      }
      self$iac$channels
    },

    #' @description
    #' Return a one-row summary table.
    summary = function() {
      data.frame(
        selected = paste(self$selected_subsystems(), collapse = ", "),
        persistence = paste(unname(self$persistence_requirements()), collapse = ", "),
        communication = paste(self$communication_requirements(), collapse = ", "),
        stringsAsFactors = FALSE
      )
    },

    #' @description
    #' Return a serializable representation.
    as_list = function() {
      self$validate()
      list(
        rwm = if (is.null(self$rwm)) NULL else self$rwm$as_list(),
        pg = if (is.null(self$pg)) NULL else self$pg$as_list(),
        ae = if (is.null(self$ae)) NULL else self$ae$as_list(),
        iac = if (is.null(self$iac)) NULL else self$iac$as_list(),
        la = if (is.null(self$la)) NULL else self$la$as_list(),
        metadata = self$metadata
      )
    },

    #' @description
    #' Print a compact subsystem summary.
    print = function(...) {
      self$validate()
      selected <- self$selected_subsystems()
      cat("<SubsystemSpec>\n")
      cat("Role: diagnostic design layer\n")
      cat("Selected:", if (length(selected)) paste(selected, collapse = ", ") else "<none>", "\n")
      comms <- self$communication_requirements()
      if (length(comms)) {
        cat("Communication:", paste(comms, collapse = ", "), "\n")
      }
      persistence <- self$persistence_requirements()
      if (length(persistence)) {
        cat("Persistence:", paste(names(persistence), persistence, sep = "=", collapse = ", "), "\n")
      }
      invisible(self)
    }
  )
)

#' AgentSpec
#'
#' Public agent-design artifact combining subsystem selection and workflow.
#'
#' @field task Source task description.
#' @field agent_name Human-readable agent name.
#' @field summary One-line agent summary.
#' @field subsystems A `SubsystemSpec` object.
#' @field workflow Embedded workflow specification or `NULL`.
#' @field knowledge_spec Embedded `KnowledgeSpec` or `NULL`.
#' @field state_requirements Free-form list of state requirements.
#' @field state_spec Optional structured state-spec list.
#' @field interfaces Free-form list of interfaces.
#' @field interface_spec Optional structured interface-spec list.
#' @field autonomy_spec Optional structured autonomy-spec list.
#' @field autonomy_stage Optional autonomy-stage label.
#' @field implementation_targets Free-form list of implementation targets.
#' @field metadata Free-form metadata list.
#' @param task Source task description.
#' @param agent_name Human-readable agent name.
#' @param summary One-line agent summary.
#' @param subsystems A `SubsystemSpec` object or list payload.
#' @param workflow Embedded workflow specification or `NULL`.
#' @param knowledge_spec Embedded `KnowledgeSpec` or `NULL`.
#' @param state_requirements Free-form list of state requirements.
#' @param state_spec Optional structured state-spec list.
#' @param interfaces Free-form list of interfaces.
#' @param interface_spec Optional structured interface-spec list.
#' @param autonomy_spec Optional structured autonomy-spec list.
#' @param autonomy_stage Optional autonomy-stage label.
#' @param implementation_targets Free-form list of implementation targets.
#' @param metadata Free-form metadata list.
#' @param file_path Output path used by `$save()`.
#' @param ... Unused print arguments.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(task, agent_name = "agentr-agent", summary = NULL, subsystems = SubsystemSpec$new(), workflow = NULL, knowledge_spec = NULL, state_requirements = list(), state_spec = NULL, interfaces = list(), interface_spec = NULL, autonomy_spec = NULL, autonomy_stage = NULL, implementation_targets = list(), metadata = list())`}{Create an agent-design artifact.}
#'   \item{`$validate()`}{Validate the agent design.}
#'   \item{`$selected_subsystems()`}{Return the selected subsystem names.}
#'   \item{`$workflow_spec()`}{Return the embedded workflow specification.}
#'   \item{`$design_summary()`}{Return a one-row summary table.}
#'   \item{`$as_list()`}{Return a serializable representation.}
#'   \item{`$save(file_path)`}{Save the object with `save_agent()`.}
#' }
#' @export
AgentSpec <- R6::R6Class(
  classname = "AgentSpec",
  public = list(
    task = NULL,
    agent_name = NULL,
    summary = NULL,
    subsystems = NULL,
    workflow = NULL,
    knowledge_spec = NULL,
    state_requirements = NULL,
    state_spec = NULL,
    interfaces = NULL,
    interface_spec = NULL,
    autonomy_spec = NULL,
    autonomy_stage = NULL,
    implementation_targets = NULL,
    metadata = NULL,

    #' @description
    #' Create an agent-design artifact.
    initialize = function(
      task,
      agent_name = "agentr-agent",
      summary = NULL,
      subsystems = SubsystemSpec$new(),
      workflow = NULL,
      knowledge_spec = NULL,
      state_requirements = list(),
      state_spec = NULL,
      interfaces = list(),
      interface_spec = NULL,
      autonomy_spec = NULL,
      autonomy_stage = NULL,
      implementation_targets = list(),
      metadata = list()
    ) {
      self$task <- as.character(task)[1]
      self$agent_name <- as.character(agent_name)[1]
      self$summary <- if (is.null(summary)) self$task else as.character(summary)[1]
      self$subsystems <- if (inherits(subsystems, "SubsystemSpec")) subsystems else do.call(SubsystemSpec$new, subsystems)
      self$workflow <- .coerce_workflow_or_null(workflow)
      self$knowledge_spec <- .coerce_knowledge_spec_or_null(knowledge_spec)
      self$state_requirements <- state_requirements
      self$state_spec <- if (is.null(state_spec)) list() else state_spec
      self$interfaces <- interfaces
      self$interface_spec <- if (is.null(interface_spec)) list() else interface_spec
      self$autonomy_spec <- if (is.null(autonomy_spec)) list() else autonomy_spec
      self$autonomy_stage <- if (is.null(autonomy_stage)) NA_character_ else as.character(autonomy_stage)[1]
      self$implementation_targets <- implementation_targets
      self$metadata <- metadata
      self$validate()
    },

    #' @description
    #' Validate the agent design.
    validate = function() {
      if (!is.character(self$task) || length(self$task) != 1L || !nzchar(self$task)) {
        stop("`task` must be a non-empty string.", call. = FALSE)
      }
      if (!is.character(self$agent_name) || length(self$agent_name) != 1L || !nzchar(self$agent_name)) {
        stop("`agent_name` must be a non-empty string.", call. = FALSE)
      }
      if (!inherits(self$subsystems, "SubsystemSpec")) {
        stop("`subsystems` must be a `SubsystemSpec`.", call. = FALSE)
      }
      self$subsystems$validate()
      selected <- self$selected_subsystems()
      if (!is.null(self$knowledge_spec)) {
        self$knowledge_spec$validate()
      }
      if (!is.null(self$workflow)) {
        validate_workflow_spec(self$workflow, knowledge_spec = self$knowledge_spec)
        node_subsystems <- .validate_node_subsystems(self$metadata$node_subsystems, nodes = self$workflow$nodes)
        if (length(node_subsystems)) {
          labeled <- unique(unlist(node_subsystems, use.names = FALSE))
          inconsistent <- setdiff(labeled, selected)
          if (length(inconsistent)) {
            stop(
              "Node subsystem labels require unselected subsystems: ",
              paste(inconsistent, collapse = ", "),
              call. = FALSE
            )
          }
        }
      } else if (!is.null(self$metadata$node_subsystems)) {
        stop("`metadata$node_subsystems` requires a non-NULL workflow.", call. = FALSE)
      }
      .validate_named_list_fields(self$interfaces, "interfaces")
      .validate_named_list_fields(self$implementation_targets, "implementation_targets")
      .validate_metadata_list(self$state_spec, "state_spec")
      .validate_metadata_list(self$interface_spec, "interface_spec")
      .validate_metadata_list(self$autonomy_spec, "autonomy_spec")
      .validate_metadata_list(self$state_requirements, "state_requirements")
      if (!is.na(self$autonomy_stage)) {
        self$autonomy_stage <- .normalize_autonomy_stage(self$autonomy_stage)
      }
      .validate_metadata_list(self$metadata)
      invisible(self)
    },

    #' @description
    #' Return the selected subsystem names.
    selected_subsystems = function() {
      self$subsystems$selected_subsystems()
    },

    #' @description
    #' Return the embedded workflow specification.
    workflow_spec = function() {
      self$validate()
      self$workflow
    },

    #' @description
    #' Return a one-row summary table.
    design_summary = function() {
      self$validate()
      data.frame(
        task = self$task,
        agent_name = self$agent_name,
        selected_subsystems = paste(self$selected_subsystems(), collapse = ", "),
        workflow_nodes = if (is.null(self$workflow)) 0L else nrow(self$workflow$nodes),
        knowledge_items = if (is.null(self$knowledge_spec)) 0L else length(self$knowledge_spec$items),
        stringsAsFactors = FALSE
      )
    },

    #' @description
    #' Return a serializable representation.
    as_list = function() {
      self$validate()
      list(
        task = self$task,
        agent_name = self$agent_name,
        summary = self$summary,
        subsystems = self$subsystems$as_list(),
        workflow = self$workflow,
        knowledge_spec = if (is.null(self$knowledge_spec)) NULL else self$knowledge_spec$to_list(),
        state_requirements = self$state_requirements,
        state_spec = self$state_spec,
        interfaces = self$interfaces,
        interface_spec = self$interface_spec,
        autonomy_spec = self$autonomy_spec,
        autonomy_stage = self$autonomy_stage,
        implementation_targets = self$implementation_targets,
        metadata = self$metadata
      )
    },

    #' @description
    #' Save the object with `save_agent()`.
    save = function(file_path) {
      save_agent_spec(self, file_path)
      invisible(TRUE)
    },

    #' @description
    #' Print a compact agent-design summary.
    print = function(...) {
      self$validate()
      cat("<AgentSpec>\n")
      cat("Name:", self$agent_name, "\n")
      cat("Task:", self$task, "\n")
      selected <- self$selected_subsystems()
      cat("Subsystems:", if (length(selected)) paste(selected, collapse = ", ") else "<none>", "\n")
      cat("Workflow nodes:", if (is.null(self$workflow)) 0L else nrow(self$workflow$nodes), "\n")
      cat("Knowledge items:", if (is.null(self$knowledge_spec)) 0L else length(self$knowledge_spec$items), "\n")
      cat("Autonomy stage:", if (is.na(self$autonomy_stage)) "<unspecified>" else self$autonomy_stage, "\n")
      invisible(self)
    }
  )
)

#' AgentScaffoldState
#'
#' Top-level state container for approved agent designs and nested workflow state.
#'
#' @field approved_agent_spec Current approved `AgentSpec` or `NULL`.
#' @field proposal_state Free-form proposal lifecycle state list.
#' @field workflow_state A `WorkflowProposalState` object.
#' @field metadata Free-form metadata list.
#' @param approved_agent_spec Current approved `AgentSpec` or `NULL`.
#' @param proposal_state Free-form proposal lifecycle state list.
#' @param workflow_state A `WorkflowProposalState` object.
#' @param metadata Free-form metadata list.
#' @param spec Agent spec used by `$set_approved_agent_spec()`.
#' @param ... Unused print arguments.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(approved_agent_spec = NULL, proposal_state = list(status = "draft", proposals = list()), workflow_state = WorkflowProposalState$new(), metadata = list())`}{Create an agent scaffold state container.}
#'   \item{`$validate()`}{Validate the state object.}
#'   \item{`$set_approved_agent_spec(spec)`}{Store an approved `AgentSpec`.}
#'   \item{`$approved_workflow()`}{Return the approved workflow, preferring the approved agent spec when present.}
#'   \item{`$as_list()`}{Return a serializable representation.}
#' }
#' @export
AgentScaffoldState <- R6::R6Class(
  classname = "AgentScaffoldState",
  public = list(
    approved_agent_spec = NULL,
    proposal_state = NULL,
    workflow_state = NULL,
    metadata = NULL,

    #' @description
    #' Create an agent scaffold state container.
    initialize = function(
      approved_agent_spec = NULL,
      proposal_state = list(status = "draft", proposals = list()),
      workflow_state = WorkflowProposalState$new(),
      metadata = list()
    ) {
      self$approved_agent_spec <- approved_agent_spec
      self$proposal_state <- proposal_state
      self$workflow_state <- workflow_state
      self$metadata <- metadata
      self$validate()
    },

    #' @description
    #' Validate the state object.
    validate = function() {
      if (!is.null(self$approved_agent_spec) && !inherits(self$approved_agent_spec, "AgentSpec")) {
        stop("`approved_agent_spec` must be `NULL` or an `AgentSpec`.", call. = FALSE)
      }
      if (!is.list(self$proposal_state)) {
        stop("`proposal_state` must be a list.", call. = FALSE)
      }
      if (!inherits(self$workflow_state, "WorkflowProposalState")) {
        stop("`workflow_state` must be a `WorkflowProposalState`.", call. = FALSE)
      }
      .validate_metadata_list(self$metadata)
      invisible(self)
    },

    #' @description
    #' Store an approved `AgentSpec`.
    set_approved_agent_spec = function(spec) {
      if (!inherits(spec, "AgentSpec")) {
        stop("`spec` must be an `AgentSpec`.", call. = FALSE)
      }
      spec$validate()
      self$approved_agent_spec <- spec
      self$proposal_state$status <- "approved"
      invisible(spec)
    },

    #' @description
    #' Return the approved workflow.
    approved_workflow = function() {
      if (!is.null(self$approved_agent_spec) && !is.null(self$approved_agent_spec$workflow)) {
        return(self$approved_agent_spec$workflow)
      }
      self$workflow_state$approved_workflow
    },

    #' @description
    #' Return a serializable representation.
    as_list = function() {
      self$validate()
      list(
        approved_agent_spec = if (is.null(self$approved_agent_spec)) NULL else self$approved_agent_spec$as_list(),
        proposal_state = self$proposal_state,
        workflow_state = self$workflow_state$as_list(),
        metadata = self$metadata
      )
    },

    #' @description
    #' Print a compact state summary.
    print = function(...) {
      self$validate()
      cat("<AgentScaffoldState>\n")
      cat("Proposal status:", self$proposal_state$status %||% "<unknown>", "\n")
      cat("Approved agent spec:", if (is.null(self$approved_agent_spec)) "<none>" else self$approved_agent_spec$agent_name, "\n")
      invisible(self)
    }
  )
)

#' IntelligentAgent
#'
#' Runtime-oriented container for an approved agent design.
#'
#' @field id Runtime identifier.
#' @field name Human-readable agent name.
#' @field spec An `AgentSpec` object.
#' @field workflow Current workflow specification.
#' @field subsystems Selected `SubsystemSpec` object.
#' @field runtime_state Free-form runtime state list.
#' @field metadata Free-form metadata list.
#' @param id Runtime identifier.
#' @param name Human-readable agent name.
#' @param spec An `AgentSpec` object.
#' @param workflow Current workflow specification.
#' @param subsystems Selected `SubsystemSpec` object.
#' @param runtime_state Free-form runtime state list.
#' @param metadata Free-form metadata list.
#' @param ... Unused print arguments.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(id = "intelligent-agent", name = NULL, spec, workflow = NULL, subsystems = NULL, runtime_state = list(), metadata = list())`}{Create a runtime-oriented agent container from an `AgentSpec`.}
#'   \item{`$validate()`}{Validate the runtime container.}
#'   \item{`$selected_subsystems()`}{Return the selected subsystem names.}
#'   \item{`$snapshot()`}{Return a serializable runtime snapshot.}
#' }
#' @export
IntelligentAgent <- R6::R6Class(
  classname = "IntelligentAgent",
  public = list(
    id = NULL,
    name = NULL,
    spec = NULL,
    workflow = NULL,
    subsystems = NULL,
    runtime_state = NULL,
    metadata = NULL,

    #' @description
    #' Create a runtime-oriented agent container from an `AgentSpec`.
    initialize = function(
      id = "intelligent-agent",
      name = NULL,
      spec,
      workflow = NULL,
      subsystems = NULL,
      runtime_state = list(),
      metadata = list()
    ) {
      if (!inherits(spec, "AgentSpec")) {
        stop("`spec` must be an `AgentSpec`.", call. = FALSE)
      }
      spec$validate()
      self$id <- as.character(id)[1]
      self$name <- as.character(name %||% spec$agent_name)[1]
      self$spec <- spec
      self$workflow <- workflow %||% spec$workflow
      self$subsystems <- subsystems %||% spec$subsystems
      self$runtime_state <- runtime_state
      self$metadata <- metadata
      self$validate()
    },

    #' @description
    #' Validate the runtime container.
    validate = function() {
      if (!inherits(self$spec, "AgentSpec")) {
        stop("`spec` must be an `AgentSpec`.", call. = FALSE)
      }
      if (!inherits(self$subsystems, "SubsystemSpec")) {
        stop("`subsystems` must be a `SubsystemSpec`.", call. = FALSE)
      }
      if (!is.null(self$workflow)) {
        validate_workflow_spec(self$workflow)
        if (!is.null(self$spec$workflow) &&
            !identical(self$workflow$nodes$id, self$spec$workflow$nodes$id)) {
          stop("`workflow` must stay aligned with `spec$workflow` node ids.", call. = FALSE)
        }
      }
      .validate_metadata_list(self$runtime_state, "runtime_state")
      .validate_metadata_list(self$metadata)
      invisible(self)
    },

    #' @description
    #' Return the selected subsystem names.
    selected_subsystems = function() {
      self$subsystems$selected_subsystems()
    },

    #' @description
    #' Return a serializable runtime snapshot.
    snapshot = function() {
      self$validate()
      list(
        id = self$id,
        name = self$name,
        spec = self$spec$as_list(),
        workflow = self$workflow,
        subsystems = self$subsystems$as_list(),
        runtime_state = self$runtime_state,
        metadata = self$metadata
      )
    },

    #' @description
    #' Print a compact runtime summary.
    print = function(...) {
      self$validate()
      cat("<IntelligentAgent>\n")
      cat("Id:", self$id, "\n")
      cat("Name:", self$name, "\n")
      cat("Subsystems:", paste(self$selected_subsystems(), collapse = ", "), "\n")
      cat("Workflow nodes:", if (is.null(self$workflow)) 0L else nrow(self$workflow$nodes), "\n")
      invisible(self)
    }
  )
)
