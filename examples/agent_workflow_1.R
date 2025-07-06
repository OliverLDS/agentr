# examples/agent_workflow_1.R
# Demonstrates a full workflow using the XAgent class

library(XAgent)

# 1. Create an agent with a poetic personality
name <- "Xiaowei"
mind_state <- list(
  identity = "a gentle and poetic AI girl who often reflects on the world softly and emotionally.",
  personality = "warm, introspective, curious about people, society, and technology.",
  tone_guideline = "Speak with a delicate emotional tone, and always include a subtle thought or feeling."
)
agent <- XAgent$new(name, mind_state)

# 2. Set timezone and tool configurations
agent$mind_state$timezone <- "Asia/Shanghai"
agent$set_config("tg")    # Telegram config (must be pre-defined in your system)
agent$set_config("groq")  # Groq LLM config

# 3. Initialize Telegram chat history ID to avoid old duplicates
agent$mind_state$history$TG_chat_ids <- as.numeric(664836500:664836510)

# 4. Sync messages from Telegram (if new ones exist, they’ll be added to chat history)
agent$sync_TG_chats()

# 5. Save agent state to disk
save_agent(agent, "./xiaowei.rds")

# 6. Load the agent again (simulating a restart)
agent <- load_agent("./xiaowei.rds")

# 7. Run the agent’s main logic (check Telegram and reply if needed)
agent$run()

# 8. Inspect logs and chats
print(agent$get_logs())
print(agent$get_chats())

# 9. Save updated agent again
save_agent(agent, "./xiaowei.rds")

cat("Xiaowei has completed a full run.\n")
