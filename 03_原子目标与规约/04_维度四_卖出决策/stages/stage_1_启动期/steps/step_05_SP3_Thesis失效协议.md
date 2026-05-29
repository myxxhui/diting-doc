# Step 05 · SP3 Thesis 失效协议 + [L-α] SP5 财报披露窗口协议（订阅 D3 `events:monitor:health_change` + D2 `TimerSignalEvent`）

## §1 一句话定位与本步交付物

**一句话**：实现 **SP3 ThesisInvalid**——订阅 D3 `events:monitor:health_change`，当 `thesis_status="invalid"`（即 `new_state=exit` 或 `narrative_label=contradiction AND narrative_invalid_count≥3`）→ 触发 SP3，`priority=1`、`buffer_days=0`；advice "thesis 失效建议清仓"；与 SP1 同优先级时按 ConflictResolver 全部记审计，事件输出含 `evidence_ref=health_change.event_id`；**同时**（Lighthouse-Alpha 扩展）实现 **SP5 财报披露窗口协议**——订阅 D2 step_04/09 的 `events:deep_strike:timer_signal`，按"A 股财报节奏与战场窗口对齐"三段信号（左侧潜伏 / 主升浪 / 撤退期）输出 advice："潜伏期建议轻仓持有等待业绩 / 主升浪建议持有 / 撤退期建议减仓"；**永久规则**：SP5 与 SP3 同样**仅产 advice，绝不自动清仓**；SP5 与 SP1 冲突时 SP1（止损）优先。

**交付物**（勾选 = 完成）：
- [ ] **A**（`HealthChangeConsumer`）：consumer group `dim_four`；`XREADGROUP` 拉取
- [ ] **B**（`ThesisInvalidProtocol`）：基于 consumer 拉取的 event payload；评估 thesis_status
- [ ] **C**（注册）：ProtocolRegistry SP3
- [ ] **D**（`event_logs`）：消费审计（msg_id 幂等）
- [ ] **E**（API）：`POST /api/protocols/SP3/evaluate` 手动评估（启动期联调用）；`GET /api/consumer/health_change/status`
- [ ] **F**（单测）：≥10；含两触发路径（exit / contradiction+invalid_count）+ 非触发路径
- [ ] **G**（Makefile）：`make exit-step05-all`
- [ ] **[L-α] H**（`TimerSignalConsumer`）：consumer group `dim_four_sp5`；订阅 D2 `events:deep_strike:timer_signal`；payload 含 `{symbol, stage: 'left_accumulate'|'main_wave'|'retreat', evidence_url, financial_report_date}`
- [ ] **[L-α] I**（`Sp5FinancialWindowProtocol`）：评估当前 stage → advice；`priority=3`（低于 SP1 止损，高于 SP4 再平衡）；`buffer_days=0`
- [ ] **[L-α] J**（注册）：ProtocolRegistry SP5
- [ ] **[L-α] K**（永久规则单测）：`test_sp5_no_auto_execute.py` 显式断言 SellSignalEvent 无 buy/execute 字段；advice 含完整 evidence_url
- [ ] **[L-α] L**（D0 告警 UI）：`GET /api/protocols/SP5/recent` 返最近 7 天 SP5 advice 供 D0 副驾驶 alerts.html 渲染（三段文案不同 emoji 但**禁止**任何触发自动动作的按钮）
- [ ] **[L-α] M**（冲突优先级单测）：SP1 ∩ SP5 同标的 → SP1 advice 主显示，SP5 advice 折叠次显示；都记审计

> **永久规则**：SP3 触发只产 advice；**不**自动清仓；evidence 链可回溯到 health_change event_id。
> **[L-α] 永久规则**：SP5 触发只产 advice；**不**自动清仓**也不自动加仓**；evidence 链可回溯到 TimerSignalEvent.event_id + 财报披露日期 url。
> **SP1/SP3/SP5 冲突永久优先级**：SP1（止损）> SP3（thesis 失效）> SP5（财报窗口）；同标的多触发时三 advice 全部 record，UI 按优先级排序。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../01_实践目标与策略.md](../01_实践目标与策略.md) SP3、[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md)
> - **DNA**：`deliverables.sell_protocols[2]`（SP3，priority=1）+ `depends_on: events:monitor:health_change`
> - **D3**：[step_07_health_change事件流](../../../03_维度三_持仓监控/stages/stage_1_启动期/steps/step_07_health_change事件流与10持仓测试.md)
> - **共享**：[13_六维度启动期集成与时序](../../../../_共享规约/13_六维度启动期集成与时序.md) §四
> - **L4**：[实践记录_step_05_SP3_Thesis失效协议.md](../../../../../04_阶段规划与实践/04_维度四_卖出决策/stage_1_启动期/实践记录_step_05_SP3_Thesis失效协议.md)
> - **上游**：D3 step_07；本维 step_01~02；**下游**：step_07 冲突

