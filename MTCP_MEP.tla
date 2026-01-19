--------------------------- MODULE MTCP_MEP ---------------------------
EXTENDS Naturals, TLC

CONSTANTS
  NFs,                \* ex.: {nfCU, nfUPF}
  Versions,           \* ex.: {v1, v2}
  startModel,         \* ∈ Versions, inicia "valid"
  TauPublish,         \* prazo p/ publicar após "valid"
  TauLoad,            \* prazo p/ cada NF carregar após "publish"
  TauFeedback,        \* prazo p/ feedback após infer
  TauNearRT,          \* prazo p/ frescor near-RT (≤ TauFeedback)
  ModelSizeKB,        \* tamanho do modelo quantizado (KB), use 300
  MaxTime             \* limite superior de tempo (ticks) p/ verificação


VARIABLES
  modelState,         \* [v -> "draft"|"valid"|"published"|"retired"]
  loadStatus,         \* [n -> "none"|v]
  publishLog,         \* SUBSET Versions (já publicados ao menos uma vez)
  inferIssued,        \* SUBSET {<<n,v>>}
  feedbackReported,   \* SUBSET {<<n,v>>}
  time,               \* Nat (ticks)
  validAt,            \* [v -> Nat]   momento do Validate
  publishAt,          \* [v -> Nat]   momento do Publish
  inferAt,            \* [<<n,v>> -> Nat] momento do Infer
  loadAt              \* [n -> Nat]   momento do último Load

vars == << modelState, loadStatus, publishLog,
           inferIssued, feedbackReported,
           time, validAt, publishAt, inferAt, loadAt >>

States == {"draft","valid","published","retired"}
Pairs  == { <<n,v>> : n \in NFs, v \in Versions }

HasOtherActive(v) ==
  \E w \in Versions :
    /\ w # v
    /\ (modelState[w] = "valid" \/ modelState[w] = "published")

(* ---------------- bound de tempo para usar no .cfg (CONSTRAINT BoundTime) --- *)
BoundTime == time <= MaxTime

(* ---------------- initial ------------------------------------------ *)
Init ==
  /\ modelState  = [v \in Versions |-> IF v = startModel THEN "valid" ELSE "draft"]
  /\ loadStatus  = [n \in NFs |-> "none"]
  /\ publishLog  = {}
  /\ inferIssued = {}
  /\ feedbackReported = {}
  /\ time = 0
  /\ validAt  = [v \in Versions |-> 0]
  /\ publishAt= [v \in Versions |-> 0]
  /\ inferAt  = [p \in Pairs    |-> 0]
  /\ loadAt   = [n \in NFs      |-> 0]

(* ---------------- MTCP actions ------------------------------------- *)
ValidateModel(v) ==
  /\ modelState[v] = "draft"
  /\ modelState' = [modelState EXCEPT ![v] = "valid"]
  /\ validAt'    = [validAt   EXCEPT ![v] = time]
  /\ UNCHANGED <<loadStatus, publishLog, inferIssued, feedbackReported,
                publishAt, inferAt, loadAt, time>>

PublishModel(v) ==
  /\ modelState[v] = "valid"
  /\ modelState' = [modelState EXCEPT ![v] = "published"]
  /\ publishLog' = publishLog \cup {v}
  /\ publishAt'  = [publishAt EXCEPT ![v] = time]
  /\ UNCHANGED <<loadStatus, inferIssued, feedbackReported,
                validAt, inferAt, loadAt, time>>

RetireModel(v) ==
  /\ modelState[v] = "published"
  /\ HasOtherActive(v)
  /\ modelState' = [modelState EXCEPT ![v] = "retired"]
  /\ UNCHANGED <<loadStatus, publishLog, inferIssued, feedbackReported,
                validAt, publishAt, inferAt, loadAt, time>>

(* ---------------- MEP actions -------------------------------------- *)
LoadModel(n,v) ==
  /\ modelState[v] = "published"
  /\ loadStatus' = [loadStatus EXCEPT ![n] = v]
  /\ loadAt'     = [loadAt    EXCEPT ![n] = time]
  /\ UNCHANGED <<modelState, publishLog, inferIssued, feedbackReported,
                validAt, publishAt, inferAt, time>>

