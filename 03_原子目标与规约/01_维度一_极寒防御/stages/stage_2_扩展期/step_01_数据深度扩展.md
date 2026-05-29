# Step 01 · 数据深度扩展（扩展期）

> **本步定位**：D1 极寒防御维度扩展期数据采集与质量提升。**承接**启动期金标准（8 只持仓股）；**目标**扩量到 30~100 只 + 时间窗扩到 8 年 + 关联方穿透 3 层 + 新增 6 类深度字段 + N1 噪音率从 ≤55% 降到 ≤30%。
>
> **不重复设计**：启动期已有的 11 张表 / 8 类公告 / OCR 流程**不重新设计**；本步只**升级口径 + 扩量 + 扩深**。
>
> **重要**：本 step 严格遵守 [`_共享规约/L3_启动期step_重构模板.md`](../../../../_共享规约/L3_启动期step_重构模板.md) 同款 13 节骨架（扩展期适配）。

---

## §1 一句话定位与本步交付物

**做完本步**：D1 cryo_guard 服务对**持仓 + 候选池 100 只标的**拥有 8 年完整数据，关联方网络穿透 3 层，新增**应收账款账龄 / 商誉构成 / 大股东诉讼 / 循环交易识别 / 明股实债 / 业绩对赌履约** 6 类深度字段；OCR 噪音率从启动期 55% 降到 ≤30%；为 step_02（扩展期 Teacher 蒸馏 3500 case 基线）准备数据。

**交付物**：
- [ ] **A**（11 张表扩量 + 6 张新表）：
  - `financial_reports` ≥ 4800 行（100 标的 × 8 年 × 6 类报告，新增"招股书 / 重组方案"）
  - `announcements` ≥ 30000 条；扩到 **12 类**（新增重大资产重组 / 股东诉讼 / 募资变更 / 商誉减值）
  - `related_party_raw` ≥ 100000 行；**N1 噪音率 ≤ 30%**
  - `related_party_graph` ≥ 3000 节点（3 层穿透 · 含实控人 / 一致行动人）
  - **`accounts_receivable_aging`**（新建 · 应收账款账龄）
  - **`goodwill_breakdown`**（新建 · 商誉构成穿透）
  - **`shareholder_litigation`**（新建 · 大股东诉讼）
  - **`circular_trading_flags`**（新建 · 循环交易识别 · 由 `related_party_graph` 衍生）
  - **`disguised_equity_debt`**（新建 · 明股实债识别）
  - **`performance_commitment`**（新建 · 业绩对赌履约跟踪）
- [ ] **B**（§3.5 扩展期质量矩阵 · **31 项**）：F1~F10 + S1~S10 + R1~R8 + C1~C3 + N1~N4
- [ ] **C**（增量调度）：月度 + 公告增量；CI 每日跑 `validate_quality_matrix.py` 阈值告警
- [ ] **D**（存储升级）：SQLite → PostgreSQL + Redis 缓存（仅扩量场景需要；启动期 SQLite 继续兼容）
- [ ] **E**（DVC 远端）：本地 → MinIO / S3 remote
- [ ] **F**（单测）：扩展期新 6 表与 N1≤30% 抽样测试 ≥ 30 passed

---

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **上游 step**：← [启动期 step_02_数据采集与50案例Holdout](../stage_1_启动期/steps/step_02_数据采集与50案例Holdout.md)（§6.5 长期推演已锁三档门槛）
> - **金标准基准**：[`金标准_8只持仓股数据验收清单.md`](../../../../../04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/金标准_8只持仓股数据验收清单.md)
> - **L2 哲学**：[01_维度一_极寒防御 · 04_防御实践策略规划](../../../../../02_战略维度/01_维度一_极寒防御/04_防御实践策略规划.md)
> - **DNA 键**：`_System_DNA/01_cryo_guard/dna_stage_2_扩展期.yaml`（Phase 2 待创建）
> - **下游 step**：→ [`step_02_Teacher蒸馏深化.md`](step_02_Teacher蒸馏深化.md)（扩展期 3500 case 基线）
> - **触发条件**：启动期 21 项质量矩阵全 ✅ + Teacher 蒸馏 100 条 Verified + D1 step_04 LoRA P=0.6 + 架构师签字

