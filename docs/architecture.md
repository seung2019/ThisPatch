# 아키텍처 — USE (Unified Schema Event)

> TODO: 커널 struct / Schema Registry / proto 인터페이스 확정 후 채우기
>
> 참조 원본: `/Users/seung/Desktop/Detect/탐지엔진_개발/project_detection_engine_concept.md`

## 핵심 결정사항

- Falco 완전 제거 (필드 어댑터, AST 평가기 모두)
- Own Event Struct — bpf2go로 C struct Go mirror 자동 생성
- YAML Rule Compiler 이중 분기:
  - 단순 조건 → BPF Map (커널)
  - 복잡 조건 → Go Evaluator (user space)
- Process Tree가 user space 중심 데이터 구조 (룰 평가 + GNN 입력)

## 모듈 간 데이터 흐름 (개요)

```
syscall
  → eBPF Probe
  → BPF Map policy lookup → 즉시 차단 (fmod_ret / SIGKILL)
  → Ring Buffer
  → Go daemon (Event struct → Context Enricher → Process Tree)
  → [Rule Evaluator → Alert]
  → [Graph Builder → gRPC → Analysis Engine]
                               → Sequence Analyser
                               → GNN (anomaly_score + attack_type)
                               → LLM (mechanism / evidence_chain)
                               → policy_feedback → BPF Map
```

## 참조 설계 패턴

| 패턴 | 출처 |
|------|------|
| event_info + body union | Tetragon `msg_execve_event` |
| policy_mask u64 bitmap | Tracee `matched_policies` |
| exec_uuid (PID reuse 안전) | Kunai ProcUuid |
| 동기 CorrelationDrain | Kunai `main.rs:2060` |
| Schema Registry | Tracee `core.go:310-400` |
| SemanticType 컬럼 태그 | Pixie DataElement |
| HASH_OF_MAPS per-container | KubeArmor |
