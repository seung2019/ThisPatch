# 탐지 엔진 — 개발 컨텍스트

## 언어
- C (eBPF 커널 프로그램)
- Go (user space 데몬)

## 아키텍처 요약
- TODO: 커널 struct / BPF Map / Ring Buffer / Schema Registry 구현 확정 후 채우기
- 전체 아키텍처: ../docs/architecture.md
- 로드맵: ../docs/roadmap.md (Phase 2~4 담당)

## 핵심 참조 소스 (로컬)
- `/Users/seung/Desktop/Detect/탐지엔진_개발/tetragon-main/bpf/` — eBPF C 패턴
- `/Users/seung/Desktop/Detect/탐지엔진_개발/tetragon-main/pkg/` — Go user space 패턴

## 디렉토리 역할
- `bpf/`   — C eBPF 프로그램 (커널 probe, BPF Map, Ring Buffer)
- `pkg/`   — Go 패키지 (event, schema, cache, enricher, evaluator, graph, alert)

## 금지 패턴
- Falco filtercheck 클래스 호출 X
- Tetragon → Falco 필드 변환 어댑터 X
- `interface{}` / `[]Argument{Name, Value}` 패턴 X
