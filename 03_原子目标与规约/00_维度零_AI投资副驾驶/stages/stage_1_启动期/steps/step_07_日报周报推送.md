# Step 07 · 日报 / 周报推送（APScheduler + 3 通道 + 中文卡片）

## §1 一句话定位与本步交付物

**一句话**：实现 **DailyReport / WeeklyReport** 生成器 + **APScheduler** 触发（日报 **每日 18:00**；周报 **周日 20:00**）+ 复用 step_05 的 3 通道 sender 推送；内容含**今日变化**（push_level 变 / sell_signal / thesis 新增）+ **本周累计 SCS/EV 简表** + 一键深链回 UI。

**交付物**（勾选 = 完成）：
- [ ] **A**（`DailyReportBuilder`）：读当日 event_logs + health_snapshots + thesis_actions → 中文摘要
- [ ] **B**（`WeeklyReportBuilder`）：滚动 7 天 + 当周 SCS/EV 快照
- [ ] **C**（中文模板）：`templates/reports/{daily,weekly}.md`、`.html`
- [ ] **D**（APScheduler）：CronTrigger；时区 Asia/Shanghai；misfire_grace 600
- [ ] **E**（推送）：复用 step_05 sender（统一 send）；推送状态写 `report_sends`
- [ ] **F**（深链）：报告含 `/holding/{symbol}`、`/thesis/{id}` 链接
- [ ] **G**（单测）：≥12（builder + scheduler mock-clock + sender）
- [ ] **H**（Makefile）：`make copilot-step07-all`

> **永久规则**：报告**不**含下单链接；仅展示与建议。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../01_实践目标与策略.md](../01_实践目标与策略.md) M3-延伸日周报、[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md)
> - **DNA**：`tech_stack.scheduler: APScheduler`、`modules` 与 `quantitative_goals.月报准时率`
> - **L4**：[实践记录_step_07_日报周报推送.md](../../../../../04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/实践记录_step_07_日报周报推送.md)
> - **上游**：step_01~06；**下游**：step_08 月报

## §3 数据采集对象 / 落库映射

| 输入 | 输出 |
|---|---|
| event_logs + health_snapshots + thesis_pool + sell_signals | 报告 markdown/html |
| 当周 SCS/EV | 报告内嵌简表 |
| 推送 | `report_sends(report_type, date, channels, send_status, latency_ms)` |

## §3.5 数据质量验收矩阵（日周报 · 仅启动期）

### §3.5.1 内容正确性

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| R1 | **日报含"今日变化"** | health_change(≥1)、sell_signal、thesis | ✅ | 无变化→明示"今日无变动" |
| R2 | **周报含 SCS/EV 简表** | 7 天累计 | ✅ | 数据不足→ partial |
| R3 | **中文文案** | 标题/字段中文；无术语堆砌 | ✅ | — |
| R4 | **深链可点** | 含 base URL + path | ✅ | — |

### §3.5.2 调度与推送

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| S1 | **日报 18:00** | 7 天准时率 100% | ✅ APScheduler | 漏发→misfire_grace 补 |
| S2 | **周报周日 20:00** | 4 周准时率 100% | ✅ | — |
| S3 | **推送至少 1 通道** | 至少 1 通道成功视为该次推送成功 | ✅ | 单通道全失败→告警 |
| S4 | **去重** | 同 (report_type,date) 不重发 | ✅ | — |

### §3.5.3 no-trade

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| N1 | **报告无下单链接** | grep "broker/buy/sell" 在报告模板 = 0 | ✅ |
| N2 | **不伪造变化** | event_logs 为空→明示而非编造 | ✅ |
| N3 | **真实推送审计** | report_sends 完整 | ✅ |

> 共 **11 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| step_05 ≥2 通道 | 推送复用 |
| `BASE_URL` | 深链 |
| event_logs 已积累 | 内容 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 日报准时率 | 7d 100% |
| 周报准时率 | 4w 100% |
| 推送成功率 | ≥99% |
| 单测 | ≥12 |

## §6 下一步

本步 ✅ → step_08 月报与熔断。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A DailyReportBuilder** | `services/reports/daily.py` | groupby 当日；中文 | 单测 |
| **B WeeklyReportBuilder** | `services/reports/weekly.py` | 滚动 7d + SCS/EV 简表 | 单测 |
| **C 模板** | `templates/reports/*.html` | 简洁中文卡片 | 渲染 |
| **D scheduler** | `scheduler/report_scheduler.py` | APScheduler Cron + tz | mock-clock |
| **E send hook** | `services/reports/sender.py` | 复用 step_05 | 单测 |
| **F `report_sends` ORM** | `models/report.py` + alembic | §3 字段 | migration |
| **G 深链 builder** | `services/reports/links.py` | BASE_URL + path | 单测 |
| **H 单测** | `test_daily_report.py`、`test_weekly_report.py`、`test_scheduler.py` | ≥12 | pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `copilot-step07-prep` | step_01~06 ok；BASE_URL 在 |
| `copilot-step07-daily-once` | 当日报告生成 + 至少 1 通道发 |
| `copilot-step07-weekly-once` | 本周报告 + 发 |
| `copilot-step07-deeplink-check` | 报告含可点深链 |
| `copilot-step07-notrade-check` | 0 命中 |
| `copilot-step07-test` | pytest ≥12 |
| `copilot-step07-all` | 端到端 |
| `copilot-step07-status` | 最近 7 日推送成功率 |
| `copilot-step07-clean` | dev FORCE=1 重置当日 send |

### §7.3 指引

先 builder→模板→scheduler→sender→深链→去重；中文文案审过再上线。

## §8 部署节奏

本机 + APScheduler 同进程；扩展期独立 worker。

## §9 准出标准

- [ ] §3.5 11 项；日/周报各发 1 次成功
- [ ] `make copilot-step07-all`；L4 回写（推送 sample 截图 + 准时率）

## §10 [Deploy]

ConfigMap 增 `DAILY_REPORT_TIME=18:00`、`WEEKLY_DAY=sun`、`WEEKLY_TIME=20:00`、`BASE_URL`。

## §11 依赖

step_01~06；step_05 sender；BASE_URL。

**严禁**：报告含下单链接；伪造内容；时区漂移。

## §12 风险

| 触发 | 动作 |
|---|---|
| scheduler misfire | grace_time 调；ADR |
| 通道全失败 | 兜底队列；告警人 |
| event_logs 空 | 明示"无变化" |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 1265 行嵌入 Python；§3.5 11 项；no-trade-link；`copilot-step07-*`；1265→~210 行 |
| 2026-05-16 | 初版 1265 行 |
