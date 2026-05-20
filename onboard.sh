#!/usr/bin/env bash
set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

BOLD="\033[1m"
CYAN="\033[1;36m"
GREEN="\033[1;32m"
RESET="\033[0m"

echo -e "${CYAN}=== ThisPatch 온보딩 ===${RESET}"
echo ""

# 1. 이름 선택
declare -A NAMES=(
  [1]="jueun"   [2]="byeongmin"
  [3]="jinwoo"  [4]="seung"  [5]="ichan"
)
declare -A KO=(
  [jueun]="주은" [byeongmin]="병민"
  [jinwoo]="진우" [seung]="세웅" [ichan]="이찬"
)

echo -e "${BOLD}팀원을 선택하세요:${RESET}"
for i in 1 2 3 4 5; do
  echo "  $i) ${KO[${NAMES[$i]}]} (${NAMES[$i]})"
done
echo -n "번호 입력: "
read choice
NAME="${NAMES[$choice]}"
if [[ -z "$NAME" ]]; then
  echo "잘못된 선택입니다." && exit 1
fi
echo -e "${GREEN}안녕하세요, ${KO[$NAME]}님!${RESET}"
echo ""

# 2. 프로젝트 개요
echo -e "${CYAN}── 프로젝트 개요 (CLAUDE.md) ──${RESET}"
cat "$REPO_ROOT/CLAUDE.md"
echo ""
echo -n "[Enter] 계속..."
read

# 3. 담당 로드맵
echo -e "${CYAN}── 담당 로드맵 (docs/contributions/${NAME}.md) ──${RESET}"
cat "$REPO_ROOT/docs/contributions/${NAME}.md"
echo ""
echo -n "[Enter] 계속..."
read

# 4. Git 워크플로우
echo -e "${CYAN}── Git 워크플로우 요약 ──${RESET}"
echo "  브랜치 구조: main ← dev ← feat/{이름}/{번호}-{설명}"
echo "  커밋 형식:   feat(1-1): 설명"
echo "  PR 대상:     항상 dev (main 직접 push 금지)"
echo "  머지 방식:   Squash and Merge, 본인 PR 본인 머지 금지"
echo ""
echo -n "[Enter] 계속..."
read

# 5. 브랜치 생성
echo -e "${CYAN}── 브랜치 생성 ──${RESET}"
git -C "$REPO_ROOT" switch dev 2>/dev/null || git -C "$REPO_ROOT" checkout dev
git -C "$REPO_ROOT" pull origin dev
echo -n "작업 번호 입력 (예: 0-1): "
read TASK_NUM
echo -n "작업 설명 입력 (예: learning): "
read TASK_DESC
BRANCH="feat/${NAME}/${TASK_NUM}-${TASK_DESC}"
git -C "$REPO_ROOT" checkout -b "$BRANCH"
echo ""
echo -e "${GREEN}브랜치 생성 완료: ${BRANCH}${RESET}"
echo ""
echo "작업 후 push:"
echo "  git push origin ${BRANCH}"
