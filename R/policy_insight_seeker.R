#' Uses LLM to extract insights from reviewed data
#' @export
policy_insight_seeker_old <- function(input, memory, goal, tools) {
  if (is.null(input)) input <- memory$review_summary
  summary_text <- paste("Price valid:", input$price_valid,
                        "\nFed rate:", input$fed_rate,
                        "\nNews items:", input$news_count)
  prompt <- paste("What key market insights can you extract from the following:\n\n", summary_text)
  insights <- tools$llm(prompt)
  memory <- update_memory(memory, "insights", insights)
  list(output = insights, memory = memory)
}

#' @title Generate insight from summaries or trades
#' @description Converts raw summaries or trade logs into distilled insight.
#' @param memory Agent belief state.
#' @param external_inputs Optional.
#' @return Updated memory.
#' @export
policy_insight_seeker <- function(memory, external_inputs = NULL) {
  closed <- memory$closed_positions %||% list()
  insight <- NULL

  if (length(closed) > 0) {
    pnl <- purrr::map_dbl(closed, "pnl")
    avg_pnl <- mean(pnl)
    insight <- if (avg_pnl >= 0) {
      "Trend bias accurate. Performance positive on last batch."
    } else {
      "Positioning misaligned. Review entry trigger rules."
    }
  }

  memory$insight <- insight
  memory$insight_ts <- Sys.time()
  memory
}

