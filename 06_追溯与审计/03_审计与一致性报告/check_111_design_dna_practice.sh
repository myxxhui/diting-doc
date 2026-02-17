#!/usr/bin/env bash
# 1:1:1 设计文档–步骤级 DNA–实践文档 一致性校验
# 对 dna_dev_workflow.workflow_stages 每步校验：design_doc、dna_file、04_ 步骤文件存在。
# 从文档仓根目录运行，或传入文档仓根路径为第一参数。
# 输出：逐项 PASS/FAIL；全部通过时退出码 0。

set -e
DOC_ROOT="${1:-}"
if [[ -z "$DOC_ROOT" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  DOC_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi
if [[ ! -f "$DOC_ROOT/03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml" ]]; then
  echo "FAIL: 未找到 dna_dev_workflow.yaml，请从 diting-doc 根目录运行或传入文档仓根路径"
  exit 2
fi

DNA="$DOC_ROOT/03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml"
FAIL=0

stage_ids=()
while IFS= read -r line; do stage_ids+=("$line"); done < <(grep 'stage_id:' "$DNA" | sed 's/.*"\([^"]*\)".*/\1/')
design_docs=()
while IFS= read -r line; do design_docs+=("$line"); done < <(grep 'design_doc:' "$DNA" | sed 's/.*"\([^"]*\)".*/\1/')
dna_files=()
while IFS= read -r line; do dna_files+=("$line"); done < <(grep 'dna_file:' "$DNA" | sed 's/.*"\([^"]*\)".*/\1/')
l4_dirs=()
while IFS= read -r line; do l4_dirs+=("$line"); done < <(grep 'l4_stage_dir:' "$DNA" | sed 's/.*"\([^"]*\)".*/\1/')
l4_docs=()
while IFS= read -r line; do l4_docs+=("$line"); done < <(grep 'l4_step_doc:' "$DNA" | sed 's/.*"\([^"]*\)".*/\1/')

BASE_04="$DOC_ROOT/04_阶段规划与实践"

for i in "${!stage_ids[@]}"; do
  sid="${stage_ids[$i]}"
  dd="${design_docs[$i]:-}"
  df="${dna_files[$i]:-}"
  ld="${l4_dirs[$i]:-}"
  lt="${l4_docs[$i]:-}"

  if [[ -n "$dd" ]] && [[ -f "$DOC_ROOT/$dd" ]]; then
    echo "PASS: design_doc 存在 $dd (stage_id=$sid)"
  elif [[ -n "$dd" ]]; then
    echo "FAIL: design_doc 不存在 $dd (stage_id=$sid)"
    FAIL=1
  fi

  if [[ -n "$df" ]] && [[ -f "$DOC_ROOT/$df" ]]; then
    echo "PASS: dna_file 存在 $df (stage_id=$sid)"
  elif [[ -n "$df" ]]; then
    echo "FAIL: dna_file 不存在 $df (stage_id=$sid)"
    FAIL=1
  fi

  if [[ -n "$ld" ]] && [[ -n "$lt" ]] && [[ -f "$BASE_04/$ld/$lt" ]]; then
    echo "PASS: L4 步骤存在 $BASE_04/$ld/$lt (stage_id=$sid)"
  elif [[ -n "$ld" ]] && [[ -n "$lt" ]]; then
    echo "FAIL: L4 步骤不存在 $BASE_04/$ld/$lt (stage_id=$sid)"
    FAIL=1
  fi

  # 可选：设计文档 TRACEBACK 中 L4 实践链接是否含 # 锚点（§5.4 索引锚点）
  if [[ -n "$dd" ]] && [[ -f "$DOC_ROOT/$dd" ]]; then
    if grep -q 'L4 实践.*#.*)' "$DOC_ROOT/$dd" 2>/dev/null; then
      echo "PASS: design_doc L4 链接含 # 锚点 (stage_id=$sid)"
    else
      echo "WARN: design_doc L4 链接建议带 # 锚点 (stage_id=$sid)"
    fi
  fi
done

if [[ $FAIL -eq 0 ]]; then
  echo "--- 1:1:1 校验全部通过"
  exit 0
else
  echo "--- 1:1:1 校验存在失败项"
  exit 1
fi
