# Table 1. Core Objects In agentr

Caption: Core objects in `agentr` and their roles in the framework.

| Object | Type | Role in the framework |
|---|---|---|
| `CognitiveState` | R6 class | Stores structured cognitive state such as beliefs, knowledge, goals, task context, confidence, and update history. |
| `AffectiveState` | R6 class | Stores the optional affective layer, including affect dimensions, decay, inertia-aware updates, and summaries. |
| `AgentCore` | R6 class | Minimal agent container that holds cognition and optional affect, and serves as the base object that can attach a `Scaffolder`. |
| `Scaffolder` | R6 class | Main human-in-the-loop scaffolding interface for task evaluation, workflow elicitation, subsystem selection, proposal handling, review, and approval. |
| `SubsystemSpec` | R6 class | Sparse specification of selected subsystems such as `RWM`, `PG`, `AE`, `IAC`, and `LA`, including their configuration objects. |
| `AgentSpec` | R6 class | Top-level approved agent-design artifact combining task, subsystem selection, workflow, interfaces, and implementation-oriented metadata. |
| `MemorySpec` | R6 class | Reviewable schema for context, semantic, episodic, and procedural memory fields. |
| `KnowledgeSpec` | R6 class | Curated narrative knowledge, first-class graph knowledge, and future vector-reference metadata. |
| `WorkflowProposal` | R6 class | Represents one candidate workflow proposal and its lifecycle state during review, discussion, approval, rejection, or supersession. |
| `WorkflowProposalState` | R6 class | Stores the approved workflow together with workflow proposal history and lifecycle management operations. |
| `MemoryProposalState` | R6 class | Stores the approved memory schema together with candidate memory-schema proposals. |
| `KnowledgeProposalState` | R6 class | Stores approved narrative knowledge together with curated knowledge proposals. |
| `KnowledgeGraphProposalState` | R6 class | Stores approved graph knowledge together with graph-node and graph-edge proposals. |
| `DesignReviewSpec` | R6 class | Packages workflow, memory, knowledge, proposal-state, and feedback-schema sections for standalone HTML review. |
| `IntelligentAgent` | R6 class | Runtime-oriented wrapper built from an `AgentSpec`, used to carry selected subsystem configuration and runtime state without defining the execution stack itself. |
