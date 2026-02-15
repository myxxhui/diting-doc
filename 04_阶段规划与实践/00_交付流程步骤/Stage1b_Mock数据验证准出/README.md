---
best_practice_goals: "README.md#关键最佳实践目标"
minimal_closure_verification: "01_本阶段实践与验证.md#验证与准出"
verification_result_ref: "L5 02_验收标准 workflow_stages 映射表 s1b 行"
phase_links: ["Phase1_核心链路/04_"]
---

# Stage1b · Mock 数据验证准出

本阶段执行与验证：[01_本阶段实践与验证](01_本阶段实践与验证.md)（含完整实践指令与验证与准出）。

> [!NOTE] **[TRACEBACK] 阶段锚点**
> - **原子规约**: [01_开发生命周期与实践流程规约](../../../03_原子目标与规约/开发与交付/01_开发生命周期与实践流程规约.md) 阶段 1b
> - **工作流详细规划**: [03_项目全功能开发测试实践工作流详细规划](../../../03_原子目标与规约/开发与交付/03_项目全功能开发测试实践工作流详细规划.md)
> - **DNA stage_id**: `s1b`（[dna_dev_workflow.yaml](../../../03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml)）
> - **L4 阶段目录**: `Stage1b_Mock数据验证准出`（与 workflow_stages 一一对应）

## 阶段目标

在 MockBroker/MockBrain 下跑通核心路径，无真实券商/LLM 调用；Table-Driven Tests 及约定集成测试通过后，再进入镜像构建与 Docker/K3s 阶段。

## 准入条件

- Stage1 逻辑填充期核心链路已实现、可被 Mock 驱动

## 准出条件

- 在 MockBroker/MockBrain 下跑通核心路径；Table-Driven Tests 及约定集成测试通过；无真实券商/LLM 调用（详细准出清单见 [01_本阶段实践与验证](01_本阶段实践与验证.md)#验证与准出）。

## 交付物

- 核心路径 Mock 验证通过；Mock 数据与场景文档化

## 关键最佳实践目标

- 使用 MockBroker、MockBrain（或等价 Mock）驱动核心业务路径，覆盖 01 规约与 Phase1 约定的关键路径。
- Table-Driven Tests 及约定集成测试全部通过；无真实券商 API、无真实 LLM 调用。
- 文档化 Mock 数据与场景，便于后续 Docker/K3s 阶段复现。

## AI 实践最佳（性价比）推荐模型

| 用途 | 推荐模型或档次 | 理由 |
|------|----------------|------|
| Mock 数据与场景设计 | Claude 3.5 Sonnet 或 GPT-4o（待项目选定：架构师 Phase0 前） | 生成可复现的 Mock 数据与结构化用例 |
| 集成测试驱动与调试 | DeepSeek-Coder 或 Cursor 默认模型（待项目选定） | 以通过测试为锚定，优先性价比 |
| 评审/Defense | 人工为主；辅助可用 Claude 3.5 | 准出前人工确认无券商/LLM 泄漏与路径覆盖 |

## 本阶段关联的 Phase 步骤

- [Phase1_核心链路](../../Phase1_核心链路/) 的 [04_A到E集成与Mock准备](../../Phase1_核心链路/04_A到E集成与Mock准备.md)：核心路径与 Mock 数据由 Phase1 约定，本阶段验证 Mock 下跑通。

## 目录内文档

- [01_本阶段实践与验证](01_本阶段实践与验证.md)：完整实践指令、验证与准出、验证结果与 L5 同步说明
