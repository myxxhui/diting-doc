# Step 03 · 价格探针（P3·30min）+ 事件探针（P4·6h）+ [L-α] 物理量探针 P5 招标 / P6 海关 / P7 产能

## §1 一句话定位与本步交付物

**一句话**：实现 **P3 价格探针**（30min，6 metric：日涨跌/60d 回撤/换手/量比/RSI/MA 偏离）+ **P4 事件探针**（6h，5 metric：大股东减持/股权质押/高管变更/重大诉讼/监管处罚）；**[L-α] 同时**实现 **P5 招标物理量探针**（24h，按持仓 SoT × Redis 监控字典中的 focus_keywords 抓 ccgp.gov.cn 中标公告，输出"近 30 天命中招标条数 / 累计中标金额 / 月度环比"三色信号）+ **P6 海关数据探针**（月度，按 HS Code 抓取持仓所在行业月度进出口量，三色信号）+ **P7 产能利用率探针**（季度，从公告/调研纪要文本规则抽取产能利用率/扩产计划，三色信号）；APScheduler 注册脚手架（完整调度器在 step_04）。

**交付物**（勾选 = 完成）：
- [ ] **A**（`quote_adapter`）：行情接入；交易时段过滤
- [ ] **B**（`announcement_adapter`）：巨潮公告 + 适配大股东减持/质押/高管/诉讼/处罚 5 类
- [ ] **C**（P3 price）：纯函数 RSI/drawdown/MA；非交易时段空跑标 `closed_market`
- [ ] **D**（P4 event）：5 metric 聚合；按窗口去重
- [ ] **E**（scheduler_skeleton）：注册 P3/P4/P5/P6/P7 占位（step_04 合并）
- [ ] **F**（单测）：≥10；含 RSI 边界、回撤计算；**[L-α]** + ≥6 物理量探针（三色阈值边界 / 监控字典联动 / 三探针均空 fallback）
- [ ] **G**（Makefile）：`make watch-step03-all`（含 P3~P7）
- [ ] **[L-α] H 物理量探针 P5 招标** | 24h | metric: `tender_hit_count_30d / tender_amount_total_30d / tender_mom_change` | 数据源: ccgp.gov.cn Playwright + 复用 D2 嗅探层 raw_text；按 Redis `monitor:{symbol}:dict:physical.focus_keywords` 过滤命中；**三色信号** (`physical_signal: green/yellow/red`) 阈值来自 `configs/physical_probes.yaml`
- [ ] **[L-α] I 物理量探针 P6 海关** | 月度 | metric: `customs_export_volume_mom / customs_import_volume_mom / customs_yoy_change` | 数据源: 海关总署月度统计 + 行业协会数据 + AKShare 海关接口；按持仓行业 HS Code 聚合；三色信号
- [ ] **[L-α] J 物理量探针 P7 产能** | 季度 | metric: `capacity_utilization_pct / expansion_capex_announce / capacity_qoq_change` | 数据源: 上市公司公告（业绩说明会纪要 + 投资者关系 Q&A）+ 行业研报 PDF 规则抽取；三色信号
- [ ] **[L-α] K PhysicalProbeAlertEvent** | Redis Stream `events:monitor:physical_alert` 投递 `{symbol, probe_id, physical_signal, value, threshold, evidence_url, recorded_at}`；被 D0 副驾驶持仓体检 + D4 SP3/SP5 协议消费

> **数据**：行情用 AKShare 日线；事件来自巨潮 + AKShare 高管/质押接口；**禁止** stub 写库。
> **[L-α] 数据**：P5 复用 D2 嗅探层 ccgp 抓取通道（共享规约 18）；P6 月度数据本机调用 AKShare 海关接口 + 行业协会；P7 文本规则抽取（启动期纯规则，扩展期可接小模型）；**禁止**伪造物理信号；**禁止**绕过监控字典直接全市场无差别抓取。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../03_数据采集与预处理.md](../03_数据采集与预处理.md) §2.3/§2.4
> - **DNA**：`deliverables.sli_probes[2]`（P3 0.5h）+ `[3]`（P4 6h）
> - **L4**：[实践记录_step_03_价格与事件探针.md](../../../../../04_阶段规划与实践/03_维度三_持仓监控/stage_1_启动期/实践记录_step_03_价格与事件探针.md)
> - **上游**：step_01、step_02 datasource 目录；**下游**：step_04 完整 Scheduler

