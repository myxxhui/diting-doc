# 维度五·演进飞轮·启动期·可执行步骤索引

> [!NOTE] **本目录定位**
> 给 Cursor / 开发者的"工作令"，每个 step 文件 = 一个可独立执行的开发任务。
> - 设计依据：见同级 [01_~05_](../) 5 份设计文档
> - DNA 真相源：[../../../../_System_DNA/05_super_evo/dna_stage_1_启动期.yaml](../../../../_System_DNA/05_super_evo/dna_stage_1_启动期.yaml)
> - 完成回写路径：[04_阶段规划与实践/05_维度五_演进飞轮/stage_1_启动期/](../../../../../04_阶段规划与实践/05_维度五_演进飞轮/stage_1_启动期/)

> **[上架与环境]** ECS+K3s · Helm · ACR · **`diting-infra`→`deploy-engine`**。[16](../../../../_共享规约/16_阿里云ECS_K3s_ACR_Helm部署与deploy-engine链路.md) · [L3§1](../../../../_共享规约/L3步骤文档_部署价值哲学_必选引用.md)

<a id="l3-step-l4-mapping-authority"></a>

### L3 ↔ L4 映射（权威）

- **唯一执行序**：**`#` 列 1→10**，即 **`step_01` … `step_10`**。
- **L4 实践记录文件名**：`实践记录_step_NN_*.md`，与本目录 **`step_NN_*.md`** 按下文 **「三、L4 实践记录预期清单」** **1:1**。
- **日历 / 跨维节拍**：见 [14_](../../../../_共享规约/14_六维度启动期统一节奏表.md)（含 **§九**）；**本目录不以周次为执行序**。

## 〇、三线并行门禁

| 线 | 要求 |
|---|---|
| **用户价值** | [15](../../../../_共享规约/15_前后端职责与产品价值优先级.md)；lora_updated → 用户对「系统在进化」的感知（经 D0） |
| **部署** | MinIO/WandB/训练 Job 等资源 **Helm/K8s** 描述在 **infra**；**勿改 deploy-engine 子模块** |
| **哲学** | 数据伦理、双盲守门；链 [06](../../../../01_顶层概念/06_投资哲学体系总纲.md)·[边界](../01_实践目标与策略.md) |

---

## 一、执行顺序与依赖

| # | Step | 上游 | 关键产出 | 行数 | 文档状态 |
|---|---|---|---|---|---|
| 1 | [step_01_环境与基础设施](./step_01_环境与基础设施.md) | - | apps/super_evo + MinIO + DVC + WandB | 127 | ✅ L3 v2 |
| 2 | [step_02_C1_Teacher蒸馏器](./step_02_C1_Teacher蒸馏器.md) | step_01 | Claude→JSONL；≥500/天；no-fake | 157 | ✅ L3 v2 |
| 3 | [step_03_C2_Label_Studio部署](./step_03_C2_Label_Studio部署.md) | step_02 | LS 3 维模板 + 双盲≥10% + verified 严格 | 150 | ✅ L3 v2 |
| 4 | [step_04_C3_LLaMA_Factory训练流水线](./step_04_C3_LLaMA_Factory训练流水线.md) | step_03 | LoRA 训练 + leak check + lora_versions | 165 | ✅ L3 v2 |
| 5 | [step_05_Holdout评测器与CI_Block](./step_05_Holdout评测器与CI_Block.md) | step_04 | Holdout 永久锁库 + 退化 5% CI Block | 163 | ✅ L3 v2 |
| 6 | [step_06_C4_双盲Kappa校准](./step_06_C4_双盲Kappa校准.md) | step_03 | Kappa ≥0.80 + 培训闭环 + 守门 step_04 | 152 | ✅ L3 v2 |
| 7 | [step_07_灰度发布流程](./step_07_灰度发布流程.md) | step_05+06 | 5 stage release + manual_gate + rollback | 161 | ✅ L3 v2 |
| 8 | [step_08_lora_updated事件流](./step_08_lora_updated事件流.md) | step_07 | XADD events:flywheel:lora_updated + 兜底 | 148 | ✅ L3 v2 |
| 9 | [step_09_首次LoRA训练联调维度一](./step_09_首次LoRA训练联调维度一.md) | step_08 + D1 | 真实暴雷 reject 提升 ≥5% + 回滚演练 | 152 | ✅ L3 v2 |
| 10 | [step_10_阶段验收](./step_10_阶段验收.md) | step_09 | 6 大检查 + assert_no_bypass + L5 `l5-stage-d5s1` | 165 | ✅ L3 v2 |

**共计**：10 份 step，**~1,540 行**（L3 实施规划体；旧版 ~9,921 行嵌入代码已剥离）。

**Makefile 前缀**：`evo-stepNN-*`（配置驱动）。

**no-mock & no-bypass**：生产路径禁止 stub teacher / fake training / fake event；manual_gate 签字不可绕过；`tests/` 内 mock 合法但不入业务库。

---

## 二、关键决策与契约

| # | 关键约定 |
|---|---|
| 全局 | service_name = `super-evo`；包路径 `apps/super_evo/`；端口 8085 |
| 4 P0 组件 | C1 Teacher 蒸馏 / C2 Label Studio / C3 LLaMA-Factory / C4 双盲 Kappa |
| 训练 | base_model: Qwen2.5-7B-Instruct；lora_rank=16/32 |
| 质量门禁 | Kappa ≥ 0.80（不通过则重标）；Holdout 退化 > 5% → CI Block |
| dry_run 优先 | step_02/04/09 全支持 dry_run（无 Claude key/无 GPU/无 D1 也可跑通）|
| MinIO | s3://super-evo/ （蒸馏 JSONL + 模型权重）|
| 事件 | events:flywheel:lora_updated 含 lora_name/version/sha256/metrics/triggered_by |
| 下游 | C1: D1 cryo_guard / D2 deep_strike / D3 holding_watch 都消费此能力 |

---

## 三、L4 实践记录预期清单

| step | L4 实践记录文件名 |
|---|---|
| step_01 | `实践记录_step_01_环境与基础设施.md` |
| step_02 | `实践记录_step_02_C1_Teacher蒸馏器.md` |
| step_03 | `实践记录_step_03_C2_Label_Studio部署.md` |
| step_04 | `实践记录_step_04_C3_LLaMA_Factory训练流水线.md` |
| step_05 | `实践记录_step_05_Holdout评测器与CI_Block.md` |
| step_06 | `实践记录_step_06_C4_双盲Kappa校准.md` |
| step_07 | `实践记录_step_07_灰度发布流程.md` |
| step_08 | `实践记录_step_08_lora_updated事件流.md` |
| step_09 | `实践记录_step_09_首次LoRA训练联调维度一.md` |
| step_10 | `实践记录_step_10_阶段验收.md` + `阶段总结_stage_1_启动期.md` |

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-16 | 全部 10 个 step 文档生成完成，共 9,921 行 |
| 2026-05-17 | **索引去周次化**；**14_ §九** 承载跨维映射与 Mock 退场闸；L3↔L4 权威说明 |
