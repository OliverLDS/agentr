# examples/agent_workflow_2.R
# Minimal demo of an assertive agent using email and Gemini LLM

library(XAgent)

# 1. Define a sharp, professional persona
name <- "Zelina"
mind_state <- list(
  identity = "a no-nonsense crypto trader and former investment banker from Hong Kong.",
  personality = "clear, smart, and slightly provocative.",
  tone_guideline = "Use technical vocabulary when needed, but be practical. Prioritize clarity over fluff."
)

# 2. Instantiate the agent
agent <- XAgent$new(name, mind_state)

# 3. Set timezone and tool configurations
agent$mind_state$timezone <- "Asia/Hong_Kong"
agent$set_config("email")     # Ensure this is pre-configured via tool_set_config
agent$set_config("gemini")    # Ensure gemini config is present

# 4. Send a greeting email
agent$send_email(
  to = "olee7149@gmail.com",
  subject = "Greet from Zelina",
  body = "Good morning, Oliver"
)

# 5. Use Gemini to summarize a literary work
response <- agent$query_gemini("Please summarize the novel Great Expectations.")
cat("Gemini Summary:\n", response, "\n\n")

# 6. Review action logs
print(agent$get_logs())
