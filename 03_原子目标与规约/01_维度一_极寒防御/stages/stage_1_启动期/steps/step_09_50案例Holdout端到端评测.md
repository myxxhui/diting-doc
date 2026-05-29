# Step 09 · 50 案例 Holdout 端到端评测 + 100 公司白名单不被误伤

## §1 一句话定位与本步交付物

**一句话**：通过 `POST /api/decision-gate/check` 跑通**全链路**（vLLM + 3 引擎 + decision_gate + 审计 + stream），对 50 案例 Holdout + 100 公司白名单做端到端评测，硬性达标 **漏判 FN = 0、综合 F1 ≥ 0.78、白名单误伤 reject ≤ 5**。

**交付物**（勾选 = 完成）：
- [ ] **A**（100 公司白名单）：`training/data/whitelist_100.json` 含 symbol/name/industry，沪深 300 蓝筹 + 中证 500 头部 + 至少 5 个行业代表
- [ ] **B**（端到端评测脚本）：`training/scripts/evaluate_holdout_e2e.py` 调 `/api/decision-gate/check`；并发 ≤ 4；单案例超时 60 s；输出 `output/eval_reports/stage_1_holdout_e2e.{json,md}`
- [ ] **C**（综合指标硬达标）：`overall.recall ≥ 0.90 / precision ≥ 0.70 / f1 ≥ 0.78 / false_negative_count = 0`（50 案例无任何 reject 被漏判）
- [ ] **D**（单引擎拆分指标）：financial_fraud Recall ≥ 0.95 / shareholder ≥ 0.90 / related_party ≥ 0.85
- [ ] **E**（白名单守门）：100 白名单 `误伤(reject) ≤ 5`、`误伤(degrade) ≤ 20`（启动期容忍 degrade 略宽）
- [ ] **F**（错判归因报告）：`stage_1_holdout_e2e.md` 含每个错判案例的归因（哪个 engine 判错 + evidence + 期望 vs 实际）
- [ ] **G**（审计 + Stream 核对）：50 + 100 ≥ 150 audit_log 新增；哈希链 validate 通过；`XLEN events:cryo_guard:reject` 行数 = 本次 reject 决策数
- [ ] **H**（调参循环工具）：本步**不**重训 LoRA；提供 `training/scripts/replay_failed_cases.py` 抽取错判案例 → 标"需难样本扩增" → 回 step_03/04/05/06 补
- [ ] **I**（单测）：`pytest tests/cryo_guard/test_holdout_e2e.py -v` ≥ 6 passed
- [ ] **J**（Makefile 一键复现）：`make cryo-step09-all` 端到端通过

> **本步是 step_10 阶段验收的硬阻塞**：不达本步指标，整个 D1 启动期不算交付。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2 哲学**：[01_维度一_极寒防御 · 04_防御实践策略规划](../../../../../02_战略维度/01_维度一_极寒防御/04_防御实践策略规划.md)
> - **本阶段总览**：[stage_1_启动期/README](../README.md)
> - **L3 验收**：[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md) §二 模型验收、§7.1 P0（漏判 = 0）
> - **L3 训练**：[../04_模型训练与部署.md](../04_模型训练与部署.md) §五 Holdout 评测（阈值表）
> - **DNA 键**：`_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml` → `quantitative_goals`（Recall / Precision / 漏判 = 0）
> - **L4 实践记录**：[实践记录_step_09_50案例Holdout端到端评测.md](../../../../../04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_09_50案例Holdout端到端评测.md)
> - **上游 step**：← step_07（3 路由 + vLLM）、step_08（decision_gate + audit + stream）；← step_02（H001~H050 Holdout 锁库）
> - **下游 step**：→ step_10（阶段验收复用本步报告）；错判反馈 → step_03/04/05/06（难样本扩增）

## §3 数据采集对象 / 落库映射

**本步不采集外部数据**——以 50 案例 Holdout + 100 白名单为输入，**生成**评测报告 + 错判归因 + 难样本清单。

