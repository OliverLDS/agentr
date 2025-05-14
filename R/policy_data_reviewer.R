#' Reviews raw data for consistency or anomalies
#' @export
policy_data_reviewer <- function(input, memory, goal, tools) {
  if (is.null(input)) input <- memory$raw_data
  reviewed <- list(
    price_valid = !is.null(input$ticker$last),
    fed_rate = as.numeric(tail(input$macro$value, 1)),
    news_count = nrow(input$news)
  )
  memory <- update_memory(memory, "review_summary", reviewed)
  list(output = reviewed, memory = memory)
}
