# Conceptual Figures

The old static manuscript figure set has been removed because it reflected an
earlier understanding of `agentr` and relied mostly on Mermaid-generated SVGs.

Current conceptual figures should be generated from package-native specs and
renderers whenever possible. This keeps diagrams aligned with the actual object
schema and review UI:

- use `render_workflow_graphviz()` for workflow graphs
- use `render_knowledge_graphviz()` for graph-shaped knowledge or memory
- use `render_memory_schema_graphviz()` for memory schemas
- use `render_schema_shape_graphviz()` for input and output schema shapes
- use `export_design_review_html()` for integrated task review pages

For task-local projects, prefer rendering from editable YAML specs under the
task `docs/` folder. JSON is useful for machine interchange, and RDS/R6 remains
useful for R-native helpers or cache artifacts. See [Spec Formats](spec_formats.md)
and [Design Review Layer](design_review_layer.md).

If a future manuscript needs static SVGs, generate them from representative
`WorkflowSpec`, `KnowledgeSpec`, or `MemorySpec` examples
instead of maintaining separate hand-authored Mermaid diagrams.
