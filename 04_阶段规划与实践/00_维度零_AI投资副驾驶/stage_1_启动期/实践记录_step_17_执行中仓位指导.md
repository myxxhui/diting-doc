# 实践记录 · step_17 执行中仓位指导（M11）

> **对应 L3**：[step_17_执行中仓位指导.md](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_17_执行中仓位指导.md)
> **波次**：波次三 · 漏斗末端（执行区）
> **状态**：✅ 本机验收通过

---

## 一、目标与交付物

| 交付物 | 状态 |
|---|---|
| A 执行档案：holdings_sot × 实时价 → 浮盈亏 T0 | ✅ |
| B 仓位指导引擎（T0 规则 + 证据）advisor.py | ✅ |
| C execution_advices 表落库 | ✅ |
| D 盘后安全扫描门控（fraud 压制加仓） | ✅ |
| E 了结归档（复用 step_15 archive） | ✅ |
| F 前端执行档案卡 + advisory 建议条 + 归档按钮 | ✅ |
| G 单测 ≥ 12 | ✅ 14 passed |
| H Makefile 8 target | ✅ |

---

## 二、实际进展（已核验）

### 2.1 核心实现

**`apps/copilot/modules/execution/advisor.py`**（新建）：
- T0 规则表覆盖 6 场景：建仓 / 加仓 / 浮盈减仓 / 浮亏止损 / 持有 / 清仓提示
- `_build_advice()` 纯函数：引规划证伪 ok_rate + market_phase + 建仓窗 + safety_status
- `_fetch_realtime_price()` 先查 Redis 缓存 → 再 MarketQuoteClient；限流 → stale 标注
- `_safety_status()` 调 FinancialFraudEngine；vLLM 未就绪 → pending（不伪造）
- fraud → `ADVICE_EXIT`（清仓提示）；pending → `ADVICE_RISK_HOLD`（暂缓加仓）
- `generate_execution_advice()` 写 `execution_advices` + `stage_artifacts(workspace=executing)`
- 阈值全配置驱动：`EXEC_PNL_TAKE_PROFIT_PCT=20` / `EXEC_PNL_STOP_PCT=-10` / `EXEC_MAX_SINGLE_POS_PCT=25`

**`apps/copilot/db/models.py`**：新增 `ExecutionAdvice` ORM 模型（execute_mode='advisory', human_confirmation_required=True）

**`apps/copilot/db/migrate_step17.py`**：建 `execution_advices` 表

**`apps/copilot/routers/planning_routes.py`**：
- `GET /api/campaigns/{id}/execution` — 列出执行建议（JSON + HTML 双模式）
- `POST /api/campaigns/{id}/execution/advise` — 生成/刷新单标的建议

**`apps/copilot/templates/planning/workbench.html`**：
- 「执行中」Tab 新增 ⑩ 执行中仓位指导 Panel：advisory 建议卡 + 生成表单 + 归档按钮

### 2.2 验收数据（本机）

```
# 持仓 × 实时价 × 浮盈亏（真实数据，2026-05-31）
601138 工业富联  实时 ¥73.4  成本 ¥59.34  浮盈 +23.7%  safety=pending → 暂缓加仓
601088 中国神华  实时 ¥46.92 成本 ¥45.82  浮盈 +2.4%   safety=pending → 暂缓加仓
300866 杰美特    实时 ¥125.72 成本 ¥113.69 浮盈 +10.58% safety=pending → 暂缓加仓
```

```bash
# fraud 场景压制加仓（demo 验证）
fraud → advice_action = 重大风险，建议评估清仓
pending → advice_action = 风险未排除，暂缓加仓（advisory）
ok → advice_action = 可考虑加仓
```

```bash
# 单测
pytest tests/copilot/test_execution.py -q
# 14 passed, 1 skipped

# 全套
pytest tests/copilot/ -q
# 149 passed, 4 skipped
```

```bash
# no-auto-execute 审计
rg -i "buy|qmt|auto_trade|order_id|webhook_target|立即|一键|下单" apps/copilot/modules/execution/ apps/copilot/templates/planning/
# 0 命中 ✅
```

### 2.3 §3.5 数据质量矩阵

| # | 维度 | 状态 | 说明 |
|---|---|---|---|
| X1 | 持仓真实（成本/持股/仓位%） | ✅ | holdings_sot 真实数据 |
| X2 | 实时价（stale 标注） | ✅ | MarketQuoteClient 成功获取 |
| X3 | 浮盈亏 T0 算 | ✅ | 23.7%/2.4%/10.58% |
| X4 | 建议带证据链 | ✅ | advice_action+rationale+evidence_chain |
| X5 | 安全扫描门控 fraud 压制加仓 | ✅（pending 显式） | LoRA 未就绪 → pending，不伪造 |
| X6 | no-auto-execute | ✅ | rg=0；schema/模板无下单语义 |
| X7 | 归档回流 | ✅ | POST /archive 可调；long_multiwave 见 step_15 |

---

## 三、no-auto-execute 永久红线审计

| 检查项 | 结果 |
|---|---|
| `execute_mode` 字段值 | advisory |
| `human_confirmation_required` | True（强制） |
| schema 字段 buy/qmt/auto_trade/order_id/webhook_target | 0 命中 |
| 模板按钮含"下单/一键/立即" | 0 命中 |
| API 路由含下单操作 | 0 命中 |

---

## 四、修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-31 | 初版：6 场景仓位引擎 + fraud 安全门控 + execution_advices 表 + 前端 ⑩ Panel + 14 单测通过 |
