#' Create a default affective state
#'
#' Initializes a minimal affective state with Plutchik-style primary dimensions,
#' an inertia factor, and a timestamp for time-based decay.
#'
#' @param decay_rate Hourly decay rate between 0 and 1.
#' @param inertia Inertia factor between 0 and 1 for incremental updates.
#'
#' @return A named list.
#' @export
default_emotion_state <- function(decay_rate = 0.98, inertia = 0.85) {
  list(
    primary = c(
      joy = 0.1,
      sadness = 0.1,
      anger = 0.1,
      fear = 0.1,
      trust = 0.1,
      disgust = 0.1,
      anticipation = 0.1,
      surprise = 0.1
    ),
    last_update = Sys.time(),
    decay_rate = decay_rate,
    inertia = inertia
  )
}

#' Create a randomized affective state
#'
#' @param total_intensity Total sum of primary emotion values.
#' @param sparsity Proportion of primary emotions to zero out.
#' @param decay_rate Hourly decay rate between 0 and 1.
#' @param inertia Inertia factor between 0 and 1 for incremental updates.
#'
#' @return A named list.
#' @export
define_random_emotion_state <- function(
  total_intensity = 1,
  sparsity = 0,
  decay_rate = 0.98,
  inertia = 0.85
) {
  primary_names <- c(
    "joy", "sadness", "anger", "fear",
    "trust", "disgust", "anticipation", "surprise"
  )

  values <- stats::runif(length(primary_names))
  values <- values / sum(values) * total_intensity

  if (sparsity > 0) {
    zero_count <- floor(sparsity * length(values))
    zero_indices <- sample(seq_along(values), zero_count)
    values[zero_indices] <- 0
  }

  names(values) <- primary_names

  list(
    primary = values,
    last_update = Sys.time(),
    decay_rate = decay_rate,
    inertia = inertia
  )
}

#' Apply time-based decay to an affective state
#'
#' @param emotion_state State list created by [default_emotion_state()] or
#'   [define_random_emotion_state()].
#' @param current_time Reference time.
#'
#' @return Updated affective state list.
#' @export
decay_emotion_state <- function(emotion_state, current_time = Sys.time()) {
  time_diff_hours <- as.numeric(
    difftime(current_time, emotion_state$last_update, units = "hours")
  )
  if (time_diff_hours <= 0) {
    return(emotion_state)
  }

  decay_factor <- emotion_state$decay_rate ^ time_diff_hours
  emotion_state$primary <- emotion_state$primary * decay_factor
  emotion_state$last_update <- current_time
  emotion_state
}

#' Combine two emotion values
#'
#' @param a First value.
#' @param b Second value.
#' @param method Combination method.
#' @param w1 Weight for `a` when `method = "weighted"`.
#' @param w2 Weight for `b` when `method = "weighted"`.
#'
#' @return Numeric scalar.
#' @export
combine_emotions <- function(a, b, method = "geometric", w1 = 0.5, w2 = 0.5) {
  as.numeric(switch(
    method,
    min = min(a, b),
    mean = mean(c(a, b)),
    geometric = sqrt(a * b),
    weighted = w1 * a + w2 * b,
    stop("Unknown method: ", method, call. = FALSE)
  ))
}

#' Compute blended emotions from primary emotions
#'
#' @param primary Named numeric vector of primary emotions.
#' @param method Combination method passed to [combine_emotions()].
#'
#' @return Named list of blended emotions.
#' @export
compute_blended_emotions <- function(primary, method = "geometric") {
  list(
    love = combine_emotions(primary["joy"], primary["trust"], method),
    submission = combine_emotions(primary["trust"], primary["fear"], method),
    awe = combine_emotions(primary["fear"], primary["surprise"], method),
    disapproval = combine_emotions(primary["surprise"], primary["sadness"], method),
    remorse = combine_emotions(primary["sadness"], primary["disgust"], method),
    contempt = combine_emotions(primary["disgust"], primary["anger"], method),
    aggression = combine_emotions(primary["anger"], primary["anticipation"], method),
    optimism = combine_emotions(primary["anticipation"], primary["joy"], method)
  )
}

#' Describe an affective state in natural language
#'
#' @param emotion_state State list created by [default_emotion_state()] or
#'   [define_random_emotion_state()].
#' @param threshold Minimum intensity required for a dominant affect label.
#' @param include_blended Whether to include blended affect.
#' @param method Combination method passed to [combine_emotions()].
#'
#' @return Character string.
#' @export
describe_emotional_state <- function(
  emotion_state,
  threshold = 0.2,
  include_blended = TRUE,
  method = "geometric"
) {
  primary <- emotion_state$primary
  top_primary <- sort(primary, decreasing = TRUE)

  if (top_primary[1] < threshold) {
    return("Currently affectively neutral with no dominant dimension.")
  }

  intensity <- top_primary[1]
  intensity_label <- if (intensity < 0.2) {
    "low"
  } else if (intensity < 0.5) {
    "moderate"
  } else {
    "strong"
  }

  description <- paste0(
    "Currently feeling mostly ", names(top_primary)[1],
    " (", intensity_label, ")."
  )

  if (include_blended) {
    blended_list <- compute_blended_emotions(primary, method = method)
    blended_vec <- unlist(blended_list, use.names = TRUE)
    top_blended <- sort(blended_vec, decreasing = TRUE)

    if (top_blended[1] >= threshold) {
      description <- paste0(
        description,
        " Dominant blend: ", names(top_blended)[1], "."
      )
    }
  }

  description
}

#' AffectiveState
#'
#' Minimal structured affective layer with inertia-aware updates.
#'
#' @field state A named list returned by [default_emotion_state()].
#' @param state Affective state used by `$initialize()`.
#' @param current_time Reference time used by `$decay()`.
#' @param updates Named numeric updates used by `$update_primary()`.
#' @param threshold Threshold used by `$describe()`.
#' @param include_blended Logical flag used by `$describe()`.
#' @param method Combination method used by `$describe()`.
#'
#' @export
AffectiveState <- R6::R6Class(
  classname = "AffectiveState",
  public = list(
    state = NULL,

    initialize = function(state = default_emotion_state()) {
      self$state <- state
    },

    decay = function(current_time = Sys.time()) {
      self$state <- decay_emotion_state(self$state, current_time = current_time)
      invisible(self)
    },

    update_primary = function(updates) {
      stopifnot(is.numeric(updates))
      self$decay()

      target_names <- intersect(names(updates), names(self$state$primary))
      if (!length(target_names)) {
        return(invisible(self))
      }

      inertia <- self$state$inertia
      for (name in target_names) {
        previous <- self$state$primary[[name]]
        proposed <- updates[[name]]
        blended <- inertia * previous + (1 - inertia) * proposed
        self$state$primary[[name]] <- max(0, min(1, blended))
      }

      self$state$last_update <- Sys.time()
      invisible(self)
    },

    describe = function(
      threshold = 0.2,
      include_blended = TRUE,
      method = "geometric"
    ) {
      describe_emotional_state(
        self$state,
        threshold = threshold,
        include_blended = include_blended,
        method = method
      )
    },

    as_list = function() {
      self$state
    }
  )
)
