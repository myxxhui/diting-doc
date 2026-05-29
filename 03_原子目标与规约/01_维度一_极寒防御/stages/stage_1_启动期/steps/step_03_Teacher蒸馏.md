# Step 03 · Teacher 蒸馏 3500 条 + 架构师 Verified ≥ 2600

## §1 一句话定位与本步交付物

**一句话**：用大模型（Claude 3.5 Sonnet 或备源 OpenAI o1）把 step_02 的原始财报 / 公告 / 关联方数据"消化"成 3 个引擎可直接训练的 LoRA 数据集（alpaca 格式），并由架构师人工 Verified ≥ 2600 条作为高质量训练种子。

**交付物**（勾选 = 完成）：
- [ ] **A**（蒸馏代码骨架）：`apps/cryo_guard/distillation/` 完整 5 模块：`prompts.py / teacher_client.py / distill_runner.py / verifier.py / exporter.py`
- [ ] **B**（蒸馏数据 ≥ 3500 条 · 落库）：`teacher_distill` 表中 financial_fraud ≥ 1500 + shareholder ≥ 1000 + related_party ≥ 1000；含 `instruction / input / output / teacher_model / teacher_tokens_in / teacher_tokens_out / latency_ms / case_hash / verified=FALSE`
- [ ] **C**（Verified ≥ 2600 条 · 架构师审）：同表 `verified=TRUE` 数：financial_fraud ≥ 1000 + shareholder ≥ 800 + related_party ≥ 800
- [ ] **D**（LLaMA-Factory 导出）：3 份 jsonl（每引擎 1 份），按 80/10/10 切分为 `_train.json / _val.json / _test.json`，落 `training/data/llama_factory/`
- [ ] **E**（Holdout 守门）：`holdout_guard.py --check-training-data training/data/llama_factory/*.json` 退出码 0（无 Holdout symbol 污染训练集）
- [ ] **F**（DVC 跟踪）：`dvc add training/data/teacher_distill training/data/verified training/data/llama_factory`
- [ ] **G**（数据质量审计）：JSON Schema 校验全过 + 解析失败率 ≤ 5%（超过则 §7 优化 Prompt 重蒸）
- [ ] **H**（单测）：`pytest tests/cryo_guard/test_distillation.py -v` ≥ 7 passed
- [ ] **I**（WandB 记录）：蒸馏 token 消耗 / JSON 解析失败率 / 各引擎样本分布

> **本步是 step_04~06 LoRA 训练的硬阻塞**：训练集质量决定模型上限；本步不达数据质量 → 三引擎 Recall 全部上不去。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2 哲学**：[01_维度一_极寒防御 · 04_防御实践策略规划](../../../../../02_战略维度/01_维度一_极寒防御/04_防御实践策略规划.md)
> - **本阶段总览**：[stage_1_启动期/README](../README.md)
> - **L3 数据采集**：[../03_数据采集与预处理.md](../03_数据采集与预处理.md) §六 Teacher 蒸馏数据（6.1/6.2/6.3/6.4）+ §七 质量管控
> - **L3 训练**：[../04_模型训练与部署.md](../04_模型训练与部署.md) §三 数据预处理（alpaca 格式）+ §一 训练目标
> - **DNA 键**：`_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml` → `training_data_scale.teacher_distill`（1500/1000/1000）、`training_data_scale.verified_min`（1000/800/800）
> - **维度五 Teacher 复用**：`_System_DNA/05_super_evo/dna_stage_1_启动期.yaml` → `services.teacher.client_path`
> - **L4 实践记录**：[实践记录_step_03_Teacher蒸馏.md](../../../../../04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_03_Teacher蒸馏.md)
> - **上游 step**：← step_02（财报 / 公告 / 关联方原始数据 + Holdout 黑名单）
> - **下游 step**：→ step_04（财务测谎 LoRA 训练）、step_05（大股东诚信 LoRA）、step_06（关联交易 LoRA）

## §3 数据采集对象 / 落库映射

**本步不采集外部数据**——以 step_02 已落库的原始数据为输入，**生成 / 蒸馏 / 落库 LLM 输出**。

| 业务对象 | ORM 表 / 关键字段 | 输入来源 | 蒸馏脚本（diting-src） |
|---|---|---|---|
| Teacher 蒸馏样本 | `teacher_distill`（`engine_name / symbol / company_name / report_period / instruction / input / output / teacher_model / teacher_tokens_in/out / latency_ms / case_hash / verified` + JSON 加权字段）| `financial_reports / announcements / related_party_raw`（step_02 已落库）| `apps/cryo_guard/distillation/distill_runner.py` |
| 架构师 Verified 标志 | 同表 `verified=TRUE`（人工 review 后翻转）| 架构师手动 review | `apps/cryo_guard/distillation/verifier.py`（CLI 审核工具 + Web 占位）|
| LLaMA-Factory 数据集 | `training/data/llama_factory/{financial_fraud,shareholder,related_party}_{train,val,test}.json` | `teacher_distill` where `verified=TRUE` | `apps/cryo_guard/distillation/exporter.py` |

**零值 / 缺失语义**：`teacher_tokens_in / out / latency_ms` 允许 null（备源 OpenAI o1 不返回 latency 时）；`output` **必须**通过 JSON Schema 校验，解析失败的行**不入库**（计入 reject 计数）。

### §3.1 `teacher_distill` ORM 表 schema 简表

| 列 | 类型 | 约束 / 索引 | 用途 |
|---|---|---|---|
| id | INTEGER | PK | — |
| engine_name | VARCHAR(32) | NOT NULL | `financial_fraud / shareholder / related_party` |
| symbol | VARCHAR(16) | NOT NULL | A 股代码 |
| company_name | VARCHAR(64) | NULL | 公司名 |
| report_period | VARCHAR(16) | NULL | `2024Q3` / `2024_annual` |
| case_hash | VARCHAR(32) | NOT NULL **UNIQUE**（uq_case_hash）| md5(engine+symbol+period+input)，防重蒸 |
| instruction | TEXT | NOT NULL | Prompt 中给 Teacher 的指令 |
| input | TEXT | NOT NULL | 财报/公告/关联方原文（脱敏后）|
| output | TEXT | NOT NULL | Teacher 返回的合法 JSON（含 label/evidence/reason）|
| teacher_model | VARCHAR(64) | NOT NULL | `claude-3-5-sonnet-20241022` 等 |
| teacher_fallback | VARCHAR(32) | NULL | 备源切换标记（`openai_o1` / `deepseek_v2.5`）|
| teacher_tokens_in / out | INTEGER | NULL | Token 消耗 |
| latency_ms | INTEGER | NULL | 调用耗时 |
| verified | BOOLEAN | NOT NULL DEFAULT FALSE | 架构师审核状态 |
| verified_by | VARCHAR(64) | NULL | 审核人 |
| verified_at | DATETIME | NULL | 审核时间 |
| created_at | DATETIME | DEFAULT NOW | — |
| INDEX(engine_name, verified) | | `ix_engine_verified` | export 查询 |

