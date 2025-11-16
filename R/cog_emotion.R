#' Create a Default Emotional State
#'
#' Initializes a Plutchik-inspired primary emotion vector with neutral values,
#' along with a decay rate and timestamp for time-based adjustments.
#'
#' @param decay_rate A numeric value between 0 and 1. Default is \code{0.98}, indicating 2% hourly decay.
#'
#' @return A named list representing the emotional state.
#' @export
default_emotion_state <- function(decay_rate = 0.98) {
  list(
    # Primary emotion levels (Plutchik-inspired), starting neutral/low
    primary = c(
      joy = 0.1, # A feeling of happiness, delight, or inner lightness, when achieving goals, receiving affection, feeling safe or playful.
      sadness = 0.1, # A response to loss, disappointment, or disconnection, when missing someone, recalling painful events, feeling let down.
      anger = 0.1, # A reaction to perceived injustice, threat to values, or frustration, when someone violated trust, crossed a boundary, or hurt a loved one.
      fear = 0.1, # Anticipated danger or threat to safety or stability, when uncertainty, personal risk, overwhelming change.
      trust = 0.1, # A sense of comfort in depending on another or sharing vulnerability, when repeated kindness, shared experience, emotional honesty.
      disgust = 0.1, # A strong rejection — physical, moral, or social, when witnessing cruelty, hypocrisy, or something repulsive.
      anticipation = 0.1, # Alert expectation or readiness for a future event (positive or negative), when waiting for a reply, upcoming news, change on the horizon.
      surprise = 0.1 # An acute reaction to an unexpected event, when receiving an unpredicted message, news, or behavior.
    ),
    
    # Timestamp to track last emotional update
    last_update = Sys.time(),
    
    # Hourly decay rate (0.98 → ~2% drop per hour)
    decay_rate = decay_rate
  )
}

#' Create a Randomized Emotional State
#'
#' Generates a random set of emotional intensities with optional sparsity.
#'
#' @param total_intensity Total sum of all emotion values. Default is \code{1}.
#' @param sparsity Proportion of primary emotions to zero out. Value from 0 to 1.
#' @param decay_rate Hourly decay rate for emotional intensity. Default is \code{0.98}.
#'
#' @return A list representing the randomized emotional state.
#' @export
define_random_emotion_state <- function(
  total_intensity = 1,
  sparsity = 0,
  decay_rate = 0.98
) {
  primary_names <- c("joy", "sadness", "anger", "fear", "trust", "disgust", "anticipation", "surprise")
  
  n <- length(primary_names)
  values <- runif(n)
  values <- values / sum(values) * total_intensity
  
  # Zero out randomly selected dimensions
  if (sparsity > 0) {
    zero_count <- floor(sparsity * n)
    zero_indices <- sample(seq_along(values), zero_count)
    values[zero_indices] <- 0
  }

  list(
    primary = stats::setNames(values, primary_names),
    last_update = Sys.time(),
    decay_rate = decay_rate
  )
}

#' Apply Time-Based Decay to Emotional State
#'
#' Reduces emotional intensity over time according to the decay rate.
#'
#' @param emotion_state A list created by \code{default_emotion_state()} or \code{define_random_emotion_state()}.
#' @param current_time POSIXct time for decay reference. Defaults to \code{Sys.time()}.
#'
#' @return Updated emotional state with decayed intensities.
#' @export
decay_emotion_state <- function(emotion_state, current_time = Sys.time()) {
  time_diff_hours <- as.numeric(difftime(current_time, emotion_state$last_update, units = "hours"))
  if (time_diff_hours <= 0) return(emotion_state)

  decay_factor <- emotion_state$decay_rate ^ time_diff_hours
  new_primary <- emotion_state$primary * decay_factor

  emotion_state$primary <- new_primary
  emotion_state$last_update <- current_time
  return(emotion_state)
}

