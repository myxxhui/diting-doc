#!/usr/bin/env bash
# 【可选】校验 04_ 步骤文档中「可执行验证清单」与 DNA 该 stage 的 verification_commands 的对应关系。
# 从文档仓根目录运行，或传入文档仓根路径为第一参数。
# 逻辑：对 dna_dev_workflow 中每步，读取 DNA 中 verification_commands[].cmd，检查对应 04_ 文档中是否出现该命令（或子串）。
# 输出：逐 stage PASS/FAIL；全部通过时退出码 0。

set -e
DOC_ROOT="${1:-}"
if [[ -z "$DOC_ROOT" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  DOC_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi
DNA="$DOC_ROOT/03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml"
BASE_04="$DOC_ROOT/04_阶段规划与实践"
[[ ! -f "$DNA" ]] && { echo "FAIL: 未找到 $DNA"; exit 1; }

# 简单实现：用 grep 提取每个 stage 的 cmd 行及 l4 路径，再检查 04_ 文档是否含该 cmd
FAIL=0
l4_dir="" l4_doc="" cur_l4=""
while IFS= read -r line; do
  if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*stage_id: ]]; then
    l4_dir="" l4_doc="" cur_l4=""
  elif [[ "$line" =~ l4_stage_dir:[[:space:]]*\"(.*)\" ]]; then
    l4_dir="${BASH_REMATCH[1]}"
  elif [[ "$line" =~ l4_step_doc:[[:space:]]*\"(.*)\" ]]; then
    l4_doc="${BASH_REMATCH[1]}"
    cur_l4="$BASE_04/$l4_dir/$l4_doc"
  elif [[ "$line" =~ cmd:[[:space:]]*\"(.*)\" ]]; then
    cmd="${BASH_REMATCH[1]}"
    if [[ -n "$cur_l4" && -f "$cur_l4" ]]; then
      if grep -qF "$cmd" "$cur_l4" 2>/dev/null; then
        echo "PASS: [验证命令] $cur_l4 含 cmd: $cmd"
      else
        echo "FAIL: [验证命令] $cur_l4 未找到 DNA cmd: $cmd"
        FAIL=1
      fi
    fi
  fi
done < "$DNA"

if [[ $FAIL -eq 0 ]]; then
  echo "--- 可执行验证清单与 DNA verification_commands 校验通过"
  exit 0
else
  echo "--- 存在失败项"
  exit 1
fi
