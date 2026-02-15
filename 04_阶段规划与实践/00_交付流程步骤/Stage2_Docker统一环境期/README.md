---
best_practice_goals: "README.md#关键最佳实践目标"
minimal_closure_verification: "01_本阶段实践与验证.md#验证与准出"
verification_result_ref: "L5 02_验收标准 workflow_stages 映射表 s2 行"
phase_links: ["Phase1_核心链路", "Phase2_MoE与执行网关/01_02_"]
---

# Stage2 · Docker 统一环境期

本阶段执行与验证：[01_本阶段实践与验证](01_本阶段实践与验证.md)（含完整实践指令与验证与准出）。

> [!NOTE] **[TRACEBACK] 阶段锚点**
> - **原子规约**: [01_开发生命周期与实践流程规约](../../../03_原子目标与规约/开发与交付/01_开发生命周期与实践流程规约.md) 阶段 2
> - **工作流详细规划**: [03_项目全功能开发测试实践工作流详细规划](../../../03_原子目标与规约/开发与交付/03_项目全功能开发测试实践工作流详细规划.md)
> - **DNA stage_id**: `s2`（[dna_dev_workflow.yaml](../../../03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml)）
> - **L4 阶段目录**: `Stage2_Docker统一环境期`（与 workflow_stages 一一对应）

## 阶段目标

用 Docker 统一基础环境与服务依赖，在容器内跑开发与测试，与「本机裸跑」脱钩；`make build`、`make test-docker` 通过。

## 准入条件

- Stage1 或 Stage1b 已准出；或当「多人/CI 需要统一环境」时提前引入

## 准出条件

- 所有开发与测试可在容器内完成；`make build`、`make test-docker` 通过（详细准出清单见 [01_本阶段实践与验证](01_本阶段实践与验证.md)#验证与准出）。

## 交付物

- 镜像、容器内可测环境；构建与运行命令文档化

## 关键最佳实践目标

- Dockerfile（及可选 docker-compose）覆盖开发与测试所需运行时与依赖；在容器内执行全部单测与集成测试，与本地结果一致。
- 文档化构建与运行命令，使新成员或 CI 可一键复现环境；`make build`、`make test-docker` 通过。

## AI 实践最佳（性价比）推荐模型

| 用途 | 推荐模型或档次 | 理由 |
|------|----------------|------|
| Dockerfile / compose 编写与排错 | DeepSeek-Coder 或 Cursor 默认模型（待项目选定：架构师 Phase0 前） | 环境与命令为主，优先性价比 |
| 文档化构建与运行命令 | 同上或 Claude 3.5 模板生成（待项目选定） | 一键复现说明 |
| 评审/Defense | 人工为主；辅助可用 Claude 3.5 | 准出前人工确认容器内全绿与本地结果一致 |

## 本阶段关联的 Phase 步骤

- [Phase1_核心链路](../../Phase1_核心链路/) 后期、[Phase2_MoE与执行网关](../../Phase2_MoE与执行网关/) 的 [01_ModuleC_MoE议会接入](../../Phase2_MoE与执行网关/01_ModuleC_MoE议会接入.md)、[02_ModuleF执行网关接入](../../Phase2_MoE与执行网关/02_ModuleF执行网关接入.md) 可在此阶段接入（见 DNA module_to_stages）。

## 目录内文档

- [01_本阶段实践与验证](01_本阶段实践与验证.md)：完整实践指令、验证与准出、验证结果与 L5 同步说明
