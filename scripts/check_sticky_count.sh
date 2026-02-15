#!/usr/bin/env bash
# 检查 _增量便利贴 目录下文件数量，超过 9 时告警（熔断阈值 ≥10）
# 建议运行：从文档仓根目录执行，如 cd diting-doc && ./scripts/check_sticky_count.sh
# 或：bash scripts/check_sticky_count.sh（从 diting-doc 根目录）

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STICKY_DIR="$REPO_ROOT/06_追溯与审计/03_审计与一致性报告/_增量便利贴"
THRESHOLD=9

if [[ ! -d "$STICKY_DIR" ]]; then
  echo "[OK] _增量便利贴 目录不存在，无需检查"
  exit 0
fi

COUNT=$(find "$STICKY_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
echo "当前便利贴数量: $COUNT (熔断阈值: ≥10)"

if [[ "$COUNT" -gt "$THRESHOLD" ]]; then
  echo "[WARNING] 便利贴数量已超过 $THRESHOLD，请尽快执行熔断合并（见协议 §3.4）"
  exit 1
fi
echo "[OK] 便利贴数量未超阈值"
exit 0
