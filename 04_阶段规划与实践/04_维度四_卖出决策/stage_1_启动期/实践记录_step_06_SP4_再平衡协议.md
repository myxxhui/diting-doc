# L4 · 维度四卖出决策 · 启动期 · 实践记录 step_06 SP4 再平衡协议

> **状态**：✅ tier-1 完成（2026-05-27 补全 21 tests + mv-based 公式）

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[step_06_SP4_再平衡协议.md](../../../03_原子目标与规约/04_维度四_卖出决策/stages/stage_1_启动期/steps/step_06_再平衡协议.md)
> - **DNA**：`exit_engine.protocols.sp4` + `sp4_rebalance_threshold` 偏离触发
> - **L5**：`02_验收标准.md#l5-stage-exit_06`
> - **上游**：← step_05 SP3 / **下游**：→ step_07 冲突处理

## 一、本步骤目标

实现 `RebalanceProtocol`（SP4）：
- `check`（双模式）：① mv/total → ratio = mv/total > 0.25 严格触发；② weight-based 兼容
- `trigger`：L3 F1 公式 `sell_ratio = (ratio - 0.25) / ratio`，clip [0,1]
- `is_reverse_condition`：ratio ≤ 0.25 → cancelled
- `output_event`：含 advice 含减仓量、无禁字段

## 二、实际进展（2026-05-27 W5 补全）

| 项 | 状态 | 证据 |
|----|------|------|
| `apps/exit_engine/protocols/rebalance.py` | ✅ | 双模式 check / trigger / is_reverse / output_event |
| `pytest tests/exit_engine/test_rebalance.py` | ✅ | **21 passed**（覆盖 T1~T5/F1~F2/B3/E2/T4）|
| `make exit-step06-all` | ✅ | prep + pytest 全绿 |
| T1 严格 > 比较（ratio=0.25 不触发，0.2501 触发）| ✅ | test_t1_* |
| F2 公式验证（30%/100w → sell_ratio ≈ 0.1667）| ✅ | test_f2_sell_ratio_formula_30pct |
| B3 反向取消（ratio 回落 ≤0.25 → is_reverse=True）| ✅ | test_b3_* |
| E2 no-auto-execute（SellSignalEvent 无禁字段）| ✅ | test_e2_* |
| tier-2：持仓权重真实接入 | ⏳ | 等 D0 持仓 SoT 推送完成 |

## 三、命令与输出摘要

```
make exit-step06-all
  21 passed in 0.10s
✅ [exit-step06-all] D4 step_06 tier-1 准出：SP4 pytest 全通过
```

## 四、准出复核（tier-1 §3.5 16 项）

- [x] T1：ratio=0.25 不触发，ratio=0.2501 触发（strict >）
- [x] T2：total_value=0 不触发
- [x] T3：mv/total 缺失降级 weight-based，仍覆盖
- [x] T4：多仓独立评估，仅 ratio>0.25 者触发
- [x] T5：priority=3，buffer_days=7，is_revocable=True
- [x] F1：sell_ratio clip [0,1]
- [x] F2：30% 仓位 sell_ratio ≈ 0.1667（精度 ±0.0001）
- [x] B3：ratio 回落 → is_reverse_condition=True → 自动 cancelled
- [x] E2：SellSignalEvent 无 buy/execute/order_id 等禁字段
- [x] pytest **21 passed**（远超 ≥16 要求）
- [x] `make exit-step06-all` 退码 0
- [ ] tier-2：真实持仓权重接入（等 D0 step_04 推荐池联调）

## 五、修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-27 | W5 补全：协议升级为 mv-based 双模式；新增 T1~T4/F1~F2/B3/E2 测试；pytest 11→21 passed |
| 2026-05-25 | W5 tier-1 完成：SP4 实现 + pytest 11 passed |
