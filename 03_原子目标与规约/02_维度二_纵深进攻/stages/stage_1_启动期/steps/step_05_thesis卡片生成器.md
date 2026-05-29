# Step 05 · thesis 卡片生成器（5 必填元素 · Pydantic 强校验）

## §1 一句话定位与本步交付物

**一句话**：在剧本命中（step_04）+ 证据链（step_03）基础上，生成结构化 **thesis 卡片**（5 必填：观点摘要 / 证据链 / 风险 / 估值锚点 / 操作建议），强校验后落 `thesis_cards`（**仅** `status=proposed`），供 step_06 LoRA 训练与 step_07 置信度评分消费；**[L-α]** 同时生成 **The Timer 三段时间窗口预测**（潜伏 / 主升浪 / 撤退），由大模型按 A 股交易规则（中报预告期 7 月上旬 / 中报披露期 8 月 / 三季报预告期 10 月上旬 / 年报披露期 4 月）排布该 thesis 的潜伏与出货节点，输出 `timer_signal` 字段嵌入 thesis 卡，供 D4 SP3 进场建议与 D4 step_05 SP5 财报披露窗口协议消费。

**交付物**（勾选 = 完成）：
- [ ] **A**（`ThesisCard` schema）：Pydantic v2；`thesis_summary` ≥50 字；`evidence_chain` ≥3；`risks` ≥1；`valuation_anchor` 含 method+target_price；`action` ∈ {buy,add,watch}；**[L-α]** `timer_signal` 嵌入字段（schema 见 §3.5.4）
- [ ] **B**（生成器）：`ThesisCardGenerator`——**规则模板**（内容来自真实 scan+evidence，**非 stub**）+ 可选 D5 Teacher HTTP 润色
- [ ] **C**（完整性）：`thesis_completeness.batch_check` 100% 通过
- [ ] **D**（API）：`POST /api/thesis/generate` 返 `thesis_id` + 完整卡片（含 `timer_signal`）
- [ ] **E**（D0 schema 对齐）：`scripts/schema_check_d0.py` 与 [13_集成与时序](../../../../_共享规约/13_六维度启动期集成与时序.md) 字段级一致
- [ ] **F**（Makefile）：`make deep-step05-all`；**禁止** `THESIS_GENERATOR_MODE=stub` 生产路径
- [ ] **[L-α] G**（The Timer 生产端）：`engines/thesis/the_timer.py`——按 A 股交易规则 + 监控字典 alert_threshold + scan 命中信号，调大模型（**Claude Opus 4.7**）按 prompt 模板生成"潜伏窗口 / 主升浪窗口 / 撤退窗口"三段；prompt 严格按 PRD §3.4 阶段四规则约束（含中报预告期 / 中报披露期 / 三季报预告期 / 年报披露期）
- [ ] **[L-α] H**（`timer_signal` 落库）：`thesis_cards.timer_signal` 列（JSONB）+ `timer_signals` 历史归档表；写入前 `jsonschema.validate`；缺失三段任一 → 拒绝写入并告警 The Timer prompt 异常
- [ ] **[L-α] I**（与 D4 SP5 严格对齐）：`timer_signal.cycle_anchors[]` 含 `cycle_type ∈ {pre_announce_h1, h1_release, pre_announce_q3, annual_release}` + `expected_window` + `confidence`；D4 step_05 SP5 消费此字段触发"披露窗口前 ±N 天"协议
- [ ] **[L-β] J**（**bottleneck_node 字段**）：thesis 卡新增 `bottleneck_node` 子结构，标注当前 thesis 描绘的「卡脖子节点」位于产业链哪一档（上游材料 / 中游集成 / 下游应用 / 平台型 / 独立运营 5 档），含 `node_type / node_name / industry_chain_position / verified_by_fact_gate(bool)`；走 [共享规约 22 fact_gate](../../../../_共享规约/22_事实交叉验证与防幻觉规约.md) 验证
- [ ] **[L-β] K**（**business_elasticity_score 字段**）：thesis 卡新增 `business_elasticity_score ∈ [0, 100]`；与 [08_业绩弹性闸门](../../../08_业绩弹性闸门_设计.md) 输出对齐（≥+5pp → 60 分 / +10pp → 80 / ≥+20pp → 95）
- [ ] **[L-β] L**（**technology_curve_stage 字段**）：thesis 卡新增 `technology_curve_stage ∈ {zero_to_one, one_to_ten, ten_to_hundred, saturated, declining}` 5 档 S 曲线位置；大模型判 + fact_gate 验
- [ ] **[L-β] M**（**valuation_dynamics 字段**）：thesis 卡新增 `valuation_dynamics` 子结构（含 `current_pe / forward_pe / peg / pe_percentile_180d / industry_median_pe / davis_phase` 等），由 [step_11 估值动态评估器](./step_11_估值动态评估器.md) 写入
- [ ] **[L-β] N**（**break_signals[] 必填**）：thesis 卡新增 `break_signals[]`（≥1 条必填）—— 每条 = `{signal_type, threshold_struct, monitor_field_ref, action_hint}`；含「逻辑何时算被证伪」的硬触发，**与 D3 narrative_invalid + D4 SP3 联动**
- [ ] **[L-β] O**（**反向补全 8 只持仓 SOP**）：本步 schema 升级后，对现有 8 只持仓的旧版 thesis 卡执行**反向补全**：① 列出旧 thesis 卡 ID 清单；② LLM 起草 4 新字段 + break_signals[]；③ 用户人工审核确认；④ 走 fact_gate 验证；⑤ 升级版 thesis 卡 status=proposed 等 HumanGate 再次确认（详见 §3.5.6 SOP）

