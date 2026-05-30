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
- `input_schema` and `output_schema`
- `subworkflow_ref` and `nested_workflow`

Reserve `human_required = TRUE` for real human decision or review gates.
External scripts, UI automation steps, and external LLM interactions are not
human gates merely because they execute outside the local R process.

External LLM steps should remain visible as first-class nodes. A GUI-backed
step may be labeled `ChatGPT`; another implementation may use a different chat
UI or an API-backed model node.

## Edges And Branches

Create edges with `workflow_edge()`. Core fields include `from`, `to`,
`relation`, `confidence`, and `notes`. Conditional branches may also use:

- `condition`
- `branch_group`
- `mutually_exclusive`

These fields are preserved by serialization and the HTML review renderer so
exclusive branch paths remain visible rather than collapsing into ordinary
sequential edges.

## Nested Workflows

Use `subworkflow_ref` when a node points to a stable task-local child spec such
as:

```text
tasks/<task_id>/nodes/<subworkflow_node_id>/docs/workflow_spec.yaml
```

Use `nested_workflow` when a combined review HTML file should embed the child
workflow. Nested nodes receive a lightweight badge in the graph and their
local chart can be inspected from the detail panel.

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
