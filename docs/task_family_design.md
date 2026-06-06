# Task-Family Design

`agentr` can represent a related set of tasks as a task family without turning
the package into a runtime orchestrator. A task family is a normal workflow spec
whose root nodes are child tasks. Each child task should point to a lower-level
workflow through `subworkflow_ref`. Task-local review rendering can resolve
that reference and embed the child workflow into the standalone HTML review
bundle.

This is useful when one workspace contains a coherent design space rather than
one narrow task. For example, a research-publication workspace may contain one
task for updating local schema records and another task for drafting a blog
article. The root workflow records the family-level objective and the child
tasks; the detailed procedural logic stays inside each child workflow.

## Recommended Schema

- Use one root workflow for the task family.
- Use one child-task node per task.
- Keep root-level edges empty when child tasks are independent.
- Add root-level edges only when one child task truly depends on another.
- Store task-family metadata under `workflow$metadata$task_family`.
- Use `task_tags` to support review filtering and grouping.
- Use `subworkflow_ref` for stable task-local file references such as
  `tasks/<task_id>/nodes/<subworkflow_node_id>/docs/workflow_spec.yaml`.
- Treat `nested_workflow` as review-bundle data. Prefer generating it from
  `subworkflow_ref` during `render_task_preview()` rather than maintaining it
  manually in editable YAML.
- Keep generated editable specs and previews under each task or subworkflow
  node's `docs/` folder.
- Prefer at most two task levels: root task and node-folder subworkflow. If
  deeper structure exists, summarize it in the nearest subworkflow spec and
  add a review note.

## Helpers

```r
family <- new_task_family_workflow(
  id = "research_publication",
  label = "Research publication maintenance",
  objective = "Coordinate related publication-maintenance tasks.",
  shared_inputs = c("arxiv_ids")
)

family <- add_child_task_node(
  family,
  child_task_node(
    id = "task_blog_article",
    label = "Write a Cognaptus blog article",
    subworkflow_ref = "tasks/write_blog/nodes/draft_article/docs/workflow_spec.yaml"
  ),
  tags = c("publication", "blog")
)
```

The result is still an `agentr_workflow_spec`, so it can be saved with
`save_workflow_spec()`, proposed through `WorkflowProposalState`, and exported
with `export_design_review_html()`.

## Boundary

The task-family workflow is a design artifact. It describes task membership,
shared objective, review concerns, schemas, and child workflow references. It
does not execute those child workflows.

The standalone review HTML uses task-preview tabs for family members and a
lightweight badge for nodes that contain nested workflows. Clicking a node
opens its inspector detail and, when embedded detail exists, its local nested
workflow chart.
