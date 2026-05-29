# Step 09 · 市场阶段分类器 MVP（Market Phase Classifier · 4 档资金博弈位置）

## §1 一句话定位与本步交付物

**一句话**：每只 active 持仓除了「逻辑健康度（D3 现有 4 态：INITIAL/GROWING/STABLE/EXIT）」之外，再加一根**正交轴**——**市场阶段**（4 档：`concept / expectation / realization / exhaustion`），表示「**资金现在在博弈哪段**」；启动期用**纯规则**实现（不训 LoRA，扩展期升级），输出 `market_phase` 字段加入 `health_change` 事件流，D4 SP 协议在 `market_phase=exhaustion` 时优先级提到 SP3 同档。**关键澄清**：本分类**不依赖** thesis 是否还成立，只判市场资金位置——thesis 仍 STABLE 但 market_phase 已 exhaustion 是**最重要的卖点**（系统目前漏掉）。

**交付物**（勾选 = 完成）：

- [ ] **A**（`MarketPhase` enum）：`concept | expectation | realization | exhaustion`（按用户 q2 决策，启动期合并 verification 进 realization）
- [ ] **B**（`MarketPhaseClassifier`）：纯规则版（启动期）；输入 = 价格信号 + 量能信号 + 公告状态 + 物理量探针（P5/P6/P7）+ 监控字典 alert 状态；输出 = 4 档 phase + 置信度 + 触发理由
- [ ] **C**（落库）：`market_phase_records`（INSERT-only history）+ `holdings.current_market_phase`（最新快照）
- [ ] **D**（与 health_change 集成）：D3 step_07 health_change 事件流增加 `market_phase` 字段（已与 step_07 协议联动）
- [ ] **E**（与 D4 联动）：D4 SP3 thesis_invalid 之外，**新增 SP6 market_phase_exhaustion 协议雏形**（同档优先级 p=1，buf=3d；正式落地放 D4 扩展期 step）
- [ ] **F**（API）：`POST /api/market-phase/classify/{symbol}` 返 phase + 置信度 + reasoning
- [ ] **G**（fact_gate 接入）：若分类依赖外部 LLM 生成的新闻情感（启动期不依赖；扩展期 LoRA 版需要） → 走共享规约 22 fact_gate
- [ ] **H**（4 档分布看板）：与 D0 副驾驶集成，显示 active 持仓在 4 档的分布柱状图