### §3.2 output JSON schema 示例（alpaca 格式 + 三引擎结构）

**financial_fraud 引擎 output 示例**：

```json
{
  "label": "fraud",
  "confidence": 0.83,
  "risk_level": "high",
  "category": "rd_capitalization_jump",
  "features": {
    "cash_flow_divergence": false,
    "accounts_recv_anomaly": true,
    "double_high_cash_debt": false,
    "inventory_stagnation": false,
    "rd_capitalization_jump": true,
    "gross_margin_anomaly": true
  },
  "evidence": [
    {
      "field": "rd_capitalized",
      "value": 18.7,
      "unit": "亿元",
      "source_table": "financial_reports",
      "source_period": "2024_annual",
      "human_readable_reason": "研发资本化金额同比+340% 远超行业基线"
    }
  ],
  "reason_zh": "研发资本化口径异常 + 应收账款增速 1.6× 营收增速，疑似利润粉饰"
}
```

**shareholder / related_party** 输出结构同框架（`label / confidence / category / evidence[] / reason_zh`），category 枚举见 §3.5.2 / §3.5.3。

## §3.5 数据质量验收矩阵（按目标引擎反推 · 仅启动期负责）

> **本步范围**：Teacher 蒸馏数据**直接决定 step_04~06 三引擎的训练上限**。质量门槛远比"3500 条"重要——3500 条低质量数据训不出 Recall=0.95；2600 条高质量 Verified 数据可以。

### §3.5.1 财务测谎引擎（step_04）所需的蒸馏质量

| # | 分析维度 | 蒸馏样本必含字段（output JSON）| 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| T1 | **6 类粉饰特征全覆盖** | `features.{cash_flow_divergence, accounts_recv_anomaly, double_high_cash_debt, inventory_stagnation, rd_capitalization_jump, gross_margin_anomaly}` 6 个 bool 字段 | ⚠️ 启动期蒸馏 1500 条须覆盖 6 类各 ≥ 150 条；Verified ≥ 1000 时每类至少 100 条 | §7 加 `prompts.py` 中 6 类显式触发模板 + 蒸馏后 `verifier.py` 按类抽样 |
| T2 | **证据链（evidence）可追溯** | `evidence[]` 数组：每条含 `field / value / source_table / source_period / human_readable_reason`（中文）| ✅ Prompt 强制 | `verifier.py` 抽样 50 条对照 step_02 SQLite 真值 |
| T3 | **结论结构化（label / confidence）** | `label: "fraud/normal"`、`confidence: 0.0~1.0`、`risk_level: "high/medium/low"` | ✅ JSON Schema 强约束 | 解析失败行入 `failed_distill.jsonl` 单独留作 Prompt 优化样本 |
| T4 | **正负样本平衡** | 整体 `label=fraud` 与 `normal` 比例 ≥ 30:70（避免训练偏置） | ⚠️ 蒸馏后统计；偏差 ≥ 5% → §7 加补充样本 | `exporter.py` 输出统计 + 不达标退出码 1 |

### §3.5.2 大股东诚信引擎（step_05）所需的蒸馏质量

| # | 分析维度 | 蒸馏样本必含字段 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| T5 | **5 类言行不一全覆盖** | `category ∈ {增持失信, 减持违规, 业绩对赌失败, 质押隐瞒, 战略落空}` | ⚠️ 启动期蒸馏 1000 条须 5 类各 ≥ 100 条；Verified ≥ 800 时每类至少 80 条 | §7 加 `prompts.py` 中 5 类显式触发模板 |
| T6 | **承诺 / 实际 双段对比** | `evidence` 含 `promise.{date, text, amount}` + `actual.{date, text, amount, deviation_pct}` | ⚠️ 启动期 Teacher 抽取，准确率目标 ≥ 80% | `verifier.py` 抽样 30 条对照原始公告 PDF |
| T7 | **公告 URL 锚定** | `evidence.source_url`（巨潮 cninfo 全文链接）+ `source_announcement_id` | ✅ step_02 已采，蒸馏时透传 | 缺 URL 行入 reject |
| T8 | **正负样本平衡** | 整体 `label=integrity_failure` 与 `normal` ≥ 25:75 | ⚠️ 启动期偏负样本（多采暴雷公告，正样本少需补） | §7 加 100 条白名单蓝筹"言行一致"样本 |

### §3.5.3 关联交易引擎（step_06）所需的蒸馏质量

| # | 分析维度 | 蒸馏样本必含字段 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| T9 | **4 类关联交易特征全覆盖** | `category ∈ {循环交易, 明股实债, 资金占用, 附注披露异常}` | ⚠️ 启动期蒸馏 1000 条须 4 类各 ≥ 100 条；Verified ≥ 800 时每类至少 80 条 | §7 加 `prompts.py` 中 4 类显式触发模板 |
| T10 | **关联方网络图引用** | `evidence` 含 `parties[].{name, relationship, source_pdf_page}` | ⚠️ 依赖 step_02 §3.5.3 R1 关联方图骨架 | 启动期 8 条图骨架不足时，蒸馏用 Teacher 文本推断 + 备注 `graph_inferred=TRUE` |
| T11 | **定价方法字段** | `evidence` 含 `pricing_method`（市价 / 协议 / 成本+ / 无披露）| ⚠️ 启动期依赖 step_02 §3.5.3 R3 抽取（非 null 率 ≥ 50%）| 无披露行 Teacher 不强造，留 null |
| T12 | **金额量级** | `evidence` 含 `amount_yuan`（含单位元）+ `revenue_pct`（占营收比） | ✅ step_02 关联方 `amount` 已采，蒸馏时计算占比 | — |

### §3.5.4 三引擎共用质量

