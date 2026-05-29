# Step 06 · M4 价值账本（SCS / EV / 8 象限归因 / 月报 / 自我熔断）

## §1 一句话定位与本步交付物

**一句话**：实现 **M4 价值账本**——综合各维度事件 + 用户操作回填，算 **SCS（System Contribution Score）** 与 **EV（Expected Value）** 指标 + **8 象限归因** + **月度避险价值 ≥¥3000** 估算 + **自我熔断**（当 SCS 长期为负触发"系统暂停建议"，仅警示，不停 D0 服务）。

**交付物**（勾选 = 完成）：
- [ ] **A**（`SCSCalculator`）：纯函数；对每个建议（reject/thesis/health_change/sell_signal）打 SCS 分（采纳/不采纳 × 后续盈亏 × 系数）
- [ ] **B**（`EVCalculator`）：基于历史标的×建议×实际结果 估 EV；分维度
- [ ] **C**（8 象限归因器）：建议 × 时间窗口（短/中/长）× 用户操作（采纳/不采纳）= 8 格；每月统计
- [ ] **D**（月度避险价值）：reject + sell_signal 标的 避免的潜在损失估算（基于回测样本系数）
- [ ] **E**（自我熔断器）：连续 3 个月 SCS<0 → 写 `circuit_breaker_events` + UI 顶部警示条
- [ ] **F**（API + UI）：`/value-ledger`；月度面板；4 卡（SCS / EV / 8 象限热图 / 避险价值）
- [ ] **G**（PDF）：`/value-ledger/{ym}/pdf` 月度报告
- [ ] **H**（单测）：≥18；Makefile `make copilot-step06-all`

> **永久规则**：自我熔断**仅警示用户**，**不**自动停止任何维度服务；用户决定是否继续使用。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../01_实践目标与策略.md](../01_实践目标与策略.md) M4、[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md)
> - **DNA**：`modules[3] M4`（SCS/EV/8 象限/月报/熔断）+ `quantitative_goals.月度避险≥¥3000`
> - **共享**：[15_前后端职责与产品价值优先级](../../../../_共享规约/15_前后端职责与产品价值优先级.md)
> - **L4**：[实践记录_step_06_价值账本.md](../../../../../04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/实践记录_step_06_价值账本.md)
> - **上游**：step_01~05；**下游**：step_07 日周报 + step_08 月报熔断 + step_10 验收

## §3 数据采集对象 / 落库映射

| 输入 | 落库 |
|---|---|
| 各维度事件历史（event_logs）| read-only |
| 用户操作（thesis_actions、portfolio 变动）| read |
| SCS 计算结果 | `scs_records(period, suggestion_id, score, payload)` |
| EV 估算 | `ev_records(period, dim, ev, n_samples)` |
| 8 象限矩阵 | `attribution_matrix(period, dim, time_window, action, count, net_value)` |
| 避险价值 | `hedge_value_estimates(period, total_yuan, breakdown)` |
| 熔断事件 | `circuit_breaker_events(triggered_at, scs_trend, status)` |

## §3.5 数据质量验收矩阵（M4 · 仅启动期）

### §3.5.1 SCS / EV 计算正确性

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| S1 | **SCS 公式 yaml** | yaml 系数；纯函数；可单测复现 | ✅ | 改公式必走 ADR |
| S2 | **采纳判定** | 用户在建议后 X 日内有对应操作（卖出/不买入）→ 采纳 | ✅ | 缺操作→未采纳 |
| S3 | **正负 SCS 边界** | 采纳避险=正；未采纳遭损=负；忽略=0 | ✅ | — |
| S4 | **EV 公式** | EV = Σ(SCS × weight) / N；分维度 | ✅ | N<10 标 low_confidence |
| S5 | **可重跑幂等** | 同期数据同结果 | ✅ | — |

### §3.5.2 8 象限归因

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| Q1 | **8 格** | 维度 × 短中长 × 采纳/未 = 8（启动期 D1/D3/D4 三维 = 实际 12 格，UI 折叠展示）| ✅ | — |
| Q2 | **热图渲染** | UI 颜色梯度；数值可点钻 | ✅ | — |
| Q3 | **导出 csv** | 月度可下载 | ✅ | — |

