# L4 · 维度五演进飞轮 · 启动期 · 实践记录 step_05 Holdout 评测器 + CI Block

> **状态**：✅ tier-1 完成（2026-05-25）；✅ tier-2 CPU 替代评测完成（2026-05-27）；✅ **tier-2 真实 GPU vLLM 评测完成（2026-05-27，按量付费 cn-hongkong-b）**

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[step_05_Holdout评测器与CI_Block.md](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_05_Holdout评测器与CI_Block.md)
> - **DNA**：`lora_gatekeeper`（holdout_required + regression_block 5%）+ `holdout_management.policy: 永久锁库`
> - **L5**：`02_验收标准.md#l5-stage-evo_05`
> - **上游**：← step_04 LLaMA-Factory 训练流水线 / **下游**：→ step_07 灰度部署

## 一、本步骤目标

实现 `HoldoutEvaluator`（A/B/C/D 交付物）：
- A：按维度加载 holdout jsonl；批推理（mock / vLLM）；统计 recall/precision/f1
- B：与 prod baseline 对比；任一指标退化 >5% 触发 CI Block
- C：regression_gate（YAML 阈值驱动，可覆盖）
- D（tier-1）：mock 模式评测通过；regression-sim 验证 blocked=True

## 二、实际进展（2026-05-25 W5）

| 项 | 状态 | 证据 |
|----|------|------|
| `apps/super_evo/quality/holdout_evaluator.py` | ✅ | load / infer / metrics / evaluate 完整 |
| `apps/super_evo/quality/regression_gate.py` | ✅ | YAML 阈值 + manual_override_gate |
| holdout 锁库（三维度）| ✅ | cryo=50 / thrust=30 / narrative=30 |
| leak-check（H2）| ✅ | 三维度 0 重叠 |
| mock 评测（cryo）| ✅ | recall=0.92 precision=0.92 f1=0.92 PASS（首次无 baseline）|
| mock 评测（thrust）| ✅ | recall=0.93 precision=0.93 f1=0.93 PASS |
| mock 评测（narrative）| ✅ | recall=0.87 precision=0.87 f1=0.87 PASS |
| regression-sim（C2）| ✅ | blocked=True，exit 1 ✅ |
| `pytest tests/super_evo/test_holdout_evaluator.py` | ✅ | **28 passed** |
| `make evo-step05-all` | ✅ | 全流程通过 |
| tier-2：CPU 替代评测（真实 LoRA 推理）| ✅ | cryo=50/thrust=30/narrative=30 全推完；metrics=0（sanity adapter 预期）；结果存 `holdout_results_cpu.json` |
| tier-2：真实 vLLM 评测 | ✅ | 按量付费 GPU（cn-hongkong-b），三维 110 条全推完；mode=vllm；metrics=0（sanity adapter 预期）；详见三C节 |
| holdout_evaluations DB 落库 | ⏳ | tier-2，等 K3s 真 DB |

## 三、命令与输出摘要

```
make evo-step05-all
  cryo: 50 ✅  thrust: 30 ✅  narrative: 30 ✅
  leak check：三维度 0 重叠 ✅
  28 passed in 0.04s
  regression-sim blocked=True（recall -11.1%，阈值 -5%）✅
  cryo PASS  thrust PASS  narrative PASS
✅ [evo-step05-all] tier-1 准出
DECISION_PENDING: 真实评测需 vLLM + GPU
```

## 四、DECISION_PENDING 与 SKIP_REASON

| 项 | 类型 | 说明 |
|----|------|------|
| 真实 vLLM 评测 | ✅ 已完成 | 2026-05-27，按量付费 GPU，NodePort 30530 |
| holdout_evaluations 落库 | SKIP_REASON | 等 K3s 真 DB；tier-1 用内存结构 |
| GitHub Actions holdout-gate.yml | SKIP_REASON | 等 CI 环境接入（启动期不强制）|

## 五、准出复核（tier-1）

- [x] holdout 锁库三维度（cryo=50 / thrust=30 / narrative=30）
- [x] leak-check 0 重叠（H2）
- [x] mock 评测三维度 PASS（首次无 baseline）
- [x] regression-sim 正确触发 blocked=True（exit 1）
- [x] pytest 28 passed（含 first_run / baseline / vLLM_no_url / manual_override）
- [x] `make evo-step05-all` 退码 0
- [x] tier-2：CPU 替代真实推理评测（110条全推完，results_cpu.json；详见三B节）
- [x] tier-2：vLLM 真实评测（2026-05-27，按量付费 GPU，三维 PASS，首次无 baseline）

## 三B、tier-2 CPU 替代评测（2026-05-27）

### 背景

P-step_05 `diting-vllm` GPU 推理组因阿里云香港区 `ecs.gn6i-c4g1.xlarge` Spot 库存耗尽（`OperationDenied.NoStock`），无法完成 GPU 上架。采用 CPU 推理替代方案：在 base 节点（`8.217.158.218`，On-Demand ECS）使用 HuggingFace Transformers + PEFT 加载 LoRA adapter 完成推理。

### 评测配置

