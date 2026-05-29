# Step 06 · 关联交易引擎 LoRA v1 训练 + 图算法 cycle_detect

## §1 一句话定位与本步交付物

**一句话**：用 step_03 的 related_party Verified 数据集训练 Qwen2.5-7B-Instruct + LoRA（rank=16），并实现 6 节点 LangGraph 引擎（股权穿透 + 附注解析 + Neo4j 图构建 + cycle_detect + 明股实债识别 + LLM 聚合），在 10 案例 Holdout 上达到 **Recall ≥ 0.85 / Precision ≥ 0.70 / F1 ≥ 0.78**。

**交付物**（勾选 = 完成）：
- [ ] **A**（LoRA 训练完成）：`output/related_party_lora_v1/adapter_model.safetensors` 存在且 size > 60MB
- [ ] **B**（WandB 训练曲线）：`train/loss` 收敛 + `eval/loss` 不发散
- [ ] **C**（Neo4j 图谱构建）：active 标的（启动期典型 4~10 只）股权穿透深度 ≥ 2 层；每标的至少 5 个关联方节点 + 5 条 OWNS / RELATED 边（启动期降级见 §5.3）
- [ ] **D**（6 节点 Agent）：`apps/cryo_guard/engines/related_party/{equity_penetrator, note_parser, graph_builder, cycle_detector, debt_equity_detector, llm_aggregator, engine, schemas}.py` + LangGraph workflow 注册
- [ ] **E**（10 案例 Holdout 评测）：`output/eval_reports/related_party_holdout_v1.json` 含 `recall ≥ 0.85 / precision ≥ 0.70 / f1 ≥ 0.78 / num_cases = 10 / passed = true`
- [ ] **F**（4 类特征覆盖）：循环交易 / 明股实债 / 资金占用 / 附注披露异常 在评测样本中 ≥ 3 类触发（10 案例 H041~H050 分布限制：5 循环 + 3 明股实债 + 2 资金占用 → 启动期门槛 ≥ 3 类）
- [ ] **G**（图路径可追溯）：每个 cycle / 明股实债预测含 `evidence.cypher_path`（Cypher 查询串 + 经过节点列表）
- [ ] **H**（单测）：`pytest tests/cryo_guard/test_related_party_engine.py -v` ≥ 8 passed
- [ ] **I**（Makefile 一键复现）：`make cryo-step06-all` 端到端通过

