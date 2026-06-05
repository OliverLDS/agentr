# agentr

`agentr` is an R package for specifying, reviewing, and scaffolding agentic AI
systems. It standardizes workflow, memory, knowledge, interface, and review
artifacts so a human or coding assistant can inspect an existing project, infer
design specs, render review HTML, and turn approved specs back into executable
code.

The package emphasizes cognitive design artifacts such as memory and knowledge,
but it is not limited to a cognitive layer. A `WorkflowSpec` can describe the
full task system: deterministic scripts, external tools, human decision gates,
external LLM steps, data interfaces, and implementation hints. `agentr` remains
a scaffolding/specification/review package, not the runtime execution engine for
those systems.

Version `0.2.7.3` refreshes the README/package framing around specification,
review, and coding-assistant scaffolding, and removes stale manuscript assets.
`agentr` can package workflow graphs, memory schemas, narrative knowledge,
graph knowledge, proposal states, and structured feedback schema into one
offline review page while remaining the design and scaffolding layer, not the
transport or execution layer.

## Scope

`agentr` keeps:

- task-local spec conventions for workflow, memory, knowledge, state, interface, and review artifacts
- YAML, JSON, and RDS/R6 serialization helpers for different review and automation boundaries
- review HTML rendering for workflow graphs, memory schemas, graph knowledge, proposal state, and structured feedback
- coding-assistant guidance for inferring specs from existing code and constructing code from approved specs
- proposal-state helpers for workflow, agent, memory, narrative knowledge, and graph knowledge review loops
- constrained prompt and action bridges for manual LLM workflows
- R helper classes such as `AgentSpec`, `KnowledgeSpec`, `MemorySpec`, `WorkflowProposalState`, and `DesignReviewSpec`
- optional node-labeling helpers, including the current RWM/PG/AE/LA/IAC capability ontology

`agentr` does not keep:

- provider-specific LLM API clients
- email, Telegram, or X communication backends
- domain-specific trading or data-collection agents
- a full execution engine

`agentr` is primarily a scaffolding and specification layer. A common
deployment pattern is a cold-start orchestrated loop:

```text
zsh orchestrator
-> loads YAML/JSON/RDS specs or state from the project folder
-> calls node scripts, external tools, or external LLM steps
-> reads and writes task-local data files
-> saves revised state or trace artifacts
-> exits
```

R6 remains useful because it gives validated design objects, clean methods, and
persistence boundaries. It is one supported representation, not the only or
dominant representation. For most project-level agentic systems, editable YAML
is the human-facing source of truth, JSON is the interchange format for
LLM/browser/CLI boundaries, and RDS/R6 is useful for R-native helpers, proposal
state, or cache artifacts.

## Installation

```r
remotes::install_github("OliverLDS/agentr")
```

## Core Objects

The package exposes R helpers and R6 classes for users who want validated
objects inside R. These objects mirror the task-local specs, but they do not
require the final agentic system to run as one long-lived R process.

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

The current public surface includes:

- `WorkflowProposal` for one persisted proposal and its lifecycle
- `WorkflowProposalState` for approved workflow plus proposal history
- `AgentSpec` for the approved agent design
- `KnowledgeSpec` for curated domain knowledge, rules, heuristics, and exceptions
- `MemorySpec` for context, semantic, episodic, and procedural memory schema
- `MemoryProposalState` and `KnowledgeGraphProposalState` for reviewable memory and graph-knowledge design loops
- `DesignReviewSpec` for review-layer data bundles, standalone HTML export, and structured feedback contracts
- `SubsystemSpec` for optional diagnostic node-labeling metadata
- `AgentScaffoldState` for approved agent-design state
- `IntelligentAgent` for the runtime-oriented abstraction

## Lifecycle Stages

`agentr` supports two complementary evolution paths.

The repository-based path is the first-class path when a coding assistant can
inspect the whole project:

```text
existing code and docs
-> coding assistant infers task-local YAML specs
-> review HTML exposes workflow, memory, knowledge, and schema structure
-> human or coding assistant edits specs and code
-> Git records the evolution of both specs and implementation
```

The proposal-state path remains useful when Git is not the right versioning
boundary, when a manual LLM workflow is preferred, or when revisions need to be
reviewed before touching approved specs:

```text
initial draft
-> proposal object
-> discussion or structured feedback
-> revision
-> explicit approval
```

Both paths use the same underlying design idea: keep specs descriptive,
reviewable, and separate from runtime execution.

For the documentation hub, start with [docs/index.md](docs/index.md). For
current figure guidance based on package-native renderers, see
[docs/conceptual_figures.md](docs/conceptual_figures.md).

For repository-based scaffolding with coding assistants, see
[docs/coding_assistant_scaffolding.md](docs/coding_assistant_scaffolding.md).
This path treats task-local YAML specs and Git history as the main review
record when executable code and specs evolve together.

## WorkflowSpec, KnowledgeSpec, And MemorySpec

`WorkflowSpec` captures procedural knowledge: what the agent does, in what order, with what review gates and implementation hints.

`KnowledgeSpec` captures epistemic and domain knowledge: what the agent should know, assume, treat as an exception, or use as a heuristic while executing or reviewing workflow steps.

Knowledge can be represented as narrative items, first-class graph knowledge, or future vector references. A knowledge graph stores typed relationships directly, for example:

```text
ACT-R --is_a--> cognitive architecture
BDI --has_component--> Belief
ReAct --implements_part_of--> observe-decide-act
```

`MemorySpec` captures the agent's memory schema: which fields hold current context, approved concepts, past events, and reusable procedures; how those fields update; and which fields persist across cold-start runs.

Subsystem labels are optional diagnostic annotations for workflow nodes, not a
first-class execution spec. A task can still be described, reviewed, and
implemented without them. Labels are useful because they help humans inspect
capability coverage, color workflow graphs, and compare designs under a chosen
ontology.

The current built-in ontology uses the five-module vocabulary from Lamo
Castrillo, Gidey, Lenz, and Knoll (2025), "Fundamentals of Building Autonomous
LLM Agents" (`https://arxiv.org/abs/2510.09244v1`):

- `RWM` means Reasoning & World Model
- `PG` means Perception & Grounding
- `AE` means Action Execution
- `LA` means Learning & Adaptation
- `IAC` means Inter-Agent Communication

Future ontologies can label the same workflow nodes differently based on other
research frameworks or application-specific review needs. Workflow, memory,
knowledge, state, and interface specs are the behavior-shaping artifacts;
subsystem labels are a review and visualization aid.

Early-stage agents often still have human-owned reasoning nodes. `agentr` supports that transitional state by letting workflow nodes carry ownership, automation status, and trace requirements while tacit knowledge is progressively codified into `KnowledgeSpec`.

Memory schemas and graph knowledge follow the same proposal-oriented pattern as workflows:

```text
initial model draft
-> proposal object
-> human discussion or structured feedback
-> revision
-> approval into active spec
```

## Workspace CLI Lifecycle

For manual LLM workflows, `agentr` can create a generic design workspace outside the package:

```r
workspace <- "my_agent_design"
init_agentr_workspace(workspace)

build_initial_spec_prompt(
  workspace,
  target = "workflow",
  comment = "Design a workflow for reading a paper and extracting schema fields."
)

# Send prompts/initial/workflow_initial_prompt.md to an external LLM,
# save the JSON response, then apply it into proposal state.
apply_initial_spec_message(
  workspace,
  target = "workflow",
  message = file.path(workspace, "responses", "workflow_initial.json")
)
```

The same workspace helpers support `workflow`, `agent`, `memory`, and `knowledge` prompt/response loops. Revision application stores proposal state; approval is a separate explicit boundary:

```r
build_revision_prompt(workspace, target = "memory", comment = "Separate lifecycle state from task state.")
apply_revision_message(workspace, target = "memory", message = file.path(workspace, "responses", "memory_revision.json"))
list_workspace_proposals(workspace, type = "memory")
approve_workspace_proposal(workspace, type = "memory", proposal_id = "memory_proposal_1")
```

Workflow node details can be revised without changing the approved top-level workflow immediately. The response is stored as a workflow proposal until explicitly approved:

```r
build_revision_prompt(
  workspace,
  target = "workflow",
  node_id = "node_interpret",
  comment = "Add input/output schemas and a nested workflow for this node."
)

apply_node_detail_message(
  workspace,
  node_id = "node_interpret",
  message = file.path(workspace, "responses", "node_interpret_detail.json")
)
```

