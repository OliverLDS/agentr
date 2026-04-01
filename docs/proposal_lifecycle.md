# Proposal Lifecycle

`agentr` separates scaffolding work into three stages:

1. agent design and workflow elicitation
2. workflow proposal review and approval
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

## 2. Workflow Proposal Review And Approval

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

## 3. Implementation And Extraction Handoff

Once a workflow is approved, use:

- `build_agent_design_prompt()` to reason about subsystem-first agent design
- `build_implementation_prompt()` to hand the approved agent design or approved workflow to a coding agent
- `build_workflow_extraction_prompt()` to infer a workflow from existing code before preview and approval

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
