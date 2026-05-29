# L4 · 维度四卖出决策 · 启动期 · 实践记录 step_05 SP3 + SP5

> **状态**：✅ tier-1/2 完成（2026-05-27 · SP3 + SP5 + Redis XREADGROUP 真流）

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[step_05_SP3_Thesis失效协议.md](../../../03_原子目标与规约/04_维度四_卖出决策/stages/stage_1_启动期/steps/step_05_SP3_Thesis失效协议.md)
> - **DNA**：`exit_engine.protocols.sp3` + `sp5_financial_window` + `event_logs`
> - **L5**：`02_验收标准.md#l5-stage-exit_05`
> - **上游**：← D3 health_change / D2 timer_signal
> - **下游**：→ step_07 冲突处理

## 一、本步骤目标

- **SP3** `ThesisInvalidProtocol`：消费 D3 `health_change`，path A/B 触发
- **SP5** `Sp5FinancialWindowProtocol`：消费 D2 `timer_signal`，三段 advice（永久 no-auto-execute）
- **tier-2**：`event_logs` 幂等 + Stream consumer + API evaluate/consume-once

## 二、实际进展（2026-05-27 W5）

| 项 | 状态 | 证据 |
|----|------|------|
| `protocols/thesis_invalid.py` | ✅ | SP3 check/trigger/output_event |
| `protocols/sp5_financial_window.py` | ✅ | 三段 stage + sell_ratio=0 |
| `services/stream_consumer.py` | ✅ | process_health_change / process_timer_signal |
| `services/conflict_resolver.py` | ✅ | SP1>SP3>SP5 优先级 |
| `models/event_log.py` | ✅ | msg_id 幂等 UniqueConstraint |
| `routers/sp3_sp5_router.py` | ✅ | evaluate + consume-once + SP5/recent |
| `events/redis_runner.py` | ✅ | XREADGROUP + xack |
| pytest SP3+SP5+consumer+Redis | ✅ | **29 passed**（含 test_redis_stream_e2e） |
| `make exit-step05-all` | ✅ | Redis 真流 e2e SP3 + SP5 三段 3/3 |
| tier-2 Redis 真流 | ✅ | prod `8.217.158.218:30379` · helm redis @ platform |

## 三、命令与输出摘要

```
make exit-step05-all
  27 passed (SP3 14 + SP5/consumer 13)
  ✅ SP5 路径无 auto_execute / order_id / QMT 禁词
  ✅ 无 qmt import
  SP3 e2e: triggered=True advice=thesis 失效建议清仓
  SP5 e2e: triggered=True advice=🚀 主升浪建议持有
✅ [exit-step05-all] D4 step_05 tier-1/2 准出
```

## 四、准出复核

- [x] SP3 path A/B 触发 + pytest 14 passed
- [x] SP5 三段 advice + sell_ratio=0 + no-auto 审计
- [x] event_logs 幂等（duplicate → reason=duplicate）
- [x] 冲突优先级 SP1>SP3>SP5
- [x] `make exit-step05-all` 退码 0
- [x] tier-2：Redis 真流 xadd → XREADGROUP → SP3/SP5（2026-05-27 prod Redis 30379）

## 五、修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-27 | Redis 真流：helm deploy redis + ExitStreamRedisRunner + e2e SP3/SP5 全绿 |
| 2026-05-25 | W5 tier-1：SP3 实现 + pytest 14 passed |
