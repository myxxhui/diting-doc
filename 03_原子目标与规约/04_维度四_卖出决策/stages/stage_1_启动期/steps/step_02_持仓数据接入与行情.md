# Step 02 · 持仓数据接入与实时行情

## §1 一句话定位与本步交付物

**一句话**：把 **持仓 SoT** (`my_holdings.yaml` 含 `cost_price/qty/holding_ratio`) 装载到 `positions` 表 + 接入 **行情适配器**（AKShare 日线 + 实时报价；非交易时段返 last_close）+ **PositionUpdater**（每 30min 刷 current_price / holding_ratio / unrealized_pnl）；为 SP1~SP4 提供输入。

**交付物**（勾选 = 完成）：
- [ ] **A**（SoT 加载）：`holdings_loader.py` 复用 D1/D2/D3 同源 `apps/common/holdings_sot.py`；只取 `active=true`
- [ ] **B**（行情适配）：`market/quote_adapter.py`（AKShare 实时 + 日线兜底）；交易时段过滤
- [ ] **C**（`PositionUpdater`）：APScheduler 30min；非交易时段不写新行情
- [ ] **D**（API）：`POST /api/positions/sync`（从 SoT 全量同步）；`GET /api/positions`（列表 + 关键指标）；`GET /api/positions/{symbol}`
- [ ] **E**（quantity vs cash 兼容）：启动期 `qty` 与 `holding_ratio` 二选一，缺失自动算
- [ ] **F**（单测）：≥10；含限频降级、非交易时段
- [ ] **G**（Makefile）：`make exit-step02-all`

> **持仓 SoT 唯一来源**：`MY_HOLDINGS_YAML`；**禁止**硬编码或写 stub 行情入业务库。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §3.1 持仓接入
> - **DNA**：`tech_stack.rule_engine`、`dependencies.upstream`
> - **持仓 SoT**：`diting-src/data/config/my_holdings.yaml`（**含 `role: portfolio/watchlist` 拆分**；仅 `portfolio` 进本 step 卖出引擎，`watchlist` 走 D1/D3）
> - **行情入口规约**：[../../../../../03_原子目标与规约/_共享规约/21_行情数据源降级与断路器规约.md](../../../../_共享规约/21_行情数据源降级与断路器规约.md)（**取代 akshare hist 全失败方案**；本 step 行情适配器以此为权威）
> - **L4**：[实践记录_step_02_持仓数据接入与行情.md](../../../../../04_阶段规划与实践/04_维度四_卖出决策/stage_1_启动期/实践记录_step_02_持仓数据接入与行情.md)
> - **上游**：step_01；**下游**：step_03~07

## §3 数据采集对象 / 落库映射

| 对象 | 表 | 字段 |
|---|---|---|
| 持仓 SoT 装载 | `positions` | symbol/cost_price/qty/holding_ratio/thesis_id/entered_at |
| 行情更新 | `positions.current_price`、`unrealized_pnl`、`updated_at` |（同表 upsert）|
| 行情快照（可选）| `price_snapshots` | symbol, price, ts |

## §3.5 数据质量验收矩阵（持仓与行情 · 仅启动期）

### §3.5.1 持仓 SoT 装载

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| H1 | **唯一来源** | MY_HOLDINGS_YAML；缺失 BLOCK | ✅ | 不接受其他源 |
| H2 | **active 过滤** | `active=true` only | ✅ | — |
| H3 | **必填字段** | symbol、cost_price 必填；qty 或 holding_ratio 至少一项 | ✅ | 都缺 reject + ADR |
| H4 | **变更同步** | SoT 改后 `POST /api/positions/sync` 可重入 | ✅ upsert | 删除标的→soft delete |

### §3.5.2 行情质量

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| Q1 | **current_price 新鲜度** | 交易日内更新间隔 ≤30min | ✅ | 非交易日跳过 |
| Q2 | **non-trading 标记** | 非交易时段 last_close 复用并标 `closed_market=true` | ✅ | — |
| Q3 | **限频降级** | AKShare 失败 3 次后回退日线 | ✅ | — |
| Q4 | **unrealized_pnl** | (cur-cost)/cost；展示用 | ✅ | qty 缺则不展示金额 |
| Q5 | **holding_ratio** | 单只市值/总市值 | ✅ | 缺总市值则由 SoT 提供基准 |

### §3.5.3 工程

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **idempotent sync** | 同 symbol 不重复行 | ✅ | — |
| E2 | **API 全 active 列表** | GET /api/positions | ✅ | — |
| E3 | **stub-free** | 业务库不入假行情 | ✅ | tests/ 例外 |
| E4 | **scheduler 健康** | next_run 可读 | ✅ | — |

> 共 **13 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| `MY_HOLDINGS_YAML` | 必须 |
| AKShare（无 key）| 行情 |
| 持仓 SoT active≥1 | 必须 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| positions 行数 | =SoT active 数 |
| current_price 新鲜度（交易日）| ≤30min |
| 单测 | ≥10 |

## §6 下一步