## §3 数据采集对象 / 落库映射

| 探针 | 数据源 | 频率 | metric |
|---|---|---|---|
| P3 price | AKShare 日线/分钟 | 30min（交易时段）| `pct_change_1d / drawdown_60d / turnover_pct / vol_ratio_20d / rsi_14 / ma_deviation_20d` |
| P4 event | 巨潮公告 + AKShare | 6h | `major_reduce_30d / pledge_ratio / exec_change_count_90d / litigation_count_180d / penalty_count_180d` |
| **[L-α] P5 tender** | ccgp.gov.cn Playwright + D2 sniffer_raw_text 共表 + 监控字典 focus_keywords | 24h | `tender_hit_count_30d / tender_amount_total_30d / tender_mom_change / physical_signal{green,yellow,red}` |
| **[L-α] P6 customs** | 海关总署月度 + AKShare 海关 + 行业协会 | 月度（每月 5 号）| `customs_export_volume_mom / customs_import_volume_mom / customs_yoy_change / physical_signal` |
| **[L-α] P7 capacity** | 上市公司公告（业绩说明会 + 投资者关系）+ 行业研报 PDF | 季度（财报日后 30 天内）| `capacity_utilization_pct / expansion_capex_announce / capacity_qoq_change / physical_signal` |

落库：`node_sli_values`（同 step_02）；**[L-α]** P5/P6/P7 metric 额外落 `physical_probe_records(symbol, probe_id, physical_signal, value, threshold_yaml_version, evidence_url, recorded_at)` 表用于审计追溯。

## §3.5 数据质量验收矩阵（价格与事件 · 仅启动期）

### §3.5.1 P3 价格质量

| # | metric | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| Q1 | **pct_change_1d** | (close-prev_close)/prev_close；交易日 | ✅ | 非交易日 skip+标 |
| Q2 | **drawdown_60d** | (close-max60d)/max60d | ✅ ≥60d 历史 | <60d 用 since-listed |
| Q3 | **turnover_pct** | 换手率 % | ✅ | 缺则 null |
| Q4 | **vol_ratio_20d** | 当日量/20d 均量 | ✅ | — |
| Q5 | **rsi_14** | 14日 Wilder | ✅ ≥15d 历史 | <15d 标 insufficient |
| Q6 | **ma_deviation_20d** | (close-ma20)/ma20 | ✅ | — |
| Q7 | **交易时段** | APScheduler 仅工作日 9:30-15:00 触发 | ✅ | 非时段跑也 OK（标 closed）|

### §3.5.2 P4 事件质量

| # | metric | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| V1 | **major_reduce_30d** | 5%以上股东 30d 减持比例之和 | ⚠️ AKShare 高管变更接口 | 接口失败→retry+ADR |
| V2 | **pledge_ratio** | 最新质押比例 | ⚠️ | 缺接口→巨潮文本兜底 |
| V3 | **exec_change_count_90d** | 90d 高管变更条数 | ✅ | — |
| V4 | **litigation_count_180d** | 180d 重大诉讼条数（含被告/原告标记）| ⚠️ 巨潮文本规则 | 漏检率<20% 即可 |
| V5 | **penalty_count_180d** | 180d 监管处罚条数 | ⚠️ | 同 V4 |
| V6 | **去重** | 公告 url hash 唯一 | ✅ | — |

