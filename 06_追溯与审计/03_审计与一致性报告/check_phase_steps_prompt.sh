#!/usr/bin/env bash
# 所有 04_ 实践文档：核心指令块与可复制命令块校验（对应人工清单第 9、10 项）
# 覆盖：Stage 01_、Phase0 01_、Phase 步骤 01_～04_
# 从文档仓根目录运行，或传入文档仓根路径为第一参数。
# 输出：逐文件 PASS/FAIL；全部通过时退出码 0。

set -e
DOC_ROOT="${1:-}"
if [[ -z "$DOC_ROOT" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  DOC_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi
BASE_04="$DOC_ROOT/04_阶段规划与实践"

# Stage1～5 步骤文档（每 Stage 取第一个步骤为代表检查；或可扩展为全步骤）
STAGE_STEPS=(
  "Stage1_仓库与骨架/01_三位一体仓库初始化.md"
  "Stage1_仓库与骨架/02_核心接口与Proto占位.md"
  "Stage1_仓库与骨架/03_密钥与配置模板就绪.md"
  "Stage2_数据采集与存储/01_基础设施与依赖实践.md"
  "Stage2_数据采集与存储/02_采集逻辑与Dockerfile实践.md"
  "Stage3_模块实践/01_语义分类器_实践.md"
  "Stage4_MoE与执行网关/01_ModuleC_MoE议会接入.md"
  "Stage5_优化与扩展/01_可观测性与日志指标.md"
)

check_one() {
  local f="$1"
  local name="$2"
  local content
  [[ ! -f "$f" ]] && { echo "FAIL: [核心指令] $name 文件不存在"; echo "FAIL: [可复制命令] $name 文件不存在"; return 1; }
  content="$(cat "$f")"

  local fail=0
  # 第 9 项：含「核心指令」或「The Prompt」或引用 00_5D / 详见 Stage0_pre 等
  if echo "$content" | grep -qE '##\s*核心指令|The Prompt|00_5D|见.*00_5D|详见.*核心指令|核心指令.*详见'; then
    echo "PASS: [核心指令] $name"
  else
    echo "FAIL: [核心指令] $name 缺少「核心指令」/「The Prompt」或引用"
    fail=1
  fi

  # 第 10 项：含可复制命令块或可执行验证清单中的可执行项
  if echo "$content" | grep -qE '```(bash|sh)' || echo "$content" | grep -qE 'make test|make -C|go test|npm test|pytest|test -d|deploy-engine'; then
    echo "PASS: [可复制命令] $name"
  else
    echo "FAIL: [可复制命令] $name 缺少可复制命令块或可执行项"
    fail=1
  fi
  return $fail
}

FAIL=0
for rel in "${STAGE_STEPS[@]}"; do
  f="$BASE_04/$rel"
  name="${rel//\//_}"
  check_one "$f" "$name" || FAIL=1
done

if [[ $FAIL -eq 0 ]]; then
  echo "--- 所有 04_ 实践文档核心指令/可复制命令检查全部通过"
  exit 0
else
  echo "--- 存在失败项"
  exit 1
fi
