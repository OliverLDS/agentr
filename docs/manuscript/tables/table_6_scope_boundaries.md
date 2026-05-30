# Table 6. Scope Boundaries Of agentr

Caption: Scope boundaries of `agentr`.

| Included in agentr | Excluded from agentr | Why the boundary matters |
|---|---|---|
| Cognitive and affective state representation | Full execution engines | Keeps the package focused on design, reasoning state, and human-guided scaffolding rather than operational runtime control. |
| Human-in-the-loop scaffolding and workflow refinement | Autonomous end-to-end task execution | Preserves explicit review and approval boundaries where human judgment is required. |
| Agent-spec and workflow design artifacts | Provider-specific LLM clients | Avoids coupling the framework to a specific model vendor or API surface. |
| Proposal lifecycle management | Transport backends such as email, Telegram, or X | Keeps communication infrastructure separate from the cognitive and scaffolding core. |
| Constrained prompt and action bridge for scaffolding | Unconstrained code execution through the model bridge | Maintains auditability, method-level control, and safer sequential semantics. |
| Persistence of workflow, proposal, and design artifacts | Domain-specific runtime applications | Supports portability of approved designs across downstream implementations instead of hardwiring one domain stack. |
| Implementation handoff prompts | Concrete multi-language runtime stacks | Makes approved artifacts portable while leaving implementation choices to downstream systems. |
