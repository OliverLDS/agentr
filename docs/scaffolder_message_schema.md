# Scaffolder Message Schema

This document defines the machine-readable contract used by the `agentr` LLM scaffolding bridge.

## Top-Level Shape

The LLM must return JSON with this top-level structure:

```json
{
  "actions": [
    {
      "method": "decompose_task",
      "args": {
        "candidates": ["Clarify objectives", "Capture rules"]
      }
    }
  ],
  "notes": "Optional short reasoning summary."
}
```

Rules:

- `actions` is required and must be a list.
- `notes` is optional.
- each action must contain `method` and `args`.
- methods outside the allowed method set are rejected.

## Allowed Methods

Allowed methods:

- `evaluate_task`
- `decompose_task`
- `ask_human_complete`
- `ask_human_changes`
- `ask_human_rule`
- `apply_human_feedback`

## Method-Specific Arguments

### `evaluate_task`

```json
{
  "method": "evaluate_task",
  "args": {
    "task": "Design a DAG for onboarding"
  }
}
```

- `task` is required and must be a non-empty string.

### `decompose_task`

```json
{
  "method": "decompose_task",
  "args": {
    "task": "Optional task override",
    "candidates": ["Clarify goals", "Draft handoff"]
  }
}
```

- `task` is optional.
- `candidates` is optional and must contain non-empty strings when provided.

### `ask_human_complete`

```json
{
  "method": "ask_human_complete",
  "args": {
    "node_id": "node_2"
  }
}
```

- `node_id` is required and must reference an existing workflow node.

### `ask_human_changes`

```json
{
  "method": "ask_human_changes",
  "args": {}
}
```

- no arguments are allowed.

### `ask_human_rule`

```json
{
  "method": "ask_human_rule",
  "args": {
    "node_id": "node_3"
  }
}
```

- `node_id` is required and must reference an existing workflow node.

### `apply_human_feedback`

```json
{
  "method": "apply_human_feedback",
  "args": {
    "completeness": {"node_1": true},
    "add": [
      {
        "label": "Capture escalation rules",
        "confidence": 0.6,
        "human_required": true
      }
    ],
    "remove": ["node_4"],
    "rule_specs": {"node_2": "Require manager approval"},
    "confidence": {"node_2": 0.8}
  }
}
```

Validation rules:

- `confidence` values must be numeric in `[0, 1]`.
- added nodes must include a non-empty `label`.
- explicit added-node `id` values must be unique.
- `remove`, `completeness`, `rule_specs`, and `confidence` must reference nodes that exist after additions/removals are considered.

## Dispatch Result

`apply_scaffolder_message()` returns a standardized result object:

- `applied_actions`: per-action status, result, and error information
- `workflow_after`: workflow specification after sequential action application
- `human_prompts`: extracted human-facing prompts
- `errors`: collected action errors when `stop_on_error = FALSE`

## Sequential Semantics

Actions are applied in order.

- later actions see the scaffolder state produced by earlier actions
- this allows decomposition first, followed by rule requests or structured updates
- if `stop_on_error = TRUE`, dispatch stops at the first error
- if `stop_on_error = FALSE`, dispatch collects errors and continues