### §3.5.3 工程

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **APScheduler 触发** | CronTrigger / IntervalTrigger 与 DNA 一致 | ✅ | — |
| E2 | **idempotent** | 同 (node, metric, day/window) upsert | ✅ | — |
| E3 | **非交易日** | P3 标 closed_market 不报错 | ✅ | — |
| E4 | **stub-free** | 不向业务库写假行情 | ✅ tests fixture 例外 | — |

### §3.5.4 [Lighthouse-Alpha] 物理量探针 P5/P6/P7

#### §3.5.4.1 P5 招标质量

| # | metric | 必产标准 | 启动期 | 降级 |
|---|---|---|---|---|
| PT1 | **tender_hit_count_30d** | 监控字典命中 + ccgp 抓取去重；近 30 天累计 | ⚠️ 依赖 D2 嗅探层 ccgp 通道就绪 | 通道未通 → P5 标 `upstream_pending` 不写 metric（不阻塞）|
| PT2 | **tender_amount_total_30d** | 累计中标金额（亿元）；正则抽取金额字段 | ⚠️ 金额字段不规范 30% | 抽取失败 → 仅记 count 不记 amount |
| PT3 | **三色信号** | green: 同比上月增长 > 30%；yellow: ±30% 内；red: 下降 > 50% 持续 2 月；阈值来自 `configs/physical_probes.yaml` | ✅ 与 DNA `physical_probes.yaml::p5_tender.thresholds` 一致 | yaml 缺失 → 不算 signal 仅记原始值 |
| PT4 | **evidence_url 留痕** | 每条信号至少 3 个 ccgp 公告 url 作为可点击证据 | ✅ | 抽取失败 → 不投告警 |

#### §3.5.4.2 P6 海关质量

| # | metric | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| PC1 | **HS Code 映射** | 持仓行业 → HS Code（如新能源车=87038040，光伏=854140）；映射表 `configs/industry_hs_code.yaml` | ⚠️ 启动期映射表覆盖率 70%（10 行业）| 缺映射 → P6 不跑 |
| PC2 | **customs_export_volume_mom** | 行业月度出口量（吨/件）；按 HS Code 聚合 | ⚠️ 海关接口延迟 | 缺月 → 用上月+标 `stale` |
| PC3 | **三色信号** | green: 同比+15% / yellow: ±15% / red: -25%+持续 2 月 | ✅ DNA 阈值一致 | — |
| PC4 | **数据源备份** | AKShare 海关接口失败 → 切行业协会公开数据 | ⚠️ 协会数据延迟 | 双源都失败 → 标 `data_unavailable` |

#### §3.5.4.3 P7 产能质量

| # | metric | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| PP1 | **capacity_utilization_pct** | 公告文本规则抽取：业绩说明会纪要 / 投资者关系 Q&A 含"产能利用率/开工率/X%"模式 | ⚠️ 启动期文本规则准确率 70% | 抽取失败 → 标 `extraction_failed` 不写 |
| PP2 | **expansion_capex_announce** | 抽取"投资 X 亿建 Y 万吨/X GW"模式金额 + 容量 | ⚠️ | 模式不匹配 → 跳过 |
| PP3 | **三色信号** | green: 利用率 > 90% 且无扩产；yellow: 70~90%；red: < 70% 或扩产 +50% 容量（产能过剩信号）| ✅ DNA 阈值 | — |
| PP4 | **季度节奏** | 每季度财报日后 30 天内运行 1 次 | ✅ APScheduler | 财报推迟 → 仍在原 cron 等数据 |

#### §3.5.4.4 三探针通用要求

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| PG1 | **PhysicalProbeAlertEvent 投递** | Redis Stream `events:monitor:physical_alert`；yellow/red 必投；green 仅写库不投 | ✅ | Redis 不可用 → 落本地队列 retry |
| PG2 | **三探针均空 fallback** | 若 P5/P6/P7 都因数据缺失未产 signal，**不**告警；保持 status_quo 不变 D0 体检卡显示 | ✅ | — |
| PG3 | **D0 持仓体检卡渲染** | API `/api/holding-watch/physical/{symbol}` 返三探针最近信号 + evidence_url | ✅ | 缺则不渲染该卡区块 |
| PG4 | **配置驱动** | 阈值/HS Code/keywords 全部 yaml 化；增减探针不改代码 | ✅ | — |
| PG5 | **可观察** | `make watch-step03-physical-status` 输出三探针最近 1 周信号矩阵 | ✅ | — |

