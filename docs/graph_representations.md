# Graph Representations

Graph is a representation shape, not a standalone top-level spec in `agentr`.

Use graph-shaped data when knowledge or memory is naturally expressed as nodes
and relationships:

```text
ACT-R --is_a--> cognitive architecture
BDI --has_component--> Belief
ReAct --implements_part_of--> observe-decide-act
```

The graph should live inside the owning spec:

- `KnowledgeSpec$graph` for developer-supplied graph-shaped knowledge.
- `MemorySpec$graph` for graph-shaped memory acquired or updated by agentic
  actions.

Do not create a separate `knowledge_graph_spec.yaml`. If a task does not
retrieve, update, or use knowledge or memory in the workflow, do not infer
knowledge or memory specs only to fill the review page.

## Shape

Use a strict YAML/list shape:

```yaml
graph:
  nodes:
    - id: act_r
      label: ACT-R
      node_type: concept
      memory_type: semantic
  edges:
    - from: act_r
      to: cognitive_architecture
      relation: is_a
      relation_type: is_a
      memory_type: semantic
  metadata:
    source: coding_assistant_inference
```

The minimal required graph fields are:

- node `id`
- node `label`
- edge `from`
- edge `to`
- edge `relation`

Optional fields such as `node_type`, `relation_type`, `memory_type`, and
`metadata` improve review and rendering.

## Rendering

Use `knowledge_graph_data()` and `render_knowledge_graphviz()` for graph-shaped
knowledge or memory:

```r
knowledge <- load_knowledge_spec_yaml("tasks/example/docs/knowledge_spec.yaml")
svg <- render_knowledge_graphviz(knowledge, as = "svg")

memory <- load_memory_spec_yaml("tasks/example/docs/memory_spec.yaml")
dot <- render_knowledge_graphviz(memory, as = "dot")
```

`knowledge_graph_from_spec()` is now a compatibility-oriented alias for
`knowledge_graph_data()`. It returns graph-ready data; it does not create a
separate graph spec object.

