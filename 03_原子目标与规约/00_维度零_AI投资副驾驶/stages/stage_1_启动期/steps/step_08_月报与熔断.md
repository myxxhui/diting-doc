# Step 08 · 月报 PDF（T+1 100% 准时）+ 自我熔断流程

## §1 一句话定位与本步交付物

**一句话**：实现 **MonthlyReportBuilder**——每月 **次月 1 日 09:00** 生成 PDF + 推送 + 归档；内容覆盖 SCS/EV/8 象限/避险价值/熔断状态；同时把 step_06 的 **自我熔断**（连续 3 月 SCS<0）固化为正式流程，含 UI 警示条 + 月报熔断章节 + 用户可点"确认知悉"日志。

**交付物**（勾选 = 完成）：
- [ ] **A**（`MonthlyReportBuilder`）：扩展 step_07 模板；含 SCS/EV/8 象限热图/避险价值/熔断小节
- [ ] **B**（PDF）：WeasyPrint A4；含 5 节 + 封面 + 目录；归档 MinIO 或本地 `data/reports/{YYYYMM}.pdf`
- [ ] **C**（APScheduler）：CronTrigger `1 9 1 * *`（每月 1 日 9:00）；T+1 准时 100%
- [ ] **D**（推送）：复用 step_05 sender（3 通道 + 附件 / 邮件 PDF）
- [ ] **E**（熔断流程）：连续 3 月 SCS<0 → UI 顶部红条 + 月报章节 + `circuit_breaker_events` 写入
- [ ] **F**（确认知悉）：`POST /api/circuit-breaker/{event_id}/ack` 用户点确认 + 写 `circuit_breaker_acks`
- [ ] **G**（单测）：≥14；Makefile `make copilot-step08-all`

> **永久规则**：熔断**仅警示**，**不**停 D0 服务；用户点"知悉"即可继续使用。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../01_实践目标与策略.md](../01_实践目标与策略.md) M4 + 月报
> - **DNA**：`quantitative_goals.月报准时率=100%`、`circuit_breaker`（暗含于 M4）
> - **L4**：[实践记录_step_08_月报与熔断.md](../../../../../04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/实践记录_step_08_月报与熔断.md)
> - **上游**：step_06/07；**下游**：step_09 全链路 + step_10 验收

## §3 数据采集对象 / 落库映射

| 输入 | 输出 |
|---|---|
| step_06 全部价值账本表 | 月报 PDF |
| circuit_breaker_events 已存在 | 月报熔断章节 |
| 用户确认 | `circuit_breaker_acks(event_id, ack_at, user_id)` |
| 推送 | `report_sends(report_type=monthly,...)` |
| 归档 | `data/reports/{YYYYMM}.pdf` + 可选 MinIO |

## §3.5 数据质量验收矩阵（月报 + 熔断 · 仅启动期）

### §3.5.1 月报准时性与完整性

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| M1 | **T+1 准时** | 次月 1 日 9:00；100% 准时（DNA）| ✅ | misfire_grace；告警人 |
| M2 | **5 节齐全** | 业绩/价值账本/归因/避险/熔断 | ✅ | — |
| M3 | **数据真实** | 来自 step_06 + event_logs；无伪造 | ✅ | — |
| M4 | **PDF 离线可读** | WeasyPrint A4 中文字体 | ✅ | — |
| M5 | **归档可查** | `data/reports/{YYYYMM}.pdf` 长期保留 | ✅ | — |

### §3.5.2 熔断流程

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| C1 | **触发条件** | 连续 3 月 SCS<0 = circuit_breaker_events 一条 | ✅ | 阈值 yaml 可调 |
| C2 | **UI 警示条** | 全站顶部红条 + 链接月报 | ✅ | — |
| C3 | **月报熔断章节** | 必含；并列 5 节之一 | ✅ | 无熔断也保留章节标 N/A |
| C4 | **确认知悉** | 写 acks 表；UI 警示条消失（直至下次触发）| ✅ | — |
| C5 | **不停服务** | grep stop/disable 路径=0；assert | ✅ | — |

### §3.5.3 no-trade

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| N1 | **月报无下单链接** | grep | ✅ |
| N2 | **熔断不自动操作** | assert no-action | ✅ |

> 共 **12 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| step_06 价值账本表已就绪 | 输入 |
| step_05 sender + 邮件附件 | 推送 |
| WeasyPrint + 中文字体 | PDF |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 月报准时 | T+1 100% |
| 熔断流程演练 | ✅ 1 次（手工 inject）|
| 单测 | ≥14 |

## §6 下一步

本步 ✅ → step_09 全链路联调。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A MonthlyReportBuilder** | `services/reports/monthly.py` | 扩展周报；5 节 | 单测 |
| **B PDF 生成** | `services/pdf_exporter.py` 扩展 | 5 节 + 目录 | render |
| **C 归档** | `services/reports/archive.py` | 本地路径；可选 MinIO | exists |
| **D scheduler** | `scheduler/report_scheduler.py` 扩展 | Cron `1 9 1 * *` tz | mock-clock |
| **E 熔断检测** | `services/value_ledger/circuit_breaker.py` 扩展 | 3 月窗口（含本月）；写 events | 模拟数据 |
| **F UI 警示条** | `templates/partials/circuit_banner.html` | 条件渲染 | 视觉 |
| **G ack API** | `api/routes/circuit.py` | 写 acks；UI 隐警示 | 200 |
| **H 单测** | `test_monthly_report.py`、`test_circuit_breaker.py`、`test_ack.py` | ≥14 | pytest |
| **I no-trade / no-stop assert** | scripts | 0 命中 | — |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `copilot-step08-prep` | step_06/07 ok |
| `copilot-step08-monthly-once` | 当月 PDF + 推送 + 归档 |
| `copilot-step08-circuit-sim` | inject 3 月 SCS<0 → 触发 + UI 警示 + 月报章节 |
| `copilot-step08-ack-test` | ack API + 警示条消失 |
| `copilot-step08-nostop-check` | grep 0 命中 |
| `copilot-step08-test` | pytest ≥14 |
| `copilot-step08-all` | 端到端 |
| `copilot-step08-status` | 最近 N 月发送状态 + 熔断历史 |

### §7.3 指引

先 monthly builder→PDF→归档→scheduler→熔断 UI→ack→assert；熔断仅警示；不停服务。

## §8 部署节奏

本机；扩展期 cron 独立 Pod。

## §9 准出标准

- [ ] §3.5 12 项；月报 1 次成功 + 熔断演练 1 次
- [ ] `make copilot-step08-all`；L4 回写（月报 PDF 路径 + 熔断演练记录）

## §10 [Deploy]

ConfigMap 增 `MONTHLY_REPORT_CRON="1 9 1 * *"`、`CIRCUIT_BREAKER_WINDOW=3`。

## §11 依赖

step_06/07；step_05 sender；字体。

**严禁**：熔断自动停服务；月报含下单链接；伪造数据。

## §12 风险

| 触发 | 动作 |
|---|---|
| PDF 中文乱码 | 字体路径修；ADR |
| 月报延迟 | misfire_grace + 告警 |
| 熔断频发 | 回查 SCS 公式 + 数据 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 1323 行嵌入 Python；§3.5 12 项；no-stop；`copilot-step08-*`；1323→~220 行 |
| 2026-05-16 | 初版 1323 行 |
