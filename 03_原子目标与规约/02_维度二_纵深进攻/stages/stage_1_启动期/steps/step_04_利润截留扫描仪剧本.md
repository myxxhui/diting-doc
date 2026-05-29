# Step 04 · 利润截留扫描仪剧本（LangGraph 4 节点 + 五信号加权）

## §1 一句话定位与本步交付物

**一句话**：实现 P0 剧本 `profit_capture_playbook`——LangGraph 四节点（加载指标 → 算 5 信号 → 加权得分 → 写 scan_log），对 active 标的输出 `playbook_score` + 5 信号明细，为 step_05 thesis 与 step_07 剧本路评分提供依据；**同时**（Lighthouse-Alpha 扩展）实现 **The Mapper 业绩弹性闸门 + 标的映射**——消费 step_03 The Critic 已通过 `physical_gate=true` 的嗅探候选簇，按"营收基数 → 业绩弹性阈值（4 档）"过滤稀释型大盘组装厂，输出**细分龙头标的清单**（带 elasticity_ratio 分数）进入 candidate_registry；**永久规则**：scan **不**触发建仓，Mapper 输出**仅**进推荐池供 D0 副驾驶展示。

**交付物**（勾选 = 完成）：
- [ ] **A**（5 Signal 计算器）：与 DNA 权重一致（0.30 / 0.25 / 0.25 / 0.10 / 0.10）；阈值来自 `configs/profit_capture_signals.yaml`（**禁止**代码硬编码）
- [ ] **B**（LangGraph 4 节点）：`load_indicators → compute_signals → aggregate_score → persist_scan_log`
- [ ] **C**（`scan_logs` 落库）：`symbol / scan_id / signals_json / score / decision_hint`（propose / watch / discard）
- [ ] **D**（API）：`POST /api/playbooks/profit_capture/scan` 单 symbol 可跑；P95 <3s（无 LLM）
- [ ] **E**（质量）：§3.5 矩阵；≥1 active 标的 5 信号中 ≥3 个 triggered
- [ ] **F**（Makefile + 单测）：`make deep-step04-all`；`pytest` ≥ 8 passed

> **本步是 D2 核心剧本**；无 scan_log 则 thesis 无「剧本命中」叙事。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2 哲学**：[04_实践策略规划](../../../../../02_战略维度/02_维度二_纵深进攻/04_实践策略规划.md)
> - **L3 策略**：[../01_实践目标与策略.md](../01_实践目标与策略.md) §2.2 PROFIT_CAPTURE_SIGNALS
> - **L3 技术**：[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) playbooks 模块
> - **DNA 键**：`_System_DNA/02_deep_strike/dna_stage_1_启动期.yaml` → `deliverables.playbooks[0]` + 5 signals
> - **L4 实践记录**：[实践记录_step_04_利润截留扫描仪剧本.md](../../../../../04_阶段规划与实践/02_维度二_纵深进攻/stage_1_启动期/实践记录_step_04_利润截留扫描仪剧本.md)
> - **上游**：← step_02、step_03
> - **下游**：→ step_05、step_07（playbook_score 路 0.5 权重）

## §3 数据采集对象 / 落库映射

| 流向 | 表/对象 |
|---|---|
| 读 | `financial_indicators`（5 信号字段）、`evidence_records`（可选附证引用）|
| 写 | `scan_logs` |
| **[L-α] 读** | `evidence_records WHERE type='physical_gate' AND physical_gate=true`（已过 The Critic 门禁的嗅探候选）+ `sniffer_clusters`（候选叙事原文）+ `financial_reports`（候选标的的营收基数）|
| **[L-α] 写** | `mapper_outputs(scan_id, cluster_id, target_symbol, elasticity_ratio, market_cap_segment, mapper_score, reasons_json, created_at)`；触发 `ThesisProposedEvent(source='sniffer')` 投递到 candidate_registry |

**本步不采外部数据。**

## §3.5 数据质量验收矩阵（剧本输出 · 仅启动期）

> 信号可复现 > 分数好看：须能用手算复核 `score = Σ(weight_i × triggered_i)`。

### §3.5.1 五信号计算质量（对齐 DNA PB1）

| # | DNA 信号 | 必产字段 / 逻辑 | 启动期 | 降级 |
|---|---|---|---|---|
| S1 | gross_margin_qoq_up (0.30) | `gross_margin_qoq > 0.02` → triggered | ⚠️ 依赖 step_02 S1 | 不可算则 weight 不计入分母 |
| S2 | cost_growth_below_revenue (0.25) | `cost_growth_yoy < revenue_growth_yoy - 0.05` | ⚠️ | 缺字段 weight=0 |
| S3 | operating_leverage (0.25) | `net_profit_growth > revenue_growth * 1.3` | ⚠️ | 同上 |
| S4 | receivable_turnover_up (0.10) | `receivable_turnover_qoq > 0` | ⚠️ | 同上 |
| S5 | inventory_turnover_up (0.10) | `inventory_turnover_qoq > 0` | ⚠️ | 同上 |

