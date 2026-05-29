# Step 06 · SP4 再平衡协议（单仓占比 >25% · 7d 缓冲 · 部分卖出）

## §1 一句话定位与本步交付物

**一句话**：实现 **SP4 RebalanceProtocol**——单仓占比 `> 0.25` 严格触发，**priority=3**（最低）、**buffer_days=7**、**部分卖出**（`sell_ratio = (mv - total*threshold)/mv`，保留 25% 仓位）；与 SP2 共用 **BufferManager** 与反向取消语义；advice "占比超阈值建议减仓至 25%"。

**交付物**（勾选 = 完成）：
- [ ] **A**（`RebalanceProtocol`）：`check / trigger / output_event / is_reverse_condition` 完整；DNA 字段一致
- [ ] **B**（sell_ratio 公式）：纯函数；可单测复现（30% 仓位+总值 100 万 → sell_ratio≈0.1667）
- [ ] **C**（BufferManager 复用）：SP2 实现已存在；本步 `evaluate_with_buffer` 泛化兼容 SP4
- [ ] **D**（API）：`POST /api/protocols/rebalance/evaluate/{user_id}`、`.../{user_id}/{position_id}`
- [ ] **E**（CLI）：`scripts/evaluate_all_holdings.py --protocol rebalance` 组合视角
- [ ] **F**（反向取消）：占比回落 ≤0.25 → pending → cancelled（自动）
- [ ] **G**（单测 + Makefile）：≥16 passed；`make exit-step06-all`

