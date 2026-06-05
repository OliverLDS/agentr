# Coding Assistant MemorySpec Inference Guide

Use this guide when inferring only `memory_spec.yaml`, or when a workstation
wrapper asks you to infer the memory part of a larger `agentr` design.

`MemorySpec` describes what persists or matters across runs. It should not
mirror every local variable in the code. Infer memory only when there is
evidence that state is saved, reused, reviewed, or needed to interpret future
task behavior.

## When To Infer MemorySpec

Infer a `MemorySpec` only when the task uses persistent state or clearly
depends on state carried across runs.

Good evidence:

- Append-only logs such as `.jsonl`, `.tsv`, or `.csv`.
- Persistent `.rds`, `.json`, YAML, database, or cache files.
- State folders that prevent repeated work.
- Caches used as inputs to later runs.
- Human decisions or review traces that should be reused.
- Workspace path memory such as `memory/agent_paths.json`.

Do not infer `MemorySpec` just because a task has local variables.
Runtime-local variables are not persistent memory unless the task saves or
reuses them across runs.

## Shape

Save memory as `tasks/<task_id>/docs/memory_spec.yaml`.

Recommended shape:

```yaml
fields:
  - id: current_task_context
    label: Current task context
    memory_type: context
    description: Current input, active item, or current task state.
    schema:
      type: object
      properties: {}
      required: []
    persistence: session
    source: null
    update_rule: null
    review:
      status: pending
metadata:
  source: coding_assistant_inference
```

## Memory Types

| Memory type | Use when |
| --- | --- |
| `context` | Current run state, active input, current task state |
| `semantic` | Stable facts, concepts, schemas, known entities |
| `episodic` | Past runs, prior user actions, completion logs |
| `procedural` | Reusable process knowledge, workflow rules, task recipes |

Examples:

- `context`: active arXiv id, current article slug, active paper paragraph
- `semantic`: approved schema field definitions, stable project paths
- `episodic`: completed item log, previous review decisions
- `procedural`: reusable prompt-building rule or task recipe

## Field Guidance

Use stable snake-case ids. Prefer one field per reviewable memory concept
rather than one field per storage file.

Include:

- `id`: stable field id
- `label`: human-readable label
- `memory_type`: one of `context`, `semantic`, `episodic`, `procedural`
- `description`: what the memory stores and why it matters
- `schema`: expected shape when visible from code or docs
- `persistence`: how it persists, such as `session`, `jsonl_trace`,
  `task_yaml`, `rds_cache`, `file`, or `external`
- `source`: file, folder, environment variable, or script that supports the
  inference
- `update_rule`: how the task updates the memory when visible
- `review`: start with `status: pending` unless already approved

## Path Memory

When a workspace provides `memory/agent_paths.json`, treat it as semantic or
context memory depending on its use:

- use `semantic` when it defines stable workspace paths
- use `context` when values change per run

Do not create a shared path-helper package only to load path memory. Prefer the
root `zsh` orchestrator to read `memory/agent_paths.json`, export environment
variables, and pass paths to node scripts.

## What Not To Infer

Do not add memory fields for:

- temporary local variables
- shell variables that are not persisted
- intermediate files that are recreated and never reused
- implementation details that have no review value
- domain knowledge that belongs in `KnowledgeSpec`
- entity-relation knowledge that belongs in `KnowledgeGraphSpec`

## Review Notes

Use `review_notes` or `review.status: pending` when:

- a file is clearly persistent but its schema is unknown
- a state file may be cache rather than memory
- update rules are implicit or spread across scripts
- the task appears to depend on human memory outside the code
