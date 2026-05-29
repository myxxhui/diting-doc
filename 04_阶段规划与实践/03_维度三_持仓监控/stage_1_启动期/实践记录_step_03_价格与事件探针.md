# 实践记录 · 维度三·持仓监控 · 启动期 · step_03 · P3 价格 + P4 事件探针

> [!NOTE] **[TRACEBACK] 实践锚点**
> - **L3 step**: [step_03_价格与事件探针.md](../../../03_原子目标与规约/03_维度三_持仓监控/stages/stage_1_启动期/steps/step_03_价格与事件探针.md)
> - **DNA**: [_System_DNA/03_holding_watch/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/03_holding_watch/dna_stage_1_启动期.yaml)
> - **本阶段看板**: [README.md](./README.md)

---

## 一、本步计划（来自 L3）

- 目标：P3 价格探针（衍生指标 + CLI）、P4 事件探针（读 cryo DB + CLI）、`quote_adapter` / `announcement_adapter`、`scheduler_skeleton`（APScheduler 注册 + `--once`）、`pytest` 覆盖价格/事件单测；**K 线默认规约 21 MarketQuote（腾讯 fqkline 优先，东财 akshare 末级降级）**；集成测试不再全局 `STATE_WATCH_QUOTE_STUB`。

---

## 二、实际进展（W3 · Composer · 已核验）

| §3.x / 项 | 状态 | 说明 |
|---|---|---|
| `quote_adapter.py` | ✅ | **MarketQuoteClient（规约 21）优先** → akshare → stub |
| `scripts/watch_step03_run.py` | ✅ | P3/P4 批量 + 交易窗 + P5~P7 占位 |
| Makefile `watch-step03-*` | ✅ | 含 physical-p5~p7 占位 target |
| **`make watch-step03-all`** | ✅ | P3+P4 **10/10** + 交易窗 + physical 占位 + **20 pytest passed** |

```bash
cd diting-src && make watch-step03-all
```

P5~P7 物理探针已在 W3 Opus + W3补完 Session 1 接入真流，见下节。

---

## 三、P5/P6/P7 物理探针真流结果（W3补完 · 启动期准出口径）

### 3.1 执行结果汇总

| 探针 | 触发方式 | 10 只 watchlist 结果 | 说明 |
|------|---------|----------------------|------|
| **P5 TenderProbe** | `make watch-step03-physical-p5` | 7/10 `ok`（600312/601138/300308 等）；3/10 `upstream_pending`（002837/300499/300602） | 这 3 只 ccgp 公告通道近期无招标数据，设计上应为 `upstream_pending`（B1 补采中） |
| **P6 CustomsProbe** | `make watch-step03-physical-p6` | 全 10 只 `data_unavailable` | AKShare 宏观接口超时；启动期降级路径（L3 §PC1）；⚠️ 可接受 |
| **P7 CapacityProbe** | `make watch-step03-physical-p7` | 部分 `ok`，部分 `extraction_failed` | 公告中无"产能利用率"标准句式时规则不命中；⚠️ 启动期可接受 |

### 3.2 启动期可接受状态说明（B3 口径确认）

> **L3 §3.5.4 已明确**：启动期物理探针的降级路径为：
> - P5：`upstream_pending` ← ccgp 通道未就绪（非 bug，是数据前置问题）
> - P6：`data_unavailable` ← AKShare 宏观接口不稳定（L3 §PC1 启动期降级路径）
> - P7：`extraction_failed` ← 公告正文无标准句式（启动期纯规则阶段；扩展期接小模型）

以上三种状态**不算探针故障**，不触发告警，不阻塞 `physical-all`，写 metric=unknown，等待数据就绪/扩展期升级。

### 3.3 W3补完 Session 1 代码修复（B2/B3）

| 修复项 | 文件 | 内容 |
|--------|------|------|
| **B2 P6 超时** | `p6_customs.py` | `_AKSHARE_CALL_TIMEOUT=8s`；每次 `run_in_executor` 独立 `asyncio.wait_for(8s)`；`retry_max=0`；双源超时→`data_unavailable`（最坏 16s，不再 90s 卡死） |
| **B3 P7 扩正则** | `p7_capacity.py` | 新增 `满产率/满开率/产能开工率/产线开工率/生产利用率`；增加反向措辞正则（"约XX%满产"）；`_extract_utilization` 双正则兜底；36 pytest passed |
| **B1 P5 数据刷新** | `crawl_announcements.py` 批量补 ccgp | 002837/300499/300602 三只补 2026 新公告；P5 重跑 → 无 `upstream_pending`（status=ok, hit_count=0 是「无招标」的诚实结论，非 bug） |

---

