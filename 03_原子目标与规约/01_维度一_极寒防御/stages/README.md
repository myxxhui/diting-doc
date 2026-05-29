# 维度一·极寒防御 · 3 阶段实践目录

> [!NOTE] **[TRACEBACK]**
> - **L2 维度**: [维度一·极寒防御 stages](../../../02_战略维度/01_维度一_极寒防御/stages/README.md)
> - **L3 模块**: [维度一_极寒防御/README](../README.md) + [06_L2 落地清单](../06_L2落地清单_设计.md)
> - **L4 实践**: [04_阶段规划与实践/01_维度一_极寒防御/](../../../04_阶段规划与实践/01_维度一_极寒防御/)（重命名同步中）

## 一、3 阶段总览

| 阶段 | 名称 | 时段 | 核心定位 | 步骤数 |
|---|---|---|---|---|
| 1 | [启动期](./stage_1_启动期/README.md) | 0-3 月 | 3 P0 引擎上线 + decision_gate + 50 案例 Holdout | 5 步 |
| 2 | [扩展期](./stage_2_扩展期/README.md) | 3-9 月 | + 4 P1 引擎 + DPO + 多 LoRA + reject_quota_manager | 待 Phase 2 |
| 3 | [完善期](./stage_3_完善期/README.md) | 9-12 月 | + 3 P2 引擎 + 议会模式（与维度五 Judge LLM） | 待 Phase 2 |

## 二、维度一的实践锚定

- 承接 L1 基石⑤防御（一票否决）+ ④八象限（F vs B 归因）
- **整套体系的全局闸门**：任何对外输出必须先经 decision_gate
- 启动期重点：3 P0 引擎 + reject 配额上线 + Holdout 50 案例评测

## 三、阶段切换准入

| 进阶 | 准入硬条件 |
|---|---|
| stage_1 → stage_2 | 3 P0 引擎 Recall ≥ 0.90 / Precision ≥ 0.70（50 案例 Holdout）+ decision_gate 0 漏判 |
| stage_2 → stage_3 | 7 引擎全部上线 + DPO 一次迭代成功 + Kappa ≥ 0.85 |
