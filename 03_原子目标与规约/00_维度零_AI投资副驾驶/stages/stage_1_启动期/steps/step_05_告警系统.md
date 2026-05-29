# Step 05 · M3 紧急告警系统（4 红 + 2 橙 / 3 通道 / 5 分钟到达率 ≥99.5%）

## §1 一句话定位与本步交付物

**一句话**：实现 **M3 告警系统**——订阅 D1（`reject`/`degrade`）+ D3（`health_change`，push_level=2/3）+ D4（`sell_signal`）三路事件，按 **4 红 + 2 橙** 告警矩阵分级，经 **3 通道**（微信企业号 webhook / Telegram Bot / 邮件 Resend）推送，**红色 5 分钟到达率 ≥99.5%**；通道失败兜底队列 + 自动重试。

**交付物**（勾选 = 完成）：
- [ ] **A**（`AlertConsumerOrchestrator`）：3 stream 并行消费；事件 → AlertEngine
- [ ] **B**（`AlertEngine`）：规则矩阵 yaml 驱动；4 红 + 2 橙 = 6 类规则；输出 `Alert` 对象
- [ ] **C**（3 通道 sender）：`WechatSender / TelegramSender / EmailSender`；统一 `send(alert)`
- [ ] **D**（`alerts` ORM）：`(alert_id, level, source_event_id, channels, send_status, latency_ms, created_at)`
- [ ] **E**（兜底队列）：通道失败落 `alert_retry_queue`；后台 worker 重试 3 次后告警
- [ ] **F**（到达率 SLA 监控）：`scripts/measure_alert_sla.py` 测红色 5min 到达率
- [ ] **G**（单测）：≥20 含规则/通道 mock/SLA 计算
- [ ] **H**（Makefile）：`make copilot-step05-all`

> **永久规则**：告警仅"通知"；通道**不**含下单链接；红色告警含"建议查看 thesis"而非"立即卖出"。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../01_实践目标与策略.md](../01_实践目标与策略.md) M3、[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md)
> - **DNA**：`modules[2] M3`（4 红+2 橙；3 通道；5min ≥99.5%）+ `cost_budget_monthly`
> - **上游 D1/D3/D4 streams** 见 13_ §四
> - **L4**：[实践记录_step_05_告警系统.md](../../../../../04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/实践记录_step_05_告警系统.md)
> - **上游**：step_01/02；D1 step_06+ / D3 step_07 / D4 step_07；**下游**：step_07 日报推送、step_08 月报

## §3 数据采集对象 / 落库映射

| 输入 | 触发规则 | 落库 |
|---|---|---|
| D1 `events:cryo_guard:reject` | R1 暴雷 reject | `alerts(level=red)` |
| D1 `events:cryo_guard:degrade` | O1 警示 degrade | `alerts(level=orange)` |
| D3 `events:monitor:health_change`（push_level=3）| R2 持仓红色 | `alerts(red)` |
| D3 `events:monitor:health_change`（push_level=2）| O2 持仓橙色 | `alerts(orange)` |
| D4 `events:exit:sell_signal`（SP1/SP3）| R3/R4 止损/Thesis 失效 | `alerts(red)` |
| 通道发送结果 | — | `alerts.send_status` 更新 |

## §3.5 数据质量验收矩阵（M3 · 仅启动期）

### §3.5.1 规则矩阵

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| A1 | **6 类规则可配置** | yaml `alert_rules.yaml`；4 红 R1~R4 + 2 橙 O1~O2 | ✅ | yaml 改不改代码 |
| A2 | **规则纯函数** | 输入 event → 输出 Alert\|None | ✅ pure | 单测多场景 |
| A3 | **去重** | 同 (source_event_id, level, symbol) 5 分钟内不重发 | ✅ | 去重窗口 yaml |

### §3.5.2 通道与 SLA

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| C1 | **3 通道** | 微信/Telegram/邮件 | ✅ | 启动期至少 2 通道可用 |
| C2 | **红色 5min 到达率** | ≥99.5%（实测样本 ≥20）| ⚠️ 启动期目标 | <99.5% 走 §12 |
| C3 | **橙色 30min 到达率** | ≥95% | ✅ | — |
| C4 | **通道幂等** | 同 alert_id 不重发 | ✅ | — |
| C5 | **失败重试** | exp backoff；3 次失败入兜底 | ✅ | — |
| C6 | **成本守门** | 邮件用 Resend 免费额度内；总成本 ≤¥50/月 | ✅ DNA | — |

