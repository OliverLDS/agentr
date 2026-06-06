# Coding Assistant KnowledgeSpec Inference Guide

Use this guide when inferring only `knowledge_spec.yaml`, or when a workstation
wrapper asks you to infer narrative knowledge for a larger `agentr` design.

`KnowledgeSpec` captures reusable domain knowledge, rules, exceptions,
heuristics, evaluation criteria, and style preferences. It is not a general
dump of all documentation. Infer only knowledge that can guide review or future
agent behavior.

## When To Infer KnowledgeSpec

Infer a `KnowledgeSpec` only when the task contains reusable knowledge that is
visible in code, docs, prompts, templates, comments, examples, or user-provided
context.

Good evidence:

- Written domain rules in docs or prompts.
- Reusable heuristics in code comments or templates.
- Exception handling that encodes practitioner judgment.
- Review criteria for generated outputs.
- Stable terminology or ontology used across tasks.
- Style preferences for writing, formatting, tone, or visual output.
- Risk warnings, constraints, or forbidden outputs.

Do not invent domain rules that are not visible in the task code, docs,
prompts, or user-provided context.

## Shape

Save narrative knowledge as `tasks/<task_id>/docs/knowledge_spec.yaml`.

Recommended shape:

```yaml
items:
  - id: ki_macro_yoy_001
    type: heuristic
    raw_statement: For noisy monthly macro indicators, YoY is often clearer than MoM.
    normalized_statement: For noisy monthly macro indicators, year-over-year transformation is often more suitable for medium-term interpretation than month-over-month change.
    domain: macro_analysis
    conditions: []
    exceptions: []
    confidence: medium
    provenance:
      source: docs/task_notes.md
    review:
      status: pending
metadata:
  source: coding_assistant_inference
```

## Supported Item Types

Use one of these item types:

- `concept`
- `causal_relation`
- `rule`
- `exception`
- `heuristic`
- `evaluation_criterion`
- `domain_constraint`
- `style_preference`
- `risk_warning`

Do not create ad hoc item types such as `style_rule`. Use
`style_preference`, `rule`, or `evaluation_criterion` depending on the evidence.

## Field Guidance

Use stable ids such as `ki_<domain>_<topic>_<nnn>`.

Include:

- `id`: stable knowledge item id
- `type`: one of the supported item types
- `raw_statement`: original wording or closest observed source statement
- `normalized_statement`: clearer reviewed wording when available
- `domain`: task or subject area where the item applies
- `conditions`: when the item applies
- `exceptions`: when the item does not apply
- `confidence`: `low`, `medium`, or `high` when inferable
- `provenance`: source file, prompt, template, or user note
- `review`: start with `status: pending` unless already approved

Approved items should have `normalized_statement`. Draft or pending items
should still keep `raw_statement`.

## Narrative Knowledge Versus Graph Knowledge

Use narrative `KnowledgeSpec` for prose rules, heuristics, exceptions, and
criteria.

Use `KnowledgeSpec$graph` for explicit developer-supplied entity-relation
structures such as:

```text
ACT-R --is_a--> cognitive architecture
BDI --has_component--> Belief
ReAct --implements_part_of--> observe-decide-act
```

When both are useful, keep them in the same `knowledge_spec.yaml`: narrative
items under `items:` and graph-shaped relationships under `graph:`.

## What Not To Infer

Do not add knowledge items for:

- every code comment
- every README sentence
- workflow order, which belongs in `WorkflowSpec`
- persistent state, which belongs in `MemorySpec`
- transient facts from a single run unless they become reusable rules
- unsupported domain claims

## Review Notes

Use pending review when:

- the raw statement is vague
- scope or exceptions are unclear
- two knowledge items may conflict
- the statement looks like a preference rather than a rule
- the source is a prompt but not confirmed by code or user notes