| 数据流向 | 来源 / 落库 | 用途 |
|---|---|---|
| H001~H050 Holdout | step_02 锁库 `training/data/holdout/` | 评测金标（fraud / integrity_failure / related_party_risk）|
| 100 公司白名单 | 本步**新建** `training/data/whitelist_100.json` | 误伤守门金标（正常公司）|
| decision_gate API | step_08 `/api/decision-gate/check` | 黑盒调用 |
| audit_log | step_08 SQLite | 评测后核对行数 + 哈希链 |
| Redis Stream | step_08 `events:cryo_guard:{reject,degrade,pass}` | 核对计数与 reject 数一致 |
| 评测报告 | `output/eval_reports/stage_1_holdout_e2e.json` + `.md` | step_10 引用 |
| 错判清单 | `output/eval_reports/failed_cases.json` | 回灌 step_03/04/05/06 |

## §3.5 数据质量验收矩阵（按 step_10 阶段验收需求反推 · 仅启动期负责）

> **本步范围**：白名单数据 + 评测脚本 + 综合指标 + 单引擎拆分 + 审计 / Stream 核对 + 错判归因六个环节。每行 ✅ 或 ⚠️。**不**列扩展期内容（如夜间回归 / CI 自动跑）。

### §3.5.1 100 公司白名单质量

| # | 维度 | 必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| W1 | **100 家公司数量** | `whitelist_100.json` 含 100 条 | ✅ 本步交付 | < 100 不准出 |
| W2 | **沪深 300 蓝筹覆盖** | 沪深 300 ≥ 60 家 | ✅ 选取策略明确 | 行业过度集中 → 强制重选 |
| W3 | **5 个行业代表** | 至少 5 个 GICS / 申万一级行业，每行业 ≥ 10 家 | ✅ | < 5 行业不准出 |
| W4 | **不与 Holdout 重叠** | 100 家 symbol 与 H001~H050 中的 symbol 0 重叠 | ✅ Holdout 守门器校验 | 重叠 → 必须替换 |
| W5 | **数据可获取** | 100 家在 step_02 SQLite 中有完整 financial_reports / announcements 数据 | ⚠️ 启动期可能部分公司数据不全；缺数据的标"data_incomplete" 不入误伤分母 | 缺数据的公司单列报告，不算入误伤率 |

### §3.5.2 评测脚本质量

| # | 维度 | 必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| E1 | **端到端调用** | 经 `/api/decision-gate/check` 而非直接调 engine（即真过 vLLM + 3 engine + 聚合 + 审计 + stream）| ✅ 黑盒验证 | 单 case 失败抛异常允许（标 `case_error=engine_failure`），不算 skip |
| E2 | **并发与超时** | concurrency=4，单 case 超时 60 s；总耗时 50+100 案例 ≤ 60 min | ⚠️ 4090 单卡；超时频发查 step_07 P95 | 降并发 = 2 |
| E3 | **请求 ID 唯一** | 每 case `request_id = f"step09:{symbol}:{ts}"`，保证 audit_log 幂等 | ✅ | — |
| E4 | **错判归因记录** | 每错判 case 落 `failed_cases.json`：`symbol / expected / actual / final_decision / engine_scores / evidence / blame_engine` | ✅ | — |

### §3.5.3 综合指标质量

| # | 维度 | 准出门槛 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| M1 | **`false_negative_count = 0`** | 50 Holdout 案例**全部** reject 或 degrade（不允许 pass）| ⚠️ 实测；任何 1 个 FN 即不达标 | 进入调参循环 ≤ 3 轮（按 §7.3） |
| M2 | **综合 Recall ≥ 0.90** | TP / (TP + FN) | ⚠️ FN=0 自动满足；50/50 | — |
| M3 | **综合 Precision ≥ 0.70** | TP / (TP + FP)；FP 来自 100 白名单被 reject 的数量 | ⚠️ FP ≤ 21 时 P ≥ 0.70 | 调阈值（升 reject_threshold）或回 LoRA 加 normal 样本 |
| M4 | **综合 F1 ≥ 0.78** | 调和均值 | ⚠️ 派生 | 同 M3 |

