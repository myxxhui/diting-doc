# Step 02 · 数据采集与 50 案例 Holdout 永久锁库

> **本步 v2 重构（2026-05-20）** 已迁移到 [`_共享规约/L3_启动期step_重构模板`](../../../../_共享规约/L3_启动期step_重构模板.md)
> 13 强制小节框架。**删除所有 Mock 相关**：占位 fixture 仅在 `tests/` 单元测试合法。

## §1 一句话定位与本步交付物

**做完本步**：D1 cryo_guard 服务对**持仓 SoT 中 4 个真实标的**拥有完整 4 年财报三表 + 五类公告 PDF 全文 + 年报附注关联交易 OCR 数据；同时 **50 案例 Holdout 永久锁库**（与持仓 SoT **解耦**，仅作训练守门用），D5 step_02 Teacher 蒸馏与 D1 step_04~06 LoRA 训练可基于真实数据继续。

**交付物**（勾选 = 完成）：
- [ ] **A**（5 张表 + 持仓 SoT 标的真实数据入库）：
  - `financial_reports` ≥ 64 行（4 标的 × 4 年 × 4 类报告）且 `industry` 非 null
  - `announcements` ≥ 30 条且 `content` 非空率 ≥ 90%（**7 类**含人事变动 + 监管问询）
  - `related_party_raw` ≥ 50 行且 `pricing_method` 非 null 率 ≥ 50%
  - `related_party_graph` ≥ 8 行（启动期最小关联方网络骨架）
  - `failed_ocr_pages` 已就绪（OCR 失败页 ≤ 5%）
- [ ] **B**（**§3.5 数据质量验收矩阵 · 仅启动期负责的 18 项**）：F1/F2/F3/F4/F9/F10 + S1/S2/S3/S4/S5/S6 + R1/R2/R3/R4 + C1/C2，每项均为 ✅ 覆盖 或 ⚠️ 启动期有降级路径（**无 ❌**）
- [ ] **C**（50 案例 Holdout 锁库）：`training/data/holdout/H001~H050.json` + `manifest.json`（SHA256）+ 文件 `chmod -w`
- [ ] **D**（守门器）：`holdout_guard.py --verify` 退出码 0；含 Holdout symbol 的训练 jsonl 退出码 1
- [ ] **E**（DVC 版本控制）：财报 DB / 附注 PDF / Holdout 三个数据集 `dvc status` 干净
- [ ] **F**（单元测试）：`pytest tests/cryo_guard/test_data_pipeline.py -q` 全绿

