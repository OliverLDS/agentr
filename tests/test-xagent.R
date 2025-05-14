devtools::load_all()

# Build config using your config constructor
conf <- create_llm_config(
  api_key = Sys.getenv("GEMINI_API_KEY"),
  provider = "gemini",
  temperature = 0.5
)

# Run the LLM using the unified tool wrapper
response <- tool_llm("List 5 unicorn startup ideas", config = conf)

# Show the result
cat(response)


agent1 <- get_agent("data_collector")
result <- run_agent(agent1)
str(result$output)
str(result$memory)


agent2 <- get_agent("data_reviewer")
agent3 <- get_agent("insight_seeker")
agent4 <- get_agent("content_generator")
agent5 <- get_agent("content_poster")





