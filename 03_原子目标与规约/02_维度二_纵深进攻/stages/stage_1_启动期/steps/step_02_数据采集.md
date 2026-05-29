# Step 02 · 财务与公告数据采集（利润截留 5 信号 + 证据链原料）

## §1 一句话定位与本步交付物

**一句话**：按持仓 SoT 对 active 标的拉取**真实**财报指标（支撑利润截留 5 信号）+ 巨潮公告（支撑证据链），落 `deep_strike.db` 四张业务表；**同时**（Lighthouse-Alpha 扩展）打通**主动嗅探采集通道**——按动态采集流水线（共享规约 18）从三大发源地（招标 ccgp / 研报政策 / 海外科技映射）抓取**全市场非结构化文本**，投递 Kafka topic `sniffer_raw_text`，下游由 D2 step_03 The Critic、step_04 The Mapper、step_07 The Scorer 以及 D5 ETL LLM Engine 消费；**禁止** mock 充数——数据质量须达到 step_04 剧本能算 5 信号、step_03 能建 ≥3 条证据/标的、嗅探侧每日 ≥ 50 条原文 + ≥1 候选题材簇。

**交付物**（勾选 = 完成）：
- [ ] **A**（ORM 4 表扩展）：`financial_reports / financial_indicators / announcements / industry_peers` + alembic migration
- [ ] **B**（akshare + 巨潮采集器）：`data/sources/akshare_source.py`、`cninfo_source.py`；normalizer + validator
- [ ] **C**（SoT 驱动 ingest）：`data/ingest.py` 读 `MY_HOLDINGS_YAML` 仅 `active=true` 标的；幂等 upsert
- [ ] **D**（启动期数据量）：每 active 标的 ≥ 4 期 `financial_indicators` + ≥ 10 条 `announcements` + 同业 ≥ 3 家
- [ ] **E**（与 D1 共源策略）：优先复用 `cryo_guard.db` 已有财报/公告（若 step_02 D1 已落库同 symbol）；缺字段再 D2 增量补采
- [ ] **F**（质量矩阵全绿/⚠️）：§3.5 矩阵通过 `validate_deep_strike_data_quality.py`
- [ ] **G**（单测）：`pytest tests/deep_strike/test_data_ingest.py -v` ≥ 6 passed（**仅** tests/ 内 fixture mock HTTP，不入业务库）
- [ ] **H**（Makefile）：`make deep-step02-all` 端到端通过
- [ ] **I**（Lighthouse-Alpha · Playwright 物理采集层）：`data/sniffer/playwright_runner.py` + 三大源 spider（`ccgp_spider.py` 招标 / `policy_research_spider.py` 研报政策 / `overseas_arxiv_spider.py` 海外映射）；K8s CronJob 或本机 APScheduler 调度
- [ ] **J**（Lighthouse-Alpha · NLP 聚类初筛）：`data/sniffer/clusterer.py` TF-IDF + 300% 关键词频触发；候选簇落 `sniffer_clusters` 表
- [ ] **K**（Lighthouse-Alpha · 监控字典生产端）：`data/sniffer/monitor_dict_writer.py` 写 Redis `monitor:{symbol}:dict:*`（schema 见共享规约 20），TTL=7d；D3 step_03 消费
- [ ] **L**（Lighthouse-Alpha · 动态采集流水线契约）：实现共享规约 18 的 `CrawlTaskConfig` Redis 热加载 + `content_hash` 去重 + `sniffer_raw_text` Kafka topic 投递

> **本步是 step_03~10 的数据硬阻塞**；采集只服务剧本分析与嗅探推理，**永不**写入持仓表（永久规则）。
> **永久规则（嗅探侧）**：Playwright 必须设 `User-Agent` 池 + ≥3s 间隔；ccgp 单源 QPS ≤ 0.3；**禁止**绕过 robots.txt；**禁止**用 mock 文本进 Kafka 业务 topic。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2 哲学**：[02_维度二_纵深进攻 · 04_实践策略规划](../../../../../02_战略维度/02_维度二_纵深进攻/04_实践策略规划.md)
> - **L3 数据采集**：[../03_数据采集与预处理.md](../03_数据采集与预处理.md) §一~§四（利润截留字段、证据链类型）
> - **L3 策略**：[../01_实践目标与策略.md](../01_实践目标与策略.md) §2.2 五信号权重
> - **DNA 键**：`_System_DNA/02_deep_strike/dna_stage_1_启动期.yaml` → `deliverables.playbooks[0].signals`
> - **持仓 SoT**：[14_六维度启动期统一节奏表](../../../../_共享规约/14_六维度启动期统一节奏表.md) §1、`diting-src/data/config/my_holdings.yaml`
> - **L4 实践记录**：[实践记录_step_02_数据采集.md](../../../../../04_阶段规划与实践/02_维度二_纵深进攻/stage_1_启动期/实践记录_step_02_数据采集.md)
> - **上游**：← step_01；← D1 step_02（可选共源 `cryo_guard.db`）
> - **下游**：→ step_03（证据链）、step_04（5 信号计算）

