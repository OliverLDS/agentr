# agentr: Modular AI Agents in R

**agentr** is a lightweight, modular R framework for building intelligent agents with identity, memory, emotion, and LLM integration.
It is designed for **automation**, **experimentation**, and **integration** with your existing R trading/data pipelines.
Agents can run as local companions, connect to chat platforms, or act as domain-specific bots using other packages like [`okxr`](https://github.com/OliverLDS/okxr), [`binxr`](https://github.com/OliverLDS/binxr), [`strategyr`](https://github.com/OliverLDS/strategyr), and [`tradesimr`](https://github.com/OliverLDS/tradesimr).

---

## 🚀 Features

* **R6-Based Modular Design** – extendable and testable components
* **Mind State** – identity, personality, beliefs, goals, memory
* **Emotion Engine** – evolving intensity, decay, blending, human-readable descriptions
* **Multi-Channel I/O** – Telegram, email, local text/logs
* **LLM Integration** – works with Groq, Gemini (easily extendable to OpenAI, Anthropic, etc.)
* **Prompt Composer** – converts structured history into LLM-ready prompts
* **Tool Configuration** – ready-to-use hooks for FRED, Binance, AlphaVantage, RSS feeds
* **Seamless Integration** – designed to plug into trading/data agents powered by your other packages

---

## 🧠 Core Concepts

**Agent = Identity + Tools + Memory + Logic**

* `Agent`: Core R6 class with default FSM (finite state machine) and messaging flow
* `NewsReaderAgent`: Example subclass with FRED, RSS, Binance integration
* `mind_state`: Agent’s internal state, including:

  * `identity`, `personality`, `tone_guideline`
  * `emotion_state`: evolving numeric values with natural language summaries
  * `history`: logs, chat records, past actions
  * `tool_config`: API credentials and service settings

📖 For architecture details, see [`docs/agent_architecture.md`](docs/agent_architecture.md)

---

## 🛠️ Installation

```r
# In your R console
library(devtools)
devtools::install_local("path_to/agentr")
```

---

## 🧪 Testing

```r
library(testthat)
testthat::test_package("agentr")
```

---

## 📁 Folder Structure

* `R/` – core agent logic, emotion models, tool wrappers
* `tests/` – unit tests using `testthat`
* `examples/` – example agent workflows (local, Telegram, trading)
* `man/` – auto-generated Rd documentation
* `docs/` – package and architecture documentation

---

## 🔧 Examples

### Local Companion

```r
agent <- agentr::Agent$new("Xiaowei", list(...))
agent$set_config("tg")
agent$run()
```

### News Reader Agent

```r
agent <- agentr::NewsReaderAgent$new("Zelina", list(...))
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

* SQLite/Redis support for persistent memory
* Multi-agent collaboration framework
* Web or Shiny-based interactive frontend

---

## 📌 Version History

* **v0.1.2** (2025-08-15) – Package renamed from **XAgent** to **agentr** to better reflect its nature as an R package for an agentic AI framework.
* **v0.1.1** (2025-07-13) – Added `CryptoTraderAgent` template; integrated [`okxr`](https://github.com/OliverLDS/okxr); memory I/O tools
* **v0.1.0** – Initial release with R6-based modular design for general-purpose AI agents

---

## 📜 License

MIT License
