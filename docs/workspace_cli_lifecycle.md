# Workspace CLI Lifecycle

`agentr` includes generic workspace helpers and a thin CLI wrapper for manual LLM-assisted design loops. The utilities are intentionally workspace-scoped and domain-neutral: they do not contain downstream project names, paths, or task content.

The lifecycle is:

```text
initialize workspace
-> build prompt
-> user sends prompt to an external LLM
-> user saves constrained JSON response
-> agentr applies response into proposal state
-> human reviews, revises, approves, or rejects proposals
-> agentr exports review HTML or implementation handoff prompt
```

This is still scaffolding. The CLI does not execute the approved agent, call tools, place orders, run production jobs, or manage a runtime loop.

## Workspace Layout

`init_agentr_workspace()` creates:

| Directory | Purpose |
| --- | --- |
| `specs/` | Approved design specs such as `agent_spec.rds` |
| `proposal_states/` | Workflow, memory, knowledge, graph, and scaffolder proposal states |
| `prompts/initial/` | Initial prompt files for manual LLM calls |
| `prompts/revision/` | Revision prompt files from current state plus human feedback |
| `prompts/implementation/` | Implementation handoff prompts |
| `responses/` | JSON responses saved from external LLM calls |
| `reviews/` | Standalone design-review HTML |
| `traces/` | Optional decision and reflection traces |
| `handoffs/` | Additional handoff artifacts |

## R Functions

```r
library(agentr)

workspace <- "my_agent_design"
init_agentr_workspace(workspace, comment = "Design workspace for a paper-review agent.")

build_initial_spec_prompt(
  workspace,
  target = "workflow",
  comment = "Design a workflow for reading a paper and extracting schema fields."
)

# User sends prompts/initial/workflow_initial_prompt.md to an external LLM,
# saves the JSON response under responses/workflow_initial.json, then:
apply_initial_spec_message(
  workspace,
  target = "workflow",
  message = file.path(workspace, "responses", "workflow_initial.json")
)
```

Supported initial prompt targets are `workflow`, `agent`, `memory`, and `knowledge`.

Revision prompts use approved/current state plus a human comment:

```r
build_revision_prompt(
  workspace,
  target = "memory",
  comment = "Separate lifecycle state from task-specific state."
)

apply_revision_message(
  workspace,
  target = "memory",
  message = file.path(workspace, "responses", "memory_revision.json")
)
```

Workflow revision responses are previewed and stored as workflow proposals. They do not mutate the approved workflow until an explicit approval call is made.

```r
list_workspace_proposals(workspace, type = "workflow")
approve_workspace_proposal(workspace, type = "workflow", proposal_id = "workflow_proposal_1")
reject_workspace_proposal(workspace, type = "memory", proposal_id = "memory_proposal_2")
```

Review and handoff artifacts are generated from approved specs and available proposal states:

```r
export_workspace_design_review(workspace)
build_workspace_implementation_prompt(workspace, language = "R")
```

## CLI Wrapper

The installed script lives at:

```text
inst/cli/agentr-cli.R
```

It is a thin shell-facing wrapper around the exported R functions.

```sh
Rscript inst/cli/agentr-cli.R --help
Rscript inst/cli/agentr-cli.R init my_agent_design "Generic review workspace"
Rscript inst/cli/agentr-cli.R build-initial-prompt my_agent_design workflow task.txt
Rscript inst/cli/agentr-cli.R apply-initial-message my_agent_design workflow responses/workflow_initial.json
Rscript inst/cli/agentr-cli.R build-revision-prompt my_agent_design knowledge feedback.txt
Rscript inst/cli/agentr-cli.R apply-revision-message my_agent_design knowledge responses/knowledge_revision.json
Rscript inst/cli/agentr-cli.R list-proposals my_agent_design knowledge
Rscript inst/cli/agentr-cli.R approve-proposal my_agent_design knowledge ki_proposal_1
Rscript inst/cli/agentr-cli.R export-review my_agent_design
Rscript inst/cli/agentr-cli.R build-handoff my_agent_design
```

Every command supports `--help` after the command name:

```sh
Rscript inst/cli/agentr-cli.R build-revision-prompt --help
```

## Proposal Boundaries

Approval is an explicit boundary:

- `apply_initial_spec_message()` and `apply_revision_message()` parse and apply constrained JSON actions into proposal state.
- Workflow revisions use `preview_scaffolder_message()` and store a `WorkflowProposal`.
- Memory revisions use `apply_memory_message()` into `MemoryProposalState`.
- Knowledge revisions use `apply_knowledge_message()` into `KnowledgeProposalState`.
- Approved specs are updated only by `approve_workspace_proposal()` or an explicit approved-agent-spec action supported by the scaffolder bridge.

## Renderer Note

The design-review workflow graph now wraps long SVG node labels with `<tspan>` lines and increases node height by wrapped line count. Node IDs remain visible above labels, and edge anchors target the vertical center of each node.
