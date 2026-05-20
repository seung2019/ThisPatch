# 프로젝트 개요

공급망 공격(npm/pypi) 탐지 PoC — 하이브리드 eBPF 탐지 엔진

- 아키텍처: USE (Unified Schema Event) → docs/architecture.md
- 전체 로드맵: docs/roadmap.md
- 팀: 주은, 병민, 진우, 세웅, 이찬

# 모듈 구조

- `detection-engine/` → 커널 C eBPF + Go user space (`detection-engine/CLAUDE.md`)
- `analysis-engine/`  → Python GNN + LLM (`analysis-engine/CLAUDE.md`)
- 모듈 간 인터페이스: `analysis-engine/proto/` — SubgraphMessage / AnalysisResult (미확정)

# Git 워크플로우

## 브랜치 구조

```
main    ← 항상 동작하는 상태. direct push 금지. dev에서만 머지.
dev     ← 통합 브랜치. 모든 feat/* 브랜치의 머지 대상.
feat/*  ← 개인 작업 브랜치. 작업 단위: roadmap 항목 1개.
```

## 작업 시작 전 (필수)

```bash
git branch                       # 현재 브랜치 확인
git switch dev
git pull origin dev              # 반드시 최신화 후 브랜치 생성
git checkout -b feat/{이름}/{번호}-{설명}
```

## 커밋 메시지

```bash
git commit -m "feat(3-2): Event struct 정의"
git commit -m "fix(3-5): race condition 수정"
git commit -m "refactor(3-8): Rule Evaluator 구조 개선"
git commit -m "docs: architecture.md 업데이트"
```

## PR 규칙

- base 브랜치: **dev** (main 아님)
- PR 제목: `[3-2] Event struct 정의` (roadmap 번호 필수)
- **본인 PR 본인 머지 금지** — 다른 팀원 1명 approval 후 Squash and Merge
- PR 크기: 400줄 이하 권장

## dev → main 머지

- 마일스톤 완료 시, 팀 전체 확인 후 진행

# 팀 컨벤션

- 브랜치명: `feat/{이름}/{작업번호}-{설명}`
- 디렉토리: 영어 소문자 (`pkg/`, `detection-engine/`)
- 모듈 경계 파일(`proto/`) 수정 시 양쪽 담당자 동시 리뷰
- 상세 가이드: CONTRIBUTING.md

# 절대 규칙

- Co-Authored-By Claude / AI attribution 커밋 메시지 포함 **금지**
- `main` 브랜치 direct push **금지**
- `dev`에서 pull 없이 브랜치 생성 **금지**
