# Knowledge Graph Spec

Graph knowledge is a first-class knowledge form in `agentr`. It stores
concepts and typed relationships directly:

```text
ACT-R --is_a--> cognitive architecture
BDI --has_component--> Belief
ReAct --implements_part_of--> observe-decide-act
```

## First-Class Graph Knowledge

Use `new_knowledge_graph_spec()`, `knowledge_graph_node()`, and
`knowledge_graph_edge()` when the graph itself is the curated artifact. Graph
nodes and edges may carry:

- type and relation metadata
- memory type
- provenance
- review state
- scope

`KnowledgeSpec` may contain narrative items, a first-class graph spec, and
future vector references. These are complementary forms of knowledge rather
than competing representations.

## Projection From Narrative Knowledge

`knowledge_graph_from_spec()` has a narrower purpose: it creates a projection
graph from narrative `KnowledgeSpec` items for inspection. A projection is not
automatically the approved first-class graph artifact. Review and approve
extracted graph relationships through `KnowledgeGraphProposalState`.

## Persistence And Rendering

```r
graph <- load_knowledge_graph_spec_yaml("docs/knowledge_graph_spec.yaml")
validate_knowledge_graph_spec(graph)
save_knowledge_graph_spec_yaml(graph, "docs/knowledge_graph_spec.yaml")
render_knowledge_graphviz(graph, as = "svg")
```

Minimal end-to-end example:

```r
kg <- new_knowledge_graph_spec(metadata = list(graph_mode = "curated"))

kg <- add_knowledge_graph_node(
  kg,
  id = "act_r",
  label = "ACT-R",
  node_type = "concept",
  memory_type = "semantic",
  review = list(status = "approved")
)

kg <- add_knowledge_graph_node(
  kg,
  id = "cognitive_architecture",
  label = "cognitive architecture",
  node_type = "concept",
  memory_type = "semantic",
  review = list(status = "approved")
)

kg <- add_knowledge_graph_edge(
  kg,
  from = "act_r",
  to = "cognitive_architecture",
  relation = "is_a",
  relation_type = "is_a",
  memory_type = "semantic",
  confidence = 0.95,
  review = list(status = "approved")
)

svg <- render_knowledge_graphviz(kg, as = "svg")
writeLines(svg, "knowledge_graph.svg")
```

Prefer YAML for human editing, JSON for interchange, and RDS for R-native
persistence or cache artifacts. See [Spec Formats](spec_formats.md).

## Proposal Loop

Use:

- `build_knowledge_graph_extraction_prompt()`
- `build_knowledge_graph_revision_prompt()`
- `preview_knowledge_graph_message()`
- `apply_knowledge_graph_message()`

The loop remains explicit:

```text
initial extraction
-> pending graph proposal
-> human discussion or revision
-> explicit approval
-> active graph knowledge
```