> **永久规则**：`confirmed` **唯一**入口 step_08 HumanGate。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2/L3**：[../01_实践目标与策略.md](../01_实践目标与策略.md)、[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md)
> - **DNA**：`thesis_card_required_elements` 5 项 + `decision_mechanism` + `permanent_rule`
> - **L4**：[实践记录_step_05_thesis卡片生成器.md](../../../../../04_阶段规划与实践/02_维度二_纵深进攻/stage_1_启动期/实践记录_step_05_thesis卡片生成器.md)
> - **上游**：step_03、04；软依赖 D5 Teacher
> - **下游**：step_06、07、08、09

## §3 数据采集对象 / 落库映射

| 输入 | 输出 |
|---|---|
| `scan_logs` + `evidence_records` | `thesis_cards`（status=proposed）|
| playbook score/hint | action 初值与 summary 语气 |
| **[L-α] 监控字典** `monitor:{symbol}:dict:*` （来自 D2 step_02 §3.5.5 The Architect）| **[L-α]** `thesis_cards.timer_signal` JSONB（三段窗口 + cycle_anchors）|
| **[L-α] A 股交易日历**（中报预告/披露 / 三季报预告 / 年报披露）| **[L-α]** `timer_signals` 历史归档表（每次 thesis 生成快照）|

## §3.5 数据质量验收矩阵（thesis 卡片 · 仅启动期）

### §3.5.1 DNA 五必填

| # | DNA 元素 | 必产标准 | 启动期 | 降级 |
|---|---|---|---|---|
| T1 | thesis_summary | ≥50 字；含 symbol+剧本名+核心逻辑 | ✅ 规则模板 | <50 拒绝 |
| T2 | evidence_chain | ≥3；每条 type+content+url(若有) | ⚠️ 来自 step_03 | <3 不准出该卡 |
| T3 | risks | ≥1；每条 ≥20 字 | ✅ 模板+行业通用 | 禁止空数组 |
| T4 | valuation_anchor | method 枚举 + target_price | ⚠️ PE/PEG 简化 | watch_only 可 null+标注 |
| T5 | action | buy/add/watch | ✅ 与 decision_hint 映射 | — |

### §3.5.2 跨维契约

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| C1 | D0 schema 对齐 | 11 必填+2 可选 field diff=0 | ⚠️ schema_check | 漂移则修 pydantic |
| C2 | pass_event_id | 来自 D1 pass 时填真实 audit_id | ⚠️ step_09 补全 | 暂无 null+备注 |
| C3 | 周产出 ≤5 | DNA quantitative_goals | ✅ 启动期可更少 | — |

### §3.5.3 no-mock

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| N1 | **禁止 stub 写库** | `THESIS_GENERATOR_MODE=stub` 不得进入业务路径 | ✅ CI grep + runtime guard | 违规不准出 |
| N2 | 内容来自真数据 | summary/evidence 可追溯到 scan/evidence 表 | ✅ | — |

