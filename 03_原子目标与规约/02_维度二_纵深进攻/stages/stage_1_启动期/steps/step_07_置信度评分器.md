# Step 07 · 置信度评分器（剧本 + LoRA + 历史相似度三路融合 · [L-α] + 嗅探候选三维打分通道）

## §1 一句话定位与本步交付物

**一句话**：实现统一 `ConfidenceScorer`——支持**两种输入模式**：①**持仓侧 thesis 评分**（综合 **剧本得分**[step_04，权重 0.5] + **LoRA 自评**[thesis_lora_v1，0.3] + **历史相似度**[vs 已 confirm 的 thesis，0.2] → `final_confidence`）；②**[L-α] 嗅探候选三维打分（The Scorer · 严格对齐 Lighthouse-Alpha PRD §2.3）**：**政策级别**[`policy_tier`，权重 0.35] + **产业空间**[`industry_space`，0.35] + **A 股映射度**[`a_share_mapping`，0.30] → `sniffer_confidence`（0~10 综合分），由 **Claude Opus 4.7** 大模型按 prompt 模板打分，与共享规约 19 异构 AI 调度对齐；与 L2 §8A.4 严格对齐；两种模式统一输出 propose/watch/discard 三档；写入 `confidence_logs` 审计；在 `ThesisCardGenerator` 中替换单一 `result.confidence`。

**交付物**（勾选 = 完成）：
- [ ] **A**（持仓侧三路融合）：`ConfidenceWeights` 默认 0.5/0.3/0.2；阈值 0.7/0.4 来自 `configs/decision_gate.yaml`（与 DNA `decision_mechanism` 一致）
- [ ] **B**（`confidence_logs` 表）：playbook/lora/similarity/final/decision/reasons JSON；**[L-α]** 同表加 `mode` 字段（`thesis_holding` / `sniffer_candidate`）+ `sniffer_policy_tier` / `sniffer_industry_space` / `sniffer_a_share_mapping` 三列（0~10 整数；与 PRD §2.3 严格对齐）
- [ ] **C**（集成生成器）：`ThesisCardGenerator.generate` 起始调用 Scorer + 写 log
- [ ] **D**（API）：`GET /api/thesis/{thesis_id}/confidence` 返三路明细；**[L-α]** `GET /api/sniffer/{cluster_id}/score` 返 PRD 对齐三维分（政策级别/产业空间/A股映射度 + 综合分 + source 引用）
- [ ] **E**（永久规则）：即使 final=0.99 也只能 propose，**禁止** auto confirm
- [ ] **F**（单测 + Makefile）：`pytest` ≥10（持仓侧）+ ≥6（嗅探侧 The Scorer）；`make deep-step07-all`
- [ ] **[L-α] G**（SnifferScoreProvider 第四 Provider）：`engines/confidence/sniffer_provider.py`；按 cluster_id 取 sniffer_raw_text + 政策原文摘录 + 产业空间研报估算 + A 股映射候选标的 → 大模型按 PRD §2.3 三维 prompt 打分 → 返回 `SnifferScoreResult{policy_tier, industry_space, a_share_mapping, composite, source_urls}`；缺 source 引用 → 该维度自动降一档
- [ ] **[L-α] H**（sniffer_weights.yaml）：`configs/sniffer_weights.yaml` 含 `policy_tier=0.35` / `industry_space=0.35` / `a_share_mapping=0.30` + 三档阈值（≥8.0 propose/置信上限 0.85；7.0~7.9 watch/上限 0.70；<7.0 当日不入推荐池）；与 L2 §8A.4 一致；与 DNA `theme_sniffer.yaml::scorer.three_dim` 一致
- [ ] **[L-α] I**（成本控制）：依赖共享规约 19 异构 AI 调度——`industry_space` 数值估算可走本地小模型（Qwen-14B）；`policy_tier` + `a_share_mapping` 走远程大模型（**Claude Opus 4.7**）；单 cluster 总成本 ≤ ¥**0.75**；超额自动降级仅算 `policy_tier`（最关键维度）并标 partial

