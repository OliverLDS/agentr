# Workflow-Only Task Spec Inference Wrapper

Use this wrapper when the user asks a coding assistant to infer only the
workflow for a task. This is appropriate for simple tasks where persistent
memory, narrative knowledge, or graph knowledge is not needed.

The only required output is:

```text
tasks/<task_id>/docs/workflow_spec.yaml
```

Use the focused workflow shape guide:

- [WorkflowSpec inference](spec_inference/workflow_spec.md)

## Scope

Infer:

- task objective
- workflow nodes
- workflow edges
- branch metadata
- human gates
- external LLM nodes
- input and output schemas when visible
- nested workflow references when a node-folder subworkflow exists
- implementation hints pointing to observed code
- review notes for uncertain behavior

Do not infer:

- `memory_spec.yaml`
- `knowledge_spec.yaml`
- `knowledge_graph_spec.yaml`
- implementation code
- new runtime behavior not present in the task

If persistent state, reusable rules, or explicit entity-relation knowledge are
clearly important after inspection, record that recommendation in
`docs/inference_notes.md` and ask whether the user wants full-stack inference.

## Minimal Process

1. Read the root orchestrator or task runner.
2. Read task docs and node scripts only as needed to clarify workflow order,
   schemas, side effects, and gates.
3. Infer `workflow_spec.yaml` using
   [WorkflowSpec inference](spec_inference/workflow_spec.md).
4. Render `review.html` with `render_task_preview()` when `agentr` is
   available.
5. Record uncertainty in `docs/inference_notes.md`.

## Validation

Before finishing, check:

- every edge references existing node ids
- real human gates use `human_required: true`
- external scripts, AutoGUI steps, and external LLM steps are not mislabeled as
  human gates
- branch edges preserve `condition`, `branch_group`, and
  `mutually_exclusive` when present
- subworkflow nodes use `subworkflow_ref` for durable child links

Warn if node scripts or orchestrators violate the code-construction guidance,
especially missing JSON output, missing `-h/--help`, or missing `node_id`
comments at node-call blocks.
