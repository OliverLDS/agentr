# agentr

`agentr` is an R package for the cognitive and human-interaction core of agentic workflows. It represents agent state, preserves a lightweight affective layer, supports human-in-the-loop scaffolding, and generates workflow specifications such as DAG-like plans and implementation-ready structures.

Version `0.1.5` keeps that narrowed scope and hardens the machine-readable bridge between scaffolding state and external LLM reasoning. `agentr` remains the core reasoning/scaffolding layer, not the transport or execution layer.

## Scope

`agentr` keeps:

- R6 state objects for cognition and affect
- a minimal `AgentCore` container
- a `Scaffolder` interface for human-guided workflow elicitation
- an LLM-facing prompt and action bridge for scaffolding decisions
- workflow-spec helpers for DAG-like outputs and persistence
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

`0.1.5` provides a constrained bridge for letting an external LLM reason about scaffolding actions without exposing arbitrary code execution.

```r
prompt <- build_scaffolder_prompt(scaffolder)

message_json <- '{
  "actions": [
    {"method": "decompose_task", "args": {"candidates": ["Clarify goals", "Ask for rules"]}},
    {"method": "ask_human_rule", "args": {"node_id": "node_2"}}
  ]
}'

dispatch <- apply_scaffolder_message(scaffolder, message_json)
dispatch$workflow_after
dispatch$human_prompts
```

The LLM is constrained to a validated set of scaffolder methods and must return machine-readable JSON. The dispatch result is normalized into:

- `applied_actions`
- `workflow_after`
- `human_prompts`
- `errors`

If you want a prompt that a human can paste into a chat UI, request Markdown instead:

```r
prompt_md <- build_scaffolder_prompt(scaffolder, format = "markdown")
cat(prompt_md)
```

If you are calling a model through another package such as `inferencer`, use the JSON format:

```r
prompt_json <- build_scaffolder_prompt(scaffolder, format = "json")
```

## End-To-End Reasoning Loop

```r
library(agentr)

agent <- AgentCore$new(name = "Scaffold Agent")
scaffolder <- Scaffolder$new(agent = agent)
scaffolder$evaluate_task("Design a DAG for onboarding a new analyst.")

prompt_json <- build_scaffolder_prompt(scaffolder, format = "json")

# Placeholder for a reasoning model call handled elsewhere, e.g. inferencer
reasoner <- function(prompt) {
  '{
    "actions": [
      {
        "method": "decompose_task",
        "args": {
          "candidates": [
            "Clarify onboarding goals",
            "Identify required tools",
            "Ask for approval rules",
            "Draft implementation handoff"
          ]
        }
      },
      {
        "method": "ask_human_rule",
        "args": {
          "node_id": "node_3"
        }
      }
    ]
  }'
}

response_json <- reasoner(prompt_json)
dispatch <- apply_scaffolder_message(scaffolder, response_json)

dispatch$workflow_after
collect_scaffolder_questions(scaffolder, dispatch)
```

## Workflow Output

The workflow object is intentionally simple in `0.1.3` and includes:

- `nodes`
- `edges`
- `confidence`
- `human_required`
- `rule_spec`
- `implementation_hint`

These structures are outputs of scaffolding and reasoning, not hard-coded package workflows.

## DAG Visualization

Workflow specs are directly convertible into graph-ready node and edge tables:

```r
graph_data <- workflow_graph_data(scaffolder)

# Example with igraph
# library(igraph)
# g <- graph_from_data_frame(graph_data$edges, vertices = graph_data$vertices)
# plot(g)
```

The returned vertex table includes fields such as `node_label`, `node_shape`, `node_color`, `node_border`, and `low_confidence` to support lightweight styling in external graph packages.

## Workflow Persistence

Workflow specs can be saved and loaded independently of the full agent object:

```r
save_workflow_spec(dispatch$workflow_after, "workflow_spec.rds")
spec <- load_workflow_spec("workflow_spec.rds")
```

## Message Schema

See [`docs/scaffolder_message_schema.md`](docs/scaffolder_message_schema.md) for the machine-readable action contract used by the LLM bridge.

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
