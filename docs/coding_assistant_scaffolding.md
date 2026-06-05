# Coding Assistant Scaffolding

Coding-assistant workflows give `agentr` a second practical scaffolding path.
The package can still run a proposal-state loop through constrained JSON
messages, but a coding assistant can also inspect a full repository, infer
editable specs from existing code, render review artifacts, revise specs and
code, and let Git record the evolution.

Because coding-assistant models are improving quickly, the recommended
end-to-end use case is not for a human to hand-write the implementation code.
Instead, the human provides goals, reviews specs and outputs, and asks the
assistant to infer or revise code. The R functions and standardized spec shapes
remain important because the guidance asks the assistant to consume them,
conform to them, and generate artifacts that humans can inspect.

## Two Complementary Modes

Proposal-state mode:

```text
human or model proposes spec change
-> constrained JSON action
-> proposal state
-> discussion or revision
-> explicit approval
-> approved spec
```

Coding-assistant mode:

```text
coding assistant inspects repository
-> infers task-local YAML specs
-> renders review HTML
-> human reviews code, specs, and outputs
-> coding assistant revises specs or code
-> Git commit records the change
```

The two modes solve different versioning problems. Proposal objects are useful
when Git is unavailable, when approval must happen inside R, or when browser
feedback should be routed into structured proposal state. Git history is often
the clearer record when specs and executable code live in the same repository.

## Task-Local Specs

For coding-assistant work, keep editable specs beside the task code:

```text
tasks/<task_id>/docs/
  workflow_spec.yaml
  memory_spec.yaml
  knowledge_spec.yaml
  knowledge_graph_spec.yaml
  review.html
  inference_notes.md
```

YAML is the preferred editable source. JSON is useful for interchange and RDS
is useful for R-native persistence or cache artifacts.

## Helper Functions

Use these helpers to locate, load, and validate task-local specs:

```r
paths <- task_spec_paths("tasks/write_new_blog_article")
manifest <- discover_task_specs("tasks/write_new_blog_article")
specs <- load_task_specs("tasks/write_new_blog_article")
validation <- validate_task_specs(
  "tasks/write_new_blog_article",
  require = "workflow",
  stop_on_error = TRUE
)
```

The helpers do not execute task code. They only discover files, load YAML specs
through existing `agentr` loaders, and report validation status.

For additional inspection snippets, see [R Function Examples](r_function_examples.md).

## Shipped Guidance

The package ships coding-assistant guidance under `inst/guides/`:

- `coding_assistant_task_spec_inference.md`
- `coding_assistant_task_code_construction.md`
- `coding_assistant_node_script_construction.md`

These guides define how a coding assistant should infer descriptive specs from
code and how approved specs can guide downstream task code. They are part of
the scaffolding method, not a runtime engine.
