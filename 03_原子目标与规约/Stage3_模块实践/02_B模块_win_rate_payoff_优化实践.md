# B 模块 · 胜率/盈亏比变量化最佳实践

> 设计目标：将 B 模块的 `win_rate_prediction`、`payoff_ratio` 做成**可配置变量**，**默认关闭**；开启时由配置或回测统计提供，供 Module D 判官凯利计算使用。

## 一、设计原则

1. **默认关闭**：B 不计算、不输出胜率与盈亏比，下游 D 使用自身默认或配置。
2. **变量化**：开启时，数值来自配置（占位）或未来回测统计模块，不硬编码。
3. **向后兼容**：未开启时，QuantSignal 中不包含 `win_rate_prediction`、`payoff_ratio` 字段；D 的 vote 已支持缺失时使用默认。

## 二、配置设计

在 `config/scanner_rules.yaml` 的 `module_b_quant_engine.product_signals` 或新增 `kelly_input` 节点：

```yaml
# product_signals 下扩展，或独立 kelly_input 节点
product_signals:
  emit_win_rate_payoff: false   # 默认关闭
  win_rate_prediction: 0.7      # 开启时的占位值（未来可由回测填充）
  payoff_ratio: 2.0             # 开启时的占位值（未来可由回测填充）
```

| 配置项 | 类型 | 默认 | 说明 |
|--------|------|------|------|
| `emit_win_rate_payoff` | bool | false | 是否在 QuantSignal 中输出 win_rate_prediction、payoff_ratio |
| `win_rate_prediction` | float | 0.7 | 开启时的胜率占位值 [0,1] |
| `payoff_ratio` | float | 2.0 | 开启时的盈亏比占位值，>0 |

## 三、输出契约

- **关闭时**：QuantSignal（及其 L2 写入）**不包含** `win_rate_prediction`、`payoff_ratio`。
- **开启时**：每条 QuantSignal 增加可选字段（dict 或 proto 扩展）：
  - `win_rate_prediction`: float，范围 [0, 1]
  - `payoff_ratio`: float，范围 > 0

## 四、与 D 模块的衔接

- D 的 `vote()` 与凯利计算：当 `quant_signal` 中无 `win_rate_prediction` 时，使用 D 侧配置默认（如 0.7）。
- B 开启 `emit_win_rate_payoff` 后，D 可优先读取 B 的输出。

## 五、验收

- [ ] 默认配置下 B 不输出 win_rate_prediction、payoff_ratio
- [ ] `emit_win_rate_payoff: true` 时，输出含两字段且值来自配置
- [ ] L2 quant_signal_snapshot / quant_signal_scan_all 仅在开启时写入对应列（若有）
