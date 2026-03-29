# agentr

`agentr` is an R package for the cognitive and human-interaction core of agentic workflows. It represents agent state, preserves a lightweight affective layer, supports human-in-the-loop scaffolding, and generates workflow specifications such as DAG-like plans and implementation-ready structures.

Version `0.1.4` keeps that narrowed scope and adds a machine-readable bridge between scaffolding state and external LLM reasoning. `agentr` remains the core reasoning/scaffolding layer, not the transport or execution layer.

## Scope

`agentr` keeps:

- R6 state objects for cognition and affect
- a minimal `AgentCore` container
- a `Scaffolder` interface for human-guided workflow elicitation
- an LLM-facing prompt and action bridge for scaffolding decisions
- workflow-spec helpers for DAG-like outputs
- terminal scaffolding helpers
- JSON/YAML and object persistence utilities
- prompt helpers tightly coupled to scaffolding logic

`agentr` does not keep:

- provider-specific LLM API clients
- email, Telegram, or X communication backends
- domain-specific trading or data-collection agents
- a full execution engine

## Installation

```r
remotes::install_github("OliverLDS/agentr")
```

## Core Objects

```r
library(agentr)

cognition <- CognitiveState$new()
affect <- AffectiveState$new()
agent <- AgentCore$new(
  id = "release-013",
  name = "Scaffold Agent",
  cognition = cognition,
  affect = affect
)

scaffolder <- agent$attach_scaffolder()$scaffolder
scaffolder$evaluate_task("Refactor an R package for a clean GitHub release.")
scaffolder$decompose_task()

spec <- scaffolder$workflow_spec()
spec
```

## LLM Scaffolding Bridge

`0.1.4` adds a minimal bridge for letting an external LLM reason about scaffolding actions without exposing arbitrary code execution.

```r
prompt <- build_scaffolder_prompt(scaffolder)

message_json <- '{
  "actions": [
    {"method": "decompose_task", "args": {"candidates": ["Clarify goals", "Ask for rules"]}},
    {"method": "ask_human_rule", "args": {"node_id": "node_2"}}
  ]
}'

apply_scaffolder_message(scaffolder, message_json)
```

The LLM is constrained to a validated set of scaffolder methods and must return machine-readable JSON.

## Workflow Output

The workflow object is intentionally simple in `0.1.3` and includes:

- `nodes`
- `edges`
- `confidence`
- `human_required`
- `rule_spec`
- `implementation_hint`

These structures are outputs of scaffolding and reasoning, not hard-coded package workflows.

## Optional Integration

`agentr` can optionally integrate with `inferencer` through lightweight integration metadata, but it no longer duplicates raw provider clients.

## Development

```r
devtools::document()
testthat::test_local()
```

## Author

Oliver Zhou  
<oliver.yxzhou@gmail.com>
