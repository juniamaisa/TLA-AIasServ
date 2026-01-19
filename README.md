# TLA-AIasServ

# NOMS 2026: Proposition of 6G RAN KPI as a Cognitive Integrity metric for a Protocol-Based AI Lifecycle Framework
An work about *NWDAF-LifeCycle*


# NWDAF AI-as-a-Service — Formal Specification (TLA+)

This repository contains the **complete, executable TLA+ model** that accompanies the short paper

> **“Proposition of 6G RAN KPI as a Cognitive Integrity metric for a Protocol-Based AI Lifecycle Framework”**  
> (submitted to IEEE NOMS 2026).

The model formalises the two service-based interfaces proposed in the paper—**MTCP** (Model Training & Creation Protocol) and **MEP** (Model Execution Protocol)—and demonstrates, via the **TLC** model checker, that they satisfy the key safety and liveness requirements claimed in the manuscript.


---

# Quick start

1 · Prerequisites

- Java 8 or newer
- tla2tools.jar ≥ 2.19 → [download](https://github.com/tlaplus/tlaplus/releases)
(alternatively install the TLA+ Toolbox, which bundles the JAR)

2 · Run the model checker

Place MTCP_MEP.tla, MTCP_MEP.cfg and tla2tools.jar in the same directory

MacOS Execute:
```text
java -XX:+UseParallelGC -cp tla2tools.jar tlc2.TLC \
     -workers 4 \
     -config MTCP_MEP.cfg MTCP_MEP.tla
```
Windows execute:
```text
java -cp tla2tools.jar tlc2.TLC -config MTCP_MEP.cfg MTCP_MEP.tla
```


---


The model captures two service mechanisms introduced in the manuscript:

- **MTCP (Model Training & Creation Protocol)**: abstract lifecycle steps for creating/validating/publishing AI models.
- **MEP (Model Execution Protocol)**: abstract steps for loading a published model, executing inference, and reporting feedback.

## Model at a glance

**Entities (abstracted):**
- `NFs`: a finite set of Network Functions (e.g., `nfCU`, `nfUPF`) consuming AIaaS.
- `Versions`: a finite set of candidate model versions (e.g., `v1`, `v2`).

**Key state variables (see `MTCP_MEP.tla`):**
- `modelState[v] ∈ {"draft","valid","published","retired"}`: lifecycle state per model version.
- `loadStatus[n] ∈ {"none"} ∪ Versions`: which model version (if any) each NF has loaded.
- `publishLog ⊆ Versions`: versions that have been published at least once.
- `inferIssued ⊆ {<<n,v>>}` and `feedbackReported ⊆ {<<n,v>>}`: inference/feedback bookkeeping.
- Discrete time: `time ∈ Nat`, with timestamps `validAt`, `publishAt`, `inferAt`, `loadAt`.

**Main actions (message steps):**
- MTCP: `ValidateModel`, `PublishModel`, `RetireModel`
- MEP: `LoadModel`, `Infer`, `ReportFeedback`
- `Tick`: advances logical time by one discrete step

**Timing model and deadlines:**
The spec models time as discrete ticks and encodes deadlines via constants in `MTCP_MEP.cfg`:
`TauPublish`, `TauLoad`, `TauFeedback`, `TauNearRT`. A bounded model-checking horizon is enforced with `MaxTime` and `CONSTRAINT BoundTime`.

## Repository contents

```text
.
├── MTCP_MEP.tla            # TLA+ specification (state, actions, properties)
├── MTCP_MEP.cfg            # TLC constants + bounded-time constraint
├── run_tlc.sh              # Convenience script (Linux/macOS)
├── tla2tools.jar           # TLA+ tools JAR (you need to include after downloading this repository)
├── run_output.out          # Short TLC run summary
├── run_output.txt          # Full TLC output (Windows log; UTF-16)
├── run_output-infinity.txt # Additional run log (larger/longer execution)




---


# Contributions via Issues or Pull Requests are welcome!


Feel free to fork and extend the specification to cover message loss,
timeouts, or authentication scopes as described in the paper.


*Replace `juniamaisa` with your GitHub handle before committing.*


If you use this artefact, please cite our CNSM 2025 short paper:
@inproceedings{...}

