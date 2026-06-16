# Full-Stack Task Spec Inference Wrapper

This wrapper describes how a coding assistant should infer `agentr` specs for a
whole workstation or task project. Spec-specific shape rules live in separate
guides so a project can use a custom wrapper while still reusing the individual
spec inference contracts.

Use this wrapper when the user asks for a full task or workstation inference.
Use the focused guides when the user asks for only one spec.

Spec guides:

- [WorkflowSpec inference](spec_inference/workflow_spec.md)
- [MemorySpec inference](spec_inference/memory_spec.md)
- [KnowledgeSpec inference](spec_inference/knowledge_spec.md)
- [Affective state inference](spec_inference/affective_spec.md)

For package-level framing, see `../../docs/coding_assistant_scaffolding.md`.

## Expected Task Folder Shape

A task folder may be sparse. Use the files that exist instead of assuming a
complete framework layout.

Preferred shape:

```text
tasks/<task_id>/
|-- run_<task_id>.sh
|-- docs/
|   |-- README.md
|   |-- workflow_spec.yaml
|   |-- memory_spec.yaml
|   |-- knowledge_spec.yaml
|   |-- review.html
|   `-- inference_notes.md
|-- nodes/
|   |-- executable_node.R
|   |-- executable_node.sh
|   `-- subworkflow_node/
|       |-- run_subworkflow_node.sh
|       |-- docs/
|       |   |-- workflow_spec.yaml
|       |   `-- review.html
|       `-- resources/
|-- config/
|-- resources/
|-- state/
|-- cache/
`-- ...
```

The editable source of truth should be YAML specs under `docs/`. JSON can be
used for machine interchange or caches, and `.rds` can be used as a binary R
object cache under `cache/`, but do not keep multiple canonical spec formats.

Common variants:

- Orchestrator scripts may live outside the task folder, such as
  `orchestrators/run_workflow_task_name.sh`.
- Node scripts may be R, shell, Python, or another local script format.
- Documentation may be partial or absent.
- State may be `.rds`, `.json`, `.jsonl`, `.tsv`, `.csv`, or plain files.
- Resource folders may contain prompts, templates, schemas, fixtures, images,
  or configuration files.
- Older task folders may contain backward-compatible documentation names such
  as `agentr-workflow-spec.md`, `workflow_proposed_manually.md`, or other
  task-specific notes. Read those files when present, but prefer the canonical
  generated spec names under `docs/`.

Rule for `nodes/`:

- A file under `nodes/` is an executable node.
- A directory under `nodes/` is a subworkflow node.
- A subworkflow node should contain its own `run_<node_id>.sh`, `docs/`, and
  `resources/` when needed.

Supported nesting for now:

```text
tasks/<task_id>/
tasks/<task_id>/nodes/<subworkflow_node_id>/
```

Do not create deeper task nesting unless the user explicitly requests it. If
the code appears deeper than one node-folder subworkflow level, summarize the
deeper behavior inside the nearest subworkflow spec and add a review note.

## Inference Order

Use this order when reconstructing a task design:

1. Read the orchestrator first when present.
2. Read task documentation next.
3. Read node scripts to clarify inputs, outputs, side effects, and error rules.
4. Read resource and state files only when they explain task semantics.
5. Infer specs from observed code paths and documented behavior.

The orchestrator is usually the best source for workflow order, branching,
loops, failure handling, and side effects. Node scripts are usually the best
source for schema details and local state updates.

## Which Specs To Infer

Always consider `WorkflowSpec` when the task has identifiable steps,
dependencies, branches, gates, or subworkflows. See
[WorkflowSpec inference](spec_inference/workflow_spec.md).

Infer `MemorySpec` only when the workflow contains memory/data nodes, memory
references, persistent state updates, or clear code evidence that state carried
across runs shapes behavior. See
[MemorySpec inference](spec_inference/memory_spec.md).

Infer narrative `KnowledgeSpec` only when the workflow contains knowledge/data
nodes, `knowledge_refs`, prompt retrieval of rules or examples, or clear code
evidence that reusable developer-supplied knowledge shapes behavior. See
[KnowledgeSpec inference](spec_inference/knowledge_spec.md).

Infer affective state only for companion, tutoring, coaching, persona,
relationship-oriented, or other long-running agents where durable affective
continuity shapes behavior. See
[Affective state inference](spec_inference/affective_spec.md). Most task agents
do not need affective state.

Do not infer `memory_spec.yaml` or `knowledge_spec.yaml` merely because the
task could theoretically use memory or knowledge. The workflow must show a
resource node, reference, retrieval path, update path, or validation dependency
that makes the spec behavior-shaping.

Do not infer affective state merely because the task uses an LLM or has a
friendly tone. The workflow or docs must show persistent persona, relational
state, affective dimensions, or an update path that makes affect
behavior-shaping.

When explicit entity-relation knowledge or memory is useful, store it as a
`graph:` representation inside `knowledge_spec.yaml` or `memory_spec.yaml`.
Do not create a separate `knowledge_graph_spec.yaml`.

## File Naming Conventions

Generated specs should live with the concrete task, not inside the `agentr`
package source tree. The default target is the task-local `docs/` directory:

```text
tasks/<task_id>/docs/
|-- workflow_spec.yaml
|-- memory_spec.yaml
|-- knowledge_spec.yaml
|-- review.html
`-- inference_notes.md
```