---

## §3 数据采集对象（扩展期新增）

| 业务对象 | ORM 表（新建 / 扩列） | 数据源 | 采集脚本 | 备注 |
|---|---|---|---|---|
| 应收账款账龄 | **新建 `accounts_receivable_aging`**（`symbol/year/aging_bucket/amount/percentage`）| 年报附注「应收账款按账龄分类」表 | 扩展 `ocr_financial_notes.py` + 新增 `_extract_aging_table` | 6 档账龄（1年内 / 1-2 / 2-3 / 3-4 / 4-5 / 5+）|
| 商誉构成穿透 | **新建 `goodwill_breakdown`**（`symbol/year/acquired_entity/initial_value/impairment/method`）| 年报附注「商誉减值测试」 | 扩展 `ocr_financial_notes.py` + `_extract_goodwill` | 含每笔商誉的减值方法与折现率 |
| 大股东诉讼 | **新建 `shareholder_litigation`**（`symbol/case_no/plaintiff/defendant/amount/status`）| 巨潮诉讼公告 + 启信宝 API（启动期未启用）| 新增 `crawl_litigation.py` | 启动期降级：仅采公告标题，金额由 Teacher 抽 |
| 循环交易标记 | **新建 `circular_trading_flags`**（`symbol/cycle_path/total_amount/year/confidence`）| 由 `related_party_graph` 衍生（图算法识别 cycle） | 新增 `detect_circular_trading.py` | NetworkX 找环 + 金额闭合校验 |
| 明股实债 | **新建 `disguised_equity_debt`**（`symbol/year/entity/declared_type/inferred_type/evidence`）| `related_party_raw` + `accounts_receivable_aging` 联合推断 | 新增 `detect_disguised_debt.py` | 启动期不做；扩展期 Critic 引擎依赖 |
| 业绩对赌履约 | **新建 `performance_commitment`**（`symbol/commitment_year/target_metric/target_value/actual_value/met`）| 重大资产重组公告 + 历年业绩公告对照 | 新增 `track_performance_commitment.py` | S5 启动期稀疏；扩展期补全 |

**扩列**：
- `announcements.ann_type` 扩到 **12 类**（新增"重大资产重组 / 股东诉讼 / 募资变更 / 商誉减值"）
- `related_party_graph` 扩列：`controller_layer`（穿透层级 1~3）、`is_circular`（是否在循环交易环上）

---

## §3.5 数据质量验收矩阵（扩展期 · 31 项 · 仅本阶段负责）

> **本节范围**：扩展期负责的 31 项质量要求。每行 ✅ 已覆盖 / ⚠️ 扩展期内有降级 / ❌（仅当本步未覆盖且转完善期负责）。
> **巴菲特原则升级**：扩展期不接受"看了 8 类公告就算看了披露"——还须看附注 6 类深度字段 + 关联方 3 层穿透 + 大股东诉讼 + 循环交易识别。

### §3.5.1 财务测谎（D1 step_04 扩展期 · 10 项）

| # | 维度 | 必产字段 | 状态 | 降级 |
|---|---|---|---|---|
| F1~F5 | 启动期同 6 项（升级口径 · 100 标的 × 8 年）| 同启动期 | ✅ 由启动期升级 | — |
| F6 | **应收账款账龄异常**（≥ 3 年占比 > 30% = 信号）| `accounts_receivable_aging` | ⚠️ 新建表 | OCR 表格抽取，降级靠 Teacher |
| F7 | **商誉构成穿透**（单笔商誉 > 净资产 30% = 高风险）| `goodwill_breakdown` | ⚠️ 新建表 | 同上 |
| F8 | **资本化研发口径深查**（按子公司明细 · 不只总额）| 扩列 `rd_capitalized_by_subsidiary` JSON | ⚠️ 启动期 F4 升级 | Teacher 抽 |
| F9 | 启动期同（升级到 100 标的）| 同启动期 | ✅ | — |
| F10 | 启动期同（升级 + 与 R6 循环交易联动）| 同启动期 + `circular_trading_flags` | ✅ | — |

