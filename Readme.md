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

## 🧠 Environment Variables

XAgent reads API keys from your `~/.Renviron` file using `Sys.getenv()`.
RStudio **automatically loads `~/.Renviron` on startup**, so there’s no
need to set the path manually.

Example `.Renviron`:

    GEMINI_API_KEY=your-gemini-api-key
    OKX_API_KEY=your-okx-api-key
    OKX_SECRET_KEY=your-okx-secret
    OKX_PASSPHRASE=your-okx-passphrase
    FRED_API_KEY=your-fred-api-key
    TELEGRAM_BOT_TOKEN=your-telegram-bot-token
    TELEGRAM_CHAT_ID=@yourchannel

## 🧪 Example: Call LLM directly

``` r
conf <- create_llm_config(
  api_key = Sys.getenv("GEMINI_API_KEY"),
  provider = "gemini",
  temperature = 0.5
)
response <- tool_llm("List 5 unicorn startup ideas", config = conf)
cat(response)
```

## 🤖 Example: Run a Full Agent Pipeline

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

### ▶️ Example: Just run `agent1` to collect data

``` r
agent1 <- get_agent("data_collector")
result <- run_agent(agent1)
str(result$output)

# Optional: update agent's memory after run
agent1$memory <- result$memory

# Inspect specific memory fields
str(agent1$memory$raw_data$ticker)
```

## ✏️ Custom Agent Example

Users can define and register their own agent using `create_agent()`:

``` r
my_agent <- create_agent(
  name = "MyTester",
  goal = list(task = "Summarize ETH and FRED rate"),
  memory = create_memory(),
  policy = policy_insight_seeker,
  tools = list(
    llm = function(prompt) tool_llm(prompt, config = get_tool_config("llm"))
  )
)

result <- run_agent(my_agent)
cat(result$output)
```

## 🛠 Tools You Can Use

- `tool_llm()` — Access Gemini for prompt-based reasoning
- `tool_okx_ticker()` — Get ETH price from OKX
- `tool_fred_series()` — Pull macroeconomic data from FRED
- `tool_post_telegram()` — Send text to a Telegram chat
- `tool_fetch_rss()` — Parse economic news feeds

## 📂 Agent Anatomy

Each agent has: - `goal`: A task description or parameters - `memory`:
State or past results - `policy`: A function that defines what the agent
does - `tools`: A named list of functions it can use

``` r
agent <- create_agent(
  name = "example_agent",
  goal = list(task = "Analyze market"),
  memory = create_memory(),
  policy = policy_insight_seeker,
  tools = list(llm = tool_llm, okx_ticker = tool_okx_ticker)
)
```

## 📫 Contact

Maintained by Oliver. Reach out via
[LinkedIn](https://www.linkedin.com/in/oliver-lee-28b32b176/).