### §3.5.4 单引擎拆分指标质量

| # | 引擎 | 准出门槛 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| P1 | **financial_fraud** | Recall ≥ 0.95（H001~H030 30 案例）| ⚠️ step_04 已验；本步复核 | 不达回 step_04 调参 |
| P2 | **shareholder_integrity** | Recall ≥ 0.90（H031~H040 10 案例）| ⚠️ step_05 已验；本步复核 | 不达回 step_05 |
| P3 | **related_party** | Recall ≥ 0.85（H041~H050 10 案例）| ⚠️ step_06 已验；本步复核 | 不达回 step_06 |

### §3.5.5 白名单守门质量

| # | 维度 | 准出门槛 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| WL1 | **误伤 reject ≤ 5** | 100 家中被 reject 的 ≤ 5 | ⚠️ 实测；不达进调参 | 调 degrade/reject 阈值 |
| WL2 | **误伤 degrade ≤ 20** | 启动期容忍 ≤ 20；扩展期收紧到 ≤ 10 | ⚠️ 实测 | 同 WL1 |
| WL3 | **5 误伤逐案归因** | 每误伤 reject 案例必须报告：哪个 engine + evidence 是真还是假 | ✅ 报告生成器实现 | — |

### §3.5.6 审计 / Stream 核对质量

| # | 维度 | 准出门槛 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| AL1 | **audit_log 新增 ≥ 150 行** | 50 + 100 = 150 行；重跑同 request_id 不重复 | ✅ step_08 已实现幂等 | — |
| AL2 | **哈希链 validate 通过** | `validate_chain.py` 退出码 0 | ✅ | 链断 → 紧急排查 |
| AL3 | **Stream 计数一致** | `XLEN events:cryo_guard:reject` = 本次 reject 决策数；同理 degrade / pass | ✅ 兜底队列也算 | Redis 不可用走兜底；计数 = 实际 reject 数 |

> 共 **20 项启动期质量要求**（W1~W5 / E1~E4 / M1~M4 / P1~P3 / WL1~WL3 / AL1~AL3）。矩阵中**无 ❌**。

### §3.5.7 质量门槛（合并到 §9.2）

矩阵每行须满足之一：
- **✅ 覆盖**：本步已实现且实测通过；
- **⚠️ 启动期降级**：明确路径（如调阈值 / 调参循环 / 回单引擎 step 补）+ 在该降级下 step_10 仍能验收。

**禁止**：①修改 audit_log 让 FN=0；②人工降阈值让 WL1 通过；③白名单选样偏向不会误伤的"低风险"行业绕过守门；④错判案例不归因仅给数。

## §4 真实数据源与凭证清单

### §4.1 资源

| 资源 | 来源 | 备注 |
|---|---|---|
| H001~H050 Holdout | step_02 锁库 | 50 案例 |
| decision_gate API | step_07/08 已部署 | 黑盒调用 |
| Redis Stream | step_08 已起 | 核对计数 |
| audit_log 表 | step_08 已建 | 核对行数 + 哈希链 |
| 100 白名单选取规则 | 沪深 300 / 中证 500 公开成分股 + akshare | 本步整理 |

### §4.2 用户须提供的凭证

| 凭证 | 用途 | 何时需要 | 写在哪里 |
|---|---|---|---|
| `CRYO_GUARD_BASE_URL`（默认 `http://cryo-guard-svc:8081`）| 评测脚本调 API | 评测前 | `.env` |
| `REDIS_URL` | Stream 核对 | 同 | `.env` |

> **本步无新增模型 / 数据凭证**。

## §5 启动期目标

### §5.1 评测设计