Infer(n,v) ==
  /\ loadStatus[n] = v
  /\ inferIssued' = inferIssued \cup {<<n,v>>}
  /\ inferAt'     = [inferAt EXCEPT ![<<n,v>>] = time]
  /\ UNCHANGED <<modelState, loadStatus, publishLog, feedbackReported,
                validAt, publishAt, loadAt, time>>

ReportFeedback(n,v) ==
  /\ <<n,v>> \in inferIssued
  /\ feedbackReported' = feedbackReported \cup {<<n,v>>}
  /\ UNCHANGED <<modelState, loadStatus, publishLog, inferIssued,
                validAt, publishAt, inferAt, loadAt, time>>

Tick ==
  /\ time' = time + 1
  /\ UNCHANGED <<modelState, loadStatus, publishLog, inferIssued, feedbackReported,
                validAt, publishAt, inferAt, loadAt>>

Next ==
      \E v1 \in Versions : ValidateModel(v1)
  \/  \E v2 \in Versions : PublishModel(v2)
  \/  \E v3 \in Versions : RetireModel(v3)
  \/  \E n1 \in NFs : \E v4 \in Versions : LoadModel(n1,v4)
  \/  \E n2 \in NFs : \E v5 \in Versions : Infer(n2,v5)
  \/  \E n3 \in NFs : \E v6 \in Versions : ReportFeedback(n3,v6)
  \/  Tick

(* ---------------- safety ------------------------------------------- *)
S11_ExactlyOncePublication ==
  \A v \in Versions : v \in publishLog => ~ENABLED PublishModel(v)

S2_NoStaleLoad ==
  \A n \in NFs :
    LET v == loadStatus[n] IN v = "none" \/ modelState[v] # "retired"

S3_NoRetireWithoutReplacement ==
  \A v \in Versions : modelState[v] = "retired" => HasOtherActive(v)

S4_WellFormedFeedback ==
  \A p \in feedbackReported : p \in inferIssued

S5_A1MEPConsistency ==
  \A n \in NFs :
    LET v == loadStatus[n] IN v = "none" \/ v \in Versions

S6_NoCrossDomainDesync ==
  \A n1 \in NFs : \A n2 \in NFs :
    LET v1 == loadStatus[n1] IN
    LET v2 == loadStatus[n2] IN
      v1 = "none" \/ v2 = "none" \/ v1 = v2

S6b_LoadedIsPublished ==
  \A n \in NFs :
    loadStatus[n] \in Versions => modelState[loadStatus[n]] = "published"

NoRevertAfterPublish ==
  \A v \in Versions : v \in publishLog => modelState[v] \in {"published","retired"}

(* ---------------- deadlines (liveness com prazo) ------------------- *)
L1_BoundedPublication ==
  \A v \in Versions :
    validAt[v] # 0 => ( time <= validAt[v] + TauPublish \/ modelState[v] = "published" )

L0_BoundedLoadAllNFs ==
  \A v \in Versions : \A n \in NFs :
    (publishAt[v] # 0 /\ modelState[v] = "published")
      => ( time <= publishAt[v] + TauLoad \/ loadStatus[n] = v )

L2_BoundedFeedback ==
  \A p \in Pairs :
    inferAt[p] # 0 => ( time <= inferAt[p] + TauFeedback \/ p \in feedbackReported )

L3_NearRTFreshness ==
  \A p \in Pairs :
    inferAt[p] # 0 => ( time <= inferAt[p] + TauNearRT \/ p \in feedbackReported )

Spec == Init /\ [][Next]_vars /\ SF_vars(Tick)

THEOREM Spec => [] S11_ExactlyOncePublication
THEOREM Spec => [] S2_NoStaleLoad
THEOREM Spec => [] S3_NoRetireWithoutReplacement
THEOREM Spec => [] S4_WellFormedFeedback
THEOREM Spec => [] S5_A1MEPConsistency
THEOREM Spec => [] S6_NoCrossDomainDesync
THEOREM Spec => [] S6b_LoadedIsPublished
THEOREM Spec => [] NoRevertAfterPublish

THEOREM Spec => [] L1_BoundedPublication
THEOREM Spec => [] L0_BoundedLoadAllNFs
THEOREM Spec => [] L2_BoundedFeedback
THEOREM Spec => [] L3_NearRTFreshness
========================================================================