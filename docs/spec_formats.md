# Spec Formats

`agentr` supports YAML, JSON, and RDS because they serve different boundaries.
Do not keep multiple editable copies as competing sources of truth.

## YAML: Editable Source

Prefer YAML for task-local human-maintained specs:

```text
tasks/<task_id>/docs/
  workflow_spec.yaml
  memory_spec.yaml
  knowledge_spec.yaml
  review.html
  inference_notes.md
```

YAML is easier to review and revise than JSON for labels, rules, schemas, and
knowledge statements. Use a strict subset: explicit arrays where the schema
expects arrays, no custom tags, and no anchors unless a downstream tool
deliberately supports them.

## JSON: Interchange Boundary

Use JSON for constrained LLM responses, browser feedback, append-only JSONL
traces, and integrations with non-R tooling. Schema-aware loaders normalize
conceptual array fields such as `knowledge_refs` and JSON-schema `required`
when a serializer emits a single scalar value.

## RDS: Native Persistence Or Cache

Use RDS when R object fidelity matters, particularly for proposal state,
cold-start runtime state, or cache artifacts. RDS is convenient for R code but
should not be the only manually reviewable representation of a design spec.

## Rendering Rule

Render review HTML from the canonical editable YAML when a task-local YAML
file exists. Load YAML into R objects during validation and rendering rather
than editing generated HTML or maintaining a separate JSON source of truth.
