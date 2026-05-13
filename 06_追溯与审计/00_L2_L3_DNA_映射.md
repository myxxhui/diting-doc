# 06 · L2 ↔ L3 ↔ DNA ↔ L4/L5 总映射

> [!NOTE] **[TRACEBACK]**
> - **L2**：[02_战略维度](../02_战略维度/00_双目标与战略维度关系.md)
> - **L3**：[03_原子目标与规约](../03_原子目标与规约/README.md)
> - **DNA**：[`_System_DNA/`](../03_原子目标与规约/_System_DNA/)
> - **L4**：[04_阶段规划与实践](../04_阶段规划与实践/README.md)
> - **L5**：[05_/02_验收标准](../05_成功标识与验证/02_验收标准.md)

## 一、版本说明（2026-05-13 第 3 批）

本表已**完全替换**旧 ABCD 模块映射，与新四大模块（极寒防御 / 纵深进攻 / 状态机监控 / 超级个体进化）+ 前端工程 + 共享平台基础对齐。

## 二、L2 战略维度 ↔ L3 模块 总映射

| L2 战略维度 | L3 模块（pillar） | L3 设计文档 | DNA 顶层 |
|------------|------------------|------------|---------|
| **防御战略**（Absolute Survival） | 极寒防御 | [03_/极寒防御/](../03_原子目标与规约/极寒防御/) | `global_const.yaml#cryo_guard_top` |
| **进攻战略**（Unstructured Alpha Strike） | 纵深进攻 | [03_/纵深进攻/](../03_原子目标与规约/纵深进攻/) | `global_const.yaml#deep_strike_top` |
| **持仓战略 + 演进战略观察面**（Dynamic Thesis Observability） | 状态机监控 | [03_/状态机监控/](../03_原子目标与规约/状态机监控/) | `global_const.yaml#state_watch_top` |
| **演进战略**（Cognitive Flywheel） | 超级个体进化 | [03_/超级个体进化/](../03_原子目标与规约/超级个体进化/) | `global_const.yaml#super_evo_top` |
| **个人财富战略 + 用户面**（Tech-Stack Pivot + UX） | 前端工程与服务 | [03_/前端工程与服务/](../03_原子目标与规约/前端工程与服务/) | `global_const.yaml#frontend_top` |
| **平台底座**（Foundation） | 共享平台基础 | [03_/_共享规约/](../03_原子目标与规约/_共享规约/) | `global_const.yaml#tech_stack` 等 |

## 三、L3 模块 ↔ 步骤级 DNA ↔ L4 实践 ↔ L5 锚点

