# Step 05 · 叙事一致性 NLI LoRA（narrative_nli_lora_v1）

## §1 一句话定位与本步交付物

**一句话**：训练 **`narrative_nli_lora_v1`**（base Qwen2.5-7B；rank=16；3 类 NLI：entailment/neutral/contradiction）+ 训练数据 **≥150 对**（train 100 / dev 20 / holdout 30，40/30/30 分布）+ **Holdout Accuracy ≥0.85** + vLLM 热加载客户端；判定 thesis vs 最新公告/财报关系，输出 `narrative_label / narrative_score`。

**交付物**（勾选 = 完成）：
- [ ] **A**（训练数据）：`training/data/narrative_nli/{train,dev,holdout}.jsonl`；alpaca 格式
- [ ] **B**（LLaMA-Factory 配置）：`training/configs/narrative_nli_lora.yaml`
- [ ] **C**（训练脚本）：`training/scripts/train_nli.sh`（可重复）
- [ ] **D**（评测）：`training/scripts/evaluate_nli.py` → JSON 报告 + per-class
- [ ] **E**（adapter）：`outputs/narrative_nli_lora_v1/` push 到 D5 模型注册表
- [ ] **F**（NLI 客户端）：`apps/state_watch/health/narrative_nli.py` 调 vLLM；**降级**：未加载时返 `degraded` 标注，**禁止**伪造 entailment
- [ ] **G**（Makefile）：`make watch-step05-all`

> **依赖**：step_02 新闻探针有数据；D5 LoRA 训练流水线最佳；本地 LLaMA-Factory 跑通即可。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../04_模型训练与部署.md](../04_模型训练与部署.md)、[../03_数据采集与预处理.md](../03_数据采集与预处理.md) §四
> - **DNA**：`deliverables.narrative_consistency`（model/rank/accuracy≥0.85）
> - **上游 D5**：`_System_DNA/05_super_evo/dna_stage_1_启动期.yaml` M1/M2
> - **L4**：[实践记录_step_05_叙事一致性NLI_LoRA.md](../../../../../04_阶段规划与实践/03_维度三_持仓监控/stage_1_启动期/实践记录_step_05_叙事一致性NLI_LoRA.md)
> - **上游**：step_02、D5 LLaMA-Factory；**下游**：step_06 健康度

## §3 数据采集对象 / 落库映射

| 输入 | 输出 |
|---|---|
| 公开财报/公告片段 + 模拟 thesis 段 | `train/dev/holdout.jsonl`（≥150）|
| Holdout 评测 | `outputs/evaluations/nli_v1_holdout.json` |
| 线上 NLI 调用 | `narrative_scores` 表（仅 score+label+evidence_ref，非长文）|

## §3.5 数据质量验收矩阵（NLI LoRA · 仅启动期）

### §3.5.1 训练数据质量

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| D1 | **总量** | ≥150（100/20/30）| ⚠️ 数据合成需 D5 Teacher 改写 | <150 不准出训练 |
| D2 | **标签分布** | 40/30/30 entail/neutral/contradiction | ✅ | 偏斜>10% 重采 |
| D3 | **真实来源** | thesis 来自 D2 卡片（或人工种子）+ 真实公告片段 | ⚠️ 启动期需手工合成部分 | 合成比例≤30% |
| D4 | **去重 + leak check** | train/dev/holdout 无重复样本；symbol 留出 | ✅ | leak→重切 |

### §3.5.2 训练与评测

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| T1 | **LoRA 参数** | rank=16 alpha=32 epoch=3 lr=2e-4 | ✅ 与 DNA | 调参写 ADR |
| T2 | **Holdout Accuracy** | ≥0.85 | ⚠️ 启动期目标 | <0.85 走 §12 回退 |
| T3 | **F1-macro** | ≥0.80 | ⚠️ | <0.80 标 partial |
| T4 | **per-class** | contradiction recall ≥0.80（生产负样本最重要）| ⚠️ | <0.80 增强数据 |
| T5 | **Holdout 防 leak** | symbol 不重叠 | ✅ | — |

