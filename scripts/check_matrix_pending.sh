#!/usr/bin/env bash
# 扫描 02_战略追溯矩阵.md 中「待填充」或「（待填充」行数，输出报告
# 建议运行：从文档仓根目录执行，如 cd diting-doc && ./scripts/check_matrix_pending.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MATRIX_FILE="$REPO_ROOT/06_追溯与审计/02_战略追溯矩阵.md"

if [[ ! -f "$MATRIX_FILE" ]]; then
  echo "[ERROR] 未找到 02_战略追溯矩阵.md"
  exit 1
fi

# 统计包含「待填充」或「（待填充」的行数（表格行，不含表头说明）
PENDING=$(grep -c -E '待填充|（待填充' "$MATRIX_FILE" 2>/dev/null || true)
PENDING=${PENDING:-0}

echo "战略追溯矩阵待填充项数量: $PENDING"
if [[ "$PENDING" -gt 0 ]]; then
  echo "涉及行（示例）："
  grep -n -E '待填充|（待填充' "$MATRIX_FILE" 2>/dev/null | head -20
  echo "[INFO] 建议在 L4 阶段完成或 L3 规约变更后更新矩阵（见协议 §6 / §7.1）"
fi
exit 0