### §3.5.2 大股东诚信（D1 step_05 扩展期 · 10 项）

| # | 维度 | 必产字段 | 状态 | 降级 |
|---|---|---|---|---|
| S1~S7 | 启动期同 7 项（升级口径 · 100 标的 × 8 年）| 同启动期 | ✅ 由启动期升级 | — |
| S8 | **业绩对赌履约**（覆盖至完整生命周期）| `performance_commitment` | ⚠️ 新建表 | 跨年对照 + Teacher 抽 |
| S9 | **大股东诉讼**（涉案金额 / 主营资产比）| `shareholder_litigation` | ⚠️ 新建表 | 启动期降级到公告标题 |
| S10 | **募资变更**（募资改投与业绩偏差）| `announcements WHERE ann_type='募资变更'` | ⚠️ ann_type 扩 12 类 | Teacher 抽金额与时间 |

### §3.5.3 关联交易（D1 step_06 扩展期 · 8 项）

| # | 维度 | 必产字段 | 状态 | 降级 |
|---|---|---|---|---|
| R1~R4 | 启动期同 4 项（升级 N1 噪音率 ≤ 30%）| 同启动期 | ✅ 由启动期升级 | N1 升级路径见 §3.5.5 |
| R5 | **关联方 3 层穿透**（控股 → 实控 → 一致行动）| `related_party_graph.controller_layer` | ⚠️ 扩列 | 启动期 1 层 → 扩展期 3 层 |
| R6 | **循环交易识别**（图算法找环）| `circular_trading_flags` | ⚠️ 新建表 | NetworkX 找环 + 金额闭合 |
| R7 | **明股实债识别**（关联 + 账龄联合）| `disguised_equity_debt` | ⚠️ 新建表 | 多表 join + Teacher 复审 |
| R8 | **关联担保金额量化**（净资产占比）| `related_party_raw.amount` 在担保类的覆盖率 | ⚠️ 启动期 R4 升级 | Teacher 抽 |

### §3.5.4 共用维度（扩展期 · 3 项）

| # | 维度 | 必产字段 | 状态 | 降级 |
|---|---|---|---|---|
| C1~C2 | 启动期同（升级 100 标的）| 同启动期 | ✅ | — |
| **C3** | **跨标的对标基线**（同行业前 N 位与本标的对比）| 新增 `industry_baseline` view | ⚠️ 新建视图 | SQL view 即可 |

### §3.5.5 数据卫生（扩展期 · 4 项）

| # | 维度 | 必产字段 | 状态 | 降级 |
|---|---|---|---|---|
| N1 | **OCR 噪音率 ≤ 30%**（关联交易表）| `is_noise` 列 + 升级规则 | ⚠️ 启动期 55% → 扩展期 30% | 升级 `_classify_noise` + 加 ML 二分类器（LightGBM） |
| **N2** | **公告 content 完整率 ≥ 95%**（正文型）| `announcements.content` | ⚠️ 启动期 90% → 扩展期 95% | 升级 PDF 抽取 + 失败重试 |
| **N3** | **重复数据率 ≤ 2%**（按业务主键去重）| 各表 UNIQUE 索引 | ⚠️ 新建索引 | DB level UNIQUE 约束 |
| **N4** | **跨表一致性**（`related_party_raw` 公司名 ↔ `related_party_graph.party_name`）| 一致性脚本 | ⚠️ 新建脚本 | `check_cross_table_consistency.py` |

> 共 **31 项扩展期质量要求** = F1~F10 + S1~S10 + R1~R8 + C1~C3 + N1~N4。
> 复核脚本：`training/scripts/validate_quality_matrix_stage2.py`（待新建）。

---

## §4 真实数据源与凭证清单

### §4.1 新增数据源

| 数据类型 | 推荐源 | 是否收费 | 备份源 |
|---|---|---|---|
| 诉讼公告 | 巨潮 + **启信宝 API**（扩展期启用）| 启信宝付费（约 ¥3000/年）| 天眼查 / 企查查 |
| 重组方案 | 巨潮重大资产重组 | 免费 | — |
| 行业基线 | Wind / iFind（扩展期）| 付费 | akshare 行业指数（降级）|