### §3.5.3 推理与降级

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| I1 | **vLLM 热加载** | `--enable-lora --max-loras 4` | ⚠️ GPU 必需 | 无 GPU 走 D5 远程 |
| I2 | **未加载降级** | adapter 未加载→标 `degraded` + score=null；**禁止**伪造 entailment | ✅ | log warning |
| I3 | **延迟** | 单条 NLI P95 <8s | ⚠️ | 超时 partial |
| I4 | **evidence 留痕** | 调用入参 thesis+公告片段 hash 入库 | ✅ | — |

### §3.5.4 no-mock

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| N1 | **业务路径不用 stub label** | 仅 tests/ fixture 合法 | ✅ | — |
| N2 | **THESIS_NLI_MODE=stub 禁止生产** | runtime guard | ✅ | — |

> 共 **15 项**。

## §4 凭证清单

| 凭证 | 用途 | 何时 |
|---|---|---|
| GPU（RTX 4090 24G）或 D5 远程训练 | LoRA 训练 | 训练阶段 |
| `HF_TOKEN` | Qwen2.5-7B 下载 | 已 step_01 |
| `WANDB_API_KEY`（可选）| 训练监控 | — |
| D5 Teacher LLM key（可选）| 合成数据 | 准备数据阶段 |

> **禁止**用 stub label 替代评测准出。

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 训练数据 | ≥150 |
| Holdout Accuracy | ≥0.85 |
| 推理路径 | vLLM 热加载或降级标注 |

## §6 下一步

本步 ✅ → step_06 健康度计算（消费 narrative_score）。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A 数据生成** | `training/scripts/build_synthetic_data.py` | D2 thesis 卡 + 真实公告片段 + Teacher 改写 | 行数 ≥150 |
| **B alpaca info** | `training/data/dataset_info.json` | 注册 narrative_nli | 解析 OK |
| **C LF config** | `training/configs/narrative_nli_lora.yaml` | rank/alpha/epoch | 训练启动 |
| **D 训练脚本** | `training/scripts/train_nli.sh` | LLaMA-Factory CLI | adapter 产出 |
| **E 评测脚本** | `training/scripts/evaluate_nli.py` | acc/F1/per-class JSON | report 写盘 |
| **F NLI 客户端** | `health/narrative_nli.py` | httpx vLLM；degraded 标注 | mock test |
| **G adapter 推送 D5** | `scripts/push_adapter_to_d5.sh` | D5 register API | 远程列表可见 |
| **H 单测** | `test_nli_client.py` | ≥6（含降级路径不伪造）| pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `watch-step05-prep` | GPU 可用 or D5 可达；HF_TOKEN |
| `watch-step05-data` | build_synthetic_data；行数检查 |
| `watch-step05-train` | train_nli.sh；adapter 产出 |
| `watch-step05-eval` | evaluate_nli.py；Acc≥0.85 |
| `watch-step05-deploy` | vLLM 热加载或注册到 D5 |
| `watch-step05-smoke` | 1 case 推理；非 degraded |
| `watch-step05-test` | pytest ≥6 |
| `watch-step05-all` | data+train+eval+deploy+test |
| `watch-step05-status` | 模型路径 + 最近评测分数 |

### §7.3 指引

数据先行（合成质量决定上限）；leak 严格；评测看 contradiction recall（生产最关注的是"识破"）；adapter 推送 D5 注册便于热加载。

## §8 部署节奏

本机训练 + vLLM 推理；扩展期到 K3s `vllm-nli` Deployment（与 D1 共用 vllm 或独立）。

## §9 准出标准

- [ ] §3.5 15 项；Acc≥0.85；F1-macro≥0.80
- [ ] adapter 路径 + 评测 JSON 留档
- [ ] `make watch-step05-all`；L4 回写（数据量、acc、F1、per-class）

## §10 [Deploy]

K3s 扩展期；启动期本机即可。

## §11 依赖

step_02；D5 训练流水线（软）；GPU 必需训练。

**严禁**：生产路径 stub label；evidence 不留痕。

## §12 风险与回退

| 触发 | 动作 |
|---|---|
| Acc<0.85 | 增数据→重训；超 2 次仍未达→ADR 写当前能力 + 放宽至 0.80 + 阻塞 step_06 上线 |
| F1-macro<0.80 | 加少数类样本 |
| GPU 不可用 | 走 D5 远程；或转 base model NLI（无 LoRA） |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 943 行嵌入数据/yaml；§3.5 15 项；no-stub label；`watch-step05-*`；943→~280 行 |
| 2026-05-16 | 初版 943 行 |