### §3.5.3 避险价值与熔断

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| H1 | **¥3000 估算** | reject/sell_signal 标的 × 回测系数；月报展示 | ⚠️ 启动期目标 | <¥3000 标 partial |
| H2 | **系数 yaml** | `hedge_coefficients.yaml`；评审 | ✅ | — |
| H3 | **熔断阈值** | 连续 3 月 SCS<0 → 触发 | ✅ | — |
| H4 | **熔断仅警示** | UI 顶部条 + 月报章节；**不**停服务 | ✅ assert | — |

### §3.5.4 no-trade

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| N1 | **不调券商 API** | 净值/持仓变动来自 SoT/手工录入 | ✅ |
| N2 | **不伪造 SCS** | 必须由 event_logs + 用户操作推导 | ✅ |

> 共 **15 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| event_logs 已积累（step_03~05）| SCS 输入 |
| 用户操作 thesis_actions、portfolio 变更 | 采纳判定 |
| `HEDGE_COEFFICIENTS_YAML` | 系数 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| SCS / EV 计算可复现 | ✅ |
| 月度避险价值估算 | ≥¥3000 或 partial 文档化 |
| 8 象限 UI 可读 | ✅ |
| 单测 | ≥18 |

## §6 下一步

本步 ✅ → step_07 日报周报推送。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A SCS calc** | `services/value_ledger/scs_calculator.py` | yaml 系数 + pure | 10 场景单测 |
| **B EV calc** | `services/value_ledger/ev_calculator.py` | 滚动窗口 | 单测 |
| **C 8 象限** | `services/value_ledger/attribution.py` | groupby + pivot | 单测 |
| **D 避险价值** | `services/value_ledger/hedge_value.py` | reject/sell × coeff | yaml + 单测 |
| **E 熔断** | `services/value_ledger/circuit_breaker.py` | 3 月窗口 + 警示 | mock 数据 |
| **F ORM** | `models/value.py` + alembic | §3 字段 | migration |
| **G API + 模板** | `api/routes/m4.py` + `templates/value_ledger.html` | 4 卡 + 热图 | 200 |
| **H PDF** | `services/pdf_exporter.py` 扩展 | 月报模板 | render |
| **I 单测** | 各 calculator + UI | ≥18 | pytest |
| **J no-trade assert** | scripts | 0 调外部 | — |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `copilot-step06-prep` | event_logs ≥N 行；coefficients yaml 在 |
| `copilot-step06-scs-test` | 10 场景单测 |
| `copilot-step06-ev-once` | 算当月 EV |
| `copilot-step06-attribution` | 8 象限输出 |
| `copilot-step06-hedge-value` | 当月避险价值 ≥¥3000 或 partial |
| `copilot-step06-circuit-sim` | 模拟 3 月 SCS<0 → 触发警示 |
| `copilot-step06-pdf` | 月度 PDF |
| `copilot-step06-test` | pytest ≥18 |
| `copilot-step06-all` | 端到端 |
| `copilot-step06-status` | 最近月 SCS/EV/避险价值 |

### §7.3 指引

先 SCS→EV→归因→避险→熔断→UI→PDF；系数 yaml 评审过再上线；熔断仅警示。

## §8 部署节奏

本机；扩展期独立计算 Pod。

## §9 准出标准

- [ ] §3.5 15 项；可重跑幂等 + 熔断模拟通过
- [ ] `make copilot-step06-all`；L4 回写（当月 SCS/EV/8 象限/避险价值）

## §10 [Deploy]

ConfigMap 增 `HEDGE_COEFFICIENTS_YAML`、`CIRCUIT_BREAKER_WINDOW_MONTHS=3`。

## §11 依赖

step_01~05；event_logs 累积；coefficients yaml。

**严禁**：自动停服务作为熔断动作；伪造 SCS/EV；不审 coefficients 上线。

## §12 风险

| 触发 | 动作 |
|---|---|
| 避险<¥3000 | 调系数 ADR；标 partial |
| SCS 公式争议 | yaml 改 + 评审 + ADR |
| 用户未操作→采纳判定空 | UI 引导用户回填 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 1750 行嵌入 Python；§3.5 15 项；no-auto-stop；`copilot-step06-*`；1750→~240 行 |
| 2026-05-16 | 初版 1750 行 |
