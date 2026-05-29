# 06 · L3/DNA 变更对 L4 影响表

> [!NOTE] **[TRACEBACK]**
> - **L3**：[03_原子目标与规约](../03_原子目标与规约/README.md)
> - **DNA**：[`_System_DNA/`](../03_原子目标与规约/_System_DNA/)
> - **L4**：[04_阶段规划与实践](../04_阶段规划与实践/README.md)
> - **L5**：[02_验收标准](../05_成功标识与验证/02_验收标准.md)
> - **本表 2026-05-13 第 3 批重写**：与新四大模块 + 前端 + 共享平台对齐

## 一、变更类型

| 变更类型 | 影响面 |
|---------|-------|
| **A. global_const.yaml 顶层 pillar 配置变更** | 影响所有 pillar；须更新 5 个 L4 模块 README + 22 个 L5 行 + 5 个 03_/<pillar>/ 设计文档 |
| **B. dna_dev_workflow.yaml workflow_stages 变更** | 影响对应 stage 的 L4 实践文档 + L5 行 + 06_/00_映射 + 03_/<pillar>/ 实施推演 |
| **C. core_modules/*.yaml 共享元数据变更** | 影响所有引用方（severity / formulas / subject 等）；须批量更新 |
| **D. 步骤级 DNA 字段变更** | 仅影响该 stage 的 L4 实践文档 + L5 行 |
| **E. 03_/<pillar>/0N_*_设计.md 结构变更** | 须同步更新 DNA `design_doc` 锚点 + L4 实践文档引用 |

## 二、按 stage 的影响矩阵（22 行）

| stage_id | 受影响 L4 文档 | 受影响 L5 行 | 受影响 03_ 设计 |
|----------|---------------|-------------|----------------|
| shared_platform_baseline | [04_/共享平台基础/01](../04_阶段规划与实践/共享平台基础/01_本阶段实践与验证.md) | `l5-shared-platform-baseline` | [03_/_共享规约/](../03_原子目标与规约/_共享规约/) |
| cryo_guard_mvp | [04_/极寒防御/01_MVP](../04_阶段规划与实践/01_维度一_极寒防御/01_MVP_本阶段实践与验证.md) | `l5-pillar-cryo-mvp` | [03_/极寒防御/05_实施推演_设计.md](../03_原子目标与规约/01_维度一_极寒防御/05_实施推演_设计.md) |
| cryo_guard_v1 | [04_/极寒防御/02_V1](../04_阶段规划与实践/01_维度一_极寒防御/02_V1_本阶段实践与验证.md) | `l5-pillar-cryo-v1` | 同上 |
| cryo_guard_v2 | [04_/极寒防御/03_V2](../04_阶段规划与实践/01_维度一_极寒防御/03_V2_本阶段实践与验证.md) | `l5-pillar-cryo-v2` | 同上 |
| deep_strike_mvp | [04_/纵深进攻/01_MVP](../04_阶段规划与实践/02_维度二_纵深进攻/01_MVP_本阶段实践与验证.md) | `l5-pillar-deep-mvp` | [03_/纵深进攻/05_实施推演_设计.md](../03_原子目标与规约/02_维度二_纵深进攻/05_实施推演_设计.md) |
| deep_strike_v1_council | [04_/纵深进攻/02_V1_council](../04_阶段规划与实践/02_维度二_纵深进攻/02_V1_council_本阶段实践与验证.md) | `l5-pillar-deep-v1-council` | 同上 |
| deep_strike_v1_feature | [04_/纵深进攻/03_V1_feature](../04_阶段规划与实践/02_维度二_纵深进攻/03_V1_feature_本阶段实践与验证.md) | `l5-pillar-deep-v1-feature` | 同上 |
| deep_strike_v1_eval | [04_/纵深进攻/04_V1_eval](../04_阶段规划与实践/02_维度二_纵深进攻/04_V1_eval_本阶段实践与验证.md) | `l5-pillar-deep-v1-eval` | 同上 |
| deep_strike_v2_runtime | [04_/纵深进攻/05_V2_runtime](../04_阶段规划与实践/02_维度二_纵深进攻/05_V2_runtime_本阶段实践与验证.md) | `l5-pillar-deep-v2-runtime` | 同上 |
| state_watch_mvp | [04_/状态机监控/01_MVP](../04_阶段规划与实践/03_维度三_持仓监控/01_MVP_本阶段实践与验证.md) | `l5-pillar-watch-mvp` | [03_/状态机监控/05_实施推演_设计.md](../03_原子目标与规约/03_维度三_持仓监控/05_实施推演_设计.md) |
| state_watch_v1_probe | [04_/状态机监控/02_V1_probe](../04_阶段规划与实践/03_维度三_持仓监控/02_V1_probe_本阶段实践与验证.md) | `l5-pillar-watch-v1-probe` | 同上 |
| state_watch_v1_gate | [04_/状态机监控/03_V1_gate](../04_阶段规划与实践/03_维度三_持仓监控/03_V1_gate_本阶段实践与验证.md) | `l5-pillar-watch-v1-gate` | 同上 |
| state_watch_v1_budget | [04_/状态机监控/04_V1_budget](../04_阶段规划与实践/03_维度三_持仓监控/04_V1_budget_本阶段实践与验证.md) | `l5-pillar-watch-v1-budget` | 同上 |
| state_watch_v2_template | [04_/状态机监控/05_V2_template](../04_阶段规划与实践/03_维度三_持仓监控/05_V2_template_本阶段实践与验证.md) | `l5-pillar-watch-v2-template` | 同上 |
| super_evo_mvp | [04_/超级个体进化/01_MVP](../04_阶段规划与实践/05_维度五_演进飞轮/01_MVP_本阶段实践与验证.md) | `l5-pillar-evo-mvp` | [03_/超级个体进化/05_实施推演_设计.md](../03_原子目标与规约/05_维度五_演进飞轮/05_实施推演_设计.md) |
| super_evo_v1_eval | [04_/超级个体进化/02_V1_eval](../04_阶段规划与实践/05_维度五_演进飞轮/02_V1_eval_本阶段实践与验证.md) | `l5-pillar-evo-v1-eval` | 同上 |
| super_evo_v1_retro | [04_/超级个体进化/03_V1_retro](../04_阶段规划与实践/05_维度五_演进飞轮/03_V1_retro_本阶段实践与验证.md) | `l5-pillar-evo-v1-retro` | 同上 |
| super_evo_v1_version | [04_/超级个体进化/04_V1_version](../04_阶段规划与实践/05_维度五_演进飞轮/04_V1_version_本阶段实践与验证.md) | `l5-pillar-evo-v1-version` | 同上 |
| super_evo_v2_online | [04_/超级个体进化/05_V2_online](../04_阶段规划与实践/05_维度五_演进飞轮/05_V2_online_本阶段实践与验证.md) | `l5-pillar-evo-v2-online` | 同上 |
| frontend_mvp | [04_/前端工程与服务/01_MVP](../04_阶段规划与实践/00_维度零_AI投资副驾驶/01_MVP_本阶段实践与验证.md) | `l5-frontend-mvp` | [03_/前端工程与服务/05_实施推演_设计.md](../03_原子目标与规约/00_维度零_AI投资副驾驶/05_实施推演_设计.md) |
| frontend_v1_full | [04_/前端工程与服务/02_V1_full](../04_阶段规划与实践/00_维度零_AI投资副驾驶/02_V1_full_本阶段实践与验证.md) | `l5-frontend-v1-full` | 同上 |
| frontend_v2_pwa | [04_/前端工程与服务/03_V2_pwa](../04_阶段规划与实践/00_维度零_AI投资副驾驶/03_V2_pwa_本阶段实践与验证.md) | `l5-frontend-v2-pwa` | 同上 |

## 三、变更操作 SOP

1. **识别变更类型**（A/B/C/D/E）
2. **修订源文件**（DNA 或 03_/<pillar>/0N_*_设计.md）
3. **同步下游**：按上表逐项更新；每个 04_/0N_*.md 的 `## 二、本步骤落实的 DNA 键` 同步
4. **更新 L5**：受影响 L5 行的「本阶段对应 L5 验收」列；锚点保持不变
5. **更新 06_/00_映射**：若 stage 集合变了，须同步该表
6. **关键重构（§4.5）**：若涉及目录结构 / 全局约定，须同步 `00_系统规则_通用项目协议.md` + `.cursorrules` 的「协议修订记录」
7. **运行一致性脚本**：`03_审计与一致性报告/check_*.sh` 全部通过

## 四、本次重构（2026-05-13 第 3 批）

旧 ABCD/Stage1~5 22 行映射全部删除，重写为 22 行新 stage 映射。