| # | 维度 | 必含字段 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| T13 | **JSON Schema 校验通过** | `output` 必须解析为合法 JSON 且通过 Pydantic schema | ✅ `verifier.py` 内置 schema | 解析失败率 > 5% → 暂停蒸馏 + 优化 Prompt |
| T14 | **Holdout 不污染** | `symbol` 不属于 H001~H050 的 50 标的 | ✅ `distill_runner.py` 调 `HoldoutGuard.is_blacklisted()` 拒绝 | 误命中行直接 skip + 计入 reject 计数 |
| T15 | **架构师 Verified 占比** | `verified=TRUE` / 总数 ≥ 75%（启动期门槛）| ⚠️ 启动期人工 review 工作量大，提供 CLI `verifier.py review --engine X --batch 20` | 不达 75% 时只能用 verified=TRUE 子集训练，量小但质量保证 |
| T16 | **Teacher 模型口径一致** | 同一引擎全部用同一 Teacher（不混 Claude + OpenAI o1）| ⚠️ Claude 限流时切 cross-region；备源 OpenAI o1 时**标注** `teacher_fallback=openai_o1` 单独存表 | step_04~06 训练时**按 Teacher 分组训练**或显式声明混源 |

> 共 **16 项启动期质量要求**。矩阵中**没有** ❌ 行——质量不达标的样本**不入 Verified**，由 `verifier.py` 拒绝。

### §3.5.5 质量门槛（合并到 §9.2）

矩阵每行须满足之一：
- **✅ 覆盖**：本步已实现校验逻辑，§9 抽样验证字段覆盖率 ≥ 90%；
- **⚠️ 启动期降级**：本步给出明确降级路径（如 T10 图骨架不足 → 文本推断 + 标注；T16 Teacher 切换 → 显式标注）。

**禁止**：①用假 LLM 响应充数（no-mock-policy）；②`verified=TRUE` 行未经架构师 review 直接置位；③把解析失败行假装合规入库。

## §4 真实数据源与凭证清单

### §4.1 Teacher 模型选型

| 优先级 | Teacher 模型 | 接口 | 备注 |
|---|---|---|---|
| **首选** | Claude 3.5 Sonnet | Anthropic API（直连 `ANTHROPIC_API_KEY`）或 AWS Bedrock cross-region | 启动期推荐；JSON 输出稳定、推理链清晰、限流时切 Bedrock |
| **备源** | OpenAI o1（o1-preview / o1-mini）| OpenAI API `OPENAI_API_KEY` | Claude 不可用时切；蒸馏样本标 `teacher_fallback=openai_o1`，**不混入** Claude 主流数据 |
| **第二备源** | DeepSeek V2.5（chat-prefill）| DeepSeek API `DEEPSEEK_API_KEY` | 极端降级；启动期不推荐主用，但可作可观测对照 |

### §4.2 用户须提供的凭证

| 凭证 | 用途 | 何时需要 | 写在哪里 |
|---|---|---|---|
| `ANTHROPIC_API_KEY` _或_ AWS Bedrock IAM（`AWS_REGION + AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY`）| Claude 3.5 Sonnet 蒸馏 | **本步执行前必填**（蒸馏的核心凭证）| `diting-src/.env` |
| `OPENAI_API_KEY` | 备源 o1 | Claude 不可用时 | `diting-src/.env` |
| `DEEPSEEK_API_KEY` | 第二备源 | 极端降级 | `diting-src/.env` |
| `WANDB_API_KEY` | 蒸馏过程监控（token 消耗 / 失败率） | 蒸馏开跑前 | `diting-src/.env` |
| `MY_HOLDINGS_YAML` | 来自 step_02 的持仓 SoT，蒸馏样本来自这些标的 | 已在 step_02 配置 | `diting-src/.env` |

> **本步无新增凭证**仅一种情况：D5 维度五 step_03 已提供 `teacher_client.py` 复用接口（同 IAM），此时本步不直接调 Anthropic / OpenAI 而调 D5 HTTP `POST /api/teacher/distill`。

## §5 启动期目标

### §5.1 数据范围
- **来源标的**：step_02 已落库的 active SoT 标的（启动期典型 4~10 只），按"暴雷 + 白名单"按比例蒸馏（财务测谎偏暴雷、大股东偏违规、关联偏循环）。
- **蒸馏样本数**：3500 条（financial_fraud 1500 + shareholder 1000 + related_party 1000）。

### §5.2 数据量预期（最低门槛 · 必要不充分）

| 指标 | 启动期最小值 | 验证 SQL |
|---|---|---|
| `teacher_distill` 总行数 | **≥ 3500**（含 verified=FALSE）| `SELECT COUNT(*) FROM teacher_distill;` |
| financial_fraud 蒸馏行数 | ≥ 1500 | `SELECT COUNT(*) FROM teacher_distill WHERE engine_name='financial_fraud';` |
| shareholder 蒸馏行数 | ≥ 1000 | 同上 + `='shareholder'` |
| related_party 蒸馏行数 | ≥ 1000 | 同上 + `='related_party'` |
| Verified 总数 | **≥ 2600** | `SELECT COUNT(*) FROM teacher_distill WHERE verified=TRUE;` |
| JSON 解析失败率 | **≤ 5%**（`failed_distill.jsonl` 行数 / 蒸馏请求总数）| WandB 报告 |
| Holdout 污染 | **= 0** | `holdout_guard.py --check-training-data` 退出码 0 |

> 上表是**必要不充分**门槛；真正准出还要 §3.5 16 项矩阵全 ✅ / ⚠️。

### §5.3 可接受退化
- Claude 限流 → 切 Bedrock cross-region 或 OpenAI o1（标注 `teacher_fallback`）；
- 单引擎 Verified 不达 800/1000 → 用 verified=TRUE 子集训练 + L4 实践记录写明实际量；
- 单类特征覆盖不达 100 条 / 80 条 → §7 加 Prompt 显式触发模板 + 重蒸该类。

## §6 下一步（一行触发条件）

- **触发条件**：本步全部 ✅ + 三引擎 `_train.json` 行数达 §5.2 → step_04 / 05 / 06 可并行开训。
- **下一阶段方向**：扩展期增加 RLHF / DPO 二次精调 + 跨引擎共享 prompt 模板；详见 [`stages/stage_2_扩展期/step_02_Teacher蒸馏深化.md`](../../stage_2_扩展期/step_02_Teacher蒸馏深化.md)（Phase 2 新建）。