| 项 | 取值 | 理由 |
|---|---|---|
| Holdout 规模 | 50 案例（H001~H050） | step_02 锁库 |
| 白名单规模 | 100 家 | 误伤守门 |
| 并发度 | 4 | 4090 单卡承载 |
| 单 case 超时 | 60 s | decision_gate P95 + 缓冲 |
| 总耗时上限 | 60 min | 150 case × 平均 16 s × 1/4 并发 |
| 综合指标计算口径 | binary（正样本 = reject + degrade；负样本 = pass）| 用户视角"是否拦截" |
| FN 定义 | Holdout 案例 final_decision = pass（漏判） | 严格 |
| FP 定义 | 白名单 final_decision = reject（误伤） | 严格 |

### §5.2 性能 / 正确性门槛

| 指标 | 启动期门槛 | 说明 |
|---|---|---|
| FN（漏判） | **= 0** | 硬要求；不能用调阈值规避 |
| 综合 F1 | ≥ 0.78 | 派生 |
| FP（误伤 reject） | ≤ 5 | 100 家中 |
| 单引擎 Recall | F:0.95 / S:0.90 / R:0.85 | 复核 |
| 总耗时 | ≤ 60 min | 并发 4 |

### §5.3 可接受退化

- 评测中单 case engine_failure → 标 `case_error` 不算入 FN（不漏判但需归因）；
- 白名单中数据不全公司 → 单列报告，不入误伤分母；
- F1 不达 0.78 → 调参循环 ≤ 3 轮（按 §7.3）；3 轮不达进入 step_10 ADR 流程；
- 单引擎 Recall 不达 → 回 step_04/05/06 调参重训。

## §6 下一步（一行触发条件）

- **触发条件**：本步 §3.5 矩阵全 ✅/⚠️ + FN = 0 + F1 ≥ 0.78 + WL1 ≤ 5 → step_10 阶段验收可开工。
- **下一阶段方向**：扩展期接夜间回归 CI + 100 → 1000 白名单扩量 + 历史回测窗口；详见 `stages/stage_2_扩展期/`。

## §7 实施规划（L3 设计 · 给后续执行模型的工作指引）

> **L3 定位**：本节是**设计规划 + 实现要点 + 验证标准**——**不嵌入完整 Python 评测脚本 / 100 家公司清单字面量**。具体落地由 L4 实践记录 / 后续执行模型按本节规划自行完成。

### §7.1 实现要点（按交付物拆分）

| 实现要点 | 涉及代码位置 | 关键设计决策 | 验证标准 |
|---|---|---|---|
| **A 100 白名单选取脚本** | `training/scripts/build_whitelist_100.py` + `training/data/whitelist_100.json` | akshare 拉沪深 300 / 中证 500 → 按 industry 抽取 → 与 Holdout 排重 → 落 JSON；交付后人工 review | `whitelist_100.json` 100 行 + 5 行业 + 0 重叠 |
| **B 端到端评测脚本** | `training/scripts/evaluate_holdout_e2e.py` | httpx.AsyncClient 并发；50 + 100 = 150 case 提交；每 case `request_id = f"step09:{symbol}:{ts}"`；超时 60 s；失败标 `case_error` | 跑通后产出 stage_1_holdout_e2e.json |
| **C 指标计算器** | `training/scripts/compute_metrics.py` | 输入：每 case 的 `(expected, final_decision, engine_scores)`；输出：综合 + 单引擎 + 白名单分位 + 错判归因；JSON + Markdown 两份 | 单测 fixture 数据计算正确 |
| **D 错判归因器** | `compute_metrics.py` 内 `blame_engine_for_fn / blame_engine_for_fp` | FN：找哪个 engine 最低 confidence；FP：找哪个 engine 最高 confidence；输出 `blame_engine` + 该 engine 的 evidence | 每错判案例 md 报告 1 段 |
| **E 难样本回灌脚本** | `training/scripts/replay_failed_cases.py` | 从 `failed_cases.json` 抽取 + 标注 `target_engine + suggested_action: add_hard_sample / lower_threshold / retrain` → 写 `training/data/hard_samples_for_step03_replay.json` 供回 step_03 补 | 本步**不**重训，仅整理 |
| **F 审计核对脚本** | `training/scripts/verify_audit_post_eval.py` | 评测后跑：`COUNT(audit_log) ≥ pre + 150`；`validate_chain.py` 退出码 0；`XLEN events:cryo_guard:reject` = 实际 reject 数 | 退出码 0 |
| **G 调参循环工具** | `training/scripts/tune_thresholds.py` | grid search reject_threshold ∈ {0.70, 0.75, 0.80}、degrade ∈ {0.45, 0.50, 0.55}；输出每组合的 FN / FP / F1；推荐最优组合 | 3×3 = 9 组合表格 |
| **H 单测** | `tests/cryo_guard/test_holdout_e2e.py` | 覆盖：①白名单 schema 校验；②指标计算 fixture；③错判归因逻辑；④审计核对；⑤调参循环工具；⑥mock decision_gate 跑 5 case e2e | `pytest -v` ≥ 6 passed |

