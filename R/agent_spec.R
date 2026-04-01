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
    value <- .normalize_character(value)
    if (!length(value)) {
      return(character())
    }
    allowed <- c("rwm", "pg", "ae", "iac", "la")
    invalid <- setdiff(value, allowed)
    if (length(invalid)) {
      stop(
        "Unsupported subsystem labels: ",
        paste(invalid, collapse = ", "),
        call. = FALSE
      )
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
.coerce_workflow_or_null <- function(workflow) {
  if (is.null(workflow)) {
    return(NULL)
  }
  validate_workflow_spec(workflow)
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
      if (!is.logical(self$enabled) || length(self$enabled) != 1L) {
        stop("`enabled` must be a single logical value.", call. = FALSE)
      }
      allowed <- c("none", "session", "persistent")
      if (!(self$persistence %in% allowed)) {
        stop("Cognitive persistence must be one of: none, session, persistent.", call. = FALSE)
      }
      if (!is.character(self$memory_types)) {
        stop("`memory_types` must be character.", call. = FALSE)
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
      if (!is.logical(self$enabled) || length(self$enabled) != 1L) {
        stop("`enabled` must be a single logical value.", call. = FALSE)
      }
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
    }
  )
)

#' RWMConfig
#'
#' Configuration for the reflective working-memory subsystem.
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
#' @section Methods:
#' \describe{
#'   \item{`$initialize(cognitive = CognitiveConfig$new(), affective = NULL, persistence = "session", summary = NULL, metadata = list())`}{Create an `RWM` config.}
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
    }
  )
)

#' PGConfig
#'
#' Configuration for the planning and goal-management subsystem.
#'
#' @field enabled Whether the subsystem is enabled.
#' @field planning_mode Planning mode label.
#' @field decomposition_style Workflow decomposition style.
#' @field metadata Free-form metadata list.
#' @param enabled Whether the subsystem is enabled.
#' @param planning_mode Planning mode label.
#' @param decomposition_style Workflow decomposition style.
#' @param metadata Free-form metadata list.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(enabled = TRUE, planning_mode = "task_decomposition", decomposition_style = "dag", metadata = list())`}{Create a planning and goal-management config.}
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
    #' Create a planning and goal-management config.
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
      if (!is.logical(self$enabled) || length(self$enabled) != 1L) {
        stop("`enabled` must be a single logical value.", call. = FALSE)
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
        planning_mode = self$planning_mode,
        decomposition_style = self$decomposition_style,
        metadata = self$metadata
      )
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
      if (!is.logical(self$enabled) || length(self$enabled) != 1L) {
        stop("`enabled` must be a single logical value.", call. = FALSE)
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
        execution_mode = self$execution_mode,
        tool_budget = self$tool_budget,
        metadata = self$metadata
      )
    }
  )
)

#' IACConfig
#'
#' Configuration for interaction and communication.
#'
#' @field enabled Whether the subsystem is enabled.
#' @field channels Character vector of communication channels.
#' @field structured_io Whether strongly structured I/O is required.
#' @field metadata Free-form metadata list.
#' @param enabled Whether the subsystem is enabled.
#' @param channels Character vector of communication channels.
#' @param structured_io Whether strongly structured I/O is required.
#' @param metadata Free-form metadata list.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(enabled = TRUE, channels = character(), structured_io = TRUE, metadata = list())`}{Create an interaction and communication config.}
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
    #' Create an interaction and communication config.
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
      if (!is.logical(self$enabled) || length(self$enabled) != 1L) {
        stop("`enabled` must be a single logical value.", call. = FALSE)
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
        channels = self$channels,
        structured_io = self$structured_io,
        metadata = self$metadata
      )
    }
  )
)

#' LAConfig
#'
#' Configuration for lightweight learning and adaptation.
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
      if (!is.logical(self$enabled) || length(self$enabled) != 1L) {
        stop("`enabled` must be a single logical value.", call. = FALSE)
      }
      if (!self$persistence %in% c("none", "session", "persistent")) {
        stop("LA persistence must be one of: none, session, persistent.", call. = FALSE)
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
    }
  )
)

#' SubsystemSpec
#'
#' Sparse inventory of the selected agent subsystems.
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
#' @section Methods:
#' \describe{
#'   \item{`$initialize(rwm = NULL, pg = NULL, ae = NULL, iac = NULL, la = NULL, metadata = list())`}{Create a sparse subsystem inventory.}
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
      self$metadata <- metadata
      self$validate()
    },

    #' @description
    #' Validate the subsystem selection.
    validate = function() {
      .validate_metadata_list(self$metadata)
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
#' @field state_requirements Free-form list of state requirements.
#' @field interfaces Free-form list of interfaces.
#' @field implementation_targets Free-form list of implementation targets.
#' @field metadata Free-form metadata list.
#' @param task Source task description.
#' @param agent_name Human-readable agent name.
#' @param summary One-line agent summary.
#' @param subsystems A `SubsystemSpec` object or list payload.
#' @param workflow Embedded workflow specification or `NULL`.
#' @param state_requirements Free-form list of state requirements.
#' @param interfaces Free-form list of interfaces.
#' @param implementation_targets Free-form list of implementation targets.
#' @param metadata Free-form metadata list.
#' @param file_path Output path used by `$save()`.
#' @section Methods:
#' \describe{
#'   \item{`$initialize(task, agent_name = "agentr-agent", summary = NULL, subsystems = SubsystemSpec$new(), workflow = NULL, state_requirements = list(), interfaces = list(), implementation_targets = list(), metadata = list())`}{Create an agent-design artifact.}
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
    state_requirements = NULL,
    interfaces = NULL,
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
      state_requirements = list(),
      interfaces = list(),
      implementation_targets = list(),
      metadata = list()
    ) {
      self$task <- as.character(task)[1]
      self$agent_name <- as.character(agent_name)[1]
      self$summary <- if (is.null(summary)) self$task else as.character(summary)[1]
      self$subsystems <- if (inherits(subsystems, "SubsystemSpec")) subsystems else do.call(SubsystemSpec$new, subsystems)
      self$workflow <- .coerce_workflow_or_null(workflow)
      self$state_requirements <- state_requirements
      self$interfaces <- interfaces
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
      if (!is.null(self$workflow)) {
        validate_workflow_spec(self$workflow)
        .validate_node_subsystems(self$metadata$node_subsystems, nodes = self$workflow$nodes)
      }
      .validate_metadata_list(self$state_requirements, "state_requirements")
      .validate_metadata_list(self$interfaces, "interfaces")
      .validate_metadata_list(self$implementation_targets, "implementation_targets")
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
        state_requirements = self$state_requirements,
        interfaces = self$interfaces,
        implementation_targets = self$implementation_targets,
        metadata = self$metadata
      )
    },

    #' @description
    #' Save the object with `save_agent()`.
    save = function(file_path) {
      save_agent(self, file_path)
      invisible(TRUE)
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
    }
  )
)
