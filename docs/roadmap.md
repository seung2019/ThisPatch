# 하이브리드 eBPF 탐지 엔진 — 전체 로드맵

프로젝트: 공급망 공격(npm/pypi) 탐지 PoC
아키텍처: USE (Unified Schema Event) — Falco 제거, Schema Registry 중심
모듈: 탐지 엔진 (Go + C) / 분석 엔진 (Python)

---

## 디렉토리 구조

```
Detect/
├── detection-engine/          ← [탐지 엔진] Go + C
│   ├── bpf/                   C eBPF 프로그램
│   ├── pkg/
│   │   ├── event/             Event struct
│   │   ├── schema/            Schema Registry
│   │   ├── cache/             ProcessCache
│   │   ├── enricher/          Context Enricher
│   │   ├── evaluator/         Rule Evaluator
│   │   ├── graph/             Graph Builder
│   │   └── alert/             Alert Manager
│   └── proto/                 공유 proto 정의 (양 모듈 공통)
│
└── analysis-engine/           ← [분석 엔진] Python
    ├── proto/                 공유 proto 사용
    ├── sequence/              Sequence Analyser
    ├── gnn/                   GraphSAGE / GAT
    ├── llm/                   LLM 분석 레이어
    └── server.py              gRPC 서버
```

---

## Phase 0. 학습 / 연구

1. `event_struct_research_findings` 완독 후 팀 공유 (담당: 진우)
   - Kunai / Tracee / Inspektor Gadget / Pixie 비교 분석 이해
   - Schema Registry, policy_mask bitmap, exec_uuid, CorrelationDrain 패턴 숙지

2. DARPA TC 데이터셋 확보
   - engagement 1~5 공식 릴리즈 또는 CADETS / THEIA / CLEARSCOPE 서브셋
   - GNN 훈련용 provenance graph 실제 데이터

3. arxiv 1610.06936 (DARPA Transparent Computing Program) 논문 이해 (전체)
   - Provenance graph 기반 APT 탐지 방법론
   - GNN 상관분석 레이어 설계의 직접 선행 연구

4. Tracee `chain_level{1,2,3}` YAML detector 분석 (전체)
   - 공급망 multi-event correlation 룰 표현 방식 학습
   - 경로: `tracee/examples/detectors/yaml/chain_level*.yaml`

---

## Phase 1. 아키텍처 확정 (팀 동기화)

5. PoC 범위 10개 op 확정
   - execve, clone, exit, open, connect, accept, kprobe_generic, lsm_block, mmap, mprotect

6. Schema Registry 필드 ~50개 정의 (`schema.go` 초안)
   - `proc.*`, `fd.*`, `container.*`, `supply_chain.*` 어휘 확정

7. `SemanticType` enum ~50개 정의 (`semantic.go`)
   - SemPID, SemFilePath, SemIPv4, SemPackageName, SemPublisherAge 등

8. `exec_uuid` 인코딩 방식 확정
   - Kunai ProcUuid 패턴: `(leader_boottime_ns << 64) | rand | tgid`

9. `policy_mask u64` BPF bitmap 정책 ID ↔ YAML rule 매핑 테이블 확정
   - Tracee `matched_policies` 패턴 차용, 64개 정책 수용

10. 모듈 간 proto 인터페이스 정의 (`detection-engine/proto/`)
    - `SubgraphMessage`: 탐지 엔진 → 분석 엔진 (nodes, edges, event_chain, package_meta)
    - `AnalysisResult`: 분석 엔진 → 탐지 엔진 (anomaly_score, attack_type, policy_feedback)
    - 이 계약이 확정되어야 두 모듈이 병렬 개발 가능

---

## [탐지 엔진] Phase 2. 커널 레이어 (C eBPF)

11. `event_info` + `event body union` C struct 정의
    - `policy_mask`, `exec_uuid`, `parent_exec_uuid` 필드 포함
    - 참조: `tetragon/bpf/lib/process.h:276`

12. body union 크기 compile-time assertion 추가
    - `_` arm 없는 switch — 새 variant 누락 시 컴파일 에러 강제
    - 참조: Kunai `events.rs:63-115` 패턴

13. BPF Map 정의
    - HASH, LPM_TRIE, HASH_OF_MAPS(per-container), LRU_HASH, RINGBUF
    - 참조: `tetragon/bpf/process/generic_maps.h`

14. LSM hook 구현 16종
    - bprm_check_security, file_open, socket_connect 등
    - 참조: `bpf_generic_lsm_core.c`

15. kprobe 구현 4종
    - memfd_create, setns, dup2, capset
    - 참조: `bpf_generic_kprobe.c`

16. `policy_mask` bitmap 셋 로직 구현 (BPF Map lookup → bit set)
    - 이벤트당 매칭 정책 비트마킹
    - 참조: Tracee `types.h:391-437`

17. 즉시 차단 구현 — fmod_ret(-EPERM), bpf_send_signal(SIGKILL)
    - LSM L1/L3, kprobe K1/K4 패턴
    - 참조: `bpf_enforcer.c`

18. Ring Buffer emit (`blocked=true/false` 플래그 포함)

---

## [탐지 엔진] Phase 3. Go User Space 레이어

19. `bpf2go`로 C struct Go mirror 자동 생성
    - cilium/ebpf 사용, Falco 필드 변환 없음

20. `Event` struct 정의 (`pkg/event/event.go`)
    - op별 body (Execve / Open / Connect) + enrichment 필드 (Container / SupplyChain / Ancestry)

