# Coding Assistant Task Spec Inference Guide

This guide describes how a coding assistant should infer `agentr` design specs
from an existing task folder. The goal is to create descriptive, reviewable
design artifacts. Do not convert the task into a new runtime, executor, or
orchestration system.

## Expected Task Folder Shape

A task folder may be sparse. Use the files that exist instead of assuming a
complete framework layout.

Preferred shape:

```text
tasks/<task_id>/
├── run_<task_id>.sh
├── docs/
│   ├── README.md
│   ├── workflow_spec.yaml
│   ├── memory_spec.yaml
│   ├── knowledge_spec.yaml
│   ├── review.html
│   └── inference_notes.md
├── nodes/
│   ├── executable_node.R
│   ├── executable_node.sh
│   └── subworkflow_node/
│       ├── run_subworkflow_node.sh
│       ├── docs/
│       │   ├── workflow_spec.yaml
│       │   └── review.html
│       └── resources/
├── config/
├── resources/
├── state/
├── cache/
└── ...
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

Do not create deeper task nesting unless the user explicitly requests it. If the
code appears deeper than one node-folder subworkflow level, summarize the deeper
behavior inside the nearest subworkflow spec and add a review note.

For parent tasks with subworkflow nodes, set `subworkflow_ref` to the child
workflow spec path:

```text
nodes/<subworkflow_node_id>/docs/workflow_spec.yaml
```

Use `nested_workflow` only when the coding assistant has loaded the child spec and is
preparing a combined parent preview HTML. The file reference remains the
durable link; the embedded workflow is a convenience for review rendering.

## Inference Order

Use this order when reconstructing a task spec:

1. Read the orchestrator first when present.
2. Read task documentation next.
3. Read node scripts to clarify inputs, outputs, side effects, and error rules.
4. Read resource and state files only when they explain task semantics.
5. Infer specs from observed code paths and documented behavior.

The orchestrator is usually the best source for workflow order, branching,
loops, failure handling, and side effects. Node scripts are usually the best
source for schema details and local state updates.

## Inferring WorkflowSpec

Create a `WorkflowSpec` when the task has identifiable steps, dependencies, or
human review points.

Map task code to workflow fields as follows:

| Evidence in code/docs | WorkflowSpec representation |
| --- | --- |
| Script invocation or named stage | `workflow_node(id, label, implementation_hint)` |
| Sequential script calls | `workflow_edge(from, to)` |
| Conditional branch | `rule_spec` and edge `notes` |
| Loop over inputs | Node label/rule describing iteration, not duplicated nodes per item |
| JSON output from a node | `output_schema` |
| CLI args, files, or environment variables | `input_schema` |
| Human judgment or manual review | `human_required = TRUE`, `owner = "human"` |
| Local script/tool action | `human_required = FALSE`, `owner = "script"` or `owner = "external_system"` |
| External LLM or chat-UI step such as ChatGPT | `human_required = FALSE`, `owner = "external_system"`, `automation_status = "llm_assisted"` |
| UI automation, API calls, file writes | `human_required = FALSE`, `automation_status = "rule_assisted"` unless the code shows stronger autonomy |

These richer node fields are expected in current `agentr`:

- `input_schema`
- `output_schema`
- `subworkflow_ref`
- `nested_workflow`

If the installed `agentr` version does not support those fields as first-class
workflow-node columns, store the same information in `rule_spec`,
`implementation_hint`, `review_notes`, `knowledge_refs`, or
`workflow$metadata`. Do not emit constructor calls that fail in the installed
package.

Keep node ids stable, lowercase, and task-scoped:

```r
workflow_node(
  id = "blog_generate_article_prompt",
  label = "Generate blog article prompt",
  implementation_hint = "Uses nodes/generate_blog_article_prompt.R.",
  input_schema = list(type = "object", required = c("arxiv_id")),
  output_schema = list(type = "object", required = c("success", "prompt"))
)
```

Use one workflow node per conceptual step. Do not create a node for every shell
line unless each line is a distinct reviewable unit.

Reserve `human_required = TRUE` for real human decision or review gates only.
Do not mark a node as human just because it is outside the local runtime,
implemented by an external script, driven through AutoGUI, or routed through an
external LLM or chat UI.

External LLM steps are first-class workflow nodes. They belong in the task
workflow even when the concrete implementation is GUI-driven or API-driven. In
the current AutoGUI-oriented pattern, the node label may be `ChatGPT` when that
is the reviewed external step. Other chat UIs or API-backed LLM nodes are also
valid conceptually; only the GUI/API implementation details differ.

## Inferring MemorySpec

Infer a `MemorySpec` only when the task uses persistent state or clearly depends
on state carried across runs.

Good evidence for `MemorySpec`:

- Append-only logs such as `.jsonl`, `.tsv`, or `.csv`.
- Persistent `.rds` files.
- State folders that prevent repeated work.
- Caches used as inputs to later runs.
- Human decisions or review traces that should be reused.

Memory type guidance:

| Memory type | Use when |
| --- | --- |
| `context` | Current run state, active input, current task state |
| `semantic` | Stable facts, concepts, schemas, known entities |
| `episodic` | Past runs, prior user actions, completion logs |
| `procedural` | Reusable process knowledge, workflow rules, task recipes |

Do not infer `MemorySpec` just because a task has local variables. Runtime-local
variables are not persistent memory unless the task saves or reuses them across
runs.

## Inferring KnowledgeSpec

Infer a `KnowledgeSpec` only when the task contains reusable domain knowledge,
rules, exceptions, evaluation criteria, or style preferences.

Good evidence for `KnowledgeSpec`:

- Written domain rules in docs or prompts.
- Reusable heuristics in code comments or templates.
- Exception handling that encodes practitioner judgment.
- Review criteria for generated outputs.
- Stable terminology or ontology used across tasks.

Use narrative knowledge for plain-English rules and graph knowledge for explicit
entity-relation structures.

Supported `KnowledgeSpec` item types:

- `concept`
- `causal_relation`
- `rule`
- `exception`
- `heuristic`
- `evaluation_criterion`
- `domain_constraint`
- `style_preference`
- `risk_warning`

Example narrative item:

```r
list(
  id = "ki_macro_yoy_001",
  type = "heuristic",
  raw_statement = "For noisy monthly macro indicators, YoY is often clearer than MoM.",
  normalized_statement = "For noisy monthly macro indicators, year-over-year transformation is often more suitable for medium-term interpretation than month-over-month change.",
  domain = "macro_analysis",
  review = list(status = "pending")
)
```

Do not invent domain rules that are not visible in the task code, docs, prompts,
or user-provided context.

## File Naming Conventions

Generated specs should live with the concrete task, not inside the `agentr`
package source tree. The default target is the task-local `docs/` directory.

Recommended task-local layout:

```text
tasks/<task_id>/docs/
├── workflow_spec.yaml
├── memory_spec.yaml
├── knowledge_spec.yaml
├── review.html
└── inference_notes.md
```

Use these names unless the workspace already has a stronger convention:

- `tasks/<task_id>/docs/workflow_spec.yaml`
- `tasks/<task_id>/docs/memory_spec.yaml`
- `tasks/<task_id>/docs/knowledge_spec.yaml`
- `tasks/<task_id>/docs/review.html`
- `tasks/<task_id>/docs/inference_notes.md`
- `tasks/<task_id>/nodes/<subworkflow_node_id>/docs/workflow_spec.yaml`
- `tasks/<task_id>/nodes/<subworkflow_node_id>/docs/review.html`

Use stable ids in snake case. Avoid dates in canonical spec filenames unless the
file is an explicit snapshot.

Do not keep `.rds` as the canonical task spec format. If a task workspace still
contains older `.rds` or `.json` artifacts, convert them to YAML when the spec
is intended for manual review and treat the YAML files as the source of truth.
Use a strict YAML subset: no anchors, no custom tags, and explicit arrays for
schema-array fields such as `knowledge_refs` and JSON-schema `required`.

Preserve existing task specs and docs unless the user explicitly asks for
regeneration. When behavior is uncertain, write the uncertainty to
`docs/inference_notes.md` instead of silently overwriting existing artifacts.

Path memory guidance:

- Load task-root path constants from `memory/agent_paths.json` when the task
  workspace provides it.
- Prefer the root `zsh` orchestrator to export those paths into environment
  variables for node scripts.
- Pass paths through environment variables or CLI args.
- Do not create a shared path-helper package just to load task paths.
- Do not resurrect `shared_scripts` only for path loading.

## Rendering Preview HTML

Render one task:

```r
library(agentr)