## §6.5 长期推演（65 → 3500 case 路径 + 三档质量矩阵 · 给后续模型的工作指引）

> **本节定位**：把"Teacher 蒸馏"从启动期 65 条小试，到扩展期 3500 条基线，再到完善期 10000+ 条精炼的路径**预先推演到完善期**，**写入本 step**——让后续低/中模型在 stage_2/stage_3 接手时**严格对齐本表**不偏离方向。
>
> **强约束**：①本节**不**是 stage_2/stage_3 的代替品；②本节是**门槛表 + 蒸馏样本质量口径**，让架构师 + 执行模型在同一张表里看到 3 阶段全貌；③低/中模型不得修改本表门槛——如需调整须先在 L3 修订并提交。

### §6.5.1 三档蒸馏路径总表（D1 三引擎共用 · 财务/股东/关联）

| 维度 | 启动期（stage_1，本 step）| 扩展期（stage_2 · step_02）| 完善期（stage_3 · step_02）|
|---|---|---|---|
| **总目标 case 数（三引擎合计）** | 100~500（试跑）| **3500（基线）**：财务 1800 / 股东 1000 / 关联 700 | 10000+（覆盖罕见信号）|
| **蒸馏数据源** | step_02 已采的 8 标的（≈ 1300 有效关联交易行 + 1051 公告 + 136 财报） | step_02 扩展期产物（100 标的 × 8 年） + 历史暴雷案例库 | 全 A × 10 年 + 多源（巨潮 / Wind / 监管处罚 / 学术案例库）|
| **Teacher 模型** | Claude **Sonnet 4.5/3.5**（启动期试跑，节省成本）+ Opus 4.7 抽 5% 质量校验 | **Claude Sonnet 主蒸 + Opus 4.7 抽 20% 质量校验** | **Sonnet 主蒸 + Opus 4.7 + GPT-4o 多模型一致性投票** |
| **单 case Token 成本** | ~2000 token in / 800 out（约 $0.015）| ~3000 / 1200（约 $0.022） | ~5000 / 2000（含多源交叉，约 $0.05）|
| **总成本估算（USD）** | ≤ $10（小试）| ≤ $80 | ≤ $500 |
| **`verified` 字段标注率** | 100% Verified（架构师亲审或 LLM 自评 ≥ 0.9）| ≥ 60% Verified（小模型预筛 + 架构师抽审 ≥ 10%）| ≥ 30% Verified + 70% Auto Accept（基于 Critic 引擎打分）|
| **`evidence` 证据链最小数量** | ≥ 2 条 / case（指向 step_02 表的字段 + ann_id）| ≥ 3 条 / case + 跨年对照 | ≥ 5 条 / case + 同行交叉 + 监管文档交叉 |
| **`label_taxonomy` 颗粒度** | 6 类（应收激进 / 关联输送 / 商誉雷 / 现金流虚 / 大股东减持承诺违约 / 监管处罚事件链）| 12 类（+ 循环交易 / 明股实债 / 商誉减值时点选择 / 业绩对赌违约 / 银行函证瑕疵 / 关联担保超限）| 25+ 类（+ 应收账款账龄异常 / 经销商压货 / 表外资金占用 / 一致行动人隐藏 / 跨境关联 / ESG 漂绿等）|
| **样本来源多样性** | 单一（8 持仓股）| 100 标的 + 50 暴雷 Holdout 案例 | 全 A + 历史 200+ 暴雷 + 学术研究案例 |
| **Prompt 模板版本** | v1.0（每个引擎 1 个模板）| v2.0（按 case 类型分支 / Few-shot 引导）| v3.0（CoT + Self-consistency + Reflection）|
| **质量校验流程** | 架构师 100% 抽审 + LLM 自评分 | 架构师 10% 抽审 + Critic LoRA 评分 + Opus 4.7 抽 20% | Critic LoRA 评分 + 多模型投票一致性 ≥ 0.8 + 架构师 1% 抽审 |
| **LoRA 引擎目标精度（→ step_04~06）**| P=0.6 baseline | **P=0.85** | **P=0.92 + R=0.88** |
| **训练吞吐（→ step_04~06）**| 单卡 4090 / 200 ~ 500 epoch | 4×A100 / 集群训练 | 8×H100 + DPO/RLHF 二次精调 |

### §6.5.2 三档共用的蒸馏样本质量矩阵（Q1~Q9 · 升级口径）

| # | 质量维度 | 启动期 | 扩展期 | 完善期 |
|---|---|---|---|---|
| Q1 | **证据链可追溯**（每个 case 须含 `step_02 表名 + 主键`）| ≥ 90% | 100% | 100% + 自动 hash 校验 |
| Q2 | **结构化字段完整**（`label / evidence / reasoning / confidence`）| 100% | 100% | 100% + JSON Schema 强校验 |
| Q3 | **标签分布平衡**（避免类别坍塌）| 6 类各 ≥ 10 | 12 类各 ≥ 100 | 25 类各 ≥ 300 |
| Q4 | **跨年对照**（同标的多年趋势）| 可选 | ≥ 50% case 含 | ≥ 80% case 含 |
| Q5 | **跨标的对照**（同行业基线）| 可选 | ≥ 30% case 含 | ≥ 60% case 含 |
| Q6 | **难度分层**（简单 / 中等 / 难 · 用于课程学习）| 不分层 | 三档各 ≥ 30% | 五档（极简~极难）|
| Q7 | **对抗样本占比**（近似但非雷 · 防过拟合）| 0% | ≥ 10% | ≥ 20% |
| Q8 | **可解释推理链长度**（reasoning 字段 token 数）| ≥ 100 | ≥ 300（CoT） | ≥ 800（含 Reflection）|
| Q9 | **Critic 引擎评分**（"物理证伪 ≥ 财务证伪"哲学贯彻）| 手工标 | LoRA 自动 + 架构师 10% | LoRA 自动 + 多模型投票 |

### §6.5.3 跨阶段升级时**禁止跳级**的硬约束

| 升级路径 | 前置硬条件（不达则不许开工 stage_n+1）| 验证方式 |
|---|---|---|
| stage_1 → stage_2 | ①本步 §6.5.1 启动期列全部 ✅；②`_train.json` 行数达 §5.2 第一档；③D1 step_04 LoRA 在 Holdout 上 P=0.6；④架构师 100% 抽审通过 | 跑 §9 准出 + L4 实践记录证据 |
| stage_2 → stage_3 | ①扩展期 3500 case 全部完成且 Q1~Q9 矩阵 ≥ ⚠️；②三引擎 LoRA P=0.85；③Critic 引擎已就绪 | 见 stage_2 step_02 §准出 |

