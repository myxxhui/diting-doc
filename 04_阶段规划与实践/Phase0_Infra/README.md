# Phase0_Infra · 基础设施与仓库初始化

> [!NOTE] **[TRACEBACK] Phase 锚点**
> - **对应阶段**：阶段 -1/0a（仓库与 L3 就绪），对应 DNA stage_id **s0_pre**；部分内容与阶段 2（Docker/IaC 骨架）相关
> - **00_ 对应**：[Stage0_pre_仓库与L3就绪](../00_交付流程步骤/Stage0_pre_仓库与L3就绪/README.md)
> - **原子规约**: [01_开发生命周期与实践流程规约](../../03_原子目标与规约/开发与交付/01_开发生命周期与实践流程规约.md)、[02_三位一体仓库规约](../../03_原子目标与规约/02_三位一体仓库规约.md)

## 阶段目标

交付**三位一体仓库结构**（diting-core、diting-infra）及最小占位；可选 Docker/IaC 骨架。本 Phase 与 **Stage0_pre（仓库与 L3 就绪）** 对齐，执行顺序以 00_ 交付流程步骤为准。

## 依赖

- 无（或 L3 规约与 DNA 已定稿）

## 交付物

- 三仓目录符合 [02_三位一体仓库规约](../../03_原子目标与规约/02_三位一体仓库规约.md)；diting-core 含 Makefile 且 `make test` 可运行（可为占位）；diting-infra 含 charts/config/observability/secrets 及 config/environments/dev/deploy.json 占位；可选 Docker/IaC 骨架。

## 行动入口

**执行见**：[00_交付流程步骤/Stage0_pre_仓库与L3就绪/01_本阶段实践与验证](../00_交付流程步骤/Stage0_pre_仓库与L3就绪/01_本阶段实践与验证.md)。本 Phase 与 Stage0_pre 合并表述，以该 01_ 为唯一实践入口；准出时须同步更新 L5 [02_验收标准](../../05_成功标识与验证/02_验收标准.md) 中 s0_pre 对应行。

## 本 Phase 关联的 Stage

- **Stage0_pre_仓库与L3就绪**（stage_id: s0_pre）— 本 Phase 对应该 Stage，执行与验收以 00_/Stage0_pre 的 01_ 为准。
