# Proposal Lifecycle

For proposal and artifact diagrams, see [conceptual_figures.md](conceptual_figures.md) and [manuscript figures](manuscript/figures/index.md).

`agentr` supports proposal-state scaffolding and coding-assistant
scaffolding. This page describes proposal-state scaffolding: candidate specs
are represented as explicit proposal objects before approval. In a repository
workflow, Git history may instead be the primary version record for task-local
YAML specs and code. See [Coding Assistant Scaffolding](coding_assistant_scaffolding.md).

For proposal-state scaffolding, `agentr` separates work into three stages:

1. agent design and workflow elicitation
2. workflow and agent-design proposal review and approval
3. implementation and extraction handoff

## 1. Agent Design And Workflow Elicitation

During elicitation, `Scaffolder` is used to:

- evaluate the task
- recommend sparse subsystems
- select subsystem configs
- label workflow-node subsystem ownership
- discuss open questions
- decompose the task into workflow nodes and edges
- collect review and rule information

At this stage, the active workflow is still the approved working state inside the `Scaffolder`. The higher-level design target is an approved `AgentSpec`, with workflow kept as one nested planning component.

## 2. Proposal Review And Approval

All proposal paths preserve one boundary: applying or previewing a model
response does not silently replace the approved spec. Promotion requires an
explicit approval operation.

### Workflow proposals

When a model or human suggests a new workflow shape, use `preview_scaffolder_message()`, `Scaffolder$propose_workflow()`, or `WorkflowProposal$new()` to create a proposal without mutating the live workflow.

Proposal lifecycle statuses are:

- `pending`
- `under_discussion`
- `approved`
- `superseded`
- `rejected`

Key behavior:

- preview creates a stored proposal while leaving the live workflow unchanged
- discussion moves a pending proposal into `under_discussion`
- approval promotes the proposal workflow into the live approved workflow
- approving a newer proposal supersedes older active proposals
- approved proposals are not reopened by direct discussion

When a model or human suggests a higher-level agent design, use `Scaffolder$propose_agent_spec()` to create a draft agent-spec proposal without mutating the approved agent design.

Agent-spec proposal lifecycle statuses are:

- `draft`
- `under_discussion`
- `approved`
- `superseded`
- `rejected`

Key behavior:

- a draft agent-spec proposal can be linked to a workflow proposal id
- discussion moves a draft agent-spec proposal into `under_discussion`
- approval promotes the proposal agent spec into the live approved agent design
- approval can also approve the linked workflow proposal first when the two are meant to advance together
- approved agent-spec proposals are not reopened by direct discussion

### Memory proposals

`MemoryProposal` and `MemoryProposalState` manage candidate memory schemas.
Use `build_memory_schema_prompt()` for an initial draft and
`build_memory_revision_prompt()` for human-comment-driven revisions. Apply
constrained messages with `preview_memory_message()` or
`apply_memory_message()`.

Memory proposals use:

- `pending`
- `under_discussion`
- `approved`
- `superseded`
- `rejected`

### Narrative knowledge proposals

`KnowledgeProposal` and `KnowledgeProposalState` manage curated narrative
knowledge items. Each item retains its raw statement, normalized statement,
scope, conditions, exceptions, provenance, review metadata, and conflict
reports when relevant.

Use:

- `build_knowledge_elicitation_prompt()`
- `build_knowledge_normalization_prompt()`
- `build_knowledge_conflict_check_prompt()`
- `build_knowledge_design_prompt()`
- `preview_knowledge_message()`
- `apply_knowledge_message()`

### Graph-knowledge proposals

`KnowledgeGraphProposal` and `KnowledgeGraphProposalState` manage candidate
graph nodes and typed relationships as first-class knowledge. Use:

- `build_knowledge_graph_extraction_prompt()`
- `build_knowledge_graph_revision_prompt()`
- `preview_knowledge_graph_message()`
- `apply_knowledge_graph_message()`

Memory, narrative-knowledge, and graph-knowledge proposals use the same core
statuses as workflow proposals: `pending`, `under_discussion`, `approved`,
`superseded`, and `rejected`.

## 3. Implementation And Extraction Handoff

Once a workflow is approved, use:

- `build_agent_design_prompt()` to reason about subsystem-first agent design
- `build_implementation_prompt()` to hand the approved agent design or approved workflow to a coding agent
- `build_workflow_extraction_prompt()` to infer a workflow from existing code before preview and approval
- `build_article_workflow_extraction_prompt()` to infer workflows from article-described cases before preview and approval

Implementation handoff uses approved state only. Pending or discussed proposals do not affect implementation prompts until approval happens.

## Persistence

Workflow proposals can be saved independently of the full `Scaffolder` session:

```r
preview <- preview_scaffolder_message(scaffolder, response_json)
proposal <- scaffolder$get_workflow_proposal(preview$proposal_id)

save_workflow_proposal(proposal, "proposal.rds")
loaded <- load_workflow_proposal("proposal.rds")

validate_workflow_proposal(loaded)
graph_data <- workflow_proposal_graph_data(loaded)
```

You can also export graph data directly from a `Scaffolder` plus proposal id:

```r
graph_data <- workflow_proposal_graph_data(scaffolder, preview$proposal_id)
```

If you want to work with proposal state directly, use `WorkflowProposalState`:

```r
state <- WorkflowProposalState$new(
  approved_workflow = scaffolder$workflow_spec()
)
state$add_proposal(proposal)
latest <- state$latest_proposal()
```

If you want to approve the higher-level agent design, use the agent-spec path:

```r
scaffolder$recommend_subsystems()
scaffolder$select_subsystems(c("pg", "ae"))
scaffolder$label_workflow_subsystems(list(
  node_1 = c("pg"),
  node_2 = c("ae")
))

agent_spec <- scaffolder$approve_agent_spec(
  agent_name = "release-agent",
  summary = "Sparse planner/executor"
)
```

If you want a proposal-oriented design loop before final approval, use:

```r
design_proposal <- scaffolder$propose_agent_spec(
  workflow_proposal_id = preview$proposal_id,
  agent_name = "release-agent",
  summary = "Draft release-agent design"
)

scaffolder$discuss_agent_spec_proposal(
  design_proposal$id,
  "Keep the agent sparse and preserve human approval gates."
)

approved_spec <- scaffolder$approve_agent_spec_proposal(design_proposal$id)
```

For a workspace-scoped manual LLM loop, use the helpers described in
[Workspace CLI Lifecycle](workspace_cli_lifecycle.md). The workspace stores
proposal-state artifacts and updates approved specs only through
`approve_workspace_proposal()`.
