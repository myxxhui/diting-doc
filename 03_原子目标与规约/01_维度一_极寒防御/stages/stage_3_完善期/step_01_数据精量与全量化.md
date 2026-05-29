# Step 01 · 数据精量与全量化（完善期）

> **本步定位**：D1 极寒防御维度完善期数据采集与质量精炼。**承接**扩展期 100 标的 8 年数据 + 17 张表 + 31 项矩阵；**目标**扩到**全 A 5000+ 标的 × 10+ 年** + 实时增量 + N1 噪音率 ≤ 10% + 多语种附注 + 机构持仓穿透 + ESG 披露。
>
> **不重复设计**：扩展期已有的 17 张表 / 12 类公告 / 6 张深度字段表**不重新设计**；本步只**继续扩量到全 A + 升级口径**。

---

## §1 一句话定位与本步交付物

**做完本步**：D1 cryo_guard 对**全 A 5000+ 上市公司 × 10 年**拥有实时增量数据；OCR 噪音率 ≤ 10%；新增多语种附注 + 机构持仓 N 层穿透 + ESG 披露 + 表外资金占用 + 隐性担保识别。为 step_02（完善期 Teacher 精炼 10000+ case）准备数据。

**交付物**：
- [ ] **A**（17 张表 + 8 张完善期新表）：
  - 扩展期 17 张表全量扩到 5000 标的
  - **新增**：`institutional_holdings`（机构持仓 N 层穿透）
  - **新增**：`off_balance_funds`（表外资金占用识别）
  - **新增**：`implicit_guarantee`（隐性担保 · 由表外推断）
  - **新增**：`esg_disclosure`（ESG 与可持续披露）
  - **新增**：`multilingual_notes`（多语种附注 · 港股 / 海外子公司）
  - **新增**：`real_time_anomaly`（实时异常 · CDC 触发）
  - **新增**：`data_lineage`（数据血缘 · 每行数据来源追溯）
  - **新增**：`audit_committee_qa`（审计委员会问答 · 业绩说明会 transcript 抽取）
- [ ] **B**（§3.5 完善期质量矩阵 · **45 项**）：F1~F15 + S1~S15 + R1~R10 + C1~C5
- [ ] **C**（实时增量 · CDC + Kafka）：T+1 实时入库
- [ ] **D**（存储升级）：PostgreSQL → **ClickHouse + Elasticsearch + Object Storage**
- [ ] **E**（数据治理）：LakeFS + 完整 lineage + SLI/SLO 仪表盘
- [ ] **F**（单测）：扩展期新表 + 实时增量 + 多语种 ≥ 80 passed