### §6.5.4 蒸馏质量提升的核心方法论（三档共用）

| 方法 | 启动期 | 扩展期 | 完善期 |
|---|---|---|---|
| **Prompt 策略** | Zero-shot + 简单 instruction | Few-shot + CoT + 角色扮演 | CoT + Self-consistency + Reflection + Tool use |
| **Teacher 选型** | 单一（Sonnet 主蒸）| 双模型（Sonnet + Opus 抽校）| 多模型投票（Sonnet + Opus + GPT-4o） |
| **样本筛选** | 全量入训 | Critic 自动评分 ≥ 0.6 入训 | Champion-Challenger A/B 测试 + 仅保留 ROC-AUC 改善样本 |
| **去重策略** | 简单 hash 去重 | 语义相似度（embedding cosine ≥ 0.9 去重）| 语义 + 因果结构相似度（避免标签泄漏）|
| **难度课程** | 不分层 | 简单 → 难（按 Critic 评分逆序训练）| 自适应难度（依据 LoRA 当前误差动态加难样本）|
| **数据增强** | 无 | 同义改写 + Few-shot 重组 | LLM 生成对抗样本 + 边界样本主动构造 |
| **质量监控** | 架构师全审 | CI 每日跑 Q1~Q9 矩阵 + 抽 10% 人审 | 实时 SLI + 数据治理仪表盘 + 自动回滚 |
| **训练监控** | wandb / tensorboard | + Champion-Challenger A/B 对比 | + 持续 Eval + 漂移检测 + 自动重训触发 |

### §6.5.5 对低/中模型在 stage_2/stage_3 执行时的约束

**禁止动作**（违反视为不达金标准）：
1. **禁止跳级**：未达 §6.5.3 前置条件不得开工下一阶段；
2. **禁止伪造蒸馏数据**：所有 case 必须真实调 Teacher API 生成，禁止抄历史数据集；
3. **禁止降低门槛**：本表 §6.5.1 / §6.5.2 的数字是基线门槛，**只能加不能减**；
4. **禁止跳过证据链**：Q1 证据链可追溯率 ≥ 90%（启动期）/ 100%（扩展期+），不达不入训；
5. **禁止用 Opus 4.7 跑全量蒸馏**（成本爆炸）：扩展期 + 完善期主蒸用 Sonnet，Opus 仅做抽样校验；
6. **禁止只调一次模型就接受**：扩展期起须 Critic 评分 ≥ 0.6 入训；
7. **禁止跨阶段共用 case**：stage_1 的 65 case 不计入 stage_2 的 3500（重新蒸提升质量），但保留作为 baseline 对照。

**必做动作**：
1. 每个 stage 完成时**必须**跑配套 §9 准出清单；
2. 每次新增 case **必须**同会话跑 Q1~Q9 矩阵；
3. 每次升级 Teacher 模型或 Prompt 模板**必须**做 100 case 对照测试，且新结果不得退步；
4. 修改本表门槛**必须**先提 L3 修订并按 `00_系统规则` §4.5 同步 14 节奏表与 .cursorrules。

## §7 实施规划（L3 设计 · 给后续执行模型的工作指引）

> **L3 定位**：本节是**设计规划 + 实现要点 + 验证标准**——靠谱地描述"做什么 / 如何执行"，**不嵌入完整 Prompt 模板 / Python 类 / JSON Schema 代码**。具体落地由 L4 实践记录 / 后续执行模型按本节规划自行完成。

### §7.1 实现要点（按交付物拆分 · L4 / 后续模型按此逐项落地）

| 实现要点 | 涉及代码位置 | 关键设计决策 | 验证标准 |
|---|---|---|---|
| **A 蒸馏模块骨架** | `apps/cryo_guard/distillation/{__init__.py, prompts.py, teacher_client.py, distill_runner.py, verifier.py, exporter.py}` | 5 模块单一职责：prompts 收纳模板、teacher_client 抽象 Anthropic/OpenAI/DeepSeek 三源、distill_runner 主流程、verifier 人工审核 CLI、exporter LLaMA-Factory 导出 | `python -c "from apps.cryo_guard.distillation import *"` 成功 |
| **B teacher_distill ORM 表** | `apps/cryo_guard/db/models.py`（追加 `TeacherDistill` 类） | 表设计：`engine_name + symbol + report_period + case_hash` 唯一约束防重蒸；`teacher_model / teacher_tokens_in/out / latency_ms` 用于 WandB 统计；`verified` bool + `verified_by + verified_at` 双字段；JSON 列存 `instruction/input/output` 全文 + `evidence` 结构化 | `sqlite3 data/cryo_guard.db ".schema teacher_distill"` 含所有字段 |
| **C 三引擎 Prompt 模板** | `apps/cryo_guard/distillation/prompts.py` | 三套 prompt（financial_fraud / shareholder / related_party）：①包含"6 类 / 5 类 / 4 类"显式触发说明；②强制 JSON 输出 schema（label / confidence / risk_level / category / evidence[] / reason_zh）；③few-shot 示例 ≥ 2 条；④`<thinking>` 标签隔离推理链 | 用 1 个真实 case 跑 prompt → Claude 返回 JSON 校验通过 |
| **D Teacher 多源客户端** | `apps/cryo_guard/distillation/teacher_client.py` | 抽象基类 `TeacherClient`；三实现 `AnthropicClient / OpenAIClient / DeepSeekClient`；统一接口 `distill(prompt, case) -> DistillResult`；按 ENV 自动选源（`TEACHER_PROVIDER=anthropic/openai/deepseek`）；失败 ≥ 3 次切备源 + 标 `teacher_fallback` | 同一 case 切 3 源都返回合法 JSON |
| **E 蒸馏主流程 distill_runner** | `apps/cryo_guard/distillation/distill_runner.py` | 流程：① 从 SQLite 取 case → ② Holdout 守门 → ③ 构造 prompt → ④ 调 teacher_client → ⑤ JSON 校验 → ⑥ 通过则入 `teacher_distill`，失败入 `failed_distill.jsonl` → ⑦ WandB 记录 token / latency；支持 `--engine financial_fraud --limit 100 --resume` | 跑 100 条小批 → 成功 ≥ 95 条 / 失败 ≤ 5 条 |
| **F 架构师 Verified CLI** | `apps/cryo_guard/distillation/verifier.py` | CLI: `verifier review --engine X --batch 20` 交互式审核（显示原始 case + Teacher output + evidence → 架构师按 y/n/skip 标 verified）；`verifier stats` 看进度；批量 marked `verified=TRUE` + `verified_by / verified_at` | 跑 1 batch 20 条 → DB 中 20 条 verified=TRUE |
| **G LLaMA-Factory 导出** | `apps/cryo_guard/distillation/exporter.py` | 从 `teacher_distill where verified=TRUE` 按引擎导出 jsonl；alpaca 格式 `{"instruction":..., "input":..., "output":...}`；80/10/10 随机切分（固定 seed）；落 `training/data/llama_factory/{engine}_{train,val,test}.json` | 3 引擎共 6 份 jsonl（每引擎 train+val+test）；行数 = verified 总数 |
| **H Holdout 守门集成** | `distill_runner.py` import `HoldoutGuard`；`exporter.py` 出文件后调 `holdout_guard.py --check-training-data` 自检 | 蒸馏前预过滤 + 导出后再校验，双重防污染 | `holdout_guard.py` 退出码 0 |
| **I 单测** | `tests/cryo_guard/test_distillation.py` | 覆盖：① ORM 表 CRUD；② prompt 模板渲染；③ teacher_client 多源切换（mock HTTP）；④ JSON Schema 校验；⑤ Holdout 守门拒绝；⑥ 80/10/10 切分稳定；⑦ verifier CLI 流程 | `pytest -v` ≥ 7 passed |
| **J 数据质量复核脚本** | 新建 `training/scripts/validate_distill_quality.py` | 自动按 §3.5 16 项扫 `teacher_distill` 表：覆盖各类样本数、JSON 通过率、正负比、Holdout 污染、Verified 占比；输出 16 行 ✅/⚠️ + SQL 证据；任一项不达 → 退出码非 0 | 退出码 0 |