The CLI wrapper in `inst/scripts/agentr-cli.R` exposes the same lifecycle for shell use while remaining a scaffolding utility, not an execution engine. See [docs/workspace_cli_lifecycle.md](docs/workspace_cli_lifecycle.md).

## Coding Assistant And Interactive Scaffolding

For project-based work, the preferred loop is to give a coding assistant the
task folder, the `agentr` guidance docs, and the current specs. The assistant
can infer or revise `workflow_spec.yaml`, `memory_spec.yaml`,
`knowledge_spec.yaml`, render `review.html`, and then implement or patch code
against the approved specs. This is more grounded than a pure discussion loop
because the assistant can inspect actual scripts, traces, docs, and Git
history.

For manual or proposal-oriented work, use `Scaffolder` plus the constrained LLM
bridge to evaluate tasks, label workflow ownership, apply optional subsystem
annotations, and build or edit workflow structure.

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

You can also attach curated knowledge directly to an agent design:

```r
knowledge_spec <- KnowledgeSpec$new(items = list(
  list(
    id = "ki_yoy_macro_001",
    type = "heuristic",
    raw_statement = "For noisy monthly macro data, YoY is usually better than MoM.",
    normalized_statement = "For noisy monthly macro indicators, YoY is often more suitable than MoM for medium-term interpretation.",
    review = list(status = "approved")
  )
))

memory_spec <- MemorySpec$new(fields = list(
  memory_field(
    id = "current_task_context",
    label = "Current task context",
    memory_type = "context",
    description = "Current dataset, selected paragraph, and active analysis state.",
    schema = list(fields = c("current_dataset", "active_paragraph", "task_state")),
    persistence = "session"
  ),
  memory_field(
    id = "approved_macro_concepts",
    label = "Approved macro concepts",
    memory_type = "semantic",
    description = "Reviewed macro-analysis concepts and charting heuristics.",
    schema = list(fields = c("term", "definition", "source")),
    persistence = "cold_start_rds",
    review = list(status = "approved")
  ),
  memory_field(
    id = "human_chart_decisions",
    label = "Human chart decisions",
    memory_type = "episodic",
    description = "Past human decisions about chart interpretation.",
    schema = list(fields = c("trace_id", "decision", "rationale", "outcome")),
    persistence = "jsonl_trace"
  ),
  memory_field(
    id = "paper_reading_workflow",
    label = "Paper reading workflow",
    memory_type = "procedural",
    description = "Reusable procedure for reading papers and extracting schema fields.",
    schema = list(workflow_ref = "workflow:paper_reading"),
    persistence = "cold_start_rds"
  )
))

agent_spec <- AgentSpec$new(
  task = "Draft a macro-analysis agent",
  agent_name = "macro-agent",
  workflow = reloaded_spec$workflow,
  knowledge_spec = knowledge_spec,
  memory_spec = memory_spec,
  state_spec = list(
    lifecycle_state = list(
      allowed_values = c("idle", "refreshing_data", "drafting_report", "awaiting_review"),
      persistent = TRUE
    ),
    task_state = list(
      fields = c("current_dataset", "latest_report_path", "last_human_decision"),
      persistent = TRUE
    )
  ),
  interface_spec = list(
    files = list(
      inputs = c("data/macro/latest.csv"),
      outputs = c("reports/macro_summary.md")
    ),
    tools = list(
      r_packages = c("readr", "ggplot2")
    )
  ),
  autonomy_spec = list(
    default_stage = "human_in_loop",
    human_required_for = c("publish_report", "change_chart_rule")
  ),
  metadata = list(runtime_pattern = "cold_start_orchestrated")
)
```

`MemorySpec` is the preferred structured schema for agent memory. `state_spec` remains a backward-compatible plain-list field for existing users and simple designs. `interface_spec` is still a plain structured list for files, tools, APIs, and other external surfaces.

Memory and workflow-node schemas can be rendered as standalone Graphviz assets
for review:

```r
memory_dot <- render_memory_schema_graphviz(memory_spec, as = "dot")
schema_dot <- render_schema_shape_graphviz(
  reloaded_spec$workflow$nodes$output_schema[[1]],
  root_label = "Node output schema",
  as = "dot"
)
```

If you want a visual knowledge map, build a graph spec from `KnowledgeSpec` and render it through the same Graphviz/DiagrammeR path used for workflows:

```r
kg <- knowledge_graph_from_spec(knowledge_spec)
dot <- render_knowledge_graphviz(kg, as = "dot")
# graph <- render_knowledge_graphviz(kg, as = "diagrammer")
# svg <- render_knowledge_graphviz(kg, as = "svg")
```

`knowledge_graph_from_spec()` creates a projection graph from narrative knowledge items. To author graph knowledge directly, build an `agentr_knowledge_graph_spec`:

```r
kg <- new_knowledge_graph_spec(metadata = list(graph_mode = "curated"))
kg <- add_knowledge_graph_node(
  kg,
  id = "act_r",
  label = "ACT-R",
  node_type = "concept",
  memory_type = "semantic",
  review = list(status = "approved")
)
kg <- add_knowledge_graph_node(
  kg,
  id = "cognitive_architecture",
  label = "cognitive architecture",
  node_type = "concept",
  memory_type = "semantic"
)
kg <- add_knowledge_graph_edge(
  kg,
  from = "act_r",
  to = "cognitive_architecture",
  relation = "is_a",
  relation_type = "is_a",
  memory_type = "semantic",
  confidence = 0.95,
  review = list(status = "approved")
)

svg <- render_knowledge_graphviz(kg, as = "svg")
writeLines(svg, "knowledge_graph.svg")
```

For memory and graph knowledge review loops, use the proposal states and constrained message handlers:

```r
memory_state <- MemoryProposalState$new()
memory_prompt <- build_memory_schema_prompt(
  context = "Design memory for a paper-reading agent."
)
# external model returns constrained JSON
# memory_state <- apply_memory_message(memory_state, model_json)

graph_state <- KnowledgeGraphProposalState$new()
graph_prompt <- build_knowledge_graph_extraction_prompt(
  context = "ACT-R is a cognitive architecture."
)
# graph_state <- apply_knowledge_graph_message(graph_state, model_json)
```

For a future JS/HTML review layer, package the current design and proposal states into a structured review bundle:

```r
review <- build_design_review_data(
  agent_spec,
  memory_state = memory_state,
  graph_state = graph_state
)

bundle <- review$to_list()
export_design_review_html(review, "agent_design_review.html")

feedback <- design_feedback_item(
  target = "memory_schema",
  target_id = "current_task_context",
  field = "agent.memory.state",
  issue_type = "unclear",
  issue = "State names are unclear.",
  suggestion = "Separate lifecycle_state from task_state.",
  severity = "medium"
)

preview_design_feedback(scaffolder, feedback)
apply_design_feedback(scaffolder, feedback)
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

`agentr` provides a constrained bridge for letting an external LLM reason about scaffolding and agent-design actions without exposing arbitrary code execution.

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

Once the workflow is mature enough, you can generate a second-stage
implementation-planning prompt for a coding assistant:

```r
implementation_prompt <- build_implementation_prompt(
  scaffolder,
  language = "R",
  format = "markdown",
  target_agent = "coding_assistant",
  runtime = "R package",
  constraints = c("Prefer testthat", "Keep changes modular")
)
```

If you want the design prompt to include optional capability labels alongside
the workflow design, use:

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
- `owner`
- `automation_status`
- `knowledge_refs`
- `subworkflow_ref`
- `input_schema`
- `output_schema`
- `nested_workflow`

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
save_workflow_spec(dispatch$workflow_after, "workflow_spec.yaml")
spec <- load_workflow_spec("workflow_spec.yaml")
```

## Task Families

A workspace can represent a coherent family of related tasks rather than a
single narrow task. In that case, use a root task-family workflow whose nodes
are child tasks, and attach each detailed child workflow through
`subworkflow_ref` or `nested_workflow`.

```r
family <- new_task_family_workflow(
  id = "research_publication",
  label = "Research publication maintenance",
  objective = "Coordinate related publication-maintenance tasks."
)

family <- add_child_task_node(
  family,
    child_task_node(
      id = "task_blog_article",
      label = "Write a Cognaptus blog article",
    subworkflow_ref = "docs/workflow_spec.yaml"
    ),
  tags = c("publication", "blog")
)
```

Root-level edges should be used only for real dependencies among child tasks.
Independent child tasks can share one workspace without forcing artificial
edges.

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
