# Step 05 · 大股东诚信引擎 LoRA v1 训练 + RAG 承诺提取

## §1 一句话定位与本步交付物

**一句话**：用 step_03 的 shareholder_integrity Verified 数据集训练 Qwen2.5-7B-Instruct + LoRA（rank=16），并实现 4 节点 LangGraph 引擎（RAG 召回 + NLI 比对），在 10 案例 Holdout 上达到 **Recall ≥ 0.90 / Precision ≥ 0.70 / F1 ≥ 0.78**。

**交付物**（勾选 = 完成）：
- [ ] **A**（LoRA 训练完成）：`output/shareholder_lora_v1/adapter_model.safetensors` 存在且 size > 60MB
- [ ] **B**（WandB 训练曲线）：`train/loss` 收敛 + `eval/loss` 不发散（末 epoch ≤ 中间最低 ×1.1）
- [ ] **C**（Milvus + BM25 双索引）：collection `shareholder_announcements` 存在（HNSW dim=1024，行数 ≥ `announcements` 表全量）+ `apps/cryo_guard/rag/bm25_index.pkl` 已生成
- [ ] **D**（4 节点 Agent）：`apps/cryo_guard/engines/shareholder_integrity/{commitment_extractor, behavior_extractor, nli_comparator, llm_scorer, engine, schemas}.py` + LangGraph workflow 注册
- [ ] **E**（10 案例 Holdout 评测）：`output/eval_reports/shareholder_holdout_v1.json` 含 `recall ≥ 0.90 / precision ≥ 0.70 / f1 ≥ 0.78 / num_cases = 10 / passed = true`
- [ ] **F**（5 类言行不一覆盖）：增持失信 / 减持违规 / 业绩对赌失败 / 质押隐瞒 / 战略落空 各 ≥ 1 次触发；10 案例分布建议 5 增持 + 3 业绩 + 2 战略 → 实际覆盖 ≥ 4 类
- [ ] **G**（RAG 可溯源）：每个预测 `evidence[].source_url`（巨潮 cninfo 链接）+ `source_announcement_id` 可在 SQLite 反查
- [ ] **H**（单测）：`pytest tests/cryo_guard/test_shareholder_engine.py -v` ≥ 7 passed
- [ ] **I**（Makefile 一键复现）：`make cryo-step05-all` 端到端通过