### §3.5.2 加权与决策档

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| D1 | **score 可复现** | `signals_json` 存 5 信号 `{triggered, score, raw_values, threshold}` | ✅ | 抽样 1 标的手算一致 |
| D2 | **decision_hint 三档** | score≥0.7 propose；0.4~0.7 watch；<0.4 discard（yaml 可调）| ✅ 对齐 DNA decision_mechanism | — |
| D3 | **scan_id 关联** | 与 step_03 evidence 同 scan_id 可对齐 | ✅ | — |
| D4 | **API 延迟** | 单 symbol P95 <3s | ⚠️ | 超时查 indicators 缺期 |

### §3.5.3 永久规则与 no-mock

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| R1 | **禁止 stub 信号** | 不得 `THESIS_GENERATOR_MODE=stub` 或随机 triggered | ✅ CI grep | — |
| R2 | **scan 不建仓** | API 响应无 buy/execute 字段 | ✅ | — |

### §3.5.4 [Lighthouse-Alpha] The Mapper 业绩弹性闸门 + 标的映射

| # | 维度 | 必产字段 / 逻辑 | 启动期 | 降级 |
|---|---|---|---|---|
| M1 | **input 严格过 The Critic** | Mapper 入口须 SQL `JOIN evidence_records ON physical_gate=true`；未过门禁的 cluster 不进 | ✅ 单测 | — |
| M2 | **营收基数 → 弹性阈值（4 档）** | small_cap (<50 亿) elasticity≥0.10；mid (<200 亿)≥0.05；large (<1000 亿)≥0.02；extra_large (≥1000 亿)≥0.01；阈值来自 `configs/elasticity_thresholds.yaml`（**禁止**代码硬编码）| ✅ 与 DNA `elasticity_gate.yaml::thresholds` 一致 | yaml 缺失 → ValidationError，不准出 |
| M3 | **elasticity_ratio 计算可复核** | `elasticity_ratio = expected_incremental_revenue / trailing_12m_revenue`；expected_incremental_revenue 取 The Critic 的 capacity_elasticity 估算 | ✅ 单测手算 3 档 | The Critic 无数 → 标 `pending_elasticity` 不入 mapper_outputs |
| M4 | **稀释型大盘排雷** | extra_large 段 elasticity_ratio<0.01 直接丢弃；reasons_json 含 `dropped_reason='base_dilution'` | ✅ | — |
| M5 | **细分龙头映射** | 每个 cluster 输出 ≥ 1 个 target_symbol；从 industry_peers + ClickHouse 嗅探历史中检索"该题材敞口 ≥ 30% 营收"的标的 | ⚠️ 启动期标的池小，可允许 1 cluster → 1 symbol（不强制龙头）| 无可映射 → 写 mapper_outputs.target_symbol=null + reasons_json='no_pure_play' |
| M6 | **触发 ThesisProposedEvent** | 每条 mapper_outputs.target_symbol 非空 → 投递 `events:deep_strike:thesis_proposed` Redis Stream，payload 含 `source='sniffer', cluster_id, elasticity_ratio` | ✅ | Redis 不可用 → 落本地队列 + retry，告警 |
| M7 | **永久规则·不建仓** | API/事件**无** buy/execute 字段；mapper_outputs **不**与 holdings 表 JOIN | ✅ | — |

> 共 **11 项原有 + 7 项 Lighthouse-Alpha = 18 项**。无 ❌。
> [Lighthouse-Alpha] 对齐 L2 P02 §十二「业绩弹性闸门阈值表」与 DNA `_System_DNA/02_deep_strike/elasticity_gate.yaml`（待 D03 设计文档新增）。

### §3.5.4 质量门槛（§9.2）

矩阵全 ✅/⚠️ 才可准出；行数够但信号全 false 仍**不准出**。

## §4 真实数据源与凭证清单

| 凭证 | 用途 |
|---|---|
| step_02/03 已准出 | 硬前置 |
| `MY_HOLDINGS_YAML` | 扫描范围 |

> **禁止** mock 指标入库后跑剧本。

## §5 启动期目标

| 项 | 值 |
|---|---|
| 剧本数 | 1 |
| 至少 1 标的 | score≥0.4（watch 以上）|
| 争取 1 标的 | score≥0.7（propose）|

## §6 下一步（一行触发条件）

