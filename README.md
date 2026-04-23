# agentr

`agentr` is an R package for the cognitive and human-interaction core of intelligent-agent scaffolding. It represents agent state, preserves a lightweight affective layer, supports human-in-the-loop scaffolding, and now centers agent-spec design with workflow specifications kept as a nested planning artifact.

Version `0.2.4.3` shifts the public design surface from workflow-first scaffolding toward agent-spec-first scaffolding and adds a proposal-oriented design loop inside `Scaffolder`. `agentr` remains the core reasoning and scaffolding layer, not the transport or execution layer.

## Scope

`agentr` keeps:

- R6 state objects for cognition and affect
- a minimal `AgentCore` container
- public agent-design objects such as `AgentSpec`, `SubsystemSpec`, and `IntelligentAgent`
- a `Scaffolder` interface for human-guided intelligent-agent scaffolding
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

`0.2.4.3` also exposes:

- `WorkflowProposal` for one persisted proposal and its lifecycle
- `WorkflowProposalState` for approved workflow plus proposal history
- `AgentSpec` for the approved agent design
- `SubsystemSpec` for sparse subsystem selection
- `AgentScaffoldState` for approved agent-design state
- `IntelligentAgent` for the runtime-oriented abstraction

## Lifecycle Stages

`agentr` now treats scaffolding work as three explicit stages:

1. agent design and subsystem selection
2. workflow proposal review and approval
3. implementation and extraction handoff

For conceptual diagrams of the transition from human workflow to approved agent design, see [docs/conceptual_figures.md](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/conceptual_figures.md), [docs/figures/index.md](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/index.md), and [docs/tables/index.md](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/tables/index.md).

## Agent Design And Workflow Elicitation

Use `Scaffolder` plus the constrained LLM bridge to evaluate tasks, recommend sparse subsystems, label workflow ownership, and build or edit workflow structure.

```r
scaffolder$evaluate_task("Design a sparse release agent for an R package.")
scaffolder$decompose_task(candidates = c("Plan release", "Execute release"))
scaffolder$recommend_subsystems()
scaffolder$select_subsystems(c("pg", "ae"))
scaffolder$label_workflow_subsystems(list(
  node_1 = c("pg"),
  node_2 = c("ae")
))

agent_spec <- scaffolder$approve_agent_spec(
  agent_name = "release-agent",
  summary = "Sparse planner/executor for package releases."
)

agent_spec$print()
save_agent_spec(agent_spec, "agent_spec.rds")
reloaded_spec <- load_agent_spec("agent_spec.rds")
```

If you want a proposal-oriented design loop before final approval, use the draft agent-spec path:

```r
workflow_preview <- preview_scaffolder_message(scaffolder, response_json)

design_proposal <- scaffolder$propose_agent_spec(
  workflow_proposal_id = workflow_preview$proposal_id,
  agent_name = "release-agent",
  summary = "Draft release-agent design from the previewed workflow"
)

scaffolder$discuss_agent_spec_proposal(
  design_proposal$id,
  "Keep the agent sparse and make publication explicitly human-gated."
)

# Approves the linked workflow proposal first, then the agent design proposal.
approved_spec <- scaffolder$approve_agent_spec_proposal(design_proposal$id)
```

## LLM Scaffolding Bridge

`0.2.4.3` provides a constrained bridge for letting an external LLM reason about scaffolding and agent-design actions without exposing arbitrary code execution.

```r
prompt <- build_scaffolder_prompt(scaffolder)

message_json <- '{
  "actions": [
    {"method": "discuss_task", "args": {"feedback": "The human wants an approval branch.", "source": "human"}},
    {"method": "decompose_task", "args": {"candidates": ["Clarify goals", "Ask for rules"]}},
    {"method": "ask_human_rule", "args": {"node_id": "node_2"}}
  ]
}'

dispatch <- apply_scaffolder_message(scaffolder, message_json)
dispatch$workflow_after
dispatch$human_prompts
```

If you used the Markdown prompt in a chatbox UI and downloaded the model's JSON file, you can pass the file path directly:

```r
dispatch <- apply_scaffolder_message(scaffolder, "response.json")
```