## §3 数据采集对象 / 落库映射

| 流向 | 表/流 |
|---|---|
| 消费 health_change | `event_logs(stream_key, msg_id, payload, handled)` |
| 触发 SP3 | `sell_signals`（含 `evidence_ref=health_change.event_id`）|
| 评估审计 | `protocol_logs` |
| **[L-α] 消费 timer_signal** | `event_logs(stream_key='events:deep_strike:timer_signal', msg_id, payload, handled)` |
| **[L-α] 触发 SP5** | `sell_signals`（含 `protocol='SP5'`、`stage='left_accumulate'\|'main_wave'\|'retreat'`、`evidence_ref=timer_signal.event_id`、`financial_report_date`）|

## §3.5 数据质量验收矩阵（SP3 · 仅启动期）

### §3.5.1 消费契约

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| C1 | **stream 名** | `events:monitor:health_change` | ✅ 常量 | — |
| C2 | **consumer group** | `dim_four` | ✅ | — |
| C3 | **msg_id 幂等** | UniqueConstraint(stream_key,msg_id) | ✅ | — |
| C4 | **payload schema 对齐** | D3 step_07 14 字段全解码 | ⚠️ schema_check | 漂移修后再 e2e |
| C5 | **handled & error** | 处理结果落库 | ✅ | — |

### §3.5.2 触发逻辑

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| L1 | **path A** | `new_state=exit` → 触发 | ✅ | — |
| L2 | **path B** | `narrative_label=contradiction AND narrative_invalid_count≥3`（从 payload）→ 触发 | ✅ | payload 缺 invalid_count→不触发+ADR |
| L3 | **不触发路径** | warning↔stable 不触发 SP3 | ✅ 单测 | — |
| L4 | **buffer_days=0** | 立即触发 | ✅ | — |
| L5 | **evidence_ref** | sell_signals 写 health_change.event_id | ✅ | — |

### §3.5.3 工程与 no-mock

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **真 Redis 联调** | D3 真 stream 或 `BLOCKED` 文档 | ⚠️ D3 step_07 ✅ 后 | tests fixture TEST_ONLY |
| E2 | **延迟** | 消费→sell_signals 写入 P95<10s | ⚠️ | 超时告警 |
| E3 | **生产路径无 mock 事件** | inject_mock 仅 tests/ | ✅ | — |
| E4 | **审计完整** | event_logs + protocol_logs 双写 | ✅ | — |

### §3.5.4 [Lighthouse-Alpha] SP5 财报披露窗口协议

| # | 维度 | 必产字段 / 逻辑 | 启动期 | 降级 |
|---|---|---|---|---|
| SP5-1 | **stream 名** | `events:deep_strike:timer_signal` | ✅ 常量 | — |
| SP5-2 | **consumer group** | `dim_four_sp5`（独立于 SP3 的 `dim_four` group）| ✅ | — |
| SP5-3 | **三段 stage 全覆盖** | `left_accumulate` / `main_wave` / `retreat` 三类信号各 ≥ 1 单测 | ✅ | — |
| SP5-4 | **每段 advice 文案** | left_accumulate: "潜伏期建议轻仓持有等待业绩"；main_wave: "主升浪建议持有"；retreat: "撤退期建议减仓" | ✅ yaml 可配 | — |
| SP5-5 | **priority=3** | ProtocolRegistry SP5 优先级介于 SP3(1)、SP4(4) 之间 | ✅ | — |
| SP5-6 | **永久 no-auto-execute** | SellSignalEvent 无 buy/execute/order_id 字段；advice 字段含完整 evidence_url | ✅ assert_no_auto_execute 单测覆盖 SP5 | — |
| SP5-7 | **financial_report_date 留痕** | sell_signals.financial_report_date 与 TimerSignalEvent.financial_report_date 一致 | ✅ | — |
| SP5-8 | **evidence_ref 可追溯** | `evidence_ref=timer_signal.event_id` + url 至少 1 个可点击（财报披露公告 url）| ✅ | — |
| SP5-9 | **冲突优先级** | SP1 ∩ SP5 → 单测 SP1 advice 主显示；SP3 ∩ SP5 → SP3 主显示；都记审计 | ✅ ConflictResolver 单测 | — |
| SP5-10 | **D0 alerts API** | `GET /api/protocols/SP5/recent?days=7` 返最近 7 天 SP5 advice 列表；D0 alerts.html 三段 emoji（🌱潜伏 / 🚀主升浪 / 🍂撤退）| ✅ | — |