Use these names unless the workspace already has a stronger convention:

- `tasks/<task_id>/docs/workflow_spec.yaml`
- `tasks/<task_id>/docs/memory_spec.yaml`
- `tasks/<task_id>/docs/knowledge_spec.yaml`
- `tasks/<task_id>/docs/review.html`
- `tasks/<task_id>/docs/inference_notes.md`
- `tasks/<task_id>/nodes/<subworkflow_node_id>/docs/workflow_spec.yaml`
- `tasks/<task_id>/nodes/<subworkflow_node_id>/docs/review.html`

Use stable ids in snake case. Avoid dates in canonical spec filenames unless
the file is an explicit snapshot.

Do not keep `.rds` as the canonical task spec format. If a task workspace still
contains older `.rds` or `.json` artifacts, convert them to YAML when the spec
is intended for manual review and treat the YAML files as the source of truth.
Use a strict YAML subset: no anchors, no custom tags, and explicit arrays for
schema-array fields such as `knowledge_refs` and JSON-schema `required`.

Preserve existing task specs and docs unless the user explicitly asks for
regeneration. When behavior is uncertain, write the uncertainty to
`docs/inference_notes.md` instead of silently overwriting existing artifacts.

## Workspace Path Configuration

- Load task-root path constants from `knowledge/agent_paths.json` when the task
  workspace provides it.
- Prefer the root `zsh` orchestrator to export those paths into environment
  variables for node scripts.
- Pass paths through environment variables or CLI args.
- Do not create a shared path-helper package just to load task paths.
- Do not resurrect `shared_scripts` only for path loading.
- Do not treat `knowledge/agent_paths.json` as `MemorySpec`; it is curated
  workspace configuration, not agent-written memory.

## Rendering Preview HTML

Prefer the package helper when rendering task-local specs. It loads
`workflow_spec.yaml` plus optional `memory_spec.yaml`, `knowledge_spec.yaml`,
when present:

```r
library(agentr)

render_task_preview(
  "tasks/write_new_blog_article",
  graph_layout = "process",
  edge_style = "orthogonal"
)
```

To render all task previews in a workspace:

```r
render_task_previews(
  root = ".",
  tasks_dir = "tasks",
  graph_layout = "process",
  edge_style = "orthogonal"
)
```

The installed package also ships a thin script wrapper:

```sh
zsh "$(Rscript -e 'cat(system.file("scripts/render_task_previews.sh", package = "agentr"))')" \
  --root . \
  --tasks-dir tasks \
  --graph-layout process \
  --edge-style orthogonal
```

## Validation Guidance

When inspecting existing task code, print a terminal warning for each violation
of the code-construction guidance below. Warn when a node script or subworkflow
orchestrator:

- outputs a plain string where the task contract says the node should emit JSON
- does not accept `-h` or `--help`
- omits a `node_id` comment at the start of each block that calls node code
- is being treated as human only because of a default `human_required = TRUE`
  when the observed code path is actually an external script, AutoGUI step, or
  external LLM interaction
- repeats the same semantic external-LLM step in both a parent node and a child
  node when the task code only implements one actual handoff path

Warnings should name the file or script, identify the violated rule, and make
it clear that the issue affects reviewability or machine-readable downstream
use. Do not silently downgrade these issues.

If a task has side effects such as git push, email sending, UI automation, paid
API calls, file deletion, or external publication, do not run the full workflow
for validation unless explicitly approved. Prefer syntax checks, parse checks,
`--help`, spec loading, and no-side-effect modes such as `--summary-only` when
available.

## Runtime Boundary

The coding assistant must not invent runtime behavior beyond the task code.

Allowed:

- Describe observed steps.
- Infer reviewable schemas from code and documented JSON outputs.
- Mark unclear fields as pending, approximate, or human-review required.
- Add `implementation_hint` pointing to the source file or orchestrator logic.
- Use `human_required = TRUE` only when a real human decision or review gate is
  visible.
- Model external scripts, AutoGUI nodes, and external LLM steps as workflow
  nodes with `human_required = FALSE`, then describe the execution surface with
  `owner`, `automation_status`, and `implementation_hint`.

Not allowed:

- Invent new automation not present in the code.
- Claim a task is autonomous when it relies on manual judgment or UI state.
- Mark external runtime steps as human gates when no real human decision is
  taking place.
- Turn a review spec into an execution engine.
- Add side effects, tool calls, or service integrations to the spec.
- Treat generated specs as approved without an explicit approval step.

## Approval Boundary

For task-local specs, approval means human review plus a git commit in the
downstream task workspace. Do not use `agentr` proposal objects unless the user
explicitly asks for structured proposal state.

Generated specs should start as review artifacts. Human review should happen
through `docs/review.html`, `docs/inference_notes.md`, or direct code review.
Once accepted, the user can commit the task-local docs and specs.

## Spec Quality Checklist

Before saving generated specs, check:

- Node ids are stable and readable.
- Every edge references existing node ids.
- The workflow represents task behavior at a reviewable level of detail.
- Inputs, outputs, state files, and side effects are represented when visible.
- Human gates are explicit.
- Memory and knowledge specs are created only when supported by evidence.
- Unknowns are documented as review notes instead of silently filled in.
- The result is descriptive and reviewable, not executable.