## 四、W3 补完 Session 2 · B4 监控字典消费端（已核验）

> **口径**：实现共享规约 20 §五消费端契约 MC1～MC5，把 Architect 写入 Redis 的 `monitor:{symbol}:dict:*` 接到 P5/P7 探针。

### 4.1 实现要点

| 项 | 文件 | 内容 |
|---|---|---|
| `MonitorDictReader` | `apps/state_watch/probes/monitor_dict_reader.py` | MC1 `has_dict()` / MC3 `mark_field_hit()` / MC5 只读业务字段；`fields_for_probe(symbol, "P5"\|"P7")` 按 probe_id 过滤；`aggregate_keywords/source_urls` 聚合工具 |
| `TenderProbe.__init__(monitor_keywords)` | `physical/p5_tender.py` | 默认招标关键词 + 监控字典关键词 OR 合并（regex 模式拼装）；返回中含 `monitor_keywords_used` |
| `CapacityProbe.__init__(monitor_keywords)` | `physical/p7_capacity.py` | 命中字典关键词的公告优先送入产能利用率抽取；返回中含 `monitor_keywords_used` + `hit_via_monitor_keyword` |
| 单测 | `tests/state_watch/test_monitor_dict_reader.py` | 11 case：MC1 不阻塞 / 按 probe 过滤 / only_active / `mark_field_hit` 不动业务字段 / 聚合工具 / **E2E 注入到 TenderProbe/CapacityProbe** |
| E2E 脚本 | `scripts/monitor_dict_e2e.py` | `--symbol 300308` 跑通 `MonitorDictReader → P5/P7 真流`；输出含 `fields_summary` + `probe_result.monitor_keywords_used` |

### 4.2 E2E 验证结果（300308 + 600312）

```bash
cd diting-src
PYTHONPATH=. python3 scripts/monitor_dict_e2e.py --symbol 300308
# → has_dict=true, _meta.count=3, P7 字段 2 个，14 个 keywords 注入 CapacityProbe
# → monitor_keywords_used = [光模块,光收发器,400G光模块,800G光模块,1.6T光模块,
#                            中际旭创,光收发合一,集采,智算中心,东数西算,...]

PYTHONPATH=. python3 scripts/monitor_dict_e2e.py --symbol 600312
# → has_dict=true, _meta.count=4, P5 字段 1 + P7 字段 2
# → P5 monitor_keywords_used = []（架构师未设 P5 关键词，符合预期）
# → P7 monitor_keywords_used 含 15 个特高压/电网投资关键词
```

### 4.3 复测命令

```bash
cd diting-src
PYTHONPATH=. python3 -m pytest tests/state_watch/test_monitor_dict_reader.py tests/state_watch/test_physical_probes.py -q
# → 47 passed in 0.29s
```

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-17 | 初稿：P3/P4 + scheduler_skeleton + pytest |
| 2026-05-23 | **W3 Composer**：quote 接规约 21 + Makefile + `watch-step03-all` 同会话通过 |
| 2026-05-23 | **no-mock 重验**：去掉随机 K 线 stub + 静默 adapter stub；`make watch-step03-test` 18 passed；2 个外部数据依赖失败（`test_fetch_returns_keys` akshare 非交易时段断连、`test_known_with_events` 999999 无惩罚记录）= **真源未就绪，非 bug**；P3 行情在交易时段可恢复 |
| 2026-05-24 | **K 线默认腾讯**：移除 conftest 全局 stub；`quote_adapter` 腾讯/新浪优先、东财 akshare 末级降级（8s 超时）；集成测试改 SoT `601138`；`watch-step03-test` **20 passed in ~1.5s**（原 ~15min） |
| 2026-05-24 | **W3补完 B2/B3**：P6 `_AKSHARE_CALL_TIMEOUT=8s` + `retry_max=0`（最坏 16s，不再 90s 卡死）；P7 扩正则（满产率/产线开工率/反向措辞）；L4 §三 写入 P5/P6/P7 启动期准出口径（upstream_pending / data_unavailable / extraction_failed 均为 ⚠️ 可接受状态，不算故障）；**36 pytest passed** |
| 2026-05-24 | **W3 补完 Session 2 · B4 监控字典消费端**：①新增 `MonitorDictReader`（共享规约 20 §五 MC1～MC5 完整实现）；②`TenderProbe` / `CapacityProbe` 接受 `monitor_keywords` 增强匹配（regex 合并 / 优先送抽取）；③`scripts/monitor_dict_e2e.py` E2E 验 300308 + 600312 真流跑通；④L4 §四 写入完整证据链。**复验**：`pytest test_monitor_dict_reader.py + test_physical_probes.py` → **47 passed** |
