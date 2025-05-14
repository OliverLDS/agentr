#' Uses LLM to extract insights from reviewed data
#' @export
policy_insight_seeker <- function(input, memory, goal, tools) {
  if (is.null(input)) input <- memory$review_summary
  summary_text <- paste("Price valid:", input$price_valid,
                        "\nFed rate:", input$fed_rate,
                        "\nNews items:", input$news_count)
  prompt <- paste("What key market insights can you extract from the following:\n\n", summary_text)
  insights <- tools$llm(prompt)
  memory <- update_memory(memory, "insights", insights)
  list(output = insights, memory = memory)
}