> **本步与现有 D3 4 态正交**——thesis 4 态描述「逻辑是否还成立」；market_phase 4 档描述「资金在博弈哪段」；二者可任意组合。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **上溯 L1**：[基石 ⑦·持仓监控哲学边界 §7.2 物理量探针读数](../../../../01_顶层概念/06_投资哲学体系总纲.md#基石-持仓监控哲学边界维度三持仓监控) + 新增 §六「市场资金位置与逻辑健康度正交」哲学（待 L1 升级）
> - **上溯 L2**：[02_战略维度/平台与产品/11_标的深度分析与阶段判定实践规划](../../../../../02_战略维度/平台与产品/11_标的深度分析与阶段判定实践规划.md) §四市场阶段 4 档判定
> - **同模块**：[step_06 健康度计算](./step_06_健康度计算与push_level.md) §3.5 / [step_07 health_change 事件流](./step_07_health_change事件流与10持仓测试.md) / [07_物理量探针_设计](../../../07_物理量探针_设计.md)
> - **同维度 D2 关联**：[D2 The Timer 三段窗口生产端 §3.7](../../../../02_维度二_纵深进攻/07_主动嗅探层_设计.md#37-the-timer-三段窗口生产端-thesis_card_generator_service-的-the_timer-引擎)（D2 The Timer 是「**预测**未来什么时候到什么期」；本 step 是「**判定**当前正处于哪一档」；二者互补）
> - **DNA**：[`_System_DNA/03_holding_watch/dna_d3_stage1_step09_market_phase_classifier.yaml`](../../../../_System_DNA/03_holding_watch/dna_d3_stage1_step09_market_phase_classifier.yaml)
> - **共享规约**：[22_事实交叉验证与防幻觉规约](../../../../_共享规约/22_事实交叉验证与防幻觉规约.md)
> - **L4**：`04_阶段规划与实践/03_维度三_持仓监控/stage_1_启动期/实践记录_step_09_市场阶段分类器MVP.md`（待创建）
> - **上游**：step_07（health_change 事件流 schema 升级）+ step_06（health 计算可选拼入）
> - **下游**：D4 SP6（待 D4 扩展期落地）+ D0 副驾驶（4 档分布看板）

## §3 数据采集对象 / 落库映射

| 输入 | 来源 | 用途 |
|---|---|---|
| **价格信号**：`pct_chg_1d/7d/30d/60d` | D3 P3 价格探针 step_03 | 涨幅判定 |
| **量能信号**：`volume_ratio_5d_vs_60d` | D3 P3 价格探针 | 主升/出货量能特征 |
| **公告状态**：`has_q_report_released / has_pre_announce_released / has_major_contract` | D3 P4 事件探针 step_03 + akshare 公告 | 进入 realization 的硬触发 |
| **物理量探针状态**（D2 P5/P6/P7 监控字典 alert） | D3 P5/P6/P7 step（[07_物理量探针_设计](../../../07_物理量探针_设计.md)） | concept→expectation 的物理证据 |
| **D2 thesis_cards.timer_signal.current_phase**（如已生成）| D2 step_05 | 与 D2 The Timer 三段窗口对比 |
| **新闻情感**（启动期：仅计数；扩展期：LoRA） | D3 P2 新闻探针 step_02 | exhaustion 的「媒体高潮期」识别 |

**落库**：

```sql
CREATE TABLE market_phase_records (
  symbol VARCHAR(10) NOT NULL,
  classified_at TIMESTAMPTZ NOT NULL,
  market_phase VARCHAR(20) NOT NULL,         -- 4 档 enum
  confidence NUMERIC(5,4) NOT NULL,          -- [0,1]
  reasoning_tags TEXT[] NOT NULL,            -- 触发理由 tag 数组
  rule_signals JSONB NOT NULL,               -- 完整输入信号快照
  classifier_version VARCHAR(20) NOT NULL,   -- 'rule_v1' / 'lora_v1'
  PRIMARY KEY (symbol, classified_at)
);

SELECT create_hypertable('market_phase_records', 'classified_at');

-- holdings 表新增列
ALTER TABLE holdings ADD COLUMN current_market_phase VARCHAR(20);
ALTER TABLE holdings ADD COLUMN current_market_phase_confidence NUMERIC(5,4);
ALTER TABLE holdings ADD COLUMN current_market_phase_updated_at TIMESTAMPTZ;
```

## §3.5 数据质量验收矩阵（启动期）

### §3.5.1 4 档判定规则（核心 · 启动期写死）

| # | market_phase | 触发条件（AND）| 业务含义 |
|---|---|---|---|
| MP1 | `concept` | `pct_chg_60d < 20%` AND `volume_ratio_5d < 1.5` AND `物理量探针 alert 全 inactive` AND `无公告利好` | 仅概念叙事，资金未实质进场 |
| MP2 | `expectation` | （`物理量探针至少 1 个 alert active` OR `pct_chg_30d > 30%`）AND `无公告兑现` AND `volume_ratio_5d > 1.5` | 资金博弈预期，等公告兑现 |
| MP3 | `realization` | `has_q_report_released = true` OR `has_pre_announce_released = true` OR `has_major_contract = true`（公告兑现窗口 -3 ~ +5 个交易日） | 公告已兑现，主升浪共振 |
| MP4 | `exhaustion` | （`pct_chg_60d > 80%` AND `volume_ratio_5d > 2.5` AND `pct_chg_5d < 0`）OR（`media_news_count_7d > 30` AND `pct_chg_3d < 0` 跌破 MA10）OR（`realization 后 10 交易日 无新利好` AND `pct_chg_5d < -5%`） | 量能放大但价格滞涨，或媒体高潮期，资金出货 |

### §3.5.2 优先级与互斥

| # | 规则 |
|---|---|
| P1 | 4 档**互斥**：同一时刻只能在一档 |
| P2 | **判定顺序**：exhaustion → realization → expectation → concept（优先识别危险信号） |
| P3 | **置信度**：所有触发条件齐全 → confidence=0.85；缺 1 个但其他强 → 0.65；强行降级判定 → 0.45 |
| P4 | **状态平滑**：同一标的同一交易日内 phase 切换 ≥ 2 次 → 标 `phase_unstable`，取多数票 |

### §3.5.3 跨维度契约

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| C1 | **health_change 事件加 phase 字段** | D3 step_07 publisher 升级，phase + confidence 加入 payload | ✅ 升级 step_07 schema | 缺则 D0 灰显 |
| C2 | **D4 SP6 触发预案**（启动期不落地，仅留接口）| 当 `market_phase=exhaustion AND confidence>=0.7` 推送 D4 sell_signal 候选（**仅候选不下单**） | ⚠️ 启动期只发事件，D4 SP6 正式协议放扩展期 | — |
| C3 | **与 D2 The Timer 对齐** | 若 `D2 thesis_cards.timer_signal` 含 `current_phase`，比对一致；不一致写 `phase_disagreement` 审计 | ✅ | — |
| C4 | **fact_gate 接入** | 若分类依赖 LLM 生成的「媒体情感」（启动期不依赖），需走 fact_gate | ⚠️ 启动期 nullable | 扩展期 LoRA 版必走 |

### §3.5.4 数据完整性

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| D1 | 必输入：D3 P3 价格探针就绪 | step_03 已部署 + 当日有数据 | ✅ | 缺 → 不分类 + tag insufficient_input |
| D2 | 必输入：D3 P4 事件探针就绪 | step_03 已部署 | ✅ | 缺 → 仅靠价格信号判 concept/expectation/exhaustion，不判 realization |
| D3 | 可选输入：物理量探针 P5/P6/P7 | 启动期可空，标 phys_probe_absent | ⚠️ | 空时 expectation 判定置信度上限 0.65 |
| D4 | 可选输入：D2 timer_signal | 启动期可空 | ⚠️ | 空时不做一致性比对 |

> 共 **4 + 4 + 4 + 4 = 16 项**。

## §4 凭证清单

| 凭证 | 用途 | 何时 |
|---|---|---|
| D3 step_03 价格探针 / P4 事件探针运行中 | 必输入 | 必须 |
| D3 step_07 publisher 可改 schema | 集成 health_change | 必须 |
| akshare 公告接口可用 | has_q_report_released 判定 | 必须 |
| （可选）D2 step_05 thesis_cards.timer_signal 已生成 | 一致性比对 | 启动期可缺 |
| （可选）D2 P5/P6/P7 监控字典 alert 状态 | 物理量证据 | 启动期可缺 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| active 持仓覆盖率 | 100% 当日有 market_phase_records 行 |
| 人工抽检一致率（20 只持仓 × 4 档抽样） | ≥ 80%（启动期纯规则，扩展期 LoRA 升 90%） |
| 4 档分布不畸形 | 任一档占比 ∈ [5%, 70%] |
| `make watch-step09-all` 通过 | exit 0 |
| health_change 事件 100% 含 market_phase 字段 | step_07 集成完成 |

## §6 下一步

本步 ✅ → **D3 step_10**（拟新增：4 档分布告警 + 与 D2 timer_signal 比对审计）。

**扩展期升级路径**（写进 stage_2）：
- 用本步规则版分类结果作为**标签源**，积累 ≥ 500 条 (symbol, date, market_phase, confidence_human=labeled) → 训练 LoRA 微调版
- 增加 verification 第 5 档（4 档→ 5 档），可用于早期识别「期望兑现过渡期」
- 接入 D4 SP6 正式协议（扩展期落地）

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A MarketPhase enum + Pydantic schema** | `apps/state_watch/market_phase/schemas.py` | 4 档枚举 + reasoning_tags 列表 | jsonschema |
| **B 规则版分类器** | `apps/state_watch/market_phase/rule_classifier_v1.py` | 表驱动 4 档规则（§3.5.1）+ 优先级判定顺序 | 单测 ≥ 8（4 档各 2 正例） |
| **C orchestrator** | `apps/state_watch/market_phase/orchestrator.py` | 编排：拉 P3+P4 当日数据 → 拉 akshare 公告 → 调 rule_classifier → 写库 + 写 holdings 最新快照 | e2e 1 只 |
| **D 写库 + history** | `data/models/market_phase_records.py` + 升级 `holdings` 表 | hypertable + ALTER | DDL ok |
| **E health_change 集成** | 改 D3 step_07 `events:monitor:health_change` payload 加 `market_phase` + `market_phase_confidence` 字段 | 与 D0 + D4 协调 schema | step_07 单测升级 |
| **F D2 timer_signal 比对** | `apps/state_watch/market_phase/cross_check_timer.py` | 若 D2 thesis 已含 timer_signal.current_phase → 比对一致；不一致写 `phase_disagreement_audit` | 单测 ≥ 2 |
| **G API** | `apps/state_watch/api/routes/market_phase.py` | POST classify / GET phase_history | 200 |
| **H 4 档分布看板** | D0 副驾驶 mini-chart 组件（拟联动） | 接 GET `/api/market-phase/distribution` | 联调 1 次 |
| **I 单测** | `tests/state_watch/test_market_phase_*.py` ≥ 15 | — | pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `watch-step09-prep` | step_03/step_07 ✅ + akshare 公告接口可达 |
| `watch-step09-classify-all` | 全 active 当日分类 |
| `watch-step09-distribution` | 4 档分布输出 |
| `watch-step09-cross-check-timer` | 与 D2 timer 一致性审计 |
| `watch-step09-quality-check` | 16 项矩阵 |
| `watch-step09-test` | pytest ≥ 15 |
| `watch-step09-all` | 端到端 |
| `watch-step09-status` | 覆盖率 / 4 档分布 / 不一致数 |
| `watch-step09-clean` | dev only |

### §7.3 给后续执行模型的指引

- **启动期不训 LoRA**：纯规则先跑出可解释结果，扩展期再用人工 label 训
- **判定顺序固定**：exhaustion 优先（防止漏掉危险）；不要并行评估再投票
- **物理量探针缺失不阻塞**：expectation 档置信度降到 0.65 仍能输出
- **不要伪造媒体情感**：启动期 nullable，标 `media_sentiment_absent`；扩展期 LoRA 版必走 fact_gate
- **配置驱动**：阈值（如 pct_chg_60d > 20% 阈值）进 yaml，不写代码
- **可重入幂等**：按 `(symbol, classified_at_date)` upsert；同日多次调用以最新覆盖

## §8 部署节奏

| 阶段 | 形态 | 是否本步必须 | 说明 |
|---|---|---|---|
| **tier-1 · 本机** | `uvicorn` port 8003 复用 + pytest | **必须** | rule_classifier + orchestrator 本机完成 |
| **P 轨 DB** | TimescaleDB NodePort 30001 同 D3 | 推荐 | `market_phase_records` hypertable |
| **P 轨 Redis（health_change 联动）** | 复用 D3 step_07 Redis Stream | 必须 | step_07 schema 升级后 |
| **扩展期** | LoRA 训练栈（复用 D3 step_05 NLI 训练栈）+ D4 SP6 正式协议落地 | 否 | |

## §9 准出标准

- [ ] §3.5 16 项全过
- [ ] active 持仓 100% 当日有 market_phase_records
- [ ] 抽检 20 只一致率 ≥ 80%
- [ ] 4 档分布不畸形（任一档 ∈ [5%, 70%]）
- [ ] `make watch-step09-all` exit 0
- [ ] D3 step_07 health_change schema 升级完成，含 market_phase 字段
- [ ] L4 实践记录含 4 档分布 + 抽检结果 + 与 D2 timer 不一致数 + commit + 同会话 pytest

## §10 [Deploy]

启动期 tier-1（本机 + 连 P 轨 DB + Redis）。扩展期合并到 state-watch Deployment。

## §11 依赖

D3 step_03（P3/P4 探针就绪）、D3 step_06（health 公式可选拼入 valuation_health_score）、D3 step_07（health_change publisher）、共享规约 22 fact_gate（扩展期 LoRA 版必走）、（可选）D2 step_05 timer_signal、（可选）D2 P5/P6/P7 监控字典。

**严禁**：启动期就训 LoRA（数据不够）；market_phase 直接触发自动下单（仅候选事件给 D4）；伪造媒体情感分数。

## §12 风险

| 触发 | 动作 |
|---|---|
| 4 档分布畸形（某档 < 5% 或 > 70%）| 重审规则阈值；可能阈值过严 / 过松 |
| phase 切换抖动（同日 ≥ 2 次） | 启用 P4 多数票平滑；记 ADR |
| 物理量探针长期空（启动期常见）| expectation 档置信度上限 0.65；扩展期 P5/P6/P7 完整后升 |
| 与 D2 timer_signal 不一致率 > 30% | 启动期记审计；可能 D2 The Timer prompt 或本规则需要调整；进 L4 复盘 |
| 同问题 ≥ 2 次（§8.4f） | 回收 / 退出 |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-27 | **初版 v1.0**（本轮关键重构 · §4.5 同步 .cursorrules）：从 Gemini 对话「炒概念/炒预期/炒业绩/利好出尽」5 档抽象出 market_phase 正交轴；按用户 q2 决策合并 verification 进 realization → 4 档；纯规则启动期 + LoRA 扩展期；与 D2 timer_signal / D3 step_06/step_07 / D4 SP6 全集成 |
