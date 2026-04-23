# Conceptual Figures

These figures summarize the core design ideas behind `agentr` as of `0.2.4.3`.

This page is the narrative hub for the figure set. For the full asset inventory, including all source, render, and caption files, see [figures/index.md](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/index.md). For the paired tables, see [tables/index.md](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/tables/index.md).

## Figure 1. From Human Workflow To Agentic Workflow Via Transitional Scaffolding

Shows the transition from an ad hoc human workflow to an approved agentic design through `agentr` as a scaffolding layer rather than an execution runtime.

- Source: [from_human_workflow_to_agentic_workflow_via_transitional_scaffolding.mmd](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/from_human_workflow_to_agentic_workflow_via_transitional_scaffolding.mmd)
- Render: [from_human_workflow_to_agentic_workflow_via_transitional_scaffolding.svg](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/from_human_workflow_to_agentic_workflow_via_transitional_scaffolding.svg)
- Caption: [from_human_workflow_to_agentic_workflow_via_transitional_scaffolding_caption.md](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/from_human_workflow_to_agentic_workflow_via_transitional_scaffolding_caption.md)

## Figure 2. Two-Axis Design Model Of agentr

Shows that subsystem design and workflow design are separate but interacting axes.

- Source: [two_axis_design_model_of_agentr.mmd](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/two_axis_design_model_of_agentr.mmd)
- Render: [two_axis_design_model_of_agentr.svg](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/two_axis_design_model_of_agentr.svg)
- Caption: [two_axis_design_model_of_agentr_caption.md](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/two_axis_design_model_of_agentr_caption.md)

## Figure 3. Package Architecture Of agentr

Shows the package layers, major public objects, constrained LLM bridge, and excluded execution-layer concerns.

- Source: [package_architecture_of_agentr.mmd](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/package_architecture_of_agentr.mmd)
- Render: [package_architecture_of_agentr.svg](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/package_architecture_of_agentr.svg)
- Caption: [package_architecture_of_agentr_caption.md](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/package_architecture_of_agentr_caption.md)

## Figure 4. Workflow And Agent-Design Proposal Lifecycle

Shows the explicit lifecycle states for workflow proposals and agent-spec proposals, including the rule that live approved state does not change until approval.

- Source: [workflow_and_agent_design_proposal_lifecycle.mmd](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/workflow_and_agent_design_proposal_lifecycle.mmd)
- Render: [workflow_and_agent_design_proposal_lifecycle.svg](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/workflow_and_agent_design_proposal_lifecycle.svg)
- Caption: [workflow_and_agent_design_proposal_lifecycle_caption.md](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/workflow_and_agent_design_proposal_lifecycle_caption.md)

## Figure 5. Before And After Workflow Refinement

Shows how a coarse economic-analysis workflow becomes more realistic when tacit charting, review, and publication knowledge is surfaced.

- Source: [before_and_after_workflow_refinement.dot](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/before_and_after_workflow_refinement.dot)
- Render: [before_and_after_workflow_refinement.svg](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/before_and_after_workflow_refinement.svg)
- Caption: [before_and_after_workflow_refinement_caption.md](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/before_and_after_workflow_refinement_caption.md)

## Figure 6. Human-LLM Scaffolding Interaction Loop

Shows the constrained and auditable loop from prompt generation through model response, validation, dispatch, human prompting, and next-round scaffolding.

- Source: [human_llm_scaffolding_interaction_loop.mmd](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/human_llm_scaffolding_interaction_loop.mmd)
- Render: [human_llm_scaffolding_interaction_loop.svg](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/human_llm_scaffolding_interaction_loop.svg)
- Caption: [human_llm_scaffolding_interaction_loop_caption.md](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/human_llm_scaffolding_interaction_loop_caption.md)

## Figure 7. Portability Of Approved Design Artifacts

Shows that the portable unit is the approved design artifact, especially the approved `AgentSpec` and approved workflow, not the downstream runtime.

- Source: [portability_of_approved_design_artifacts.mmd](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/portability_of_approved_design_artifacts.mmd)
- Render: [portability_of_approved_design_artifacts.svg](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/portability_of_approved_design_artifacts.svg)
- Caption: [portability_of_approved_design_artifacts_caption.md](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/portability_of_approved_design_artifacts_caption.md)

## Figure 8. Comparison Of Two Illustrative Design Cases

Shows how subsystem mix, tacit knowledge, and human gates differ across the economic-analysis case and the market-investment-suggestion-writing case.

- Source: [comparison_of_two_illustrative_design_cases.mmd](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/comparison_of_two_illustrative_design_cases.mmd)
- Render: [comparison_of_two_illustrative_design_cases.svg](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/comparison_of_two_illustrative_design_cases.svg)
- Caption: [comparison_of_two_illustrative_design_cases_caption.md](/Users/oliver/Documents/2025/_2025-05-11_XAgent/agentr/docs/figures/comparison_of_two_illustrative_design_cases_caption.md)