### §3.5.3 工程 no-trade-link

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| N1 | **告警文案无下单链接** | grep "立即买入"、broker URL = 0 | ✅ |
| N2 | **真实事件触发** | 不允许定时器构造假事件 | ✅ |
| N3 | **审计** | alerts 表每条全留痕 | ✅ |

> 共 **12 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| `WECHAT_WEBHOOK_URL` | 微信企业号 |
| `TELEGRAM_BOT_TOKEN / CHAT_ID` | TG |
| `RESEND_API_KEY` 或 `MAILGUN_*` | 邮件 |
| 3 上游 stream 真流可用 | 主路径 |

> 缺通道：标 BLOCKED 单通道；不伪造发送成功。

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 红色 5min 到达率 | ≥99.5% |
| 橙色 30min 到达率 | ≥95% |
| 3 通道全可用 | ≥2 通道 |
| 单测 | ≥20 |

## §6 下一步

本步 ✅ → step_06 M4 价值账本。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A 3 consumer** | `events/{cryo,health,sell}_consumer.py` | 各自 group；汇总到 orchestrator | mock 3 流 |
| **B AlertEngine** | `services/alert_engine.py` | rules.yaml 驱动；纯函数 | 6 场景单测 |
| **C 3 sender** | `services/senders/{wechat,telegram,email}.py` | 统一 send(alert)；超时 5s | mock + 单测 |
| **D `alerts` ORM + retry** | `models/alert.py` + `services/retry_worker.py` | §3 字段 | migration |
| **E SLA 测量** | `scripts/measure_alert_sla.py` | 时间戳差；P95/到达率 | 报告 |
| **F 去重** | engine 内 LRU；ttl=5min | redis SETEX | 单测 |
| **G 单测** | `test_alert_engine.py`、`test_senders.py`、`test_sla.py` | ≥20 | pytest |
| **H notrade-link grep** | scripts | 0 命中 | — |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `copilot-step05-prep` | 3 stream 与 ≥2 通道凭证在 |
| `copilot-step05-rules-test` | 6 规则单测 |
| `copilot-step05-send-once-red` | 真发 1 条红色到 ≥2 通道 |
| `copilot-step05-send-once-orange` | 真发 1 条橙色 |
| `copilot-step05-sla` | 红色到达率 + 报告 |
| `copilot-step05-retry-sim` | mock 失败→兜底→重试成功 |
| `copilot-step05-notrade-check` | 0 命中 |
| `copilot-step05-test` | pytest ≥20 |
| `copilot-step05-all` | 端到端 |
| `copilot-step05-status` | 24h alerts 计数 + 通道成功率 + 兜底队列 |

### §7.3 指引

先规则→engine→sender→ORM→retry→SLA；红色 5min 是硬指标，缺通道时不强 PASS；文案审过再上线，禁含下单链接。

## §8 部署节奏

本机；扩展期 sender 独立 worker。

## §9 准出标准

- [ ] §3.5 12 项；红色 SLA ≥99.5%（≥20 样本）
- [ ] `make copilot-step05-all`；L4 回写（SLA 报告、3 通道成功率、规则触发计数）

## §10 [Deploy]

ConfigMap 增 `ALERT_RULES_YAML=...`、`SLA_RED_TARGET=0.995`。

## §11 依赖

step_01~04；D1/D3/D4 真流（至少其一可触发演练）；通道凭证。

**严禁**：通道文案含下单链接；定时器构造假事件刷 SLA；同 event 重发。

## §12 风险

| 触发 | 动作 |
|---|---|
| SLA<99.5% | 加并发 + 调通道顺序 + ADR |
| 通道额度耗尽 | 切备用通道 |
| 重复发送 | 去重窗口调长 + 单测 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 1515 行嵌入 Python；§3.5 12 项；SLA + no-trade-link；`copilot-step05-*`；1515→~240 行 |
| 2026-05-16 | 初版 1515 行 |
