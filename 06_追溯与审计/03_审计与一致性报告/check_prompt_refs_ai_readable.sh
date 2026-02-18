#!/usr/bin/env bash
# 04_ 步骤文档「本步逻辑引用（AI 可读）」块校验（对应人工清单第 17、18 项）
# 若步骤文档含「本步逻辑引用（AI 可读）」块，则解析其中的 dna_file、design_doc 路径并校验存在性。
# 从文档仓根目录运行，或传入文档仓根路径为第一参数。
# 输出：逐文件 PASS/FAIL/SKIP；全部通过时退出码 0。

set -e
DOC_ROOT="${1:-}"
if [[ -z "$DOC_ROOT" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  DOC_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi
BASE_04="$DOC_ROOT/04_阶段规划与实践"

STAGE_STEPS=(
  "Stage1_仓库与骨架/01_三位一体仓库初始化.md"
  "Stage1_仓库与骨架/02_核心接口与Proto占位.md"
  "Stage1_仓库与骨架/03_基础设施ECS与K3s就绪.md"
  "Stage1_仓库与骨架/04_密钥与配置模板就绪.md"
  "Stage2_数据采集与存储/01_基础设施与依赖部署.md"
  "Stage2_数据采集与存储/02_采集逻辑与Dockerfile.md"
  "Stage3_模块实践/01_ModuleA.md"
  "Stage4_MoE与执行网关/01_ModuleC_MoE议会接入.md"
  "Stage5_优化与扩展/01_可观测性与日志指标.md"
)

check_one() {
  local f="$1"
  local name="$2"
  local content
  [[ ! -f "$f" ]] && { echo "SKIP: $name 文件不存在"; return 0; }
  content="$(cat "$f")"

  # 若无「本步逻辑引用（AI 可读）」块，跳过
  if ! echo "$content" | grep -q '本步逻辑引用（AI 可读）\|本步逻辑引用(AI 可读)'; then
    echo "SKIP: [AI可读引用] $name 无「本步逻辑引用（AI 可读）」块"
    return 0
  fi

  local fail=0
  # 从「本步逻辑引用」到下一个 ## 之间的内容中提取路径
  local section
  section="$(echo "$content" | sed -n '/本步逻辑引用（AI 可读）\|本步逻辑引用(AI 可读)/,/^## /p' | sed '1d;$d')"
  # 提取 03_原子目标与规约/ 开头的 .yaml 或 .md 路径（去掉 # 及后续锚点），逐条校验
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    path="${p%%#*}"
    if [[ -n "$path" && ! -f "$DOC_ROOT/$path" ]]; then
      echo "FAIL: [AI可读引用] $name 引用路径不存在: $path"
      fail=1
    fi
  done < <(echo "$section" | grep -oE '03_原子目标与规约/[^ )\]"'"'"'#]+\.(yaml|md)' || true)

  if [[ $fail -eq 0 ]]; then
    echo "PASS: [AI可读引用] $name 本步逻辑引用块内路径可解析"
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
  echo "--- 本步逻辑引用（AI 可读）路径校验全部通过或已跳过"
  exit 0
else
  echo "--- 存在失败项"
  exit 1
fi
