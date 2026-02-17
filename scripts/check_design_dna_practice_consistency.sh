#!/usr/bin/env bash
# 设计↔DNA↔实践 三方一致性检查脚本
# 校验：04_ Stage 目录存在；dna_dev_workflow 中 l4_stage_dir 与 04_ 目录对应
# 引用：L4 与 03_/DNA 一体化重构计划
# 运行：从文档仓根目录（diting-doc/）执行 ./scripts/check_design_dna_practice_consistency.sh

set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
ERR=0

echo "=== 设计↔DNA↔实践 三方一致性检查 ==="

STAGES="Stage1_仓库与骨架 Stage2_数据采集与存储 Stage3_模块实践 Stage4_MoE与执行网关 Stage5_优化与扩展"

# 检查 04_ Stage 目录存在
for stage in $STAGES; do
  if [ ! -d "04_阶段规划与实践/${stage}" ]; then
    echo "⚠ 04_ 缺少目录 ${stage}"
    ERR=1
  fi
done

# 检查 dna_dev_workflow 中 l4_stage_dir 与 04_ 目录对应
if [ -f "03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml" ]; then
  for stage in $STAGES; do
    if ! grep -q "l4_stage_dir: \"${stage}\"" "03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml" 2>/dev/null && \
       ! grep -q "l4_stage_dir: ${stage}" "03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml" 2>/dev/null; then
      echo "⚠ dna_dev_workflow 中可能缺少 l4_stage_dir: ${stage}"
      ERR=1
    fi
  done
fi

# 检查 03_ _共享规约 存在
if [ ! -d "03_原子目标与规约/_共享规约" ]; then
  echo "⚠ 03_ 缺少 _共享规约 目录"
  ERR=1
fi

if [ $ERR -eq 0 ]; then
  echo "✅ 设计↔DNA↔实践 一致性检查通过"
else
  echo "❌ 存在不一致项，请修复"
  exit 1
fi
