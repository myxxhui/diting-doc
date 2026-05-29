# Step 03 · SP1 止损协议（-15%，priority=1，无缓冲）

## §1 一句话定位与本步交付物

**一句话**：实现 **SP1 StopLoss**——`(current_price/cost_price - 1) ≤ -0.15` 立即触发，`priority=1`、`buffer_days=0`；输出 `SellDecision(signal_type=SP1, advice="立即止损")` 并写 `sell_signals` + `protocol_logs`；阈值从 `configs/exit_protocols.yaml` 注入，**禁止**硬编码。

**交付物**（勾选 = 完成）：
- [ ] **A**（`StopLossProtocol`）：继承 BaseSellProtocol；评估输入 position
- [ ] **B**（阈值 yaml）：`configs/exit_protocols.yaml` SP1.threshold = -0.15（可调）
- [ ] **C**（注册）：ProtocolRegistry 替换 step_01 占位
- [ ] **D**（API）：`POST /api/protocols/SP1/evaluate?symbol=X` 即时评估单标的；`GET /api/protocols/SP1/preview` 全 active 预演
- [ ] **E**（advice 文案）：含 `current_price / cost_price / pnl / 建议动作`；启动期固定中文文案
- [ ] **F**（单测）：≥10 边界（-14.99% 不触发 / -15% 触发 / -50% 触发 / 缺 cost_price 跳过）
- [ ] **G**（Makefile）：`make exit-step03-all`

> **永久规则**：触发后**只产 advice**；不调用任何交易接口。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../01_实践目标与策略.md](../01_实践目标与策略.md) SP1
> - **DNA**：`deliverables.sell_protocols[0]`（SP1，threshold=-0.15，priority=1，buffer_days=0）
> - **L4**：[实践记录_step_03_SP1止损协议.md](../../../../../04_阶段规划与实践/04_维度四_卖出决策/stage_1_启动期/实践记录_step_03_SP1止损协议.md)
> - **上游**：step_01/02；**下游**：step_07 冲突 + 回测

## §3 数据采集对象 / 落库映射

| 输入 | 落库 |
|---|---|
| `positions(symbol, cost_price, current_price)` | — |
| 触发结果 | `sell_signals`（仅触发时）|
| 所有评估（触发与否）| `protocol_logs` |

## §3.5 数据质量验收矩阵（SP1 · 仅启动期）

### §3.5.1 触发逻辑

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| L1 | **阈值精确** | `(c/cost - 1) <= -0.15` 严格 | ✅ | yaml 可调 |
| L2 | **边界** | -14.99% 不触发；-15% 触发 | ✅ 单测 | — |
| L3 | **缺 cost_price** | 跳过 + 记 protocol_logs(skip=true,reason=missing_cost) | ✅ | — |
| L4 | **closed_market** | 非交易时段不评估或仅用 last_close 标记 | ✅ | — |
| L5 | **buffer_days=0** | 立即触发；不需要持续天数 | ✅ | — |

### §3.5.2 信号输出

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| S1 | **signal_type=SP1** | 字段固定 | ✅ | — |
| S2 | **advice 中文** | 含 cost/current/pnl 数字 + "建议立即止损" | ✅ | — |
| S3 | **trigger_price** | 触发时的 current_price | ✅ | — |
| S4 | **不自动卖** | 无 broker 调用 | ✅ assert | — |

### §3.5.3 工程

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **yaml 可调** | 改 threshold 重启即生效 | ✅ | — |
| E2 | **idempotent** | 同 symbol 同日同信号不重复 | ✅ uq(symbol, date, signal_type) | — |
| E3 | **审计完整** | 全部评估写 protocol_logs | ✅ | — |

> 共 **11 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| step_02 positions 表有数据 | 必须 |
| `EXIT_PROTOCOLS_YAML` | 阈值 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 4 边界单测 | 全过 |
| 全 active 预演 | 不抛错 |
| advice 文案 | 含完整数字 |

## §6 下一步

本步 ✅ → step_04 SP2 止盈协议。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A yaml 加载** | `config_loader.py` | Pydantic 解析 | yaml→obj |
| **B StopLossProtocol** | `protocols/stop_loss.py` | evaluate 纯函数 | 单测 |
| **C 注册** | engine/registry | 替换占位 | 列表含 SP1 |
| **D advice 模板** | `protocols/messages.py` | 中文模板 + 数字格式化 | 1 case |
| **E API routes** | `api/routes/protocols.py` | evaluate + preview | 200 |
| **F 单测** | `test_sp1_stop_loss.py` | ≥10 边界 | pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `exit-step03-prep` | yaml + positions ≥1 |
| `exit-step03-preview` | 全 active 预演；触发数报告 |
| `exit-step03-evaluate-one` | 1 symbol 评估 |
| `exit-step03-threshold-test` | yaml 改 -0.10 重测 |
| `exit-step03-test` | pytest ≥10 |
| `exit-step03-all` | preview+evaluate+threshold+test |
| `exit-step03-status` | 最近 sell_signals SP1 数 + protocol_logs 总数 |
| `exit-step03-clean` | dev FORCE=1 |

