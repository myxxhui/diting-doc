# 实践看板 · 维度一·极寒防御 · 启动期

> [!NOTE] **[TRACEBACK]**
> - **L3 阶段设计**: [03_/01_维度一/stages/stage_1_启动期/](../../../03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/)
> - **DNA**: [_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml)
> - **L5 验收**: l5-stage-d1s1

---

## 一、阶段目标速览

| 项 | 内容 |
|---|---|
| **时段** | stage_1（权威：`step_01`～`step_10`；日历对齐见 [14](../../../03_原子目标与规约/_共享规约/14_六维度启动期统一节奏表.md)）|
| **核心目标** | 3 P0 引擎 + decision_gate 实现"任何对外输出必须先过防御门禁" |
| **成功标准** | 50 案例 Holdout：Recall ≥ 0.90、Precision ≥ 0.70、漏判 = 0 |

---

## 二、引擎进度看板

| 引擎 | LoRA | 关联 step | Holdout Recall | 状态 | 实践记录 |
|---|---|---|---|---|---|
| E1·财务测谎 | financial_fraud_lora_v1 | step_04 | 目标 ≥ 0.95 | ⏳ | |
| E2·大股东诚信 | shareholder_lora_v1 | step_05 | 目标 ≥ 0.90 | ⏳ | |
| E3·关联交易 | related_party_lora_v1 | step_06 | 目标 ≥ 0.85 | ⏳ | |
| decision_gate | - | step_08 | 漏判 = 0 | ⏳ | |

---

## 三、进度分组（按 step；日历仅对齐 [14](../../../03_原子目标与规约/_共享规约/14_六维度启动期统一节奏表.md)）

| step 区间 | 主要任务 | 状态 | 实践记录 |
|---|---|---|---|
| step_01 | 基础设施（K3s + vLLM + Milvus + Neo4j）| ✅ | [实践记录_step_01_环境与基础设施.md](./实践记录_step_01_环境与基础设施.md) |
| step_02 | 数据采集 + 50 案例 Holdout 整理 | ✅ **10 只全采 + 质量矩阵 21 项无 ❌（2026-05-23）** | [实践记录_step_02_数据采集与50案例Holdout.md](./实践记录_step_02_数据采集与50案例Holdout.md) |
| step_03 | Teacher 蒸馏 + Verified | ✅ **启动期候选耗尽（121 条 DB / 37 条 verified）** | [实践记录_step_03_Teacher蒸馏.md](./实践记录_step_03_Teacher蒸馏.md) |
| step_04～06 | 3 LoRA 训练 + Holdout 评测 | ⏳ | |
| step_07～08 | 3 引擎服务 + decision_gate + 审计日志部署 | ⏳ | |
| step_09～10 | 联调验收 + 50 案例 Holdout 通过 | ⏳ | |

---

## 四、数据采集进度

| 数据 | 目标 | 实际 | 状态 |
|---|---|---|---|
| 全 A 股财报 | 5000 家 × 5 年 | - | ⏳ |
| 财报附注 OCR | 500 家 | - | ⏳ |
| 大股东公告 | 500 家 | - | ⏳ |
| 股权穿透 | 500 家 | - | ⏳ |
| 50 案例 Holdout | 50 | - | ⏳ |
| Teacher 蒸馏 | 3500 条 | - | ⏳ |
| Verified | 2600 条 | - | ⏳ |

---

## 五、依赖就绪状态

| 依赖 | 期望就绪（step / 里程碑） | 实际状态 |
|---|---|---|
| 05_super_evo: Teacher 蒸馏 + LLaMA-Factory | **D5 step_03** 完成后 · 对齐 **14** M1/M2 | ⏳ |
| 平台：K3s + vLLM + Milvus + Neo4j | step_01 准出 | ⚠️ 代码与 YAML 已交付；本机未连集群，Running 态待节点复验 |

---

## 六、关键验收指标实时跟踪

| 指标 | 目标 | 当前 | 状态 |
|---|---|---|---|
| 财务测谎 Holdout Recall | ≥ 0.95 | - | ⏳ |
| 大股东诚信 Holdout Recall | ≥ 0.90 | - | ⏳ |
| 关联交易 Holdout Recall | ≥ 0.85 | - | ⏳ |
| 综合 Precision | ≥ 0.70 | - | ⏳ |
| decision_gate 漏判 | = 0 | - | ⏳ |

---

## 七、实践记录索引

按 `实践记录_step_{NN}_*.md` 命名（与 L3 `step_NN_*.md` 1:1）。每条记录对应一个 [L3 step](../../../03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/steps/README.md) 条目。

参考模板：[../../_模板/](../../_模板/)

| # | 对应 L3 step | 实践记录文件名 | 状态 |
|---|---|---|---|
| 1 | [step_01_环境与基础设施](../../../03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/steps/step_01_环境与基础设施.md) | `实践记录_step_01_环境与基础设施.md` | ✅ |
| 2 | [step_02_数据采集与50案例Holdout](../../../03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/steps/step_02_数据采集与50案例Holdout.md) | `实践记录_step_02_数据采集与50案例Holdout.md` | ⚠️ |
| 3 | [step_03_Teacher蒸馏](../../../03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/steps/step_03_Teacher蒸馏.md) | `实践记录_step_03_Teacher蒸馏.md` | ⚠️ 阶段 A |
| 4 | [step_04_财务测谎引擎LoRA](../../../03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/steps/step_04_财务测谎引擎LoRA.md) | `实践记录_step_04_财务测谎引擎LoRA.md` | ⏳ |
| 5 | [step_05_大股东诚信引擎LoRA](../../../03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/steps/step_05_大股东诚信引擎LoRA.md) | `实践记录_step_05_大股东诚信引擎LoRA.md` | ⏳ |
| 6 | [step_06_关联交易引擎LoRA](../../../03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/steps/step_06_关联交易引擎LoRA.md) | `实践记录_step_06_关联交易引擎LoRA.md` | ⏳ |
| 7 | [step_07_3引擎服务部署](../../../03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/steps/step_07_3引擎服务部署.md) | `实践记录_step_07_3引擎服务部署.md` | ⏳ |
| 8 | [step_08_decision_gate聚合与审计](../../../03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/steps/step_08_decision_gate聚合与审计.md) | `实践记录_step_08_decision_gate聚合与审计.md` | ⏳ |
| 9 | [step_09_50案例Holdout端到端评测](../../../03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/steps/step_09_50案例Holdout端到端评测.md) | `实践记录_step_09_50案例Holdout端到端评测.md` | ⏳ |
| 10 | [step_10_阶段验收](../../../03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/steps/step_10_阶段验收.md) | `实践记录_step_10_阶段验收.md` + `阶段总结_stage_1_启动期.md` | ⏳ |

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-16 | 初版看板（实践记录待填充）|
| 2026-05-17 | 看板去「计划周」列；分组改为 step；依赖对齐 **14_**（§九） |
| 2026-05-17 | step_03 **阶段 A** L4：`实践记录_step_03_Teacher蒸馏.md`（全量见文内「阶段 B」） |