> 共 **17 项原有 + 17 项 Lighthouse-Alpha = 34 项**（PT1~4 + PC1~4 + PP1~4 + PG1~5）。
> [Lighthouse-Alpha] 对齐 L2 P05 「物理量探针阈值矩阵」+ DNA `_System_DNA/03_holding_watch/physical_probes.yaml`（待新增）+ 共享规约 20 监控字典。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| AKShare | P3 行情 + P4 高管/质押 |
| 巨潮公告 | P4 诉讼/处罚兜底 |
| SoT active≥1 | 范围 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| P3 metric 入库（交易日）| ≥5/6 |
| P4 metric 覆盖率 | ≥3/5（启动期可接受文本规则漏检）|
| 单测 | ≥10 passed |

## §6 下一步

本步 ✅ → step_04 完整 Scheduler + SLI 聚合。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A quote_adapter** | `probes/datasource/quote_adapter.py` | AKShare 日线 + 交易日历 | 1 标的拉 60d |
| **B announcement_adapter** | `.../announcement_adapter.py` | 巨潮 + AKShare 双源 | 5 事件类 |
| **C P3 纯函数** | `probes/price.py` | RSI Wilder；drawdown；MA | 单测边界 |
| **D P4 聚合** | `probes/event.py` | 窗口去重 | — |
| **E scheduler_skeleton** | `probes/scheduler_skeleton.py` | 占位注册；`--once` 全部触发一次 | 4 类各 1 次 |
| **F CLI** | 各 probe `__main__` | `--symbol --once` | JSON |
| **G 单测** | `test_probe_price.py`/`test_probe_event.py` | ≥10 | pytest |
| **[L-α] H physical_probes.yaml** | `configs/physical_probes.yaml` | 三探针阈值（green/yellow/red 边界 + 持续期数）+ HS Code 映射 + 文本抽取正则模式；与 DNA 1:1 | yaml 单测加载 |
| **[L-α] I P5 TenderProbe** | `probes/physical/p5_tender.py` | 复用 D2 嗅探层 ccgp 抓取通道；按 monitor:{symbol}:dict:physical.focus_keywords 过滤；30 天滑窗聚合；三色信号；evidence_url 留痕 ≥ 3 | 单测：mock 5 公告 → 触发 yellow signal |
| **[L-α] J P6 CustomsProbe** | `probes/physical/p6_customs.py` | HS Code 映射；月度数据双源（AKShare + 行业协会）；月环比/同比；三色信号 | 单测：mock 12 月数据 → 触发 red signal |
| **[L-α] K P7 CapacityProbe** | `probes/physical/p7_capacity.py` | 文本规则抽取（业绩说明会 + 投资者关系 Q&A）；正则匹配 capacity_utilization + capex；季度节奏 | 单测：mock 公告全文 → 抽取产能利用率字段 |
| **[L-α] L PhysicalProbeAlertEvent publisher** | `events/physical_alert_publisher.py` | Redis Stream `events:monitor:physical_alert`；yellow/red 投；green 仅写库 | XADD 单测 + consumer roundtrip |
| **[L-α] M physical_probe_records ORM** | `db/models.py` | 字段见 §3 落库说明；索引 (symbol, probe_id, recorded_at desc) | migration |
| **[L-α] N 三探针 D0 API** | `api/routes/holding_watch.py::get_physical_signal` | `GET /api/holding-watch/physical/{symbol}` 返三探针最近信号 + evidence_url 列表 | 200 + body |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `watch-step03-prep` | quote/announcement adapter 可达 |
| `watch-step03-price-once` | 全 active 跑 P3；返 metric 数 |
| `watch-step03-event-once` | 同上 P4 |
| `watch-step03-trade-window-check` | 非交易日空跑 OK |
| `watch-step03-test` | pytest ≥10 |
| `watch-step03-all` | once+once+test |
| `watch-step03-status` | 近 24h 入库 + 覆盖 |
| `watch-step03-clean` | dev only FORCE=1 |
| **[L-α]** `watch-step03-physical-p5-once` | P5 招标单次抓取 + 三色信号计算 + Event 投递 | metric 数 + signal 颜色 |
| **[L-α]** `watch-step03-physical-p6-once` | P6 海关月度（手动触发）| HS Code 覆盖率 + signal |
| **[L-α]** `watch-step03-physical-p7-once` | P7 产能（手动触发）| 抽取成功率 + signal |
| **[L-α]** `watch-step03-physical-all` | P5+P6+P7 全跑 + 验收 §3.5.4 矩阵 | 三探针均落库 |
| **[L-α]** `watch-step03-physical-status` | 三探针近 7 日 signal 矩阵 + 各标的覆盖 | 只读表格 |

