#!/usr/bin/env bash
# DNA–00_–L5 一致性校验脚本
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
BASE_00="$DOC_ROOT/04_阶段规划与实践/00_交付流程步骤"

stage_ids=()
while IFS= read -r line; do stage_ids+=("$line"); done < <(grep 'stage_id:' "$DNA" | sed 's/.*"\([^"]*\)".*/\1/')
l4_dirs=()
while IFS= read -r line; do l4_dirs+=("$line"); done < <(grep 'l4_stage_dir:' "$DNA" | sed 's/.*"\([^"]*\)".*/\1/')

FAIL=0

# (1) DNA 每个 stage_id 在 00_ 下有对应 Stage 目录
for i in "${!stage_ids[@]}"; do
  sid="${stage_ids[$i]}"
  dir="${l4_dirs[$i]}"
  if [[ -d "$BASE_00/$dir" ]]; then
    echo "PASS: 00_ 存在 Stage 目录 $dir (stage_id=$sid)"
  else
    echo "FAIL: 00_ 缺少 Stage 目录 $dir (stage_id=$sid)"
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

# (3) 每个 Stage 的 01_ 均含「可执行验证清单」与「本步骤失败时」
for dir in "${l4_dirs[@]}"; do
  f="$BASE_00/$dir/01_本阶段实践与验证.md"
  if [[ ! -f "$f" ]]; then
    echo "FAIL: 01_ 不存在 $f"
    FAIL=1
    continue
  fi
  has_verify=0
  has_fail=0
  grep -q "可执行验证清单" "$f" && has_verify=1
  grep -q "本步骤失败时" "$f" && has_fail=1
  if [[ $has_verify -eq 1 && $has_fail -eq 1 ]]; then
    echo "PASS: 01_ 含可执行验证清单与本步骤失败时 ($dir)"
  else
    echo "FAIL: 01_ 缺少可执行验证清单或本步骤失败时 ($dir)"
    FAIL=1
  fi
done

if [[ $FAIL -eq 0 ]]; then
  echo "--- 全部检查通过"
  exit 0
else
  echo "--- 存在失败项"
  exit 1
fi
