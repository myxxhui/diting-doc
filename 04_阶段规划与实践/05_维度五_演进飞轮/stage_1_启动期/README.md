# 实践看板 · 维度五·演进飞轮 · 启动期

> [!NOTE] **[TRACEBACK]**
> - **L3 阶段设计**: [03_/05_维度五/stages/stage_1_启动期/](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/)
> - **DNA**: [_System_DNA/05_super_evo/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/05_super_evo/dna_stage_1_启动期.yaml)
> - **L5 验收**: l5-stage-d5s1

---

## 一、阶段目标速览

| 项 | 内容 |
|---|---|
| **时段** | 10 周 |
| **核心目标** | 4 P0 组件实现 AI 模型自我进化基础设施 |
| **成功标准** | 4 组件可运行；首次 LoRA 训练成功；Kappa ≥ 0.80 |

---

## 二、4 组件进度看板

| 组件 | 计划交付 | 状态 | 实践记录 |
|---|---|---|---|
| C1·Teacher LLM 蒸馏 | W2 | ✅ | [实践记录_step_02](./实践记录_step_02_C1_Teacher蒸馏器.md) |
| C2·Label Studio | W3 | ✅ | [实践记录_step_03](./实践记录_step_03_C2_Label_Studio部署.md) |
| C3·LLaMA-Factory 训练器 | W4 | ⏳ | |
| C4·双盲 Kappa 校准 | W5 | ⏳ | |

---

## 三、周进度看板（10 周）

| 周次 | 主要任务 | 状态 | 实践记录 |
|---|---|---|---|
| W1-W2 | C1 Teacher 蒸馏（Claude-3.5 API + JSONL）| ✅ | [step_02](./实践记录_step_02_C1_Teacher蒸馏器.md) |
| W3 | C2 Label Studio 部署 + 标注流程 | ✅ | [step_03](./实践记录_step_03_C2_Label_Studio部署.md) |
| W4-W5 | C3 LLaMA-Factory 训练流水线 + Holdout 评测 | ⏳ | |
| W5-W6 | C4 Kappa 校准实现 | ⏳ | |
| W7-W8 | 灰度发布流程 + lora_updated 事件 | ⏳ | |
| W9-W10 | 全链路：维度一首次 LoRA 训练成功 | ⏳ | |

---

## 四、关键验收指标实时跟踪

| 指标 | 目标 | 当前 | 状态 |
|---|---|---|---|
| Teacher 蒸馏吞吐 | ≥ 500 条/天 | 契约用例已绿（dry_run）；生产需 key 后复验延迟 | ⚠️ |
| 双盲 Kappa | ≥ 0.80 | - | ⏳ |
| 首次 LoRA 训练 | 成功 | - | ⏳ |
| lora_updated 事件 | 可发布 | - | ⏳ |

---

## 五、下游消费状态

| 下游维度 | 需要的 LoRA | 提供状态 |
|---|---|---|
| 01_cryo_guard | 3 P0 引擎 LoRA | ⏳ |
| 02_deep_strike | Thesis LoRA | ⏳ |
| 03_holding_watch | 叙事一致性 NLI LoRA | ⏳ |

---

## 六、实践记录索引

参考模板：[../../_模板/](../../_模板/)。每条记录对应一个 [L3 step](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/) 文件。

| # | L3 step | 实践记录文件名 | 状态 |
|---|---|---|---|
| 1 | [step_01_环境与基础设施](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_01_环境与基础设施.md) | [实践记录_step_01_环境与基础设施.md](./实践记录_step_01_环境与基础设施.md) | ✅ |
| 2 | [step_02_C1_Teacher蒸馏器](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_02_C1_Teacher蒸馏器.md) | [实践记录_step_02_C1_Teacher蒸馏器.md](./实践记录_step_02_C1_Teacher蒸馏器.md) | ✅ |
| 3 | [step_03_C2_Label_Studio部署](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_03_C2_Label_Studio部署.md) | [实践记录_step_03_C2_Label_Studio部署.md](./实践记录_step_03_C2_Label_Studio部署.md) | ✅ |
| 4 | [step_04_C3_LLaMA_Factory训练流水线](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_04_C3_LLaMA_Factory训练流水线.md) | `实践记录_step_04_C3_LLaMA_Factory训练流水线.md` | ⏳ |
| 5 | [step_05_Holdout评测器与CI_Block](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_05_Holdout评测器与CI_Block.md) | `实践记录_step_05_Holdout评测器与CI_Block.md` | ⏳ |
| 6 | [step_06_C4_双盲Kappa校准](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_06_C4_双盲Kappa校准.md) | `实践记录_step_06_C4_双盲Kappa校准.md` | ⏳ |
| 7 | [step_07_灰度发布流程](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_07_灰度发布流程.md) | `实践记录_step_07_灰度发布流程.md` | ⏳ |
| 8 | [step_08_lora_updated事件流](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_08_lora_updated事件流.md) | `实践记录_step_08_lora_updated事件流.md` | ⏳ |
| 9 | [step_09_首次LoRA训练联调维度一](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_09_首次LoRA训练联调维度一.md) | `实践记录_step_09_首次LoRA训练联调维度一.md` | ⏳ |
| 10 | [step_10_阶段验收](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_10_阶段验收.md) | `实践记录_step_10_阶段验收.md` + `阶段总结_stage_1_启动期.md` | ⏳ |

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-16 | 初版看板 |
| 2026-05-17 | step_03 C2 Label Studio L4 |