## §3 数据采集对象 / 落库映射

| 业务对象 | ORM 表 / 关键字段 | 真实数据源 | 采集模块 |
|---|---|---|---|
| 三大报表摘要 | `financial_reports`（revenue/cost/net_profit/period）| akshare `stock_financial_report_sina` | `akshare_source.fetch_financial_report` |
| **利润截留指标** | `financial_indicators`（gross_margin/gross_margin_qoq/revenue_growth_yoy/cost_growth_yoy/net_profit_growth_yoy/receivable_turnover/receivable_turnover_qoq/inventory_turnover/inventory_turnover_qoq）| akshare `stock_financial_analysis_indicator` | `akshare_source.fetch_financial_indicator` |
| 公告（证据链） | `announcements`（title/content/url/ann_type/ann_date）| 巨潮 + akshare `stock_notice_report` | `cninfo_source` + akshare |
| 同业对比 | `industry_peers`（peer_symbol/industry/rank_metric）| akshare 行业成分 | `akshare_source.fetch_industry_peers` |
| **[L-α] 招标公告原文** | Kafka `sniffer_raw_text`（source=ccgp）+ `sniffer_raw_text`（落库镜像可选）| ccgp.gov.cn Playwright | `data/sniffer/ccgp_spider.py` |
| **[L-α] 研报与政策文本** | 同上（source=research/policy）| 券商研报 PDF + 政策门户 | `data/sniffer/policy_research_spider.py` |
| **[L-α] 海外科技映射** | 同上（source=overseas）| ArXiv + GitHub Trending + 海外科技媒体 | `data/sniffer/overseas_arxiv_spider.py` |
| **[L-α] 题材聚类候选** | `sniffer_clusters`（cluster_id/keyword/freq_growth/sample_doc_ids/created_at）| 300% TF-IDF 频次触发 | `data/sniffer/clusterer.py` |
| **[L-α] 监控字典（出库）** | Redis `monitor:{symbol}:dict:{field}` + ClickHouse `monitor_dict_history` | The Architect 大模型生成（schema 见共享规约 20）| `data/sniffer/monitor_dict_writer.py` |

**零值语义**：指标缺失 → null + `missing_fields[]` JSON；**禁止**用 0 假装有值。
**嗅探零值语义**：原文抓取失败 → 写 `failed_crawl.log`（不入 Kafka）；聚类 0 簇当日则 `sniffer_clusters` 空表合规、**不**写假候选；监控字典生成失败 → 不写 Redis，告警但不阻塞下游 D3 探针（D3 退化用默认阈值）。

## §3.5 数据质量验收矩阵（按 step_04/03 反推 · 仅启动期）

> **巴菲特原则**：利润截留不是看一行毛利率——要看**环比/同比/周转/杠杆**是否可算、可复核。

### §3.5.1 利润截留 5 信号（step_04 消费）

| # | 分析维度（DNA 信号）| 必产字段 / 衍生 | 启动期 | 降级路径 |
|---|---|---|---|---|
| S1 | gross_margin_qoq_up（权重 0.30）| `gross_margin` + `gross_margin_qoq` 可算；qoq 基于连续 2 期 | ⚠️ 每 active 标的 ≥ 4 期指标行 | 不足 4 期标 `history_insufficient`；该信号不参与加权 |
| S2 | cost_growth_below_revenue（0.25）| `cost_growth_yoy`、`revenue_growth_yoy` 非 null | ⚠️ 非 null 率 ≥ 90% | 缺则该信号权重归零 + 日志 |
| S3 | operating_leverage（0.25）| `net_profit_growth_yoy` vs `revenue_growth_yoy` 可比较 | ⚠️ 同上 | 同上 |
| S4 | receivable_turnover_up（0.10）| `receivable_turnover` + `receivable_turnover_qoq` | ⚠️ 周转字段非 null 率 ≥ 80% | 缺则降权 |
| S5 | inventory_turnover_up（0.10）| `inventory_turnover` + `inventory_turnover_qoq` | ⚠️ 同上 | 同上 |

