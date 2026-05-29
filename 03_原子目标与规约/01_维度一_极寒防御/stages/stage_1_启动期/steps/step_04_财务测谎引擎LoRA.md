# Step 04 · 财务测谎引擎 LoRA v1 训练 + Holdout 评测

## §1 一句话定位与本步交付物

**一句话**：用 step_03 的 financial_fraud Verified 数据集训练 Qwen2.5-7B-Instruct + LoRA（rank=16），并实现 5 节点 LangGraph 引擎；在 30 案例 Holdout 上达到 **Recall ≥ 0.95 / Precision ≥ 0.70 / F1 ≥ 0.80**。

**交付物**（勾选 = 完成）：
- [ ] **A**（LoRA 训练完成）：`output/financial_fraud_lora_v1/adapter_model.safetensors` 存在且 size > 60MB（rank=16 全线性层）
- [ ] **B**（WandB 训练曲线）：`train/loss` 末 100 步均值 < 初始 30%；`eval/loss` 末 epoch ≤ 中间最低 × 1.1（无过拟合）
- [ ] **C**（5 节点 Agent）：`apps/cryo_guard/engines/financial_fraud/{field_extractor, feature_calculator, time_series_comparator, peer_comparator, llm_interrogator, engine, schemas}.py` + LangGraph workflow 注册 5 节点 + 入口 + END
- [ ] **D**（30 案例 Holdout 评测）：`output/eval_reports/financial_fraud_holdout_v1.json` 含 `recall ≥ 0.95 / precision ≥ 0.70 / f1 ≥ 0.80 / num_cases = 30 / passed = true`
- [ ] **E**（6 类粉饰特征全触发）：存贷双高 / 现金流背离 / 应收异常 / 存货积压 / 研发资本化突变 / 毛利率异常 在评测样本中各触发 ≥ 1 次
- [ ] **F**（evidence 可追溯）：每个预测 `evidence[]` 含 `source_table / source_period / human_readable_reason`，抽样 5 条对照 SQLite 真值一致
- [ ] **G**（单测）：`pytest tests/cryo_guard/test_financial_fraud_engine.py -v` ≥ 8 passed
- [ ] **H**（Makefile 一键复现）：`make cryo-step04-all` 端到端通过

