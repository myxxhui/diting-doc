#!/usr/bin/env bash
# 跨文档锚点可解析性校验（L4 锚点与引用体系优化，§5.4 / §7.5）
# 校验 L4 步骤文档中 l4-*-goal / l4-*-exit 与 L5 中 l5-stage-* 锚点存在。
# 运行：从文档仓根目录执行 ./scripts/check_anchor_resolvable.sh

set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
FAIL=0

echo "=== 跨文档锚点可解析性校验（L4/L5 显式锚点） ==="

# L4：各 Stage 步骤文档须含 l4-stageN-MM-goal 与 l4-stageN-MM-exit
check_l4_anchor() {
  local file="$1" anchor="$2"
  if grep -qE "id=[\"']${anchor}[\"']|<a id=[\"']${anchor}[\"']" "$file" 2>/dev/null; then
    echo "PASS: $anchor 于 $file"
  else
    echo "FAIL: $anchor 缺失于 $file"
    FAIL=1
  fi
}

stage1_steps="01 02 03"
stage2_steps="01 02 03 04 05"
stage3_steps="01 02 03 04 05 06 07"
stage4_steps="01 02 03"
stage5_steps="01 02 03 04"

for step in $stage1_steps; do
  for f in 04_阶段规划与实践/Stage1_仓库与骨架/${step}_*.md; do
    [[ -f "$f" ]] || continue
    check_l4_anchor "$f" "l4-stage1-${step}-goal"
    check_l4_anchor "$f" "l4-stage1-${step}-exit"
    break
  done
done

for step in $stage2_steps; do
  for f in 04_阶段规划与实践/Stage2_数据采集与存储/${step}_*.md; do
    [[ -f "$f" ]] || continue
    check_l4_anchor "$f" "l4-stage2-${step}-goal"
    check_l4_anchor "$f" "l4-stage2-${step}-exit"
    break
  done
done

for step in $stage3_steps; do
  for f in 04_阶段规划与实践/Stage3_模块实践/${step}_*.md; do
    [[ -f "$f" ]] || continue
    check_l4_anchor "$f" "l4-stage3-${step}-goal"
    check_l4_anchor "$f" "l4-stage3-${step}-exit"
    break
  done
done

for step in $stage4_steps; do
  for f in 04_阶段规划与实践/Stage4_MoE与执行网关/${step}_*.md; do
    [[ -f "$f" ]] || continue
    check_l4_anchor "$f" "l4-stage4-${step}-goal"
    check_l4_anchor "$f" "l4-stage4-${step}-exit"
    break
  done
done

for step in $stage5_steps; do
  for f in 04_阶段规划与实践/Stage5_优化与扩展/${step}_*.md; do
    [[ -f "$f" ]] || continue
    check_l4_anchor "$f" "l4-stage5-${step}-goal"
    check_l4_anchor "$f" "l4-stage5-${step}-exit"
    break
  done
done

# L5：02_验收标准须含各 stage_id 对应 l5-stage-*
L5_FILE="05_成功标识与验证/02_验收标准.md"
for sid in stage1_01 stage1_02 stage1_03 stage2_01 stage2_02 stage2_03 stage2_04 stage2_05 \
           stage3_01 stage3_02 stage3_03 stage3_04 stage3_05 stage3_06 stage3_07 \
           stage4_01 stage4_02 stage4_03 stage5_01 stage5_02 stage5_03 stage5_04; do
  anchor="l5-stage-${sid}"
  if grep -q "id=\"$anchor\"" "$L5_FILE" 2>/dev/null; then
    echo "PASS: $anchor 于 $L5_FILE"
  else
    echo "FAIL: $anchor 未在 $L5_FILE 中找到"
    FAIL=1
  fi
done

if [[ $FAIL -eq 0 ]]; then
  echo "--- 锚点可解析性校验通过"
  exit 0
else
  echo "--- 存在锚点缺失，请按 §5.4 补全显式锚点"
  exit 1
fi