### §3.5.4 [Lighthouse-Alpha] The Timer 三段时间窗口预测（生产端 · 严格对齐 PRD §3.4）

**承接 PRD §3.4 阶段四（The Timer）**：大模型必须结合 A 股交易规则，**为每个 thesis 卡排布"潜伏 / 主升浪 / 撤退"三段时间节点**——监控字典 alert_threshold 触发后到财报披露之前的窗口期是"潜伏建仓"；中报/三季报披露当天到披露后 3 个交易日是"主升浪共振"；披露后放量滞涨或跌破 10 日均线是"撤退"。

**`timer_signal` schema**：

```yaml
ThesisCard.timer_signal:
  generated_by:
    model_name: str               # claude-opus-4-7
    prompt_template_id: str       # the_timer_v1
    generated_at: datetime
    tokens_used: int
  current_date: date
  three_phases:
    incubation:                   # 潜伏窗口（监控字典预警触发 → 财报披露前 N 天）
      start_date: date
      end_date: date
      trigger_source: str         # 引用 monitor_matrix.field_id
      action_hint: "watch | gradual_build"
    main_surge:                   # 主升浪窗口（财报披露当天 +0~3 交易日 / 或重大合同公告当天）
      start_date: date
      end_date: date
      trigger_event: str          # "h1_release" / "q3_pre_announce" / "major_contract"
      action_hint: "hold | add"
    retreat:                      # 撤退窗口（披露后放量滞涨 / 媒体全面高潮期 / 跌破 10 日均线）
      start_date: date
      end_date: date
      trigger_condition: str      # "high_volume_no_rise | break_ma10 | media_peak"
      action_hint: "begin_exit"
  cycle_anchors:                  # A 股财报节奏锚点（与 D4 SP5 严格对齐）
    - cycle_type: pre_announce_h1 | h1_release | pre_announce_q3 | q3_release | annual_pre_announce | annual_release
      expected_window: [start_date, end_date]
      confidence: float           # 0~1
      basis: str                  # 文字说明（如"7 月上旬中报预告期"）
  permanent_rule_acknowledged: true   # 永久规则：timer_signal 仅是建议，不触发自动交易
```

| # | 维度 | 必产标准 | 启动期 | 降级 |
|---|---|---|---|---|
| TM1 | **三段必须齐全** | incubation / main_surge / retreat 三段非空 | ✅ jsonschema | 缺一拒绝写入 + 告警 The Timer prompt 异常 |
| TM2 | **窗口顺序合理** | incubation.end ≤ main_surge.start ≤ main_surge.end ≤ retreat.start | ✅ runtime guard | 违反 → 拒绝写入 |
| TM3 | **cycle_anchors 至少 1 个** | 必须显式锚定到 A 股一个财报披露事件（中报预告 / 中报 / 三季报预告 / 三季报 / 年报）| ✅ | 0 个 → 标 `no_earnings_anchor`，置信度上限 0.55 |
| TM4 | **与监控字典对齐** | incubation.trigger_source 必须引用 monitor_matrix.field_id | ✅ | 缺失 → 标 partial（仍允许写入但 D4 SP3 不据此进场）|
| TM5 | **与 D4 SP5 严格对齐** | cycle_anchors[].cycle_type ∈ D4 SP5 协议 6 种 cycle_type 枚举 | ✅ | 枚举外值拒绝写入 |
| TM6 | **永久 no-auto-execute** | permanent_rule_acknowledged 必须为 true；**禁止**任何 buy/qmt/auto_trade 字段嵌入 timer_signal | ✅ assert_no_auto_confirm | 违反 → 启动拒绝（防穿透）|
| TM7 | **prompt 留痕** | confidence_logs 或 timer_signals 表存 prompt_template_id + model_name + tokens_used + raw_response | ✅ | 用于飞轮回流（→ D5 §8A.3 P06 The Timer 训练）|

> The Timer **生产端归属本 step（D2 step_05）**——thesis 卡生成时即调大模型算出三段窗口，作为 thesis 卡的不可分割组成部分；**消费端**在 D4 step_05 SP5（财报披露窗口协议）+ D3 持仓监控；与 PRD §3.4 阶段四"周期推演"严格对齐。

