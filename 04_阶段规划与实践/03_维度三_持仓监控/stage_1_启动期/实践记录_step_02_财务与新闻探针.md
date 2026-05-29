# 实践记录 · 维度三·持仓监控 · step_02 · 财务与新闻探针

> [!NOTE] **[TRACEBACK]**
> - **L3**: [step_02_财务与新闻探针.md](../../../03_原子目标与规约/03_维度三_持仓监控/stages/stage_1_启动期/steps/step_02_财务与新闻探针.md)
> - **DNA**: [_System_DNA/03_holding_watch/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/03_holding_watch/dna_stage_1_启动期.yaml)
> - **看板**: [README.md](./README.md)

---

## 一、本步计划

- P1 财务探针 + P2 新闻探针；AKShare/stub 与 cryo 公告库；CLI 与 pytest。

## 二、实际进展

| 项 | 状态 | 说明 |
|---|---|---|
| `apps/state_watch/probes/` | ✅ | `base_probe`、`financial`、`news`、`datasource/akshare_adapter`、`datasource/news_adapter` |
| **P1 主 API 切换** | ✅ | `stock_financial_analysis_indicator` 已失效 → 改用 **`stock_financial_abstract`**（source=`akshare_abstract`） |
| **P2 公告真流** | ✅ | `news_adapter` 读 `data/cryo_guard.db` · `announcements` 表（D1 巨潮采集）；无近 7 日条目时 `total_count_7d=0` 为**披露空窗预期**，非 mock |
| `pyproject.toml` | ✅ | 增加 `feedparser`、`jieba` |
| pytest | ✅ | `test_probe_financial.py` + `test_probe_news.py` **18 passed** |
| **W2 P1 真流批量** | ✅ | `make watch-step02-financial-once` → **10/10 ok，avg_coverage=1.0**（SoT 4 portfolio + 6 watchlist） |
| **W2 P2 真流批量** | ✅ | `make watch-step02-news-once` → **10/10 ok**；cryo 公告已补采 10 只（300866/601899 由 0→139 条）；7 日窗：300308=1，4 只 portfolio 当前 0（最近公告 05-09~04-30，属披露空窗） |
| **W2 Makefile 合约** | ✅ | `watch-step02-*` 7 target；`scripts/watch_step02_run.py` |
| **W2 monitor_dict 消费端** | ✅ | `monitor_dict_reader.py` + `/api/monitor-dict/{symbol}` 路由 |

## 三、测试运行

```bash
cd diting-src
make watch-step02-all
# P1: {"total":10,"ok":10,"avg_coverage":1.0}
# P2: {"total":10,"ok":10}  # total_count_7d 当前全 0（7 日空窗）
# pytest: 18 passed

PYTHONPATH=. python3 -m pytest tests/state_watch/test_probe_financial.py tests/state_watch/test_probe_news.py -v
```

## 四、手工 CLI（可选）

```bash
cd diting-src
PYTHONPATH=. python3 -m apps.state_watch.probes.financial --symbol 601138
PYTHONPATH=. python3 -m apps.state_watch.probes.news --symbol 601138
```

## 五、下一步

- [step_03_价格与事件探针.md](../../../03_原子目标与规约/03_维度三_持仓监控/stages/stage_1_启动期/steps/step_03_价格与事件探针.md)

## 六、W2 与节奏表

- 日历行准出：[14 · W2 行准出核验](../../../03_原子目标与规约/_共享规约/14_六维度启动期统一节奏表.md#w2-行准出核验)
