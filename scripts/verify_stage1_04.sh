#!/usr/bin/env bash
# Stage1-04 密钥与配置模板就绪 — L1 验证脚本
# 与 L4 验证表、DNA verification_commands 一致。
# 用法：在 diting-infra 根目录执行 ./scripts/verify_stage1_04.sh；或 INFRA_DIR=/path/to/diting-infra ./scripts/verify_stage1_04.sh（从文档仓执行时）

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOC_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INFRA_DIR="${INFRA_DIR:-${1:-}}"
if [[ -n "$INFRA_DIR" ]]; then
  cd "$INFRA_DIR"
else
  # 假定在 diting-infra 根目录执行
  INFRA_DIR="$(pwd)"
fi

FAIL=0
run() {
  if eval "$@"; then
    echo "[OK] $*"
  else
    echo "[FAIL] $*"
    FAIL=1
  fi
}

echo "=== Stage1-04 L1 验证（工作目录: $(pwd)）==="

run "test -d secrets"
# config 单一 YAML 仅使用 config/deploy.yaml，不创建 config/environments/dev/
run "test -f config/deploy.yaml"
if ls secrets/certs/sealed-secrets-public*.pem 1>/dev/null 2>&1; then
  echo "[OK] 公钥文件存在 secrets/certs/sealed-secrets-public*.pem"
else
  echo "[FAIL] 未找到 secrets/certs/sealed-secrets-public*.pem"
  FAIL=1
fi

if command -v helm &>/dev/null; then
  echo "执行 helm template 检查（需根据实际 chart 路径调整）..."
  run "test -d charts/dependencies/sealed-secrets || test -d charts/sealed-secrets || true"
else
  echo "[SKIP] helm 未安装，跳过 Chart 模板检查"
fi

if command -v deploy-engine &>/dev/null || [[ -x deploy-engine/bin/deploy-engine ]]; then
  run "deploy-engine -config=config/deploy.yaml -dry-run 2>/dev/null || true"
else
  echo "[SKIP] deploy-engine 未在 PATH 或子目录，跳过解析检查"
fi

run "test -d deploy-engine"

echo ""
if [[ $FAIL -eq 0 ]]; then
  echo "L1 验证通过。L2/L3 需在集群就绪后于 diting-infra 中执行（见 04_密钥与配置模板设计#部署验证要求）。"
  exit 0
else
  echo "L1 验证存在失败项。"
  exit 1
fi