| pillar | milestone | DNA file | L4 实践文档 | L5 锚点 |
|--------|-----------|----------|------------|---------|
| shared_platform | mvp | [shared/dna_shared_platform_baseline.yaml](../03_原子目标与规约/_System_DNA/shared/dna_shared_platform_baseline.yaml) | [共享平台基础/01](../04_阶段规划与实践/共享平台基础/01_本阶段实践与验证.md) | `l5-shared-platform-baseline` |
| cryo_guard | mvp | [cryo_guard/dna_cryo_guard_mvp.yaml](../03_原子目标与规约/_System_DNA/cryo_guard/dna_cryo_guard_mvp.yaml) | [极寒防御/01_MVP](../04_阶段规划与实践/极寒防御/01_MVP_本阶段实践与验证.md) | `l5-pillar-cryo-mvp` |
| cryo_guard | v1 | [cryo_guard/dna_cryo_guard_v1.yaml](../03_原子目标与规约/_System_DNA/cryo_guard/dna_cryo_guard_v1.yaml) | [极寒防御/02_V1](../04_阶段规划与实践/极寒防御/02_V1_本阶段实践与验证.md) | `l5-pillar-cryo-v1` |
| cryo_guard | v2 | [cryo_guard/dna_cryo_guard_v2.yaml](../03_原子目标与规约/_System_DNA/cryo_guard/dna_cryo_guard_v2.yaml) | [极寒防御/03_V2](../04_阶段规划与实践/极寒防御/03_V2_本阶段实践与验证.md) | `l5-pillar-cryo-v2` |
| deep_strike | mvp | [deep_strike/dna_deep_strike_mvp.yaml](../03_原子目标与规约/_System_DNA/deep_strike/dna_deep_strike_mvp.yaml) | [纵深进攻/01_MVP](../04_阶段规划与实践/纵深进攻/01_MVP_本阶段实践与验证.md) | `l5-pillar-deep-mvp` |
| deep_strike | v1 | [deep_strike/dna_deep_strike_v1_council.yaml](../03_原子目标与规约/_System_DNA/deep_strike/dna_deep_strike_v1_council.yaml) | [纵深进攻/02_V1_council](../04_阶段规划与实践/纵深进攻/02_V1_council_本阶段实践与验证.md) | `l5-pillar-deep-v1-council` |
| deep_strike | v1 | [deep_strike/dna_deep_strike_v1_feature.yaml](../03_原子目标与规约/_System_DNA/deep_strike/dna_deep_strike_v1_feature.yaml) | [纵深进攻/03_V1_feature](../04_阶段规划与实践/纵深进攻/03_V1_feature_本阶段实践与验证.md) | `l5-pillar-deep-v1-feature` |
| deep_strike | v1 | [deep_strike/dna_deep_strike_v1_eval.yaml](../03_原子目标与规约/_System_DNA/deep_strike/dna_deep_strike_v1_eval.yaml) | [纵深进攻/04_V1_eval](../04_阶段规划与实践/纵深进攻/04_V1_eval_本阶段实践与验证.md) | `l5-pillar-deep-v1-eval` |
| deep_strike | v2 | [deep_strike/dna_deep_strike_v2.yaml](../03_原子目标与规约/_System_DNA/deep_strike/dna_deep_strike_v2.yaml) | [纵深进攻/05_V2_runtime](../04_阶段规划与实践/纵深进攻/05_V2_runtime_本阶段实践与验证.md) | `l5-pillar-deep-v2-runtime` |
| state_watch | mvp | [state_watch/dna_state_watch_mvp.yaml](../03_原子目标与规约/_System_DNA/state_watch/dna_state_watch_mvp.yaml) | [状态机监控/01_MVP](../04_阶段规划与实践/状态机监控/01_MVP_本阶段实践与验证.md) | `l5-pillar-watch-mvp` |
| state_watch | v1 | [state_watch/dna_state_watch_v1_probe.yaml](../03_原子目标与规约/_System_DNA/state_watch/dna_state_watch_v1_probe.yaml) | [状态机监控/02_V1_probe](../04_阶段规划与实践/状态机监控/02_V1_probe_本阶段实践与验证.md) | `l5-pillar-watch-v1-probe` |
| state_watch | v1 | [state_watch/dna_state_watch_v1_gate.yaml](../03_原子目标与规约/_System_DNA/state_watch/dna_state_watch_v1_gate.yaml) | [状态机监控/03_V1_gate](../04_阶段规划与实践/状态机监控/03_V1_gate_本阶段实践与验证.md) | `l5-pillar-watch-v1-gate` |
| state_watch | v1 | [state_watch/dna_state_watch_v1_budget.yaml](../03_原子目标与规约/_System_DNA/state_watch/dna_state_watch_v1_budget.yaml) | [状态机监控/04_V1_budget](../04_阶段规划与实践/状态机监控/04_V1_budget_本阶段实践与验证.md) | `l5-pillar-watch-v1-budget` |
| state_watch | v2 | [state_watch/dna_state_watch_v2.yaml](../03_原子目标与规约/_System_DNA/state_watch/dna_state_watch_v2.yaml) | [状态机监控/05_V2_template](../04_阶段规划与实践/状态机监控/05_V2_template_本阶段实践与验证.md) | `l5-pillar-watch-v2-template` |
| super_evo | mvp | [super_evo/dna_super_evo_mvp.yaml](../03_原子目标与规约/_System_DNA/super_evo/dna_super_evo_mvp.yaml) | [超级个体进化/01_MVP](../04_阶段规划与实践/超级个体进化/01_MVP_本阶段实践与验证.md) | `l5-pillar-evo-mvp` |
| super_evo | v1 | [super_evo/dna_super_evo_v1_eval.yaml](../03_原子目标与规约/_System_DNA/super_evo/dna_super_evo_v1_eval.yaml) | [超级个体进化/02_V1_eval](../04_阶段规划与实践/超级个体进化/02_V1_eval_本阶段实践与验证.md) | `l5-pillar-evo-v1-eval` |
| super_evo | v1 | [super_evo/dna_super_evo_v1_retro.yaml](../03_原子目标与规约/_System_DNA/super_evo/dna_super_evo_v1_retro.yaml) | [超级个体进化/03_V1_retro](../04_阶段规划与实践/超级个体进化/03_V1_retro_本阶段实践与验证.md) | `l5-pillar-evo-v1-retro` |
| super_evo | v1 | [super_evo/dna_super_evo_v1_version.yaml](../03_原子目标与规约/_System_DNA/super_evo/dna_super_evo_v1_version.yaml) | [超级个体进化/04_V1_version](../04_阶段规划与实践/超级个体进化/04_V1_version_本阶段实践与验证.md) | `l5-pillar-evo-v1-version` |
| super_evo | v2 | [super_evo/dna_super_evo_v2.yaml](../03_原子目标与规约/_System_DNA/super_evo/dna_super_evo_v2.yaml) | [超级个体进化/05_V2_online](../04_阶段规划与实践/超级个体进化/05_V2_online_本阶段实践与验证.md) | `l5-pillar-evo-v2-online` |
| frontend | mvp | [frontend/dna_frontend_mvp.yaml](../03_原子目标与规约/_System_DNA/frontend/dna_frontend_mvp.yaml) | [前端工程与服务/01_MVP](../04_阶段规划与实践/前端工程与服务/01_MVP_本阶段实践与验证.md) | `l5-frontend-mvp` |
| frontend | v1 | [frontend/dna_frontend_v1_full.yaml](../03_原子目标与规约/_System_DNA/frontend/dna_frontend_v1_full.yaml) | [前端工程与服务/02_V1_full](../04_阶段规划与实践/前端工程与服务/02_V1_full_本阶段实践与验证.md) | `l5-frontend-v1-full` |
| frontend | v2 | [frontend/dna_frontend_v2.yaml](../03_原子目标与规约/_System_DNA/frontend/dna_frontend_v2.yaml) | [前端工程与服务/03_V2_pwa](../04_阶段规划与实践/前端工程与服务/03_V2_pwa_本阶段实践与验证.md) | `l5-frontend-v2-pwa` |