21. Schema Registry 구현 (`pkg/schema/schema.go`)
    - `FieldDef{Name, Type, Semantic, Path, Resolver}` + `Schema[Op]` 맵
    - 참조: Tracee `core.go:310-400`

22. Ring Buffer Consumer 구현
    - 비동기 멀티스레드, 배치 처리
    - 참조: `tetragon/pkg/observer/observer_linux.go`

23. 동기 CorrelationEvent Drain 구현 ← 핵심
    - exec / clone을 timestamp-sorted dispatch 이전에 synchronously 처리
    - "npm → node → curl → connect" race condition 해결
    - 참조: Kunai `main.rs:2060-2095`

24. ProcessCache 구현 (exec_uuid LRU + /proc fallback)
    - `proc.aname[N]` resolver가 exec_uuid 체인 walk
    - 참조: `tetragon/pkg/process/cache.go`

25. Context Enricher 구현
    - K8s Pod/NS, container image, DNS/GeoIP, npm/pypi 패키지 메타데이터
    - 참조: `tetragon/pkg/k8s/`

26. Go Rule Evaluator 구현
    - YAML complex 조건 평가 (substring, regex, aname[N], time window)
    - `Schema.Lookup(field)`로 extractor resolve — filtercheck 클래스 X

27. YAML Rule Compiler — BPF Map 분기
    - 단순 조건 (exact match, CIDR, path prefix) → BPF Map atomic push

28. YAML Rule Compiler — Go Evaluator 분기
    - 복잡 조건 → AST leaf = Schema extractor

29. Alert Manager 구현 (JSON Lines 출력)
    - 필드: `rule_id, priority_score, output_fields, enforcement, correlation_id`

---

## [탐지 엔진] Phase 4. Graph Builder + gRPC 서버

30. Graph Builder 구현 — SemanticType dispatch
    - SemFilePath → file node, SemIPv4 → socket node, SemPackageName → package node
    - ProcessCache와 결합 — race condition 없이 subgraph 구성
    - 새 이벤트 타입 추가 시 graph builder 수정 불필요

31. gRPC 서버 구현 (Go, 탐지 엔진 측)
    - SubgraphMessage 스트리밍 → 분석 엔진으로 전송
    - AnalysisResult 수신 → Policy Feedback Loop 처리

32. Policy Feedback Loop 구현 (Go)
    - 분석 엔진의 고신뢰 anomaly → BPF Map 동적 차단 push
    - cilium/ebpf `Map.Put`

---

## [분석 엔진] Phase 5. Sequence Analyser + GNN + LLM (Python)

33. gRPC 클라이언트 구현 (Python)
    - 탐지 엔진에서 SubgraphMessage 수신
    - AnalysisResult 반환

34. Provenance graph 데이터 구조 설계
    - DARPA TC 논문(1610.06936) 기반, GNN 입력 포맷 확정

35. Sequence Analyser 구현 (30s~5min 슬라이딩 윈도우)
    - 공급망 공격 패턴 체인 탐지 (subgraph 시계열 분석)

36. GraphSAGE / GAT 모델 구현
    - 출력: `anomaly_score` 0~1 + 공급망 공격 유형 분류 레이블 (Ladisa 2023)

37. GNN 훈련 데이터 준비
    - npm postinstall 공격 시나리오 시뮬레이션 그래프
    - Backstabber's Knife Collection, MalOSS 데이터셋 활용

38. LLM 분석 레이어 구현 (Phase 2)
    - GNN 공급망 공격 유형 분류 결과를 입력으로 수신
    - Ladisa 2023 taxonomy 기반 분석 출력 (MITRE ATT&CK 매핑 X)
    - 출력: attack_type / mechanism / evidence_chain / risk_factors / confidence_reason

---

## Phase 6. 테스트 및 검증

39. Schema Registry unit test (탐지 엔진)
    - 필드 lookup, Path extractor, Resolver 전체 케이스

40. Rule Evaluator unit test (탐지 엔진)
    - proc.aname[N], substring, regex 조건 타입별

41. CorrelationDrain race-condition test (탐지 엔진)
    - connect 이벤트가 exec 이전 도착해도 정상 처리되는지 검증

42. gRPC 인터페이스 통합 테스트 (탐지 ↔ 분석)
    - SubgraphMessage 송수신, AnalysisResult 반환, Policy Feedback 적용

43. End-to-end 시나리오 — `npm postinstall → node → curl 외부 IP`
    - 탐지 엔진 Alert + 분석 엔진 anomaly_score 출력 확인

44. End-to-end 시나리오 — `newly-published pypi package → shell exec`
    - `publisher_age_days < 7` 탐지 확인

45. 성능 벤치마크
    - Ring Buffer throughput, Rule Evaluator latency
    - 목표: CPU 0.5~2%, ringbuf 부하 Falco 대비 1/10

---

## 병렬 진행 구간 요약

```
1~4    학습            → 각자 병렬
5~10   설계 + proto    → 팀 동기화 필요 (10번 확정 후 병렬 개발 시작)

proto 확정 이후 병렬:
  [탐지 엔진] 11~18   커널 C eBPF
  [탐지 엔진] 19~21   Go 기반 (Event, Schema)
  [분석 엔진] 34~35   GNN 데이터 구조 + Sequence Analyser

  [탐지 엔진] 22~29   Go 구현 (커널 완료 후)
  [분석 엔진] 36~37   GNN 모델 + 훈련

  [탐지 엔진] 30~32   Graph Builder + gRPC 서버
  [분석 엔진] 33      gRPC 클라이언트

39~45  통합 테스트     → 양 모듈 완료 후
38     Phase 2 (LLM)  → 통합 테스트 이후
```