### §3.5.2 证据链原料（step_03 消费）

| # | 分析维度 | 必产字段 | 启动期 | 降级路径 |
|---|---|---|---|---|
| E1 | 财务类证据 | `financial_indicators` 最新 1 期可引用为 evidence | ✅ | — |
| E2 | 公告类证据 | `announcements.content` 全文 ≥ 200 字；`url` 巨潮链接 | ⚠️ 每标的 ≥ 10 条；全文率 ≥ 70% | 仅标题行不入 evidence，计入 reject |
| E3 | 行业类证据 | `industry_peers` ≥ 3 家同业 | ⚠️ 每标的 ≥ 3 peers | 不足 3 家退全市场分位（step_04 标 `peer_fallback`）|
| E4 | 管理层表述 | 公告 type ∈ {业绩预告, 经营情况, 重大事项} 至少各 1 条（若有披露）| ⚠️ 按披露存在性检查 | 无则 evidence 仅财务 |

### §3.5.3 共源与 SoT

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| C1 | 持仓 SoT 驱动 | 仅 `active=true` 标的入库（持仓侧采集）| ✅ `holdings_sot.active_symbols()` | 禁止硬编码 symbol |
| C2 | D1 共源不重复爬 | 同 symbol 已在 `cryo_guard.db` 的 announcements 可 COPY/ATTACH 只读同步 | ⚠️ 减少限流 | 无共源则全量 akshare |
| C3 | 幂等 upsert | 重跑 `make deep-step02-all` 行数不翻倍 | ✅ 业务主键 upsert | — |

### §3.5.4 [Lighthouse-Alpha] 主动嗅探与动态采集质量

| # | 维度 | 必产字段 / 衍生 | 启动期 | 降级 |
|---|---|---|---|---|
| LA1 | **三源覆盖** | ccgp + research + overseas 三 source 当日各 ≥ 1 条 raw_text | ⚠️ ccgp 反爬可能间歇失败 | 单源失败标 `source_degraded`；当日另两源 ≥ 1 即不阻塞 |
| LA2 | **原文条数门槛** | Kafka topic `sniffer_raw_text` 当日累计 ≥ 50 条 | ⚠️ | 不足 50 → 告警不准出，回查爬虫限流 |
| LA3 | **content_hash 去重** | 同源 `md5(url + content[:500])` 全局唯一 | ✅ Redis SET `sniffer:dedup:{date}` | 重复条丢弃 + 计数 |
| LA4 | **题材聚类触发** | `sniffer_clusters` 当日 ≥ 1 簇（关键词频环比涨 ≥ 200%）| ⚠️ 启动期阈值放宽至 200% | < 1 簇不阻塞 D2 主线但告警 |
| LA5 | **监控字典 schema** | 写 Redis 前 `jsonschema.validate` 通过（schema 见共享规约 20）| ✅ | 不通过拒绝写入 + DLQ |
| LA6 | **监控字典覆盖** | active 持仓标的 monitor:{symbol}:dict:* 至少 1 个有效字典；扩展到候选 ≥ 3 标的 | ⚠️ 依赖 The Architect 大模型可用 | 缺则 D3 探针走默认阈值（不阻塞）|
| LA7 | **CronJob/调度可观察** | 每次抓取轮次落 `crawl_logs(task_id, source, success, fail, started_at, finished_at)` | ✅ | — |
| LA8 | **合规** | robots.txt 遵守；ccgp QPS ≤ 0.3；User-Agent 轮换 | ✅ 单测覆盖 | 触发反爬 → 退避 5 倍 + 切 UA |
| LA9 | **配置热加载** | `CrawlTaskConfig` 改 Redis 即生效（无须重启）| ✅ | 单测：改 enabled=false 后 5min 内停采 |

> 共 **12 项原有 + 9 项 Lighthouse-Alpha = 21 项**。无 ❌ 扩展期行。
> [Lighthouse-Alpha] 项均与共享规约 18（动态采集流水线）/ 20（监控字典）严格对齐。

### §3.5.5 [Lighthouse-Alpha] The Architect 监控字典 JSON Schema（严格对齐 PRD §3.3）

**承接 PRD §3.3 阶段三（The Architect）**：大模型必须输出包含**具体网址 / 数据途径 / HS 编码**的 JSON 字典；本节固定 schema，由 §3.5.4 LA5 引用。

**完整 schema（写 Redis + ClickHouse 时同时落库）**：

