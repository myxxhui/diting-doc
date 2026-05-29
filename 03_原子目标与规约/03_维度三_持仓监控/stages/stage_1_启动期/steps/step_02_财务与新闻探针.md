# Step 02 · 财务探针（P1·24h）+ 新闻探针（P2·1h）

## §1 一句话定位与本步交付物

**一句话**：实现 **BaseProbe** 抽象基类 + **P1 财务探针**（24h，6 metric：营收/净利/毛利率/经营现金流/负债率/ROE）+ **P2 新闻探针**（1h，2 metric：7d 情感均值/7d 负面计数）；落库 `node_sli_values`（step_04 建表，本步可临时表）+ 供 step_06 健康度消费。

**交付物**（勾选 = 完成）：
- [ ] **A**（`BaseProbe`）：抽象 `fetch / normalize / on_failure / health_check`；统一 metric schema
- [ ] **B**（P1 financial）：AKShare 适配 + 缺失字段降级标 `coverage<1.0`
- [ ] **C**（P2 news）：新闻/公告情感聚合；启动期可用 RSS+jieba 简易情感词典
- [ ] **D**（datasource 双源）：`akshare_adapter` / `news_adapter`；**禁止** stub 写业务库
- [ ] **E**（CLI）：`python -m apps.state_watch.probes.financial --symbol XXXXXX` 输出 6 metric JSON
- [ ] **F**（单测）：≥6 financial + ≥6 news；含缺数据降级用例
- [ ] **G**（Makefile）：`make watch-step02-all`