**计 22 行**，与 [`dna_dev_workflow.yaml#workflow_stages`](../03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml) 严格 1:1。

## 四、跨模块共享元数据（core_modules）

| 文件 | 用途 |
|------|------|
| [core_modules/dna_pillar_definitions.yaml](../03_原子目标与规约/_System_DNA/core_modules/dna_pillar_definitions.yaml) | 五大 pillar + shared_platform 元定义；为 `global_const.yaml#vision.pillars` 真相源 |
| [core_modules/dna_core_formulas.yaml](../03_原子目标与规约/_System_DNA/core_modules/dna_core_formulas.yaml) | 议会一致性、预期差、状态机迁移、四大退出模型、风控约束、推理成本 |
| [core_modules/dna_subject_taxonomy.yaml](../03_原子目标与规约/_System_DNA/core_modules/dna_subject_taxonomy.yaml) | 标的 / 行业 / segment / 证据类型枚举 |
| [core_modules/dna_severity_taxonomy.yaml](../03_原子目标与规约/_System_DNA/core_modules/dna_severity_taxonomy.yaml) | 全局严重度 / 通知通道矩阵 / 风险事件严重度映射 |

## 五、维护规则

- **DNA 增删 stage** → 同步本表 + L5 02_验收标准 + 04_/README 索引（按 §4.1）
- **L3 设计文档结构变更** → 同步本表「L3 设计文档」列与锚点
- **本表与 DNA 强一致**：可由脚本（`03_审计与一致性报告/check_dna_00_l5.sh`）做 stage_id 一致性校验
