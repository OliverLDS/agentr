# Coding Assistant Task Code Construction Guide

This guide describes how a coding assistant should implement task code from an approved
`agentr` spec. It is separate from the spec-inference guide, which covers
how to infer specs from existing code and render preview artifacts.

For the package-level framing of coding-assistant scaffolding, see
`../../docs/coding_assistant_scaffolding.md`.

Use this guide when the user already has a task-level or node-level
`agentr` spec and wants the corresponding executable task code created or
refactored.

For the general contract for writing one standardized executable node script,
see [node_script_construction.md](node_script_construction.md).
This task guide focuses on orchestration, task layout, and how node scripts are
assembled into a workflow implementation.

## Core Goal

Generate code that is:

- faithful to the approved spec
- local to the task workspace
- reviewable before execution
- deterministic where practical
- explicit about side effects
- easy to rerun and debug

Do not widen the runtime boundary. The code should implement the described task,
not invent a generic orchestration engine.

## Required Script Contract

Every executable script under a task should support `-h` and `--help`.

This applies to:

- task root orchestrators such as `run_<task_id>.sh`
- node scripts such as `*.R`, `*.sh`, `*.py`, or other executable entrypoints
- orchestrating scripts for node-folder subworkflows

For the detailed single-node script contract, help-text requirements, JSON
output expectations, side-effect visibility, and external node-call rules, use
the shared node-script guide referenced above.

## Task Code Shape

At the workspace root, keep this boundary explicit:

- `memory/`: durable learned or accumulated state produced or updated by the
  virtual agent across runs; writable by agent workflows when the task
  contract allows it.
- `knowledge/`: human-authored imported domain knowledge, rules, references,
  and workspace-level configuration; treated as curated input, not
  agent-writable runtime state.

Within each task folder:

- `state/` and `cache/` are task-level writable memory areas.
- agent workflows may write into `state/` and `cache/` when the task contract
  allows it.

Prefer this structure:

```text
tasks/<task_id>/
├── run_<task_id>.sh
├── docs/
│   ├── workflow_spec.yaml
│   ├── memory_spec.yaml
│   ├── knowledge_spec.yaml
│   ├── review.html
│   └── inference_notes.md
├── nodes/
│   ├── step_one.R
│   ├── step_two.sh
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

Rules:

- files under `nodes/` are executable nodes
- directories under `nodes/` are subworkflow nodes
- a subworkflow node should have its own orchestrator and its own docs when
  the behavior is materially distinct
- do not create deeper nesting unless the user explicitly asks for it

## Script Behavior Principles

### 1. Keep entrypoints thin

The root task orchestrator should:

- load workspace paths
- parse arguments
- set environment variables
- dispatch to node scripts or node-folder subworkflows
- preserve control flow visible in the spec

The root orchestrator should not contain unrelated business logic that belongs in
a node script.

When generating a root orchestrator or any subworkflow orchestrator from a
spec, add a comment containing the `node_id` at the start of each contiguous
block that calls node code. The comment should appear before the first command
in the block so humans can scan workflow structure quickly.

Example:

```bash
# node_id: extract_source_material
python nodes/extract_source_material.py --input "$INPUT" --output "$CACHE_DIR/source.json"