> **数据质量优于数据量**（与 `00_系统规则` 规则生效要点表"数据采集质量优先于数据量"一致）：启动期**不**要求"全 A × 5 年 ≥ 22500 行"——但**要求**对 4 标的做"巴菲特式深度采集"（附注 / 披露 / 事件链 / 质性披露 / 关联方穿透），细节见 §3.5。全 A 量级是扩展期目标（见 §6）。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2 哲学**：[01_维度一_极寒防御 · 04_防御实践策略规划](../../../../../02_战略维度/01_维度一_极寒防御/04_防御实践策略规划.md)
> - **本阶段总览**：[stage_1_启动期/README](../README.md)
> - **L3 数据规约**：[../03_数据采集与预处理.md](../03_数据采集与预处理.md) §一~§八
> - **L3 验收**：[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md) §四
> - **DNA 键**：`_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml#deliverables.holdout`、`#training_data_scale.teacher_distill`
> - **L4 实践记录**：[实践记录_step_02_数据采集与50案例Holdout](../../../../../04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_02_数据采集与50案例Holdout.md)
> - **持仓 SoT**：[`diting-src/data/config/my_holdings.example.yaml`](../../../../../../diting-src/data/config/my_holdings.example.yaml) · 加载器 `apps/common/holdings_sot.py`
> - **全局开发地图**：[14_六维度启动期统一节奏表 §3.2](../../../../_共享规约/14_六维度启动期统一节奏表.md#32-维度一--极寒防御-cryo_guard10-step--三引擎反诈骗)
> - **上游 step**：← `step_01_环境与基础设施`（SQLite/ORM/alembic 就绪）
> - **下游 step**：→ `step_03_Teacher蒸馏`（依赖本步真实财报与公告做证据链）；→ `step_04/05/06 LoRA 训练`（依赖 Holdout 守门防污染）

## §3 数据采集对象 / 落库映射

| 业务对象 | ORM 表 / 关键字段 | 数据源 | 采集脚本（diting-src） | 备注 |
|---|---|---|---|---|
| 财务三表 + 行业归类 | `financial_reports`（`raw_*` JSON + 归一化列 `revenue/net_profit/cash_and_equivalents/...` + **`industry`**） | **Akshare**（底层东财 + `stock_industry_category_cninfo`） | `training/data/scripts/crawl_financial_reports.py` | `raw_*` 含东财英文键；归一化列同时映射中英文键；`industry` 列**新增**（§3.5.4·C2） |
| 公告（**7 类**：增持/减持/业绩/质押/战略/**人事变动/监管问询**） | `announcements`（`title / ann_date / ann_type / url / content / raw_json`） | **巨潮 cninfo PDF 全文**（默认）；东财仅元数据 | `training/data/scripts/crawl_announcements.py` | `ANN_TYPES` 启动期扩到 7 类（§3.5.2·S3/S6）；`content` 必须非空（PDF 抽出）；缺失时 `CRYO_ANN_ENRICH_EMPTY=1` 补全 |
| 关联交易明细（年报附注） | `related_party_raw`（`party_name / relationship / transaction_type / **pricing_method** / amount / raw_text / pdf_page_no`） | **巨潮年报 PDF + pdfplumber + 可选 PaddleOCR** | `training/data/scripts/ocr_financial_notes.py` | `CRYO_NOTES_FETCH_PDF=1` 时先下年报 PDF 再扫描；启动期补完 `_detect_pricing_method` 抽取（§3.5.3·R3） |
| **关联方网络图骨架**（新建） | `related_party_graph`（`symbol / party_name / parent_party / controller / source_pdf_page`） | 同上（年报「关联方关系图」页） | 同上（在 `ocr_financial_notes.py` 内增 `_extract_graph` 段） | 启动期最小可用（§3.5.3·R1），扩展期补全 |
| OCR 失败页 | `failed_ocr_pages`（`symbol / report_year / page_no / pdf_path / error_reason`） | — | 同上 | 不阻塞主流程 |
| 50 案例 Holdout（与持仓 SoT 解耦） | `training/data/holdout/H001~H050.json` + `manifest.json`（SHA256） | 历史暴雷案例（架构师人工整理） | `training/scripts/build_holdout_manifest.py` + `holdout_guard.py` | **永久锁库**：`chmod -w`，禁止训练集出现这些 symbol |

**零值/缺失语义**：归一化数值列允许 `null`（财报披露口径不同）；`announcements.content` 不允许长期为空（缺则跑 enrich）；`related_party_raw.amount` 允许 `null`（OCR 抽不到金额仅留 `raw_text`）；`related_party_graph.parent_party / controller` 允许 `null`（启动期可仅写直接关联方，穿透在扩展期补）。

## §3.5 数据质量验收矩阵（按目标引擎反推 · 仅启动期负责）

> **本节范围**：仅记录**启动期**应负责的数据类型与质量检测，每行**要么 ✅ 已覆盖、要么 ⚠️ 启动期内有降级**。**不展开**扩展期 / 完善期清单（那是 `stage_2_扩展期 / stage_3_完善期` 文档的事，与本步骤无关）。
> **巴菲特原则**：不接受"看了三表就算看了财报"——启动期 4 标的虽少，但**对它们的采集深度必须达到引擎能做实质分析的程度**（附注 / 披露 / 事件链 / 网络穿透 / 定价方法 / 承诺履约一个不能少）。
> **质量门槛 > 数量门槛**：§5 行数门槛是必要不充分；本节矩阵全绿（含 ⚠️ 有降级）才能 §9 准出。

### §3.5.1 财务测谎引擎（D1 step_04）所需的分析维度（启动期负责 6 项）

| # | 分析维度（一句话） | 本步必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| F1 | **现金流-账面利润背离**（造假典型信号） | `operating_cash_flow / net_profit` 多年比值序列 | ✅ 归一化列已有 | 4 标的 × 4 年 = 16 个点对，可绘趋势 |
| F2 | **应收账款异常增长 vs 营收增速** | `accounts_receivable + revenue` 增速比 | ✅ 已有 | 衍生计算在 step_03 蒸馏证据链中完成 |
| F3 | **存贷双高**（资金虚增信号） | `cash_and_equivalents + short_term_debt + long_term_debt` 同时高位 | ✅ 已有 | — |
| F4 | **研发资本化比例**（利润粉饰信号） | `rd_capitalized / (rd_expense + rd_capitalized)` 比 | ⚠️ 字段有但东财口径混淆 | §7.8 抽样 4 标的对照年报原文校验；若错位则在 `_build_record` 修正 |
| F9 | **季度连续趋势**（启动期至关重要） | ROE / 毛利率 / 净利率 4 季走势 | ⚠️ 默认 `REPORT_TYPES=("annual",)` 仅年报 | §7.3 改默认为 `("annual","semi","q1","q3")`，4 标的 × 4 期 × 4 类 = 64 行 |
| F10 | **关联方占营收/采购比例** | 关联方交易额 / 营收 / 营业成本 | ✅ 由 `related_party_raw.amount` + `financial_reports.revenue` 衍生 | §3.5.3 R2 提供分子，§3.5.1 F1 提供分母 |

### §3.5.2 大股东诚信引擎（D1 step_05）所需的分析维度（启动期负责 7 项）

| # | 分析维度 | 本步必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| S1 | 增持/减持**承诺履约**（承诺 vs 实际） | `announcements.content` 全文 → Teacher 在 step_03 抽取承诺金额 + 完成进度 | ⚠️ 本步只保证 `content` 完整 | 抽取在 step_03；本步 §9 须**正文型公告** content 非空率 ≥ 90%（业绩/质押/战略/关联交易/增减持；人事/监管标题型不计入分母）|
| S2 | 累计持股变动 + 解禁时间表 | 增减持公告时间序列 + 解禁公告 | ✅ 元数据 + 内容齐 | 解析在 step_03 |
| S3 | **董监高变动密度**（频繁辞职 = 信号） | `ann_type='人事变动'` 类公告 | ✅ 已增「人事变动」类（关键词清单见 `crawl_announcements.py::_classify_ann_type`）| 启动期 8 只持仓 W1 实测 221 条 |
| S4 | **股权质押率**（控股质押 = 信号） | 股东质押公告 + 质押比例 | ⚠️ 在 `质押` 类公告中，比例由 Teacher 抽 | step_03 抽取 |
| S5 | **业绩对赌履约** | 重大资产重组公告 + 历年业绩承诺 + 实际达成 | ⚠️ `业绩` 类含但稀疏 | 启动期可接受稀疏（8 标的 × 4 年内事件数本就少）|
| S6 | **问询函与监管处罚** | `ann_type='监管问询'` 类公告 | ✅ 已增「监管问询」类 | 启动期允许"已尝试 + 返回 0"——但 `_classify_ann_type` 关键词清单必须含 |
| **S7** | **关联交易公告交叉验证**（公告侧 vs 附注 OCR 侧）| `ann_type='关联交易'` 类公告与 `related_party_raw` 抽取交叉核对 | ✅ 已增「关联交易」类 | 启动期 W1 实测 43 条；偏差行写入 L4 实践记录 |

### §3.5.3 关联交易引擎（D1 step_06）所需的分析维度（启动期负责 4 项）

| # | 分析维度 | 本步必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| R1 | **关联方网络图骨架**（最小可用） | `related_party_graph(symbol, party_name, parent_party, controller, source_pdf_page)` | ⚠️ 启动期新建表 + 直接关联方落库（`parent_party / controller` 允许 null） | §7.2 新建表；§7.7 在 `ocr_financial_notes.py` 加 `_extract_graph` 段，从年报「关联方关系图」页 PDF 表抽取；不要求穿透 N 层 |
| R2 | **金额占比时间序列** | 同一关联方多年累计金额 / 营收占比 | ✅ `related_party_raw.amount + report_year` 已支撑 | 4 标的 × 2 年 ≥ 50 行可绘趋势 |
| R3 | **定价方法异常** | 定价方法（市价/协议/成本+）+ 同行价偏差 | ⚠️ `pricing_method` 字段有但 OCR regex 未抽全 | §7.7 扩展 `_detect_pricing_method`（识别"市场价格"/"协议价格"/"成本加成"等关键词）；非 null 率 ≥ 50% |
| R4 | **关联担保与资金占用** | 担保金额 / 净资产 比、资金占用余额 | ⚠️ `transaction_type` 含 "担保"/"资金拆借" 但金额未必齐 | §7.7 OCR 补量级抽取 |

### §3.5.4 共用维度（启动期负责 2 项）

| # | 维度 | 本步必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| C1 | **业绩预告 / 快报 / 年报 三段对比**（D2/D3 共用） | `业绩` 类公告元数据 + content | ✅ 启动期标准 8 类已含「业绩」 | 解析在消费 step 做 |
| C2 | **同行业基线**（行业均值 / 中位数对比） | `financial_reports.industry` 列 | ✅ akshare 优先 + segment 兜底（基于 `my_holdings.yaml` 的 `segment` 字段映射）| `crawl_industry_category.py` 含两阶段；8 标的覆盖 100% |

### §3.5.5 数据卫生（启动期负责 1 项 · 跨 R 系列共用）

| # | 维度 | 本步必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| **N1** | **OCR 噪音率 ≤ 55%**（关联交易表）| `related_party_raw.is_noise` 列 + 行级噪音标注 | ✅ `clean_related_party_noise.py` 已实现 5 类噪音规则（元数据词 / 长字串 / 章节编号 / 无业务字段 / 括号说明）| 噪音 > 55% → 扩展 `_classify_noise` 规则集；金标准 ≤ 55%，扩展期 ≤ 30%、完善期 ≤ 10%（见 §6.5）|

> 共 **21 项启动期质量要求** = F1/F2/F3/F4/F9/F10 + S1/S2/S3/S4/S5/S6/**S7** + R1/R2/R3/R4 + C1/C2 + **N1**。
> 矩阵中**没有** ❌ 行——若某维度启动期不做，则**根本不出现**在本矩阵；本步骤只对自己负责。
> 21 项的复核脚本：`training/scripts/validate_quality_matrix.py`（退出码 0 = 0 个 ❌）。

### §3.5.5 质量门槛（合并到 §9.2）

矩阵每行须满足之一：
- **✅ 覆盖**：本步已落库，§9 抽样验证字段非 null 率 ≥ 90%
- **⚠️ 启动期降级**：本步给出明确降级路径（§7 中具体动作 + 引擎在该降级下仍能达到 P=0.4 baseline）

**禁止**：把字段假装填 null 然后视为达标；**禁止**在本矩阵列扩展期 / 完善期内容。

## §4 真实数据源与凭证清单

### §4.1 数据源选型

| 数据类型 | 推荐源 | 是否收费 | 备份源 |
|---|---|---|---|
| 财务三表 | **Akshare → Eastmoney**（`stock_*_by_report_em`） | 免费 | Tushare / efinance（需迁移） |
| 公告全文 | **巨潮 cninfo PDF**（`hisAnnouncement/query` + `static.cninfo.com.cn` 下载） | 免费 | 东财列表 API（**无全文**，仅元数据） |
| 年报附注 PDF | **巨潮**（与公告同源） | 免费 | — |
| OCR 引擎 | `pdfplumber` 文本抽取（首选）+ `PaddleOCR`（图片回退，可选） | 免费（本地包） | — |
| 50 案例事实核对 | 公开新闻 + 巨潮历史公告 + 行政处罚决定书 | 免费 | — |

### §4.2 用户须提供的凭证

| 凭证 | 用途 | 何时需要 | 写在哪里 | 是否必填 |
|---|---|---|---|---|
| **持仓 SoT** `my_holdings.yaml`（含 ≥ 1 只真实标的） | 本步**所有**真实数据采集的标的来源 | 执行本步**前** | `diting-src/data/config/my_holdings.yaml`（环境变量 `MY_HOLDINGS_YAML` 指向）；初次复制 example 即可 | **必填** |
| `MY_HOLDINGS_YAML` 环境变量 | 上述 yaml 路径 | 执行本步前 | `diting-src/.env` | **必填** |
| **网络可达**（akshare / 巨潮 cninfo） | 拉财报 + 公告 + PDF | 执行采集时 | 系统层；如在境内须能直连 cninfo | **必填**（无可代理） |
| `pdfplumber` Python 包 | PDF 文本抽取 | 公告 PDF + 附注 OCR | `pip install pdfplumber`（已在 `pyproject.toml` 中） | **必填** |
| `paddleocr` Python 包（可选） | OCR 回退（图像型 PDF） | 仅当 pdfplumber 抽不出文字时启用 | `pip install paddleocr`；首次会下模型权重 ~200MB | 可选 |
| `企查查 API key` | 股东穿透（启动期**不**强求） | 暂未启用代码路径 | `diting-src/.env`（如未来启用） | 否（启动期降级为 akshare 前 10 大股东） |
| `dvc` 远端（MinIO / S3 / 本地） | 数据集版本远端 | DVC push | `dvc remote add` 命令 | 启动期可用**本地远端**先跑通 |

> **本步无 LLM key 需求**——Teacher LLM key 在 D5 step_02 / D1 step_03 才需要（见 14 节奏表 §2）。

## §5 启动期目标（数据量 / 标的范围 / 时间窗）

> §5 **行数门槛 = 必要不充分**条件；真正准出由 **§3.5 数据质量验收矩阵 + §9 准出标准**联合判定。

### §5.1 标的范围
- 由 `data/config/my_holdings.yaml` 中 `active=true` 的标的决定；example 模板含 4 只（茅台 / 平安 / 神华 / 富联）。
- 启动期**只采**这 4 只；扩展期再到候选池（见 §6）。

### §5.2 时间窗 + 报告类型
- **时间窗**：由 `defaults.crawl_years` 决定，默认 `[2022, 2023, 2024, 2025]`；公告窗口取 `min(年)-01-01 .. max(年)-12-31`。
- **报告类型**：启动期默认采集 **全部四类**（`annual / semi / q1 / q3`）以支撑 §3.5.1·F9「季度连续趋势」；可通过 `CRYO_REPORT_TYPES=annual,semi,q1,q3` 显式覆盖。
- 可通过 `.env` 覆盖：`CRYO_YEARS=2023,2024,2025,2026`。

### §5.3 数据量预期（最低门槛 · 必要不充分）

| 表 | 启动期最小行数 | 计算口径 | 验证 SQL |
|---|---|---|---|
| `financial_reports` | **≥ 64**（≥ 128 = 8 标的金标准）| 标的数 × 年数 × 4 类报告（annual/semi/q1/q3） | `SELECT COUNT(*) FROM financial_reports;` 且 `SELECT report_type, COUNT(*) FROM financial_reports GROUP BY report_type;` |
| `financial_reports.industry` | 全标的非 null（**§3.5.4·C2**） | 每只标的 1 条行业映射（akshare 优先 + segment 兜底） | `SELECT COUNT(*) FROM financial_reports WHERE industry IS NOT NULL;` |
| `financial_reports.roe` | ≥ 90% 非 null | `roe = net_profit / (total_assets - total_liabilities)` 由 `crawl_financial_reports.py` 自动计算 | `SELECT COUNT(*) FROM financial_reports WHERE roe IS NOT NULL;` |
| `announcements` | **≥ 30**（≥ 800 = 8 标的金标准），且**正文型**公告 `content` 非空率 ≥ 90% | 标的 × **8 类公告**（业绩/质押/战略/**人事变动/监管问询/关联交易**/增持/减持，§3.5.2·S3/S6/S7）| `SELECT ann_type, COUNT(*) FROM announcements GROUP BY ann_type;` 与 `SELECT COUNT(*) FROM announcements WHERE ann_type IN ('业绩','质押','战略','关联交易','增持','减持') AND (content IS NULL OR LENGTH(content)<200);` |
| `related_party_raw`（总行数）| **≥ 50** | 标的 × 近 2 年年报附注（含噪音） | `SELECT COUNT(*) FROM related_party_raw;` |
| `related_party_raw`（**有效交易行**）| **≥ 50**（金标准 ≥ 800） | `is_noise=0 AND transaction_type ∈ 12 类` （由 `clean_related_party_noise.py` 标注）| `SELECT COUNT(*) FROM related_party_raw WHERE is_noise=0 AND transaction_type IN ('销售','采购','租赁','劳务','借款','担保','资金拆借','代付','服务','委托','股权','资产');` |
| `related_party_raw.pricing_method`（有效行覆盖率）| ≥ 50% | **分母 = 有效交易行**（**N1 去噪后**）；金标准 100% | `WHERE is_noise=0 AND transaction_type IN (12类) AND pricing_method IS NOT NULL` |
| `related_party_graph`（新建） | **≥ 8**（金标准 ≥ 100）| 关联方网络图最小骨架（**§3.5.3·R1**） | `SELECT COUNT(*) FROM related_party_graph;` |
| **`related_party_raw.is_noise`**（**N1 噪音率**）| ≤ 55% | `clean_related_party_noise.py` 实施 5 类噪音规则；金标准 ≤ 55% / 扩展期 ≤ 30% / 完善期 ≤ 10% | `SELECT COUNT(*) FROM related_party_raw WHERE is_noise=1` ÷ 总行数 |
| `failed_ocr_pages` | 任意（仅观察） | OCR 失败页占总扫描页 ≤ 5% | `SELECT COUNT(*) FROM failed_ocr_pages;` |
| Holdout 文件 | **= 50**（H001~H050） | 与持仓 SoT 无关 | `ls training/data/holdout/H*.json \| wc -l` |

> 上表行数是"够开工的下限"。**充分准出**还要 §3.5 矩阵每行满足 ✅ / ⚠️ 有降级 / ❌ 有扩展期承接。

### §5.4 可接受退化
- akshare 限流 → 缩短 `CRYO_YEARS` 至最近 2 年，但保持 4 类报告齐全（4 标的 × 2 年 × 4 类 = 32 行）；
- 巨潮 cninfo PDF 拉不到（部分老公告退市公司）→ `content` 可暂为 null，**但**须在 L4 实践记录写"哪几条 / 为什么"，**禁止**填充假文本；
- OCR 失败页 → 写入 `failed_ocr_pages`，不阻塞 Holdout 锁库与后续 step；
- 「人事变动 / 监管问询」类启动期**不达 3 条**时，可降为"已尝试采集且至少有日志显示巨潮该关键词返回 0 条"——**不得**用其它类公告冒充。

## §6 下一步（触发条件 · 一行 · 不展开扩展期细节）

- **触发条件**：当本步 8 标的产出可被 D5 step_02 蒸馏出 ≥ 100 条 Verified 案例 **且** D1 step_04 LoRA 在 Holdout 上达到 **P=0.6** 时，进入下一阶段 [`stages/stage_2_扩展期/step_01_数据深度扩展.md`](../../stage_2_扩展期/step_01_数据深度扩展.md)。
- **下一阶段范围**：持仓池扩量、时间窗扩长、新增数据类型（应收账款账龄 / 商誉构成 / 大股东诉讼 / 循环交易识别 / 明股实债等）的清单与质量要求**在 stage_2 文档独立维护，与本步骤无关**。本 step **只对启动期 §3.5 矩阵中的 21 项负责**。

## §6.5 长期推演（启动期 → 扩展期 → 完善期 三档质量门槛 · 给后续模型的工作指引）

> **本节定位**：把"启动期数据"的扩量与质量提升路径**预先推演到完善期**，**写入本 step**——目的是让后续低/中模型在 stage_2/stage_3 接手时，**严格对齐本表**不偏离方向；具体执行 step 文档见 §7 链接。
>
> **强约束**：①本节**不**是 stage_2/stage_3 的代替品（详细 step 仍在对应 stage 目录维护）；②本节是**门槛表 + 检测口径**，让架构师与执行模型**在同一张表里看到 3 阶段全貌**，便于反推每个阶段任务的难度与凭证；③低/中模型不得修改本表门槛——如需调整须先在 L3 修订并提交。

### §6.5.1 三档质量门槛总表（D1 极寒防御维度）

| 维度 | 启动期（stage_1，本 step）| 扩展期（stage_2 · step_01）| 完善期（stage_3 · step_01）|
|---|---|---|---|
| **标的范围** | 8 只 active 持仓 | 30~100 只（持仓 + 候选池）| 全 A 5000+ 上市公司 |
| **时间窗** | 4 年（2022~2025）| 8 年（2018~2025）| 10+ 年（2015 至今） + 实时增量 |
| **报告类型** | annual + semi + q1 + q3（4 类齐）| 同左 + 历史招股书 + 重组方案 | 同左 + 配股 / 定增 / 业绩说明会 transcript |
| **公告 ann_type 类别数** | 8 类（业绩 / 质押 / 战略 / 人事变动 / 监管问询 / 关联交易 / 增持 / 减持） | 12+ 类（+ 重大资产重组 / 股东诉讼 / 募资变更 / 商誉减值）| 20+ 类（+ ESG / 可持续披露 / 多语种附注）|
| **关联方网络深度** | 1 层（直接关联方）| 3 层穿透（控股股东 / 实控人 / 一致行动人）| N 层穿透 + 机构持仓追溯 |
| **OCR 字段深度** | 11 字段（party / relationship / transaction_type / amount / pricing_method ...）| + 担保金额 / 资金占用余额 / 同行价偏差 / 关联担保期限 | + 表外资金占用 / 隐性担保 / 商誉构成穿透 |
| **OCR 噪音率（N1）** | ≤ 55%（清洗后）| ≤ 30%（更严 regex + ML 分类器）| ≤ 10%（视觉 OCR + 表格结构识别）|
| **`financial_reports` 行数** | ≥ 128 | ≥ 4800（100 标的 × 8 年 × 6 类）| ≥ 200000（5000 标的 × 10 年 × 4 类）|
| **`announcements` 行数** | ≥ 800 | ≥ 30000 | ≥ 1500000 |
| **`related_party_raw` 行数** | ≥ 5000 | ≥ 100000 | ≥ 2000000 |
| **`pricing_method` 有效行覆盖率** | 100%（启动期兜底）| ≥ 80%（regex 升级，去掉兜底）| ≥ 95%（LLM 提取 + 同行价校准）|
| **Teacher 蒸馏 case 数（→ step_03）**| 100~500 | 3500（基线）| 10000+（覆盖罕见信号）|
| **LoRA 引擎精度（→ step_04~06）**| P=0.6 baseline | P=0.85 | P=0.9 + R=0.85 |
| **数据更新频率** | 一次性全量（手动）| 月度 + 公告增量 | T+1 实时（CDC + Kafka）|
| **存储后端** | SQLite 单文件 | PostgreSQL + Redis 缓存 | ClickHouse + Elasticsearch + Object Storage |
| **数据版本控制** | DVC + 本地 remote | DVC + MinIO/S3 remote | LakeFS + 完整 lineage |
| **数据治理责任** | 架构师 + 1 个低中模型 | 架构师 + DataOps Pipeline | 架构师 + 自动 SLI 监控 + 数据合约平台 |

### §6.5.2 跨阶段升级时**禁止跳级**的硬约束

| 升级路径 | 前置硬条件（不达则不许开工 stage_n+1）| 验证方式 |
|---|---|---|
| stage_1 → stage_2 | ①金标准 §3 全部 ✅；②§3.5 矩阵 21 项 0 ❌；③Teacher 蒸馏 100 条 Verified；④LoRA P=0.6 | 跑 [`金标准_8只持仓股数据验收清单.md`](../../../../../04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/金标准_8只持仓股数据验收清单.md) §3 全部 SQL + L4 实践记录证据 |
| stage_2 → stage_3 | ①扩展期 100 标的金标准全 ✅；②OCR 噪音率 ≤ 30%；③LoRA P=0.85；④Teacher 3500 case 已完成；⑤数据更新频率达到月度增量 | 见 stage_2 step_01 §准出 |

### §6.5.3 数据质量提升的核心方法论（三档共用）

| 方法 | 启动期 | 扩展期 | 完善期 |
|---|---|---|---|
| **OCR 引擎** | pdfplumber 文本（首选）+ PaddleOCR 回退 | + 表格结构识别（PP-Structure）+ 版面分析 | + 多模态 LLM（Claude Opus / GPT-4V）解析图片型扫描件 |
| **字段抽取** | regex 关键词 + 简单分类 | + 小模型分类器（LoRA 微调）+ 规则集 | + LLM 复杂语义抽取 + 知识图谱推理 |
| **去噪策略** | 关键词 + 长度阈值（`clean_related_party_noise.py`）| + ML 二分类（噪音/有效）+ 行级置信度评分 | + 主动学习（人工标 100 例 / 自动 propagate） + 与公告 / 公告穿透交叉验证 |
| **质量监控** | 一次性 `validate_quality_matrix.py` | + CI 每日跑 + 阈值告警 | + 实时 SLI / SLO + 自动回滚 + 数据治理仪表盘 |
| **数据增量** | 手动重跑全量 | 增量调度（按 ann_date / report_date 增量） | CDC + Kafka 实时流式入库 |
| **数据回测** | Holdout 50 案例守门 | + 影子模式新模型 vs 旧模型对比 | + 多基线对比 + Champion-Challenger A/B |

### §6.5.4 对低/中模型在 stage_2/stage_3 执行时的约束

**禁止动作**（违反视为不达金标准 · 见金标准文档 §6）：
1. **禁止跳级**：未达 §6.5.2 前置条件不得开工下一阶段；
2. **禁止伪造数据**：扩量到 100 只 / 5000 只时，仍须真实采集，禁止任何 mock；
3. **禁止降低门槛**：本表 §6.5.1 的数字是基线门槛，**只能加不能减**；
4. **禁止跨阶段并行**：stage_1 未达 ✅ 不得偷跑 stage_2；
5. **禁止"假装质量"**：N1 噪音率、`pricing_method` 覆盖率必须按 `validate_quality_matrix.py` 的实际输出，**禁止**估算或抽样代替全量。

**必做动作**：
1. 每个 stage 完成时**必须**重跑对应 stage 的金标准验收清单（启动期已有，扩展期 / 完善期由 stage_2/3 step 文档配套）；
2. 每次扩量（替换 / 新增标的）**必须**同会话跑 §6.5.2 第一行验证；
3. 每次升级数据源 / 抽取方法**必须**同会话跑 N1 + R3 验证，确认无回归；
4. 修改本表门槛**必须**先提 L3 修订并按 `00_系统规则` §4.5 同步 14 节奏表与 .cursorrules。

## §7 实施规划（L3 设计 · 给后续执行模型的工作指引）

> **L3 定位**：本节是**设计规划 + 实现要点 + 验证标准**——靠谱地描述"做什么 / 如何执行"，但**不嵌入完整 Makefile / 脚本代码**。具体命令、调试日志、参数填值由 L4 实践记录 / 后续执行模型按本节规划自行落地。

### §7.1 实现要点（按交付物拆分 · L4 / 后续模型按此逐项落地）

| 实现要点 | 涉及代码位置 | 关键设计决策 | 验证标准 |
|---|---|---|---|
| **A 持仓 SoT 驱动** | `data/config/my_holdings.yaml`（example 已就绪）+ `apps/common/holdings_sot.py`（已就绪） | 唯一真相源；增减标的 / `active=true/false` / 调年份 / 调报告类型均改本文件 | `from apps.common.holdings_sot import active_symbols; active_symbols()` 列出预期代码 |
| **B ORM 扩展（一次性 migration）** | `apps/cryo_guard/db/models.py` | ① `FinancialReport` 加 `industry: str` 列；② 新建 `RelatedPartyGraph` 简表（`symbol / party_name / parent_party / controller / source_pdf_page`，后两个 nullable）；③ alembic autogenerate 一次 | alembic upgrade 后 `.tables` 含 `related_party_graph`；`.schema financial_reports` 含 `industry` |
| **C 公告类别扩 7 类** | `training/data/scripts/crawl_announcements.py` | `ANN_TYPES` 在原 5 类基础上加「人事变动」「监管问询」（关键词清单作为常量维护，便于后续扩展） | 7 类各有日志记录；启动期允许某类"已尝试 + 返回 0" |
| **D 财报 4 类报告齐采** | `training/data/scripts/crawl_financial_reports.py` 默认行为 | 默认 `CRYO_REPORT_TYPES=annual,semi,q1,q3`；优先从 SoT `defaults.crawl_report_types` 读取 | `report_type` 4 类均 ≥ `active 标的数 × 年数` |
| **E 行业归类采集** | 新建 `training/data/scripts/crawl_industry_category.py` | 调 `ak.stock_industry_category_cninfo`，按 symbol 反查并更新 `financial_reports.industry`；调用频次有限，无需 throttle | active 标的全部非 null |
| **F 定价方法抽取** | `training/data/scripts/ocr_financial_notes.py` 内新增 `_detect_pricing_method` | 识别 "市场价格 / 协议价格 / 成本加成 / 参考公允价值 / 双方协商" 等关键词；多个匹配时返回最高优先级 | `related_party_raw.pricing_method` 非 null 率 ≥ 50% |
| **G 关联方网络图骨架** | 同上文件新增 `_extract_graph` | **启动期只抽直接关联方**（不穿透多层）；优先从年报「关联方关系图」页面（含表格或缩进列表）提取；`parent_party / controller` 抽不到则留 null | `related_party_graph` ≥ `active 标的数 × 2` |
| **H F4 研发资本化口径校验** | 新建 `training/scripts/audit_rd_capitalization.py` | 对 active 标的输出 `rd_expense / rd_capitalized` 归一化结果 vs 年报原文披露的「研发支出资本化金额」对比；不一致则修正 `_build_record` 的字段映射（中英文键混淆问题） | 对比表无错位，或错位修正后重跑 D 通过 |
| **I §3.5 质量矩阵复核脚本** | 新建 `training/scripts/validate_quality_matrix.py` | 自动按 §3.5.1~§3.5.4 的 18 项的「必产字段」查 DB 覆盖率，输出 ✅/⚠️ + 非 null 率 + SQL 证据；任一项不达预期则退出码非 0 | 退出码 0；18 行全 ✅ 或 ⚠️ |
| **J 50 案例 Holdout 锁库** | `training/data/holdout/`（骨架已就绪）+ `build_holdout_manifest.py` + `holdout_guard.py` | 一次性锁库 + `chmod -w`；二次执行 idempotent（manifest 已存在则跳过重写） | `H001~H050.json` 共 50 个；守门器退出码 0 |
| **K DVC 锁定 + 单测** | DVC 三个数据集（DB / PDF / Holdout）+ `tests/cryo_guard/test_data_pipeline.py` | 单测最少覆盖：7 类公告分类、4 类报告归一化、关联方图骨架抽取、`_detect_pricing_method` 关键词匹配、Holdout 守门器 | `dvc status` 干净；`pytest -q` ≥ 8 passed |

### §7.2 Makefile 一键复现合约（L3 约定 · L4 / `diting-src/Makefile` 实现）

**设计目的**：架构师**只改 `data/config/my_holdings.yaml`** 一个文件（增减 active 标的 / 调 `crawl_years` / 调 `crawl_report_types`），跑**一条命令**完成端到端"采集 → 质量检测 → Holdout → DVC → 单测"全套。**禁止**在 Makefile 或脚本中 hardcode 标的代码、年份、报告类型。

**target 合约表**（L3 此处只定义合约 · 实现交 L4 / `diting-src/Makefile`）：

| target | 用途（一句话） | 入参（环境变量 · 均有默认） | 验证标准 |
|---|---|---|---|
| `make cryo-step02-prep` | alembic upgrade + SoT 自检 | `MY_HOLDINGS_YAML` | active symbols 非空，退出码 0 |
| `make cryo-step02-collect` | **一键采集**（财报 + 行业 + 公告 + OCR） | `MY_HOLDINGS_YAML / CRYO_YEARS / CRYO_REPORT_TYPES / CRYO_THROTTLE_SEC` | 4 张业务表全部增量更新 |
| `make cryo-step02-quality-check` | F4 抽样 + §3.5 矩阵复核 | — | 18 行 ✅/⚠️；退出码 0 |
| `make cryo-step02-holdout` | Holdout 锁库 + 守门 | — | manifest 50 行；权限位无 `w`；守门器退出码 0 |
| `make cryo-step02-dvc` | DVC 锁定 | — | `dvc status` 干净 |
| `make cryo-step02-test` | 单测 | — | `pytest -q` ≥ 8 passed |
| `make cryo-step02-all` | **端到端一键**（含上述 6 步顺序串联） | 同上合并 | 全部退出码 0；4 标的端到端 ≤ 30 min |
| `make cryo-step02-status` | 数据量进度快照（**只读**） | — | 打印 4 张表 COUNT + §3.5 覆盖率 |
| `make cryo-step02-clean` | 清产出（**保留 Holdout**） | — | `cryo_guard.db` / `data/raw/financial_notes` 已删除；Holdout 不动 |

**合约要求**（L4 实现时必须遵守）：
1. **入参全部环境变量化**：默认值见 §5.2；命令行 / `.env` / Makefile 顶部三层叠加优先级；
2. **target 是薄包装**：核心动作在 Python 脚本里，Makefile 只串环境变量与调用顺序，**不**写业务逻辑；
3. **可重入幂等**：重跑 `cryo-step02-all` 不破坏已有数据（采集脚本须按 `symbol+year+report_type` upsert 而非 insert）；
4. **配置驱动**：增减标的 / 改年份 / 改报告类型仅改 yaml，**禁止**改 Makefile 或脚本内 hardcode；
5. **失败可观察**：每个 target 输出"做了什么 / 期望什么 / 实际什么"3 行摘要（中文优先，见 `00_系统规则` §7.2 第 14 条）。

### §7.3 给后续执行模型的指引（步骤与边界）

L4 / 执行模型在本步落地时**按以下顺序**，**不偏离 §7.1 实现要点 + §7.2 合约**：

1. **核对 SoT**：`my_holdings.yaml` 已就绪 + §3 表与代码一致 → 否则不开工；
2. **逐项落地 A~K**：每项产出独立可跑（不耦合下一项），落地后跑对应「验证标准」；
3. **集成 Makefile**：按 §7.2 合约表实现 9 个 target，过 `make cryo-step02-all` 端到端验证；
4. **§9 准出清单逐项打勾** + 同会话给证据（命令输出 / SQL 结果摘要）；
5. **回写 L4 实践记录**：每个 ⚠️ 项的实际状况、§3.5 矩阵填表、commit hash、耗时；
6. **遇问题**：按 `00_系统规则` §7.2 第 6 条（Verify First）先验证再改；同问题修复重试 ≥ 2 次仍失败再回收（§8.4f）。

> **L3 责任边界**：本节给规划 + 实现要点 + 验证标准；**不**给完整 Makefile / 脚本代码、不写每个命令。具体落地由 L4 实践记录 / 后续执行模型按本节规划自行完成。
> **§7 禁止 Mock**：所有实现要点与 target 均不允许 `CRYO_MOCK=1` / `--use-mock` / `mock_*.json`；上游 SoT 未提供前**等待**。
> **§7 数据质量优于数据量**：A~K 的目的不仅是"凑够行数"，而是按 §3.5 矩阵为下游引擎备齐分析维度；任一项非 null 率不达预期 → 回 §3.5 对应行检查抽取代码（如 `_detect_pricing_method` 关键词需扩展）。

## §8 部署节奏（本步在哪里跑）

| 阶段 | 形态 | 是否本步必须 | 说明 |
|---|---|---|---|
| **本机开发** | `python -m apps.cryo_guard.main` + `pytest` + 上述采集脚本 | **必须** | 本步全部产出（4 张表 + Holdout + DVC + 单测）在本机完成 |
| **本机 docker-compose** | — | 否 | 本步不需要中间件 |
| **Dev K3s** | — | 否 | 本步不上集群 |
| **ACR + 生产 K3s** | — | 否 | 本步**不**产出镜像；当 step_07 vLLM 部署时再上 |

**本步默认运行形态**：仅本机。`data/cryo_guard.db`（SQLite）作为单文件存储，后续 step_03~06 训练同一台机器读它即可。

## §9 准出标准（同会话可执行清单 · 质量优于数量）

> **门槛口径**：以下分四档：① 数据量门槛（§5.3 行数）；② **数据质量门槛（§3.5 矩阵）**；③ 锁库与守门；④ 工程交付。**第 ② 档不绿则视为本步未准出**——即使行数已达 §5.3 也不放行。

### §9.1 数据量门槛（§5.3）
- [ ] `SELECT COUNT(*) FROM financial_reports;` ≥ 64 且 `report_type` 4 类均 ≥ 16
- [ ] `SELECT COUNT(*) FROM financial_reports WHERE industry IS NOT NULL;` ≥ 4
- [ ] `SELECT COUNT(*) FROM announcements;` ≥ 30 且 `content` 非空率 ≥ 90%；7 类 `ann_type` 各有日志记录（人事变动 / 监管问询可为 0 但须日志说明）
- [ ] `SELECT COUNT(*) FROM related_party_raw;` ≥ 50 且 `pricing_method` 非 null 率 ≥ 50%
- [ ] `SELECT COUNT(*) FROM related_party_graph;` ≥ 8

### §9.2 数据质量门槛（§3.5 矩阵 · 启动期 18 项）
- [ ] **财务测谎维度 6 项**：F1/F2/F3/F9/F10 = ✅；F4 = ⚠️（§7.8 抽样校验已执行且结果一致 / 不一致已修正）
- [ ] **大股东诚信维度 6 项**：S2 = ✅；S1/S3/S4/S5/S6 = ⚠️（公告 7 类全部已尝试采集，`content` 非空率 ≥ 90%）
- [ ] **关联交易维度 4 项**：R2 = ✅；R1/R3/R4 = ⚠️（`related_party_graph` ≥ 8 行、`pricing_method` 非 null 率 ≥ 50%）
- [ ] **共用维度 2 项**：C1 = ✅；C2 = ⚠️（`industry` 4 标的各 1 条非 null）
- [ ] **复核脚本**：`python training/scripts/validate_quality_matrix.py` 退出码 0，输出 18 行均为 ✅ 或 ⚠️

### §9.3 锁库与守门
- [ ] `ls training/data/holdout/H*.json | wc -l` = 50
- [ ] `python training/scripts/holdout_guard.py --verify` 退出码 0
- [ ] `ls -l training/data/holdout/H001.json` 权限位无 `w`

### §9.4 工程交付 + 一键复现
- [ ] **Makefile 合约落地**（§7.2）：`cryo-step02-prep / collect / quality-check / holdout / dvc / test / all / status / clean` 9 个 target 已实现，且全部通过；`make cryo-step02-all` 4 标的端到端 ≤ 30 min
- [ ] **配置驱动验证**：`data/config/my_holdings.yaml` 中临时新增 1 个 `active=true` 标的，跑 `make cryo-step02-all` 端到端通过；移除该标的并跑 `make cryo-step02-status` 显示数据量回到预期（验证可重入幂等）
- [ ] `pytest tests/cryo_guard/test_data_pipeline.py -q` ≥ 8 passed
- [ ] `dvc status` 输出 `Pipelines are up to date` 或空
- [ ] L4 实践记录 `04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_02_数据采集与50案例Holdout.md` 已按 §8.4g 更新"二、实际进展"为已核验准出，且**含 §3.5 矩阵填表**（18 行实际 ✅/⚠️ 状态与 SQL 证据）
- [ ] commit：`feat(cryo-guard): step_02 真实采集 + 质量矩阵 + Makefile 一键复现 + 50 案例 Holdout 锁库 [Ref: 03_/01_维度一/stages/stage_1_启动期/steps/step_02]`
- [ ] **同会话验证**：上述命令在当次会话执行并输出摘要（按 `00_系统规则` §7.2 第 10/11 条）

## §10 [Deploy] 段

本步**不**涉及上架（无镜像 / 无 Chart / 无 K8s workload）；运行形态详见 §8。

> 当 D1 step_07（三引擎服务部署）启动时，本步采集到的 SQLite DB / 附注 PDF / Holdout 文件将作为运行时数据卷或只读 ConfigMap 挂载——相关 Chart 与 values 在 step_07 写明，本步无需处理。

## §11 依赖与被依赖

**上游**（必须先完成）：
- `step_01_环境与基础设施`：SQLite 文件 / 4 张表 ORM / alembic 上行已就绪
- 用户提供：`MY_HOLDINGS_YAML` + 真实 `my_holdings.yaml`（§4.2）

**下游**（本步产出被消费）：
- `step_03_Teacher蒸馏`：从 `financial_reports` / `announcements` / `related_party_raw` 抽取证据 → 喂 D5 Teacher → 输出 3500 条 Verified（启动期可先 100 条试跑）
- `step_04~06`（三引擎 LoRA 训练）：每次训练前**必须**先跑 `holdout_guard.py --check-training-data <jsonl>` 排除 Holdout symbol
- `D2 step_02`（deep_strike 数据采集）：复用同一份 `financial_reports` / `announcements`（共表）
- `D3 step_02`（holding_watch 财务探针）：读 `financial_reports` 做健康度计算

**严禁伪造**（no-mock-policy）：上游 SoT 未提供前**等待**；不得在本步用任何 mock JSON 跑通后续表数据。

## §12 风险与回退

| 触发条件 | 动作 |
|---|---|
| akshare 限流（HTTP 429） | 增大 `CRYO_THROTTLE_SEC=1.0`；同一原因 ≥ 2 次仍失败 → 切换备源 efinance / Tushare |
| 巨潮 cninfo PDF 部分老公告下载失败 | `content` 留 null；在 L4 实践记录写明哪几条 + 原因；**禁止**填假文本 |
| `pdfplumber` 抽不到文字（图像型 PDF） | 启用 `paddleocr` 回退（若未装 → `pip install paddleocr` 后重跑） |
| OCR 失败页 > 5% | 升级 paddle 模型 / 调高 `dpi=300`；仍失败 → 记入 `failed_ocr_pages`，不阻塞 Holdout |
| 持仓 SoT 标的极少（< 1 只）→ 数据量门槛达不到 | 由用户在 SoT 中追加 1～3 只候选股；**禁止**用 `crawl_symbols.example.txt` 替代 |
| Holdout SHA256 不匹配 | 必有人为篡改；立即 `git revert` 并通知架构师；**不可**强行覆盖 manifest |
| DVC remote 暂未配置 | 启动期允许仅本地 add；扩展期切 S3/MinIO 时回头改 `dvc remote add -d storage <url>` |
| 同一问题修复重试 ≥ 2 次仍失败 | 停止 + L4 实践记录"问题与风险"中说明 + 按 `00_系统规则` §8.4f 回收 |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-23 | **v2.4 短期金标准 + 长期推演内嵌**（关键重构 · 与 `00_系统规则` §4.5 同步）：用户两条核心反馈：①「8 只持仓**先做成黄金标版**，让低中模型有标准答案」；②「**长期推演**写进步骤，让以后扩量时不跑题不偏离」。变更：①§3.5 矩阵从 18 项 → **21 项**：新增 S7（关联交易公告交叉验证）、N1（OCR 噪音率 ≤ 55%）、§3.5.5 数据卫生小节；S3/S6 从 ⚠️ 升为 ✅（已扩 8 类公告分类）、C2 从 ⚠️ 升为 ✅（akshare + segment 兜底）；②§5.3 表新增 N1 噪音率 / `roe` / **有效交易行**（去噪后口径）行，启动期门槛与金标准（8 标的）并列；③**新增 §6.5 长期推演**（启动期 → 扩展期 → 完善期 三档质量门槛总表 17 行 + 跨阶段升级硬约束 + 数据质量提升方法论 + 对低/中模型的执行约束）；④L4 配套金标准文档 [`金标准_8只持仓股数据验收清单.md`](../../../../../04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/金标准_8只持仓股数据验收清单.md) 已建；⑤8 类公告分类（`crawl_announcements.py::ANN_TYPES` + `_classify_ann_type` 已扩）；⑥配套脚本：`clean_related_party_noise.py`（去噪标注）+ `backfill_pricing_method.py`（R3 有效行兜底）+ `validate_quality_matrix.py`（21 项矩阵）+ `crawl_industry_category.py`（含 segment 兜底）+ `build_related_party_graph.py`。**8 只持仓 W1 实测**：21/21 ✅、N1=47.9%、R3@valid=100%、industry=8/8、关联方图=340 节点 |
| 2026-05-20 | **v2.3 L3 定位修正 + Makefile 一键复现 + §3.5 仅启动期**（关键重构，与 `00_系统规则` §4.5 同步）：用户两条反馈：①「**L3 以设计规划推演为主**，描述好如何执行 / 测试 / 验证标准，**不嵌入完整代码**，具体落地交后续模型」；②「本步**只负责启动期**的数据类型与质量检测，不写扩展期；要**Makefile 一键启动**——改 yaml 即可扩标的，无需改其他文件」。变更：①§7 **完整重写**：原"7.1~7.13 命令清单表"改为「§7.1 实现要点（A~K 11 项 · 4 列）+ §7.2 Makefile 合约表（9 个 target）+ §7.3 给后续执行模型的指引」三段式；删除嵌入命令、删除完整代码、改为"设计规划 + 实现要点 + 验证标准"；②§3.5 质量矩阵剔除所有 ❌（扩展期）行，仅保留启动期负责的 18 项（F1/F2/F3/F4/F9/F10 + S1~S6 + R1~R4 + C1/C2），每行 ✅ 或 ⚠️ 启动期降级；③§6 收敛为一行触发条件（不展开扩展期细节，扩展期清单在 stage_2 文档独立维护）；④§9.4 准出加「Makefile 9 个 target 落地 + 配置驱动可重入幂等验证」；⑤§1 交付物表更新引用 |
| 2026-05-20 | **v2.1 数据质量优于数据量**（关键重构）：用户指出 v2 仅设"行数门槛"过于表面，**采集是为给模型引擎分析，质量须按引擎分析需求反推**（"巴菲特原则：不接受看了三表就算看了财报"）。变更：①新增 **§3.5 数据质量验收矩阵**；②启动期默认报告类型扩到**全 4 类**；③公告类别从 5 类扩到 **7 类**；④新建 `related_party_graph` 表；⑤`financial_reports` 加 `industry` 列；⑥§9 准出标准重构为四档 |
| 2026-05-20 | **v2 按新模板 13 小节重写**（关键重构，与 `00_系统规则` §4.5 + [`_共享规约/L3_启动期step_重构模板`](../../../../_共享规约/L3_启动期step_重构模板.md) 同步）：①删除全部 Mock 相关；②启动期目标改为「持仓 SoT 标的 + 4 张表小行数门槛」，**全 A 22500 行下沉到扩展期**；③新增 §4.2 凭证清单（用户先填 `MY_HOLDINGS_YAML`，本步不需 LLM key）；④新增 §6 扩展期一行；⑤新增 §8 部署节奏（本步仅本机）；⑥精简 §7 实施步骤为表格化动作单（代码以"现行实现位置"指引，不再嵌入大段代码块）；⑦同步 [14_六维度启动期统一节奏表 §3.2](../../../../_共享规约/14_六维度启动期统一节奏表.md) 关键产出列。从 1207 行 → ~290 行 |
| 2026-05-18 | 补充 §1.5：数据类、数据源、脚本与 `CRYO_*` 对齐；区分「代码落地」与「准出全量长跑」 |
| 2026-05-16 | 初版：财报 + 附注 OCR + 公告 + 50 案例 Holdout 锁库 + DVC + 守门器 |