> 共 **10 项原有 + 7 项 The Timer = 17 项**。

### §3.5.5 [Lighthouse-β] 4 新字段 + break_signals[] 验收矩阵（启动期）

**承接本轮关键重构** · 从 Gemini 对话审计「概念→预期→业绩→出尽」与「戴维斯双击」与「卡脖子节点」抽象出 thesis 卡 schema 升级 —— **4 新字段 + break_signals[] 是后续 D3 market_phase 分类、D2 estimation_gap、D4 SP6 协议的共同 schema 锚点**。

**新 schema 子结构**（追加进 ThesisCardSchema）：

```yaml
ThesisCard:  # 已有 5 必填 + timer_signal 之外
  bottleneck_node:
    node_type: enum  # 上游材料 / 中游集成 / 下游应用 / 平台型 / 独立运营
    node_name: str   # 如 "1.6T 光收发模块" / "液冷板冷板" / "高压超充快充模块"
    industry_chain_position: enum  # upstream / midstream / downstream / platform / standalone
    verified_by_fact_gate: bool    # 必走 fact_gate.verify
    fact_claim_id: str             # fact_gate 返回的 claim_id
  business_elasticity_score: int  # [0, 100]，与 08_业绩弹性闸门对齐
  technology_curve_stage: enum     # zero_to_one / one_to_ten / ten_to_hundred / saturated / declining
  valuation_dynamics:              # 由 step_11 估值动态评估器写入
    current_pe: float | null
    forward_pe: float | null
    peg: float | null
    pe_percentile_180d: float | null
    industry_median_pe: float | null
    davis_phase: enum              # davis_double_click / single_click_eps / double_kill / neutral
    evaluated_at: datetime
  break_signals:                   # ≥1 条必填
    - signal_type: enum            # narrative_contradiction / physical_data_break / financial_break / regulation_break / valuation_overload
      threshold_struct:            # 结构化阈值（与 monitor_dict alert_threshold_struct 一致）
        operator: enum             # gt / lt / change_pct_gt / consecutive_n
        value: float
        window_days: int
      monitor_field_ref: str       # 引用 monitor_matrix.field_id（如 'monitor:002837:dict:contract_liability_pct'）
      action_hint: enum            # raise_warning / propose_exit / propose_reduce
```

| # | 维度 | 必产标准 | 启动期 | 降级 |
|---|---|---|---|---|
| LB1 | **bottleneck_node 必填** | 5 字段齐 + verified_by_fact_gate=true | ✅ 走 fact_gate.verify | 未验证 → 写库但 status=proposed_unverified |
| LB2 | **business_elasticity_score 必填** | 与 08_业绩弹性闸门 输出一致；range [0,100] | ✅ 引 08_ Mapper 输出 | <60 给 warning（业绩弹性不足） |
| LB3 | **technology_curve_stage 必填** | 5 档枚举 + 大模型判 + fact_gate 验 | ✅ Opus 4.7 + fact_gate | LLM 输出非枚举 → 拒绝写 |
| LB4 | **valuation_dynamics 字段必填** | 等 step_11 落地后 100% 填；step_11 落地前可空 + tag step_11_pending | ⚠️ 启动期可空 | step_11 完成后必填 |
| LB5 | **break_signals[] ≥ 1 条** | 每条 4 子字段齐；monitor_field_ref 必须能解析到现有 monitor_dict 字段 | ✅ runtime guard | 0 条 → 拒绝写 |
| LB6 | **break_signals signal_type 5 档枚举** | enum 严格校验 | ✅ pydantic | 非枚举拒绝 |
| LB7 | **break_signals 与 D3 narrative_invalid 联动** | 至少 1 条 `signal_type=narrative_contradiction` 的 break_signal 引用 D3 narrative_nli 输出字段 | ✅ | 缺 → warning 不阻塞 |
| LB8 | **break_signals 与 D4 SP3 联动** | action_hint=propose_exit 的 break_signal 触发 → D4 SP3 候选事件 | ✅ 与 step_07 publisher 协议 | — |
| LB9 | **fact_gate 接入** | bottleneck_node + technology_curve_stage 写库前必走 fact_gate；valuation_dynamics 中 P/E 数据点写入前必走 | ✅ | dlq_rejected 拒绝写 |
| LB10 | **反向补全 8 只持仓** | §3.5.6 SOP 走完；旧 thesis 卡 100% 升级到含 4 新字段 + break_signals[] | ⚠️ 等用户提供 8 只清单 | — |

