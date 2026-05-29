# 实践记录 · 维度四·卖出决策 · step_02 · 持仓数据接入与行情

> [!NOTE] **[TRACEBACK]**
> - **L3**: [step_02_持仓数据接入与行情.md](../../../03_原子目标与规约/04_维度四_卖出决策/stages/stage_1_启动期/steps/step_02_持仓数据接入与行情.md)
> - **DNA**: [_System_DNA/04_exit_engine/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/04_exit_engine/dna_stage_1_启动期.yaml)
> - **规约 21**: [21_行情数据源降级与断路器规约](../../../03_原子目标与规约/_共享规约/21_行情数据源降级与断路器规约.md)
> - **看板**: [README.md](./README.md)

---

## 一、本步计划

- `holdings_repo`、`QuoteFetcher`/mock、30min 调度、`PortfolioService`、`/api/portfolio/{user_id}`、seed 与 pytest。

## 二、实际进展

| 项 | 状态 | 说明 |
|---|---|---|
| `apps/exit_engine/data/` | ✅ | `holdings_repo`、`quote_fetcher`（薄壳 → `apps/common/market_quote`） |
| `apps/common/market_quote/` | ✅ | 腾讯/新浪/东财降级链 + 断路器；**移除 akshare 行情依赖** |
| `apps/exit_engine/services/` | ✅ | `quote_scheduler`、`portfolio_service` |
| **SoT 双角色** | ✅ | `portfolio` 4 只真实持仓 + `watchlist` 6 只关注；**D4 仅 sync portfolio** |
| pytest | ✅ | holdings + quote + scheduler **20 passed** |
| **W2 SoT 同步** | ✅ | `sync_positions_from_sot` → **4/4 portfolio synced**（601138/601088/300866/601899） |
| **W2 行情刷新** | ✅ | `make exit-step02-update-once` → **4/4 updated**（腾讯源 ~0.5s）；样例：601138=67.16、601088=44.98、300866=127.89、601899=30.96 |
| **真实持仓** | ✅ | `my_holdings.yaml` 已填券商 APP 真实 quantity/cost_price（4 只 portfolio） |

## 三、测试与命令

```bash
cd diting-src
make exit-step02-all
# synced=4 portfolio=[601138,601088,300866,601899]
# 刷新完成: total=4 updated=4
# pytest: 20 passed

PYTHONPATH=. python3 -m pytest tests/exit_engine/test_quote_fetcher.py tests/common/market_quote/ -q
# market_quote 21 passed
```

## 四、偏离与决策

- `holdings_repo` 使用 SQLAlchemy 2.0 `select`/`update` 风格。
- 行情走规约 21 的 `MarketQuoteClient`（腾讯 list 优先），东财 hist 仅作降级；不再依赖 akshare spot。
- watchlist 标的不进 D4 持仓表，仅 D1/D3 消费。

## 五、下一步

- [step_03_SP1止损协议.md](../../../03_原子目标与规约/04_维度四_卖出决策/stages/stage_1_启动期/steps/step_03_SP1止损协议.md)

## 六、W2 与节奏表

- 日历行准出：[14 · W2 行准出核验](../../../03_原子目标与规约/_共享规约/14_六维度启动期统一节奏表.md#w2-行准出核验)