```yaml
MonitorMatrix:
  thesis_card_id: str            # 关联 D2 thesis_cards.thesis_card_id
  target_company: str            # 自然语言名称，如 "中际旭创 (300308)"
  symbol: str                    # 代码，如 "300308"
  generated_by:
    model_name: str              # claude-opus-4-7
    prompt_template_id: str      # the_architect_v1
    generated_at: datetime
    tokens_used: int
  monitor_matrix:
    - field_id: str              # 业务字段 ID，如 "field_001"
      probe_id: P5 | P6 | P7     # 与 D3 §6A.1 探针映射
      metric_name: str           # 如 "光模块对美出口高频数据"
      data_source_type: STRUCT_DATA_API | WEB_SCRAPING
      source_api: str | null     # STRUCT_DATA_API 时必填，如 "akshare.macro_china_customs()"
      source_url: str | null     # WEB_SCRAPING 时必填，如 "https://www.ccgp.gov.cn"
      specific_target: str       # 如 "HS Code: 85176239 (光通信设备), 目的地: 美国"
      keywords: list[str]        # WEB_SCRAPING 时建议；如 ["智算中心", "液冷", "冷板式", "中标候选人"]
      alert_threshold: str       # 自然语言（人审阅），与 PRD 一致
      alert_threshold_struct:    # 结构化（机器执行），D3 §6A.3 强制双形式
        operator: gt | lt | mom_pct | yoy_pct | sum_pct
        value: float
        window_days: int
      polling_frequency: daily | monthly_after_release
      mapped_logic_chain_nodes: list[str]   # 关联 thesis 卡逻辑链节点 ID（D2 §二）
      status: active | stale     # 90 天无写入命中 → stale（D3 §6A.3 死字段 GC）
      created_at: datetime
      last_hit_at: datetime | null
```

**示例 1（PRD §3.3 算力互联网络 1.6T · HS Code 触发 P6 海关探针）**：

```json
{
  "thesis_card_id": "thesis_300308_1p6t_optical_20260520",
  "target_company": "中际旭创 (300308)",
  "symbol": "300308",
  "generated_by": {
    "model_name": "claude-opus-4-7",
    "prompt_template_id": "the_architect_v1",
    "generated_at": "2026-05-20T10:30:00Z",
    "tokens_used": 1842
  },
  "monitor_matrix": [{
    "field_id": "field_optical_export_us",
    "probe_id": "P6",
    "metric_name": "光模块对美出口高频数据",
    "data_source_type": "STRUCT_DATA_API",
    "source_api": "akshare.macro_china_customs()",
    "source_url": null,
    "specific_target": "HS Code: 85176239 (光通信设备), 目的地: 美国",
    "keywords": [],
    "alert_threshold": "每月20日发布上月数据时，环比增长 > 30% 且单价飙升",
    "alert_threshold_struct": {
      "operator": "mom_pct",
      "value": 0.30,
      "window_days": 30
    },
    "polling_frequency": "monthly_after_release",
    "mapped_logic_chain_nodes": ["node_supply_demand_mismatch", "node_overseas_demand"],
    "status": "active",
    "created_at": "2026-05-20T10:30:00Z",
    "last_hit_at": null
  }]
}
```

**示例 2（PRD §3.3 散热革命 全液冷 · keyword 触发 P5 政府招标探针）**：

```json
{
  "thesis_card_id": "thesis_002837_liquid_cooling_20260520",
  "target_company": "英维克 (002837)",
  "symbol": "002837",
  "generated_by": {
    "model_name": "claude-opus-4-7",
    "prompt_template_id": "the_architect_v1",
    "generated_at": "2026-05-20T11:15:00Z",
    "tokens_used": 2103
  },
  "monitor_matrix": [{
    "field_id": "field_liquid_cooling_bid",
    "probe_id": "P5",
    "metric_name": "智算中心液冷标段集采金额",
    "data_source_type": "WEB_SCRAPING",
    "source_api": null,
    "source_url": "https://www.ccgp.gov.cn",
    "specific_target": "中国政府采购网 / 三大运营商电子采购平台",
    "keywords": ["智算中心", "液冷", "冷板式", "中标候选人"],
    "alert_threshold": "近30天累计中标金额超上一年度总营收 20%",
    "alert_threshold_struct": {
      "operator": "sum_pct",
      "value": 0.20,
      "window_days": 30
    },
    "polling_frequency": "daily",
    "mapped_logic_chain_nodes": ["node_supply_demand_mismatch", "node_capacity_elasticity"],
    "status": "active",
    "created_at": "2026-05-20T11:15:00Z",
    "last_hit_at": null
  }]
}
```