本步 ✅ → step_03 SP1 止损协议。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A SoT loader** | `holdings_loader.py` | 复用 apps/common/holdings_sot | 装载数 |
| **B quote_adapter** | `market/quote_adapter.py` | 实时+日线降级；交易日历 | 1 标的 |
| **C PositionUpdater** | `market/updater.py` | APScheduler 30min | next_run |
| **D API routes** | `api/routes/positions.py` | sync/list/get | curl 200 |
| **E unrealized_pnl** | service 层计算 | 公式见 §3.5 | 单测 |
| **F 单测** | `test_positions.py` | ≥10 | pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `exit-step02-prep` | SoT 存在 + AKShare ping |
| `exit-step02-sync` | POST sync；行数=active 数 |
| `exit-step02-update-once` | PositionUpdater run_once；price 更新 |
| `exit-step02-list` | GET positions；JSON OK |
| `exit-step02-test` | pytest ≥10 |
| `exit-step02-all` | sync+update+list+test |
| `exit-step02-status` | 最近行情时间 + active 数 |
| `exit-step02-clean` | dev FORCE=1 |

### §7.3 关键代码片段（中间道）

#### 7.3.1 SoT 持仓 loader（核心 ~12 行）

```python
async def sync_positions_from_sot(session: AsyncSession) -> dict:
    """从 my_holdings.yaml 全量同步到 positions 表（可重入 upsert）。"""
    from apps.common.holdings_sot import load_holdings_active
    holdings = load_holdings_active()           # [{symbol, cost_price, qty?, holding_ratio?, thesis_id?}]
    if not holdings:
        raise RuntimeError("BLOCKED: 0 active in MY_HOLDINGS_YAML")
    n_new, n_upd, n_softdel = 0, 0, 0
    active_symbols = {h["symbol"] for h in holdings}
    for h in holdings:
        if not h.get("cost_price"):
            raise ValueError(f"{h['symbol']}: cost_price required")
        if not h.get("qty") and not h.get("holding_ratio"):
            raise ValueError(f"{h['symbol']}: qty or holding_ratio required")
        await upsert_position(session, h)
    # SoT 中删除的标的 → soft delete（保留 sell_signals 关联）
    n_softdel = await soft_delete_missing(session, keep=active_symbols)
    await session.commit()
    return {"new_or_updated": n_new + n_upd, "soft_deleted": n_softdel}
```

#### 7.3.2 行情适配器双源降级（核心 ~12 行）

```python
class QuoteAdapter:
    async def get_realtime(self, symbol: str) -> dict:
        """实时报价；失败 3 次后回退日线 last_close。"""
        if not is_trading_session():
            return {**(await self.get_last_close(symbol)), "closed_market": True}
        for attempt in range(3):
            try:
                quote = await akshare_realtime(symbol)
                return {"price": quote["current"], "ts": quote["ts"],
                        "source": "akshare_realtime", "closed_market": False}
            except (RateLimitError, NetworkError) as e:
                if attempt == 2:
                    fallback = await self.get_last_close(symbol)
                    return {**fallback, "stale": True, "fallback_reason": str(e)}
                await asyncio.sleep(2 ** attempt)
```

#### 7.3.3 PositionUpdater APScheduler 注册（核心 ~12 行）

```python
class PositionUpdater:
    def __init__(self, adapter: QuoteAdapter, session_factory):
        self.adapter = adapter
        self.session_factory = session_factory

    async def run_once(self):
        async with self.session_factory() as session:
            positions = await session.execute(select(Position).where(Position.deleted_at.is_(None)))
            for pos in positions.scalars():
                quote = await self.adapter.get_realtime(pos.symbol)
                if quote.get("closed_market"):
                    continue                            # 非交易时段不刷
                pos.current_price = quote["price"]
                pos.unrealized_pnl = (quote["price"] - pos.cost_price) / pos.cost_price
                pos.updated_at = utcnow()
            await session.commit()

# 注册：scheduler.add_job(updater.run_once, IntervalTrigger(minutes=30),
#                       id="position_updater", next_run_time=datetime.now())
```

#### 7.3.4 GET /api/positions 响应 schema（核心 ~10 行）

```json
{
  "total": 4,
  "closed_market": false,
  "positions": [
    {
      "symbol": "600519",
      "cost_price": 1680.0,
      "current_price": 1620.5,
      "qty": 100,
      "holding_ratio": 0.25,
      "unrealized_pnl": -0.0354,
      "thesis_id": "thesis_20260301_kweichow",
      "updated_at": "2026-05-21T10:30:00+08:00"
    }
  ]
}
```

### §7.4 指引

先 loader→adapter→updater→API；交易日历用 AKShare `trade_cal`；删除 SoT 标的须 soft delete（保留历史 sell_signals 关联）。

## §8 部署节奏

本机；K3s 扩展期合并 exit-engine Pod。

## §9 准出标准

- [ ] §3.5 13 项；行数=active；新鲜度达标
- [ ] `make exit-step02-all`；L4 回写

## §10 [Deploy]

启动期本机；后续与 updater 合并部署。

## §11 依赖

step_01；SoT；AKShare。

**严禁**：stub 行情入库；硬编码持仓。

## §12 风险

| 触发 | 动作 |
|---|---|
| AKShare 限频 | 日线兜底 + 标 stale |
| SoT 字段缺失 | reject + ADR |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v3 中间道细化**：保留 v2 §3.5 13 项；§7.3 新增 4 个关键片段（SoT 持仓 loader + 必填字段校验 + soft delete / QuoteAdapter 双源降级 + 限频回退 / PositionUpdater APScheduler 30min / GET /api/positions JSON schema）；150→~330 行 |
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 1022 行；§3.5 13 项；SoT；`exit-step02-*`；1022→~220 行 |
| 2026-05-16 | 初版 1022 行 |
