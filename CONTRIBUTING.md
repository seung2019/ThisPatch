# 기여 가이드

## 브랜치 전략

```
main ──────────────────────────────── 배포 가능 상태, direct push 금지
  ↑ (마일스톤 완료 시 PR)
dev ────────────────────────────────── 통합 브랜치, 모든 feat/* PR의 target
  ↑ feat PR (1 approval 필수)
feat/{이름}/{번호}-{설명} ──────────── 개인 작업 브랜치
```

---

## 작업 흐름

### 1. 작업 시작 전 (매번 필수)

```bash
git branch                    # 현재 브랜치 확인
git switch dev
git pull origin dev           # 반드시 최신화 후 브랜치 생성
git checkout -b feat/{이름}/{번호}-{설명}
# 예) feat/seung/3-2-event-struct
```

### 2. 커밋

```bash
git status                    # 작업물 확인
git add .
git commit -m "{type}({번호}): {설명}"
```

커밋 메시지 타입:
```bash
git commit -m "feat(3-2): Event struct 정의"
git commit -m "fix(3-5): CorrelationDrain race condition 수정"
git commit -m "refactor(3-8): Rule Evaluator 구조 개선"
git commit -m "docs: architecture.md 업데이트"
```

### 3. PR 올리기 전 최신화

```bash
git push origin feat/seung/3-2-event-struct
# GitHub 터미널 링크 또는 직접 접속 → dev에 PR 생성
# Reviewer 1명 지정 (본인 제외)
```

PR 제목: `[3-2] Event struct 정의`

### 4. 리뷰 & 머지

- Reviewer Approve → **Squash and Merge**
- 머지 후 원격 feat 브랜치 삭제 (GitHub UI)

### 5. 머지 후 로컬 정리

```bash
git switch dev
git pull origin dev           # 최신화
git branch -D feat/seung/3-2-event-struct   # 로컬 브랜치 삭제
git branch                    # 확인
```

---

## 작업 중 dev 최신화가 필요할 때 (stash)

```bash
git stash -u                  # 현재 작업 임시 저장
git switch dev
git pull origin dev
git switch feat/seung/3-2-event-struct
git stash pop                 # 작업 복원
```

---

## 로컬 변경사항 버리고 원격 dev로 초기화

```bash
git reset HEAD .              # 스테이징 해제
git checkout -- .             # 로컬 변경사항 버리기
git clean -fd                 # untracked 파일 삭제
git pull origin dev           # 원격 dev 받기
```

---

## GitHub 브랜치 보호 규칙 (레포 생성 후 Settings → Branches)

`main` 브랜치:
- [x] Require a pull request before merging
- [x] Require approvals: **1**
- [x] Dismiss stale pull request approvals when new commits are pushed
- [x] Do not allow bypassing the above settings

`dev` 브랜치:
- [x] Require a pull request before merging
- [x] Require approvals: **1**

---

## 네이밍 규칙

| 대상 | 규칙 | 예시 |
|------|------|------|
| 브랜치명 | `feat/{이름}/{번호}-{설명}` | `feat/seung/3-2-event-struct` |
| 디렉토리 | 영어 소문자 | `pkg/`, `detection-engine/` |
| Go 파일 | snake_case | `event_struct.go` |
| Python 파일 | snake_case | `gnn_model.py` |
| C 파일 | snake_case | `bpf_execve.c` |

---

## PR 크기 권장

- **400줄 이하** 유지
- 초과 시 roadmap 항목 단위로 분리 검토

---

## 금지

- `main` 브랜치 direct push
- `dev` pull 없이 브랜치 생성
- 본인 PR 본인 머지
- 커밋 메시지에 AI attribution (`Co-Authored-By: Claude` 등)
