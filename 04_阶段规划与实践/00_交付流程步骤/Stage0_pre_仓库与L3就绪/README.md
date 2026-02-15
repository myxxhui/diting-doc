---
# 阶段目录结构化块（§8.4b）：供脚本/AI 解析
best_practice_goals: "README.md#关键最佳实践目标"
minimal_closure_verification: "01_本阶段实践与验证.md#验证与准出"
verification_result_ref: "L5 02_验收标准 workflow_stages 映射表 s0_pre 行"
phase_links: ["Phase0_Infra"]
---

# Stage0_pre · 仓库与 L3 就绪

本阶段执行与验证：[01_本阶段实践与验证](01_本阶段实践与验证.md)（含完整实践指令与验证与准出）。

> [!NOTE] **[TRACEBACK] 阶段锚点**
> - **原子规约**: [01_开发生命周期与实践流程规约](../../../03_原子目标与规约/开发与交付/01_开发生命周期与实践流程规约.md) 第一步（仓库与 L3 就绪）
> - **工作流详细规划**: [03_项目全功能开发测试实践工作流详细规划](../../../03_原子目标与规约/开发与交付/03_项目全功能开发测试实践工作流详细规划.md)
> - **DNA stage_id**: `s0_pre`（[dna_dev_workflow.yaml](../../../03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml)）
> - **L4 阶段目录**: `Stage0_pre_仓库与L3就绪`（与 workflow_stages 一一对应）

## 阶段目标

创建并初始化三位一体仓库（diting-core、diting-infra），使目录与最小占位符合 02_三位一体仓库规约；diting-core 具备 Makefile 且 `make test` 可运行（可为占位）。本阶段准出后满足 [Stage0_骨架期](../Stage0_骨架期/README.md) 的准入条件。

## 准入条件

- L3 规约与 DNA 已定稿（见 [02_三位一体仓库规约](../../../03_原子目标与规约/02_三位一体仓库规约.md)、[dna_dev_workflow.yaml](../../../03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml)）

## 准出条件

- 三仓存在且目录与 global_const.trinity_repos 一致；diting-core 可执行 make test（占位通过）（详细准出清单见 [01_本阶段实践与验证](01_本阶段实践与验证.md)#验证与准出）。

## 交付物

- diting-core、diting-infra 目录结构及最小 Makefile/占位；diting-infra 的 charts/config/observability/secrets 及 config/environments/dev/deploy.json 占位；README 说明 deploy-engine 版本与调用方式（可选）。

## 关键最佳实践目标

- 按 [02_三位一体仓库规约](../../../03_原子目标与规约/02_三位一体仓库规约.md) 与 [global_const.yaml](../../../03_原子目标与规约/_System_DNA/global_const.yaml) 的 trinity_repos 创建 diting-core、diting-infra 目录与占位文件。
- diting-core 须含 Makefile，提供 `test` target（可为占位实现，退出码 0 即可）。
- diting-infra 须含 charts/、config/、observability/、secrets/ 及 config/environments/dev/deploy.json（可为占位），便于 Stage3 准入。

## AI 实践最佳（性价比）推荐模型

见 [00_ 交付流程步骤 README 项目级 AI 实践推荐模型](../README.md#项目级-ai-实践推荐模型)。本阶段补充：仓库与目录结构设计、脚本/Makefile 占位生成、评审/Defense 均按项目级表；本阶段以占位与目录创建为主，优先性价比。

## 本阶段关联的 Phase 步骤

- [Phase0_Infra](../../Phase0_Infra/)（本阶段与 Phase0_Infra 对齐；执行以本目录 01_ 为准）

## 目录内文档

- [01_本阶段实践与验证](01_本阶段实践与验证.md)：完整实践指令、验证与准出、验证结果与 L5 同步说明