### §7.2 Makefile 一键复现合约（L3 约定 · L4 / `diting-src/Makefile` 实现）

**设计目的**：架构师改 `data/config/my_holdings.yaml`（标的）或 `.env`（切 Teacher 源）后跑 `make cryo-step03-all` 完成"蒸馏 → 校验 → 审核占位 → 导出 → 守门 → 单测"全套。

**target 合约表**：

| target | 用途 | 入参（环境变量 · 均有默认） | 验证标准 |
|---|---|---|---|
| `make cryo-step03-prep` | ORM 表 migration + 凭证自检 | `ANTHROPIC_API_KEY / OPENAI_API_KEY / TEACHER_PROVIDER` | `teacher_distill` 表存在；凭证 echo（脱敏）|
| `make cryo-step03-distill-financial` | 蒸馏 financial_fraud 1500 条 | `TEACHER_PROVIDER / MY_HOLDINGS_YAML / DISTILL_LIMIT=1500` | 表中 `engine_name='financial_fraud'` ≥ 1500 |
| `make cryo-step03-distill-shareholder` | 蒸馏 shareholder 1000 条 | 同上 | ≥ 1000 |
| `make cryo-step03-distill-related` | 蒸馏 related_party 1000 条 | 同上 | ≥ 1000 |
| `make cryo-step03-distill` | 串联上述 3 个蒸馏 | 同上合并 | 总数 ≥ 3500 |
| `make cryo-step03-quality-check` | §3.5 16 项矩阵 + Holdout 守门 + JSON 解析率 | — | 16 行 ✅/⚠️；退出码 0 |
| `make cryo-step03-review` | 启动架构师 CLI 审核（人机交互） | `REVIEW_ENGINE / REVIEW_BATCH` | 进入交互模式 |
| `make cryo-step03-export` | LLaMA-Factory 导出 + 80/10/10 切分 | — | 6 份 jsonl 存在；行数 = Verified |
| `make cryo-step03-test` | 单测 | — | `pytest -v` ≥ 7 passed |
| `make cryo-step03-dvc` | DVC 跟踪 | — | `dvc status` 干净 |
| `make cryo-step03-all` | **端到端一键**（含上述 7 步 + 中间审核为占位） | 同上合并 | 全部退出码 0；3500 条蒸馏耗时 ≤ 6 hr（Claude 主源；含限流 retry） |
| `make cryo-step03-status` | 进度快照（蒸馏数 / verified 数 / 各类分布）| — | 打印 3 引擎数据量 + 16 行矩阵覆盖率 |
| `make cryo-step03-clean` | 清掉蒸馏数据（**不**清 Verified 与已导出 jsonl）| — | `teacher_distill` 表清空但 jsonl 保留 |

**合约要求**：①入参环境变量化；②Teacher 切源在 `teacher_client.py` 内透明（Makefile 不感知）；③可重入（蒸馏脚本检查 `case_hash` 已存在则 skip）；④配置驱动（增减标的只改 `my_holdings.yaml`）；⑤失败可观察（每个 target 中文 3 行摘要 + Token 消耗 + 限流次数）。

### §7.3 关键代码片段（中间道 · 非完整模块）

#### 7.3.1 Pydantic DistillResult schema（核心 ~15 行）

```python
class EvidenceItem(BaseModel):
    field: str
    value: Any
    unit: Optional[str] = None
    source_table: str
    source_period: str
    human_readable_reason: str

class DistillResult(BaseModel):
    label: Literal["fraud","normal","integrity_failure","related_anomaly"]
    confidence: float = Field(ge=0.0, le=1.0)
    risk_level: Literal["high","medium","low"]
    category: str        # 6 / 5 / 4 类枚举见 §3.5
    evidence: list[EvidenceItem] = Field(min_length=1)
    reason_zh: str = Field(min_length=10)
```

#### 7.3.2 Holdout 守门集成（核心 ~10 行）

```python
class HoldoutGuard:
    def __init__(self, manifest_path: str = "training/data/holdout/manifest.json"):
        with open(manifest_path) as f:
            self.blacklist = {c["symbol"] for c in json.load(f)["cases"]}

    def is_blacklisted(self, symbol: str) -> bool:
        return symbol.zfill(6) in self.blacklist

# distill_runner 调用：
if HoldoutGuard().is_blacklisted(case.symbol):
    log.info("skip holdout symbol %s", case.symbol)
    continue
```

