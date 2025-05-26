#' Generates Markdown content and basic chart instructions
#' @export
policy_content_generator_old <- function(input, memory, goal, tools) {
  if (is.null(input)) input <- memory$insights
  chart_code <- "ggplot(data, aes(x = date, y = price)) + geom_line()"  # placeholder
  content <- paste("# Daily ETH Market Insights\n\n", input, "\n\n```r\n", chart_code, "\n```")
  memory <- update_memory(memory, "report", content)
  list(output = content, memory = memory)
}

#' @title Render HTML plot from belief state
#' @description Converts insight and chart data into Rmd-generated HTML.
#' @param memory Agent belief state.
#' @param external_inputs Optional.
#' @return Updated memory.
#' @export
policy_content_generator <- function(memory, external_inputs = NULL) {
  insight <- memory$insight %||% "No insight generated."
  plot_obj <- memory$plot_data %||% default_summary_plot()

  output_path <- tempfile(fileext = ".html")
  rmarkdown::render(
    input = system.file("templates", "content_plot.Rmd", package = "XAgent"),
    params = list(insight = insight, plot_obj = plot_obj),
    output_file = output_path,
    quiet = TRUE
  )

  memory$content_report <- output_path
  memory$last_render <- Sys.time()
  log_info("📄 Rendered content to {output_path}")
  memory
}
