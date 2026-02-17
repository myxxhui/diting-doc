#!/usr/bin/env bash
# DNA–04_ Stage–L5 一致性校验脚本
# 从文档仓根目录运行，或传入文档仓根路径为第一参数。
# 输出：逐项 PASS/FAIL；全部通过时退出码 0。

set -e
DOC_ROOT="${1:-}"
if [[ -z "$DOC_ROOT" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  DOC_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi
if [[ ! -f "$DOC_ROOT/03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml" ]]; then
  echo "FAIL: 未找到 DNA 文件，请从 diting-doc 根目录运行或传入正确路径"
  exit 2
fi

DNA="$DOC_ROOT/03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml"
L5="$DOC_ROOT/05_成功标识与验证/02_验收标准.md"
BASE_04="$DOC_ROOT/04_阶段规划与实践"

stage_ids=()
while IFS= read -r line; do stage_ids+=("$line"); done < <(grep 'stage_id:' "$DNA" | sed 's/.*"\([^"]*\)".*/\1/')
l4_dirs=()
while IFS= read -r line; do l4_dirs+=("$line"); done < <(grep 'l4_stage_dir:' "$DNA" | sed 's/.*"\([^"]*\)".*/\1/')

# 去重：每个 Stage 目录只检查一次
declare -A seen
unique_dirs=()
for d in "${l4_dirs[@]}"; do
  [[ -z "${seen[$d]}" ]] && { seen[$d]=1; unique_dirs+=("$d"); }
done

FAIL=0

# (1) DNA 每个 l4_stage_dir 在 04_ 下存在
for dir in "${unique_dirs[@]}"; do
  if [[ -d "$BASE_04/$dir" ]]; then
    echo "PASS: 04_ 存在 Stage 目录 $dir"
  else
    echo "FAIL: 04_ 缺少 Stage 目录 $dir"
    FAIL=1
  fi
done

# (2) 每个 stage_id 在 L5 02_ 表中有对应行
for sid in "${stage_ids[@]}"; do
  if grep -q "| $sid |" "$L5"; then
    echo "PASS: L5 02_ 含 stage_id 行 $sid"
  else
    echo "FAIL: L5 02_ 缺少 stage_id 行 $sid"
    FAIL=1
  fi
done

# (3) 各 Stage 下步骤文档（01_～0N_）均含「可执行验证清单」与「本步骤失败时」
for dir in "${unique_dirs[@]}"; do
  stage_path="$BASE_04/$dir"
  step_ok=1
  for f in "$stage_path"/0*.md; do
    [[ ! -f "$f" ]] && continue
    has_verify=0; has_fail=0
    grep -q "可执行验证清单" "$f" && has_verify=1
    grep -q "本步骤失败时" "$f" && has_fail=1
    if [[ $has_verify -ne 1 || $has_fail -ne 1 ]]; then
      echo "FAIL: $dir/$(basename "$f") 缺少可执行验证清单或本步骤失败时"
      step_ok=0; FAIL=1
    fi
  done
  if [[ $step_ok -eq 1 ]]; then
    echo "PASS: $dir 步骤文档均含可执行验证清单与本步骤失败时"
  fi
done

if [[ $FAIL -eq 0 ]]; then
  echo "--- 全部检查通过"
  exit 0
else
  echo "--- 存在失败项"
  exit 1
fi