### §7.2 Makefile 一键复现合约（L3 约定 · L4 实现）

**设计目的**：step_07/08 跑通后跑 `make cryo-step09-all` 完成"白名单构建 → 端到端评测 → 指标计算 → 审计核对 → 单测"全套。失败时跑 `make cryo-step09-tune` 进调参循环。

**target 合约表**：

| target | 用途 | 入参（环境变量 · 均有默认） | 验证标准 |
|---|---|---|---|
| `make cryo-step09-prep` | 调用 build_whitelist_100 + holdout 完整性自检 | `HOLDOUT_DIR / MY_HOLDINGS_YAML` | `whitelist_100.json` 100 行 |
| `make cryo-step09-eval` | 跑端到端评测 150 case | `CRYO_GUARD_BASE_URL / CONCURRENCY=4 / TIMEOUT=60` | `stage_1_holdout_e2e.json` 存在 |
| `make cryo-step09-metrics` | 计算指标 + 错判归因 | — | F1 ≥ 0.78 + FN = 0 + FP ≤ 5（不达退出码 1） |
| `make cryo-step09-audit-check` | 审计 + Stream 核对 | `REDIS_URL` | audit +150 + 哈希链 OK + stream 计数一致 |
| `make cryo-step09-test` | 单测 | — | `pytest -v` ≥ 6 passed |
| `make cryo-step09-all` | **端到端一键**（含上述 5 步） | 同上合并 | 全部退出码 0；端到端 ≤ 60 min |
| `make cryo-step09-tune` | 调参循环：阈值 grid search 推荐 + 输出建议 | — | 输出 9 组合表 + 推荐组合 |
| `make cryo-step09-replay-failed` | 整理错判 → 写难样本清单回灌 step_03 | — | `hard_samples_for_step03_replay.json` 存在 |
| `make cryo-step09-status` | 进度快照（只读） | — | 最近一次评测指标 + audit_log 行数 |
| `make cryo-step09-clean` | 清评测产物（不清白名单 / Holdout） | — | `output/eval_reports/stage_1_*` 清空 |

**合约要求**：
1. **入参环境变量化**；不同评测 base_url 仅切 env；
2. **target 是薄包装**；指标计算与 e2e 分离便于复用；
3. **可重入幂等**：同 request_id 命名规则保证 audit_log 不重复；评测可中断重跑接续；
4. **失败显式**：F1 不达 / FN > 0 / WL1 > 5 → make 退出码 1 + 中文 5 行摘要指明具体不达项；
5. **调参循环边界**：`tune` target 仅输出**建议**不自动改 yaml；改阈值由架构师手动 + ADR。

### §7.3 给后续执行模型的指引（含调参循环 ≤ 3 轮）

L4 / 执行模型按以下顺序：