> **永久规则**：置信度**不**等于建仓许可；建仓仅 step_08。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2/L3**：[../01_实践目标与策略.md](../01_实践目标与策略.md) §3.1、[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §3.2
> - **DNA**：`decision_mechanism` + `quantitative_goals` 一致率 ≥80%（为 step_08 铺垫）
> - **L4**：[实践记录_step_07_置信度评分器.md](../../../../../04_阶段规划与实践/02_维度二_纵深进攻/stage_1_启动期/实践记录_step_07_置信度评分器.md)
> - **上游**：← step_04（playbook_score）、step_05（卡片）、step_06（LoRA）
> - **下游**：→ step_08（一致率）、step_09/10

## §3 数据采集对象 / 落库映射

**本步不采外部数据**——消费 scan_logs + thesis_cards + vLLM LoRA 自评 + human_confirmations（历史 confirmed）。

| 流向 | 落库 |
|---|---|
| 三路分数 + final | `confidence_logs` |
| 写回卡片（可选）| `thesis_cards.confidence` 字段或 JSON 子树 |

## §3.5 数据质量验收矩阵（置信度输出 · 仅启动期）

### §3.5.1 三路分数质量

| # | 路 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| P1 | **playbook_score** | 来自 step_04 `scan_logs.score`；0~1 | ✅ | 无 scan 则该路=0+标 missing |
| P2 | **lora_score** | vLLM `thesis_lora_v1` 自评 JSON `confidence` 0~1 | ⚠️ step_06 后 | LoRA 未加载→base+标 `lora_loaded=false` |
| P3 | **similarity_score** | vs `human_confirmations`+confirmed thesis；token-overlap 或 bge 余弦 0~1 | ⚠️ 启动期 confirmed≥1 才有意义 | 无 confirmed→该路=0.5 中性+标 `no_history` |
| P4 | **加权可复现** | `final = Σ w_i * s_i`（权重和=1）| ✅ | 单测手算一致 |

### §3.5.2 决策档与永久规则

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| D1 | **三档阈值** | ≥0.7 propose；0.4~0.7 watch；<0.4 discard | ✅ yaml | 调参仅改 yaml |
| D2 | **永久规则** | API/代码**无**路径因高 confidence 直接 confirmed | ✅ `assert_no_auto_confirm` 单测 | — |
| D3 | **reasons 可审计** | `confidence_logs.reasons` 含三路原始分+权重 | ✅ | — |

### §3.5.3 工程

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **与 step_08 一致率铺垫** | AI decision 与 classify 同口径 | ✅ | step_08 算一致率 |
| E2 | **延迟** | 单 thesis 评分 P95 <8s（含 LoRA）| ⚠️ | 超时标 partial |

### §3.5.4 [Lighthouse-Alpha] The Scorer 嗅探候选三维打分

| # | 维度 | 必产字段 / 逻辑 | 启动期 | 降级 |
|---|---|---|---|---|
| TS1 | **PRD 三维分齐（严格命名对齐）** | `policy_tier` / `industry_space` / `a_share_mapping` 三列非空（0~10 整数）；命名严格对齐 Lighthouse-Alpha PRD §2.3 + L2 §8A.4 | ✅ | 单维失败 → 标 partial + sniffer_confidence 降权 |
| TS2 | **加权可复现（PRD 对齐）** | `sniffer_confidence = 0.35·policy_tier + 0.35·industry_space + 0.30·a_share_mapping`（0~10 综合分）；权重来自 sniffer_weights.yaml | ✅ 单测手算 | yaml 缺失 ValidationError |
| TS3 | **大模型 prompt 模板 + source 留痕** | confidence_logs.reasons_json 含 `prompt_template_id` + `model_name` + `tokens_used` + 每维 `source_urls[]`；缺 source 该维度自动降一档 | ✅ | — |
| TS4 | **三档阈值（与 L2 §8A.4 严格对齐）** | sniffer_confidence ≥ **8.0** propose（置信上限 0.85）；7.0~7.9 watch（置信上限 0.70）；< **7.0** 当日不入推荐池（仅入次日复评队列）| ✅ | — |
| TS5 | **永久规则：propose 不等于建仓** | 即使 sniffer_confidence=9.5 也仅进推荐池；**禁止**任何 buy/execute/qmt/auto_trade 字段；与 §9.4 永久 no-auto-execute 规则一致 | ✅ assert_no_auto_confirm 单测覆盖嗅探侧 | — |
| TS6 | **异构 AI 调度对齐** | `industry_space` 数值估算走本地小模型（Qwen-14B，成本省 90%）；`policy_tier` + `a_share_mapping` 走远程大模型（**Claude Opus 4.7**）；总成本 ≤ ¥**0.75**/cluster | ✅ 与共享规约 19 对齐 | 超成本 → 降级仅算 `policy_tier` + 标 partial |
| TS7 | **mode 字段双轨可区分** | 同表 `confidence_logs.mode` 取 `thesis_holding` 或 `sniffer_candidate`；可分别统计准确率与成本；嗅探侧准确率回流飞轮（→ D5 §8A.3 P06）| ✅ | — |

> 共 **9 项原有 + 7 项 Lighthouse-Alpha = 16 项**。
> [Lighthouse-Alpha] 对齐 L1 哲学基石⑥ + DNA `theme_sniffer.yaml::scorer.three_dim` + 共享规约 19 异构 AI 调度。

## §4 凭证

| 凭证 | 用途 |
|---|---|
| step_06 adapter 或 vLLM 可达 | LoRA 路 |
| ≥1 条 confirmed thesis（step_08 后可补种子）| 相似度路；启动期可先人工种子 1 条 |

> **禁止** Stub LLM 伪造 lora_score 生产路径（tests/ 除外）。

## §5 启动期目标

| 项 | 值 |
|---|---|
| 权重 | 0.5/0.3/0.2（可 yaml）|
| 阈值 | 0.7/0.4 |
| 每卡有 log | 100% generate 路径 |

## §6 下一步

本步 ✅ → step_08 人工门禁 + 一致率 ≥80%。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A ConfidenceLog ORM** | `db/models.py` | 字段见 §1·B；索引 thesis_id | migration |
| **B weights yaml** | `configs/confidence_weights.yaml` | playbook/lora/similarity + thresholds | 解析 |
| **C PlaybookScoreProvider** | `engines/confidence/playbook_provider.py` | 读最近 scan_logs | 单测 |
| **D LoRAConfidenceProvider** | `lora_provider.py` | httpx vLLM；prompt 自评 JSON | mock |
| **E SimilarityProvider** | `similarity_provider.py` | 启动期 token-overlap；扩展期 embedding | 单测 |
| **F ConfidenceScorer** | `confidence_scorer.py` | `score()` + `classify()` | 手算一致 |
| **G 集成 ThesisGenerator** | `thesis_generator.py` | generate 首行调 scorer | e2e 1 卡 |
| **H API GET confidence** | `api/routes/thesis.py` | 三路明细 | 200 |
| **I 单测** | `test_confidence_scorer.py` | ≥10 | — |
| **[L-α] J SnifferScoreProvider** | `engines/confidence/sniffer_provider.py` | 第四 Provider；按 cluster_id 取 sniffer_raw_text + 政策原文摘录 + 产业空间研报估算 + A 股映射候选 → 走共享规约 19 异构 AI 调度（小模型先算 `industry_space` 数值；`policy_tier` + `a_share_mapping` 走大模型；prompt 模板严格对齐 PRD §2.3 三维定义）| 单测 mock 5 cluster → 三维评分一致性 + 命名对齐 PRD |
| **[L-α] K sniffer_weights.yaml** | `configs/sniffer_weights.yaml` | PRD 对齐三维权重（`policy_tier=0.35` / `industry_space=0.35` / `a_share_mapping=0.30`）+ 三档阈值（≥8/7~7.9/<7）+ 大小模型选择；与 DNA `theme_sniffer.yaml::scorer.three_dim` 严格一致 | yaml schema 单测 + 与 L2 §8A.4 字段名对账 |
| **[L-α] L sniffer Scorer 集成入口** | `engines/confidence/scorer.py` | 增 `score_sniffer(cluster_id) -> SnifferScoreResult`；mode 字段路由两种打分逻辑 | 单测两种 mode 流程 |
| **[L-α] M sniffer API** | `api/routes/sniffer.py` | `GET /api/sniffer/{cluster_id}/score` 返 PRD 三维明细（含 source_urls / model_name / tokens / 综合分 / 三档判定）| 200 + body schema 严格对齐 PRD |
| **[L-α] N test_the_scorer** | `tests/deep_strike/test_the_scorer.py` | ≥6：①PRD 三维命名与权重对齐 ②加权综合分手算一致 ③propose 不等建仓（assert_no_auto_confirm）④成本上限 ⑤异构调度 ⑥mode 区分；额外：缺 source 自动降档 | pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `deep-step07-prep` | step_06 adapter + vLLM models 含 thesis_lora |
| `deep-step07-score-all` | 对已生成 thesis 批量评分 |
| `deep-step07-test` | pytest ≥10 |
| `deep-step07-all` | 端到端 |
| `deep-step07-status` | 最近 10 条 log 三路分布 |

### §7.3 指引

先 ORM+yaml→三路 Provider→Scorer→集成；LoRA 不可用须显式 degraded 不准假装满分。

## §8 部署节奏

本机 + 调 D1 `vllm-svc:8000`（LoRA 路）。

## §9 准出标准

- [ ] §3.5 9 项；每卡有 confidence_logs；手算 final 一致
- [ ] `make deep-step07-all`；L4 + commit

## §10 [Deploy]

LoRA 挂载 D1 vllm；无新 Pod。

## §11 依赖

step_04/05/06；**[L-α]** step_03 The Critic（physical_gate 过滤后才进 Scorer）+ step_04 The Mapper（mapper_outputs 提供 target_symbol 上下文）+ 共享规约 19 异构 AI 调度（成本控制）+ DNA `theme_sniffer.yaml::scorer`。
**严禁**伪造 lora_score；**[L-α]** 严禁 sniffer_confidence 高分直接触发建仓；严禁绕过异构 AI 调度直接走最贵大模型。

## §12 风险

| 触发 | 动作 |
|---|---|
| LoRA 超时 | 降权或仅 playbook 路 |
| 无 confirmed | similarity 中性+ADR |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v2.1 Lighthouse-Alpha 融合**：merge_inplace 融入 The Scorer 嗅探候选三维打分通道（与现有持仓三路融合并存）——§1 一句话改为双模式统一评分器；交付物 +G/H/I（SnifferScoreProvider + sniffer_weights.yaml + 成本控制）；§3.5 新增 §3.5.4 矩阵 7 项（TS1~TS7）；§7.1 追加 J~N 五实现要点；§11 上下游加 The Critic/The Mapper 与共享规约 19；对齐 DNA `theme_sniffer.yaml::scorer.three_dim` |
| 2026-05-21 | **v2.2 PRD 命名严格对齐修正**：v2.1 中 The Scorer 三维使用了 diting 内部命名（叙事/数据/产业链），与 Lighthouse-Alpha PRD §2.3 + L2 §8A.4 严格命名（**政策级别 0.35 + 产业空间 0.35 + A 股映射度 0.30**）不一致；本次全文替换为 PRD 命名（含 §1 一句话 / 交付物 B/D/G/H/I / §3.5.4 TS1~TS7 / §7.1 J/K/M/N）；阈值由 0.7/0.4 三档（0~1 域）改为 8.0/7.0 三档（0~10 域），与 L2 §8A.4 严格一致；异构调度从"data 走小模型"改为"`industry_space` 数值估算走小模型；`policy_tier` + `a_share_mapping` 走大模型"（后者更需要大模型政治/产业判断力）|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 883 行嵌入 Python；§3.5 9 项三路融合；永久规则；Makefile；883→~300 行 |
| 2026-05-16 | 初版 883 行 |
