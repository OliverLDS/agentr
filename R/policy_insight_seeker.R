policy_insight_seeker <- function(input, memory, goal, tools) {
  summary <- tools$fetch_summary(input)
  prompt <- paste("What insights can you find in:", summary)
  insights <- tools$llm(prompt)  # just one tool
  memory$last_insights <- insights
  list(output = insights, memory = memory)
}