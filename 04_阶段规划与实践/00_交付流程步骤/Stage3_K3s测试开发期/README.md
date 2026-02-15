---
best_practice_goals: "README.md#关键最佳实践目标"
minimal_closure_verification: "01_本阶段实践与验证.md#验证与准出"
verification_result_ref: "L5 02_验收标准 workflow_stages 映射表 s3 行"
phase_links: ["Phase2_MoE与执行网关", "Phase3_优化与扩展/01_02_"]
---

# Stage3 · K3s 测试开发期

本阶段执行与验证：[01_本阶段实践与验证](01_本阶段实践与验证.md)（含完整实践指令与验证与准出）。

> [!NOTE] **[TRACEBACK] 阶段锚点**
> - **原子规约**: [01_开发生命周期与实践流程规约](../../../03_原子目标与规约/开发与交付/01_开发生命周期与实践流程规约.md)、[02_基础设施与部署规约](../../../03_原子目标与规约/开发与交付/02_基础设施与部署规约.md)
> - **工作流详细规划**: [03_项目全功能开发测试实践工作流详细规划](../../../03_原子目标与规约/开发与交付/03_项目全功能开发测试实践工作流详细规划.md)
> - **DNA stage_id**: `s3`（[dna_dev_workflow.yaml](../../../03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml)）
> - **L4 阶段目录**: `Stage3_K3s测试开发期`（与 workflow_stages 一一对应）

## 阶段目标

在 K3s 上跑测试/开发用部署（非生产），验证编排、Secret、网络策略等；在 diting-infra 下调用 deploy-engine 完成 Up，Helm release 存在。**本阶段针对环境仅 dev（k3s_dev）**；staging/prod 准入与部署见 [02_基础设施与部署规约](../../../03_原子目标与规约/开发与交付/02_基础设施与部署规约.md) 与 Level 2/3。

## 准入条件

- Stage2 Docker 统一环境期已准出；执行前须确认 **deploy-engine 版本与 diting-infra 配置兼容**（见 [02_基础设施与部署规约](../../../03_原子目标与规约/开发与交付/02_基础设施与部署规约.md) 或 diting-infra README）

## 准出条件

- deploy-engine Up 成功；KubeConfig 可用 / Helm release 存在；在 K3s 上可部署并跑通测试/开发用 workload（详细准出清单见 [01_本阶段实践与验证](01_本阶段实践与验证.md)#验证与准出）。

## 交付物

- K3s 上测试/开发部署；编排与配置与生产一致

## 关键最佳实践目标

- 在 diting-infra 下调用 deploy-engine 完成 dev 环境 Up；配置符合 deploy-engine 的 DeploymentConfig（见 02_基础设施与部署规约）。
- 在 K3s 测试/开发命名空间中部署 workload，编排、Secret（Sealed-Secrets）、网络策略与生产一致；不部署生产数据或生产密钥。
- 执行前确认 deploy-engine 版本与 diting-infra 配置兼容。

## AI 实践最佳（性价比）推荐模型

| 用途 | 推荐模型或档次 | 理由 |
|------|----------------|------|
| 编排与 DeploymentConfig 编写 | Claude 3.5 Sonnet 或 GPT-4o（待项目选定：架构师 Phase0 前） | 与 02_基础设施与部署规约 对齐，YAML/配置结构化输出 |
| 排错与 E2E 验证 | DeepSeek-Coder 或 Cursor 默认模型（待项目选定） | Up 成功与 workload 跑通为主，优先性价比 |
| 评审/Defense | 人工为主；辅助可用 Claude 3.5 | 准出前人工确认 Sealed-Secrets、网络策略与生产一致（非生产命名空间） |

## 本阶段关联的 Phase 步骤

- [Phase2_MoE与执行网关](../../Phase2_MoE与执行网关/)（含 [03_回测或仿真验证](../../Phase2_MoE与执行网关/03_回测或仿真验证.md)）、[Phase3_优化与扩展](../../Phase3_优化与扩展/) 的 [01_可观测性与日志指标](../../Phase3_优化与扩展/01_可观测性与日志指标.md)、[02_成本治理与Token熔断](../../Phase3_优化与扩展/02_成本治理与Token熔断.md)；K3s 验证与 [02_基础设施与部署规约](../../../03_原子目标与规约/开发与交付/02_基础设施与部署规约.md) 对齐。

## 目录内文档

- [01_本阶段实践与验证](01_本阶段实践与验证.md)：完整实践指令、验证与准出、验证结果与 L5 同步说明