> **依赖**：step_01 BaseProbe 占位 + holdings_state 已注册；持仓 SoT 必须有 ≥1 active。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../03_数据采集与预处理.md](../03_数据采集与预处理.md) §2.1/§2.2、[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §3 探针
> - **DNA**：`deliverables.sli_probes[0]`（P1 24h）+ `[1]`（P2 1h）
> - **持仓 SoT**：`my_holdings.yaml`（只跑 active=true）
> - **L4**：[实践记录_step_02_财务与新闻探针.md](../../../../../04_阶段规划与实践/03_维度三_持仓监控/stage_1_启动期/实践记录_step_02_财务与新闻探针.md)
> - **上游**：step_01；**下游**：step_04（调度）、step_06（聚合）

## §3 数据采集对象 / 落库映射

| 探针 | 数据源 | 频率 | metric 入库 |
|---|---|---|---|
| P1 financial | AKShare 三表年/季报 + 巨潮 | 24h | `revenue_yoy / net_profit_yoy / gross_margin / operating_cf / debt_ratio / roe` |
| P2 news | 财联社 RSS + 巨潮公告 + 简易情感 | 1h | `sentiment_score_7d / negative_count_7d` |

**[L-α] 监控字典消费端**：P1/P2 探针**额外**消费 D2 step_02 写入的 `monitor:{symbol}:dict:financial` / `monitor:{symbol}:dict:news` Redis 字典（schema 见共享规约 20），把"该标的应监控的精准字段/关键词"作为指标采集的优先级提示——例如若字典含 `{focus_keywords: ['碳化硅出货量', '海外车厂订单']}`，则 P2 新闻探针把这些关键词加入 sentiment 词典权重，命中时 `sentiment_score` 加权；同理 P1 财务字典可指定 `focus_metrics: ['gross_margin_segment_auto']` 触发 P1 优先拉分部毛利率。

落库表：`node_sli_values(node_id, probe_id, metric, value, score, recorded_at, source)`（建表见 step_04；本步可先写 health_records 临时字段）。
**[L-α]** 新增字段 `metric_metadata`（JSON）：含 `monitor_dict_used: bool` / `dict_version: str` / `dict_focus: [str]`，便于审计该 metric 是否被监控字典加权。

## §3.5 数据质量验收矩阵（探针采集 · 仅启动期）

### §3.5.1 P1 财务质量

| # | metric | 必产标准 | 启动期覆盖 | 降级路径 |
|---|---|---|---|---|
| F1 | **revenue_yoy** | 来自 latest_q vs 去年同期；缺去年→null+coverage<1 | ✅ AKShare 季报 | 财报未披露则 coverage<1 不报错 |
| F2 | **net_profit_yoy** | 同上 | ✅ | 同 |
| F3 | **gross_margin** | (revenue-cost)/revenue；季报或年报 | ✅ | cost 缺→null |
| F4 | **operating_cf** | 现金流表"经营活动现金流量净额"；亿元 | ✅ | 现金流表缺→null |
| F5 | **debt_ratio** | 总负债/总资产 | ✅ | 资产负债表缺→null |
| F6 | **roe** | 摊薄 ROE 年化 | ✅ | — |
| F7 | **数据新鲜度** | `recorded_at` 入库 + 与最新财报日差≤90d | ✅ | >90d 标 stale |

### §3.5.2 P2 新闻质量

| # | metric | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| N1 | **7d 新闻收集量** | 每标的 ≥3 条/周 | ⚠️ 冷门标的可能<3 | <3 时 coverage 降权 |
| N2 | **sentiment_score_7d** | 范围 [-1,1]；jieba 词典或 LLM | ✅ 启动期 jieba | 词典命中率<30%→标 low_confidence |
| N3 | **negative_count_7d** | 整数 | ✅ | — |
| N4 | **去重** | 同源同标题不重复计 | ✅ url hash | — |
| N5 | **公告兼容** | 巨潮公告标题进 sentiment 池 | ✅ | API 限频→retry |

### §3.5.3 工程

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **only active** | 仅采 SoT `active=true` | ✅ | — |
| E2 | **失败重试** | 单标的失败 3 次后 on_failure 写 fail 日志 | ✅ | — |
| E3 | **不写 stub** | 业务库严禁 stub | ✅ tests/ 例外 | — |
| E4 | **idempotent** | 同 day 不重复写 metric | ✅ | upsert by (node, metric, day) |

### §3.5.4 [Lighthouse-Alpha] 监控字典消费端质量

| # | 维度 | 必产字段 / 逻辑 | 启动期 | 降级 |
|---|---|---|---|---|
| MD1 | **Redis 字典查询** | 每次 fetch 前 `redis.get('monitor:{symbol}:dict:financial/news')`；命中则 jsonschema.validate 通过后使用 | ✅ | 字典缺失或 schema 不通过 → 走 P1/P2 默认配置 + 标 `metric_metadata.monitor_dict_used=false`（不阻塞）|
| MD2 | **focus_keywords 加权** | P2 sentiment 计算时，命中 focus_keywords 的词权重 ×2；落 `metric_metadata.dict_focus` 留痕 | ✅ | 单测 mock 字典 + 文本命中 → 加权一致 |
| MD3 | **focus_metrics 触发** | P1 字典含 focus_metrics 时，优先拉取该 metric（如分部毛利率）| ⚠️ 启动期 AKShare 分部数据覆盖率低 | 接口不支持 → 标 `focus_metric_pending` + 不阻塞 |
| MD4 | **dict_version 追溯** | metric_metadata.dict_version 与 Redis 字典 ETag 一致 | ✅ | — |
| MD5 | **零信任**（消费端）| 不假设字典一定可用；空字典 = 默认行为 = 不报错 | ✅ | — |
| MD6 | **可观察** | `make watch-step02-monitor-dict-status` 输出每标的字典命中率 + 加权次数 | ✅ | — |

> 共 **16 项原有 + 6 项 Lighthouse-Alpha = 22 项**。
> [Lighthouse-Alpha] 对齐共享规约 20（监控字典 schema）+ D2 step_02 监控字典生产端。

## §4 凭证清单

| 凭证 | 用途 | 何时 |
|---|---|---|
| AKShare（无 key）| P1 财务 | 必须 |
| 新闻 RSS / 巨潮 | P2 | 启动期可降级用 1 个稳定源 |
| 持仓 SoT 已 active | 采集范围 | 必须 |

> **禁止** stub 进入 node_sli_values 写库。

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| P1 每 active 标的 6 metric 入库 | ≥4/6 非空 |
| P2 每 active 每周新闻收集 | ≥3 条（达不到则 coverage 降级标注）|
| 单测 | ≥12 passed |

## §6 下一步

本步 ✅ → step_03 价格 + 事件探针（P3/P4）。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A BaseProbe** | `probes/base_probe.py` | fetch/normalize/on_failure 抽象；统一 schema | 子类签名一致 |
| **B AKShare adapter** | `probes/datasource/akshare_adapter.py` | 包 retry+rate-limit | mock + 1 真标的 |
| **C P1 financial** | `probes/financial.py` | 6 metric 实现；coverage 计算 | CLI 输出 |
| **D News adapter** | `probes/datasource/news_adapter.py` | RSS+巨潮+jieba 情感 | 1 标的有数据 |
| **E P2 news** | `probes/news.py` | 7d 聚合 | CLI 输出 |
| **F dedup** | url hash util | 内存 LRU 或 SQLite seen 表 | 单测 |
| **G CLI** | 每探针 `__main__` | `--symbol` + JSON 输出 | stdout 可解析 |
| **H 单测** | `test_probe_financial.py`/`test_probe_news.py` | ≥12 含缺数据降级 | pytest |
| **[L-α] I MonitorDictReader** | `probes/monitor_dict_reader.py` | Redis client + jsonschema.validate；TTL aware；命中/未命中均记 metric_metadata | 单测 4 例：命中/缺失/schema 不通过/Redis 不可用 |
| **[L-α] J focus_keywords 加权** | `probes/news.py::jieba_sentiment` 改造 | 接收 focus_keywords 参数；命中词权重 ×2；返 dict_focus 留痕 | 单测：相同文本带/不带字典对比加权差异 |
| **[L-α] K focus_metrics 触发** | `probes/financial.py::fetch` 改造 | 字典含 focus_metrics 时优先调用 akshare 分部接口；失败标 `focus_metric_pending` 不报错 | mock akshare 接口返回不同样本 |
| **[L-α] L 监控字典命中率统计** | `probes/monitor_dict_metrics.py` | 累加每标的 hit/miss + 落 ClickHouse `monitor_dict_consumer_stats` | Makefile target 输出可读 |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `watch-step02-prep` | deps 在；SoT active≥1 |
| `watch-step02-financial-once` | 全 active 跑 P1；返 metric 数 |
| `watch-step02-news-once` | 同上 P2 |
| `watch-step02-coverage` | metric 覆盖率报告 |
| `watch-step02-test` | pytest ≥12 |
| `watch-step02-all` | financial+news+test |
| `watch-step02-status` | 最近 24h 入库数 + coverage |
| `watch-step02-clean` | dev FORCE=1 清当日 |
| **[L-α]** `watch-step02-monitor-dict-status` | 各标的字典命中率 + 加权次数 + dict_version | 只读表格 |

### §7.3 关键代码片段（中间道）

#### 7.3.1 BaseProbe 抽象基类（核心 ~15 行）

```python
class ProbeMetric(BaseModel):
    metric: str                # 'revenue_yoy' 等
    value: Optional[float]     # null 表示数据缺
    score: Optional[float]     # 0~100 归一化（健康度消费）
    coverage: float = Field(ge=0.0, le=1.0)
    source: str
    recorded_at: datetime

class BaseProbe(ABC):
    probe_id: str              # 'P1' / 'P2' / 'P3' / 'P4'
    interval_seconds: int

    @abstractmethod
    async def fetch(self, symbol: str) -> dict: ...
    @abstractmethod
    def normalize(self, raw: dict) -> list[ProbeMetric]: ...

    async def on_failure(self, symbol: str, exc: Exception):
        log.error("probe %s symbol=%s failed: %s", self.probe_id, symbol, exc)

    async def run_once(self, symbol: str) -> list[ProbeMetric]:
        for attempt in range(3):
            try: return self.normalize(await self.fetch(symbol))
            except Exception as e:
                if attempt == 2: await self.on_failure(symbol, e); return []
                await asyncio.sleep(2 ** attempt)
```

#### 7.3.2 P1 财务探针 6 metric 归一化（核心 ~15 行）

```python
class FinancialProbe(BaseProbe):
    probe_id = "P1"
    interval_seconds = 86400

    def normalize(self, raw: dict) -> list[ProbeMetric]:
        latest_q, year_ago = raw["latest_quarter"], raw["year_ago_quarter"]
        bs, cf = raw.get("balance_sheet"), raw.get("cash_flow")
        # 6 metric 计算 + null 安全
        m = {}
        m["revenue_yoy"]   = pct_change(latest_q.get("revenue"), year_ago.get("revenue"))
        m["net_profit_yoy"] = pct_change(latest_q.get("net_profit"), year_ago.get("net_profit"))
        m["gross_margin"]  = safe_div(latest_q.get("revenue", 0) - latest_q.get("cost", 0),
                                       latest_q.get("revenue"))
        m["operating_cf"]  = cf.get("operating_net") if cf else None
        m["debt_ratio"]    = safe_div(bs.get("total_liab"), bs.get("total_assets")) if bs else None
        m["roe"]           = latest_q.get("roe_diluted")
        covered = sum(1 for v in m.values() if v is not None)
        coverage = covered / 6
        return [ProbeMetric(metric=k, value=v, score=score_metric(k, v),
                            coverage=coverage, source="akshare",
                            recorded_at=utcnow()) for k, v in m.items()]
```

#### 7.3.3 P2 新闻情感聚合（核心 ~12 行）

```python
class NewsProbe(BaseProbe):
    probe_id = "P2"
    interval_seconds = 3600

    def normalize(self, raw: dict) -> list[ProbeMetric]:
        news = dedupe_by_url_hash(raw["news_list"])
        scored = [jieba_sentiment(n["title"] + n.get("summary","")) for n in news]
        n_total = len(scored)
        if n_total < 3:
            cov = n_total / 3
        else:
            cov = 1.0
        avg = sum(scored) / n_total if n_total else 0.0
        neg = sum(1 for s in scored if s < -0.3)
        return [
            ProbeMetric(metric="sentiment_score_7d", value=avg, score=(avg+1)*50,
                        coverage=cov, source="rss", recorded_at=utcnow()),
            ProbeMetric(metric="negative_count_7d", value=neg, score=max(0,100-neg*15),
                        coverage=cov, source="rss", recorded_at=utcnow()),
        ]
```

#### 7.3.4 jieba 情感词典简易实现（核心 ~10 行）

```python
POS_WORDS = {"增长","创新高","盈利","订单","突破","利好","续约","回购","回升"}
NEG_WORDS = {"下滑","亏损","违规","调查","处罚","退市","商誉减值","暴雷","裁员"}

def jieba_sentiment(text: str) -> float:
    """返回 [-1, 1] 区间。"""
    words = set(jieba.cut(text))
    pos = len(words & POS_WORDS)
    neg = len(words & NEG_WORDS)
    if pos + neg == 0:
        return 0.0
    return (pos - neg) / (pos + neg)
```

### §7.4 指引

先 BaseProbe→adapter→P1→P2→CLI→test；coverage 严于 metric 数；冷门标的可能新闻少，不报错只标记。

## §8 部署节奏

本机 + 调 AKShare/RSS；K3s 扩展期。

## §9 准出标准

- [ ] §3.5 16 项
- [ ] 每 active 标的 P1≥4/6 metric；P2 有数据或显式 coverage 降级
- [ ] `make watch-step02-all`；L4 回写（标的×metric 覆盖矩阵）

## §10 [Deploy]

启动期本机；后续与 P3/P4 合并 K3s scheduler Pod。

## §11 依赖

step_01；AKShare/RSS 可达；SoT；**[L-α]** Redis 可达（消费 `monitor:{symbol}:dict:*`）；共享规约 20 监控字典 schema 已定稿；D2 step_02 监控字典生产端先于本步上线（生产端缺失不阻塞本步，但失去字典加权能力）。

**严禁**：stub 数据写库；忽略 coverage 直接断言准出；**[L-α]** 假设字典一定可用（须降级路径覆盖）；忽略 dict_version 留痕。

## §12 风险

| 触发 | 动作 |
|---|---|
| AKShare 限频 | exponential backoff；超限走巨潮 |
| 新闻 RSS 不稳定 | 多源备份 |
| 情感词典准度低 | 标 low_confidence + ADR |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v3.1 Lighthouse-Alpha 融合**：merge_inplace 融入监控字典消费端——§3 表加 [L-α] 段说明 + metric_metadata 字段；§3.5 新增 §3.5.4 矩阵 6 项（MD1~MD6）；§7.1 追加 I~L 四实现要点（MonitorDictReader / focus_keywords 加权 / focus_metrics 触发 / 命中率统计）；§7.2 Makefile 加 monitor-dict-status target；§11 依赖加 Redis + 共享规约 20 |
| 2026-05-21 | **v3 中间道细化**：保留 v2 §3.5 16 项；§7.3 新增 4 个关键片段（BaseProbe 抽象基类 + ProbeMetric schema / P1 财务探针 6 metric 归一化 / P2 新闻情感聚合 / jieba 情感词典实现）；160→~330 行 |
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 818 行嵌入 Python；§3.5 16 项；`watch-step02-*`；818→~240 行 |
| 2026-05-16 | 初版 818 行 |