### §7.3 关键代码片段（中间道）

#### 7.3.1 P3 价格指标纯函数（核心 ~15 行）

```python
def rsi_wilder(closes: list[float], period: int = 14) -> Optional[float]:
    """Wilder RSI；不足 period+1 → None。"""
    if len(closes) < period + 1:
        return None
    gains, losses = [], []
    for i in range(1, period + 1):
        diff = closes[i] - closes[i-1]
        gains.append(max(diff, 0)); losses.append(max(-diff, 0))
    avg_g, avg_l = sum(gains)/period, sum(losses)/period
    for i in range(period + 1, len(closes)):
        diff = closes[i] - closes[i-1]
        g, l = max(diff, 0), max(-diff, 0)
        avg_g = (avg_g * (period-1) + g) / period
        avg_l = (avg_l * (period-1) + l) / period
    if avg_l == 0: return 100.0
    rs = avg_g / avg_l
    return 100 - 100 / (1 + rs)

def drawdown_60d(closes: list[float]) -> float:
    window = closes[-60:] if len(closes) >= 60 else closes
    peak = max(window)
    return (window[-1] - peak) / peak if peak else 0.0
```

#### 7.3.2 P3 价格探针完整 normalize（核心 ~15 行）

```python
class PriceProbe(BaseProbe):
    probe_id = "P3"
    interval_seconds = 30 * 60

    def normalize(self, raw: dict) -> list[ProbeMetric]:
        if not raw.get("is_trading_session"):
            return [self._closed_metric()]                    # 非交易时段 1 条占位
        closes = raw["closes_daily"]                          # 升序 list[float]
        volumes = raw["volumes_daily"]
        ma20 = sum(closes[-20:]) / 20 if len(closes) >= 20 else None
        metrics = {
            "pct_change_1d":     (closes[-1] - closes[-2]) / closes[-2] if len(closes) >= 2 else None,
            "drawdown_60d":      drawdown_60d(closes),
            "turnover_pct":      raw.get("turnover_pct"),
            "vol_ratio_20d":     volumes[-1] / (sum(volumes[-20:]) / 20) if len(volumes) >= 20 else None,
            "rsi_14":            rsi_wilder(closes, 14),
            "ma_deviation_20d":  (closes[-1] - ma20) / ma20 if ma20 else None,
        }
        cov = sum(1 for v in metrics.values() if v is not None) / 6
        return [ProbeMetric(metric=k, value=v, score=score_metric(k, v),
                            coverage=cov, source="akshare", recorded_at=utcnow())
                for k, v in metrics.items()]
```

#### 7.3.3 P4 事件文本规则匹配（核心 ~12 行）

