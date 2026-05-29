# L4 · 共享平台基础 · 启动期 · 实践记录（v2）

> **本目录定位**：与 L3 [`共享平台基础/stages/stage_1_启动期/steps/`](../../../03_原子目标与规约/共享平台基础/stages/stage_1_启动期/steps/README.md) **严格 1:1:1** 的实践记录（含 DNA `dna_shared_platform_baseline.yaml#steps`）。每份记录回填**实际执行**的命令、输出、Spot ID、抢价、成本、DECISION_PENDING / SKIP_REASON。
>
> **v2 重大修正（2026-05-24）**：①命令统一用 chart 名 `make down-stack <chart-name>`②VPC/SG/路由/网关与数据同级永驻③4 chart × 3 stack 矩阵④三档释放纪律。

> [!NOTE] **[TRACEBACK]**
> - **L3 入口**：[`03_/共享平台基础/README`](../../../03_原子目标与规约/共享平台基础/README.md)
> - **DNA v2.0**：[`_System_DNA/shared/dna_shared_platform_baseline.yaml`](../../../03_原子目标与规约/_System_DNA/shared/dna_shared_platform_baseline.yaml)
> - **总览 smoke**：[`../01_本阶段实践与验证`](../01_本阶段实践与验证.md)
> - **L5 准出**：[`05_/02_验收标准.md#l5-shared-platform-baseline`](../../../05_成功标识与验证/02_验收标准.md)
> - **全局节奏**：[`_共享规约/14_六维度启动期统一节奏表.md#§6.4`](../../../03_原子目标与规约/_共享规约/14_六维度启动期统一节奏表.md)

## 实践记录索引（v2 · 1:1:1）

| # | step | 类型 | 状态 | 实践记录 | 关键证据字段 |
|---|------|------|------|---------|-------------|
| 01 | 现状盘点与凭证复用 | 必经 · 30min | ⏳ | [实践记录_step_01_现状盘点与凭证](./实践记录_step_01_现状盘点与凭证.md) | 现状 10 项 ID 核对 · deploy-engine submodule SHA · ACR login |
| **02 (设计)** | deploy-engine 扩展规约 | **设计 · 在外仓改** | ⏳ | [实践记录_step_02_deploy_engine扩展](./实践记录_step_02_deploy_engine扩展.md) | 主仓 commit SHA · make help 新 target · terraform plan 校验 |
| 03 | CPU Stack 按需 Up · platform-base + diting-stack | 必经 | ⏳ | [实践记录_step_03_CPU_Stack_按需Up](./实践记录_step_03_CPU_Stack_按需Up.md) | base ECS ID · helm releases · 三轮数据继承 · D1 ingest |
| 04 | GPU 训练组按需 Up · diting-training chart | **按需** | ⏳ | [实践记录_step_04_GPU训练组](./实践记录_step_04_GPU训练组.md) | train ECS Spot ID · Job Complete · NAS LoRA 路径 · 成本 |
| 05 | GPU 推理组按需 Up · diting-vllm chart | **按需** | ⏳ | [实践记录_step_05_GPU推理组](./实践记录_step_05_GPU推理组.md) | infer ECS Spot ID · `/v1/models` · Holdout metrics · 成本 |
| 06 | Stack Down 与三档释放纪律 | **核心纪律** | ⏳ | [实践记录_step_06_三档释放纪律](./实践记录_step_06_三档释放纪律.md) | tier-1/2/3 演练 · 永驻 10 项验证 · 二次确认机制 |
| 07 | 阶段验收 · 平台快照 | 必经 | ⏳ | [实践记录_step_07_阶段验收](./实践记录_step_07_阶段验收.md) | 平台快照 MD · L5 8 锚点 · 月度对账 |

> **回填要求**（与 [00_系统规则 §8.4g](../../../00_系统规则_通用项目协议.md) 一致）：每次准出 / 复验**覆盖**正文，**禁止**文末堆叠多轮全文；审计追溯写入 06_/审计；共用环境证据一处写深、他处链接。

## v2 修订速查

| 项 | v1 | v2 |
|----|----|----|
| 地域 | 新加坡 ap-southeast-1 | **香港 cn-hongkong** |
| 常态 | CPU 24/7 | **0 节点 · 随用随起** |
| 架构 | 单 diting-stack | **4 chart**（platform-base + stack + training + vllm）|
| 命令 | `make platform-stepXX-up/down` | **`make up-stack <chart>` / `make down-stack <chart>`** |
| 永驻 | 数据类（NAS/盘/OSS）| **数据 + 网络**（+ VPC/SG/路由/网关）10 项 |
| 月成本 | ¥400-600 | **¥140-310**（节省 60%）|
