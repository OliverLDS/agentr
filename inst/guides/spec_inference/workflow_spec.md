# Coding Assistant WorkflowSpec Inference Guide

Use this guide when inferring only `workflow_spec.yaml`, or when a workstation
wrapper asks you to infer the workflow part of a larger `agentr` design.

`WorkflowSpec` captures procedural structure: what the task does, in what
order, under which conditions, with which human gates, schemas, side effects,
and nested workflows. It is descriptive and reviewable. It is not an execution
engine.

## When To Infer WorkflowSpec

Create a `WorkflowSpec` when the task has identifiable steps, dependencies,
branches, loops, human review points, external LLM steps, or subworkflows.

Read evidence in this order:

1. Root orchestrator or task runner.
2. Task docs and inference notes.
3. Node scripts.
4. Resource prompts, schemas, templates, and state files.

## Shape

Save the workflow as `tasks/<task_id>/docs/workflow_spec.yaml`.

Core shape:

```yaml
task: "Human-readable task objective"
metadata:
  source: "coding_assistant_inference"
nodes:
  - id: stable_node_id
    label: Human-readable node label
    node_kind: action
    human_required: false
    owner: script
    automation_status: rule_assisted
    source_path: null
    retrieval_mode: null
    persistence: null
    linked_spec_ids: []
    rule_spec: null
    implementation_hint: "Source file or observed behavior."
    input_schema: {}
    output_schema: {}
    subworkflow_ref: null
    nested_workflow: null
    knowledge_refs: []
    review_status: pending
    review_notes: null
edges:
  - from: stable_node_id
    to: next_node_id
    relation: depends_on
    condition: null
    branch_group: null
    mutually_exclusive: false
    notes: null
```

## Mapping Evidence To Fields

| Evidence in code/docs | WorkflowSpec representation |
| --- | --- |
| Script invocation or named stage | `workflow_node(id, label, implementation_hint)` |
| Sequential script calls | `workflow_edge(from, to)` |
| Status, mode, error, or checkpoint marker that affects control flow but does not itself run task code | `node_kind: status` |
| Knowledge, memory, file, API, schema, or data resource used by an action | A resource node with `node_kind` set to `knowledge`, `memory`, `file`, `api`, `schema`, or `data` |
| Action reads a resource | Resource-to-action edge with `relation: reads` |
| Action writes or updates a resource | Action-to-resource edge with `relation: writes` or `relation: updates` |
| Action injects resource content into an LLM prompt | Resource-to-action edge with `relation: prompts_with` |
| Action validates output against a schema resource | Schema-to-action edge with `relation: validates_against` |
| Action produces a durable artifact | Action-to-resource edge with `relation: produces` |
| Real conditional fan-out | Edge `condition`, `branch_group`, and `mutually_exclusive`; use `rule_spec` for node-level routing rules |
| Optional guard inside a sequential step | Keep the sequential edge unconditioned; put the guard in the guarded node's `rule_spec`, `implementation_hint`, `review_notes`, or edge `notes` |
| Loop over inputs | Node label/rule describing iteration, not duplicated nodes per item |
| JSON output from a node | `output_schema` |
| CLI args, files, or environment variables | `input_schema` |
| Human judgment or manual review | `human_required = TRUE`, `owner = "human"` |
| Local script/tool action | `human_required = FALSE`, `owner = "script"` or `owner = "external_system"` |
| External LLM or chat-UI step such as ChatGPT | `human_required = FALSE`, `owner = "external_system"`, `automation_status = "llm_assisted"` |
| UI automation, API calls, file writes | `human_required = FALSE`, `automation_status = "rule_assisted"` unless the code shows stronger autonomy |

Current `agentr` workflow nodes support these richer fields:

- `node_kind`
- `source_path`
- `retrieval_mode`
- `persistence`
- `linked_spec_ids`
- `input_schema`
- `output_schema`
- `subworkflow_ref`
- `nested_workflow`

If an installed package version does not support those fields as first-class
node columns, store the same information in `rule_spec`,
`implementation_hint`, `review_notes`, `knowledge_refs`, or
`workflow$metadata`. Do not emit constructor calls that fail in the installed
package.

## Node Ids And Granularity

Keep node ids stable, lowercase, and task-scoped:

```r
workflow_node(
  id = "blog_generate_article_prompt",
  label = "Generate blog article prompt",
  implementation_hint = "Uses nodes/generate_blog_article_prompt.R.",
  input_schema = list(type = "object", required = c("arxiv_id")),
  output_schema = list(type = "object", required = c("success", "prompt"))
)
```

Use one workflow node per conceptual step. Do not create a node for every shell
line unless each line is a distinct reviewable unit.

## Status, Data, And Resource Nodes

Use `node_kind = "action"` for steps that do work.

Use `node_kind = "status"` for visible control-state markers such as failure
states, checkpoint states, cached/not-cached states, or mode states when the
state affects review of the workflow but is not itself executable code,
developer-imported knowledge, or agent memory. A status node may point to a
manual recovery/review node without drawing failure edges from every upstream
node that could theoretically fail.

Use these resource node kinds when the workflow explicitly depends on external
or persistent data:

- `knowledge`: developer-curated facts, rules, heuristics, exceptions, style
  preferences, or other static domain knowledge.
- `memory`: state gained through previous agent actions or prior runs.
- `file`: a concrete local file or generated artifact.
- `api`: an external service surface or API response source.
- `schema`: a validation or shape contract used by workflow actions.
- `data`: a generic dataset or resource that does not fit the more specific
  kinds.

Resource nodes are not human gates. Do not set `human_required = TRUE` merely
because a resource is manually editable or outside the local runtime.