**硬约束**：

| # | 约束 | 不通过动作 |
|---|---|---|
| MA1 | **schema jsonschema 必须 validate 通过** | 写 Redis 前拒绝；落 DLQ；告警 The Architect 大模型 prompt 异常 |
| MA2 | **alert_threshold + alert_threshold_struct 双形式** | 缺一拒绝；防止 D3 探针无结构化字段无法自动判定 |
| MA3 | **probe_id 必须是 P5/P6/P7 之一** | 与 D3 §6A.1 探针 ID 映射严格对账 |
| MA4 | **HS Code / source_url / keywords 至少一项不为空** | 全空 = 无法触发任何探针 → 拒绝 |
| MA5 | **mapped_logic_chain_nodes 非空** | 监控字典必须能反向追溯到 D2 thesis 卡某个逻辑链节点；否则 D3 探针告警时无法关联 |
| MA6 | **status 死字段 GC** | 90 天无 last_hit_at 更新 → status=stale；由架构师月度复审 |

> The Architect 是 Lighthouse-Alpha 进攻能力的**核心落脚点**（PRD §3.3 原话）——它把大模型的"想法"翻译成 D3 探针能消费的结构化字典，是"思想 → 工程"的关键桥梁。本 schema 与 L2 §8A 监控字典消费契约 + 共享规约 20 监控字典规约**三处严格对齐**。

## §4 真实数据源与凭证清单

### §4.1 数据源

| 资源 | 用途 |
|---|---|
| akshare | 财报、财务指标、公告列表、行业成分 |
| 巨潮 cninfo | 公告全文 |
| `my_holdings.yaml` | 标的清单 |
| `cryo_guard.db`（可选）| 共源同步 |

### §4.2 用户须提供

| 凭证 | 用途 | 何时 | 位置 |
|---|---|---|---|
| `MY_HOLDINGS_YAML` | SoT | **本步前必填** | `.env` |
| 网络 | eastmoney + cninfo | 采集时 | — |

> **禁止** `THESIS_GENERATOR_MODE=stub`、`-mock` 进入本步业务路径。

## §5 启动期目标

### §5.1 数据范围

- **标的**：SoT 中 `active=true`（典型 4~10 只）
- **期数**：每标的财务指标 ≥ 4 个季度（支撑 qoq）
- **公告**：每标的 ≥ 10 条（近 12 个月）

### §5.2 数据量门槛（必要不充分）

| 指标 | 最小值 | 验证 SQL |
|---|---|---|
| `financial_indicators` 行数 | active 数 × 4 | `SELECT symbol, COUNT(*) ... GROUP BY symbol` |
| `announcements` 行数 | active 数 × 10 | 同上 |
| `industry_peers` | 每 symbol ≥ 3 | 同上 |
| §3.5 矩阵 | 全 ✅/⚠️ | `validate_deep_strike_data_quality.py` 退出码 0 |

### §5.3 可接受退化

- akshare 限流 → 指数退避 + 降并发；仍失败写 `failed_ingest.log`；
- 巨潮全文失败 → 保留标题+url，不计入 E2 全文率分子；
- D1 共源不可用 → 全量 D2 自采。

## §6 下一步（一行触发条件）

- **触发条件**：本步 ✅ + §3.5 矩阵绿 → step_03 证据链可开工。
- **扩展期**：全市场候选池采集；见 `stage_2_扩展期/`。

## §7 实施规划

### §7.1 实现要点

