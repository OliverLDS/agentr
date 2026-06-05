# Coding Assistant KnowledgeGraphSpec Inference Guide

Use this guide when inferring only `knowledge_graph_spec.yaml`, or when a
workstation wrapper asks you to infer first-class graph knowledge for a larger
`agentr` design.

`KnowledgeGraphSpec` stores knowledge as nodes and relationships. It is a form
of knowledge, not merely a visualization. This differs from
`knowledge_graph_from_spec()`, which creates a projection graph from narrative
`KnowledgeSpec` items.

## When To Infer KnowledgeGraphSpec

Infer a first-class `KnowledgeGraphSpec` when the task contains explicit
entity-relation knowledge that is useful to inspect as nodes and edges.

Good evidence:

- Ontology-like statements, such as `ACT-R is_a cognitive architecture`.
- Stable entity relationships in prompts, docs, schemas, or examples.
- Dependency or compatibility relations among concepts, tools, files, models,
  data sources, or output types.
- Reusable relation triples that humans would want to review visually.
- Knowledge that is naturally queried as connected concepts rather than as one
  prose rule.

Do not create a `KnowledgeGraphSpec` just because the workflow itself is a DAG.
Workflow edges describe procedural order. Knowledge-graph edges describe
semantic or domain relationships.

## Shape

Save first-class graph knowledge as
`tasks/<task_id>/docs/knowledge_graph_spec.yaml`.

Recommended shape:

```yaml
metadata:
  graph_mode: curated
  source: coding_assistant_inference
nodes:
  - id: act_r
    label: ACT-R
    node_type: concept
    memory_type: semantic
    knowledge_form: graph
    provenance:
      source: docs/task_notes.md
    review:
      status: pending
    scope:
      domain: cognitive_architectures
edges:
  - from: act_r
    to: cognitive_architecture
    relation: is_a
    relation_type: is_a
    memory_type: semantic
    provenance:
      source: docs/task_notes.md
    review:
      status: pending
    scope:
      domain: cognitive_architectures
```

## Node Fields

| Field | Guidance |
| --- | --- |
| `id` | Stable snake-case identifier, unique inside the graph |
| `label` | Human-readable concept/entity label |
| `node_type` | Conceptual node category, such as `concept`, `tool`, `file`, `schema`, `model`, `source`, or `criterion` |
| `memory_type` | Usually `semantic` or `procedural`; use `context` or `episodic` only when the graph represents current state or past events |
| `knowledge_form` | Use `graph` for first-class graph knowledge |
| `provenance` | Source file, prompt, doc, comment, or user note that supports the node |
| `review` | Start with `status: pending` unless the user has already approved it |
| `scope` | Domain, task, or condition where the node is valid |

## Edge Fields

| Field | Guidance |
| --- | --- |
| `from` | Source graph node id |
| `to` | Target graph node id |
| `relation` | Human-readable relation, such as `is_a`, `has_component`, `requires`, `implements_part_of`, `produces`, or `constrains` |
| `relation_type` | Normalized relation family; often the same as `relation` |
| `memory_type` | Usually follows the source relation's memory type |
| `provenance` | Source evidence for the relation |
| `review` | Start with `status: pending` unless approved |
| `scope` | Domain, task, or condition where the relation is valid |

## Relation Guidance

Prefer normalized relation names that are stable across tasks:

- `is_a`
- `has_component`
- `requires`
- `produces`
- `consumes`
- `constrains`
- `implements_part_of`
- `depends_on_concept`
- `compatible_with`
- `conflicts_with`
- `lacks_explicitly`

If the observed relation is task-specific, preserve the human-readable wording
in `relation` and add a broader family in `relation_type`.

## Example

```yaml
metadata:
  graph_mode: curated
nodes:
  - id: act_r
    label: ACT-R
    node_type: concept
    memory_type: semantic
    knowledge_form: graph
    provenance:
      source: docs/task_notes.md
    review:
      status: pending
    scope:
      domain: cognitive_architectures
  - id: cognitive_architecture
    label: cognitive architecture
    node_type: concept
    memory_type: semantic
    knowledge_form: graph
    provenance:
      source: docs/task_notes.md
    review:
      status: pending
    scope:
      domain: cognitive_architectures
edges:
  - from: act_r
    to: cognitive_architecture
    relation: is_a
    relation_type: is_a
    memory_type: semantic
    provenance:
      source: docs/task_notes.md
    review:
      status: pending
    scope:
      domain: cognitive_architectures
```

## Relationship To Other Specs

Use `WorkflowSpec` for procedural order and task dependencies. Do not copy
workflow DAG edges into graph knowledge unless the relation is also semantic
knowledge.

Use narrative `KnowledgeSpec` for prose rules, heuristics, exceptions, and
evaluation criteria.

Use `MemorySpec` when the graph represents a persistent memory schema or state
surface. If graph knowledge is a semantic memory artifact, set
`memory_type: semantic`.

## What Not To Infer

Do not add graph knowledge for:

- every file import
- every workflow edge
- temporary runtime object references
- speculative entity relationships
- relations unsupported by code, docs, prompts, or user context

Keep graph knowledge descriptive and reviewable. Do not use it as a hidden
runtime planner or execution engine.