> 共 **原有 17 + Lighthouse-β 10 = 27 项**。

### §3.5.6 反向补全 8 只持仓 thesis 卡 SOP（按用户 q3 决策 = backfill）

**适用场景**：本步 schema 升级后，现有持仓的旧 thesis 卡需要补充 4 新字段 + break_signals[]，否则 D3 step_09 market_phase 分类、D2 step_11 估值动态评估、D4 SP6 协议无法对老持仓生效。

**SOP 步骤**：

| # | 步骤 | 执行者 | 输出 |
|---|---|---|---|
| 1 | **导出旧 thesis 卡清单** | AI（执行 `make deep-step05-list-active-thesis-cards`） | `holdings_thesis_backfill_queue.csv`（symbol, thesis_id, missing_fields[]）|
| 2 | **LLM 起草 4 新字段** | AI（Opus 4.7，每只标的 1 prompt 4 字段全 fill） | `holdings_thesis_backfill_draft.json`（每只一份）|
| 3 | **LLM 起草 break_signals[]（≥3 条建议）** | AI（按业务逻辑生成 narrative/physical/financial 三类）| 同上 json 拼入 break_signals |
| 4 | **fact_gate 验证** | AI（每条新字段走 fact_gate.verify）| `holdings_thesis_backfill_fact_gate_report.md` |
| 5 | **用户审核确认** | 人工（按 fact_gate 报告 + LLM 草稿，人工逐字段确认 / 修改） | `holdings_thesis_backfill_confirmed.json` |
| 6 | **写库** | AI（按 confirmed.json 更新 thesis_cards 表） | thesis 卡 status=proposed（**升级版需重新走 HumanGate 一致率检验**） |
| 7 | **HumanGate 二次确认** | 人工（[step_08 HumanGate](./step_08_人工确认门禁与一致率.md) 流程） | status=confirmed |
| 8 | **L4 记录** | AI | `实践记录_step_05_反向补全8只持仓.md` |

**触发命令**：`make deep-step05-backfill-holdings HOLDINGS_FILE=data/config/my_holdings.yaml`

**输入要求**（**等用户下一轮提供**）：
- 8 只持仓的 `symbol` 清单（用户已在 `my_holdings.yaml` 配置）
- 用户对 thesis 卡 4 新字段的领域知识补充（可选）

## §4 凭证清单

| 凭证 | 用途 | 何时 |
|---|---|---|
| D5 `POST /api/distill/*` 或 `ANTHROPIC_API_KEY` | 可选润色 | 无则纯规则 |
| step_03/04 已齐 | 硬前置 | 本步前 |

> **禁止** stub/mock 写 `thesis_cards`。

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 卡片数 | ≥ active 数 |
| 5 必填完整率 | 100% |
| 周产出 | ≤5（DNA）|

## §6 下一步