### §4.2 用户须提供的凭证（扩展期新增）

| 凭证 | 用途 | 何时需要 | 必填 |
|---|---|---|---|
| `QICHA_API_KEY`（启信宝）| 大股东诉讼 + 关联方穿透 | 扩展期 step_01 开工时 | **必填**（约 ¥3000/年）|
| `WIND_API_KEY`（可选）| 行业基线 | 同上 | 可降级到 akshare |
| PostgreSQL DSN | 扩展期存储升级 | 数据量 > 100k 行后 | **必填** |

---

## §5 扩展期目标（数据量 / 标的范围 / 时间窗）

### §5.1 标的范围
- 8 持仓 + 92 候选池（架构师在 `my_holdings.yaml` 增 `active=true` 标的至 100 只；或新建 `candidate_pool.yaml`）
- 候选池选择标准：① 沪深 300 全集；② 行业分布与持仓互补；③ 含 5~10 只 Holdout 备选案例（暴雷股，做训练样本）

### §5.2 时间窗
- 8 年（2018~2025）；公告窗口 `2018-01-01 .. 2025-12-31`
- **新增报告类型**：招股书（IPO 时点）+ 重组方案（事件触发）

### §5.3 数据量门槛（**金标准 + 行数门槛**）

| 表 | 扩展期最小行数 | 计算口径 |
|---|---|---|
| `financial_reports` | **≥ 4800** | 100 × 8 × 6 类 |
| `announcements` | **≥ 30000** | 100 × 8 × 12 类公告 |
| `related_party_raw` | **≥ 100000** | 100 × 8 × 年报附注 |
| `related_party_raw` 有效率 | **≥ 80%** | `1 - N1` |
| `related_party_graph` | **≥ 3000** | 100 × ≥ 30 关联方（3 层穿透）|
| `accounts_receivable_aging` | **≥ 600** | 100 × ≥ 6 年 |
| `goodwill_breakdown` | **≥ 200** | 标的有商誉的 × 年 |
| `shareholder_litigation` | ≥ 50（有诉讼的标的 × 年）| 启动期未采，扩展期补 |
| `circular_trading_flags` | 任意（衍生 · 仅观察）| 找到几个就几个 |
| `disguised_equity_debt` | 任意（衍生 · 仅观察）| 同上 |
| `performance_commitment` | ≥ 100（重组事件 × 年）| 时间窗内有重组的 |

---

## §6 下一步（一行触发条件）

- **触发条件**：本步 §3.5 31 项矩阵全 ✅ / ⚠️ + 数据量门槛全达 + 单测 ≥ 30 passed → 进入 [`step_02_Teacher蒸馏深化.md`](step_02_Teacher蒸馏深化.md)（3500 case 基线）
- **下一阶段方向**：完善期数据精量与全量化（全 A × 10 年 + 实时增量）；见 [`stage_3_完善期/step_01_数据精量与全量化.md`](../stage_3_完善期/step_01_数据精量与全量化.md)（Phase 2 新建）

## §6.5 长期推演（扩展期 → 完善期 二档质量门槛 · 简表）

