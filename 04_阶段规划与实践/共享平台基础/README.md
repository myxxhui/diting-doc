# L4 · 共享平台基础

> [!NOTE] **[TRACEBACK]**
> - **L3**：[03_/_共享规约/](../../03_原子目标与规约/_共享规约/)
> - **DNA**：[`_System_DNA/global_const.yaml#tech_stack`](../../03_原子目标与规约/_System_DNA/global_const.yaml) + `dna_dev_workflow.yaml#workflow_stages[stage_id=shared_platform_baseline]`
> - **L5**：`l5-shared-platform-baseline`

## 阶段索引

| # | stage_id | 阶段文档 |
|---|----------|----------|
| 1 | `shared_platform_baseline` | [01_本阶段实践与验证.md](./01_本阶段实践与验证.md) |

## 关键最佳实践目标

- 共享组件（PostgreSQL / OpenSearch / Kafka / Redis / K3s / 推理网关 / 配置中心）健康就绪
- 推荐技术栈：K3s（阿里云 ECS 起步，可平滑迁 ACK）+ vLLM（推理加速）+ HAMi（GPU 切分调度）+ LangGraph（议会编排）+ LLaMA-Factory（LoRA 微调流水线）
- 鉴权 / API Gateway / 静态资源 CDN 就绪

## AI 实践最佳推荐模型

| 用途 | 推荐模型 / 档次 | 一句理由 |
|------|----------------|---------|
| Helm / K8s 资源生成 | Claude Sonnet 4 系列（cursor 默认） | 长上下文 + YAML 一次成型 |
| 故障排查 | GPT-5 系列 | 现场推理与命令生成 |
| 推理网关压测脚本 | DeepSeek-V3 / 豆包 | 性价比高 |
| **维护责任**：架构师每季度复审 |