| 要点 | 代码位置 | 设计决策 | 验证 |
|---|---|---|---|
| **A ORM 4 表** | `db/models.py` + alembic | 字段对齐 §3 表；`financial_indicators` 含 5 信号全部列 | migration OK |
| **B akshare 源** | `data/sources/akshare_source.py` | 5 函数：report/indicator/announcements/peers/quote；节流 `DEEP_INGEST_THROTTLE_SEC` | 1 symbol 小批成功 |
| **C 巨潮全文** | `data/sources/cninfo_source.py` | 重试 3 次；失败入 log | 抽样 3 条 url 可开 |
| **D normalizer** | `data/normalizer.py` | 中文列名→英文字段；单位统一（%→小数）| 单测映射 |
| **E validator** | `data/validator.py` | 毛利率 0~1；qoq 异常 >30% 告警 | 单测边界 |
| **F repository upsert** | `data/repository.py` | 按 (symbol, period) 唯一 | 重跑幂等 |
| **G ingest CLI** | `data/ingest.py` | 读 SoT → 可选 sync D1 → 采集 → 摘要 3 行中文 | 全 active 跑通 |
| **H 共源同步** | `data/sync_from_cryo.py` | ATTACH cryo_guard.db 只读 COPY announcements 缺则补 | 有 D1 时行数增加 |
| **I 质量脚本** | `training/scripts/validate_deep_strike_data_quality.py` | 扫 §3.5 21 项（含 §3.5.4 9 项 Lighthouse-Alpha）| 退出码 0 |
| **J 单测** | `tests/deep_strike/test_data_ingest.py` + `test_sniffer_*.py` | mock HTTP only in tests | ≥ 6 passed（持仓侧）+ ≥ 4 passed（嗅探侧）|
| **[L-α] K Playwright 物理采集层** | `data/sniffer/playwright_runner.py` + 三 spider | 共享 Playwright 实例池；UA 轮换；3s 间隔；429/反爬退避；输出 raw_text 投 Kafka `sniffer_raw_text` | 1 spider 烟测 ≥ 1 条 raw_text |
| **[L-α] L NLP 聚类初筛** | `data/sniffer/clusterer.py` | TF-IDF 关键词频；与 7 日 baseline 对比；增长 ≥ 200% → 候选簇；落 `sniffer_clusters` | 单测 mock 1000 文档 → 触发 ≥ 1 簇 |
| **[L-α] M 监控字典生产端** | `data/sniffer/monitor_dict_writer.py` | The Architect 大模型（**Claude Opus 4.7**）按 prompt 模板生成 JSON；`jsonschema.validate` 通过后写 Redis + ClickHouse | 1 标的生成 + Redis 可读回 + jsonschema 通过 |
| **[L-α] N 动态采集流水线契约** | `data/sniffer/pipeline.py` 实现共享规约 18 | `CrawlTaskConfig` Redis 热加载 + `content_hash` 去重 + DLQ + crawl_logs 落库 | 改 Redis config 5min 内热生效 |
| **[L-α] O 调度** | K8s CronJob（生产）/ APScheduler（本机）| 每源不同 cron：ccgp 6h、research 4h、overseas 12h；可配置驱动 | `make deep-step02-sniffer-status` 显示最近 N 次调度 |

### §7.2 Makefile 合约

| target | 用途 | 入参 | 验证 |
|---|---|---|---|
| `make deep-step02-prep` | SoT 自检 + alembic | `MY_HOLDINGS_YAML` | active 非空 |
| `make deep-step02-sync-cryo` | 可选 D1 共源 | `CRYO_DB=data/cryo_guard.db` | 有则同步 |
| `make deep-step02-collect` | 全 active 采集 | `MY_HOLDINGS_YAML / DEEP_INGEST_THROTTLE_SEC` | 行数达 §5.2 |
| `make deep-step02-quality-check` | §3.5 矩阵 | — | 退出码 0 |
| `make deep-step02-test` | pytest | — | ≥ 6 passed |
| `make deep-step02-all` | 端到端 | 合并 | 全 0 |
| `make deep-step02-status` | 快照 | — | 每 symbol 行数 |
| `make deep-step02-clean` | 清 4 表业务数据 | `FORCE=1` | 已清 |
| **[L-α]** `make deep-step02-sniffer-prep` | 校验 Kafka topic / Redis 键空间 / Playwright 浏览器就绪 | `KAFKA_BROKERS / REDIS_URL` | 全部 ready |
| **[L-α]** `make deep-step02-sniffer-once` | 单源单轮抓取（开发用）| `SOURCE=ccgp\|research\|overseas` | ≥ 1 条 raw_text |
| **[L-α]** `make deep-step02-sniffer-day` | 三源一日完整采集 + 聚类 + 监控字典生成 | 同 prep | 满足 §3.5.4 LA1~LA4 |
| **[L-α]** `make deep-step02-sniffer-quality-check` | §3.5.4 LA1~LA9 矩阵 | — | 退出码 0 |

**合约**：配置驱动（改 yaml 增标的 → 重跑 collect；改 Redis `sniffer:crawl_config:*` 热加载嗅探任务）；可重入；失败可观察。
**嗅探合约补充**：`make deep-step02-sniffer-*` 与持仓侧 `deep-step02-*` 解耦，可独立跑；`deep-step02-all` 含两者。

### §7.3 关键代码片段（中间道）

#### 7.3.1 `financial_indicators` 表 schema（5 信号支撑 · 核心 ~12 行）

