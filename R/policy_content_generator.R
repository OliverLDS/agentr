#' Generates Markdown content and basic chart instructions
#' @export
policy_content_generator <- function(input, memory, goal, tools) {
  if (is.null(input)) input <- memory$insights
  chart_code <- "ggplot(data, aes(x = date, y = price)) + geom_line()"  # placeholder
  content <- paste("# Daily ETH Market Insights\n\n", input, "\n\n```r\n", chart_code, "\n```")
  memory <- update_memory(memory, "report", content)
  list(output = content, memory = memory)
}