| 项 | 值 |
|----|-----|
| 脚本 | `run_holdout_cpu.py`（NAS 路径 `/mnt/titan-data/diting-src/output/`）|
| 基础模型 | `/mnt/titan-data/models/Qwen2.5-1.5B-Instruct` |
| 推理设备 | CPU（float16，无 GPU）|
| Prompt 格式 | Qwen Chat Template（apply_chat_template）|
| max_new_tokens | 32 |
| do_sample | False |
| 速度 | ~13 秒/样本 |

### 评测结果

| 维度 | adapter | holdout 条数 | recall | precision | f1 | 模式 |
|------|---------|------------|--------|-----------|-----|------|
| cryo | `cryo_lora_v1` | 50 | 0.0000 | 0.0000 | 0.0000 | cpu_transformers_lora |
| thrust | `thrust_lora_v1` | 30 | 0.0000 | 0.0000 | 0.0000 | cpu_transformers_lora |
| narrative | `narrative_lora_v1` | 30 | 0.0000 | 0.0000 | 0.0000 | cpu_transformers_lora |

**结果文件**：`/mnt/titan-data/diting-src/output/holdout_results_cpu.json`（已下载至 `diting-src/scripts/training/holdout_results_cpu.json`）

### 根因分析

recall/f1=0 是符合预期的 sanity run 结果，原因如下：

1. **训练数据为 sanity dry run**：三个 adapter 训练于 `distilled/financial_fraud/sanity_dry_run.jsonl`（通用金融欺诈数据），非 cryo/thrust/narrative 维度专用分类数据
2. **训练轮次极少（1 epoch）**：sanity 目的仅验证训练流水线（LLaMA Factory + LoRA + NAS）可跑通，非生产训练
3. **模型输出格式未收敛**：base Qwen2.5-1.5B-Instruct 默认生成分析性长文本（如"根据您提供的信息，我将从以下几个方面..."），而非目标 JSON 格式 `{"label":"block"}`；1 epoch sanity 训练不足以改变输出分布
4. **评测流水线本身正常**：脚本完整运行了 load_holdout / run_dim_inference / compute_metrics / write_results，全部110条样本均推理完成，无报错

### 生产训练所需（扩展期目标）

| 项 | 要求 |
|----|------|
| 训练数据 | 每维度 1000+ 条维度专用分类样本（含正确 JSON 输出格式）|
| 训练轮次 | 3-5 epochs + 早停（eval_recall 连续2轮不升则停）|
| 验证集 | 每维度各 100 条，与 holdout 完全隔离 |
| 目标 recall | cryo ≥ 0.85、thrust ≥ 0.82、narrative ≥ 0.80 |
| GPU | 阿里云 `ecs.gn6i-c4g1.xlarge`（T4 16G）或等效 |

## 三C、tier-2 真实 GPU vLLM 评测（2026-05-27 W5）

### 背景

用户确认接受**按量付费**（PostPaid），阿里云香港区 `cn-hongkong-b` Available。P-step_04 起 `ecs.gn6i-c4g1.xlarge`（T4 16G）train 节点，P-step_05 在同节点部署 `diting-vllm`（复用，不另起 infer ECS）。

### 评测配置

| 项 | 值 |
|----|-----|
| GPU | NVIDIA T4 16G（cn-hongkong-b，按量付费） |
| vLLM | `vllm/vllm-openai:v0.6.6`（NAS 离线镜像导入，dtype=half） |
| NodePort | 30530（经 base EIP `8.217.158.218` 访问） |
| 已加载 LoRA | `lora-cryo` / `lora-narrative` / `lora-thrust` |
| VLLM_URL | `http://8.217.158.218:30530` |
| 评测脚本 | `scripts/evo_step05_run.py evaluate <dim> 0 vllm` |

### 评测结果

| 维度 | 条数 | recall | precision | f1 | is_first_run | blocked | 模式 |
|------|------|--------|-----------|-----|------|---------|------|
| cryo | 50 | 0.0000 | 0.0000 | 0.0000 | True | False | vllm |
| thrust | 30 | 0.0000 | 0.0000 | 0.0000 | True | False | vllm |
| narrative | 30 | 0.0000 | 0.0000 | 0.0000 | True | False | vllm |

**全部 PASS**（首次评测，无 baseline，is_first_run=True，不触发 CI Block）。metrics=0 与 CPU 替代评测结论一致（sanity adapter 预期，见三B节根因分析）。

### 关键里程碑

- ✅ 推理链路端到端通：本地 → NodePort → vLLM → LoRA 推理 → 指标统计
- ✅ mode=vllm（非 mock，非 BLOCKED）
- ✅ 三维度 110 条全部推理完成
- `VLLM_URL` 已写入 `diting-src/.env`

## 六、修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-25 | W5 tier-1 完成：holdout 锁库 + 28 passed + regression-sim；BLOCKED(gpu_unavailable) 已记录 |
| 2026-05-27 | tier-2 CPU 替代评测完成：110 条全部推理完毕，metrics=0（sanity adapter 预期结果）；根因分析与扩展期目标已记录 |
| 2026-05-27 | **tier-2 真实 GPU vLLM 评测完成**：用户确认按量付费；P-step_04 训练节点起 T4 GPU；P-step_05 部署 diting-vllm（三 LoRA）；三维 Holdout 全部 PASS（mode=vllm）；GPU 任务全部完成 |
