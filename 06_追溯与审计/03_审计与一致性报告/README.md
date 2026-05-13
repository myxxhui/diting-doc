# 06 · 审计与一致性报告

> [!NOTE] **[TRACEBACK]**
> - **L3 DNA**：[`_System_DNA/dna_dev_workflow.yaml`](../../03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml)
> - **L4**：[04_阶段规划与实践](../../04_阶段规划与实践/README.md)
> - **L5**：[05_/02_验收标准.md](../../05_成功标识与验证/02_验收标准.md)
> - **2026-05-13 第 3 批重写**：与新 22 个 workflow_stages 对齐

## 一、目标

DNA、04_ 阶段目录（5 pillar + shared）、L5 验收标准、03_ 设计文档、06_ 映射五者变更时，可按下述清单或脚本快速发现漏改或断链。**执行时机**：人工定期执行或 CI 集成。

## 二、一致性检查清单

| # | 项 | 验证方式 |
|---|---|---------|
| 1 | DNA 中每个 `workflow_stages[].stage_id` 在 [04_阶段规划与实践](../../04_阶段规划与实践/) 下存在对应 stage 实践文档 | 打开 [dna_dev_workflow.yaml](../../03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml)，逐条 `l4_doc` 字段路径存在 |
| 2 | 每个 `stage_id` 在 [05_/02_验收标准.md](../../05_成功标识与验证/02_验收标准.md) 中有对应行 + 锚点 | 打开 02_验收标准.md，在「workflow_stages 验收表」中确认 22 行 |
| 3 | 每个 `stage_id` 在 [00_L2_L3_DNA_映射.md](../00_L2_L3_DNA_映射.md) 中有对应行 | 打开 00_L2_L3_DNA_映射.md，第三节表格 22 行 |
| 4 | 每个 stage 的 `dna_file` 与 `design_doc` 路径存在 | 运行 [check_dna_00_l5.sh](./check_dna_00_l5.sh) 或 Python 脚本 |
| 5 | L5 verification_commands 与 L4 实践文档「四、可执行验证清单」一致 | 运行 [check_l4_verification_commands_vs_dna.sh](./check_l4_verification_commands_vs_dna.sh) |
| 6 | 03_/<pillar>/0N_*_设计.md 5 份俱全 | `find 03_原子目标与规约/<pillar> -name '0?_*_设计.md' \| wc -l` 应 = 5 |
| 7 | 04_/<pillar>/ 阶段实践文档与 DNA milestone 数一致 | 见 [04_/README §二](../../04_阶段规划与实践/README.md) |
| 8 | 03_ 设计文档与对应 DNA、L4 实践 1:1:1 | 运行 [check_111_design_dna_practice.sh](./check_111_design_dna_practice.sh) |

## 三、22 stages 快速对照（与 [00_L2_L3_DNA_映射 §三](../00_L2_L3_DNA_映射.md#三l3-模块--步骤级-dna--l4-实践--l5-锚点) 一致）

| pillar | stages | L5 锚点前缀 |
|--------|--------|------------|
| shared_platform | 1 (mvp) | `l5-shared-platform-baseline` |
| cryo_guard | 3 (mvp/v1/v2) | `l5-pillar-cryo-` |
| deep_strike | 5 (mvp + 3 v1 + v2) | `l5-pillar-deep-` |
| state_watch | 5 (mvp + 3 v1 + v2) | `l5-pillar-watch-` |
| super_evo | 5 (mvp + 3 v1 + v2) | `l5-pillar-evo-` |
| frontend | 3 (mvp/v1/v2) | `l5-frontend-` |
| **合计** | **22** | — |

## 四、脚本（v2 待重写说明）

本目录下 `check_*.sh` 脚本部分基于旧 stage_id 命名（如 `stage1_01`），第 3 批重构后须按新命名（如 `cryo_guard_mvp`、`shared_platform_baseline`）重写或参数化。**当前可用的简化校验**：使用 Python 直接读取 [`dna_dev_workflow.yaml`](../../03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml) 校验 `design_doc` / `dna_file` / `l4_doc` 路径存在性（第 3 批已通过）。

| 脚本 | 状态 | 说明 |
|------|------|------|
| `check_dna_00_l5.sh` | 待重写 | 校验 DNA stage_id ↔ L5 锚点 |
| `check_l5_dna_consistency.sh` | 待重写 | 校验 L5 表与 DNA 强一致 |
| `check_l4_verification_commands_vs_dna.sh` | 待重写 | 校验 L4 命令与 DNA 一致 |
| `check_111_design_dna_practice.sh` | 待重写 | 校验 1:1:1 |
| `check_phase_steps_prompt.sh` | 待重写 | 校验 Phase 步骤模板 |
| `check_prompt_refs_ai_readable.sh` | 待重写 | 校验「本步逻辑引用」AI 可读 |
| `list_l4_for_dna_stage.sh` | 待重写 | 按 stage_id 列出 L4 |
| `00_实践记录模板.md` | 仍可用 | 通用模板 |

**临时校验命令**（在文档仓根目录）：

```bash
python3 -c "
import yaml; from pathlib import Path
wf = yaml.safe_load(open('03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml'))
ok = True
for s in wf['workflow_stages']:
    sid = s['stage_id']
    for fk in ['design_doc', 'dna_file', 'l4_doc']:
        v = s.get(fk);  v = v.split('#')[0] if v else None
        if v and not (Path('03_原子目标与规约/_System_DNA') / v).exists():
            print(f'MISSING {fk}: {sid} → {v}'); ok = False
print('OK' if ok else 'FAIL')
"
```

## 五、本次重构（2026-05-13 第 3 批）

旧 22 行 stage1_01~stage5_04 模式 → 新 22 行 5 pillar × milestone 模式。