本步 ✅ → step_06（≥100 thesis + ≥100 risk 训练样本）。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A ThesisCardSchema** | `engines/thesis/schemas.py` | 5 必填 + D0 扩展字段 | pydantic |
| **B 规则生成器** | `thesis_generator.py` | 读 scan+evidence 拼模板；**非随机文本** | 1 卡完整 |
| **C Teacher 润色（可选）** | `thesis_llm_polish.py` | HTTP D5；失败降级规则 | 不阻塞 |
| **D completeness** | `thesis_completeness.py` | batch 100% | 0 失败 |
| **E runtime guard** | `config.py` | `THESIS_GENERATOR_MODE=stub` → 启动拒绝 | 单测 |
| **F API** | `api/routes/thesis.py` | POST generate | 200 |
| **G schema_check_d0** | `scripts/schema_check_d0.py` | vs D0 ThesisProposedPayload | diff=0 |
| **H 单测** | `test_thesis_generator.py` | ≥8 | — |
| **[L-α] I The Timer 核心** | `engines/thesis/the_timer.py` | 4 节点：`load_thesis_context → fetch_monitor_dict_alerts → call_llm_three_phases → emit_timer_signal`；prompt 严格对齐 PRD §3.4；走共享规约 19 异构 AI 调度（大模型路径，因涉及 A 股交易日历 + 财报节奏的综合判断）| 单测 ≥5：三段非空 / 顺序合理 / cycle_anchors 锚定 / 与 D4 SP5 枚举对齐 / no-auto-execute 强校验 |
| **[L-α] J `timer_signals` 表** | `data/models/timer_signals.py` | thesis_card_id + generated_by + three_phases + cycle_anchors + raw_llm_response（飞轮回流）| 单测 schema |
| **[L-α] K timer prompt 模板** | `prompts/the_timer_v1.txt` | 含 A 股财报披露日历枚举 + PRD §3.4 三段示例（液冷 5-6 月招标 → 7-8 月中报披露主升浪）| diff vs PRD §3.4 |
| **[L-α] L test_the_timer** | `tests/deep_strike/test_the_timer.py` | ≥7：TM1~TM7 矩阵全覆盖 + no-auto-execute assert | pytest |
| **[L-β] M ThesisCardSchema 升级** | `engines/thesis/schemas.py` | 追加 `bottleneck_node / business_elasticity_score / technology_curve_stage / valuation_dynamics / break_signals[]` 5 子结构（含 enum 枚举） | pydantic + jsonschema |
| **[L-β] N break_signals 校验器** | `engines/thesis/break_signal_validator.py` | 校验 ≥1 条 + signal_type 枚举 + monitor_field_ref 可解析 | 单测 ≥ 5 |
| **[L-β] O fact_gate 集成** | `engines/thesis/thesis_generator.py` 升级 | 写库前对 `bottleneck_node + technology_curve_stage + valuation_dynamics P/E 数据点` 调 `fact_gate.verify`；dlq_rejected 拒写 | 单测 ≥ 3 |
| **[L-β] P 反向补全脚本** | `scripts/backfill_thesis_4fields.py` | 输入 `my_holdings.yaml` → 调 Opus 起草 → fact_gate 验证 → 输出 confirmed.json | e2e 1 只 + 单测 ≥ 4 |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `deep-step05-generate-all` | 每 active ≥1 卡 |
| `deep-step05-completeness` | 100% |
| `deep-step05-schema-d0` | 0 |
| `deep-step05-test` | pytest |
| `deep-step05-all` | 端到端 |
| **[L-α]** `deep-step05-timer-generate` | 对最近 N 个 thesis 卡生成 timer_signal | 每 thesis ≥1 timer 完整三段 |
| **[L-α]** `deep-step05-timer-quality-check` | TM1~TM7 矩阵 | 退出码 0 |
| **[L-α]** `deep-step05-timer-test` | pytest 7+ | pass |
| **[L-β]** `deep-step05-schema-upgrade-validate` | 4 新字段 + break_signals[] schema 通过 jsonschema | exit 0 |
| **[L-β]** `deep-step05-list-active-thesis-cards` | 列出现有持仓 thesis 卡缺字段清单 | csv 输出 |
| **[L-β]** `deep-step05-backfill-holdings` | 反向补全 8 持仓 SOP 端到端跑（含 LLM 起草 + fact_gate） | confirmed.json 输出 |
| **[L-β]** `deep-step05-break-signals-test` | break_signals 校验器 pytest | exit 0 |
| **[L-β]** `deep-step05-fact-gate-integration-test` | 注入 R1~R4 反模式 → 4 新字段写库被拒绝 | pytest pass |

### §7.3 指引

启动期**允许规则模板**（非 stub——须可追溯 scan/evidence）；step_06 后 LoRA 提升文风。

## §8 部署节奏（P 轨 · 真实基建对齐）

| 阶段 | 形态 | 是否本步必须 | 说明 |
|---|---|---|---|
| **tier-1 · 本机** | `uvicorn` port 8082 + `pytest` | **必须** | ThesisCardGenerator / The Timer 逻辑 + 单测在本机完成 |
| **P轨 DB 中间件（tier-1 可用）** | P-step_03 `diting-stack` 已 Up；`thesis_cards` 写入 TimescaleDB NodePort 30001 | 推荐 | `PG_DSN` 指向 `8.217.179.252:30001`（prod.conn）；P-step_03 ✅ W4 已验；本步不需要额外起 stack |
| **P轨 Redis（★M6+ 事件流）** | 同 `diting-stack`；Redis NodePort 30379 / `redis-svc.platform:6379` | M6 消费端需要 | `timer_signal` 写 Redis Stream 供 D0/D4 消费；tier-1 本地 Redis 也可 |