> **本步是 step_07/09 的硬阻塞**：LoRA 与 RAG 索引双双就绪后才能开 vLLM 多 LoRA 热加载 + 综合 Holdout 评测。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2 哲学**：[01_维度一_极寒防御 · 04_防御实践策略规划](../../../../../02_战略维度/01_维度一_极寒防御/04_防御实践策略规划.md)
> - **本阶段总览**：[stage_1_启动期/README](../README.md)
> - **L3 模型训练**：[../04_模型训练与部署.md](../04_模型训练与部署.md) §一 训练目标（shareholder Recall ≥ 0.90）、§四 LoRA、§五 Holdout
> - **L3 技术架构**：[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §二 代码结构（shareholder_integrity 4 节点 Agent）、§3.2 引擎基类
> - **L3 数据规约**：[../03_数据采集与预处理.md](../03_数据采集与预处理.md) §三 大股东数据（5 类公告）、§6.2 蒸馏 Prompt 模板
> - **L3 验收**：[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md) §二 模型验收（shareholder Recall ≥ 0.90）
> - **DNA 键**：`_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml` → `deliverables.engines[1]` E2·shareholder：`lora_name=shareholder_lora_v1`、`rank=16`、`detection_categories=5`、`agents=4`
> - **L4 实践记录**：[实践记录_step_05_大股东诚信引擎LoRA.md](../../../../../04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_05_大股东诚信引擎LoRA.md)
> - **上游 step**：← step_01（GPU + Milvus）、step_02（公告数据 + H031~H040 Holdout）、step_03（shareholder_integrity_{train,val,test}.json）
> - **下游 step**：→ step_07（vLLM 多 LoRA 热加载）、step_09（综合 Holdout 评测）

## §3 数据采集对象 / 落库映射

**本步不采集数据**——消费 step_02 的公告 + step_03 的 jsonl，并**新建** Milvus 向量索引 + BM25 备份索引。

| 数据流向 | 来源 / 落库 | 用途 |
|---|---|---|
| `shareholder_integrity_{train,val,test}.json` | step_03 `training/data/llama_factory/` | LoRA 训练输入 |
| `announcements`（7 类公告 + content 全文） | step_02 SQLite | 索引源（bge-m3 嵌入 → Milvus）+ 实时检索 |
| `shareholder_announcements` Milvus collection | 本步**新建**（dim=1024 HNSW，启动期标的全部入库） | `commitment_extractor` 检索 |
| `apps/cryo_guard/rag/bm25_index.pkl` | 本步**新建**（jieba 分词 + rank_bm25） | Milvus 不可用时降级 |
| `financial_reports`（含历史业绩） | step_02 SQLite | `behavior_extractor` 抽实际业绩 |
| `H031~H040.json`（10 大股东诚信案例） | step_02 锁库 | Holdout 评测金标 |
| LoRA 产物 | `output/shareholder_lora_v1/` | adapter + 训练日志 |
| 评测产物 | `output/eval_reports/shareholder_holdout_v1.json` | 指标 JSON + 5 类触发统计 |

## §3.5 数据质量验收矩阵（按 Holdout 评测需求反推 · 仅启动期负责）

> **本步范围**：训练数据 + RAG 索引 + 4 节点引擎 + Holdout 评测四个环节的质量要求。每行 ✅ 已达成 或 ⚠️ 启动期内有降级路径。**不**列扩展期内容。

### §3.5.1 训练数据质量（消费 step_03 产出）

| # | 分析维度 | 必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| Q1 | **5 类言行不一各类样本充足** | step_03 `teacher_distill` 中 `category ∈ {增持失信, 减持违规, 业绩对赌失败, 质押隐瞒, 战略落空}` 各 ≥ 100 条 | ⚠️ 依赖 step_03 §3.5.2·T5 | §7.1·B 训练前 precheck；缺类回 step_03 |
| Q2 | **承诺 / 实际双段对比完整率** | 样本 `evidence.{promise,actual}` 双对象都非空 ≥ 80% | ⚠️ 依赖 step_03 §3.5.2·T6（启动期目标 80%）| precheck 不达标暂停训练 |
| Q3 | **公告 URL 锚定** | 样本 `evidence.source_url` 非空率 100% | ✅ step_03 §3.5.2·T7 强制 | precheck 全过 |

### §3.5.2 RAG 索引质量（Milvus + BM25）

| # | 分析维度 | 必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| R1 | **Milvus 向量索引覆盖率** | `shareholder_announcements` 行数 = `announcements` 表全量（启动期 ≥ 30 条）| ⚠️ 启动期建仓时全量嵌入 | 嵌入失败行入 `failed_embed.log`；失败率 > 5% 暂停 |
| R2 | **bge-m3 嵌入维度 + HNSW** | `dim=1024`，`index_type=HNSW`，`metric=IP`（内积） | ✅ Milvus 建表强制 schema | 建表失败 → 切 IVF_FLAT 备用 |
| R3 | **BM25 备份索引** | `bm25_index.pkl` 含 (ids, symbols, ann_types, ann_dates, titles, urls, bm25_obj)；jieba 分词 | ⚠️ 启动期必建 | Milvus 不可用时自动回退；失败率监控 |
| R4 | **召回质量** | 用 5 类典型 query 对 active 标的检索，top-12 中至少 1 条相关 | ⚠️ 启动期抽样 4 标的 × 5 query 验证 | 召回率 < 80% → 加 query 多样性（5 类各扩到 3 query）|

### §3.5.3 4 节点 Agent 输出质量

| # | 节点 | 设计目标 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| N1 | **commitment_extractor** | RAG（Milvus top-12 / BM25 fallback）召回承诺类公告 → LLM 抽出 `commitments[]`（每个含 `date / type / amount / text / source_url`）| ⚠️ Milvus 优先；不可用切 BM25 | 双索引都不可用时抛异常（不允许 mock） |
| N2 | **behavior_extractor** | 从 SQLite `announcements`（增减持公告）+ `financial_reports`（业绩）抽实际行为，`actual_behaviors[]` 含 `date / type / amount` | ✅ ORM 查询直接拿 | 缺数据返回 `behaviors=[]` + 标 `data_insufficient=True` |
| N3 | **nli_comparator** | 把 commitments 与 actual_behaviors 按 5 类规则比对（NLI + 数值偏差 + 时间窗口）；输出每类 `triggered: bool` + `deviation_pct` | ⚠️ 启动期规则化为主（NLI 模型可选） | 规则不全时返回 `comparison_uncertain=True` 交 N4 兜底 |
| N4 | **llm_scorer** | 调 vLLM `/v1/chat/completions` w/ `lora_name=shareholder_lora_v1`；prompt = 公司基础 + commitments + actual_behaviors + nli_comparison → JSON 输出 `{label, confidence, risk_level, category, evidence[], reason_zh}` | ✅ vLLM HTTP 直连 | LoRA 未加载时降级 base model + 标 `lora_loaded=False` |

### §3.5.4 Holdout 评测质量（10 案例）

| # | 评测维度 | 准出门槛 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| H1 | **10 案例全跑** | num_cases = 10，不允许 skip | ✅ Holdout 锁库（H031~H040）保证 | 异常案例标预测 fail，不算 skip |
| H2 | **Recall ≥ 0.90** | 真为 integrity_failure 至少 90% 被预测出 | ⚠️ 实测；不达进调参循环 | §12 ADR + 启动期降级 Recall ≥ 0.80 |
| H3 | **Precision ≥ 0.70** | 预测正样本至少 70% 真为正 | ⚠️ 实测 | 同 H2 |
| H4 | **F1 ≥ 0.78** | 调和均值 | ⚠️ 实测 | 同 H2 |
| H5 | **5 类覆盖** | 10 案例至少触发 5 类中 4 类（H031~H040 本身仅含 3 类，最多覆盖 3，故启动期门槛降为 ≥ 3 类）| ⚠️ Holdout 本身分布限制 | 类型不足由 step_09 综合评测在更大池子补 |
| H6 | **RAG 可溯源** | 每个预测 `evidence[].source_url` 可访问到原始公告（巨潮 PDF） | ⚠️ 抽样 5 条手工核对 | 失效链接（公告下架）允许，但需在 evidence 中标 `url_status=expired` |

> 共 **14 项启动期质量要求**（Q1~Q3 训练 + R1~R4 索引 + N1~N4 节点 + H1~H6 评测，去重后 17 - 3 重叠 = 14）。矩阵中**无 ❌**。

### §3.5.5 质量门槛（合并到 §9.2）

矩阵每行须满足之一：
- **✅ 覆盖**：本步已实现且抽样验证通过；
- **⚠️ 启动期降级**：本步给出明确降级路径 + 在该降级下仍能满足 step_08 decision_gate baseline。

**禁止**：①RAG 索引数 < 全量 announcements 仍声称构建完成；②指标不达标人工改 eval JSON；③用 step_03 训练样本的 source_url 反向作弊。

## §4 真实数据源与凭证清单

### §4.1 训练 + 索引资源

| 资源 | 来源 | 备注 |
|---|---|---|
| 基模 Qwen2.5-7B-Instruct | step_01 已下载 | 与 step_04 共用 |
| bge-m3 嵌入模型 | step_01 已下载（`models/bge-m3/`）| RAG 嵌入用 |
| Milvus Standalone | step_01 已起 | dim=1024 collection |
| LLaMA-Factory ≥ 0.8 | step_04 已装 | 复用 |
| 训练数据 | step_03 产出 jsonl | 3 份 |
| Holdout 10 案例 | step_02 锁库 | H031~H040 |

### §4.2 用户须提供的凭证

| 凭证 | 用途 | 何时需要 | 写在哪里 |
|---|---|---|---|
| `WANDB_API_KEY` | 训练监控 | 训练前 | `diting-src/.env` |
| GPU 节点 | RTX 4090 24GB | 训练前 | step_01 已就绪 |
| `MILVUS_HOST / MILVUS_PORT` | Milvus 连接（默认 `milvus-svc.diting:19530`）| 索引构建前 | `.env` |

> **本步无新增凭证**（与 step_04 共用 GPU + WandB）。

## §5 启动期目标

### §5.1 训练超参 + RAG 设计

| 项 | 取值 | 理由 |
|---|---|---|
| 基模 / LoRA rank / alpha / dropout | Qwen2.5-7B-Instruct / 16 / 32 / 0.05 | 与 step_04 一致，便于 vLLM 多 LoRA 共用 |
| epochs / batch_size / grad_acc / cutoff | 3 / 2 / 8 / 4096 | 同 step_04 |
| lr / warmup_ratio | 5e-5 / 0.1 | 同 step_04 |
| 嵌入模型 | bge-m3 | 中文支持好；dim=1024 |
| Milvus 索引 | HNSW（M=16, ef_construction=200） | 平衡构建速度与召回 |
| BM25 分词 | jieba | 中文标准 |
| 检索 topk | 12 | 5 类 × 2~3 候选 |

### §5.2 评测目标

| 指标 | 启动期门槛 | 评测集 |
|---|---|---|
| Recall | ≥ 0.90 | H031~H040 10 案例 |
| Precision | ≥ 0.70 | 同 |
| F1 | ≥ 0.78 | 同 |
| 5 类触发覆盖 | ≥ 3 类（受 Holdout 案例分布限制）| 同 |
| 端到端单 case 延迟 | < 12 s（含 RAG）| 10 案例平均 |

### §5.3 可接受退化

- Milvus 不可用 → BM25 fallback + 标 `retrieval_mode=bm25`；
- 嵌入失败率 > 5% → 暂停索引构建 + 查日志（多半是 OOM）；
- LoRA 训练后指标不达 → 调参循环 ≤ 3 轮；
- 仍不达 → ADR 启动期降级到 Recall ≥ 0.80。

## §6 下一步（一行触发条件）

- **触发条件**：本步全部 ✅ + Holdout JSON `passed=true` → step_06（关联交易 LoRA）可并行；step_07/09 等三引擎都完成后开工。
- **下一阶段方向**：扩展期接入 NLI 专用模型（如 deberta-v3-large）+ Milvus 切 GPU 索引；详见 `stages/stage_2_扩展期/`。

## §7 实施规划（L3 设计 · 给后续执行模型的工作指引）

> **L3 定位**：本节是**设计规划 + 实现要点 + 验证标准**——**不嵌入完整 YAML / Python 类 / Prompt 代码**。具体落地由 L4 实践记录 / 后续执行模型按本节规划自行完成。

### §7.1 实现要点（按交付物拆分）

| 实现要点 | 涉及代码位置 | 关键设计决策 | 验证标准 |
|---|---|---|---|
| **A LLaMA-Factory 数据集注册** | `training/configs/dataset_info.json`（追加 3 份）| 与 step_04 共存；命名 `shareholder_integrity_train/val/test` | `llamafactory-cli` 加载不报错 |
| **B 训练 YAML + precheck** | `training/configs/shareholder_lora.yaml` + `training/scripts/precheck_shareholder.py` | yaml 超参同 §5.1；precheck 验 §3.5.1 Q1~Q3（5 类样本数、双段对比、URL 锚定） | yaml 可解析；precheck 退出码 0 |
| **C 训练脚本 + WandB** | 调 `llamafactory-cli train`；report_to=wandb | 与 step_04 共用流程，仅换 yaml | adapter 落 `output/shareholder_lora_v1/`，size > 60MB |
| **D bge-m3 嵌入封装** | `apps/cryo_guard/rag/embedder.py` | 加载 `models/bge-m3/`，提供 `embed(texts: list[str]) -> np.ndarray` + `embed_one(text) -> np.ndarray`；GPU 优先 CPU 备用 | 单测 5 条文本嵌出 (5, 1024) |
| **E Milvus 客户端** | `apps/cryo_guard/rag/milvus_store.py` | `init_collection(drop)` 建表（schema：id/symbol/ann_type/ann_date/title/content/url/embedding）；`search(col, qv, symbol, topk, ann_types)` 含 symbol 过滤 + ann_type 过滤；`upsert_batch(col, rows)` 批量入库 | 单测 mock Milvus 验 schema + search 调用 |
| **F 批量索引 + BM25** | `training/scripts/build_rag_index.py` | 从 `announcements` 全量读取 → bge-m3 嵌入 → Milvus upsert + jieba 分词 → rank_bm25 → pickle 落 `apps/cryo_guard/rag/bm25_index.pkl`；进度条 + 失败行落 `failed_embed.log` | 启动期 active 标的全量公告 ≥ 30 行入库；BM25 文件存在 |
| **G commitment_extractor 节点** | `apps/cryo_guard/engines/shareholder_integrity/commitment_extractor.py` | RAG 召回：先 Milvus（5 类典型 query 嵌入）→ 失败切 BM25；topk=12；按 ann_type ∈ 5 类过滤；输出 `retrieved_announcements + commitments_block`（格式化文本） | 单测 mock Milvus 返回 5 条 → 输出 commitments_block 含 5 行 |
| **H behavior_extractor 节点** | `behavior_extractor.py` | 从 `announcements`（增持 / 减持类）抽数量 / 时间；从 `financial_reports` 抽业绩；输出 `actual_behaviors[]` | 单测 4 标的 × 4 期数据抽出非空 |
| **I nli_comparator 节点 + 5 类规则** | `nli_comparator.py` + `configs/shareholder_rules.yaml` | 5 类规则化比对：增持失信（承诺金额 vs 实际 < 50%）、减持违规（窗口期内大宗减持）、业绩对赌（承诺业绩 vs 实际 < 80%）、质押隐瞒（质押公告 vs 大股东持股变化）、战略落空（战略目标 vs 实际营收增长）；阈值放 yaml | 单测 5 类各正负 1 案例 = 10 测试 |
| **J llm_scorer 节点** | `llm_scorer.py` + `prompts/shareholder.py` | 调 vLLM w/ `lora_name=shareholder_lora_v1`；prompt = 公司基础 + commitments + behaviors + nli_comparison → JSON；schema 校验失败 retry ≤ 2 次 | mock vLLM 响应通过 schema |
| **K engine + LangGraph** | `engine.py` + `schemas.py` | LangGraph: START → 并行(commitment_extractor, behavior_extractor) → nli_comparator → llm_scorer → END；State 含 `symbol / retrieved_announcements / commitments_block / actual_behaviors / nli_comparison / prediction`；`engine.run(symbol) -> Prediction` | e2e mock 跑 1 个 case |
| **L Holdout 评测脚本** | `training/scripts/eval_shareholder_holdout.py` | 读 H031~H040 → engine.run() → 算 Recall/Precision/F1 + 5 类触发统计 + RAG 召回率；输出 JSON `passed=true/false` | 10 案例全跑 + 指标达 §5.2 |
| **M 单测** | `tests/cryo_guard/test_shareholder_engine.py` | 4 节点单测 + 5 类规则 + e2e mock + Holdout fixture | `pytest -v` ≥ 7 passed |

### §7.2 Makefile 一键复现合约（L3 约定 · L4 实现）

**设计目的**：跑 `make cryo-step05-all` 完成"数据预检 → RAG 索引构建 → LoRA 训练 → smoke eval → engine 单测 → Holdout 评测"全套。

**target 合约表**：

| target | 用途 | 入参（环境变量 · 均有默认） | 验证标准 |
|---|---|---|---|
| `make cryo-step05-prep` | 数据集注册 + GPU/Milvus 自检 + WandB login | `WANDB_API_KEY / MILVUS_HOST` | `nvidia-smi / pymilvus.connect()` 都 OK |
| `make cryo-step05-precheck` | §7.1·B 训练前数据预检 | — | Q1~Q3 全过；退出码 0 |
| `make cryo-step05-build-rag` | bge-m3 嵌入全量公告 + Milvus upsert + BM25 落盘 | `MILVUS_HOST / EMBED_BATCH_SIZE` | Milvus 行数 = announcements 表全量；`bm25_index.pkl` 存在 |
| `make cryo-step05-train` | LoRA 训练 | `LORA_CONFIG=training/configs/shareholder_lora.yaml` | adapter > 60MB；WandB run 完成 |
| `make cryo-step05-smoke-eval` | val.json 抽 30 条快评 | — | F1 > 0.4（仅冒烟）|
| `make cryo-step05-engine-test` | 4 节点单测 + e2e mock | — | `pytest -v` ≥ 7 passed |
| `make cryo-step05-holdout-eval` | 10 案例 Holdout | `HOLDOUT_DIR` | F1 ≥ 0.78 + Recall ≥ 0.90 + Precision ≥ 0.70 + ≥ 3 类触发；`passed=true` |
| `make cryo-step05-all` | **端到端一键**（含上述 7 步） | 同上合并 | 全部退出码 0；4090 端到端 ≤ 4 hr（含 RAG 嵌入）|
| `make cryo-step05-retrain` | 调参循环：清旧 + 重训 + 重评 | 改 yaml 后跑 | 同 all 但跳过 prep/build-rag |
| `make cryo-step05-status` | 进度快照（只读） | — | 打印训练状态 + Milvus 行数 + 最近评测指标 |
| `make cryo-step05-clean` | 清 LoRA + Milvus collection + BM25（**不**清 bge-m3 模型） | — | 已删；基模 / 嵌入模型保留 |

**合约要求**：
1. **入参环境变量化**；
2. **target 是薄包装**：训练调 `llamafactory-cli`，索引调 `training/scripts/build_rag_index.py`，评测调 `training/scripts/eval_shareholder_holdout.py`；
3. **可重入幂等**：RAG 索引检查"行数 = announcements 表"则跳过；adapter 已存在 + JSON passed=true 则跳过训练直接验证；
4. **配置驱动**：增标的 → 改 `my_holdings.yaml` → 重跑 `build-rag` 仅嵌入新 symbol（增量）；
5. **失败可观察**：每个 target 中文 3 行摘要 + Milvus 行数 / BM25 大小 / WandB run url。

### §7.3 给后续执行模型的指引

L4 / 执行模型按以下顺序：

1. **核对前置**：step_01 GPU + Milvus Ready；step_02 H031~H040 锁库 ✅；step_03 jsonl 6 份 + Verified ≥ 800；bge-m3 模型已下载；
2. **逐项落地 A~M**：建议顺序 D→E→F→B→C→G→H→I→J→K→L→M（基础 RAG 先于业务节点）；
3. **集成 Makefile**：按 §7.2 实现 11 个 target；
4. **训练前必跑 precheck + RAG 索引**：缺索引则 commitment_extractor 必失败；
5. **训练后 Holdout 评测**：不达进**调参循环 ≤ 3 轮**（每轮 ADR）；3 轮仍不达 § 12 启动期降级；
6. **§9 准出 + L4 回写**：训练耗时、RAG 嵌入耗时、Milvus 行数、Recall/Precision/F1、5 类触发分布、调参轮数；
7. **遇问题**：Milvus 不可用 → 切 BM25（标 mode）；嵌入 OOM → 减 batch；调参 ≥ 2 次仍失败 § 8.4f 回收。

> **L3 责任边界**：本节给规划 + 实现要点 + 验证标准；**不**给完整 yaml / Python 类 / Prompt 字面量；具体落地交给 L4 实践记录 / 后续执行模型。

## §8 部署节奏（本步在哪里跑）

| 阶段 | 形态 | 是否本步必须 | 说明 |
|---|---|---|---|
| **本机开发** | `python -m apps.cryo_guard.engines.shareholder_integrity.engine` + `pytest` + `llamafactory-cli train` | **必须** | 4 节点代码 + 训练 + 评测 |
| **本机 docker-compose** | — | 否 | Milvus / vLLM 已在 step_01 Dev K3s 起 |
| **Dev K3s** | RAG 索引落 Milvus Pod；LoRA adapter 挂载 vllm Pod | **必须** | 推理评测依赖 |
| **ACR + 生产 K3s** | 扩展期镜像化 | 否 | 启动期 PVC 挂载即可 |

**本步默认运行形态**：本机训练 + Dev K3s 索引存储 + 推理。

## §9 准出标准（同会话可执行清单 · 质量优于数量）

### §9.1 训练与文件门槛
- [ ] `ls -lh output/shareholder_lora_v1/adapter_model.safetensors` size > 60MB
- [ ] WandB run 状态 `finished`；loss 曲线 OK（同 step_04）
- [ ] `output/eval_reports/shareholder_holdout_v1.json` 存在且 `passed=true`

### §9.2 数据质量门槛（§3.5 矩阵 14 项）
- [ ] **训练数据 3 项（Q1~Q3）**：precheck 全过
- [ ] **RAG 索引 4 项（R1~R4）**：Milvus 行数 = announcements 全量；BM25 文件存在；召回质量抽样 ≥ 80%
- [ ] **4 节点 4 项（N1~N4）**：单测全过 + 抽样推理无 schema 错
- [ ] **Holdout 评测 6 项（H1~H6）**：10 案例全跑 + F1 ≥ 0.78 + ≥ 3 类触发 + evidence URL 可溯源

### §9.3 工程交付
- [ ] `pytest tests/cryo_guard/test_shareholder_engine.py -v` ≥ 7 passed
- [ ] `apps/cryo_guard/engines/shareholder_integrity/` 含 7 个 .py（4 节点 + engine + schemas + __init__）
- [ ] LangGraph workflow 注册 4 节点

### §9.4 一键复现
- [ ] **Makefile 合约**（§7.2）：11 个 target 已实现且通过；`make cryo-step05-all` 端到端 ≤ 4 hr
- [ ] **配置驱动可重入**：连跑两次 `make cryo-step05-all`，第二次跳过 RAG 索引（增量）+ 跳过训练（直接评测）≤ 8 min
- [ ] L4 实践记录 `04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_05_大股东诚信引擎LoRA.md` 已按 §8.4g 更新"二、实际进展"（含训练耗时、RAG 嵌入耗时、Milvus 行数、Holdout 指标、5 类触发、调参轮数）
- [ ] commit：`feat(cryo-guard): step_05 shareholder LoRA v1 + 4 节点引擎 + RAG + Holdout pass + Makefile [Ref: 03_/01_维度一/.../step_05]`
- [ ] **同会话验证**：上述命令在当次会话执行并输出摘要

## §10 [Deploy] 段

本步**不**产出镜像 / Chart / K8s workload；LoRA 落 `output/shareholder_lora_v1/` + RAG 索引存 Milvus Pod。step_07 vLLM 多 LoRA 热加载时统一编排。

> 与 step_04 一致的 deploy-engine 自检约定：修改 vllm/milvus K8s yaml 须在与 diting-infra 平级的独立 `deploy-engine/` 仓库内 push，再 `make update-deploy-engine`。**禁止**在 diting-infra 子模块拷贝内做写操作。

## §11 依赖与被依赖

**上游**：
- `step_01`：GPU + Milvus + bge-m3 模型 + vLLM；
- `step_02`：公告全量 + H031~H040 锁库；
- `step_03`：shareholder_integrity jsonl 6 份 + Verified ≥ 800；
- 用户提供：`WANDB_API_KEY`、GPU、Milvus 凭证。

**下游**：
- `step_07` 三引擎服务部署：消费 `shareholder_lora_v1`；
- `step_09` 50 案例综合 Holdout 评测：消费 engine.run() + adapter + Milvus；
- `step_08` decision_gate：消费 engine Prediction。

**严禁伪造**（no-mock-policy）：训练 / Holdout / Prediction / RAG 检索结果**不**允许 mock；Milvus 不可用须切 BM25 真索引（不能伪造命中）。

## §12 风险与回退

| 触发条件 | 动作 |
|---|---|
| Milvus 不可达 | 自动切 BM25 + 标 `retrieval_mode=bm25`；日志中文写明 |
| bge-m3 嵌入 OOM | 减 EMBED_BATCH_SIZE（默认 32 → 8 → 4）；仍失败用 CPU 推理 |
| 训练 OOM | 同 step_04 三级降级（batch=1 → QLoRA → rank=8） |
| 训练 loss 不收敛 | precheck 复核 Q1~Q3；lr 减半重训 |
| Holdout F1 不达 0.78 | 调参循环 ≤ 3 轮：① epoch=5；② lr=3e-5；③ 加 normal 样本；④ 加 RAG topk=20。每轮 ADR；3 轮不达 → 启动期降级 Recall ≥ 0.80 + ADR |
| 5 类触发 < 3 类 | Holdout 案例分布固有限制；交 step_09 综合评测在更大池子补 |
| 同问题修复重试 ≥ 2 次仍失败 | § 8.4f 回收 |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按新 L3 启动期 step 模板（v1.2）重写**（关键重构，与 `00_系统规则` §4.5 同步）：①删除全部嵌入完整 YAML / Python 类 / Prompt / Milvus schema 代码（原文 1034 行 → 现 ~340 行）；②新增 §3.5 数据质量验收矩阵 14 项（Q1~Q3 训练 + R1~R4 RAG 索引 + N1~N4 4 节点 + H1~H6 Holdout）；③§7 改为"实施规划"三段式（§7.1 实现要点 13 项 + §7.2 Makefile 合约 11 个 target + §7.3 给后续执行模型指引）；④§5.1 超参 + RAG 设计表只保留决策不嵌 yaml；⑤§9 准出加 Makefile 合约 + 增量索引可重入验证；⑥§12 风险与回退含 Milvus 切 BM25 + 嵌入 OOM 三级降级 + 调参循环 3 轮上限；⑦明确 L3 责任边界 |
| 2026-05-16 | 初版（含完整 yaml / 4 节点 Python 类 / RAG 代码块），1034 行 |
