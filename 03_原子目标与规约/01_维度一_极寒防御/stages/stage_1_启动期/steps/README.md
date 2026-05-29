# 维度一·极寒防御·启动期·可执行步骤索引

> [!NOTE] **本目录定位**
> 给 Cursor / 开发者的"工作令"，每个 step 文件 = 一个可独立执行的开发任务。
> - 设计依据：见同级 [01_~05_](../) 5 份设计文档
> - DNA 真相源：[../../../../_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml](../../../../_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml)
> - 完成回写路径：[04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/](../../../../../04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/)

> **[上架与环境]** 目标运行时 **阿里云 ECS + K3s**；**Helm Chart**；镜像 **阿里云 ACR**；**`diting-infra` → `deploy-engine`**。必读：[16 · 部署链路](../../../../_共享规约/16_阿里云ECS_K3s_ACR_Helm部署与deploy-engine链路.md) · [L3 steps §1 必读块](../../../../_共享规约/L3步骤文档_部署价值哲学_必选引用.md)

<a id="l3-step-l4-mapping-authority"></a>

### L3 ↔ L4 映射（权威）

- **唯一执行序**：**`#` 列 1→10**，即 **`step_01` … `step_10`**（见下表）。
- **L4 实践记录文件名**：`实践记录_step_NN_*.md`，与本目录 **`step_NN_*.md`** 按下文 **「三、L4 实践记录预期清单」** **1:1**。
- **六维度日历节奏**：若需与产品计划对齐，见共享规约 [14_六维度启动期统一节奏表](../../../../_共享规约/14_六维度启动期统一节奏表.md)（含 **§九**）— **本目录正文不承载日历周次**，避免与 step 序号混读。

## 〇、三线并行门禁（每张 `step_*.md` 必须满足）

| 线 | 要求 |
|---|---|
| **用户价值** | §1 链接 [15](../../../../_共享规约/15_前后端职责与产品价值优先级.md) + 写明本步如何通过 **维度零触点**或可验收 mock 体现防御价值 |
| **部署进度** | 涉镜像/Chart/K8s：`### [Deploy]` + **`diting-infra`**；**勿改** `diting-infra/deploy-engine` 子模块工作树 |
| **哲学挂钩** | 边界链到 [06](../../../../../01_顶层概念/06_投资哲学体系总纲.md) · [`01_实践目标与策略` §边界](../01_实践目标与策略.md) |

---

## 一、执行顺序与依赖

| # | Step | 上游 | 关键产出 | 行数 | 实施状态 |
|---|---|---|---|---|---|
| 1 | [step_01_环境与基础设施](./step_01_环境与基础设施.md) | - | K3s + vLLM + Milvus + Neo4j + 骨架 | 1057 | ⏳ |
| 2 | [step_02_数据采集与50案例Holdout](./step_02_数据采集与50案例Holdout.md) | step_01 | akshare + PDF OCR + 50 案例锁库（SHA256）| 1162 | ⏳ |
| 3 | [step_03_Teacher蒸馏](./step_03_Teacher蒸馏.md) | step_02 + D5 step_03 完成后（Teacher/Label 就绪，对齐共享规约 M1/M2） | 3500 条蒸馏数据 + Verified | 1108 | ⏳ |
| 4 | [step_04_财务测谎引擎LoRA](./step_04_财务测谎引擎LoRA.md) | step_03 | financial_fraud_lora_v1 + Recall ≥ 0.95 | 1089 | ⏳ |
| 5 | [step_05_大股东诚信引擎LoRA](./step_05_大股东诚信引擎LoRA.md) | step_03 | shareholder_lora_v1 + RAG + Recall ≥ 0.90 | 1034 | ⏳ |
| 6 | [step_06_关联交易引擎LoRA](./step_06_关联交易引擎LoRA.md) | step_03 | related_party_lora_v1 + Neo4j + Recall ≥ 0.85 | 1078 | ⏳ |
| 7 | [step_07_3引擎服务部署](./step_07_3引擎服务部署.md) | step_04+05+06 | vLLM multi-lora + 3 路由 + LangGraph | 812 | ⏳ |
| 8 | [step_08_decision_gate聚合与审计](./step_08_decision_gate聚合与审计.md) | step_07 | DecisionGate + 永久审计（SHA256 哈希链）+ 3 Stream | 874 | ⏳ |
| 9 | [step_09_50案例Holdout端到端评测](./step_09_50案例Holdout端到端评测.md) | step_08 | 评测脚本 + 漏判 = 0 + 100 公司白名单 | 917 | ⏳ |
| 10 | [step_10_阶段验收](./step_10_阶段验收.md) | step_09 | validate_stage_1_cryo_guard.sh + 验收 PDF | 704 | ⏳ |

**共计**：10 份 step，**9,835 行**。

---

## 二、关键决策与契约

| # | 关键约定 |
|---|---|
| 全局 | service_name = `cryo-guard`；包路径 `apps/cryo_guard/`；端口 8081 |
| 跨维度 | 维度五 Teacher 接口约定 `http://d5-teacher-svc.diting:8000/v1/teacher/distill`；须 **D5 step_03 完成后**就绪 |
| 训练 | base_model: Qwen2.5-7B-Instruct；lora_rank=16；alpha=32；epochs=3；lr=1e-4 |
| Holdout | 50 案例（30 财务+10 大股东+10 关联）SHA256 永久锁库；写入守门 |
| 服务 | vLLM `--enable-lora --max-loras 4` multi-lora 热加载 |
| 审计 | SHA256 哈希链；应用层拒绝 UPDATE/DELETE；永久不可改 |
| 验收 | 9 项硬卡，任一 ❌ → 禁止签字 + 禁止进入扩展期 |

---

## 三、L4 实践记录预期清单

| step | L4 实践记录文件名 |
|---|---|
| step_01 | `实践记录_step_01_环境与基础设施.md` |
| step_02 | `实践记录_step_02_数据采集与50案例Holdout.md` |
| step_03 | `实践记录_step_03_Teacher蒸馏.md` |
| step_04 | `实践记录_step_04_财务测谎引擎LoRA.md` |
| step_05 | `实践记录_step_05_大股东诚信引擎LoRA.md` |
| step_06 | `实践记录_step_06_关联交易引擎LoRA.md` |
| step_07 | `实践记录_step_07_3引擎服务部署.md` |
| step_08 | `实践记录_step_08_decision_gate聚合与审计.md` |
| step_09 | `实践记录_step_09_50案例Holdout端到端评测.md` |
| step_10 | `实践记录_step_10_阶段验收.md` + `阶段总结_stage_1_启动期.md` |

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-16 | 全部 10 个 step 文档生成完成，共 9,835 行 |
| 2026-05-17 | **索引去周次化**：删除「周次」列；L3↔L4 权威映射；跨维节拍见 **14_ §九**；上游依赖仍以 step 序号表述 |