- **触发**：本步 ✅ → step_05 thesis 卡片生成。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A signals.yaml** | `configs/profit_capture_signals.yaml` | 5 信号 condition 与 DNA 逐字对齐；权重和为 1.0 | yaml 单测 |
| **B SignalCalculator** | `playbooks/profit_capture/signals.py` | 纯规则；返回 5 个 SignalResult | 12 单测（每信号正负）|
| **C LangGraph** | `playbooks/profit_capture/graph.py` | State: symbol, indicators, signals, score, hint, scan_id | 1 symbol e2e |
| **D PlaybookRunner** | `playbooks/runner.py` | 注册 profit_capture | import OK |
| **E scan_logs ORM** | `db/models.py` | JSON signals_json；索引 symbol+created_at | migration |
| **F API** | `api/routes/playbooks.py` | POST `/api/playbooks/profit_capture/scan` | 200 + body |
| **G 质量脚本** | `validate_profit_capture_scan.py` | §3.5 18 项（含 §3.5.4 7 项 Lighthouse-Alpha）| 0 |
| **H 单测** | `test_profit_capture_playbook.py` + `test_the_mapper.py` | ≥8 持仓侧 + ≥6 Mapper（4 档弹性阈值、稀释排雷、ThesisProposedEvent 投递、no-buy 单测）| — |
| **[L-α] I elasticity_thresholds.yaml** | `configs/elasticity_thresholds.yaml` | 4 档阈值 + 营收段定义；与 DNA `elasticity_gate.yaml` 1:1 | yaml 单测 |
| **[L-α] J The Mapper 核心** | `playbooks/the_mapper/mapper.py` | 5 节点：`load_critic_passed_clusters → fetch_revenue_base → compute_elasticity → segment_filter → emit_thesis_proposed`；纯规则；LLM 不参与（成本控制）| 单测 4 档边界 + 3 候选完整流 |
| **[L-α] K mapper_outputs ORM** | `db/models.py` | 字段见 §3；索引 `(scan_id, target_symbol)` | migration |
| **[L-α] L 投递 ThesisProposedEvent** | `events/publisher.py` | Redis Stream `events:deep_strike:thesis_proposed`；payload schema 与 candidate_registry consumer 对齐 | XADD 单测 + consumer roundtrip |

### §7.2 Makefile 合约

| target | 用途 | 验证 |
|---|---|---|
| `deep-step04-prep` | step_03 quality 0 | 0 |
| `deep-step04-scan-all` | 全 active | scan_logs +N |
| `deep-step04-quality-check` | §3.5 | 0 |
| `deep-step04-test` | pytest | ≥8 |
| `deep-step04-all` | 端到端 | 0 |
| `deep-step04-status` | 每 symbol 最近 score | 只读 |
| **[L-α]** `deep-step04-mapper-run` | 对当日 The Critic 已通过的 cluster 跑 Mapper；输出 mapper_outputs 行数 + ThesisProposedEvent 投递数 | 行数 ≥ 1（若当日有 critic-pass cluster）|
| **[L-α]** `deep-step04-mapper-status` | 近 7 日 mapper_outputs 分布（市值段 × elasticity 分位）| 只读 |

**合约**：只改 yaml 调阈值；增标的只改 SoT；**[L-α]** 调整 4 档弹性阈值只改 `configs/elasticity_thresholds.yaml`。

### §7.3 指引

顺序 A→H；**禁止** LLM 参与本步；信号不可算须显式 `computable=false`。

## §8 部署节奏

**本机** API 8082；无 K3s 本步必须。

## §9 准出标准

### §9.1
- [ ] ≥1 标的 scan_log 可展示 5 信号 JSON + 手算 score 一致

### §9.2
- [ ] §3.5 11 项；`validate_profit_capture_scan.py` 0

### §9.3
- [ ] `make deep-step04-all`；L4 + commit；同会话验证

## §10 [Deploy]

无。

## §11 依赖

**上游** step_02/03（含 The Critic physical_gate 输出）；**[L-α]** elasticity_thresholds.yaml 配置文件；Redis Stream `events:deep_strike:thesis_proposed` topic 可用（共享规约对齐）。
**下游** step_05（thesis 卡片消费 playbook_score 和 mapper_outputs）/ step_07（The Scorer 消费两类候选评分）；**[L-α]** D0 推荐池（订阅 ThesisProposedEvent 显示主动嗅探标签页）。
**严禁**伪造 triggered；**[L-α]** 严禁 Mapper 输出在未经 The Critic 验证的 cluster 上跑；严禁 mapper_outputs 直接 JOIN holdings 表（永久 no-buy 规则）。

## §12 风险

| 触发 | 动作 |
|---|---|
| 5 信号全 false | 回 step_02 补指标期数 |
| score 手算不一致 | 修权重归一化逻辑 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v2.2 Lighthouse-Alpha 融合**：merge_inplace 融入 The Mapper 业绩弹性闸门 + 标的映射——§1 一句话扩；§3 输入/输出加 mapper_outputs；§3.5 新增 §3.5.4 矩阵 7 项（M1~M7，4 档营收基数→弹性阈值）；§7.1 追加 I~L 四实现要点（yaml 配置 / Mapper 核心 / ORM / ThesisProposedEvent 投递）；§7.2 Makefile 加 2 个 mapper target；§11 上下游同步 |
| 2026-05-20 | **v2.1 深度补全**：§3.5 扩 11 项对齐 DNA 五信号；§7~§13 完整；1039→~310 行 |
| 2026-05-20 | v2 瘦身 |
| 2026-05-16 | 初版 1039 行 |