```python
EVENT_PATTERNS = {
    "litigation": [r"重大诉讼", r"起诉", r"被告", r"应诉"],
    "penalty":    [r"行政处罚", r"立案调查", r"警示函", r"监管措施"],
    "exec_change":[r"董事.*辞职", r"总经理.*变更", r"高管.*离任"],
    "major_reduce":[r"减持.*股份", r"竞价交易减持", r"集中竞价减持"],
    "pledge":     [r"股权质押", r"质押解除"],
}

def classify_announcement(title: str, content: str) -> set[str]:
    """返回该公告命中的事件类型集合。"""
    text = title + " " + (content or "")
    hits = set()
    for ev_type, patterns in EVENT_PATTERNS.items():
        if any(re.search(p, text) for p in patterns):
            hits.add(ev_type)
    return hits
```

#### 7.3.4 交易时段判断（核心 ~10 行）

```python
TRADE_CALENDAR = None  # 启动期可用 akshare.tool_trade_date_hist_sina() 缓存

def is_trading_session(dt: datetime = None) -> bool:
    dt = dt or datetime.now(tz=ZoneInfo("Asia/Shanghai"))
    if dt.weekday() >= 5:                                # 周六日
        return False
    if TRADE_CALENDAR and dt.date() not in TRADE_CALENDAR:
        return False
    t = dt.time()
    return (time(9,30) <= t <= time(11,30)) or (time(13,0) <= t <= time(15,0))
```

### §7.4 指引

先 adapter→price 纯函数→event 聚合→skeleton；交易日历用 `trade_cal` 接口；事件文本规则启动期 keep simple，ADR 写漏检率。

## §8 部署节奏

本机；扩展期合并到 watch K3s Deployment。

## §9 准出标准

- [ ] §3.5 17 项
- [ ] 交易日 P3 ≥5/6 metric；P4 ≥3/5
- [ ] `make watch-step03-all`；L4 回写

## §10 [Deploy]

启动期本机；与 step_04 整合。

## §11 依赖

step_01/02；AKShare/巨潮 可达；SoT；**[L-α]** D2 step_02 嗅探层 ccgp 通道（P5 复用）+ 共享规约 20 监控字典消费者契约 + Redis Stream `events:monitor:physical_alert` topic + DNA `physical_probes.yaml`。
**下游**：D0 副驾驶持仓体检卡（订阅 `events:monitor:physical_alert` + 调用 `/api/holding-watch/physical/{symbol}`）；D4 SP3 Thesis 失效协议可选消费物理信号叠加判断。

**严禁**：stub 行情入库；非交易时段强写 P3；**[L-α]** 伪造 physical_signal；绕过监控字典全市场无差别抓取（资源浪费 + 反爬风险）；P5/P6/P7 yellow/red 信号直接触发自动建仓或自动清仓（永久 no-auto-execute 规则）。

## §12 风险

| 触发 | 动作 |
|---|---|
| AKShare 限频 | backoff |
| 公告解析漏判 | ADR 写漏检率；启动期接受 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v3.1 Lighthouse-Alpha 融合**：merge_inplace 追加物理量探针 P5 招标 / P6 海关 / P7 产能——§1 一句话扩 + 交付物 H~K（P5/P6/P7/PhysicalProbeAlertEvent）；§3 探针表追加 3 行；§3.5 新增 §3.5.4 矩阵 17 项（PT/PC/PP/PG 四组）；§7.1 追加 H~N 七实现要点（yaml/3 探针/Event publisher/ORM/D0 API）；§7.2 Makefile 加 5 个 physical target；§11 上下游同步 D0 副驾驶 + 永久 no-auto-execute |
| 2026-05-21 | **v3 中间道细化**：保留 v2 §3.5 17 项；§7.3 新增 4 个关键片段（RSI Wilder + drawdown 纯函数 / P3 价格 6 metric normalize / P4 事件正则规则匹配 / 交易时段判断）；156→~330 行 |
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 834 行 Python；§3.5 17 项；`watch-step03-*`；834→~250 行 |
| 2026-05-16 | 初版 834 行 |
