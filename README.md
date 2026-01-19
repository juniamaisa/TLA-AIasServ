# CNSM 2025: A Protocol-Based Framework for AIaaS Lifecycle Management in 6G via NWDAF
An work about *AIasServ-LifeCycle*


# NWDAF AI-as-a-Service — Formal Specification (TLA+)

This repository contains the **complete, executable TLA+ model** that accompanies the short paper

> **“A Protocol-Based Framework for AIaaS Lifecycle Management in 6G via NWDAF”**  
> (submitted to IEEE CNSM 2025).

The model formalises the two service-based interfaces proposed in the paper—**MTCP** (Model Training & Creation Protocol) and **MEP** (Model Execution Protocol)—and demonstrates, via the **TLC** model checker, that they satisfy the key safety and liveness requirements claimed in the manuscript.

---

## Repository layout

```text
.
├── MTCP_MEP.tla   # TLA+ specification: variables, actions, properties
├── MTCP_MEP.cfg   # TLC configuration: constants, invariants, liveness goals
└── README.md      # This file
└── run_output     # Execution evidence
└── run_tlc.sh     # Execution script. On terminal type: 0bash run_tlc.sh


```
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


Expected summary is presented in the image.

# Verified properties

| Property                | Type      | Meaning in protocol terms                                  |
| ----------------------- | --------- | ---------------------------------------------------------- |
| **NoStaleLoad**         | Invariant | An NF never loads a model that has already been *retired*. |
| **DeadlockFreedom**     | Invariant | The system always has at least one enabled transition.     |
| **EventuallyPublished** | Liveness  | Every model marked *valid* is eventually *published*.      |
| **EventuallyFeedback**  | Liveness  | Every inference triggers feedback eventually.              |


✅ Temporal Properties Verified
This TLA+ specification defines and verifies eight temporal properties using the TLC model checker. These properties fall into two categories: safety (ensuring nothing bad happens) and liveness (ensuring something good eventually happens).

🔒 Safety Properties
ExactlyOncePublication
Ensures that a given modelURI is published at most once during the execution lifecycle.

NoStaleLoad
Guarantees that a model previously tagged as retired cannot be loaded by any Network Function (NF).

DeadlockFreedom
Ensures that the system never reaches a deadlock; at least one transition is always enabled.

🔁 Liveness Properties
EventuallyPublished
Asserts that every MTCP request issued by an NF eventually leads to a published model.

EventuallyFeedback
Ensures that every MEP inference operation is eventually followed by a metric report (MEP-Report).

🧩 Auxiliary/Structural Properties
AlwaysEventuallyValidState
Asserts that the system eventually reaches a stable state that satisfies all defined invariants.

NoDuplicateModelURI
Ensures that model URIs are unique and cannot be reused in future publications.

ProgressForEachNF
Verifies that all registered NFs progress through the expected model lifecycle phases (intent → publication → inference).


# Scaling the constants

To explore larger scenarios, edit MTCP_MEP.cfg:
```text
CONSTANTS
  NFs        = {nf1, nf2, nf3, nf4, nf5}
  Versions   = {v1, v2, v3}
  startModel = v2
```

# Relation to the paper

Section V-A (Formal Verification) of the manuscript cites this artefact.

### Running Example — Messages ↔ TLA+ Variables/States

| Phase | Message(s) | TLA+ Action(s) | Main Variables / State Updates |
|---|---|---|---|
| Init (k=0) | — | — | `state_NF = idle`, `state_MLO = idle`, `state_MRV = <>`, `modelURI = ⊥`, `ver = 0`, `kpi = ⊥`, `drift = 0` |
| 1 | MTCP-Request (NF → MLO) | `MTCP_Request` | `state_NF' = requested`; append intent/SLA to `queue_MLO` |
| 2 | MTCP-DataCollect (MLO → Data Exposure/NEF) | `MTCP_DataCollect` | `state_MLO' = collecting`; bind `datasetURI` |
| 3 | MTCP-Train (MLO → Compute) | `MTCP_Train` | `state_MLO' = training`; produce `ckpt` |
| 4 | MTCP-Validate (MRV) | `MTCP_Validate` | `state_MRV' = valid`; attach validation score + signature |
| 5 | MTCP-Publish (MRV) | `MTCP_Publish` | Insert `⟨modelURI, ver⟩` into `catalog`; increment `ver`; retire prior version(s) |
| 6 | MEP-Request (UPF/NF → DEE/MLO) | `MEP_Request` | Cache `modelURI` and execution profile at NF/DEE |
| 7 | MEP-Load → MEP-Infer (DEE in NF) | `MEP_Load`, `MEP_Infer` | `state_NF' = running`; compute `x̂[k]`; update `kpi` |
| 8 | MEP-Report (DEE → FA) & feedback | `MEP_Report` (+ policy trigger) | Set `drift'`; if `drift' > θ` then re-enter lifecycle via `MTCP_Request` (i.e., retraining, `ver++`) |

