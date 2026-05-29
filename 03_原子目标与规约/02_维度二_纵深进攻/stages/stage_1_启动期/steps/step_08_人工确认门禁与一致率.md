# Step 08 · 人工确认门禁与一致率分析

## §1 一句话定位与本步交付物

**一句话**：实现 **HumanGate**——架构师对 `status=proposed` 的 thesis 执行 confirm/reject/defer；**唯一**允许将 `thesis_cards.status` 改为 `confirmed` 的代码路径；**ConsistencyAnalyzer** 对齐 AI `decision` 与人工决策，启动期一致率 ≥80%；**仅** confirmed 的 thesis 经 `publisher` 写入 `events:thrust:thesis_proposed` 供 D0 消费。

**交付物**（勾选 = 完成）：
- [ ] **A**（`HumanGate`）：`confirm(thesis_id, reviewer, decision, comment)` + `_promote_to_confirmed()` 为**唯一** status→confirmed 入口
- [ ] **B**（`human_confirmations` 审计）：每操作一行；含 `consistency_label`（ai vs human 对齐标签）
- [ ] **C**（`ConsistencyAnalyzer`）：`weekly_report` / `per_playbook_report`；阈值 DNA `quantitative_goals` ≥80%
- [ ] **D**（API）：`POST /api/thesis/{id}/confirm`；`GET /api/consistency/report?weeks=4`
- [ ] **E**（`publisher.py`）：confirmed → `XADD events:thrust:thesis_proposed`；payload 与 D0 `ThesisProposedPayload` 字段级一致
- [ ] **F**（防 bypass）：`assert_no_bypass()` + 单测禁止直接 UPDATE status=confirmed
- [ ] **G**（Makefile）：`make deep-step08-all`

> **永久规则**：AI **不可**自动建仓；高 confidence **不得**跳过本步。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2/L3**：[../01_实践目标与策略.md](../01_实践目标与策略.md) §3.1 决策机制、[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md) §4.1
> - **DNA**：`quantitative_goals[2]` 一致率 ≥80%、`permanent_rule`、`decision_mechanism`
> - **共享**：[13_六维度启动期集成与时序](../../../../_共享规约/13_六维度启动期集成与时序.md) §三场景 A
> - **L4**：[实践记录_step_08_人工确认门禁与一致率.md](../../../../../04_阶段规划与实践/02_维度二_纵深进攻/stage_1_启动期/实践记录_step_08_人工确认门禁与一致率.md)
> - **D0**：[step_04_推荐池模块](../../../../00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_04_推荐池模块.md)
> - **上游**：← step_07；**下游**：→ step_09/10、D0 推荐池

## §3 数据采集对象 / 落库映射

| 流向 | 表/流 |
|---|---|
| 人工决策 | `human_confirmations` |
| 状态流转 | `thesis_cards.status`（proposed→confirmed/rejected/deferred）|
| 推送 | Redis `events:thrust:thesis_proposed` |
| 一致率统计 | 读 `confidence_logs.decision` + `human_confirmations.decision` |

## §3.5 数据质量验收矩阵（门禁与一致率 · 仅启动期）

### §3.5.1 永久规则强制

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| R1 | **唯一 confirmed 入口** | 仅 `HumanGate._promote_to_confirmed` 可写 confirmed | ✅ grep + 单测 | bypass→fail |
| R2 | **未 confirm 不推送** | publisher 前校验 status=confirmed | ✅ | 违规 XADD→告警 |
| R3 | **自动建仓防护** | 无 API/定时任务因 confidence 直接 confirmed | ✅ `assert_no_auto_confirm` | — |
| R4 | **reject/defer 不推送** | reject/defer 行不写 thrust stream | ✅ | — |

### §3.5.2 一致率质量

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| C1 | **标签口径一致** | AI `propose/watch/discard` 与 human `confirm/reject/defer` 映射表固定 | ✅ yaml | 漂移则修映射 |
| C2 | **consistency_label** | 每条 human 行有 label：agree/disagree/partial | ✅ | — |
| C3 | **周一致率** | `weekly_report` 最近 4 周；overall ≥80% | ⚠️ 需≥10 条配对样本 | <10 条标 insufficient |
| C4 | **分剧本一致率** | `per_playbook_report` 按 PB1 拆分 | ✅ | — |
| C5 | **与 step_07 同档** | 一致率计算用 ConfidenceLog.decision 非手写 | ✅ | — |

