# Function Index: XAgent Package

This document provides a categorized index of exported functions and methods in the **XAgent** R package. It is intended to assist developers and users in locating key utilities and understanding their intended usage.

---

## 1. 📦 Agent Initialization & Persistence

| Function/Method  | Purpose                                                |
| ---------------- | ------------------------------------------------------ |
| `XAgent$new()`   | Create a new agent with a name and initial mind\_state |
| `load_agent()`   | Load an agent from an RDS file                         |
| `save_agent()`   | Save an agent to an RDS file                           |
| `backup_agent()` | Save an agent with timestamped filename                |

---

## 2. 🧠 Mind State Management

| Function/Method       | Purpose                                         |
| --------------------- | ----------------------------------------------- |
| `init_mind_state()`   | Create or modify the mind\_state structure      |
| `update_mind_state()` | Update a nested path inside mind\_state         |
| `set_nested_path()`   | Utility to update deeply nested list structures |

---

## 3. 📡 Communication Interfaces

### Telegram

| Function/Method   | Purpose                                 |
| ----------------- | --------------------------------------- |
| `send_text_TG()`  | Send a text message via Telegram        |
| `send_image_TG()` | Send an image with caption via Telegram |
| `sync_TG_chats()` | Fetch user replies from Telegram        |

### Email

| Function/Method | Purpose                           |
| --------------- | --------------------------------- |
| `send_email()`  | Send an email via configured tool |

### Local Chat

| Function/Method           | Purpose                                                |
| ------------------------- | ------------------------------------------------------ |
| `send_text_local()`       | Append message to local chat file                      |
| `sync_local_user_input()` | Read user input from chat file and update agent memory |
| `popout_local()`          | Open local chat file in external editor                |

---

## 4. 🧠 Prompt Composition & LLM Querying

| Function/Method          | Purpose                          |
| ------------------------ | -------------------------------- |
| `compose_prompt_plain()` | Compose prompt from chat history |
| `query_groq()`           | Query Groq API with prompt       |
| `query_gemini()`         | Query Gemini API with prompt     |

---

## 5. 📈 Data Fetching Utilities

| Function                        | Purpose                              |
| ------------------------------- | ------------------------------------ |
| `fetch_fred_series()`           | Download FRED time series            |
| `fetch_ts_daily_alphavantage()` | Daily OHLC data from Alpha Vantage   |
| `fetch_binance_klines()`        | Minute-level kline data from Binance |
| `fetch_rss()`                   | Load and parse RSS feed              |

---

## 6. 🧬 Emotion Modeling

| Function/Method                 | Purpose                               |
| ------------------------------- | ------------------------------------- |
| `define_random_emotion_state()` | Generate random emotion profile       |
| `decay_emotion_state()`         | Apply decay to existing emotion state |
| `describe_emotional_state()`    | Return qualitative emotion summary    |
| `combine_emotions()`            | Merge multiple emotion states         |
| `compute_blended_emotions()`    | Blend emotion states with weights     |

---

## 7. ⚙️ Tools and Configuration

| Function/Method     | Purpose                                                 |
| ------------------- | ------------------------------------------------------- |
| `tool_set_config()` | Return prefilled config list for tool (e.g., TG, email) |

---

## 8. 📃 Utilities and Format Helpers

| Function                  | Purpose                             |
| ------------------------- | ----------------------------------- |
| `convert_time_to_tz()`    | Convert time to a specific timezone |
| `format_timestamp()`      | Format timestamp in readable form   |
| `recent_timestamp()`      | Filter recent entries               |
| `util_sync_new_records()` | Compare and sync data frame records |

---

## 9. 🔄 Operators

| Operator | Purpose |     |                                   |
| -------- | ------- | --- | --------------------------------- |
| \`%      |         | %\` | Return left-hand side if not NULL |

---

## 10. 🧪 Example Agent Workflows (see `/examples`)

* `agent_workflow.R`: Load and test an agent interactively
* Includes: Email sending, LLM querying, FRED/RSS/news access

---

For full details on each function or method, refer to the generated documentation in the `man/` folder or run `?function_name` within R.
