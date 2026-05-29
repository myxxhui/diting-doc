# 维度四·卖出决策 · 3 阶段实践目录

> [!NOTE] **[TRACEBACK]**
> - **L2 维度**: [维度四·卖出决策](../../../02_战略维度/04_维度四_卖出决策/README.md)
> - **L3 模块**: [维度四_卖出决策/README](../README.md) + [06_L2 落地清单](../06_L2落地清单_设计.md)
> - **L4 实践**: [04_阶段规划与实践/04_维度四_卖出决策/](../../../04_阶段规划与实践/04_维度四_卖出决策/)（待创建，Phase 1 步 8 同步）

## 一、3 阶段总览

| 阶段 | 名称 | 时段 | 核心定位 | 步骤数 |
|---|---|---|---|---|
| 1 | [启动期](./stage_1_启动期/README.md) | 0-3 月 | 4 类卖出协议 schema + take_profit + logic_break_exit + 不正确卖出拦截器 | 4 步 |
| 2 | [扩展期](./stage_2_扩展期/README.md) | 3-9 月 | + opportunity_cost_reset + battlefield_failure_exit + 卖飞豁免 180 天 | 待 Phase 2 |
| 3 | [完善期](./stage_3_完善期/README.md) | 9-12 月 | + 缓冲期撤销机制 + 议会模式协作（与维度五）| 待 Phase 2 |

## 二、维度四的实践锚定

- 承接 L1 基石⑧卖出决策 + ③时间边界 + ⑦收益仓库
- **永远不直接下单**：仅产生 SellSignalEvent，前端人工确认
- 启动期重点：4 类协议骨架 + take_profit + logic_break_exit 跑通

## 三、阶段切换准入

| 进阶 | 准入硬条件 |
|---|---|
| stage_1 → stage_2 | take_profit / logic_break_exit 触发 0 漏；不正确卖出拦截器 100% 工作 |
| stage_2 → stage_3 | 4 类协议全部上线；卖飞豁免 180 天 + 缓冲期撤销稳定 |
