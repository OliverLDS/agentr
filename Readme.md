# XAgent: A Modular Multi-Agent Framework in R


<!-- badges: start -->
<!-- badges: end -->

## 📦 Overview

`XAgent` is a composable multi-agent framework in R that lets you create
autonomous agents with tools, memory, goals, and optional LLM access.
Agents can fetch data, analyze it, generate insights and content, post
to channels, or interact with APIs (like OKX, FRED, or Telegram).

## 🔧 Installation

Clone the repo and install locally:

``` r
# From your R console
devtools::install_local("path/to/XAgent")
```

Or load it directly in development mode:

``` r
devtools::load_all()
```

## 🧠 Example: Run a Full Agent Pipeline

``` r
# Load your agent registry
agent1 <- get_agent("data_collector")
agent2 <- get_agent("data_reviewer")
agent3 <- get_agent("insight_seeker")
agent4 <- get_agent("content_generator")
agent5 <- get_agent("content_poster")

# Optionally configure posting goal (for Telegram, etc.)
agent5$goal <- list(
  task = "Post today's economic summary",
  bot_token = Sys.getenv("TELEGRAM_BOT_TOKEN"),
  chat_id = Sys.getenv("TELEGRAM_CHAT_ID")
)

# Run the pipeline
result <- run_pipeline(list(agent1, agent2, agent3, agent4, agent5))
cat(result)
```

## 🛠 Tools You Can Use

- `tool_llm()` — Access Gemini for prompt-based reasoning
- `tool_okx_ticker()` — Get ETH price from OKX
- `tool_fred_series()` — Pull macroeconomic data from FRED
- `tool_post_telegram()` — Send text to a Telegram chat
- `tool_fetch_rss()` — Parse economic news feeds

## 📂 Agent Anatomy

Each agent has:

- `goal`: A task description or parameters
- `memory`: State or past results
- `policy`: A function that defines what the agent does
- `tools`: A named list of functions it can use

``` r
agent <- create_agent(
  name = "example_agent",
  goal = list(task = "Analyze market"),
  memory = create_memory(),
  policy = policy_insight_seeker,
  tools = list(llm = tool_llm, okx_ticker = tool_okx_ticker)
)
```

## 📢 Contact

Maintained by Oliver. Reach out via
[LinkedIn](https://www.linkedin.com/in/oliver-lee-28b32b176/).