If you want the human to preview a proposed DAG before it becomes the live workflow, use the non-mutating preview path:

```r
preview <- preview_scaffolder_message(scaffolder, response_json)
proposal <- scaffolder$get_workflow_proposal(preview$proposal_id)
graph_data <- workflow_proposal_graph_data(proposal)

# Human decides whether to approve or continue discussion
scaffolder$discuss_workflow_proposal(
  preview$proposal_id,
  "Add a dedicated review checkpoint before publication."
)
# scaffolder$approve_workflow_proposal(preview$proposal_id)
```

Proposal discussion moves a stored proposal from `pending` to `under_discussion`. The live workflow stays unchanged until `approve_workflow_proposal()` is called, and implementation prompts continue to use the approved workflow only.

Agent-design proposals follow a parallel flow: draft first, discussion when needed, then approval. When an agent-spec proposal is linked to a workflow proposal, `approve_agent_spec_proposal()` can approve both in one coherent step.

## Workflow And Agent-Design Proposal Review And Approval

Proposal objects can be saved and reloaded independently of the full `Scaffolder`:

```r
proposal <- scaffolder$get_workflow_proposal(preview$proposal_id)

save_workflow_proposal(proposal, "workflow_proposal.rds")
loaded_proposal <- load_workflow_proposal("workflow_proposal.rds")

validate_workflow_proposal(loaded_proposal)
graph_data <- workflow_proposal_graph_data(loaded_proposal)
```

If you still have the original `Scaffolder`, you can also export graph data directly from the stored proposal id:

```r
graph_data <- workflow_proposal_graph_data(scaffolder, preview$proposal_id)
```

You can also create and manage proposal objects directly:

```r
proposal <- WorkflowProposal$new(
  id = "proposal_manual",
  workflow = scaffolder$workflow_spec(),
  notes = "Manual review branch"
)

proposal$discuss("Needs an explicit publication checkpoint.")
proposal$transition("under_discussion")
```

For the higher-level design loop, `Scaffolder$propose_agent_spec()`, `Scaffolder$discuss_agent_spec_proposal()`, and `Scaffolder$approve_agent_spec_proposal()` provide the same draft-to-approval structure for agent designs.

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

Once the workflow is mature enough, you can generate a second-stage implementation-planning prompt for a coding agent:

```r
implementation_prompt <- build_implementation_prompt(
  scaffolder,
  language = "R",
  format = "markdown",
  target_agent = "codex",
  runtime = "R package",
  constraints = c("Prefer testthat", "Keep changes modular")
)
```

If you want the design prompt to reason about subsystems first and workflow second, use:

```r
agent_design_prompt <- build_agent_design_prompt(
  scaffolder,
  format = "markdown"
)
```

If you already have ad hoc code written by others and want a reasoning model to infer an `agentr`-compatible workflow spec from it, use the workflow-extraction prompt:

```r
extraction_prompt <- build_workflow_extraction_prompt(
  code_context = c(
    "fetch_data <- function() read.csv('latest.csv')",
    "analyze_data <- function(df) summary(df)",
    "write_report <- function(stats) cat('report')"
  ),
  task = "Infer a reporting workflow from existing code",
  language = "R",
  format = "markdown"
)
```

If the source is an article rather than code, use the article extraction prompt:

```r
article_prompt <- build_article_workflow_extraction_prompt(
  article_context = c(
    "The article describes an analyst agent that gathers indicators,",
    "selects suitable charts, asks a human reviewer, and publishes a report."
  ),
  article_title = "Illustrative agentic analysis case",
  extraction_mode = "both",
  format = "markdown"
)
```

Article extraction returns an article-level object with one or more workflows.
Convert it into validated workflow specs with:

```r
article_workflows <- article_workflow_specs_from_json("article_workflows.json")
workflow <- article_workflows[[1]]
graph <- render_workflow_graphviz(workflow, as = "diagrammer")
```

After the reasoning model returns JSON, import it directly with:

```r
workflow <- workflow_spec_from_json(response_json)

# or store it on a scaffolder as a proposal immediately
imported <- import_extracted_workflow(
  response_json,
  scaffolder = scaffolder,
  source = "model"
)
```