> **本步是 step_07/09 的硬阻塞**：LoRA + Neo4j 图都就绪后才能开 vLLM 多 LoRA 热加载 + 综合 Holdout 评测。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2 哲学**：[01_维度一_极寒防御 · 04_防御实践策略规划](../../../../../02_战略维度/01_维度一_极寒防御/04_防御实践策略规划.md)
> - **本阶段总览**：[stage_1_启动期/README](../README.md)
> - **L3 模型训练**：[../04_模型训练与部署.md](../04_模型训练与部署.md) §一 训练目标（related_party Recall ≥ 0.85）
> - **L3 技术架构**：[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §二 代码结构（related_party 6 节点 Agent）
> - **L3 数据规约**：[../03_数据采集与预处理.md](../03_数据采集与预处理.md) §四 关联交易数据（股权穿透 + 关联方明细）
> - **L3 验收**：[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md) §二 模型验收（related_party Recall ≥ 0.85）
> - **DNA 键**：`_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml` → `deliverables.engines[2]` E3·related_party：`lora_name=related_party_lora_v1`、`detection_categories=4`、`agents=6`
> - **L4 实践记录**：[实践记录_step_06_关联交易引擎LoRA.md](../../../../../04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_06_关联交易引擎LoRA.md)
> - **上游 step**：← step_01（Neo4j）、step_02（关联方原始 + related_party_graph + H041~H050 Holdout）、step_03（related_party_{train,val,test}.json）
> - **下游 step**：→ step_07（vLLM 多 LoRA 热加载）、step_09（综合 Holdout 评测）

## §3 数据采集对象 / 落库映射

**本步不采集外部数据**——消费 step_02 关联方数据 + step_03 jsonl，**新建** Neo4j 图谱（节点 + 边）。

| 数据流向 | 来源 / 落库 | 用途 |
|---|---|---|
| `related_party_{train,val,test}.json` | step_03 `training/data/llama_factory/` | LoRA 训练输入 |
| `related_party_raw`（含 `pricing_method / amount_yuan / relationship`） | step_02 SQLite | `note_parser` 实时读取 |
| `related_party_graph`（启动期最小骨架）| step_02 SQLite | `graph_builder` 转 Neo4j 节点 / 边 |
| 企查查 API / akshare 前 10 大股东 | 外部（可选）| `equity_penetrator` 补充 2 层穿透 |
| Neo4j 节点：Company / Person / SPV | 本步**新建** | 关联方网络 |
| Neo4j 边：OWNS（含 percent）/ CONTROLS / RELATED_TO（含 reason）| 本步**新建** | 图算法基础 |
| `H041~H050.json`（10 关联交易案例）| step_02 锁库 | Holdout 评测金标 |
| LoRA 产物 | `output/related_party_lora_v1/` | adapter + 训练日志 |
| 评测产物 | `output/eval_reports/related_party_holdout_v1.json` | 指标 JSON + 4 类触发 + 图路径统计 |

## §3.5 数据质量验收矩阵（按 Holdout 评测需求反推 · 仅启动期负责）

> **本步范围**：训练数据 + Neo4j 图谱 + 6 节点引擎 + Holdout 评测四个环节。每行 ✅ 或 ⚠️ + 降级路径。**不**列扩展期内容。

### §3.5.1 训练数据质量（消费 step_03 产出）

| # | 分析维度 | 必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| Q1 | **4 类关联交易特征各类样本充足** | step_03 `teacher_distill` 中 `category ∈ {循环交易, 明股实债, 资金占用, 附注披露异常}` 各 ≥ 100 条 | ⚠️ 依赖 step_03 §3.5.3·T9 | §7.1·B precheck；缺类回 step_03 |
| Q2 | **关联方网络图引用率** | 样本 `evidence.parties[]` 含 `name / relationship / source_pdf_page` ≥ 80% | ⚠️ 依赖 step_03 §3.5.3·T10（启动期 graph 骨架 8 条，蒸馏可标 `graph_inferred=True`）| precheck 不达标暂停训练 |
| Q3 | **定价方法字段** | 样本 `evidence.pricing_method` 非 null 率 ≥ 50% | ⚠️ 依赖 step_03 §3.5.3·T11 | 无披露行 null 合规，不强造 |
| Q4 | **金额量级 / 占营收比** | 样本 `evidence.amount_yuan + revenue_pct` 双字段非空 ≥ 90% | ✅ step_03 §3.5.3·T12 强制 | precheck 全过 |

### §3.5.2 Neo4j 图谱质量（启动期最小骨架）

| # | 分析维度 | 必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| G1 | **active 标的 2 层股权穿透** | 每个 active 标的至少 2 层 OWNS 路径 + 直系股东 ≥ 5 个 | ⚠️ 依赖企查查 API；无 key 时退 akshare 前 10 大股东（仅 1 层） | 仅 1 层时标 `penetration_depth=1` + cycle_detector 跳过该标的 |
| G2 | **关联方节点最小骨架** | 每 active 标的至少 5 个 Person/Company 关联方节点 + 5 条 RELATED_TO 边 | ⚠️ 启动期 8 条 `related_party_graph` 骨架为基础（来自 step_02 §3.5.3·R4）| 不足时退到 raw 文本 + 标 `graph_partial=True` |
| G3 | **OWNS 边带 percent 属性** | 每条 OWNS 边含 `percent: float (0~100)` | ✅ 企查查 / akshare 都带 percent | 缺失行用 0.0 + 标 `percent_unknown=True` |
| G4 | **RELATED_TO 边带 reason** | 每条 RELATED_TO 边含 `reason: str`（如"配偶 / 共同投资 / 历史交易"）| ⚠️ 启动期文本抽取准确率目标 70% | 抽取失败用 "unknown" + 标 |

### §3.5.3 6 节点 Agent 输出质量

| # | 节点 | 设计目标 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| N1 | **equity_penetrator** | 调企查查 API 拿 2 层股权 → 写 Neo4j Person / Company / OWNS | ⚠️ 企查查 key 缺时切 akshare（仅 1 层）| 标 `penetration_depth` 在 evidence |
| N2 | **note_parser** | 从 `related_party_raw` 抽 `parties / amount / pricing / relationship`；按 active 标的 + 报告期过滤 | ✅ ORM 直接查 | 缺 OCR 文本退 raw 文本字段 |
| N3 | **graph_builder** | note_parser 输出 + equity_penetrator 输出 → Cypher MERGE 写 Neo4j；幂等（重复 case 不重复入图） | ✅ Cypher MERGE 天然幂等 | 写入失败行入 `failed_graph.log` |
| N4 | **cycle_detector** | 用 networkx / Neo4j 内置算法找 ≤ 4 跳环路；输出 `cycles[]` 含 `path / total_amount / pricing_method` | ⚠️ 启动期 active 标的图小，环路可能少；目标识别 ≥ 1 个/标的 | 0 环路时标 `no_cycle_found=True` 交 N6 兜底 |
| N5 | **debt_equity_detector** | 规则化识别"明股实债"特征：股权回购承诺 + 固定收益条款 + 实际控制权未转移 | ⚠️ 启动期规则覆盖 3 个典型模式 | 规则未覆盖的"创新结构"返回 `pattern_unknown=True` 交 N6 |
| N6 | **llm_aggregator** | 调 vLLM w/ `lora_name=related_party_lora_v1`；prompt = 公司基础 + parsed_notes + cycles + debt_equity_patterns + 图概要 → JSON `{label, confidence, risk_level, category, evidence[]}` | ✅ vLLM HTTP 直连 | LoRA 未加载降级 base model + 标 |

### §3.5.4 Holdout 评测质量（10 案例）

| # | 评测维度 | 准出门槛 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| H1 | **10 案例全跑** | num_cases = 10，不允许 skip | ✅ Holdout 锁库（H041~H050）保证 | 异常案例标 prediction=fail，不算 skip |
| H2 | **Recall ≥ 0.85** | 真为 related_party_risk 至少 85% 被预测 | ⚠️ 实测；不达进调参循环 | §12 ADR + 启动期降级 Recall ≥ 0.75 |
| H3 | **Precision ≥ 0.70** | 预测正样本至少 70% 真为正 | ⚠️ 实测 | 同 H2 |
| H4 | **F1 ≥ 0.78** | 调和均值 | ⚠️ 实测 | 同 H2 |
| H5 | **4 类覆盖** | ≥ 3 类（H041~H050 仅含循环 / 明股实债 / 资金占用 3 类，附注披露异常需 step_09 补） | ⚠️ Holdout 本身分布限制 | step_09 综合评测覆盖第 4 类 |
| H6 | **图路径可追溯** | 每个 cycle / 明股实债预测 `evidence.cypher_path` 在 Neo4j 真实可执行 | ⚠️ 抽样 3 条手工执行 Cypher | 失效路径（图后变）允许，但需标 `path_status=stale` |

> 共 **18 项启动期质量要求**（Q1~Q4 训练 + G1~G4 图谱 + N1~N6 6 节点 + H1~H6 评测）。矩阵中**无 ❌**。

### §3.5.5 质量门槛（合并到 §9.2）

矩阵每行须满足之一：
- **✅ 覆盖**：本步已实现且抽样验证通过；
- **⚠️ 启动期降级**：明确降级路径 + 在该降级下仍能满足 step_08 decision_gate baseline。

**禁止**：①Neo4j 图空时声称图构建完成；②指标不达标人工改 eval JSON；③Cypher 路径伪造（手编不在图中的节点）。

## §4 真实数据源与凭证清单

### §4.1 训练 + 图谱资源

| 资源 | 来源 | 备注 |
|---|---|---|
| 基模 Qwen2.5-7B-Instruct | step_01 已下载 | 共用 |
| Neo4j Community | step_01 已起 | 7687 端口 |
| LLaMA-Factory ≥ 0.8 | 已装 | 复用 |
| 训练数据 | step_03 产出 jsonl | 3 份 |
| Holdout 10 案例 | step_02 锁库 | H041~H050 |
| 企查查 API（可选） | 用户申请 | 缺则降 akshare |

### §4.2 用户须提供的凭证

| 凭证 | 用途 | 何时需要 | 写在哪里 |
|---|---|---|---|
| `WANDB_API_KEY` | 训练监控 | 训练前 | `diting-src/.env` |
| GPU 节点 | RTX 4090 24GB | 训练前 | step_01 已就绪 |
| `NEO4J_URI / NEO4J_USER / NEO4J_PASSWORD` | Neo4j 连接（默认 `bolt://neo4j-svc.diting:7687, neo4j, diting123`）| 图构建前 | `.env` |
| `QICHACHA_API_KEY`（可选）| 2 层股权穿透 | 图构建前；缺则降 akshare | `.env` |

## §5 启动期目标

### §5.1 训练超参 + 图设计

| 项 | 取值 | 理由 |
|---|---|---|
| 基模 / LoRA rank / alpha / dropout | Qwen2.5-7B-Instruct / 16 / 32 / 0.05 | 与 step_04/05 一致 |
| epochs / batch_size / grad_acc / cutoff | 3 / 2 / 8 / 4096 | 同 |
| lr / warmup_ratio | 5e-5 / 0.1 | 同 |
| Neo4j 节点 schema | Company (symbol, name, industry) / Person (name, role) / SPV (name, type) | 3 类标签 |
| Neo4j 边 schema | OWNS (percent) / CONTROLS (since) / RELATED_TO (reason, source) | 3 类边 |
| cycle 检测最大跳数 | 4 | 启动期；超过 4 跳的环误报多 |
| 图构建幂等 | Cypher MERGE | 重复 case 不重复入图 |

### §5.2 评测目标

| 指标 | 启动期门槛 | 评测集 |
|---|---|---|
| Recall | ≥ 0.85 | H041~H050 10 案例 |
| Precision | ≥ 0.70 | 同 |
| F1 | ≥ 0.78 | 同 |
| 4 类触发覆盖 | ≥ 3 类（受 Holdout 分布限制）| 同 |
| 图路径可追溯率 | ≥ 80%（cycle / 明股实债类预测）| 同 |
| 端到端单 case 延迟 | < 15 s（含图查询）| 10 案例平均 |

### §5.3 可接受退化

- 企查查 key 缺 → akshare 1 层穿透（cycle_detector 跳过深穿透标的）；
- active 标的图节点 < 5 → 退到 raw 文本，标 `graph_partial=True`；
- 训练后指标不达 → 调参循环 ≤ 3 轮；
- 仍不达 → ADR 启动期降级到 Recall ≥ 0.75。

> **启动期图规模降级**：旧版要求"节点 ≥ 1000 + 边 ≥ 1500"——启动期 active 标的 4~10 只 + 企查查 2 层穿透，**实际典型 50~300 节点 + 80~500 边**。本步**不**强制旧规模；按每标的 ≥ 5 节点 + 5 边 + 2 层穿透实测为准。

## §6 下一步（一行触发条件）

- **触发条件**：本步全部 ✅ + Holdout JSON `passed=true` → 三引擎（step_04/05/06）全部完成 → step_07 可开工。
- **下一阶段方向**：扩展期接入 GDS 图算法（PageRank / 社团检测）+ 企查查全量股权链路；详见 `stages/stage_2_扩展期/`。

## §7 实施规划（L3 设计 · 给后续执行模型的工作指引）

> **L3 定位**：本节是**设计规划 + 实现要点 + 验证标准**——**不嵌入完整 YAML / Python 类 / Cypher / Prompt 代码**。具体落地由 L4 实践记录 / 后续执行模型按本节规划自行完成。

### §7.1 实现要点（按交付物拆分）

| 实现要点 | 涉及代码位置 | 关键设计决策 | 验证标准 |
|---|---|---|---|
| **A LLaMA-Factory 数据集注册** | `training/configs/dataset_info.json`（追加 3 份）| 与 step_04/05 共存；命名 `related_party_train/val/test` | `llamafactory-cli` 加载不报错 |
| **B 训练 YAML + precheck** | `training/configs/related_party_lora.yaml` + `training/scripts/precheck_related_party.py` | yaml 同 §5.1；precheck 验 §3.5.1 Q1~Q4 | precheck 退出码 0 |
| **C 训练 + WandB** | 调 `llamafactory-cli train` | 与 step_04/05 共用流程 | adapter > 60MB |
| **D Neo4j 客户端封装** | `apps/cryo_guard/graph/neo4j_client.py` | `driver = GraphDatabase.driver(URI, auth)`；`run_cypher(query, **params) -> list[dict]`；`merge_node / merge_edge` 辅助；async + sync 双模 | 单测 mock Neo4j 验 query 调用 |
| **E equity_penetrator 节点** | `apps/cryo_guard/engines/related_party/equity_penetrator.py` | 优先调企查查 `/api/equity-penetration?symbol=&depth=2`；缺 key 降 akshare `stock_main_stock_holder`（1 层）；输出 `equity_nodes[] + equity_edges[]` | 单测对 1 真标的（公开数据，如贵州茅台）返回 ≥ 5 节点 + ≥ 5 边 |
| **F note_parser 节点** | `note_parser.py` | 从 `related_party_raw where symbol = ? and report_period = ?` 抽 `parties / amount / pricing / relationship`；按金额倒排取 top-20 | 单测 4 标的 × 4 期数据抽出非空 |
| **G graph_builder 节点** | `graph_builder.py` | equity_penetrator + note_parser 输出 → Cypher `MERGE`（幂等）；批量 1 个事务；返回 `nodes_created + edges_created` 计数 | 单测 mock + 真 Neo4j 跑 1 标的；二次跑计数 0（幂等） |
| **H cycle_detector 节点** | `cycle_detector.py` | Cypher `MATCH p=(c:Company {symbol:$symbol})-[:RELATED_TO*1..4]-(c) RETURN p`；或用 networkx 离线算（图小时）；输出 `cycles[]` 含 `path / total_amount / pricing_summary` | 单测构造 3 节点环图 → 检出 1 环 |
| **I debt_equity_detector 节点** | `debt_equity_detector.py` + `configs/related_party_patterns.yaml` | 3 个规则：① 股权回购承诺 + 固定收益（年化 ≥ 5%）；② 实际控制权未转移；③ 抽屉协议关键词；阈值放 yaml | 单测 3 类各正负 1 案例 = 6 测试 |
| **J llm_aggregator 节点** | `llm_aggregator.py` + `prompts/related_party.py` | 调 vLLM w/ `lora_name=related_party_lora_v1`；prompt = 公司基础 + parsed_notes + cycles 摘要 + debt_equity_patterns → JSON；schema retry ≤ 2 次 | mock vLLM 响应通过 schema |
| **K engine + LangGraph** | `engine.py` + `schemas.py` | LangGraph: START → 并行(equity_penetrator, note_parser) → graph_builder → 并行(cycle_detector, debt_equity_detector) → llm_aggregator → END；State 含全部上述对象；`engine.run(symbol, period) -> Prediction` | e2e mock 跑 1 case |
| **L Holdout 评测脚本** | `training/scripts/eval_related_party_holdout.py` | 读 H041~H050 → engine.run() → 算 Recall/Precision/F1 + 4 类触发 + Cypher 路径可达率；输出 JSON `passed=true/false` | 10 案例全跑 + 指标达 §5.2 |
| **M 单测** | `tests/cryo_guard/test_related_party_engine.py` | 6 节点单测 + 3 类明股实债规则 + cycle 算法 + e2e mock + Holdout fixture | `pytest -v` ≥ 8 passed |

### §7.2 Makefile 一键复现合约（L3 约定 · L4 实现）

**设计目的**：跑 `make cryo-step06-all` 完成"数据预检 → 股权穿透 → 图构建 → LoRA 训练 → 引擎单测 → Holdout 评测"全套。

**target 合约表**：

| target | 用途 | 入参（环境变量 · 均有默认） | 验证标准 |
|---|---|---|---|
| `make cryo-step06-prep` | 数据集注册 + GPU/Neo4j 自检 + WandB login | `WANDB_API_KEY / NEO4J_URI` | `nvidia-smi / cypher-shell "RETURN 1"` 都 OK |
| `make cryo-step06-precheck` | §7.1·B 训练前数据预检 | — | Q1~Q4 全过 |
| `make cryo-step06-build-graph` | 调用 equity_penetrator + graph_builder 把 active 标的全部入图 | `MY_HOLDINGS_YAML / QICHACHA_API_KEY` | active 标的全部入图；每标的 ≥ 5 节点 + 5 边 + 2 层穿透 |
| `make cryo-step06-train` | LoRA 训练 | `LORA_CONFIG=training/configs/related_party_lora.yaml` | adapter > 60MB |
| `make cryo-step06-smoke-eval` | val.json 抽 30 条快评 | — | F1 > 0.4 |
| `make cryo-step06-engine-test` | 6 节点单测 + e2e mock | — | `pytest -v` ≥ 8 passed |
| `make cryo-step06-holdout-eval` | 10 案例 Holdout | `HOLDOUT_DIR` | F1 ≥ 0.78 + Recall ≥ 0.85 + Precision ≥ 0.70 + ≥ 3 类 + 路径可达 ≥ 80%；`passed=true` |
| `make cryo-step06-all` | **端到端一键** | 同上合并 | 全部退出码 0；4090 端到端 ≤ 4 hr（含图构建 + 训练） |
| `make cryo-step06-retrain` | 调参循环 | 改 yaml 后跑 | 同 all 跳过 prep/build-graph |
| `make cryo-step06-status` | 进度快照（只读） | — | 打印训练状态 + Neo4j 节点 / 边数 + 最近评测指标 |
| `make cryo-step06-clean` | 清 LoRA + Neo4j 图（保留 schema）| — | 已删；基模保留 |

**合约要求**：
1. **入参环境变量化**；
2. **target 是薄包装**：训练调 `llamafactory-cli`，图构建调 `training/scripts/build_related_party_graph.py`；
3. **可重入幂等**：Cypher MERGE 天然幂等；adapter 已存在 + JSON passed=true 则跳过训练直接验证；
4. **配置驱动**：增标的 → 改 `my_holdings.yaml` → 重跑 `build-graph` 仅增量入图新 symbol；
5. **API 降级显式**：企查查 key 缺时自动切 akshare，日志中文写明"已降级为 1 层穿透"。

### §7.3 给后续执行模型的指引

L4 / 执行模型按以下顺序：

1. **核对前置**：step_01 GPU + Neo4j Ready；step_02 H041~H050 锁库 ✅ + `related_party_raw` ≥ 5000 + `related_party_graph` ≥ 8 行；step_03 jsonl 6 份 + Verified ≥ 800；
2. **逐项落地 A~M**：建议顺序 D→E→F→G→B→C→H→I→J→K→L→M（图先于业务节点）；
3. **集成 Makefile**：按 §7.2 实现 11 个 target；
4. **训练前必跑 precheck + 图构建**：缺图 cycle_detector 必空；
5. **训练后 Holdout 评测**：不达进调参循环 ≤ 3 轮；3 轮不达 §12 启动期降级；
6. **§9 准出 + L4 回写**：训练耗时、图构建耗时、Neo4j 节点 / 边数、Recall/Precision/F1、4 类触发、调参轮数；
7. **遇问题**：企查查限流 → 切 akshare（标 `equity_source=akshare`）；图查询超时 → 切 networkx 离线（图小时）；调参 ≥ 2 次仍失败 § 8.4f 回收。

> **L3 责任边界**：本节给规划 + 实现要点 + 验证标准；**不**给完整 Cypher / Python 类 / Prompt 字面量。

## §8 部署节奏（本步在哪里跑）

| 阶段 | 形态 | 是否本步必须 | 说明 |
|---|---|---|---|
| **本机开发** | `python -m apps.cryo_guard.engines.related_party.engine` + `pytest` + `llamafactory-cli train` | **必须** | 6 节点 + 训练 + 评测 |
| **本机 docker-compose** | — | 否 | Neo4j / vLLM 已在 step_01 Dev K3s 起 |
| **Dev K3s** | 图谱落 Neo4j Pod；LoRA 挂载 vllm Pod | **必须** | 推理评测依赖 |
| **ACR + 生产 K3s** | 扩展期镜像化 | 否 | 启动期 PVC 挂载即可 |

**本步默认运行形态**：本机训练 + Dev K3s 图存储 + 推理。

## §9 准出标准（同会话可执行清单 · 质量优于数量）

### §9.1 训练与文件门槛
- [ ] `ls -lh output/related_party_lora_v1/adapter_model.safetensors` size > 60MB
- [ ] WandB run `finished`；loss 曲线 OK
- [ ] `output/eval_reports/related_party_holdout_v1.json` 存在且 `passed=true`

### §9.2 数据质量门槛（§3.5 矩阵 18 项）
- [ ] **训练数据 4 项（Q1~Q4）**：precheck 全过
- [ ] **图谱 4 项（G1~G4）**：每 active 标的 ≥ 5 节点 + 5 边 + 2 层穿透（缺 key 时 1 层 + 标）
- [ ] **6 节点 6 项（N1~N6）**：单测全过 + 抽样推理无 schema 错
- [ ] **Holdout 6 项（H1~H6）**：10 案例全跑 + F1 ≥ 0.78 + ≥ 3 类 + Cypher 路径抽样可达

### §9.3 工程交付
- [ ] `pytest tests/cryo_guard/test_related_party_engine.py -v` ≥ 8 passed
- [ ] `apps/cryo_guard/engines/related_party/` 含 9 个 .py（6 节点 + engine + schemas + __init__）
- [ ] LangGraph workflow 注册 6 节点 + 入口 + END

### §9.4 一键复现
- [ ] **Makefile 合约**（§7.2）：11 个 target 已实现且通过；`make cryo-step06-all` 端到端 ≤ 4 hr
- [ ] **可重入验证**：连跑两次 `make cryo-step06-all`，第二次跳过图构建（幂等）+ 跳过训练（直接评测）≤ 8 min
- [ ] **配置驱动**：临时新增 1 个 active 标的 → `make cryo-step06-build-graph` 仅增量入图新 symbol
- [ ] L4 实践记录 `04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_06_关联交易引擎LoRA.md` 已按 §8.4g 更新"二、实际进展"（训练耗时、图构建耗时、Neo4j 节点 / 边数、Holdout 指标、4 类触发、调参轮数）
- [ ] commit：`feat(cryo-guard): step_06 related_party LoRA v1 + 6 节点引擎 + cycle_detect + Holdout pass + Makefile [Ref: 03_/01_维度一/.../step_06]`
- [ ] **同会话验证**：上述命令在当次会话执行并输出摘要

## §10 [Deploy] 段

本步**不**产出镜像 / Chart / K8s workload；LoRA 落 `output/related_party_lora_v1/` + 图谱存 Neo4j Pod。step_07 vLLM 多 LoRA 热加载时三引擎统一编排。

> 与 step_04/05 一致的 deploy-engine 自检约定：修改 neo4j/vllm K8s yaml 须在平级 `deploy-engine/` 仓库 push 后 `make update-deploy-engine`。**禁止**在 diting-infra 子模块拷贝内做写操作。

## §11 依赖与被依赖

**上游**：
- `step_01`：GPU + Neo4j + vLLM；
- `step_02`：`related_party_raw` ≥ 5000 + `related_party_graph` ≥ 8 行（最小骨架）+ H041~H050 锁库；
- `step_03`：related_party jsonl 6 份 + Verified ≥ 800；
- 用户提供：`WANDB_API_KEY`、GPU、Neo4j 凭证；可选 `QICHACHA_API_KEY`。

**下游**：
- `step_07` 三引擎服务部署：消费 `related_party_lora_v1`；
- `step_09` 50 案例综合 Holdout 评测：消费 engine.run() + adapter + Neo4j 图；
- `step_08` decision_gate：消费 engine Prediction。

**严禁伪造**（no-mock-policy）：训练 / Holdout / Prediction / Cypher 路径**不**允许 mock；企查查不可用须切 akshare 真实数据（不能 mock 股权关系）。

## §12 风险与回退

| 触发条件 | 动作 |
|---|---|
| 企查查 API 限流 / key 不可用 | 切 akshare 前 10 大股东（1 层）+ 标 `equity_source=akshare`；cycle_detector 跳过该标的 |
| Neo4j 不可达 | 切 networkx 离线（启动期图小可行）+ 标 `graph_backend=networkx`；扩展期回 Neo4j |
| 训练 OOM | 同 step_04/05 三级降级（batch=1 → QLoRA → rank=8） |
| Holdout F1 不达 0.78 | 调参循环 ≤ 3 轮：① epoch=5；② lr=3e-5；③ 加 normal 样本；④ 加图特征（直系股东数 / 行业集中度）。每轮 ADR；3 轮不达 → 启动期降级 Recall ≥ 0.75 + ADR |
| 4 类触发 < 3 类 | Holdout 案例分布限制；交 step_09 综合评测在更大池补 |
| Cypher 路径可达率 < 80% | 检查 graph_builder 幂等性是否被破坏（如重复跑后边重复） |
| 同问题修复重试 ≥ 2 次仍失败 | § 8.4f 回收 |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按新 L3 启动期 step 模板（v1.2）重写**（关键重构，与 `00_系统规则` §4.5 同步）：①删除全部嵌入完整 Cypher / Python 类 / Prompt 代码（原文 1078 行 → 现 ~350 行）；②新增 §3.5 数据质量验收矩阵 18 项（Q1~Q4 训练 + G1~G4 图谱 + N1~N6 6 节点 + H1~H6 Holdout）；③§7 改为"实施规划"三段式（§7.1 实现要点 13 项 + §7.2 Makefile 合约 11 个 target + §7.3 给后续执行模型指引）；④§5.3 修正启动期图规模（不再强求节点 ≥ 1000）；⑤§9 准出加 Makefile 合约 + 增量图入图可重入验证；⑥§12 含企查查降级 akshare + Neo4j 切 networkx + 调参循环 3 轮上限；⑦明确 L3 责任边界 |
| 2026-05-16 | 初版（含完整 yaml / 6 节点 Python 类 / Cypher 代码块），1078 行 |