#' Combine Two Emotion Values
#'
#' Combines two emotion intensities using a specified mathematical method.
#'
#' @param a First emotion value.
#' @param b Second emotion value.
#' @param method Combination method: \code{"min"}, \code{"mean"}, \code{"geometric"}, or \code{"weighted"}.
#' @param w1 Weight for \code{a} when \code{method = "weighted"}.
#' @param w2 Weight for \code{b} when \code{method = "weighted"}.
#'
#' @return A numeric value representing the combined emotion.
#' @export
combine_emotions <- function(a, b, method = "geometric", w1 = 0.5, w2 = 0.5) {
  as.numeric(switch(method,
    min = min(a, b),
    mean = mean(c(a, b)),
    geometric = sqrt(a * b),
    weighted = w1 * a + w2 * b,
    stop("Unknown method: ", method)
  ))
}

#' Compute Blended Emotions from Primary Emotions
#'
#' Calculates secondary emotions by blending pairs of primary emotions.
#'
#' @param primary A named numeric vector of primary emotions.
#' @param method Combination method for blending. Passed to \code{combine_emotions()}.
#'
#' @return A named list of blended emotional values.
#' @export
compute_blended_emotions <- function(primary, method = "geometric") {
  list(
    love         = combine_emotions(primary["joy"], primary["trust"], method), # A warm emotional bond marked by both happiness and confidence in the other’s presence. It expresses affection, appreciation, and emotional closeness.
    submission   = combine_emotions(primary["trust"], primary["fear"], method), # A feeling of yielding or deferring to someone more powerful, grounded in admiration, awe, or dependence. Not always negative — can be respectful.
    awe          = combine_emotions(primary["fear"], primary["surprise"], method), # A reverent and stunned reaction to something vast, powerful, or incomprehensible — can include admiration and smallness.
    disapproval  = combine_emotions(primary["surprise"], primary["sadness"], method), # A response of emotional withdrawal or moral discomfort, often due to disappointment or unmet expectations.
    remorse      = combine_emotions(primary["sadness"], primary["disgust"], method), # A regretful response to having violated one’s values, especially when the action feels morally or emotionally tainted.
    contempt     = combine_emotions(primary["disgust"], primary["anger"], method), # A judgmental emotional state that views another as beneath moral or social standards — often cold, critical, and distancing.
    aggression   = combine_emotions(primary["anger"], primary["anticipation"], method), # A readiness to confront or take action, often driven by frustration and the urge to push forward or retaliate.
    optimism     = combine_emotions(primary["anticipation"], primary["joy"], method) # A forward-looking positive state marked by excitement about good outcomes, possibilities, or upcoming rewards.
  )
}

#' Describe the Agent's Emotional State in Natural Language
#'
#' Returns a text summary of the dominant emotion and optionally a blended emotion.
#'
#' @param emotion_state A list created by \code{default_emotion_state()} or \code{define_random_emotion_state()}.
#' @param threshold Minimum intensity to consider an emotion as dominant. Default is \code{0.2}.
#' @param include_blended Logical. If \code{TRUE}, include blended emotions in the description.
#' @param method Method used for blending. See \code{combine_emotions()}.
#'
#' @return A character string summarizing the emotional state.
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
    return("Currently emotionally neutral — no strong feelings dominate.")
  }

  primary_label <- names(top_primary)[1]
  intensity <- top_primary[1]

  intensity_label <- if (intensity < 0.2) {
    "low"
  } else if (intensity < 0.5) {
    "moderate"
  } else {
    "strong"
  }

  description <- paste0("Currently feeling mostly *", primary_label, "* (", intensity_label, ")")

  if (include_blended) {
    blended_list <- compute_blended_emotions(primary, method = method)
    blended_vec <- unlist(blended_list) |> as.numeric()
    names(blended_vec) <- names(blended_list)

    top_blended <- sort(blended_vec, decreasing = TRUE)
    if (top_blended[1] >= threshold) {
      blended_label <- names(top_blended)[1]
      description <- paste0(description, ", with a hint of *", blended_label, "*")
    }
  }

  return(paste0(description, "."))
}