> 共 **14 项原有 + 10 项 Lighthouse-Alpha = 24 项**。
> [Lighthouse-Alpha] 对齐 L2 P03 「A 股财报节奏与战场窗口对齐矩阵」+ DNA `_System_DNA/02_deep_strike/theme_sniffer.yaml::timer` 与 `_System_DNA/04_exit_engine` 新增 SP5 节。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| `REDIS_URL` | 消费 D3 stream |
| D3 step_07 真流可用 | 主路径 |
| `MY_HOLDINGS_YAML` 已 positions | symbol 匹配过滤（仅持仓内触发）|

> D3 未就绪：`exit-step05-all` 走 BLOCKED；tests TEST_ONLY 注入；**禁止**伪造业务库信号。

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 消费率（D3 真流上有事件时）| handled=true ≥99% |
| 触发延迟 P95 | <10s |
| 单测 | ≥10 |

## §6 下一步

本步 ✅ → step_06 SP4 再平衡协议。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A EventLog ORM** | `db/models.py` | 同 D2 schema | migration |
| **B HealthChangeConsumer** | `events/consumer.py` | asyncio + XREADGROUP | 1 真 event |
| **C ThesisInvalidProtocol** | `protocols/thesis_invalid.py` | 评估 payload | 单测两路径 |
| **D 仅持仓过滤** | consumer 内 | symbol ∈ positions.active | 单测 |
| **E SellSignal 写入 evidence_ref** | service 层 | 写 event_id | curl 验 |
| **F status API** | `api/routes/consumer.py` | 最近 N 事件 | 200 |
| **G TEST_ONLY fixture** | `tests/fixtures/inject_health_change.py` | 仅 pytest | — |
| **H 单测** | `test_sp3_thesis_invalid.py` + consumer | ≥10 | pytest |
| **[L-α] I TimerSignalConsumer** | `events/timer_consumer.py` | asyncio + XREADGROUP；consumer group `dim_four_sp5`；msg_id 幂等 | 1 真 timer_signal event 流通 |
| **[L-α] J Sp5FinancialWindowProtocol** | `protocols/sp5_financial_window.py` | 评估 stage → 选 advice 文案；写 sell_signals 含 protocol='SP5' + stage + evidence | 单测三段 stage |
| **[L-α] K sp5_advice_templates.yaml** | `configs/sp5_advice_templates.yaml` | 三段 advice 文案 + emoji + 优先级 | yaml 单测 |
| **[L-α] L SP5 注册** | `protocols/registry.py` | ProtocolRegistry add SP5 priority=3 | import OK |
| **[L-α] M SP5 API** | `api/routes/protocols.py` | `POST /api/protocols/SP5/evaluate`（手动）+ `GET /api/protocols/SP5/recent?days=7` | 200 + body |
| **[L-α] N 永久规则单测** | `tests/exit_engine/test_sp5_no_auto_execute.py` | assert SellSignalEvent 无 buy/execute/order_id 字段；advice 含 evidence_url；任何 priority 都不触发 trade 接口 | ≥4 passed |
| **[L-α] O 冲突优先级单测** | `tests/exit_engine/test_sp_conflict_priority.py` | SP1∩SP5 / SP3∩SP5 / SP1∩SP3∩SP5 三场景；assert UI 排序与 ConflictResolver record 完整 | ≥3 passed |
| **[L-α] P TEST_ONLY fixture** | `tests/fixtures/inject_timer_signal.py` | 三段 stage 各 1 个 event | 仅 pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `exit-step05-prep` | Redis + D3 stream 存在或 BLOCKED |
| `exit-step05-consumer-up` | start +5s 后看消费 |
| `exit-step05-e2e-real` | 真 event 或 BLOCKED；triggered≥0 |
| `exit-step05-schema` | payload schema 解码 OK |
| `exit-step05-test` | pytest ≥10 |
| `exit-step05-all` | 非 BLOCKED 时全绿 |
| `exit-step05-status` | event_logs handled 计数 + 最近 SP3 信号 |
| `exit-step05-clean` | dev FORCE=1 |
| **[L-α]** `exit-step05-sp5-consumer-up` | 启动 TimerSignalConsumer | +5s 后看消费 |
| **[L-α]** `exit-step05-sp5-e2e-real` | 真 D2 timer_signal event 或 BLOCKED；triggered 三段统计 | 非 BLOCKED 全绿 |
| **[L-α]** `exit-step05-sp5-test` | pytest test_sp5_* | ≥7 passed |
| **[L-α]** `exit-step05-sp5-no-auto-audit` | 审计：grep "auto_execute\\|order_id" SP5 代码 → 必须 0 命中 | exit 0 |
| **[L-α]** `exit-step05-sp5-status` | 近 7 日 SP5 advice 三段分布 + 与 SP1/SP3 冲突次数 | 只读表格 |