1. **核对前置**：step_07 三路由 ✅；step_08 decision_gate ✅；step_02 H001~H050 锁库；
2. **逐项落地 A~H**：建议顺序 A→B→C→D→F→H→G→E；
3. **集成 Makefile**：按 §7.2 实现 10 个 target；
4. **首轮全跑**：`make cryo-step09-all` → 取 metrics 报告；
5. **不达进调参循环**（≤ 3 轮，每轮 ADR）：
   - **第 1 轮**：`make cryo-step09-tune` 推荐阈值组合 → 改 `configs/decision_gate.yaml` → 重跑 `make cryo-step09-eval` + metrics；
   - **第 2 轮**：错判归因找 blame_engine → 跑 `replay-failed` 输出难样本 → 回到 step_03 补蒸 50~100 难样本 → step_04/05/06 增量训练（仅 + 5 epoch finetune，不全 retrain） → 重跑 eval；
   - **第 3 轮**：仍不达 → ADR 说明 + 申请启动期降级（Recall ≥ 0.85 + FN = 0 仍保留）；
6. **§9 准出 + L4 回写**：每轮 ADR + 最终指标 + 错判清单 + 难样本回灌情况；
7. **遇问题**：同问题 ≥ 2 次失败 § 8.4f 回收。

> **L3 责任边界**：本节给规划 + 实现要点 + 验证标准；**不**给完整 Python 评测脚本 / 100 家清单字面量；具体落地交给 L4 实践记录 / 后续执行模型。
> **特别强调**：FN = 0 是**硬约束**，不允许通过任何方式（改阈值 / 改 audit_log / 改 Holdout）规避；只能通过提高单引擎 Recall 实现。

## §8 部署节奏（本步在哪里跑）

| 阶段 | 形态 | 是否本步必须 | 说明 |
|---|---|---|---|
| **本机开发** | `python -m training.scripts.evaluate_holdout_e2e` + `pytest` | **必须** | 评测脚本 + 指标 + 单测 |
| **本机 docker-compose** | — | 否 | decision_gate / vLLM 已在 step_07/08 Dev K3s |
| **Dev K3s** | 评测脚本远程调 `cryo-guard-svc:8081` | **必须** | 真实链路验证 |
| **ACR + 生产 K3s** | 扩展期跑夜间回归 CI | 否 | 启动期手工触发 |

**本步默认运行形态**：本机评测脚本远程调 Dev K3s decision_gate。

## §9 准出标准（同会话可执行清单 · 质量优于数量）

### §9.1 报告与门槛
- [ ] `output/eval_reports/stage_1_holdout_e2e.json` 存在且 `overall.false_negative_count = 0 + f1 ≥ 0.78`
- [ ] `output/eval_reports/stage_1_holdout_e2e.md` 含每错判案例归因
- [ ] `output/eval_reports/failed_cases.json` 含 blame_engine + suggested_action

### §9.2 数据质量门槛（§3.5 矩阵 20 项）
- [ ] **白名单 5 项（W1~W5）**：100 家 + 5 行业 + 0 重叠 + 数据完整
- [ ] **评测脚本 4 项（E1~E4）**：端到端调 + 并发超时 + request_id 唯一 + 错判归因
- [ ] **综合 4 项（M1~M4）**：FN = 0 + Recall/Precision/F1 全过
- [ ] **单引擎 3 项（P1~P3）**：F:0.95 / S:0.90 / R:0.85
- [ ] **白名单守门 3 项（WL1~WL3）**：FP ≤ 5 + degrade ≤ 20 + 5 误伤归因
- [ ] **审计 / Stream 3 项（AL1~AL3）**：≥ 150 行 + 哈希链 OK + Stream 计数一致

### §9.3 工程交付
- [ ] `pytest tests/cryo_guard/test_holdout_e2e.py -v` ≥ 6 passed
- [ ] `training/scripts/` 含本步 7 个脚本（build_whitelist_100 / evaluate_holdout_e2e / compute_metrics / replay_failed_cases / verify_audit_post_eval / tune_thresholds + __init__）

