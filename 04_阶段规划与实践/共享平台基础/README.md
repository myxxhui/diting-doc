# L4 · 共享平台基础

> [!NOTE] **[TRACEBACK]**
> - **L3**：[03_/_共享规约/](../../03_原子目标与规约/_共享规约/)
> - **DNA**：[`_System_DNA/global_const.yaml#tech_stack`](../../03_原子目标与规约/_System_DNA/global_const.yaml) + `dna_dev_workflow.yaml#workflow_stages[stage_id=shared_platform_baseline]`
> - **L5**：`l5-shared-platform-baseline`

## 阶段索引

| # | stage_id | 阶段文档 |
|---|----------|----------|
| 1 | `shared_platform_baseline` | [01_本阶段实践与验证.md](./01_本阶段实践与验证.md)（**总览 smoke** · 保留） |
| 1.P | `shared_platform_baseline · P 轨 7 step` | [stage_1_启动期/README.md](./stage_1_启动期/README.md)（**P 轨实践记录** · 2026-05-24 新增） |

## P 轨实践记录 1:1 索引（与 L3 共享平台基础/stages/stage_1_启动期/steps 严格 1:1:1 · **v2 重写**）

| # | P 轨 step | 类型 | L3 设计 | L4 实践记录 |
|---|-----------|------|--------|------------|
| 01 | 现状盘点与凭证复用 | 必经 · 30min | [step_01](../../03_原子目标与规约/共享平台基础/stages/stage_1_启动期/steps/step_01_现状盘点与凭证复用.md) | [实践记录_step_01](./stage_1_启动期/实践记录_step_01_现状盘点与凭证.md) |
| **02 (设计)** | deploy-engine 扩展规约 | **设计 · 在外仓实现** | [02_deploy-engine扩展规约](../../03_原子目标与规约/共享平台基础/stages/stage_1_启动期/02_deploy-engine扩展规约.md) | [实践记录_step_02](./stage_1_启动期/实践记录_step_02_deploy_engine扩展.md) |
| 03 | CPU Stack 按需 Up · platform-base + diting-stack | 必经 | [step_03](../../03_原子目标与规约/共享平台基础/stages/stage_1_启动期/steps/step_03_CPU_Stack_按需Up.md) | [实践记录_step_03](./stage_1_启动期/实践记录_step_03_CPU_Stack_按需Up.md) |
| 04 | GPU 训练组按需 Up · diting-training chart | **按需** | [step_04](../../03_原子目标与规约/共享平台基础/stages/stage_1_启动期/steps/step_04_GPU训练组按需Up.md) | [实践记录_step_04](./stage_1_启动期/实践记录_step_04_GPU训练组.md) |
| 05 | GPU 推理组按需 Up · diting-vllm chart | **按需** | [step_05](../../03_原子目标与规约/共享平台基础/stages/stage_1_启动期/steps/step_05_GPU推理组按需Up.md) | [实践记录_step_05](./stage_1_启动期/实践记录_step_05_GPU推理组.md) |
| 06 | Stack Down 与三档释放纪律 | **核心纪律** | [step_06](../../03_原子目标与规约/共享平台基础/stages/stage_1_启动期/steps/step_06_Stack_Down与三档释放纪律.md) | [实践记录_step_06](./stage_1_启动期/实践记录_step_06_三档释放纪律.md) |
| 07 | 阶段验收 · 平台快照 | 必经 | [step_07](../../03_原子目标与规约/共享平台基础/stages/stage_1_启动期/steps/step_07_阶段验收_平台快照.md) | [实践记录_step_07](./stage_1_启动期/实践记录_step_07_阶段验收.md) |

**v2 修订（2026-05-24）**：①命令统一用 chart 名 `make down-stack <chart-name>`；②**VPC/SG/路由/网关与数据同级永驻**（永驻 10 项）；③4 chart 架构（platform-base + stack + training + vllm）；④地域改香港 cn-hongkong（复用现状）；⑤0 节点常态 + 月成本 ¥140-310（节省 60%）。

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