### §3.5.3 D0 推送契约

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| P1 | **stream 名** | `events:thrust:thesis_proposed` = 13_ §四 | ✅ | — |
| P2 | **payload 11+2** | symbol/thesis_id/5必填/pass_event_id/confidence/decision_at 等 | ⚠️ schema_check | diff=0 才准出 |
| P3 | **at-least-once** | XADD 失败落本地重试表 | ⚠️ 最小 worker | Redis 不可用积压 |

### §3.5.4 工程

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **样本量** | ≥5 proposed 可供 confirm 演练 | ✅ 种子或 step_05 产出 | — |
| E2 | **单测** | ≥10 passed human_gate + publisher | ✅ | — |

> 共 **14 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| `REDIS_URL` | publisher XADD |
| 架构师 JWT/API key（启动期可固定 dev token）| POST confirm |
| step_07 ConfidenceLog 已有数据 | 一致率 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 一致率 overall | ≥80%（DNA）|
| bypass 违例 | 0 |
| confirmed 推送成功率 | ≥99%（Redis 可达时）|

## §6 下一步

本步 ✅ → step_09 PassEvent 消费 + 全链路 e2e。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A HumanGate** | `engines/human_gate.py` | confirm/reject/defer；`_promote_to_confirmed` 唯一 | 单测 bypass 失败 |
| **B ConsistencyAnalyzer** | `engines/consistency_analyzer.py` | 映射表 yaml；周/剧本报告 | 手算 10 条 |
| **C publisher** | `events/publisher.py` | 仅 confirmed；Pydantic payload | schema_check diff=0 |
| **D API routes** | `api/routes/thesis.py` | POST confirm + GET consistency | 200 |
| **E failed_publish 兜底** | `db/models.py` | 同 D1 模式 | mock redis fail |
| **F assert_no_bypass** | `engines/human_gate.py` | 扫描 ORM 直改路径 | pytest |
| **G 种子数据** | `scripts/seed_human_review_batch.py` | 可选 10 条 proposed | 一致率可算 |
| **H 单测** | `test_human_gate.py` | ≥10 | — |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `deep-step08-prep` | Redis + ≥5 proposed |
| `deep-step08-confirm-batch` | 批量 confirm 5 条（dev reviewer）|
| `deep-step08-consistency` | GET report overall≥80% 或 insufficient 说明 |
| `deep-step08-stream-check` | XLEN thrust stream ≥1 |
| `deep-step08-bypass-check` | assert_no_bypass 退出码 0 |
| `deep-step08-test` | pytest ≥10 |
| `deep-step08-all` | 端到端 |
| `deep-step08-status` | 最近 confirm 数 + 一致率快照 |

### §7.3 指引

先 Gate→Analyzer→publisher→API；**禁止**在 generate 路径写 confirmed；推送前必跑 schema_check。

## §8 部署节奏

本机 deep-strike + Redis；无新 Pod。

## §9 准出标准

### §9.1 功能
- [ ] confirm 1 条 → status=confirmed + human_confirmations +1
- [ ] reject 不推送；stream 无该 thesis_id 新消息

### §9.2 质量（§3.5 14 项）
- [ ] R1~R4、C1~C5、P1~P3、E1~E2 逐项勾选

### §9.3 工程
- [ ] `make deep-step08-all`；L4 回写（一致率%、XLEN、commit）
- [ ] **禁止**生产路径 stub 自动 confirm

## §10 [Deploy]

复用 deep-strike 镜像；ConfigMap 增 `REVIEWER_API_TOKEN`（可选）。

## §11 依赖

step_05~07；Redis；D0 step_04 可并行（stream 自检代替）。

**严禁**：伪造一致率；未 confirm 推送。

## §12 风险

| 触发 | 动作 |
|---|---|
| 样本<10 | 人工补种子；报告标 insufficient |
| schema 漂移 | 修 pydantic + 重跑 schema_check |
| bypass 检出 | 立即修 + ADR |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 940 行嵌入 Python；§3.5 14 项；Makefile；永久规则三处强制；940→~310 行 |
| 2026-05-16 | 初版 940 行 |