### §9.4 一键复现
- [ ] **Makefile 合约**（§7.2）：10 个 target 已实现且通过；`make cryo-step09-all` 端到端 ≤ 60 min
- [ ] **可重入验证**：连跑两次 `make cryo-step09-all`，第二次 audit_log 不重复（同 request_id 命名规则保证）
- [ ] **配置驱动**：增 active 标的不影响本步（白名单与 active 解耦）；改阈值 yaml 即可重跑
- [ ] L4 实践记录 `04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_09_50案例Holdout端到端评测.md` 已按 §8.4g 更新"二、实际进展"（含综合指标 + 单引擎指标 + WL1~WL3 + 调参轮数 + 难样本回灌情况 + commit hash）
- [ ] commit：`feat(cryo-guard): step_09 50 案例 Holdout 端到端 + 100 白名单守门 + Makefile [Ref: 03_/01_维度一/.../step_09]`
- [ ] **同会话验证**：上述命令在当次会话执行并输出摘要

## §10 [Deploy] 段

本步**不**产出镜像 / Chart / K8s workload；评测脚本本机跑 + 远程调 Dev K3s decision_gate。

> 扩展期可选：把 `evaluate_holdout_e2e.py` 包成 K8s CronJob 跑夜间回归 + Slack/钉钉报告；启动期不强制。
> deploy-engine 自检约定与前置 step 一致。

## §11 依赖与被依赖

**上游**：
- `step_07`：3 engine 路由可调；
- `step_08`：decision_gate + audit + stream 可用；
- `step_02`：H001~H050 锁库；
- 用户提供：`CRYO_GUARD_BASE_URL`、`REDIS_URL`、akshare 可用。

**下游**：
- `step_10` 阶段验收：复用本步报告 + 难样本清单；
- `step_03/04/05/06` 回灌：错判案例反馈难样本补蒸 / 增量训练。

**严禁伪造**（no-mock-policy）：①评测必须端到端经 decision_gate API（不允许直接调 engine.run()）；②不允许人工删除 failed_cases.json 中的难案例；③不允许把 Holdout 案例改成 fraud=False 让 FN=0。

## §12 风险与回退

| 触发条件 | 动作 |
|---|---|
| FN > 0（任一 Holdout 漏判）| **不准出**；进调参循环（≤ 3 轮）按 §7.3 流程；改阈值 / 加难样本 / 增量训 |
| F1 < 0.78（FN=0 但 FP 过多）| 调参循环：升 reject_threshold 或回 step_04/05/06 加 normal 样本 |
| WL1 > 5（误伤 reject）| 同上 + 检查白名单数据完整性（W5 数据不完整可能误判）|
| 单引擎 Recall 不达 | 回该 step（04/05/06）调参 + 重训 |
| audit_log 行数 < 150 | 排查幂等中间件是否过激 cache + 部分 case 被去重 |
| Stream 计数 ≠ reject 数 | 查兜底队列 `failed_stream_publish` 是否积压 |
| 评测耗时 > 60 min | 降并发 = 2 + 排查 step_07 P95 退化 |
| 同问题修复重试 ≥ 2 次仍失败 | § 8.4f 回收 |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按新 L3 启动期 step 模板（v1.2）重写**（关键重构，与 `00_系统规则` §4.5 同步）：①删除全部嵌入完整 Python 评测脚本 / 100 家公司清单字面量 / 多份附录代码（原文 917 行 → 现 ~310 行）；②新增 §3.5 数据质量验收矩阵 20 项（W1~W5 白名单 + E1~E4 评测脚本 + M1~M4 综合 + P1~P3 单引擎 + WL1~WL3 白名单守门 + AL1~AL3 审计 Stream）；③§7 改为"实施规划"三段式（§7.1 实现要点 8 项 + §7.2 Makefile 合约 10 个 target + §7.3 给后续执行模型指引 含调参循环 ≤ 3 轮）；④把 4 份附录（A 报告 schema / B 回归曲线 / C 夜间 CI / D 错判归因 / E 白名单选取）合并到对应实现要点 / 风险与回退章节；⑤§9 准出加 Makefile 合约 + audit_log 幂等可重入；⑥明确 L3 责任边界 + FN=0 硬约束 |
| 2026-05-16 | 初版（含完整 Python 评测脚本 + 4 份附录 + 100 家清单），917 行 |