```python
class FinancialIndicator(Base):
    __tablename__ = "financial_indicators"
    id = Column(Integer, primary_key=True)
    symbol = Column(String(16), nullable=False, index=True)
    report_period = Column(String(16), nullable=False)   # 2024Q3 / 2024_annual
    # ── 利润截留 5 信号字段 ──
    gross_margin = Column(Numeric(8, 4))                  # 0~1
    gross_margin_qoq = Column(Numeric(8, 4))              # 季度环比变化
    revenue_growth_yoy = Column(Numeric(8, 4))
    cost_growth_yoy = Column(Numeric(8, 4))
    net_profit_growth_yoy = Column(Numeric(8, 4))
    receivable_turnover = Column(Numeric(10, 4))
    receivable_turnover_qoq = Column(Numeric(8, 4))
    inventory_turnover = Column(Numeric(10, 4))
    inventory_turnover_qoq = Column(Numeric(8, 4))
    # ── 元数据 ──
    missing_fields = Column(JSON)                          # ["receivable_turnover", ...]
    source = Column(String(32))                            # 'akshare'
    __table_args__ = (UniqueConstraint("symbol", "report_period", name="uq_symbol_period"),)
```

#### 7.3.2 中文列名映射 normalizer（核心 ~12 行 · 关键算法）

```python
AKSHARE_INDICATOR_CN_TO_EN = {
    "毛利率": "gross_margin",
    "营业总收入同比增长": "revenue_growth_yoy",
    "营业总成本同比增长": "cost_growth_yoy",
    "净利润同比增长": "net_profit_growth_yoy",
    "应收账款周转率": "receivable_turnover",
    "存货周转率": "inventory_turnover",
}

def normalize_indicator(row_cn: dict) -> dict:
    en = {AKSHARE_INDICATOR_CN_TO_EN[k]: v for k, v in row_cn.items()
          if k in AKSHARE_INDICATOR_CN_TO_EN}
    # 百分比 → 小数（akshare 多为百分数）
    for pct_field in ["gross_margin", "revenue_growth_yoy",
                       "cost_growth_yoy", "net_profit_growth_yoy"]:
        if en.get(pct_field) is not None and abs(en[pct_field]) > 5:
            en[pct_field] = en[pct_field] / 100
    return en
```

#### 7.3.3 qoq 衍生计算（核心 ~10 行 · 4 期连续校验）

```python
def derive_qoq(df_indicator):
    """按 symbol + period 排序，计算环比衍生字段。"""
    df = df_indicator.sort_values(["symbol", "report_period"])
    df["gross_margin_qoq"] = df.groupby("symbol")["gross_margin"].diff()
    df["receivable_turnover_qoq"] = (
        df.groupby("symbol")["receivable_turnover"].pct_change()
    )
    df["inventory_turnover_qoq"] = (
        df.groupby("symbol")["inventory_turnover"].pct_change()
    )
    # 期数不足 4 期的 symbol 标 history_insufficient
    counts = df.groupby("symbol").size()
    insufficient = counts[counts < 4].index.tolist()
    return df, insufficient
```

#### 7.3.4 §3.5 矩阵质量脚本骨架（核心 ~15 行）

```python
def check_quality_matrix(db_url: str) -> dict:
    results = {}
    with engine.connect() as conn:
        # S1: 每 active 标的 ≥ 4 期
        symbols = active_symbols_from_sot()
        for sym in symbols:
            n = conn.execute(text("SELECT COUNT(*) FROM financial_indicators "
                                  "WHERE symbol=:s"), {"s": sym}).scalar()
            results[f"S1_{sym}"] = "ok" if n >= 4 else f"insufficient ({n})"
        # E2: 公告全文率
        total = conn.execute(text("SELECT COUNT(*) FROM announcements")).scalar()
        with_text = conn.execute(text("SELECT COUNT(*) FROM announcements "
                                      "WHERE LENGTH(content) >= 200")).scalar()
        rate = with_text / total if total else 0
        results["E2_fulltext_rate"] = f"{rate:.2%} {'ok' if rate>=0.7 else 'warn'}"
        # ... S2~C3 类似
    failed = [k for k,v in results.items() if "ok" not in v and "warn" not in v]
    return {"results": results, "exit_code": 0 if not failed else 1}
```

### §7.4 给后续执行模型指引

1. 先 `prep` → 可选 `sync-cryo` → `collect` → **必须** `quality-check` 再宣称准出；
2. 临时增 1 个 active 标的验证配置驱动（§9.4）；
3. 禁止 mock 入库；API 不可用**等待**用户修网络/凭证。

## §8 部署节奏