To inspect the inferred DAG visually, use the DiagrammeR-oriented renderer:

```r
dot <- render_workflow_graphviz(workflow, as = "dot")
cat(dot)

# Optional backends:
# graph <- render_workflow_graphviz(workflow, as = "diagrammer")
# svg <- render_workflow_graphviz(workflow, as = "svg")
# graph <- plot_workflow_graph(workflow)
```

## Implementation And Extraction Handoff

Implementation prompts are built from the approved workflow only. Previewed or discussed proposals do not affect handoff until they are explicitly approved.

## End-To-End Reasoning Loop

```r
library(agentr)

agent <- AgentCore$new(name = "Scaffold Agent")
scaffolder <- Scaffolder$new(agent = agent)
scaffolder$evaluate_task(
  paste(
    "Conduct economic analysis based on updated data, infer insightful points,",
    "and write a professional report with visualization."
  )
)

# Another realistic online task for the same loop:
# scaffolder$evaluate_task(
#   paste(
#     "Read daily business news, select podcast topics that do not repeat",
#     "recent channel coverage, generate a transcript with the given host roles",
#     "and style, convert it to audio with a TTS model, and release or schedule",
#     "the episode in the podcast channel."
#   )
# )

prompt_json <- build_scaffolder_prompt(scaffolder, format = "json")

# Real reasoning-model call via inferencer
response_json <- inferencer::query_openrouter(prompt_json, max_tokens = 4000)

# Or use a local placeholder during development
reasoner <- function(prompt) {
  '{
    "actions": [
      {
        "method": "discuss_task",
        "args": {
          "feedback": "The workflow should separate data refresh, analysis, visualization, report drafting, and final review.",
          "source": "model"
        }
      },
      {
        "method": "decompose_task",
        "args": {
          "suggestions": {
            "nodes": [
              {"id": "node_1", "label": "Refresh economic data", "confidence": 0.95},
              {"id": "node_2", "label": "Run economic analysis", "depends_on": ["node_1"], "confidence": 0.9},
              {"id": "node_3", "label": "Generate visualization set", "depends_on": ["node_1"], "confidence": 0.85},
              {"id": "node_4", "label": "Draft professional report", "depends_on": ["node_2", "node_3"], "confidence": 0.85},
              {"id": "node_5", "label": "Request human review on narrative and claims", "depends_on": ["node_4"], "confidence": 0.75, "human_required": true}
            ]
          }
        }
      },
      {
        "method": "ask_human_changes",
        "args": {
        }
      }
    ]
  }'
}

# response_json <- reasoner(prompt_json)
dispatch <- apply_scaffolder_message(scaffolder, response_json)

questions <- collect_scaffolder_questions(scaffolder, dispatch)
questions

# Capture free-form human feedback before the next structured update
human_feedback <- terminal_ask_workflow_changes(scaffolder)

if (nzchar(trimws(human_feedback$response))) {
  followup_json <- build_scaffolder_prompt(scaffolder, format = "json")
  followup_response <- inferencer::query_openrouter(followup_json, max_tokens = 4000)
  dispatch <- apply_scaffolder_message(scaffolder, followup_response)
}

dispatch$workflow_after
scaffolder$workflow$metadata$discussion_rounds
```

## Workflow Output

The workflow object is intentionally simple and includes:

- `nodes`
- `edges`
- `confidence`
- `human_required`
- `rule_spec`
- `implementation_hint`
- `review_status`
- `review_notes`
- `review_confidence`

These structures are outputs of scaffolding and reasoning, not hard-coded package workflows.

## DAG Visualization

Workflow specs are directly convertible into DiagrammeR/Graphviz-ready views:

```r
graph_data <- workflow_graph_data(scaffolder)
graph <- plot_workflow_graph(scaffolder)
dot <- render_workflow_graphviz(scaffolder, as = "dot")
```

The returned vertex table includes fields such as `node_label`, `node_shape`, `node_color`, `node_border`, and `low_confidence` to support lightweight styling in external graph packages. For visual rendering, `DiagrammeR` is preferred over base `igraph` plotting because it produces clearer DAG layouts for workflow inspection.

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
