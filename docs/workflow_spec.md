# Workflow Spec

`WorkflowSpec` captures procedural knowledge: what a task does, how steps
depend on one another, where review gates exist, and which details still need
human judgment or external implementation.

## Nodes

Create nodes with `workflow_node()`. Important fields include:

- `id` and `label`
- `confidence`
- `human_required`
- `rule_spec`
- `implementation_hint`
- `owner`
- `automation_status`
- `knowledge_refs`
- `node_kind`
- `input_schema` and `output_schema`
- `subworkflow_ref` and `nested_workflow`

Reserve `human_required = TRUE` for real human decision or review gates.
External scripts, UI automation steps, and external LLM interactions are not
human gates merely because they execute outside the local R process.

External LLM steps should remain visible as first-class nodes. A GUI-backed
step may be labeled `ChatGPT`; another implementation may use a different chat
UI or an API-backed model node.

Use `node_kind = "status"` for visible status, mode, checkpoint, or error
markers that affect workflow review but are not executable actions and are not
knowledge or memory resources. Status nodes stay in the workflow graph and can
connect to recovery or manual-review actions without drawing failure edges from
every possible upstream action.

## Edges And Branches

Create edges with `workflow_edge()`. Core fields include `from`, `to`,
`relation`, `confidence`, and `notes`. Real conditional fan-out edges may also
use:

- `condition`
- `branch_group`
- `mutually_exclusive`

These fields are preserved by serialization and the HTML review renderer so
exclusive branch paths remain visible rather than collapsing into ordinary
sequential edges. Do not use `condition` for an internal guard on an otherwise
sequential step, such as "first iteration only" or "if cache exists". Put that
guard in the target node's `rule_spec`, `implementation_hint`, `review_notes`,
or in edge `notes`; otherwise the review renderer will treat the edge as
branch-like metadata.

## Nested Workflows

Use `subworkflow_ref` when a node points to a stable task-local child spec such
as:

```text
tasks/<task_id>/nodes/<subworkflow_node_id>/docs/workflow_spec.yaml
```

`render_task_preview()` resolves task-local `subworkflow_ref` paths when the
referenced child spec exists and embeds the child workflow into the standalone
review bundle. Use `nested_workflow` only for already-combined review bundles
or programmatic fixtures, not as the preferred editable source.

Subworkflow nodes receive a lightweight badge in the graph. Clicking the badge
opens the embedded child workflow in a modal. If the referenced child workflow
was not embedded, the modal shows the unresolved reference path.

## Editable YAML

Prefer task-local YAML as the editable source:

```r
workflow <- load_workflow_spec_yaml("docs/workflow_spec.yaml")
validate_workflow_spec(workflow)
save_workflow_spec_yaml(workflow, "docs/workflow_spec.yaml")
```

JSON is useful for machine interchange. RDS is useful for R-native
persistence or cache artifacts. See [Spec Formats](spec_formats.md).

## Review Rendering

```r
workflow <- load_workflow_spec_yaml("docs/workflow_spec.yaml")
export_design_review_html(
  workflow,
  path = "docs/review.html",
  graph_layout = "process",
  edge_style = "orthogonal"
)
```

The standalone HTML graph wraps labels, keeps node ids in the inspector,
supports node and edge clicks, marks nested workflows, and scrolls
horizontally when the graph is wider than its panel. Use `process` layout for
branches or backward edges. `grid`, `layered`, and `swimlane` remain available
for simpler views.

## Schema Shape Rendering

Workflow nodes can carry `input_schema` and `output_schema` fields. Use
`schema_shape_graph_data()` when another renderer needs graph-ready node and
edge tables. Use `render_schema_shape_graphviz()` for standalone DOT,
DiagrammeR, or SVG output:

```r
node <- workflow$nodes[workflow$nodes$id == "node_3", ]
dot <- render_schema_shape_graphviz(
  node$output_schema[[1]],
  root_label = "node_3 output_schema",
  as = "dot"
)
```

This renderer visualizes schema structure for review. It does not validate
the schema as JSON Schema.
