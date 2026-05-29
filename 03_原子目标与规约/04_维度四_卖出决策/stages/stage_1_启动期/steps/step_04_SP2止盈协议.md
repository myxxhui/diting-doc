# Step 04 · SP2 止盈协议（+30%，priority=2，3 天缓冲）

## §1 一句话定位与本步交付物

**一句话**：实现 **SP2 TakeProfit**——`(current_price/cost_price - 1) ≥ +0.30` 且**连续 ≥3 个交易日**持续满足 → 触发；`priority=2`、`buffer_days=3`；advice 含"建议分批止盈/部分减仓"；阈值与 buffer_days 进 yaml 可调。

**交付物**（勾选 = 完成）：
- [ ] **A**（`TakeProfitProtocol`）：评估需查历史；`buffer_days=3`
- [ ] **B**（缓冲计算）：基于 `protocol_logs` 最近 3 个交易日 SP2 命中状态；缓冲未满标 `pending(n/3)` 不发信号
- [ ] **C**（yaml 阈值）：SP2.threshold=0.30；buffer_days=3
- [ ] **D**（API）：`POST /api/protocols/SP2/evaluate?symbol=X`；返回 `triggered / pending / not_met`
- [ ] **E**（advice 文案）：含 cost/current/pnl + "建议分批止盈"
- [ ] **F**（单测）：≥12（buffer 1/3、2/3、3/3 = 触发；连续中断重置）
- [ ] **G**（Makefile）：`make exit-step04-all`

> **永久规则**：触发只发 advice；具体比例（如 50%）由架构师决定。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../01_实践目标与策略.md](../01_实践目标与策略.md) SP2
> - **DNA**：`deliverables.sell_protocols[1]`（SP2，threshold=0.30，priority=2，buffer_days=3）
> - **L4**：[实践记录_step_04_SP2止盈协议.md](../../../../../04_阶段规划与实践/04_维度四_卖出决策/stage_1_启动期/实践记录_step_04_SP2止盈协议.md)
> - **上游**：step_01/02/03；**下游**：step_07 冲突 + 回测

## §3 数据采集对象 / 落库映射

| 输入 | 落库 |
|---|---|
| positions + 最近 3 交易日 protocol_logs | — |
| 触发 | `sell_signals`（buffer 满足后）|
| pending/not_met | `protocol_logs`（含 buffer_state）|

## §3.5 数据质量验收矩阵（SP2 · 仅启动期）

### §3.5.1 触发与缓冲

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| L1 | **阈值精确** | `(c/cost - 1) >= 0.30` 严格 | ✅ | yaml 调整 |
| L2 | **buffer_days=3** | 连续 3 交易日满足才触发 | ✅ | — |
| L3 | **缓冲计数** | 用 protocol_logs 最近 3 交易日 SP2 hit 状态；非交易日跳过 | ✅ | — |
| L4 | **中断重置** | 中间 1 日跌破→计数清零重计 | ✅ | — |
| L5 | **pending(n/3)** | 未到 3 天明示进度 | ✅ | — |

### §3.5.2 信号输出

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| S1 | **signal_type=SP2** | — | ✅ | — |
| S2 | **advice** | 含 cost/current/pnl/缓冲天数 + "建议分批止盈" | ✅ | — |
| S3 | **trigger_price** | 第 3 天 current_price | ✅ | — |
| S4 | **不自动卖** | 无 broker 调用 | ✅ | — |

### §3.5.3 工程

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **yaml 可调** | threshold + buffer_days | ✅ | — |
| E2 | **idempotent** | (symbol, date) 一次 SP2 信号 | ✅ | — |
| E3 | **审计 buffer_state** | protocol_logs 含 1/3、2/3、3/3 | ✅ | — |
| E4 | **交易日历** | 连续天数用 trade_cal | ✅ | — |

> 共 **13 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| step_02 positions + 行情 | 必须 |
| protocol_logs 最近 3 交易日有评估 | 缓冲前提（启动期可前置预热）|
| `EXIT_PROTOCOLS_YAML` | 阈值 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 12 单测（含 buffer 边界）| 全过 |
| pending 状态可读 | API 返结构 |
| 触发 advice 文案合规 | ✅ |

## §6 下一步

本步 ✅ → step_05 SP3 thesis_invalid（订阅 D3 health_change）。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A TakeProfitProtocol** | `protocols/take_profit.py` | evaluate + 缓冲查询 | 单测 |
| **B 缓冲计算 util** | `engine/buffer.py` | 输入 protocol_logs 最近 N 交易日 → bool/n | 单测中断重置 |
| **C 注册** | registry | 替换占位 | ✅ |
| **D advice 文案** | messages.py | buffer 状态文案 | — |
| **E API** | routes/protocols.py | evaluate 返 triggered/pending/not_met | 200 |
| **F 单测** | `test_sp2_take_profit.py` | ≥12 含中断 | pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `exit-step04-prep` | yaml；step_03 已跑过预演（预热 logs）|
| `exit-step04-preview` | 全 active 三档分布 |
| `exit-step04-buffer-progress` | 显示 pending 1/3、2/3、3/3 各几只 |
| `exit-step04-evaluate-one` | 1 symbol 评估 |
| `exit-step04-test` | pytest ≥12 |
| `exit-step04-all` | preview+buffer+evaluate+test |
| `exit-step04-status` | 最近 sell_signals SP2 + pending 列表 |
| `exit-step04-clean` | dev FORCE=1 |

### §7.3 指引

缓冲计数严格基于交易日；中断必须重置；advice 文案"分批"不"全卖"——D4 永远只建议。

## §8 部署节奏

本机；合并 exit-engine。

## §9 准出标准

- [ ] §3.5 13 项；缓冲单测全过
- [ ] `make exit-step04-all`；L4 回写（pending/触发分布）

## §10 [Deploy]

ConfigMap 增 SP2 配置；无新 workload。

## §11 依赖

step_01/02/03（共用 logs 表）。

**严禁**：跳过缓冲；硬编码 buffer=3；自动卖出。

## §12 风险

| 触发 | 动作 |
|---|---|
| 缓冲日历错误 | 切 pytz；ADR |
| 频繁抖动 | 提升 buffer 或加迟滞 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 1118 行；§3.5 13 项；buffer 严谨；`exit-step04-*`；1118→~210 行 |
| 2026-05-16 | 初版 1118 行 |
