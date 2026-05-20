# 분석 엔진 — 개발 컨텍스트

## 언어
- Python

## 아키텍처 요약
- TODO: GNN 모델 구조 / LLM 분석 레이어 확정 후 채우기
- 전체 아키텍처: ../docs/architecture.md
- 로드맵: ../docs/roadmap.md (Phase 5 담당)

## 인터페이스
- 입력: detection-engine gRPC `SubgraphMessage` (proto 미확정, 1-6번 작업)
- 출력: `AnalysisResult` (anomaly_score 0~1, attack_type, policy_feedback)

## 디렉토리 역할
- `proto/`    — 공유 proto 정의 (detection-engine과 공통)
- `gnn/`      — GraphSAGE / GAT 모델
- `llm/`      — LLM 분석 레이어 (attack_type → mechanism / evidence_chain / risk_factors)
- `server.py` — gRPC 서버

## 공격 유형 분류 기준
- Ladisa 2023 taxonomy 사용 (MITRE ATT&CK X)
- 유형: malicious_postinstall, dependency_confusion, typosquatting,
        account_takeover, ci_cd_compromise, build_system_compromise

## 훈련 데이터
- DARPA TC dataset (담당: docs/contributions/ 확인)
- Backstabber's Knife Collection, MalOSS