> **本步是 step_07/09 的硬阻塞**：LoRA 不达标 → 三引擎服务无法上线、Holdout 综合评测拒绝放行。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2 哲学**：[01_维度一_极寒防御 · 04_防御实践策略规划](../../../../../02_战略维度/01_维度一_极寒防御/04_防御实践策略规划.md)
> - **本阶段总览**：[stage_1_启动期/README](../README.md)
> - **L3 模型训练**：[../04_模型训练与部署.md](../04_模型训练与部署.md) §一 训练目标、§二 训练环境、§四 LoRA 训练、§五 Holdout 评测
> - **L3 技术架构**：[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §3.2 引擎基类、§3.3 财务测谎引擎、§3.4 6 类粉饰特征
> - **L3 数据规约**：[../03_数据采集与预处理.md](../03_数据采集与预处理.md) §六 蒸馏 prompt 模板（与本 step 训练对齐）
> - **L3 验收**：[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md) §二 模型验收（财务测谎 Recall ≥ 0.95）
> - **DNA 键**：`_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml` → `deliverables.engines[0]` E1·financial_fraud：`lora_name=financial_fraud_lora_v1`、`rank=16`、`recall ≥ 0.95`、`agents=5`
> - **L4 实践记录**：[实践记录_step_04_财务测谎引擎LoRA.md](../../../../../04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_04_财务测谎引擎LoRA.md)
> - **上游 step**：← step_01（GPU + vLLM 骨架）、step_02（SQLite 真值 + H001~H030 Holdout）、step_03（financial_fraud_{train,val,test}.json）
> - **下游 step**：→ step_07（vLLM 多 LoRA 热加载）、step_09（50 案例综合 Holdout 评测）

## §3 数据采集对象 / 落库映射

**本步不采集数据**——仅**消费** step_03 LLaMA-Factory jsonl + step_02 SQLite 真值。

| 数据流向 | 来源 | 用途 |
|---|---|---|
| `financial_fraud_{train,val,test}.json` | step_03 `training/data/llama_factory/` | LoRA 训练输入 |
| `financial_reports`（含 `industry`）| step_02 SQLite | `field_extractor / peer_comparator` 推理时实时查询 |
| `H001~H030.json`（30 财务测谎案例）| step_02 `training/data/holdout/` | Holdout 评测金标 |
| 训练产物 | `output/financial_fraud_lora_v1/` | LoRA adapter + 训练日志 |
| 评测产物 | `output/eval_reports/financial_fraud_holdout_v1.json` | 指标 JSON + 6 类特征触发统计 |

## §3.5 数据质量验收矩阵（按 Holdout 评测需求反推 · 仅启动期负责）

> **本步范围**：训练 + 5 节点引擎 + Holdout 评测三个环节的质量要求。每行 ✅ 已达成 或 ⚠️ 启动期内有降级路径。**不**列扩展期 / 完善期内容。

### §3.5.1 训练数据质量（消费 step_03 产出 · 训练前校验）

| # | 分析维度 | 必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| Q1 | **6 类粉饰特征每类训练样本充足** | step_03 `teacher_distill` 中 `features.{cash_flow_divergence/double_high/...}` 每类 ≥ 150 条 | ⚠️ 依赖 step_03 §3.5.1·T1 | §7.1·B 训练前自检脚本，缺类则报错并指引回 step_03 补蒸 |
| Q2 | **evidence 字段完整率** | 每条样本 `output.evidence[]` 数组长度 ≥ 2 | ⚠️ 依赖 step_03 蒸馏质量（启动期目标 ≥ 95%）| §7.1·B 训练前抽样 100 条统计；< 95% 则暂停训练 |
| Q3 | **正负样本比** | `label=fraud` 与 `normal` 比 ≈ 30:70 ± 5% | ⚠️ 依赖 step_03 §3.5.1·T4 | §7.1·B 训练前统计；偏差 ≥ 10% 时回 step_03 补蒸 |

### §3.5.2 5 节点 Agent 输出质量（推理阶段）

| # | 节点 | 设计目标 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| N1 | **field_extractor** | 按 `symbol + report_period` 从 `financial_reports` 抽 11 字段（cash / debt / AR / inventory / rd_cap / gross_margin 等），单字段缺失允许返回 null + 标 `missing_field=True` | ✅ ORM 查询直接拿；4 标的 × 4 期 = 16 条记录覆盖 | 抽样验证字段非 null 率 ≥ 90% |
| N2 | **feature_calculator** | 6 类特征公式逐一计算：① 存贷双高（cash/total_assets > 0.3 且 debt/total_assets > 0.3）② 现金流-利润背离（OCF/NetProfit < 0.5）③ 应收异常（AR_yoy > revenue_yoy × 1.5）④ 存货积压（inventory/revenue > 行业中位数 × 1.5）⑤ 研发资本化突变（rd_cap_ratio_yoy > 30%）⑥ 毛利率异常（gross_margin_yoy < -5%） | ⚠️ 公式落地 + 单测 6 类正负各 1 案例 | §7.1·E 公式单测；公式参数（阈值）作为配置项放 `configs/financial_fraud_thresholds.yaml` |
| N3 | **time_series_comparator** | 同 `symbol` 至少 4 期历史的 yoy 趋势 | ⚠️ 需要 step_02 ×4 类报告齐采（annual+semi+q1+q3）| 若不足 4 期，返回"历史不足"标记，仍允许下游 llm_interrogator 工作 |
| N4 | **peer_comparator** | 按 `industry` 拉同行 ≥ 3 家算百分位（gross_margin / inventory_ratio 等）| ⚠️ 启动期 4 标的可能同行业不足 3 家 | 同行业不足时退回"全市场分位"（启动期 4 标的全市场可用）+ 标 `peer_fallback=market_wide` |
| N5 | **llm_interrogator** | 调 vLLM `/v1/chat/completions` w/ LoRA adapter；prompt = 6 类特征值 + 历史趋势 + 同行分位；输出 JSON `{label, confidence, risk_level, category, evidence[], reason_zh}` | ✅ vLLM HTTP 接口直连；schema 校验在 `schemas.py` | LoRA 未加载（推理用 base model）时降级返回 confidence=0.5 + 标 `lora_loaded=False` |

### §3.5.3 Holdout 评测质量（30 案例 · 端到端）

| # | 评测维度 | 准出门槛 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| H1 | **30 案例全跑** | num_cases = 30，不允许 skip | ✅ Holdout 锁库（step_02 J 项）保证可用 | 任一案例 engine 抛异常 → 标 `prediction=fraud + confidence=0.0` 不算 skip |
| H2 | **Recall ≥ 0.95** | 真为 fraud 的样本至少 95% 被预测为 fraud | ⚠️ 训练后实测；不达标进入 §7.3·6 调参循环 ≤ 3 轮 | 调参不达标时 ADR 说明 + 启动期降级到 Recall ≥ 0.85 + 在 step_08 decision_gate 用其他引擎补足 |
| H3 | **Precision ≥ 0.70** | 预测为 fraud 的样本至少 70% 真为 fraud | ⚠️ 实测；偏低 → 调参 + 加 normal 样本 | 同 H2 |
| H4 | **F1 ≥ 0.80** | 调和均值 | ⚠️ 实测 | 同 H2 |
| H5 | **6 类特征触发覆盖** | 30 案例中 6 类特征**各**触发 ≥ 1 次 | ⚠️ Holdout 案例本就按 6 类挑；实测覆盖 | 不达 6 类时回 step_02 §7.9·J 补充对应类型 Holdout 案例（保持 H001~H030 标识不变 + 重新 chmod -w） |
| H6 | **evidence 可溯源** | 每个预测 `evidence[].source_table + source_period` 可在 SQLite 真值表中找到对应行 | ⚠️ 抽样 5 条手工核对 | 抽样发现幻觉 evidence → 回 step_03 §3.5.1·T2 优化 Prompt |

> 共 **14 项启动期质量要求**（Q1~Q3 训练数据 / N1~N5 节点输出 / H1~H6 Holdout 评测）。矩阵中**无 ❌**——某项启动期实在不做的（如多 LoRA 路由）根本不列。

### §3.5.4 质量门槛（合并到 §9.2）

矩阵每行须满足之一：
- **✅ 覆盖**：本步已实现，§9 抽样验证通过；
- **⚠️ 启动期降级**：本步给出明确降级路径（如 N4 peer_fallback、H2 调参循环）+ 引擎在该降级下仍能满足 step_08 decision_gate baseline。

**禁止**：①LoRA 未训出来用 base model 假装通过 Holdout；②指标不达标人工修改 eval JSON；③用 step_03 lookup 表反向作弊（训练集见过的样本进 Holdout）。

## §4 真实数据源与凭证清单

### §4.1 训练资源

| 资源 | 来源 | 备注 |
|---|---|---|
| 基模 Qwen2.5-7B-Instruct | step_01 已下载到 `models/Qwen2.5-7B-Instruct/` | ~14GB |
| LLaMA-Factory ≥ 0.8 | pip / GitHub | `llamafactory-cli --help` 可用 |
| vLLM ≥ 0.4.0 | pip | 推理评测 |
| 训练数据 | step_03 产出 jsonl | 3 份（train/val/test）|
| Holdout 30 案例 | step_02 锁库 | `training/data/holdout/H001-H030.json` |

### §4.2 用户须提供的凭证

| 凭证 | 用途 | 何时需要 | 写在哪里 |
|---|---|---|---|
| `WANDB_API_KEY` | 训练监控（loss 曲线、超参快照）| 训练前 | `diting-src/.env` |
| `HF_TOKEN` | 基模已下载则**无需**；首次下载需 | 训练前 | 同上 |
| GPU 节点 | RTX 4090 24GB（或 A100/H100）| 训练前 | step_01 已就绪 |

> **本步无需** Teacher LLM key（仅训练 + 评测，不蒸馏）。

## §5 启动期目标

### §5.1 训练超参（关键设计）

| 项 | 取值 | 理由 |
|---|---|---|
| 基模 | Qwen2.5-7B-Instruct | 启动期统一基模（D1 三引擎共用，便于 vLLM 多 LoRA 热切换） |
| 微调类型 | LoRA | 显存友好（4090 24GB 单卡可跑） |
| LoRA rank | 16 | 启动期典型值；rank=8 显存更省但表达力略弱、rank=32 显存吃紧 |
| LoRA alpha | 32 | 一般 = rank × 2 |
| LoRA dropout | 0.05 | 防过拟合 |
| 目标层 | all（全线性层）| LLaMA-Factory `lora_target=all` |
| epochs | 3 | 启动期数据量 ~1000 条，3 epoch 足够；过多易过拟合 |
| batch_size | 2 | 24GB 显存约束；用 gradient_accumulation_steps=8 等效 batch=16 |
| cutoff_len | 4096 | 多数样本输入 < 3K token，留 1K 余量 |
| lr | 5e-5 | LoRA 典型起点；warmup_ratio=0.1 |
| fp16 + gradient_checkpointing | true | 24GB 必开 |

> **降级路径**：若 4090 仍 OOM，按 §12 调整：① batch=1；② 切 QLoRA（4bit 量化）；③ rank=8。**禁止**伪造训练成功。

### §5.2 评测目标

| 指标 | 启动期门槛 | 评测集 |
|---|---|---|
| Recall | ≥ 0.95 | H001~H030 30 案例 |
| Precision | ≥ 0.70 | 同 |
| F1 | ≥ 0.80 | 同 |
| 6 类特征触发覆盖 | 6/6 | 同 |
| 端到端单 case 延迟 | < 8 s（GPU）| 30 案例平均 |

### §5.3 可接受退化

- 显存不足 → batch=1 + QLoRA + rank=8（按 §12 顺序降级，每次记录 ADR）；
- 训练后指标不达 → 进入 §7.3·6 调参循环（最多 3 轮：调 epoch / lr / 加正样本 / 改 lora_target）；
- 仍不达 → ADR 说明（启动期降级到 Recall ≥ 0.85 + decision_gate 在 step_08 用其他引擎补足）。

## §6 下一步（一行触发条件）

- **触发条件**：本步全部 ✅ + Holdout 评测 JSON `passed=true` → step_05/06（其他两引擎 LoRA）可继续；step_07（vLLM 多 LoRA 热加载）等三引擎都完成后开工。
- **下一阶段方向**：扩展期改 RLHF / DPO 二次精调 + multi-task LoRA 合并；详见 `stages/stage_2_扩展期/`。

## §7 实施规划（L3 设计 · 给后续执行模型的工作指引）

> **L3 定位**：本节是**设计规划 + 实现要点 + 验证标准**——靠谱地描述"做什么 / 如何执行"，**不嵌入完整 YAML / Python 类 / Prompt 模板代码**。具体落地由 L4 实践记录 / 后续执行模型按本节规划自行完成。

### §7.1 实现要点（按交付物拆分 · L4 / 后续模型按此逐项落地）

| 实现要点 | 涉及代码位置 | 关键设计决策 | 验证标准 |
|---|---|---|---|
| **A LLaMA-Factory 数据集注册** | `training/configs/dataset_info.json` | 三份注册（financial_fraud_train/val/test）：`columns={"prompt":"instruction","query":"input","response":"output"}` | `llamafactory-cli` 加载数据集不报错 |
| **B 训练 YAML + 数据预检** | `training/configs/financial_fraud_lora.yaml` + `training/scripts/precheck_financial_fraud.py` | yaml 含 §5.1 全部超参；预检脚本验证 §3.5.1 Q1~Q3（6 类样本数、evidence 完整率、正负比）；不达预期则退出码非 0 阻断训练 | yaml 可解析；预检脚本对 step_03 产出数据通过 |
| **C 训练脚本与 WandB 集成** | 直接调 `llamafactory-cli train training/configs/financial_fraud_lora.yaml`（不写包装类）；WandB 配置走 `report_to: wandb` | 训练前自动跑 §7.1·B 预检；训练中 WandB 实时记录 loss / lr / grad_norm；结束生成 `output/financial_fraud_lora_v1/` | adapter 落 `output/`，size > 60MB；WandB 有完整 run |
| **D field_extractor 节点** | `apps/cryo_guard/engines/financial_fraud/field_extractor.py` | 按 `symbol + report_period` 查 `financial_reports` 取 11 字段：cash_and_equivalents / short_term_debt / long_term_debt / accounts_receivable / inventory / revenue / net_profit / operating_cash_flow / rd_expense / rd_capitalized / gross_margin；缺字段返回 null + `missing_fields[]` 列表 | 单测对 4 标的 ×4 期 16 条记录抽出 11×16 = 176 字段位，非 null 率 ≥ 90% |
| **E feature_calculator 节点 + 6 类公式** | `feature_calculator.py` + `configs/financial_fraud_thresholds.yaml` | 6 类公式（见 §3.5.2·N2）；阈值放 yaml 便于调参；每个特征输出 `{triggered: bool, score: float, threshold: float, raw_values: {...}}` | 单测 6 类各构造正负 2 案例 = 12 测试，全过；阈值可被 yaml 覆盖 |
| **F time_series_comparator 节点** | `time_series_comparator.py` | 取同 `symbol` 近 4 期 `revenue / net_profit / OCF / gross_margin`，算 yoy 序列；不足 4 期则标 `history_insufficient=True` | 单测构造 4 期数据算 yoy；构造 2 期数据返回 insufficient |
| **G peer_comparator 节点** | `peer_comparator.py` | 按 `industry` 找同行 ≥ 3 家算 percentile（gross_margin / inventory_ratio 等）；不足 3 家退到全市场 + 标 `peer_fallback=market_wide` | 单测 mock 一个 industry 5 标的算分位；mock 1 标的全市场 |
| **H llm_interrogator 节点** | `llm_interrogator.py` + `prompts/financial_fraud.py` | 调 vLLM `/v1/chat/completions` w/ `lora_name=financial_fraud_lora_v1`；prompt 模板 = 公司基础信息 + 6 类特征 raw_values + yoy 趋势 + 同行分位 → JSON 输出；schema 校验失败 retry ≤ 2 次 | mock vLLM 响应通过 Pydantic schema；连续 3 次失败抛异常 |
| **I engine 主类 + LangGraph workflow** | `engine.py` + `schemas.py` | LangGraph: START → field_extractor → 并行(feature_calculator, time_series_comparator, peer_comparator) → llm_interrogator → END；State 含 `symbol/report_period/extracted_fields/features/time_series/peer_stats/prediction`；`engine.run(symbol, period) -> Prediction` | end-to-end mock 跑 1 个 case 返回完整 Prediction |
| **J Holdout 评测脚本** | `training/scripts/eval_financial_fraud_holdout.py` | 读 H001~H030 30 案例 → engine.run() → 对照 `ground_truth.label` 算 Recall/Precision/F1 + 6 类特征触发统计；输出 `output/eval_reports/financial_fraud_holdout_v1.json` 含 `passed=true/false`；指标不达标退出码 1 | 30 案例 100% 完成 + 指标达 §5.2 门槛 |
| **K 单测** | `tests/cryo_guard/test_financial_fraud_engine.py` | 覆盖：5 节点各 1 单测 + 6 类特征单测 + e2e mock 1 个 + Holdout 评测 fixture 数据上跑通 | `pytest -v` ≥ 8 passed |

### §7.2 Makefile 一键复现合约（L3 约定 · L4 / `diting-src/Makefile` 实现）

**设计目的**：训练数据准备好后跑 `make cryo-step04-all` 完成"数据预检 → LoRA 训练 → smoke eval → engine 单测 → Holdout 评测"全套；调参循环用 `make cryo-step04-retrain` 改 yaml 后重训。

**target 合约表**：

| target | 用途（一句话） | 入参（环境变量 · 均有默认） | 验证标准 |
|---|---|---|---|
| `make cryo-step04-prep` | 数据集注册 + GPU 自检 + WandB login | `WANDB_API_KEY / HF_TOKEN` | `nvidia-smi` OK；`wandb status` 已登录 |
| `make cryo-step04-precheck` | §7.1·B 训练前数据预检 | — | 退出码 0；Q1~Q3 全过 |
| `make cryo-step04-train` | LoRA 训练 | `LORA_CONFIG=training/configs/financial_fraud_lora.yaml` | adapter 落 `output/financial_fraud_lora_v1/`，size > 60MB；WandB run 完成 |
| `make cryo-step04-smoke-eval` | 用 val.json 抽 50 条快速评测（确认未崩） | — | F1 > 0.5（仅冒烟，不达 §5.2 门槛允许）|
| `make cryo-step04-engine-test` | 5 节点 + e2e mock 单测 | — | `pytest -v` ≥ 8 passed |
| `make cryo-step04-holdout-eval` | 30 案例 Holdout 评测 | `HOLDOUT_DIR=training/data/holdout` | F1 ≥ 0.80 + Recall ≥ 0.95 + Precision ≥ 0.70 + 6 类全覆盖；`passed=true` |
| `make cryo-step04-all` | **端到端一键**（含上述 6 步） | 同上合并 | 全部退出码 0；4090 单卡端到端 ≤ 3 hr |
| `make cryo-step04-retrain` | 调参循环用：清旧 adapter + 重训 + 重评 | 改 yaml 后跑 | 同 `all`，但跳过 prep |
| `make cryo-step04-status` | 数据量进度快照（只读） | — | 打印训练状态 / WandB run id / 最近一次评测指标 |
| `make cryo-step04-clean` | 清 `output/financial_fraud_lora_v1/` + WandB 本地 cache | — | 已删；**不**清 `models/Qwen2.5-7B-Instruct/`（基模保留） |

**合约要求**（L4 实现时遵守）：
1. **入参环境变量化**：`.env` + 命令行覆盖；超参变化只改 yaml 不改 Makefile；
2. **target 是薄包装**：训练调 `llamafactory-cli`，评测调 `python training/scripts/*.py`；
3. **可重入幂等**：`make cryo-step04-all` 二次执行检测到 adapter 已存在 + Holdout JSON 已 `passed=true` → 跳过训练直接验证；
4. **OOM 显式降级**：训练脚本捕获 OOM 自动按 §5.3 三档降级（batch=1 → QLoRA → rank=8），每次降级日志中文写明并标 ADR；
5. **失败可观察**：每个 target 中文 3 行摘要 + WandB run url。

### §7.3 给后续执行模型的指引（步骤与边界）

L4 / 执行模型按以下顺序，**不偏离 §7.1 实现要点 + §7.2 合约**：

1. **核对前置**：step_01 GPU Ready；step_02 H001~H030 锁库 ✅；step_03 jsonl 6 份就绪 + Verified ≥ 1000；
2. **逐项落地 A~K**：建议顺序 A→B→D→E→F→G→I→C→H→J→K（节点先于训练，便于 mock 测试推理流程）；
3. **集成 Makefile**：按 §7.2 合约表实现 10 个 target；
4. **训练前必跑 precheck**：`make cryo-step04-precheck` 通过后再 `train`；不通过回 step_03 补蒸；
5. **训练后 Holdout 评测**：`make cryo-step04-holdout-eval`；不达 §5.2 进入**调参循环 ≤ 3 轮**（每轮记录 ADR：改了什么、为什么、结果如何）；3 轮仍不达按 §12 ADR + 启动期降级；
6. **§9 准出清单逐项打勾** + 同会话给证据（adapter size、Holdout JSON 摘要、WandB run url）；
7. **回写 L4 实践记录**：训练耗时、最终超参（若调过）、Recall/Precision/F1、6 类特征触发分布、commit hash。

> **L3 责任边界**：本节给规划 + 实现要点 + 验证标准；**不**给完整 yaml / Python 类 / Prompt 字面量；具体落地交给 L4 实践记录 / 后续执行模型。
> **§7 禁止 Mock**：训练不允许用 mock data 充数；评测不允许跳过案例；vLLM 不可用须等待 step_01 修复，**不**用 mock vLLM 响应通过 Holdout。

## §8 部署节奏（本步在哪里跑）

| 阶段 | 形态 | 是否本步必须 | 说明 |
|---|---|---|---|
| **本机开发** | `python -m apps.cryo_guard.engines.financial_fraud.engine` + `pytest` + `llamafactory-cli train` | **必须** | 5 节点代码 + 训练 + 评测在本机完成（tier-1）|
| **P轨 GPU 训练（★M2 · tier-2）** | P-step_04 `make up-stack diting-training` → Job → `make down-stack diting-training` | **M2 必须** | 训练 Job 由 `diting-infra/charts/diting-training/` 管理（`--set training.dim=cryo`）；NAS LoRA 权重保留；GPU ECS 随 down 回收 |
| **P轨 GPU 推理（★M2 · tier-2）** | P-step_05 `make up-stack diting-vllm`；LoRA 自动从 NAS `/lora/` 热加载 | **M2 Holdout 必须** | vLLM 在 `infer` ns（`vllm-infer-svc.infer:8000`）；推理完成后 `make down-stack diting-vllm`（保留 NAS）|
| **本机 docker-compose** | — | 否（备用）| vLLM 已在 P-step_05 起；本机直连 NodePort 也可 tier-1 测试 |
| **ACR + 生产 K3s** | （扩展期）镜像化 + Helm Chart | 否 | 启动期 LoRA 通过 NAS PVC 挂载即可 |

**本步默认运行形态**：
- **tier-1**：本机训练 + 本机 / NodePort vLLM 推理（评测可接受）；
- **tier-2 / ★M2**：P-step_04 训练 Job + P-step_05 vllm infer（标准流水线，真实基建）。

**缺 GPU**：标 `BLOCKED(gpu_unavailable)`；dry-run + 5 节点单测通过视为 tier-1 准出；等 P-step_04 确认后执行 tier-2。

## §9 准出标准（同会话可执行清单 · 质量优于数量）

> **门槛口径**：分四档：① 数据量门槛（§5）→ ② **数据质量门槛（§3.5 矩阵 14 项）** → ③ 工程交付 → ④ 一键复现。**第 ② 档不绿即未准出**。

### §9.1 训练与文件门槛
- [ ] `ls -lh output/financial_fraud_lora_v1/adapter_model.safetensors` size > 60MB
- [ ] WandB run 状态 `finished`；`train/loss` 末 100 步均值 < 初始 30%；`eval/loss` 末 epoch ≤ 中间最低 ×1.1
- [ ] `output/eval_reports/financial_fraud_holdout_v1.json` 存在且 `passed=true`

### §9.2 数据质量门槛（§3.5 矩阵 14 项）
- [ ] **训练数据 3 项（Q1~Q3）**：precheck 全过
- [ ] **5 节点 5 项（N1~N5）**：单测全过 + 抽样 4 标的 ×4 期推理无 schema 错
- [ ] **Holdout 评测 6 项（H1~H6）**：30 案例全跑 + Recall ≥ 0.95 + Precision ≥ 0.70 + F1 ≥ 0.80 + 6 类各 ≥ 1 触发 + 抽样 5 条 evidence 可溯源

### §9.3 工程交付
- [ ] `pytest tests/cryo_guard/test_financial_fraud_engine.py -v` ≥ 8 passed
- [ ] `apps/cryo_guard/engines/financial_fraud/` 含 8 个 .py 文件（5 节点 + engine + schemas + __init__）
- [ ] LangGraph workflow 注册 5 节点 + START + END

### §9.4 一键复现
- [ ] **Makefile 合约**（§7.2）：10 个 target 全部已实现且通过；`make cryo-step04-all` 端到端 ≤ 3 hr（4090 单卡）
- [ ] **可重入验证**：连跑两次 `make cryo-step04-all`，第二次跳过训练直接评测（≤ 5 min 完成）
- [ ] L4 实践记录 `04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_04_财务测谎引擎LoRA.md` 已按 §8.4g 更新"二、实际进展"（含训练耗时、最终超参、Holdout 三指标、6 类触发分布、调参轮数）
- [ ] commit：`feat(cryo-guard): step_04 financial_fraud LoRA v1 + 5 节点引擎 + Holdout pass + Makefile [Ref: 03_/01_维度一/.../step_04]`
- [ ] **同会话验证**：上述命令在当次会话执行并输出摘要（按 `00_系统规则` §7.2 第 10/11 条）

## §10 [Deploy] 段

本步**不**产出镜像 / Chart / K8s workload；LoRA 文件落 `output/financial_fraud_lora_v1/` 并通过 step_01 已就绪的 vllm Pod 挂载 PVC 实现热加载。

> **vLLM 多 LoRA 热加载约定**：vllm-deployment.yaml 启动参数含 `--enable-lora --max-loras 4 --max-cpu-loras 4`；LoRA 文件通过 PVC 挂载到 `/loras/{financial_fraud,shareholder,related_party}/`；推理时 HTTP 调用指定 `lora_name`，无需重启 Pod。step_07 会将三引擎 LoRA 统一在 Chart 中编排。
> deploy-engine 自检：若需修改 vllm-deployment.yaml 启动参数，须在与 diting-infra 平级的独立 `deploy-engine/` 仓库内修改、push，再 `make update-deploy-engine`。**禁止**在 diting-infra 子模块拷贝内做写操作。

## §11 依赖与被依赖

**上游**：
- `step_01`：GPU 节点 Ready；vLLM Pod 启动并 `--enable-lora`；
- `step_02`：H001~H030 30 财务测谎 Holdout 锁库 + SHA256 校验通过；
- `step_03`：`financial_fraud_{train,val,test}.json` 6 份就绪 + Verified ≥ 1000；
- 用户提供：`WANDB_API_KEY`、GPU 节点。

**下游**：
- `step_07` 三引擎服务部署：消费 `financial_fraud_lora_v1` adapter；
- `step_09` 50 案例综合 Holdout 评测：消费 engine.run() 接口 + adapter；
- `step_08` decision_gate 聚合：消费 engine 输出的 Prediction 结构。

**严禁伪造**（no-mock-policy）：训练数据 / Holdout / Prediction 三处**不**允许 mock；vLLM 不可用须等待 step_01 修复。

## §12 风险与回退

| 触发条件 | 动作 |
|---|---|
| 显存 OOM（4090 24GB）| ① 先 batch=1 + grad_acc=16；② 仍 OOM 切 QLoRA（4bit）；③ 仍 OOM 降 rank=8。每次降级在 L4 实践记录 ADR 写明 |
| `train/loss` 不下降 / `eval/loss` 发散 | 检查数据：① 跑 `make cryo-step04-precheck` 复核 §3.5.1；② lr 减半重训；③ 数据质量问题 → 回 step_03 补蒸 |
| Holdout F1 不达 0.80 | **调参循环 ≤ 3 轮**：① epoch=5；② lr=3e-5；③ 加 normal 样本（让 step_03 补蒸 200 条）；④ lora_target 缩到 `q_proj,v_proj`。每轮 ADR；3 轮不达 → 启动期降级（Recall ≥ 0.85）+ ADR |
| 6 类特征某类 0 触发 | 回 step_02 §7.9 补对应类 Holdout 案例（保持 H001~H030 标识）+ 重新 `chmod -w`；重跑 Holdout |
| 同一问题修复重试 ≥ 2 次仍失败 | 按 `00_系统规则` §8.4f 回收：L4 "问题与风险" 说明 + ADR |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-25 | **P 轨基建对齐（回写）**：§8 将 `Dev K3s` 行拆为 `P轨 GPU 训练（P-step_04 diting-training chart）` + `P轨 GPU 推理（P-step_05 diting-vllm chart）` 双行，补 M2 链锁死说明与 BLOCKED 处理 |
| 2026-05-20 | **v2 按新 L3 启动期 step 模板（v1.2）重写**（关键重构，与 `00_系统规则` §4.5 同步）：①删除全部嵌入完整 YAML / Python 类 / Prompt 模板代码（原文 1089 行 → 现 ~310 行）；②新增 §3.5 数据质量验收矩阵 14 项（Q1~Q3 训练数据 + N1~N5 5 节点 + H1~H6 Holdout），按 step_07/09 反推训练 + 评测质量；③§7 改为"实施规划"三段式（§7.1 实现要点 11 项 + §7.2 Makefile 合约 10 个 target + §7.3 给后续执行模型指引）；④§5.1 训练超参表只保留设计决策不嵌 yaml；⑤§9 准出加 Makefile 合约落地 + 可重入验证；⑥§12 风险与回退含调参循环 3 轮上限 + OOM 三级降级；⑦明确 L3 责任边界："给规划与验证标准，不给完整代码" |
| 2026-05-16 | 初版（含完整训练 yaml / 5 节点 Python 类 / Prompt 模板 / Makefile），1089 行 |