**tier-1 准出**：本机 + 本地 DB（SQLite 可）或连 prod.conn；卡片完整率 100% + schema 0 diff。
**tier-2 / ★M6**：thesis / timer_signal 必须写入 `diting-stack` TimescaleDB（连 prod.conn）+ Redis Stream，才能被 D0/D4 真流消费。

**扩展期**：上线 deep-strike Deployment；定时触发 Timer；接入 D0 日报推送。

## §9 准出标准

- [ ] 完整率 100% + schema_check 0 + `make deep-step05-all`
- [ ] L4 + commit；同会话验证

## §10 [Deploy]

无。

## §11 依赖

step_03/04；D5 可选。**严禁** stub 写库。**[L-α]**：The Timer 依赖共享规约 19（异构 AI 调度）+ D2 step_02 §3.5.5 The Architect 监控字典已就绪 + A 股财报披露日历配置；**下游消费**：D4 step_05 SP5 财报披露窗口协议消费 `timer_signal.cycle_anchors[]`；D3 持仓监控按 `timer_signal.three_phases.incubation/main_surge/retreat` 调整探针告警敏感度。

## §12 风险

| 触发 | 动作 |
|---|---|
| evidence<3 | 回 step_03 |
| schema 漂移 | 对齐 D0 |
| stub 穿透 | 修 guard |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-25 | **P 轨基建对齐（回写）**：§8 由单行改为 tier-1/P轨DB/P轨Redis 三行表，补 prod.conn 指向（`8.217.179.252:30001`）+ M6 事件流条件 + 扩展期说明 |
| 2026-05-20 | **v2.1 深度补全**：§3.5 10 项；D0 契约；no-mock 专节；§7~§13 完整；1033→~320 行 |
| 2026-05-20 | v2 瘦身 |
| 2026-05-16 | 初版 1033 行 |
| 2026-05-21 | **v3.0 Lighthouse-Alpha 融合 · The Timer 生产端归属**：补 PRD §3.4 阶段四（The Timer 财报披露窗口预测器）缺失的生产端归属——§1 一句话扩；交付物 +G/H/I（The Timer 引擎 + `timer_signal` 落库 + 与 D4 SP5 严格对齐）；§3 输入加监控字典 / A 股交易日历，输出加 `thesis_cards.timer_signal` JSONB + `timer_signals` 历史表；§3.5 新增 §3.5.4 矩阵 7 项（TM1~TM7 三段必齐 / 窗口顺序 / cycle_anchors 锚定 / 与监控字典对齐 / 与 D4 SP5 枚举对齐 / 永久 no-auto-execute / prompt 留痕）；§7.1 追加 I~L 四实现要点（The Timer 核心 4 节点 / timer_signals 表 / prompt 模板 / 单测）；§7.2 Makefile 加 3 个 timer target；§11 下游标注 D4 SP5 + D3 持仓监控消费 |
| 2026-05-27 | **v3.1 Lighthouse-β · thesis 卡 schema 升级 + 反向补全 8 持仓**（本轮关键重构 §4.5）：从 Gemini 对话审计抽象 thesis 卡 4 新字段 + break_signals[] —— 交付物 +J/K/L/M/N/O（bottleneck_node / business_elasticity_score / technology_curve_stage / valuation_dynamics / break_signals[]≥1 / 反向补全 SOP）；§3.5 新增 §3.5.5 矩阵 10 项 LB1~LB10（schema 字段必填 + fact_gate 集成 + 与 D3 narrative_invalid + D4 SP3 联动）+ §3.5.6 反向补全 8 持仓 SOP 8 步表；§7.1 追加 M~P 四实现要点（schema 升级 / break_signals 校验器 / fact_gate 集成 / 反向补全脚本）；§7.2 Makefile 加 5 个 schema 升级 / backfill target；下游联动 D2 step_11 估值动态 + D3 step_09 market_phase 分类器 + D4 SP6 候选事件 |
