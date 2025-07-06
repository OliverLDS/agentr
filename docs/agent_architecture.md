# XAgent Architecture Overview

## Purpose

**XAgent** is a modular, extensible AI agent framework implemented in R. It is designed to simulate autonomous agents that can:

* Perceive and remember their interactions
* Manage internal mental states
* Interact with users across various channels (Telegram, local, email)
* Query external tools such as LLMs
* Maintain flexible workflows using Finite State Machines (FSMs)

This document explains the conceptual and structural design of XAgent.

---

## Core Concepts

### 1. Agent

An `Agent` is an R6 object with:

* A unique name
* A `mind_state` (a nested list)
* A defined behavior (via methods like `run()`)

### 2. Mind State (`mind_state`)

The agent's internal state. It contains:

* `identity`: description of the agent's role
* `personality`: how the agent speaks or behaves
* `tone_guideline`: stylistic tone
* `history`: stores logs, chats, and channel info
* `emotion_state`: emotional profile
* `current_context`: contains the FSM state
* `tool_config`: stores API keys and file paths
* `timezone`: governs timestamp handling

### 3. FSM State

The field `mind_state$current_context$state` defines the agent's **current mode**, such as:

* "idle"
* "reading"
* "replying"

This supports rule-based workflows (e.g., conditional responses).

### 4. Tool System

Tools provide functionality, such as:

* `query_groq()` / `query_gemini()`
* `send_text_TG()` / `send_email()`
* `fetch_fred_series()`

Configurations are stored in `tool_config`.

### 5. Memory and History

The agent stores both:

* **Logs**: internal notes (via `log()`)
* **Chats**: timestamped conversations

These can be summarized into prompts for LLMs.

---

## Modular Functions

XAgent supports pluggable design. Major components include:

### 📡 Sensors / Fetchers

Fetch and interpret external data:

* `fetch_fred_series()`
* `fetch_binance_klines()`
* `fetch_rss()`

### 💬 Output Channels

Send messages to users:

* `send_text_TG()`
* `send_email()`
* `send_text_local()`

### 🧠 Prompt and LLM Tools

Use LLMs for decision making or generation:

* `compose_prompt_plain()`
* `query_groq()` / `query_gemini()`

### 😶‍🌫️ Emotion Module

Emulates emotional dynamics:

* `define_random_emotion_state()`
* `decay_emotion_state()`
* `describe_emotional_state()`

---

## Extending the Agent

To build new agents (e.g., `NewsReaderAgent`):

* Inherit from `XAgent`
* Override `run()` to customize the workflow
* Add new methods as needed

```r
NewsReaderAgent <- R6::R6Class("NewsReaderAgent", inherit = XAgent,
  public = list(
    run = function() {
      self$fetch_rss("AI")
      self$send_text_TG("Today's AI news fetched.")
    }
  )
)
```

---

## Sample Workflows

### Telegram Workflow

```r
agent$set_config("tg")
agent$set_config("groq")
agent$run()
```

* Reads new messages from Telegram
* Constructs prompt
* Queries LLM
* Sends back answer

### Local Chatbot

```r
agent$set_config("localchat")
agent$local_check_and_reply()
```

* Checks `/tmp/agent_chats.txt`
* Responds locally

---

## Design Philosophy

* ✅ Modular and clear function separation
* ✅ Pluggable configurations
* ✅ Expandable via child classes
* ✅ Suitable for research, prototypes, and bots

---

## Future Directions

* Multimodal input (images, speech)
* Long-term memory persistence and summarization
* GUI or Shiny-based dashboards
* Multi-agent collaboration

---

For full function index, see `docs/function_index.md`.