task_dir <- "tasks/write_new_blog_article"
docs_dir <- file.path(task_dir, "docs")
workflow <- load_workflow_spec_yaml(file.path(docs_dir, "workflow_spec.yaml"))

export_design_review_html(
  workflow,
  path = file.path(docs_dir, "review.html"),
  title = "Cognaptus new blog article review",
  graph_layout = "process",
  edge_style = "orthogonal"
)
```

Render a task with one-level subworkflow nodes:

```r
library(agentr)

task_dir <- "tasks/literature_maintenance"
docs_dir <- file.path(task_dir, "docs")
workflow <- load_workflow_spec_yaml(file.path(docs_dir, "workflow_spec.yaml"))

export_design_review_html(
  workflow,
  path = file.path(docs_dir, "review.html"),
  title = "Literature maintenance review",
  graph_layout = "grid",
  edge_style = "straight"
)
```

For task/subworkflow previews, parent nodes should use `subworkflow_ref` and
may include `nested_workflow`. The review page can then show task labels as
selectable previews while keeping node details in the side panel. In practice,
render `review.html` from the editable YAML spec and load that YAML into R
objects only for rendering.

## Task-Family Preview

Task-family review is optional and should be used only when the user asks to
group multiple sibling tasks under one family-level objective. The default
inference target is still `tasks/<task_id>/docs/`.

When task-family review is useful, represent the family as a root workflow whose
nodes are child tasks. Keep root-level edges empty unless the child tasks truly
depend on one another.

## Validation Guidance

When inspecting existing task code, print a terminal warning for each violation
of the code-construction guidance below. Warn when a node script or
subworkflow orchestrator:

- outputs a plain string where the task contract says the node should emit JSON
- does not accept `-h` or `--help`
- omits a `node_id` comment at the start of each block that calls node code
- is being treated as human only because of a default `human_required = TRUE`
  when the observed code path is actually an external script, AutoGUI step, or
  external LLM interaction

Warnings should name the file or script, identify the violated rule, and make it
clear that the issue affects reviewability or machine-readable downstream use.
Do not silently downgrade these issues.

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

## Preview Caveat

If generated `review.html` has clickable nodes but node details do not appear,
check whether an installed `agentr` version predates scalar-or-array
normalization for `knowledge_refs`. Current `agentr` renders preview HTML with
array-normalizing JavaScript and normalizes scalar YAML/JSON values during spec
loading.

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