### §7.3 指引

D3 未就绪时仅跑 TEST_ONLY tests，**不**在生产 Makefile 注入假事件；evidence_ref 必填用于审计回溯。

## §8 部署节奏

本机；consumer 与 main 同进程；扩展期独立 worker。

## §9 准出标准

- [ ] §3.5 14 项
- [ ] 真 D3 event 路径跑通**或** L4 写明 BLOCKED+TEST_ONLY 已过
- [ ] `make exit-step05-all`；L4 回写（消费数、触发数、延迟）

## §10 [Deploy]

env 增 `EXIT_AUTO_CONSUMER=true`（可选）。

## §11 依赖

step_01/02；D3 step_07；Redis；**[L-α]** **D2 step_05 thesis 卡片生成器**（The Timer 生产端归属此 step；thesis 卡 `timer_signal` JSONB 字段 + `timer_signals` 历史表）+ Redis Stream `events:deep_strike:timer_signal` topic（从 D2 step_05 后台 emitter 推送）+ DNA `theme_sniffer.yaml::timer` + DNA `04_exit_engine::sell_protocols` 新增 SP5 节 + 共享规约 D0 alerts.html 渲染契约。

**下游**：D0 副驾驶 alerts.html（SP3 + SP5 advice 统一渲染）；ConflictResolver（SP1/SP3/SP4/SP5 优先级裁决）；用户手动确认后由用户在 QMT/PTrade 等交易终端**手动下单**（**禁止** SP5 → 交易终端的任何自动通路）。

### [L-α] PRD §5 "QMT 自动执行" 在 diting 中的永久翻译契约（必读）

**Lighthouse-Alpha PRD §5（量利变现）** 描述了三段策略：①左侧潜伏预警 → "执行**分批低吸建仓**" / ②主升浪共振 → "**坚定右侧加仓**" / ③利好兑现 → "**毫不留情清仓出局**"，并明确"通过 Webhook 将信号推送到 QMT/PTrade 量化终端"实现自动交易。

**在 diting 项目中，此 PRD §5 描述被永久翻译为以下契约**（**不可违反**）：

| PRD §5 原描述 | diting 翻译 | 强制约束 |
|---|---|---|
| Webhook 推 QMT/PTrade 实现"自动建仓 / 加仓 / 清仓" | SP5 SellSignalEvent 仅作为 **advice**，由 D0 副驾驶 alerts.html 推送给用户；**用户手动**到 QMT/PTrade 下单 | **禁止** SP5 产 `buy/execute/qmt_signal/auto_trade/webhook_target` 等字段；**禁止** D4 调任何交易接口 |
| "执行分批低吸建仓"（潜伏期）| advice "潜伏期建议轻仓持有等待业绩" + evidence_url（监控字典预警 + The Timer 三段） | 不输出建仓量、买入价格、止损位等"执行参数" |
| "坚定右侧加仓"（主升浪期）| advice "主升浪建议持有"（不主动加仓）| diting 永久不输出"加仓/补仓"指令，只输出"持有"建议 |
| "毫不留情清仓出局"（撤退期）| advice "撤退期建议减仓" + evidence_url（财报披露后放量滞涨 / 跌破 10 日均线信号）| 不输出清仓量、卖出价格、止损单等 |