> **永久规则**：SP4 仅产 advice 与 sell_signal 事件；**不**自动下单。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../01_实践目标与策略.md](../01_实践目标与策略.md) §2.4 SP4、[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §3.5
> - **DNA**：`deliverables.sell_protocols[3]`（SP4：threshold=0.25，priority=3，buffer_days=7）
> - **共享**：[13_六维度启动期集成与时序](../../../../_共享规约/13_六维度启动期集成与时序.md) §四
> - **L4**：[实践记录_step_06_SP4再平衡协议.md](../../../../../04_阶段规划与实践/04_维度四_卖出决策/stage_1_启动期/实践记录_step_06_SP4再平衡协议.md)
> - **上游**：step_02 PortfolioService、step_04 BufferManager；**下游**：step_07 冲突 + 回测

## §3 数据采集对象 / 落库映射

| 流向 | 表/流 |
|---|---|
| 持仓快照 → 占比 | 读 `portfolio_positions`（step_02 已建）|
| 触发审计 | `protocol_logs(protocol=rebalance, decision, sell_ratio, ratio)` |
| pending/cancelled | `protocol_buffer(protocol_id, position_id, created_at, expires_at, status)` |
| 触发输出（step_07 发布）| `sell_signals(symbol, protocol, sell_ratio, advice)` |

## §3.5 数据质量验收矩阵（SP4 · 仅启动期）

### §3.5.1 触发逻辑

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| T1 | **严格 `>` 比较** | ratio=0.25 → 不触发；ratio=0.2501 → 触发 | ✅ 边界单测 | — |
| T2 | **portfolio 边界** | `total_value <= 0` → 不触发 | ✅ | — |
| T3 | **mv 缺失** | `market_value is None`（无行情）→ 不触发 + reason="no_quote" | ✅ | — |
| T4 | **多仓独立评估** | 仅触发 ratio>0.25 的 position；其余 abstain | ✅ | — |
| T5 | **priority/buffer/is_revocable** | priority=3；buffer_days=7；is_revocable=true | ✅ DNA | — |

### §3.5.2 sell_ratio 公式

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| F1 | **公式** | `sell_ratio = (mv - total*0.25)/mv`；clip [0,1] | ✅ 纯函数 | — |
| F2 | **可复现样例** | 30%/100w → 5w 减仓 / mv=30w → 0.1667 ±1e-4 | ✅ 单测 | — |
| F3 | **保留下限** | 卖出后剩余占比 ≈ 25%（受其他仓变动影响）| ✅ | 实际成交差异由人确认 |
| F4 | **advice 含数额** | "占比 30%→25%，建议减仓 5 万" | ✅ | — |

### §3.5.3 缓冲与反向取消

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| B1 | **BufferManager 入队** | 触发→`pending` 7 天 | ✅ 复用 step_04 | — |
| B2 | **同 (position, protocol) 幂等** | 已 pending 不重复入队 | ✅ | — |
| B3 | **反向条件** | ratio ≤0.25 → `is_reverse_condition=True` → cancelled | ✅ | — |
| B4 | **过期触发** | 7 天到期且 ratio 仍 >0.25 → `triggered` 写 sell_signals | ✅ | — |

### §3.5.4 工程与 no-mock

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **行情来源** | step_02 持仓快照真实 | ✅ | mock 仅 tests |
| E2 | **不自动下单** | sell_signal 仅 advice | ✅ assert | — |
| E3 | **单测 ≥16** | 边界/多仓/反向/过期 | ✅ | — |

> 共 **16 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| step_02 PortfolioService | 持仓与行情 |
| step_04 BufferManager | 缓冲与反向 |
| `MY_HOLDINGS_YAML` 含成本/数量 | 占比计算 |

> **禁止**：mock 价格走业务 sell_signals；buffer 表手工改 status。

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 触发准确率（含反向取消）| ≥95% 单测 |
| buffer 复用 | 与 SP2 同一管理器 |
| 单测 | ≥16 passed |

## §6 下一步

本步 ✅ → step_07 冲突处理 + 100 笔回测 + sell_signal publisher。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A RebalanceProtocol** | `protocols/rebalance.py` | priority=3；buffer=7；is_revocable | 单测覆盖 §3.5.1 |
| **B sell_ratio fn** | 同上模块 pure func | 公式 §3.5.2 | 单测样例 |
| **C is_reverse_condition** | 同模块方法 | ratio≤0.25 | 单测 |
| **D ProtocolRunner.evaluate_with_buffer** | `services/protocol_runner.py` | SP2 已有；本步去 SP-specific 分支 | 泛化测 |
| **E API rebalance_router** | `routers/rebalance_router.py` | user/position 两级 | 200 |
| **F evaluate_all_holdings CLI** | `scripts/evaluate_all_holdings.py` | `--protocol rebalance` | stdout 报告 |
| **G ProtocolRegistry 注册** | `protocols/__init__.py` | SP4 注册 | startup OK |
| **H 单测** | `test_rebalance.py` | ≥16 含反向/过期 | pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `exit-step06-prep` | step_02/04 表在；portfolio 有 ≥1 仓 |
| `exit-step06-evaluate-once` | 全持仓评估 1 次 |
| `exit-step06-reverse-check` | 注入 ratio 下降 → cancelled |
| `exit-step06-buffer-expire-sim` | 注入 created_at-8d → triggered |
| `exit-step06-test` | pytest ≥16 |
| `exit-step06-all` | 端到端 |
| `exit-step06-status` | pending/cancelled/triggered 计数 |
| `exit-step06-clean` | dev FORCE=1 清当日 SP4 buffer |

### §7.3 指引

先 RebalanceProtocol→泛化 Runner→反向条件→Buffer→API→CLI；**不**在生产路径调真实下单接口。

## §8 部署节奏

本机 + 与现有 exit-engine 同进程；K3s 扩展期。

## §9 准出标准

### §9.1 功能
- [ ] 全持仓评估 1 次：仅 ratio>0.25 触发 pending；其余 abstain
- [ ] 反向条件：下调 mv 至 ratio≤0.25 → 自动 cancelled
- [ ] 过期 7d：注入 created_at-8d → triggered + sell_signals +1

### §9.2 质量（§3.5 16 项）
- [ ] T1~T5 + F1~F4 + B1~B4 + E1~E3 全勾

### §9.3 工程
- [ ] `pytest tests/exit_engine/test_rebalance.py` ≥16
- [ ] `make exit-step06-all`；L4 回写（pending/cancelled/triggered 计数）

## §10 [Deploy]

复用 exit-engine 镜像；ConfigMap 增 `SP4_THRESHOLD=0.25 SP4_BUFFER_DAYS=7`（可调）。

## §11 依赖

step_02、step_04；SP1/SP2/SP3 已注册（同进程）。

**严禁**：手工改 buffer 表状态；mock 价格写业务 sell_signals。

## §12 风险

| 触发 | 动作 |
|---|---|
| portfolio 数据缺失 | reason=no_quote 不触发 |
| buffer 表损坏 | 重建（dev FORCE）|
| 过期任务漏触发 | scheduler 增 daily sweep（step_07 可补）|
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 724 行嵌入 Python；§3.5 16 项；`exit-step06-*`；724→~230 行 |
| 2026-05-16 | 初版 724 行 |
