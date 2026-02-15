#!/usr/bin/env bash
# L5 与 DNA 一致性校验（功能验收表锚点、workflow_stages stage_id）
# 约定：L5 02_ 功能验收表锚点与 global_const product_scope.phases[].steps[].l5_anchor 一致；
#       L5 02_ workflow_stages 表行集与 dna_dev_workflow workflow_stages[].stage_id 一致。
# 从文档仓根目录运行，或传入文档仓根路径为第一参数。退出码 0 表示通过。

set -e
DOC_ROOT="${1:-}"
if [[ -z "$DOC_ROOT" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  DOC_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

DNA_WORKFLOW="$DOC_ROOT/03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml"
DNA_GLOBAL="$DOC_ROOT/03_原子目标与规约/_System_DNA/global_const.yaml"
L5_02="$DOC_ROOT/05_成功标识与验证/02_验收标准.md"

FAIL=0

# 1) workflow_stages: 每个 DNA stage_id 在 L5 02_ 中有对应锚点 l5-stage-*
echo "=== 1) workflow_stages stage_id vs L5 锚点 ==="
for stage in s0_pre s0 s1 s1b s2 s3 s4; do
  anchor="l5-stage-$stage"
  if grep -q "id=\"$anchor\"" "$L5_02" || grep -q "l5-stage-$stage" "$L5_02"; then
    echo "PASS: $stage -> $anchor 存在于 L5 02_"
  else
    echo "FAIL: $stage -> $anchor 未在 L5 02_ 中找到"
    FAIL=1
  fi
done

# 2) 功能验收表：DNA 中 l5_anchor 非 null 的应在 L5 02_ 中出现
echo ""
echo "=== 2) product_scope.phases[].steps[].l5_anchor vs L5 功能验收表 ==="
# 从 YAML 提取 l5_anchor 值（简单 grep，要求缩进为 l5_anchor: "l5-func-XX"）
while read -r line; do
  anchor=$(echo "$line" | sed -n 's/.*l5_anchor:[[:space:]]*"\(l5-func-[0-9]*\)".*/\1/p')
  [[ -z "$anchor" ]] && continue
  if grep -q "^\`$anchor\`" "$L5_02" || grep -q "$anchor" "$L5_02"; then
    echo "PASS: $anchor 存在于 L5 02_"
  else
    echo "FAIL: DNA 中有 $anchor，L5 02_ 中未找到"
    FAIL=1
  fi
done < <(grep -E "l5_anchor:\s*\"l5-func-" "$DNA_GLOBAL" 2>/dev/null || true)

# 若 DNA 中无 l5-func 行，仅提示
if ! grep -q "l5_anchor:.*l5-func-" "$DNA_GLOBAL" 2>/dev/null; then
  echo "INFO: DNA global_const 中未找到 l5_anchor（l5-func-*），跳过功能表锚点校验"
fi

# 3) Stage 01_ 是否引用 DNA 的 work_dir、verification_commands、l5_stage_anchor
echo ""
echo "=== 3) Stage 01_ 引用 DNA work_dir / verification_commands / l5_stage_anchor ==="
BASE_04="$DOC_ROOT/04_阶段规划与实践/00_交付流程步骤"
STAGE_DIRS=(
  "Stage0_pre_仓库与L3就绪"
  "Stage0_骨架期"
  "Stage1_逻辑填充期"
  "Stage1b_Mock数据验证准出"
  "Stage2_Docker统一环境期"
  "Stage3_K3s测试开发期"
  "Stage4_与流水线衔接"
)
for dir in "${STAGE_DIRS[@]}"; do
  f="$BASE_04/$dir/01_本阶段实践与验证.md"
  if [[ ! -f "$f" ]]; then
    echo "FAIL: $f 不存在"
    FAIL=1
    continue
  fi
  missing=""
  grep -q "work_dir" "$f" || missing="work_dir"
  grep -q "verification_commands" "$f" || missing="$missing verification_commands"
  grep -q "l5_stage_anchor" "$f" || missing="$missing l5_stage_anchor"
  if [[ -z "$missing" ]]; then
    echo "PASS: $dir/01_ 含 work_dir、verification_commands、l5_stage_anchor 引用"
  else
    echo "FAIL: $dir/01_ 缺少 DNA 键引用: $missing"
    FAIL=1
  fi
done

[[ $FAIL -eq 0 ]] && echo "" && echo "全部通过。" || true
exit $FAIL