**违反检测**：

| # | 检测项 | 命令 | 通过条件 |
|---|---|---|---|
| AU1 | SP5 SellSignalEvent 模型 schema 无禁词字段 | `pytest tests/exit_engine/test_sp5_no_auto_execute.py::test_event_schema_clean` | 0 命中 |
| AU2 | SP5 代码仓 grep 无 QMT/webhook/auto_trade 调用 | `make exit-step05-sp5-no-auto-audit` | exit 0 |
| AU3 | SP5 advice 文案不含"建仓量/止损位/买入价/卖出价"等执行参数 | NLP 关键词检测 + 单测 | 0 命中 |
| AU4 | 全项目 grep `from .* import qmt` 必须 0 命中 | `make audit-no-qmt-import` | exit 0 |

> **本节是 diting 永久规则**：**不为任何 PRD 妥协，不为任何"高级 AI 功能"破例**。Lighthouse-Alpha 的"自动执行精髓"在 diting 中被**重定义为"信号精度 + 用户决策"**——AI 把"什么时候该建仓 / 持有 / 减仓"的信号做到极致，但**最终扳机永远在人**。这是 L1 基石⑦ 三不为 + L1 基石⑨ 演进哲学的工程兑现。

**严禁**：自动清仓；`inject_mock_health_change.py` 进生产 make all；**[L-α]** SP5 触发 trade/order/execute/qmt 任何接口；SP5 与 SP1/SP3 同标的时丢弃任一记录（必须全部 record 入审计）；伪造 TimerSignalEvent 入业务库；**任何代码或文档建议**从 SP5 直连 QMT/PTrade 或类似自动交易终端。

## §12 风险

| 触发 | 动作 |
|---|---|
| D3 无 event | BLOCKED；TEST_ONLY |
| payload 漂移 | 修+重 schema_check |
| 延迟>10s | 查 D3 producer 与 Redis |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v2.1 Lighthouse-Alpha 融合**：merge_inplace 追加 SP5 财报披露窗口协议（与 SP3 同属事件驱动型卖出协议，逻辑同类）——§1 一句话扩为双协议；交付物 +H~M（TimerSignalConsumer/Sp5Protocol/注册/永久规则单测/D0 告警/冲突优先级）；§3 表追加 timer_signal 消费 + SP5 sell_signals；§3.5 新增 §3.5.4 矩阵 10 项（SP5-1~SP5-10）；§7.1 追加 I~P 八实现要点；§7.2 Makefile 加 5 个 sp5 target；§11 上下游加 D2 The Timer + D0 alerts；强化 no-auto-execute 永久规则在 SP5 上的显式覆盖 |
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 1087 行；§3.5 14 项；evidence_ref；no-auto；TEST_ONLY；`exit-step05-*`；1087→~230 行 |
| 2026-05-16 | 初版 1087 行 |
| 2026-05-21 | **v2.2 The Timer 来源修正 + PRD §5 永久翻译契约**：① 修正 §11 中 The Timer 生产端引用：`D2 step_09` → **`D2 step_05 thesis 卡片生成器`**（与 D2 step_05 v3.0 The Timer 归属一致；step_09 端到端联调仅消费）；② §11 新增"PRD §5 QMT 自动执行在 diting 中的永久翻译契约"小节：对照表 4 行（PRD 原文 vs diting 翻译）+ 4 条违反检测项（AU1~AU4：SP5 SellSignalEvent schema 无禁词 / SP5 代码无 QMT 调用 / advice 文案无执行参数 / 全项目无 qmt import）；③ 严禁清单加"任何代码或文档建议从 SP5 直连 QMT/PTrade"；④ 下游补充"用户手动到 QMT/PTrade 下单"路径明确——彻底阻断 SP5 → 自动交易终端的任何穿透 |