### §7.3 关键代码片段（中间道）

#### 7.3.1 exit_protocols.yaml 阈值配置（核心 ~12 行）

```yaml
# configs/exit_protocols.yaml
sp1_stop_loss:
  enabled: true
  threshold: -0.15            # (current/cost - 1) <= -0.15 触发
  priority: 1                 # 最优先
  buffer_days: 0              # 无缓冲，立即触发
  advice_template: |-
    建议立即止损。成本 {cost_price:.2f} 元，当前 {current_price:.2f} 元，
    浮动亏损 {pnl:+.2%}，已触发 -15% 止损线。
  sell_ratio: 1.0             # 默认全卖
  skip_closed_market: true    # 非交易时段不评估
```

#### 7.3.2 StopLossProtocol 实现（核心 ~15 行）

```python
class StopLossProtocol(BaseSellProtocol):
    protocol_id = "SP1"

    def __init__(self, config: SP1Config):
        self.config = config
        self.priority = config.priority
        self.buffer_days = config.buffer_days

    async def evaluate(self, position: Position, ctx: EvalContext) -> Optional[SellDecision]:
        if not position.cost_price:
            ctx.log_skip(self.protocol_id, position.symbol, reason="missing_cost")
            return None
        if ctx.closed_market and self.config.skip_closed_market:
            return None
        pnl = (position.current_price - position.cost_price) / position.cost_price
        if pnl > self.config.threshold:                  # threshold = -0.15
            return None
        advice = self.config.advice_template.format(
            cost_price=position.cost_price,
            current_price=position.current_price,
            pnl=pnl,
        )
        return SellDecision(symbol=position.symbol, signal_type="SP1",
                            advice=advice, trigger_price=position.current_price,
                            sell_ratio=self.config.sell_ratio,
                            reason_zh=f"{pnl:.2%} ≤ {self.config.threshold:.0%} 止损线")
```

#### 7.3.3 边界单测用例（核心 ~12 行 · 必覆盖）

```python
@pytest.mark.parametrize("cost,current,expect", [
    (100.0,  86.0,  None),                  # -14% 不触发
    (100.0,  85.0,  "SP1"),                 # -15.0% 严格触发（边界）
    (100.0,  85.01, None),                  # -14.99% 不触发
    (100.0,  50.0,  "SP1"),                 # -50% 触发
    (None,   85.0,  None),                  # 缺 cost_price 跳过
])
async def test_sp1_boundary(cost, current, expect, sp1_config, eval_ctx):
    proto = StopLossProtocol(sp1_config)
    pos = Position(symbol="600519", cost_price=cost, current_price=current,
                   holding_ratio=0.25, entered_at=datetime.now())
    decision = await proto.evaluate(pos, eval_ctx)
    if expect is None:
        assert decision is None
    else:
        assert decision.signal_type == expect
        assert "止损" in decision.advice
```

#### 7.3.4 grep 永久规则审计（核心 ~6 行）

```bash
# CI 自检：apps/exit_engine/ 全模块禁止 broker / order / buy / sell API 调用
rg -i "broker_api|place_order|order_submit|trade_execute|auto_sell" \
    apps/exit_engine/ -t py
# 期望：exit code 1（无匹配） · 若有匹配则 CI fail
assert PERMANENT_RULE_NO_AUTO_EXECUTE is True   # 在 test_permanent_rule.py
```

### §7.4 指引

先 yaml→Protocol 类→注册→API→单测；阈值改 yaml 立刻生效；advice 文案严谨标注 cost/current 数字。

## §8 部署节奏

本机 + 后续合并 exit-engine。

## §9 准出标准

- [ ] §3.5 11 项；4 边界单测全过；预演 OK
- [ ] `make exit-step03-all`；L4 回写

## §10 [Deploy]

无新 workload；ConfigMap 加 `EXIT_PROTOCOLS_YAML` 路径。

## §11 依赖

step_01/02。

**严禁**：硬编码 -0.15；自动卖出；忽略 cost 缺失。

## §12 风险

| 触发 | 动作 |
|---|---|
| cost_price 缺失 | skip + ADR |
| 行情陈旧 | closed_market 不评估 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v3 中间道细化**：保留 v2 §3.5 11 项；§7.3 新增 4 个关键片段（exit_protocols.yaml 阈值配置 + advice 模板 / StopLossProtocol evaluate 完整算法 / 5 项边界 parametrize 单测 / grep 永久规则 CI 自检脚本）；147→~330 行 |
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 1009 行；§3.5 11 项；yaml 阈值；`exit-step03-*`；1009→~200 行 |
| 2026-05-16 | 初版 1009 行 |
