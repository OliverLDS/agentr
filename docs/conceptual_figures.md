# Conceptual Figures

These figures summarize the core design ideas behind `agentr` as of `0.2.3`.

## Figure 1. From Human Workflow To Agentic Workflow

This figure shows the transitional scaffolding story: a human starts with an ad hoc workflow, `Scaffolder` turns it into an explicit reviewed design artifact, and only then does implementation move into an agentic stack.

```mermaid
flowchart LR
    classDef human fill:#f7f1e8,stroke:#9a6735,stroke-width:2px;
    classDef scaffold fill:#eaf4ee,stroke:#3f7559,stroke-width:2px;
    classDef proposal fill:#fbf4df,stroke:#a78622,stroke-width:2px;
    classDef approved fill:#e4f1e8,stroke:#3b8459,stroke-width:2px;
    classDef runtime fill:#edf2fb,stroke:#4a6ea9,stroke-width:2px;

    A[Human task and ad hoc workflow] --> B[Scaffolder evaluation and decomposition]
    B --> C[Workflow proposal preview]
    C --> D[Human critique and refinement]
    D --> E[Approved workflow plus agent design]
    E --> F[Implementation handoff to coding or runtime stack]

    class A,D human;
    class B scaffold;
    class C proposal;
    class E approved;
    class F runtime;
```

## Figure 2. Two-Axis Design Model

`agentr` keeps subsystem design separate from workflow design. Subsystems define what kind of agent is needed; workflow defines how work is organized and reviewed.

```mermaid
flowchart TB
    classDef subsystem fill:#edf3fb,stroke:#4a6ea9,stroke-width:2px;
    classDef workflow fill:#f8eedf,stroke:#a6782a,stroke-width:2px;
    classDef center fill:#e7f1ea,stroke:#3b8459,stroke-width:2.5px;

    subgraph S[Subsystem axis]
        RWM[RWM<br/>memory and reflective state]
        PG[PG<br/>planning and goal management]
        AE[AE<br/>action execution]
        IAC[IAC<br/>interaction and communication]
        LA[LA<br/>learning and adaptation]
    end

    subgraph W[Workflow axis]
        N[Nodes]
        E[Edges]
        RU[Rules]
        RV[Review state]
        HG[Human-required gates]
    end

    S --> X[Agent design]
    W --> X

    class RWM,PG,AE,IAC,LA subsystem;
    class N,E,RU,RV,HG workflow;
    class X center;
```

## Figure 3. Proposal Lifecycle

The approved workflow remains stable until a proposal is explicitly accepted.

```mermaid
flowchart LR
    classDef approved fill:#e4f1e8,stroke:#3b8459,stroke-width:2px;
    classDef proposal fill:#fbf4df,stroke:#a78622,stroke-width:2px;
    classDef rejected fill:#f8e8e8,stroke:#b25b5b,stroke-width:2px;
    classDef handoff fill:#edf2fb,stroke:#4a6ea9,stroke-width:2px;

    A[Initial approved workflow] --> B[Preview proposal]
    B --> C[Proposal under discussion]
    C --> D[Approved proposal]
    D --> E[Implementation handoff]

    C --> F[Rejected or superseded proposal]
    F -. keeps current approved workflow .-> A

    class A,D approved;
    class B,C proposal;
    class F rejected;
    class E handoff;
```

## Figure 4. Before And After Refinement Example

Human critique should make the workflow more realistic, not just longer.

```mermaid
flowchart TB
    classDef before fill:#f8eedf,stroke:#a6782a,stroke-width:2px;
    classDef after fill:#e7f1ea,stroke:#3b8459,stroke-width:2px;
    classDef gate fill:#f8e8e8,stroke:#b25b5b,stroke-width:2.5px;

    subgraph Before[Before critique]
        B1[Draft report]
        B2[Publish report]
        B1 --> B2
    end

    subgraph After[After human critique]
        A1[Draft report]
        A2[Check evidence and assumptions]
        A3[Human approval gate]
        A4[Publish report]
        A1 --> A2 --> A3 --> A4
    end

    class B1,B2 before;
    class A1,A2,A4 after;
    class A3 gate;
```

## Figure 5. Portability Of Approved Design Artifacts

`agentr` is the scaffolding environment. The approved artifacts should remain portable to other implementation stacks.

```mermaid
flowchart LR
    classDef scaffold fill:#eaf4ee,stroke:#3f7559,stroke-width:2px;
    classDef artifact fill:#fbf4df,stroke:#a78622,stroke-width:2px;
    classDef runtime fill:#edf2fb,stroke:#4a6ea9,stroke-width:2px;

    subgraph AG[agentr]
        T[Task evaluation]
        S[Subsystem selection]
        W[Workflow design and review]
        A[Approved AgentSpec]
        F[Approved workflow]
        T --> S --> W --> A
        W --> F
    end

    A --> R1[R runtime package]
    A --> R2[Python agent runtime]
    A --> R3[LLM orchestration stack]
    F --> R1
    F --> R2
    F --> R3

    class T,S,W scaffold;
    class A,F artifact;
    class R1,R2,R3 runtime;
```