**Minimal TLC configuration used in the artifact:** `N = 3`, `V = 2`.


## TLC verification run summary (reproducibility evidence)
This table records the outcome of running the public TLA+/TLC artefact that accompanies the manuscript (Sec. V-A: Formal Verification of Lifecycle Protocols).The workflow and terminology follow Lamport’s TLA+/TLC methodology https://www.microsoft.com/en-us/research/wp-content/uploads/2018/05/book-02-08-08.pdf .


| **Parameter / Result**              | **Value**                                                                        |
| ----------------------------------- | -------------------------------------------------------------------------------- |
| TLC constants (from `MTCP_MEP.cfg`) | `NFs = {3}`; `Versions = {2}`                           |
| States explored (total / distinct)  | 18,500 / 65 |
| Maximum search depth                | 11                                                                      |
| Verified safety properties          | S1: ExactlyOncePublication; S2: NoStaleLoad; S3: DeadlockFreedom                 |
| Verified liveness properties        | L1: EventuallyPublished; L2: EventuallyFeedback                                  |
| Auxiliary properties                | NoDuplicateModelURI; ProgressForEachNF; AlwaysEventuallyValidState               |
| TLC workers / platform              | Java 8 or newer; tla2tools.jar ≥ 2.19                               |
| Command line                        | `java -cp tla2tools.jar tlc2.TLC -workers <N> -config MTCP_MEP.cfg MTCP_MEP.tla` |



## Symbols and EFSM states (reader’s guide to the spec)

This table maps the main variables, states, and actions in your EFSM-style TLA+ model to their informal meaning in the MTCP/MEP protocols described in Sec. III–IV of the manuscript. It is intended to make Sec. V-A easier to read and to align the formal model with the protocol narrative.

| **Name**                        | **Sort / Domain**                               | **Owner / Process** | **Informal meaning and invariants**                                                                                                                                             |
| ------------------------------- | ----------------------------------------------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `NF`                            | subset of *NFs*                                 | System              | Set of network functions participating in MTCP/MEP (e.g., AMF/SMF/UPF).                                                                                                         |
| `Versions`                      | finite set                                      | MRV                 | Set of candidate model versions.                                                                                                                                                |
| `modelURI`                      | `Versions → URI`                                | MRV                 | Immutable locator for each published model version; uniqueness required (S1).                                                                                                   |
| `state`                         | `Versions → {draft, valid, published, retired}` | MRV                 | Lifecycle state per version; a `retired` model cannot be loaded (S2).                                                                                                           |
| `registry`                      | finite map                                      | MRV                 | Catalogue of versions with signatures/metadata; holds only `valid` or `published`.                                                                                              |
| `loaded`                        | `NF → Versions ∪ {⊥}`                           | DEE                 | Currently loaded model per NF (`⊥` if none); must not be `retired` (S2).                                                                                                        |
| `pendingIntent`                 | subset of `NF`                                  | MLO                 | NFs with open MTCP requests; fairness ensures eventual handling (L1).                                                                                                           |
| `reportDue`                     | `NF → ℕ`                                        | DEE/FA              | Countdown to enforce bounded report delay; each inference triggers a report within `dmax` (L2).                                                                                 |
| `dmax`                          | ℕ                                               | System              | Upper bound on inference→report delay (abstract steps).                                                                                                                         |
| `K`, `a`                        | ℝ                                               | System              | Control-loop gain (`K`) and residual factor (`a`) used in the stability analysis of Sec. V-B.                                                                                   |
| **Actions (message steps)**     | —                                               | —                   | `MTCP_Request`, `MTCP_DataCollect`, `MTCP_Train`, `MTCP_Validate`, `MTCP_Publish`; `MEP_Request`, `MEP_Load`, `MEP_Infer`, `MEP_Report`. Guards include OAuth 2.0 scope checks. |
| **Properties (checked by TLC)** | —                                               | —                   | **S1** Exactly-once publication; **S2** No stale load; **S3** Deadlock freedom. **L1** Eventual publication; **L2** Eventual feedback within `dmax`.                            |


# Contributions via Issues or Pull Requests are welcome!


Feel free to fork and extend the specification to cover message loss,
timeouts, or authentication scopes as described in the paper.


*Replace `juniamaisa` with your GitHub handle before committing.*


If you use this artefact, please cite our CNSM 2025 short paper:
@inproceedings{...}