# node_id: build_prompt
Rscript nodes/build_prompt.R --source "$CACHE_DIR/source.json" --output "$CACHE_DIR/prompt.json"
```

Do not hide node calls in unlabeled shell blocks. The `node_id` comment is part
of the review contract.

If a workflow node is implemented through an external LLM surface, keep that
step as a first-class workflow node and make the implementation details explicit
in the surrounding orchestrator comments. When the current implementation uses
AutoGUI against ChatGPT, the workflow may label the external LLM node as
`ChatGPT`; if the UI or API surface changes later, the node concept should stay
in the graph even if the implementation code changes.

When a node is expected to fail as part of normal control flow, do not let
`set -e` terminate the orchestrator before the JSON result is inspected. Capture
that command with an explicit `if ! var="$(... || true)"; then ... fi` pattern,
or otherwise neutralize the exit status long enough to read the node output and
decide the next branch. This is especially important for duplicate checks,
missing-artifact checks, and other gate nodes that intentionally return
non-zero on an expected branch.

Prefer direct data handoff over wrapper envelopes. If a node's real output is
already the JSON document needed by the next step, return that document
directly instead of wrapping it again inside a second JSON object unless there
is a real multi-field contract that justifies the extra layer.

### 2. Prefer local paths and local memory

Use task-local paths, task-local `state/`, and task-local `cache/` unless the
spec explicitly says otherwise.

If workspace-level path configuration exists in `knowledge/agent_paths.json`,
load it in the root orchestrator and export the needed environment variables to
node scripts.

When a task depends on workspace path configuration, make the required keys
explicit in the task docs and related specs. Typical examples are:

- agent/workspace roots such as `zelina_agent_dir`
- task roots such as `<task_id>_task_dir`
- external package roots such as `autogui_root` or `litxr_root`
- project URLs or similar runtime endpoints when the workflow depends on a
  specific external thread, project page, or target surface

Treat `knowledge/agent_paths.json` as configuration that the root orchestrator
resolves once at startup. Node scripts should receive resolved values through
arguments or exported environment variables rather than reopening that
configuration themselves.

Do not create a shared path-helper package just to solve path loading.

When a node writes a task-local trace or state artifact, make that output path
optional when practical and default it under the task's `state/` or `cache/`
tree. Treat missing workspace path configuration as a configuration error, not
as a reason to hardcode a fallback package root inside the node.

Prefer shell-native parsing for simple orchestrator control flow. In shell
orchestrators, use direct `jq` or equivalent shell-native extraction for simple
field reads instead of introducing `Rscript -e` or another inline scripting
layer when the shell can express the control clearly.

### 3. Make side effects visible

If a node writes files, commits git changes, pushes to a remote, sends email,
drives browser UI, uses the clipboard, downloads files, or launches a server,
the script should make that side effect obvious in:

- its usage text
- its JSON output
- its task docs
- its `implementation_hint` in the spec

### 4. Use debug logs for traceability

Emit concise debug logs for major workflow transitions when they help with
reruns and diagnosis. Keep them short, stable, and node-oriented. Prefer logs
that identify the current `node_id` or a nearby step label so humans can follow
control flow without reading the whole script. Debug logs are useful for review
and troubleshooting, but they do not replace the required `node_id` comments in
orchestrators.

Guard the real failure boundary, not an imagined one. Add retries, polling, and
timeout logic around the asynchronous step that actually fails in practice,
rather than adding unrelated validation layers elsewhere in the workflow.

For clipboard- or UI-copy-based flows, treat copy completion as asynchronous.
After triggering the copy action, poll until the clipboard content is present
and passes the semantic checks required by the task, or fail on timeout.

Semantic validation should match the task contract. For copied or returned
JSON, validate not only that the payload parses, but also that it is the
expected object for that step, such as matching the expected `ref_id` or other
task-defining identifier.

### 5. Separate local code from external node calls

When a spec node belongs to another package, the task code should call that
package’s executable node script instead of reimplementing the step locally.

Examples of external node sources:

- `autogui` package scripts for browser or desktop interactions
- `litxr` package scripts for literature processing
- future local model packages for classification, scoring, or other services

Use local task code only when:

- the required node does not already exist in an external package
- the step is task-specific and belongs in the task workspace
- the implementation is being created for the first time as part of this task

This means each spec node should resolve to one of two implementation paths:

- call an existing external node script
- create the node locally in the task workspace

Do not define the implementation boundary in terms of “UI-driven” versus
“deterministic” alone. The deciding factor is whether the node already exists as
an executable target in another package.

Prefer passing semantic inputs directly between nodes, such as `--ref-ids`,
`--litxr-root`, `--json-path`, or `--prompt-file`, and keep path resolution in
the shell orchestrator. Avoid hardcoding external package roots inside R/Python
nodes.

Avoid thin wrapper scripts that only forward to an external package command
unless the wrapper adds a concrete task-local contract, such as writing a task
artifact, adapting a parameter shape, or validating output before the next
workflow step.

Let the system of record own validation when possible. If the downstream
external package or canonical ingest/write script already validates the payload
as part of its contract, do not add a redundant local pre-validation wrapper
unless it catches a distinct class of error that the downstream system does not
cover.

## Node-Folder Subworkflow Pattern

Use a node folder when a step has multiple low-level actions but one reviewable
purpose.

Good candidates:

- send prompt
- wait for output
- copy output
- retry once on failure
- confirm a download dialog
- place the final file into the task’s expected location

In that case, the parent workflow node should describe the conceptual step, and
the folder-level subworkflow should contain the smaller mechanics.

Example:

- parent node: `Obtain article markdown through ChatGPT UI`
- subworkflow nodes: `send prompt`, `wait for canvas`, `copy markdown`,
  `retry copy once`

This keeps the parent workflow readable while preserving the implementation
details in the child workflow.

Treat the `nodes/` directory with this convention:

- a file under `nodes/` is one executable node
- a directory under `nodes/` is one subworkflow node
- a subworkflow node directory should contain its own orchestrator, and should
  keep its own `docs/` when the lower-level workflow is reviewable on its own

Do not mix both meanings in one path. If a step is a subworkflow, make it a
folder and put the executable orchestrator inside that folder.

## Task Code Generation Order

When implementing a task from spec, use this order:

1. Read the approved workflow, memory, and knowledge specs.
2. Create or update the root task orchestrator.
3. Create or update executable node scripts.
4. Create or update node-folder subworkflow scripts where needed.
5. Wire environment variables and workspace path configuration handling.
6. Write or refresh task-local docs if the task shape changed.
7. Validate shell syntax and script parsers.
8. Validate JSON outputs for nodes that claim JSON contracts.
9. Regenerate preview HTML only after the code matches the spec.

Do not start from the preview HTML and work backward. The code should follow the
spec, not the other way around.

## Validation Rules

Before considering the task implementation complete, validate at least:

- shell syntax for every `*.sh`
- parser or syntax checks for every `*.R` or other executable script
- `-h/--help` behavior for every executable entrypoint
- JSON output shape for nodes that promise JSON
- path export behavior when `knowledge/agent_paths.json` is used

If a workflow has side effects such as git push, email send, browser UI control,
or external publication, do not run the full workflow unless that side effect is
intended for validation.

Prefer dry runs, no-op dates, or isolated helper checks when available.

## Loop and Control Flow

When a root orchestrator implements repeated task execution, prefer explicit,
inspectable loop control.

Use this pattern when practical:

- one node determines whether the workflow should continue and which item should
  be processed next
- loop-only setup or transition steps such as page reloads should stay visible
  in code and specs
- the root orchestrator should avoid hiding normal control flow in large shell
  blocks with scattered `break` conditions

When the workflow has a special first-iteration behavior, such as opening a
project page once and reloading it only on later iterations, keep that decision
in the root orchestrator and make it readable through nearby `node_id`
comments.

Prefer condition-driven loops over unconstrained `while true` loops when the
task already has explicit pending-list state, index state, or a bounded run
limit.

## Review Boundary

Generated code should still be reviewable by a human using the same `agentr`
preview artifacts.

That means:

- task nodes should correspond to conceptual steps
- node-folder subworkflows should represent low-level mechanics
- JSON outputs should be inspectable
- help output should explain how each script is used
- side effects should be explicit and bounded

If the code cannot be explained in the preview or in a short usage summary, it
is probably too dense.

## Conversion Boundary

When an `agentr` spec is ready to become code, convert each node by deciding
whether it is:

1. an existing external node script to call
2. a new local script to create in the task workspace
3. a node-folder subworkflow whose internal steps should be split out locally

Do not leave the conversion step ambiguous. Every spec node should map to a
concrete executable target or a concrete local implementation plan.