承接 [启动期 step_02 §6.5](../stage_1_启动期/steps/step_02_数据采集与50案例Holdout.md#65-长期推演启动期--扩展期--完善期-三档质量门槛-给后续模型的工作指引) 三档表的「扩展期」「完善期」列；本节仅作引用，**禁止**在此重写。

---

## §7 实施规划（L3 设计 · 给后续执行模型的工作指引）

> **L3 定位**：本节是**设计规划 + 实现要点 + 验证标准**——**不嵌入完整代码**；具体落地由 L4 实践记录 / 后续执行模型按本节规划自行完成。

### §7.1 实现要点（按交付物拆分）

| 实现要点 | 涉及代码位置 | 关键设计决策 | 验证标准 |
|---|---|---|---|
| **A 候选池 SoT 扩展** | `data/config/my_holdings.yaml` 或新建 `data/config/candidate_pool.yaml` | 持仓不变；新增 `candidates` 段（max 92 只）；`active=true` 字段升级语义为"主持仓"，新增 `tier='watch'` 候选池标识 | `active_symbols() + watch_symbols()` 合计 100 只 |
| **B 6 张新表 + 扩列 alembic** | `apps/cryo_guard/db/models.py` | 6 张新表 + `controller_layer` + `is_circular` 列 + 12 类 `ann_type` 兼容 | alembic upgrade 后 `.tables` 含 17 张表（11 启动 + 6 新建）|
| **C 公告 12 类扩展** | `crawl_announcements.py::_classify_ann_type` | 在 8 类基础上加 4 类（重大资产重组 / 股东诉讼 / 募资变更 / 商誉减值）+ 兼容旧分类 | 12 类各有日志记录 |
| **D 8 年时间窗扩量** | `CRYO_YEARS=2018,...,2025` + Makefile 增 `cryo-stage2-collect` | 启动期 4 年向后扩到 8 年；按 throttle 控制总耗时 | 100 标的端到端 ≤ 8 小时 |
| **E 应收账款账龄 OCR** | 新增 `ocr_financial_notes.py::_extract_aging_table` | 识别"应收账款按账龄分类"表头 + 6 档桶 | `accounts_receivable_aging` ≥ 600 行 |
| **F 商誉构成穿透 OCR** | 同上 `_extract_goodwill` | 识别"商誉减值测试"表 + 折现率字段 | `goodwill_breakdown` ≥ 200 行 |
| **G 关联方 3 层穿透** | 新增 `training/scripts/build_3layer_graph.py` | 用启动期 1 层基础 + 启信宝 API 穿透实控人 / 一致行动人；NetworkX 持有 graph 对象 | `related_party_graph.controller_layer` 分布在 1~3 |
| **H 循环交易识别** | 新增 `detect_circular_trading.py` | NetworkX `simple_cycles` + 金额闭合校验（误差 ≤ 5%）| `circular_trading_flags` 行数 ≥ 0（有就抓，无也不阻塞）|
| **I 明股实债识别** | 新增 `detect_disguised_debt.py` | 多表 join + Teacher 复审（取 100 个候选交 Teacher 判断）| `disguised_equity_debt` ≥ 30（启动期暴雷案例必含）|
| **J 业绩对赌跟踪** | 新增 `track_performance_commitment.py` | 重组公告抽承诺 + 历年业绩对照 + 计算 `met`（达成）| `performance_commitment` ≥ 100 行 |
| **K 大股东诉讼采集** | 新增 `crawl_litigation.py` | 启信宝 API（付费）+ 巨潮诉讼公告 | `shareholder_litigation` ≥ 50 行 |
| **L N1 噪音率升级到 ≤ 30%** | 升级 `clean_related_party_noise.py` + 新增 ML 二分类器 | LightGBM 训练 in：标记 1000 条人工标注（启动期 1194 有效 + 1000 噪音抽样）out：is_noise 概率 ≥ 0.7 标 1 | N1 ≤ 30% |
| **M PostgreSQL 迁移**（可选）| 新增 `apps/cryo_guard/db/pg_migrator.py` | 仅当总行数 > 100k 触发；启动期 SQLite 保留作为 fallback | psql DSN 可读 |
| **N CI 每日 + 阈值告警** | `.github/workflows/data_quality.yml` 或 K3s CronJob | 每日跑 `validate_quality_matrix_stage2.py`；任一 ❌ 发 Slack/邮件 | CI 历史可见 ≥ 7 天 |

### §7.2 Makefile 一键复现合约

| target | 用途 | 入参 | 验证 |
|---|---|---|---|
| `make cryo-stage2-prep` | alembic upgrade 17 表 + 候选池自检 | `MY_HOLDINGS_YAML / CANDIDATE_POOL_YAML` | 退出码 0 |
| `make cryo-stage2-collect` | 一键扩量采集（100 标的 × 8 年 × 12 类公告 + 6 张新表）| 同上 + `CRYO_YEARS` | 17 表全部 upsert 完成 |
| `make cryo-stage2-quality-check` | 31 项矩阵复核 | — | `validate_quality_matrix_stage2.py` 退出码 0 |
| `make cryo-stage2-noise-upgrade` | N1 噪音率从 55% 降到 30%（含 ML 训练） | — | N1 ≤ 30% |
| `make cryo-stage2-pg-migrate`（可选）| PG 迁移 | `POSTGRES_DSN` | 数据完整 + 行数一致 |
| `make cryo-stage2-test` | 单测 | — | ≥ 30 passed |
| `make cryo-stage2-all` | 端到端一键 | 同上合并 | 全部 ✅；100 标的 ≤ 8h |
| `make cryo-stage2-status` | 数据量 + 31 项矩阵快照（**只读**）| — | 打印 17 表 COUNT + §3.5 覆盖率 |

### §7.3 给后续执行模型的指引

L4 / 执行模型按以下顺序：
1. **核对前置**：启动期金标准全 ✅ + Teacher 100 case + LoRA P=0.6 + 架构师签字（否则不开工）；
2. **逐项落地 A~N**：每项产出独立可跑；落地后跑对应「验证标准」；
3. **集成 Makefile**：按 §7.2 合约表实现 8 个 target；
4. **§9 准出清单逐项打勾** + 同会话给证据；
5. **回写 L4 实践记录**：每个 ⚠️ 项的实际状况、§3.5 31 项填表；
6. **遇问题**：按 `00_系统规则` §7.2 第 6 条 Verify First；同问题修复重试 ≥ 2 次仍失败再回收。

---

## §8 部署节奏（本步在哪里跑）

| 阶段 | 形态 | 是否必须 |
|---|---|---|
| 本机开发 | 持续；扩展期采集仍在本机起 | 必须 |
| Dev K3s | PG/Redis 起 K3s | 数据量 > 100k 时必须 |
| ACR + 生产 K3s | CronJob 跑增量 | CI 每日扩量必须 |

---

## §9 准出标准

### §9.1 数据量门槛（§5.3 全部达标）
- [ ] 17 张表行数全达 §5.3

### §9.2 数据质量门槛（§3.5 矩阵 · 31 项）
- [ ] 31 行全 ✅ 或 ⚠️ 有降级；`validate_quality_matrix_stage2.py` 退出码 0

### §9.3 工程交付
- [ ] Makefile 8 target 落地
- [ ] CI 每日跑 `validate_quality_matrix_stage2.py`
- [ ] L4 实践记录已按 §8.4g 更新

---

## §10 [Deploy] 段

PG/Redis 由 Chart 部署：`deploy/charts/postgres-cryo`、`deploy/charts/redis-cryo`（部署仓 Phase 2 新建）。CronJob：`deploy/charts/cronjob-cryo-stage2-daily`。

---

## §11 依赖与被依赖

**上游**：← 启动期 step_01~07 全 ✅；用户提供 `QICHA_API_KEY` + `POSTGRES_DSN`
**下游**：→ step_02（扩展期 Teacher 3500 case 基线）；→ D2 deep_strike 扩展期共用扩量数据

---

## §12 风险与回退

| 触发 | 动作 |
|---|---|
| 启信宝 API 限流 | 切天眼查；同一原因 ≥ 2 次 → 降级仅采公告标题 |
| 8 年时间窗采集 > 8h | 分批次（每批 25 标的）+ throttle ↑ |
| N1 ML 分类器训练样本不足 1000 | 用启动期 1194 有效 + 主动学习扩 |
| PG 迁移 schema 不兼容 | 回退 SQLite + 提 ADR 修订 |
| 同问题 ≥ 2 次失败 | 按 `00_系统规则` §8.4f 回收 |

---

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-23 | **v1.0 初版**（关键重构 · 与 `00_系统规则` §4.5 同步）：用户要求"长期推演加到步骤里，便于低中模型不跑题"。变更：①新建本文件（11 节骨架）；②承接启动期 21 项矩阵 → 扩展期 31 项；③新增 6 张表 + 4 类公告；④N1 噪音率 55% → 30% 升级路径；⑤Makefile 8 target；⑥与启动期金标准 + step_03 §6.5 形成跨阶段质量门槛闭环 |