---

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **上游 step**：← [扩展期 step_01_数据深度扩展](../stage_2_扩展期/step_01_数据深度扩展.md) §3.5 31 项全 ✅
> - **L2 哲学**：[01_维度一_极寒防御 · 04_防御实践策略规划](../../../../../02_战略维度/01_维度一_极寒防御/04_防御实践策略规划.md)
> - **三档质量门槛总表**：[启动期 step_02 §6.5](../stage_1_启动期/steps/step_02_数据采集与50案例Holdout.md#65-长期推演启动期--扩展期--完善期-三档质量门槛-给后续模型的工作指引)（本 step 实现「完善期」列）
> - **下游 step**：→ [`step_02_Teacher精炼.md`](step_02_Teacher精炼.md)（10000+ case + 多模型投票）
> - **触发条件**：扩展期 31 项矩阵全 ✅ + Teacher 3500 case + 三引擎 LoRA P=0.85 + 架构师签字

---

## §3 数据采集对象（完善期新增）

| 业务对象 | ORM 表（新建）| 数据源 | 采集脚本 | 备注 |
|---|---|---|---|---|
| 机构持仓 N 层穿透 | `institutional_holdings`（`symbol/holder/holder_type/ratio/layer/source`）| 巨潮 + WIND + 私募排排网 + SEC（海外）| `crawl_institutional_holdings.py` | N 层 = 公募 → 私募 → 投顾 → 实际控制人 |
| 表外资金占用 | `off_balance_funds`（`symbol/year/entity/amount/inferred_method`）| `related_party_raw` + `shareholder_litigation` + Critic 引擎推断 | `detect_off_balance.py` | LLM 推断（Sonnet）+ 架构师抽审 |
| 隐性担保 | `implicit_guarantee`（`symbol/year/guarantor/amount/evidence`）| `off_balance_funds` + `related_party_graph` 联合 | 同上 | 仅当多重证据时入库 |
| ESG 披露 | `esg_disclosure`（`symbol/year/dimension/score/source`）| ESG 报告 PDF + Wind ESG | `crawl_esg.py` | 启动期 + 扩展期未做，完善期补 |
| 多语种附注 | `multilingual_notes`（`symbol/lang/raw_text/translated_text/source`）| 港股年报 EN + 海外子公司公告 | `crawl_multilingual.py` + Claude 翻译 | LLM 翻译 + 架构师审 |
| 实时异常 | `real_time_anomaly`（`symbol/event_time/anomaly_type/severity/data_link`）| CDC（Debezium）+ Kafka | `realtime_anomaly_engine.py` | 触发实时告警 |
| 数据血缘 | `data_lineage`（`table/row_id/source_url/extracted_at/extractor_version`）| 所有采集脚本写 | `lineage_writer.py` | 每行数据可溯源 |
| 审计委员会问答 | `audit_committee_qa`（`symbol/meeting_date/question/answer/sentiment`）| 业绩说明会 transcript | `parse_earnings_call.py` + LLM | 多模态（音频 → 文本）|

---

## §3.5 数据质量验收矩阵（完善期 · 45 项 · 仅本阶段负责）

> **本节范围**：完善期负责的 45 项质量要求。**强约束**：本节是矩阵骨架；具体每行指标 / 阈值 / 降级方案 / 必产字段，由架构师在执行本 step 时按当时业界 SOTA 与监管要求细化。

### §3.5.1 财务测谎（D1 step_04 完善期 · 15 项）
启动期 6 + 扩展期 +4 = 10 项继承；完善期新增 5 项（待 Phase 3 细化）：
- F11 表外资金占用率
- F12 隐性担保占净资产比
- F13 多语种附注异常（海外子公司）
- F14 ESG 与财务披露一致性
- F15 审计委员会问答情绪偏差

### §3.5.2 大股东诚信（D1 step_05 完善期 · 15 项）
扩展期 10 + 完善期新增 5 项（待 Phase 3 细化）：
- S11 机构持仓 N 层穿透完整率
- S12 实时减持事件检出延迟（≤ 5 分钟）
- S13 跨境关联识别
- S14 一致行动人隐藏度
- S15 ESG 治理评分与监管违规相关性

### §3.5.3 关联交易（D1 step_06 完善期 · 10 项）
扩展期 8 + 完善期新增 2 项：
- R9 跨境关联交易检出（含离岸架构）
- R10 关联方网络变更率（年度对比 · 频繁变更 = 信号）

### §3.5.4 共用维度（完善期 · 5 项）
C1~C3 继承 + 新增：
- C4 行业拐点检测（财务集体异常 = 行业风险）
- C5 监管处罚跨年趋势

### §3.5.5 数据卫生（完善期 · 已升级）
- N1：OCR 噪音率 ≤ **10%**（多模态 LLM 视觉 OCR + 表格结构识别）
- N2：公告 content 完整率 ≥ **99%**
- N3：重复数据率 ≤ **0.5%**
- N4：跨表一致性 100%
- **N5（新增）**：数据延迟 SLI（CDC → ClickHouse ≤ 5 分钟，99 分位）

> 共 **45 项完善期质量要求**。复核脚本：`training/scripts/validate_quality_matrix_stage3.py`（Phase 3 新建）。

---

## §4 真实数据源与凭证清单

### §4.1 新增数据源
| 数据类型 | 推荐源 | 备份 |
|---|---|---|
| 机构持仓 | WIND + 私募排排网 + SEC EDGAR（海外）| 巨潮 + 启信宝 |
| ESG | Wind ESG + 商道融绿 | 公司自披露 |
| 多语种附注 | 港交所 / SEC | 海外子公司官网 |
| 实时增量 | Debezium CDC | Kafka Connect |

### §4.2 用户须提供的凭证
| 凭证 | 必填 | 估算成本 |
|---|---|---|
| `WIND_API_KEY` | **必填** | ¥30000/年 |
| `SEC_EDGAR_KEY` | 可选 | 免费 |
| `ClickHouse / ES` 集群 DSN | **必填** | 自建或云 |
| `Kafka` cluster DSN | **必填** | 同上 |

---

## §5 完善期目标

### §5.1 标的范围
- **全 A 5000+** 上市公司（沪深京全市场）
- 含港股通 + 中概股（多语种附注）

### §5.2 时间窗
- **10+ 年**（2015~至今） + 实时增量

### §5.3 数据量门槛
| 表 | 完善期最小行数 |
|---|---|
| `financial_reports` | ≥ 200000 |
| `announcements` | ≥ 1500000 |
| `related_party_raw` | ≥ 2000000 |
| `institutional_holdings` | ≥ 500000 |
| `real_time_anomaly` | T+1 实时（无最小行数 · 看 SLI）|

### §5.4 SLI/SLO 指标
- 数据延迟：CDC → CH ≤ 5 min（99 分位）
- 数据完整性：每日跑 N1~N5 矩阵；任一红灯发 Slack
- 数据可用性：99.5% 月度 uptime

---

## §6 下一步（一行触发条件）

- **触发条件**：本步 45 项矩阵全 ✅ + SLI 持续 30 天达标 → 进入 [`step_02_Teacher精炼.md`](step_02_Teacher精炼.md)（10000+ case + 多模型投票）
- **下一阶段方向**：完善期之后进入运维优化（持续 OPS）；无新 stage

---

## §7 实施规划（L3 设计 · 给后续执行模型的工作指引）

> **L3 定位**：**不嵌入完整代码**；具体落地由 L4 实践记录 / 后续执行模型完成。

### §7.1 实现要点（按交付物拆分）

| 要点 | 涉及代码 | 关键决策 | 验证 |
|---|---|---|---|
| A 全 A 候选池扩量 | `data/config/full_a_pool.yaml`（新建）| 5000 标的 SoT；按板块 / 行业分批 | active+watch = 5000 |
| B 8 张新表 + 多模态 ORM | `apps/cryo_guard/db/models.py` + alembic | 表结构 + 索引 + lineage 钩子 | 25 张表 |
| C 机构持仓 N 层穿透 | 新增 `crawl_institutional_holdings.py` | 启动期 1 层 → 扩展期 3 层 → 完善期 N 层 | `holdings_layer` 分布 |
| D 表外资金占用推断 | 新增 `detect_off_balance.py` | Sonnet 推断 + 多证据约束 + 架构师抽审 | `off_balance_funds` ≥ 200（暴雷案例必含）|
| E 隐性担保识别 | 新增 `detect_implicit_guarantee.py` | 同上 + Critic 评分 ≥ 0.7 | `implicit_guarantee` ≥ 100 |
| F ESG 披露采集 | 新增 `crawl_esg.py` | Wind ESG 主源 + 商道融绿备源 | `esg_disclosure` ≥ 5000 |
| G 多语种附注 + 翻译 | 新增 `crawl_multilingual.py` + Claude/OpusKB | 港股 EN → ZH 翻译 + 架构师审 | `multilingual_notes` ≥ 500 |
| H 实时增量（CDC + Kafka） | 新增 `realtime_anomaly_engine.py` + Debezium 配置 | 财报 / 公告变更触发 CDC | SLI ≤ 5 min |
| I 业绩说明会 transcript | 新增 `parse_earnings_call.py` | 音频 → 文本（Whisper）+ LLM 抽 QA | `audit_committee_qa` ≥ 5000 |
| J ClickHouse + ES + Object Storage 迁移 | 部署仓 Chart + 数据迁移脚本 | 全量 PG → CH/ES 一次性迁移 + 双写 | 行数一致 |
| K LakeFS + lineage + SLI 仪表盘 | 新增 `lineage_writer.py` + Grafana dashboard | 每行入 lineage 表；CH 写 SLI | 仪表盘可见 30 天 |
| L N1 噪音率从 30% 降到 10% | 升级 `clean_related_party_noise.py` + 多模态视觉 OCR | PP-Structure / Claude Opus 多模态 | N1 ≤ 10% |
| M CI + 数据治理平台 | 新增 `data_governance/` 模块 | 数据合约 + 自动回滚 + 自动重训 | 持续 30 天 ≥ 99.5% uptime |

### §7.2 Makefile 一键复现合约

| target | 用途 | 验证 |
|---|---|---|
| `make cryo-stage3-prep` | 25 表 alembic + 全 A SoT + CH/ES 就绪 | 退出码 0 |
| `make cryo-stage3-collect` | 全 A 扩量采集 | 25 表全 upsert |
| `make cryo-stage3-realtime` | CDC + Kafka 启动 | SLI ≤ 5 min |
| `make cryo-stage3-quality-check` | 45 项矩阵 | 退出码 0 |
| `make cryo-stage3-noise-upgrade` | N1 ≤ 10% | 多模态 OCR |
| `make cryo-stage3-migrate-ch` | PG → CH 迁移 | 行数一致 |
| `make cryo-stage3-test` | 单测 | ≥ 80 passed |
| `make cryo-stage3-all` | 端到端 | 全 ✅；5000 标的 ≤ 72h |

### §7.3 给后续执行模型的指引

L4 / 执行模型按以下顺序：
1. **核对前置**：扩展期 31 项矩阵全 ✅ + Teacher 3500 case + LoRA P=0.85 + 架构师签字；
2. **按 A~M 逐项落地**；
3. **集成 Makefile** 8 target；
4. **§9 准出清单** + 同会话证据；
5. **回写 L4 实践记录**；
6. **遇问题** 按 `00_系统规则` §7.2 第 6 条 Verify First。

---

## §8 部署节奏

| 阶段 | 形态 | 必须 |
|---|---|---|
| 本机开发 | Whisper / 多语种 LLM 在本机 | 是 |
| Dev K3s | ClickHouse / ES / Kafka / Debezium | 是 |
| 生产 K3s | 同上 + CronJob + 实时数据流 | 是 |

---

## §9 准出标准

### §9.1 数据量门槛（§5.3 全部达标）
- [ ] 25 张表行数全达 §5.3

### §9.2 数据质量门槛（§3.5 矩阵 · 45 项）
- [ ] 45 行全 ✅ 或 ⚠️ 有降级；`validate_quality_matrix_stage3.py` 退出码 0

### §9.3 SLI/SLO 持续达标
- [ ] CDC 延迟 ≤ 5 min（99 分位 · 持续 30 天）
- [ ] 数据可用性 99.5%（月度）
- [ ] 任一红灯告警响应时间 ≤ 10 min

### §9.4 工程交付
- [ ] Makefile 8 target 落地
- [ ] CI 每日跑 + 阈值告警
- [ ] LakeFS lineage 完整
- [ ] L4 实践记录回写

---

## §10 [Deploy] 段

完善期部署涉及 6 个新组件（ClickHouse + ES + Kafka + Debezium + LakeFS + Grafana），全部由 Chart 部署：`deploy/charts/cryo-stage3-stack`（部署仓 Phase 3 新建）。

---

## §11 依赖与被依赖

**上游**：← 扩展期 step_01~06 全 ✅；用户提供 `WIND_API_KEY` + CH/ES/Kafka 集群
**下游**：→ step_02（完善期 Teacher 10000+ case 精炼）

---

## §12 风险与回退

| 触发 | 动作 |
|---|---|
| WIND API 限流 | 切第三方备源；同一原因 ≥ 2 次 → 降级到 akshare 全 A |
| CDC 延迟 > 5 min | 排查 Kafka 消费能力；不达 SLI 阻断生产 |
| 多模态 OCR 成本爆 | 降级到 PP-Structure（纯本地） |
| ClickHouse 迁移失败 | 双写期保留 PG fallback |
| 同问题 ≥ 2 次失败 | 按 `00_系统规则` §8.4f 回收 |

---

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-23 | **v1.0 初版**（关键重构 · 与 `00_系统规则` §4.5 同步）：用户要求完善期长期推演加到步骤里。变更：①新建本文件（13 节骨架）；②承接扩展期 31 项 → 完善期 45 项；③新增 8 张表（机构持仓 N 层 / 表外资金 / 隐性担保 / ESG / 多语种 / 实时异常 / 数据血缘 / 审计 QA）；④存储升级 PG → CH+ES+OS；⑤实时增量 CDC + Kafka；⑥SLI/SLO 达标 30 天；⑦Makefile 8 target；⑧与启动期金标准 + 扩展期 step_01 形成跨 3 阶段质量门槛闭环 |
