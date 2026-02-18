#!/usr/bin/env bash
# 按 stage_id 列出对应 04_ 步骤文档路径及建议复核的 DNA 键（DNA 变更时 L4 复核用）
# 用法：从文档仓根运行；可选参数 stage_id（如 stage1_01），不传则列出全部。
# 输出：每行「04_阶段规划与实践/l4_stage_dir/l4_step_doc」及「建议检查：dna_file, work_dir, verification_commands, l5_stage_anchor」。

set -e
DOC_ROOT="${1:-}"
FILTER_STAGE=""
if [[ -n "$DOC_ROOT" && "$DOC_ROOT" != stage* ]]; then
  FILTER_STAGE="${2:-}"
else
  FILTER_STAGE="$DOC_ROOT"
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  DOC_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi
DNA="$DOC_ROOT/03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml"
[[ ! -f "$DNA" ]] && { echo "FAIL: 未找到 $DNA"; exit 1; }

stage_id="" l4_dir="" l4_doc="" dna_file=""
print_block() {
  if [[ -n "$stage_id" && -n "$l4_dir" && -n "$l4_doc" ]]; then
    if [[ -z "$FILTER_STAGE" || "$FILTER_STAGE" == "$stage_id" ]]; then
      echo "04_阶段规划与实践/$l4_dir/$l4_doc  (stage_id=$stage_id)"
      echo "  建议检查 DNA 键: dna_file=${dna_file:-<见上>}, work_dir, verification_commands, l5_stage_anchor"
    fi
  fi
}
while IFS= read -r line; do
  if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*stage_id:[[:space:]]*\"(.*)\" ]]; then
    print_block
    stage_id="${BASH_REMATCH[1]}"
    l4_dir="" l4_doc="" dna_file=""
  elif [[ "$line" =~ l4_stage_dir:[[:space:]]*\"(.*)\" ]]; then
    l4_dir="${BASH_REMATCH[1]}"
  elif [[ "$line" =~ l4_step_doc:[[:space:]]*\"(.*)\" ]]; then
    l4_doc="${BASH_REMATCH[1]}"
  elif [[ "$line" =~ dna_file:[[:space:]]*\"(.*)\" ]]; then
    dna_file="${BASH_REMATCH[1]}"
  fi
done < "$DNA"
print_block