When useful, add:

- `source_path`: path, URI, or symbolic source.
- `retrieval_mode`: for example `load_yaml`, `read_jsonl`, `semantic_lookup`,
  `vector_search`, `api_fetch`, or `manual_copy`.
- `persistence`: for example `static`, `task_local`, `append_only`,
  `cross_run`, or `external`.
- `linked_spec_ids`: ids or paths for linked `KnowledgeSpec`, `MemorySpec`,
  schema, interface, or state specs.

Prefer explicit data/resource nodes when a knowledge or memory object is
retrieved into a prompt, validates an output, or is updated by the task. Do not
infer standalone `knowledge_spec.yaml` or `memory_spec.yaml` if the workflow
does not contain corresponding resource nodes, `knowledge_refs`, memory
references, or clear code evidence that those resources shape behavior.

Example:

```yaml
nodes:
  - id: article_style_rules
    label: Article style rules
    node_kind: knowledge
    human_required: false
    source_path: docs/knowledge_spec.yaml
    retrieval_mode: yaml_lookup
    persistence: static
    linked_spec_ids: [knowledge_spec.yaml]
  - id: build_article_prompt
    label: Build article prompt
    node_kind: action
    human_required: false
edges:
  - from: article_style_rules
    to: build_article_prompt
    relation: prompts_with
```

## Human Gates

Reserve `human_required = TRUE` for real human decision or review gates only.
Do not mark a node as human just because it is outside the local runtime,
implemented by an external script, driven through AutoGUI, or routed through an
external LLM or chat UI.

When a node is not a human gate, set `human_required = FALSE` and describe the
surface with `owner`, `automation_status`, and `implementation_hint`.

## External LLM Nodes

External LLM steps are first-class workflow nodes. They belong in the task
workflow even when the concrete implementation is GUI-driven or API-driven, and
even when no local script directly implements the response-generation step.

When a workflow sends a prompt to an external LLM and later retrieves a
response, include an explicit external LLM node between prompt delivery and
response retrieval.

Model the semantic response-generation step, not just the local transport
mechanics. For example, prefer:

```text
send_prompt_to_chatgpt_ui
-> chatgpt_generate_structure_plan
-> copy_structure_plan_from_ui
```

over a graph that contains only send/wait/copy UI mechanics.

In the current AutoGUI-oriented pattern, the node label may be `ChatGPT` or a
more task-specific label such as `ChatGPT generates structure-plan JSON`. Other
chat UIs or API-backed LLM nodes are also valid conceptually; only the GUI/API
implementation details differ. The node output schema may be JSON, markdown,
plain text, YAML, image prompt text, or unknown, depending on the actual task
contract.

## Branches And Loops

Use branch metadata only when the code has real conditional fan-out: one source
node routes to two or more alternative successor nodes, and those successors
represent distinct possible paths.

```yaml
edges:
  - from: route_article_source_count
    to: generate_single_source_prompt
    relation: branch
    condition: "source_count == 1"
    branch_group: source_count_route
    mutually_exclusive: true
  - from: route_article_source_count
    to: generate_multi_source_prompt
    relation: branch
    condition: "source_count > 1"
    branch_group: source_count_route
    mutually_exclusive: true
```

When code expresses an optional single-step continuation such as
`if condition: A -> B -> C; else: A -> C`, prefer to model the condition inside
node `B` when `B` is already the reviewed conceptual step. In that case, infer
the simpler workflow shape `A -> B -> C` and describe the guard in `B`'s
`rule_spec`, `implementation_hint`, or edge notes rather than adding a separate
skip edge that bypasses `B`.

Do not put a guard such as "first iteration only", "if cache exists", or
"only when extended mode is active" into `edge.condition` when the edge is still
part of the ordinary sequential spine. In `agentr` review HTML, `condition`,
`branch_group`, and `mutually_exclusive` are branch-visualization metadata. A
condition-only sequential edge will look like a branch even if there is no
alternate successor in the spec. For guarded sequential steps, keep
`edge.condition: null`, keep `branch_group: null`, keep
`mutually_exclusive: false`, and record the guard on the node or in plain edge
`notes`.

Use a loop edge only when the workflow actually cycles across runs or repeated
items. For a loop over input records, describe iteration in the node label or
rule instead of duplicating nodes per record.

## Subworkflow Nodes

For parent tasks with subworkflow nodes, set `subworkflow_ref` to the child
workflow spec path:

```text
nodes/<subworkflow_node_id>/docs/workflow_spec.yaml
```

Do not manually maintain `nested_workflow` in editable task specs unless the
user explicitly asks for a self-contained bundle. The file reference remains
the durable link. `agentr::render_task_preview()` can resolve task-local
`subworkflow_ref` paths and embed the child workflow into the standalone review
HTML at render time.

Keep the abstraction level consistent across parent and child specs. A parent
node should represent the reviewable conceptual step, and the child spec should
represent the internal mechanics of that step.

In practice:

- if the parent node is `Retrieve article markdown from ChatGPT UI`, do not
  also keep a separate top-level `ChatGPT generates article markdown` node for
  the same handoff
- if the child workflow already exposes the external LLM response-generation
  node, the parent should usually stay at the composite retrieval level
- if the parent workflow needs to show a semantic browser/page reload or other
  loop-control step, keep that step visible as its own node rather than folding
  it into an unrelated nearby node

## Review Notes

Record uncertainty instead of filling gaps silently:

- unknown schema fields
- unclear branch conditions
- implicit side effects
- manual steps that may or may not be decision gates
- external LLM outputs whose exact contract is not visible

Use `review_status: pending` and `review_notes` for unresolved details.
