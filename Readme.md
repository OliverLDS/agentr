# XAgent: Modular AI Agents in R

**XAgent** is a lightweight, modular R framework for building intelligent agents with personalities, memory, emotion, and LLM integration. Designed for both automation and experimentation, it allows flexible configuration and extension for various use cases like:

* Local chatbot companions
* Telegram-connected AI agents
* Financial or news-fetching bots
* Emotion-aware assistants

---

## 🚀 Features

* **Modular Design** via R6 classes
* **Mind State**: identity, beliefs, emotions, goals, memory
* **Multi-channel IO**: Telegram, email, local text
* **LLM Querying**: Supports Groq, Gemini (extendable)
* **Prompt Composition**: Structured history -> prompt
* **Emotion Engine**: Intensity, decay, blending, description
* **Tool Config**: FRED, Binance, AlphaVantage, RSS

---

## 🧠 Core Concepts

### Agent = Identity + Tools + Memory + Logic

* `XAgent`: Core class with default FSM and messaging flow
* `NewsReaderAgent`: Example subclass with FRED, RSS, Binance
* `mind_state`: Agent's internal state including:

  * `identity`, `personality`, `tone_guideline`
  * `emotion_state`: evolving values
  * `history`: logs and chats
  * `tool_config`: API credentials and settings

📖 For more details, see [`docs/agent_architecture.md`](docs/agent_architecture.md).

---

## 🛠️ Installation

```r
# In your R console
library(devtools)
devtools::install_local("path_to/XAgent")
```

---

## 🧪 Testing

```r
library(testthat)
testthat::test_package("XAgent")
```

---

## 📁 Folder Structure

* `R/`: Core agent logic, emotion models, tool functions
* `tests/`: Testthat test files
* `examples/`: Example agent workflows
* `man/`: Auto-generated documentation
* `docs/`: Project-level documentation

---

## 🔧 Examples

### Local Companion

```r
agent <- XAgent$new("Xiaowei", list(...))
agent$set_config("tg")
agent$run()
```

### News Reader

```r
agent <- NewsReaderAgent$new("Zelina", list(...))
agent$set_config("fred")
df <- agent$fetch_fred_series("GDP")
```

---

## 📚 Documentation

* 📄 [Agent Architecture](docs/agent_architecture.md)
* 📂 [Function Index](docs/function_index.md)

---

## ✍️ Author

Created by Oliver Lee

---

## 🧩 Future Work

* Add SQLite or Redis support for memory
* Multi-agent collaboration
* Web or Shiny-based frontend

---

## 📜 License

MIT License
