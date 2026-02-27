# 5D 范例 · Module D 判官最小闭环

本文档针对 [Stage3_模块实践/04_热路径判官风控与执行](Stage3_模块实践/04_热路径判官风控与执行_实践.md)，按 **Design → Drive → Decompose → Defense** 完整走通，读者不打开 09_/01_ 即可按本范例执行 02_。对应 L3：[09_核心模块架构规约](../03_原子目标与规约/_共享规约/09_核心模块架构规约.md) Module D、[01_核心公式与MoE架构规约](../03_原子目标与规约/_共享规约/01_核心公式与MoE架构规约.md)。

---

## 5D-1 Design（设计左移）

### 变量与类型

| 变量/类型 | 说明 |
|-----------|------|
| `quant_signal.technical_score` | 0–100，来自 Module B |
| `quant_signal.win_rate_prediction` | 0.0–1.0 |
| `expert_opinions` | List[ExpertOpinion]；ExpertOpinion 含 is_supported, direction (BULLISH/BEARISH), reasoning_summary |
| `payoff_ratio` | 盈亏比，> 0 |
| `win_rate` | 投票后的综合胜率，0.0–1.0 |
| `kelly_fraction` | 输出 [0.0, 1.0] |

### Kelly 公式（锁死）

```
kelly_fraction = (win_rate × payoff_ratio - (1 - win_rate)) / payoff_ratio
# 约束：kelly_fraction 限制在 [0.0, 1.0]；payoff_ratio <= 0 时按约定返回 0 或 error，不除零
```

### Verdict 结构（判官输出）

- `action`: BUY | PASS
- `win_rate_prediction`: float
- `kelly_fraction`: float
- `primary_reasoning`: string

### 边界与零值

- `payoff_ratio == 0`：不除零，返回 kelly_fraction = 0 或明确 error。
- `win_rate == 0` 或 `win_rate == 1`：公式仍成立，kelly 可能为负或超 1，**必须截断到 [0.0, 1.0]**。
- Quant 得分 = 70：边界算 Pass（> 70 为 Pass，依 09_）。
- 无 Expert 占位（空列表）：仅 Quant Pass 时按 09_ 为「未通过」（Quant Pass + 至少一个 Expert Strong Buy 才有效信号）。

---

## 5D-2 Drive（测试锚定）

Table-Driven 用例（输入 → 期望输出）：

| 用例 | technical_score | win_rate (投票后) | payoff_ratio | expert_opinions 占位 | 期望 action | 期望 kelly_fraction（约） |
|------|-----------------|-------------------|--------------|----------------------|-------------|---------------------------|
| 1 标准通过 | 80 | 0.6 | 2.0 | 至少 1 个 BULLISH+supported | BUY | (0.6*2 - 0.4)/2 = 0.4 |
| 2 Quant 不通过 | 60 | - | - | 任意 | PASS | 0 |
| 3 Expert 不通过 | 85 | - | - | 空或全未 supported | PASS | 0 |
| 4 边界截断 | 75 | 0.9 | 3.0 | 1 个 BULLISH | BUY | min(1.0, (0.9*3-0.1)/3)=1.0 |
| 5 除零防护 | 80 | 0.5 | 0 | 1 个 BULLISH | BUY 或 PASS | 0（不 panic） |

以上 5 行可转为 `_test.go` 的 Table-Driven 用例；先红灯再实现。

---

## 5D-3 Decompose（原子函数）

| 函数/组件 | 职责 | 建议文件/包 |
|-----------|------|-------------|
| `vote(quant_signal, expert_opinions)` | Quant Pass（score>70）+ 至少一个 Expert BULLISH → 有效信号，返回 win_rate 与 action | gavel/voting.go |
| `calcKelly(win_rate, payoff_ratio)` | 凯利公式 + 截断 [0,1]，payoff_ratio<=0 返回 0 | gavel/kelly.go |
| `assembleAlpha(verdict, kelly_fraction)` | 组装 Verdict（含 action, win_rate_prediction, kelly_fraction, primary_reasoning） | gavel/verdict.go 或同包 |

每函数建议 <50 行，可单测。

---

## 5D-4 Defense（人工防御）

- **运行测试**：`go test ./internal/gavel/...` 或 `go test ./diting/gavel/...`（与项目路径一致）；或 `make test` 在 diting-core 根目录。
- **Review 要点**：投票规则与 09_ 一致（Quant>70，Expert 至少一个 BULLISH）；Kelly 公式与 01_ 一致；输出限制 [0,1]；无除零。
- **L5 同步**：本步准出时更新 [05_成功标识与验证/02_验收标准](../05_成功标识与验证/02_验收标准.md) 功能验收表中「09_ Module D」对应行状态。

---

**[TRACEBACK]** 本范例对应 [04_热路径判官风控与执行](Stage3_模块实践/04_热路径判官风控与执行_实践.md)；L3：[09_核心模块架构规约](../03_原子目标与规约/_共享规约/09_核心模块架构规约.md)、[01_核心公式与MoE架构规约](../03_原子目标与规约/_共享规约/01_核心公式与MoE架构规约.md)。