| 形态 | 必须 | 说明 |
|---|---|---|
| **本机** | **是** | python ingest + pytest |
| **K3s** | 否 | 采集不上集群 |

## §9 准出标准

### §9.1 数据量
- [ ] §5.2 行数门槛全过

### §9.2 质量（§3.5 · 12 项）
- [ ] `validate_deep_strike_data_quality.py` 退出码 0

### §9.3 工程 + 一键复现
- [ ] `make deep-step02-all` 通过
- [ ] **配置驱动**：增 1 active → 重跑 collect → 新 symbol 有数据
- [ ] L4 实践记录含矩阵填表 + SQL 证据
- [ ] commit：`feat(deep-strike): step_02 真实数据采集 + 质量矩阵 + Makefile [Ref: 03_/02_维度二/.../step_02]`

## §10 [Deploy] 段

本步无镜像；数据落本机 SQLite。

## §11 依赖与被依赖

**上游**：step_01；`MY_HOLDINGS_YAML`；网络；可选 D1 step_02；**[L-α]** 共享规约 18（动态采集流水线）+ 20（监控字典 schema）已定稿；Kafka 集群可达；The Architect 大模型 API key（监控字典生成必需）。

**下游**：step_03/04 消费 `financial_indicators` + `announcements`；**[L-α]** step_03 The Critic 消费 `sniffer_raw_text` 与 `sniffer_clusters`；step_04 The Mapper 消费聚类候选；step_07 The Scorer 消费聚类原文；**D3 step_03** 物理量探针消费 Redis `monitor:{symbol}:dict:*`；**D5 step_01** ETL LLM Engine 消费 Kafka `sniffer_raw_text` 做结构化抽取。

**严禁伪造**（no-mock-policy）：禁止 mock fixture 入 `deep_strike.db`；禁止 `--mock` 生产路径；**[L-α]** 禁止伪造 Playwright 抓取结果入 Kafka；禁止用 hardcoded 关键词冒充 The Architect 输出的监控字典。

## §12 风险与回退

| 触发 | 动作 |
|---|---|
| akshare 限流 | 退避 + 减并发 |
| 5 信号字段大面积 null | 回查 normalizer 列名映射；对照 L3 §2.1 |
| 矩阵不绿但行数够 | **不准出**；补采或扩期数 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v3.1 Lighthouse-Alpha 融合**：在原有持仓侧采集基础上 merge_inplace 融入主动嗅探通道——§1 一句话扩+ 4 交付物 I/J/K/L；§3 表追加 5 个嗅探数据对象；§3.5 新增 §3.5.4 矩阵 9 项（LA1~LA9）；§7.1 实现要点追加 K~O 五项；§7.2 Makefile 追加 4 个 sniffer target；§11 依赖与下游补全嗅探消费方；与共享规约 18（动态采集）+ 20（监控字典）严格对齐 |
| 2026-05-21 | **v3.2 The Architect JSON Schema 补完**：v3.1 中 The Architect 监控字典仅有引用未给完整 schema，PRD §3.3 明确要求"包含具体网址 / 数据途径 / HS 编码"的结构化输出。本次新增 §3.5.5 完整子节：①MonitorMatrix yaml schema（含 thesis_card_id / target_company / monitor_matrix[].probe_id [P5/P6/P7] / source_api / specific_target [HS Code 格式] / alert_threshold + alert_threshold_struct 双形式 / mapped_logic_chain_nodes / status[active/stale]）；②PRD §3.3 两个完整示例 JSON（中际旭创 1.6T HS Code 85176239 触发 P6 + 英维克液冷 ccgp keyword 触发 P5）；③6 项硬约束（MA1~MA6：jsonschema validate / 双形式 / probe_id 严格对账 / HS Code 或 url 或 keywords 至少一项 / mapped_logic_chain_nodes 非空 / 死字段 GC 90 天）；与 L2 §8A 监控字典消费契约 + 共享规约 20 严格三处对齐 |
| 2026-05-21 | **v3 中间道细化**：保留 v2 §3.5 矩阵 12 项；§7.3 新增 4 个关键片段（financial_indicators schema / 中文列名映射 normalizer / qoq 衍生算法 / §3.5 质量脚本骨架）；209→~390 行 |
| 2026-05-20 | **v2 L3 v1.2 重写**：删嵌入 Python/mock fixture/离线 stub；§3.5 12 项质量矩阵；SoT + D1 共源；Makefile `deep-step02-*`；1089→~320 行 |
| 2026-05-16 | 初版含 mock fallback，1089 行 |
