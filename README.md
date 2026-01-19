# TLA-AIasServ

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

# 



---


# Contributions via Issues or Pull Requests are welcome!


Feel free to fork and extend the specification to cover message loss,
timeouts, or authentication scopes as described in the paper.


*Replace `juniamaisa` with your GitHub handle before committing.*


If you use this artefact, please cite our CNSM 2025 short paper:
@inproceedings{...}