#### 7.3.3 Teacher 多源切换决策（核心 ~12 行）

```python
async def get_teacher(provider: str = None) -> TeacherClient:
    p = provider or os.environ.get("TEACHER_PROVIDER", "anthropic")
    if p == "anthropic" and os.environ.get("ANTHROPIC_API_KEY"):
        return AnthropicClient()
    if p == "openai" and os.environ.get("OPENAI_API_KEY"):
        return OpenAIClient(model="o1-mini")
    if p == "deepseek" and os.environ.get("DEEPSEEK_API_KEY"):
        return DeepSeekClient(model="deepseek-v2.5")
    # 兜底切换尝试 3 家
    for name, env, cls in [("anthropic","ANTHROPIC_API_KEY",AnthropicClient),
                            ("openai","OPENAI_API_KEY",OpenAIClient),
                            ("deepseek","DEEPSEEK_API_KEY",DeepSeekClient)]:
        if os.environ.get(env): return cls()
    raise EnvironmentError("no teacher key available")
```

#### 7.3.4 80/10/10 切分（确定性 seed · 核心 ~10 行）

```python
def split_train_val_test(rows: list[dict], seed: int = 42) -> tuple:
    import random
    rng = random.Random(seed)
    shuffled = rows.copy()
    rng.shuffle(shuffled)
    n = len(shuffled)
    n_train = int(n * 0.8)
    n_val = int(n * 0.1)
    return (shuffled[:n_train],
            shuffled[n_train:n_train+n_val],
            shuffled[n_train+n_val:])
```

#### 7.3.5 蒸馏主流程伪代码（核心 ~15 行）

```python
async def distill_engine(engine: str, limit: int, teacher: TeacherClient):
    cases = await load_cases_from_sqlite(engine, limit)
    guard = HoldoutGuard()
    n_ok, n_fail = 0, 0
    for case in cases:
        if guard.is_blacklisted(case.symbol):
            continue
        if await case_already_distilled(case.case_hash):
            continue   # 可重入
        prompt = render_prompt(engine, case)
        try:
            resp = await teacher.agenerate(prompt)
            result = DistillResult.model_validate_json(resp.text)  # schema check
        except Exception as e:
            await save_failed(case, str(e)); n_fail += 1; continue
        await save_distill(case, resp, result); n_ok += 1
        wandb.log({"engine": engine, "ok": n_ok, "fail": n_fail,
                   "tokens_in": resp.in_tok, "tokens_out": resp.out_tok})
```

### §7.4 给后续执行模型的指引

L4 / 执行模型按以下顺序：

1. **核对前置**：step_02 已 ✅；`.env` 含 `ANTHROPIC_API_KEY`；Holdout manifest 已锁；
2. **逐项落地 A~J**：建议顺序 A→B→C→D→E→F→G→H→I→J；
3. **集成 Makefile**：按 §7.2 合约表实现 13 个 target；
4. **小批先跑**：`make cryo-step03-distill-financial DISTILL_LIMIT=100` 先跑 100 条验证 JSON 通过率 ≥ 95% 再放量；
5. **架构师 review**：跑 `make cryo-step03-review REVIEW_ENGINE=financial_fraud REVIEW_BATCH=50` 分批审，目标 1000 Verified；
6. **§9 准出 + L4 实践记录回写**：含每个引擎实际 Verified 数、Token 消耗、限流次数、备源占比；
7. **遇问题**：JSON 解析率 < 95% → 暂停蒸馏 + 优化 Prompt + 重蒸；同一问题修复重试 ≥ 2 次仍失败按 §8.4f 回收。

> **L3 责任边界**：本节给规划 + 实现要点 + 验证标准；**不**给完整 Prompt 模板 / Pydantic schema 代码；具体落地交给 L4 实践记录 / 后续执行模型。

## §8 部署节奏（本步在哪里跑）

| 阶段 | 形态 | 是否本步必须 | 说明 |
|---|---|---|---|
| **本机开发** | `python -m apps.cryo_guard.distillation.distill_runner` + `pytest` | **必须** | 蒸馏脚本 / 审核 CLI / 导出 / 单测全部本机完成 |
| **本机 docker-compose** | — | 否 | 本步无需中间件，只需访问 Anthropic/OpenAI HTTPS |
| **Dev K3s** | — | 否 | 本步不上集群；可选：把 distill_runner 包成 K8s Job 跑批量（启动期不要求）|
| **ACR + 生产 K3s** | — | 否 | 本步**不**产出镜像 |

**本步默认运行形态**：仅本机（python 进程 + SQLite + HTTPS 调 Anthropic）。

## §9 准出标准（同会话可执行清单）

> **门槛口径**：分四档：① 数据量门槛 → ② **数据质量门槛（§3.5 矩阵）** → ③ 工程交付 → ④ 一键复现。**第 ② 档不绿即未准出**。

### §9.1 数据量门槛（§5.2）
- [ ] `SELECT engine_name, COUNT(*) FROM teacher_distill GROUP BY engine_name;` 三行 ≥ 1500 / 1000 / 1000
- [ ] `SELECT engine_name, COUNT(*) FROM teacher_distill WHERE verified=TRUE GROUP BY engine_name;` 三行 ≥ 1000 / 800 / 800
- [ ] JSON 解析失败率 ≤ 5%（`wc -l < failed_distill.jsonl < 总蒸馏请求数 × 5%`）

### §9.2 数据质量门槛（§3.5 矩阵 · 启动期 16 项）
- [ ] 财务测谎 4 项（T1~T4）= ✅ 或 ⚠️ 有降级
- [ ] 大股东 4 项（T5~T8）= ✅ 或 ⚠️ 有降级
- [ ] 关联交易 4 项（T9~T12）= ✅ 或 ⚠️ 有降级
- [ ] 三引擎共用 4 项（T13~T16）= ✅ 或 ⚠️ 有降级
- [ ] **复核脚本**：`python training/scripts/validate_distill_quality.py` 退出码 0；输出 16 行均 ✅ 或 ⚠️

### §9.3 工程交付 + 一键复现
- [ ] **Makefile 合约落地**（§7.2）：13 个 target 全部已实现且通过；`make cryo-step03-all` 端到端通过；3500 条蒸馏耗时 ≤ 6 hr（含限流 retry）
- [ ] **配置驱动验证**：临时新增 1 个 active 标的，跑 `make cryo-step03-distill-financial DISTILL_LIMIT=50`，新标的对应 50 行入库（验证可重入幂等 + SoT 驱动）
- [ ] 3 引擎共 6 份 LLaMA-Factory jsonl 存在；行数 = Verified 数
- [ ] Holdout 守门：`holdout_guard.py --check-training-data training/data/llama_factory/*.json` 退出码 0
- [ ] DVC：`dvc status` 干净
- [ ] `pytest tests/cryo_guard/test_distillation.py -v` ≥ 7 passed
- [ ] WandB 报告：蒸馏 token 消耗 / 失败率 / 各引擎分布 可看
- [ ] L4 实践记录 `04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_03_Teacher蒸馏.md` 已按 §8.4g 更新"二、实际进展"为已核验准出，且**含 §3.5 矩阵填表**（16 行实际 ✅/⚠️ 状态与 SQL 证据 + Teacher 模型分布 + Token 消耗）
- [ ] commit：`feat(cryo-guard): step_03 Teacher 蒸馏 3500 + Verified 2600 + Makefile 一键复现 [Ref: 03_/01_维度一/.../step_03]`
- [ ] **同会话验证**：上述命令在当次会话执行并输出摘要（按 `00_系统规则` §7.2 第 10/11 条）

## §10 [Deploy] 段

本步**不**涉及上架（无镜像 / 无 Chart / 无 K8s workload）；运行形态详见 §8。

> 扩展期可选：把 `distill_runner` 包成 K8s Job，按需在 ECS GPU 节点上批跑（节省本机 6 hr）；启动期不强制。

## §11 依赖与被依赖

**上游**：
- `step_02`：`financial_reports / announcements / related_party_raw / related_party_graph` 已落库 + Holdout 锁库；
- 用户提供：`ANTHROPIC_API_KEY`（或 Bedrock IAM）；
- 可选：D5 维度五 step_03 完成后 `teacher_client.py` 可复用。

**下游**：
- `step_04` 财务测谎 LoRA 训练：消费 `financial_fraud_{train,val,test}.json`；
- `step_05` 大股东诚信 LoRA：消费 `shareholder_{train,val,test}.json`；
- `step_06` 关联交易 LoRA：消费 `related_party_{train,val,test}.json`。

**严禁伪造**（no-mock-policy）：Teacher API 不可用时**等待**（用户补 key），**不**用 `mock_teacher_response.json` 充数；占位 fixture 仅在 `tests/` 单测中合法。

## §12 风险与回退

| 触发条件 | 动作 |
|---|---|
| Anthropic 限流（429 / 5xx）≥ 3 次 | 切 Bedrock cross-region；仍失败切 OpenAI o1 + 标 `teacher_fallback=openai_o1` |
| JSON 解析失败率 > 10% | **暂停蒸馏** + 抓 10 条 failed 样本分析 + 优化 Prompt（加 schema 显式约束 + few-shot）+ 小批重蒸验证 ≤ 5% 后再放量 |
| 单引擎 Verified 卡在 < 800 / 1000 | 启动期可降级：用 Verified 子集训练 + L4 实践记录写明实际量 + ADR 说明对模型上限影响 |
| Token 消耗严重超预算（Claude > $200 / 引擎）| 切 DeepSeek 备源 + 标注；或在 L4 写明并提 ADR |
| Holdout 污染（守门器红灯）| 立即停止 export；查 SoT yaml 是否误入 Holdout 标的；不得放行训练 |
| 同一问题修复重试 ≥ 2 次仍失败 | 按 `00_系统规则` §8.4f 回收 |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-23 | **v3.1 长期推演内嵌**（关键重构 · 与 `00_系统规则` §4.5 同步）：用户要求「**长期推演**写进步骤，让以后扩量 65→3500→10000+ 时不偏离方向」。变更：①**新增 §6.5 长期推演**（启动期 → 扩展期 → 完善期 三档蒸馏路径总表 14 行：含成本估算 / Teacher 选型 / verified 标注率 / 证据链最小数量 / label 颗粒度 / Prompt 版本 / LoRA 精度目标）；②**新增 §6.5.2 蒸馏样本质量矩阵 Q1~Q9**（证据链可追溯 / 标签分布平衡 / 难度分层 / 对抗样本 / Critic 评分等）；③§6.5.3 跨阶段升级硬约束；④§6.5.4 蒸馏质量提升方法论（Prompt 策略 / Teacher 选型 / 样本筛选 / 难度课程 / 数据增强）；⑤§6.5.5 对低/中模型的 7 条禁止 + 4 条必做约束；⑥§6 链接补 stage_2 step_02 文档（Phase 2 新建）。配套：金标准文档 [`金标准_8只持仓股数据验收清单.md`](../../../../../04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/金标准_8只持仓股数据验收清单.md) §7 stage_2/3 衔接 |
| 2026-05-21 | **v3 中间道细化**：保留 v2 三段式 §7；新增 §3.1 teacher_distill ORM 表 schema 简表（含 case_hash UNIQUE / teacher_fallback / verified_by / ix_engine_verified）、§3.2 output JSON alpaca 示例（financial_fraud + 6 类 features + evidence[]）；§7.3 新增 5 个关键片段（DistillResult Pydantic schema / HoldoutGuard 集成 / Teacher 多源切换决策 / 80/10/10 确定性切分 / 蒸馏主流程伪代码）；279→~450 行 |
| 2026-05-20 | **v2 按新 L3 启动期 step 模板（v1.2）重写**（关键重构，与 `00_系统规则` §4.5 同步）：①删除全部嵌入的 Python 类 / Prompt 模板 / Pydantic schema 完整代码（原文 1108 行）；②新增 §3.5 数据质量验收矩阵（16 项 · 仅启动期负责）按下游 step_04/05/06 三引擎反推质量需求（T1~T16）；③§7 改为"实施规划"三段式：§7.1 实现要点 10 项 + §7.2 Makefile 合约 13 个 target + §7.3 给后续执行模型指引；④§6 收敛为一行触发；⑤§9 准出加 Makefile 合约落地 + 配置驱动可重入验证；⑥强调 Teacher 多源选型 + 备源切换标注 + Holdout 双重守门。从 1108 行 → ~280 行 |
| 2026-05-16 | 初版（含完整 Python 代码块 + Prompt 模板），1108 行 |
