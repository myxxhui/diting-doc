# Step 08 · decision_gate 聚合 + 审计日志 + Redis Stream

## §1 一句话定位与本步交付物

**一句话**：把 step_07 三引擎路由聚合为一个 `decision_gate` 总闸（任意 reject → reject；≥2 degrade → 升级 reject；全 pass → 放行），所有决策写**不可篡改**的 `audit_log`（哈希链）+ 异步 publish 到 3 个 Redis Stream（reject / degrade / pass），供 D0 副驾驶与 D5 演进飞轮消费。

**交付物**（勾选 = 完成）：
- [ ] **A**（`DecisionGate` 聚合器）：`apps/cryo_guard/decision_gate/gate.py` 实现 `aggregate(engine_outputs: list[EngineOutput]) -> GateDecision`；聚合规则与 DNA `deliverables.decision_gate.aggregation_rule` 一致
- [ ] **B**（`audit_log` 表 + 哈希链）：`AuditLog` ORM + 字段：`audit_id / symbol / decision_at / final_decision / aggregation_reason / engine_scores(JSON) / evidence(JSON) / prev_hash / curr_hash`；INSERT-only；`prev_hash` 链式校验
- [ ] **C**（3 Redis Stream）：`apps/cryo_guard/decision_gate/streams.py` 提供 `publish_{reject,degrade,pass}(payload)`；事件 payload 含 `symbol / name / audit_id / final_decision / aggregation_reason / engine_scores`；topic 与共享时序 §四对齐
- [ ] **D**（聚合路由）：`POST /api/decision-gate/check` 并行调 3 engine → aggregate → audit 入库 → xadd stream → 返 GateDecision
- [ ] **E**（审计查询）：`GET /api/audit/logs?symbol=&from=&to=` 列表 + `GET /api/audit/logs/{audit_id}` 单条
- [ ] **F**（DB 写权限收紧）：运行时 DB user 仅 SELECT + INSERT；`apps/cryo_guard/decision_gate/validate_chain.py` 离线校验哈希链
- [ ] **G**（真实验证）：暴雷公司（康得新）→ reject；白名单（贵州茅台）→ pass；Holdout H001~H050 漏判 = 0（50 案例全部 reject）
- [ ] **H**（单测）：`pytest tests/cryo_guard/test_decision_gate.py -v` ≥ 10 passed
- [ ] **I**（Stream 可消费）：`redis-cli XRANGE events:cryo_guard:reject - + COUNT 3` 返示例事件
- [ ] **J**（Makefile 一键复现）：`make cryo-step08-all` 端到端通过

> **本步是 step_09/10 的硬阻塞**：综合 Holdout 评测 + 阶段验收均通过 decision_gate 跑。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2 哲学**：[01_维度一_极寒防御 · 04_防御实践策略规划](../../../../../02_战略维度/01_维度一_极寒防御/04_防御实践策略规划.md)
> - **本阶段总览**：[stage_1_启动期/README](../README.md)
> - **L3 技术架构**：[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §3.1 decision_gate（聚合逻辑 + 阈值）、§4.1 API 设计
> - **L3 验收**：[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md) §3.4 服务验收清单（decision_gate 可正确聚合）、§7.1 P0 必须项
> - **DNA 键**：`_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml` → `deliverables.decision_gate.aggregation_rule + reject/degrade thresholds`、`deliverables.audit_log`（表名 / 字段 / retention=永久）
> - **共享规约**：[13_六维度启动期集成与时序](../../../../_共享规约/13_六维度启动期集成与时序.md) §四 事件流总表（events:cryo_guard:reject/degrade/pass 与 D0/D5 消费契约）
> - **L4 实践记录**：[实践记录_step_08_decision_gate聚合与审计.md](../../../../../04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_08_decision_gate聚合与审计.md)
> - **上游 step**：← step_07（3 engine 路由）
> - **下游 step**：→ step_09（综合 Holdout 评测调 decision_gate）、step_10（阶段验收 e2e 跑 50 案例）；D0 副驾驶 / D5 演进飞轮（消费 Redis Stream）

## §3 数据采集对象 / 落库映射

**本步不采集外部数据**——把 3 engine 输出聚合为决策 + 写审计 + 发事件。

| 数据流向 | 来源 / 落库 | 用途 |
|---|---|---|
| 3 个 `EngineOutput` | HTTP 调 step_07 `/api/engines/*/check` | 聚合输入 |
| 决策结果 `GateDecision` | API 响应体 | 给前端 / 上游 |
| 审计 `audit_log` 行 | SQLite（INSERT-only + 哈希链） | 永久审计追溯 |
| Reject 事件 | Redis Stream `events:cryo_guard:reject` | D0 副驾驶推送 + D5 演进飞轮回灌 |
| Degrade 事件 | Redis Stream `events:cryo_guard:degrade` | 同 |
| Pass 事件 | Redis Stream `events:cryo_guard:pass` | 量较大，D5 抽样消费 |
| 兜底队列 | 本地 SQLite `failed_stream_publish` 表 | Redis 不可用时落本地 + 异步重试 |

## §3.5 数据质量验收矩阵（按 step_09/10 + 下游 D0/D5 消费需求反推 · 仅启动期负责）

> **本步范围**：聚合规则 + 审计哈希链 + Redis Stream 三个环节。每行 ✅ 或 ⚠️。**不**列扩展期内容（如 Kafka 替换 Redis、多副本 stream）。

### §3.5.1 聚合规则质量

| # | 维度 | 必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| A1 | **任意 reject → reject** | `engine_outputs` 任一 `label=fraud / integrity_failure / related_party_risk` 且 `confidence ≥ reject_threshold(0.75)` → `final_decision=reject` | ✅ 规则直接实现 | reject 阈值放 `configs/decision_gate.yaml` 可调 |
| A2 | **2 degrade → 升级 reject** | ≥ 2 个引擎处于 `confidence ∈ [degrade_threshold(0.5), reject_threshold(0.75))` → `final_decision=reject` + `aggregation_reason=2_degrade_escalated` | ✅ | 阈值可调 |
| A3 | **全 pass → 放行** | 3 引擎均 `confidence < degrade_threshold` 且 `label != fraud` → `final_decision=pass` | ✅ | — |
| A4 | **单引擎调用失败的兜底** | engine 路由超时 / 5xx → 标该 engine `status=engine_failure` 并视为 `degrade`（不强转 reject 避免假阳性）| ⚠️ 启动期保守；ADR 说明权衡 | 引擎失败超过 1 个 → 整请求降级 `final_decision=degrade + reason=engine_unavailable` |
| A5 | **并行调用 + 超时控制** | 3 engine 并行调用；单 engine 30 s 超时；总耗时 ≤ 35 s | ✅ httpx + asyncio.gather | 超时频繁 → 检查 step_07 P95 |

### §3.5.2 审计日志哈希链质量

| # | 维度 | 必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| H1 | **不可篡改：INSERT-only** | 运行时 DB user 仅 SELECT + INSERT 权限；任何 UPDATE / DELETE 抛权限错 | ⚠️ SQLite 弱权限模型；启动期靠"应用层不写 UPDATE / DELETE 语句" + 代码 review；扩展期切 PostgreSQL 用真权限 | 启动期 ADR 说明现状；扩展期实现 RBAC |
| H2 | **哈希链字段** | `prev_hash + curr_hash`；`curr_hash = SHA256(prev_hash + audit_id + symbol + decision_at + final_decision + aggregation_reason + engine_scores_json + evidence_json)` | ✅ 入库前计算 | 链断（prev_hash 找不到前一条）→ 抛异常拒绝入库 |
| H3 | **链可校验** | `validate_chain.py` 离线扫表逐条重算 hash 比对 | ✅ | 校验失败定位到具体 audit_id + 中断说明 |
| H4 | **必产字段齐全** | 9 字段全部非 null（除首条 prev_hash 为空字符串）| ✅ ORM 约束 | 缺字段抛 ValueError 拒绝入库 |
| H5 | **保留期** | 启动期永久保留；不归档 | ✅ | 扩展期接归档冷存储 |

### §3.5.3 Redis Stream 事件质量

| # | 维度 | 必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| S1 | **3 topic 名一致** | `events:cryo_guard:{reject,degrade,pass}` 严格 = 共享时序 §四 | ✅ 常量定义 | 名字漂移 → CI 失败 |
| S2 | **payload schema 一致** | `symbol / name / audit_id / final_decision / aggregation_reason / engine_scores / decision_at` | ✅ Pydantic | 缺字段不发布；落兜底队列 |
| S3 | **at-least-once 投递** | `XADD` 失败 → 落 SQLite `failed_stream_publish` + 后台任务重试 | ⚠️ 启动期最小实现；启动 worker 后台扫表 | Redis 长期不可用时累积；告警阈值 ≥ 100 行 |
| S4 | **D0 副驾驶消费契约对齐** | D0 用 consumer group `d0_copilot_reject` 消费 reject；ack 后才不重发 | ✅ 13_ 共享规约约定 | D0 未起时 stream 积压（Redis 7.x stream 默认不限长，启动期可接受）|
| S5 | **D5 演进飞轮回灌契约对齐** | D5 用 consumer group `d5_evo_all` 消费三 topic 全量 | ✅ | 同 S4 |

### §3.5.4 真实数据验证质量

| # | 维度 | 准出门槛 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| V1 | **暴雷公司 reject** | 康得新等 ≥ 1 暴雷标的过 decision_gate 返 reject + 至少 1 engine high confidence fraud | ⚠️ 依赖 active 标的含暴雷 / 或临时加 1 真实历史暴雷做验证（如康美药业）| 标的不在 active 时临时跑 + 不入库（test mode）|
| V2 | **白名单 pass** | 贵州茅台等蓝筹过 decision_gate 返 pass | ⚠️ 同 V1 | 同 |
| V3 | **50 案例 Holdout 漏判 = 0** | H001~H050 50 案例全部 reject | ⚠️ 实测；step_09 会完整跑 | 漏判 > 0 → 本步标 fail 不 pass 准出，回到对应 step_04/05/06 排查 |

> 共 **17 项启动期质量要求**（A1~A5 聚合 + H1~H5 审计 + S1~S5 stream + V1~V3 验证）。矩阵中**无 ❌**。

### §3.5.5 质量门槛（合并到 §9.2）

矩阵每行须满足之一：
- **✅ 覆盖**：本步已实现且抽样验证通过；
- **⚠️ 启动期降级**：明确降级路径 + 在该降级下下游 D0/D5/step_09 仍能消费。

**禁止**：①审计日志写明文密码；②为通过准出人工删除/修改 audit_log；③stream payload 不全靠下游补全；④用 mock engine 返回伪造 V1/V2/V3 验证。

## §4 真实数据源与凭证清单

### §4.1 资源

| 资源 | 来源 | 备注 |
|---|---|---|
| 3 engine 路由 | step_07 已部署 | HTTP 调用 |
| Redis 6379 | step_01 已起 | db=1（与 D0 共用实例不同 db）|
| SQLite cryo_guard.db | step_01 已建 | 本步加 `audit_log` 表 + `failed_stream_publish` 兜底表 |

### §4.2 用户须提供的凭证

| 凭证 | 用途 | 何时需要 | 写在哪里 |
|---|---|---|---|
| `REDIS_URL` | Stream 发布 | 部署前 | `.env` |
| `DECISION_GATE_REJECT_THRESHOLD / DEGRADE_THRESHOLD` | 阈值可调 | 部署前 | `configs/decision_gate.yaml` |

> **本步无新增外部凭证**。

## §5 启动期目标

### §5.1 关键设计

| 项 | 取值 | 理由 |
|---|---|---|
| reject_threshold | 0.75 | 高置信才单引擎触发；防误杀 |
| degrade_threshold | 0.50 | 中间态；≥ 2 个 degrade 升级 reject |
| 引擎调用并行度 | 3（asyncio.gather） | 总耗时接近最慢 engine |
| 单引擎超时 | 30 s | 与 step_07 一致 |
| 总超时 | 35 s | 留 5 s 给聚合 + 审计 + xadd |
| 审计哈希算法 | SHA256 | 标准选择 |
| Stream maxlen | 启动期不限（默认）；扩展期改 maxlen=1e6 ~ | 启动期 50 案例 +日常少量；不会积压 |
| 兜底队列重试间隔 | 后台 60 s 扫一次 | 启动期最小可工作 |

### §5.2 性能 / 正确性门槛

| 指标 | 启动期门槛 | 说明 |
|---|---|---|
| `/api/decision-gate/check` P50 | < 8 s | 含 3 engine 串行最坏 |
| `/api/decision-gate/check` P95 | < 12 s | |
| 哈希链 100% 可校验 | 是 | `validate_chain.py` 退出码 0 |
| Holdout 50 案例漏判 | = 0 | 50 案例全部 reject |
| Stream 至少一次投递率 | ≥ 99% | Redis 短暂不可用允许走兜底 |

### §5.3 可接受退化

- Redis 不可用 → 走兜底队列 + 后台异步重试 + 标 `stream_published=false`；
- 单引擎调用失败 → 视为 degrade 不强 reject；超 1 个失败 → 整请求 degrade；
- 哈希链断裂 → 拒绝该次入库 + 告警 + ADR；
- 50 案例漏判 > 0 → 本步**不通过**准出，回到对应 step_04/05/06 排查。

## §6 下一步（一行触发条件）

- **触发条件**：本步全部 ✅ + 50 案例漏判 = 0 + 哈希链 OK + Stream 可消费 → step_09（综合 Holdout 评测正式跑）。
- **下一阶段方向**：扩展期把 Redis 切 Kafka + audit_log 切 PostgreSQL + 引入 ABAC 权限；详见 `stages/stage_2_扩展期/`。

## §7 实施规划（L3 设计 · 给后续执行模型的工作指引）

> **L3 定位**：本节是**设计规划 + 实现要点 + 验证标准**——**不嵌入完整 Python 类 / Cypher / yaml 代码**。具体落地由 L4 实践记录 / 后续执行模型按本节规划自行完成。

### §7.1 实现要点（按交付物拆分）

| 实现要点 | 涉及代码位置 | 关键设计决策 | 验证标准 |
|---|---|---|---|
| **A `AuditLog` ORM + migration** | `apps/cryo_guard/db/models.py` + alembic | 9 字段（见 §1·B）；INSERT-only 通过应用约定 + DB user 权限；索引：`(symbol, decision_at)`、`audit_id` 唯一 | `alembic upgrade head`；`.tables` 含 audit_log |
| **B 哈希链计算** | `apps/cryo_guard/decision_gate/audit_log.py` | `compute_curr_hash(prev_hash, audit_row) -> str`；入库前查最近一条 prev；首条 prev_hash="" | 单测：3 条入库 → 链可校验 |
| **C `validate_chain.py`** | `apps/cryo_guard/decision_gate/validate_chain.py` | 扫全表按 decision_at 升序逐条重算 hash 比对；不通过定位 audit_id；CLI 退出码 | 单测 mock 1 条改 final_decision → 校验失败 |
| **D `DecisionGate.aggregate`** | `apps/cryo_guard/decision_gate/gate.py` | 输入 `list[EngineOutput]` → 输出 `GateDecision(final_decision, aggregation_reason, engine_scores)`；阈值从 yaml 注入；A1~A5 全实现 | 单测：5 类规则各正负 1 = 10 测试 |
| **E `streams.py` + 兜底** | `apps/cryo_guard/decision_gate/streams.py` + `apps/cryo_guard/db/models.py`（追加 `FailedStreamPublish`）| `publish_{reject,degrade,pass}(payload)`；失败落兜底表 + 后台 worker 重试 | 单测 mock Redis fail → 兜底表 +1；mock OK → stream +1 |
| **F decision_gate 路由** | `apps/cryo_guard/api/routes/decision_gate.py` | `POST /api/decision-gate/check`：①Pydantic 入参（request_id, symbol, period?）；②asyncio.gather 调 3 engine 路由（30 s 超时）；③aggregate；④audit 入库（含哈希链）；⑤publish stream（兜底）；⑥返 GateDecision | 端到端 fixture 1 case 全过 |
| **G audit 查询路由** | `apps/cryo_guard/api/routes/audit.py` | `GET /api/audit/logs?symbol=&from=&to=&page=&size=`；`GET /api/audit/logs/{audit_id}`；只读 | 查询返已入库行 |
| **H FastAPI 注册** | `apps/cryo_guard/api/main.py` | 注册 2 新路由 + 启动时 SELECT 检查 audit_log 表存在；不存在则 503 启动失败 | `/api/decision-gate/health` 返 `ready` |
| **I 集成验证脚本** | `scripts/e2e_verify_step08.sh` | ①调 decision-gate 1 暴雷标的 → 期望 reject + 1 stream 事件 + 1 audit 行；②1 白名单 → pass；③validate_chain 退出码 0 | 退出码 0 |
| **J Holdout 50 案例漏判校验** | `training/scripts/holdout_recall_check.py` | 50 案例并发调 decision-gate → 统计 final_decision=reject 数 + missing 列表；输出 JSON | reject 数 = 50；missing 空 |
| **K DB 写权限收紧（启动期约定）** | 文档约定 + 代码 review checklist | 不在代码中出现 UPDATE/DELETE audit_log；扩展期切 PostgreSQL 实现 RBAC | 代码 grep 0 UPDATE audit_log |
| **L 单测** | `tests/cryo_guard/test_decision_gate.py` | 覆盖：聚合 5 类（10 测试）+ 哈希链（2）+ Stream 兜底（2）+ 集成路由（2）+ validate_chain（2） | `pytest -v` ≥ 10 passed |

### §7.2 Makefile 一键复现合约（L3 约定 · L4 实现）

**设计目的**：step_07 跑通后跑 `make cryo-step08-all` 完成"alembic 加 audit_log → 路由部署 → 真实 / Holdout 验证 → 哈希链校验 → 单测"全套。

**target 合约表**：

| target | 用途 | 入参（环境变量 · 均有默认） | 验证标准 |
|---|---|---|---|
| `make cryo-step08-prep` | alembic upgrade 加 audit_log + failed_stream_publish 表 | `DATABASE_URL` | `.tables` 含 2 新表 |
| `make cryo-step08-apply` | rebuild cryo-guard 镜像 + apply | `IMAGE_TAG` | Pod Running；新路由可达 |
| `make cryo-step08-e2e-real` | 1 暴雷 + 1 白名单 真实验证 | `BLACKLIST_SYMBOL / WHITELIST_SYMBOL` | reject + pass 各 1 |
| `make cryo-step08-holdout-recall` | 50 案例 Holdout 漏判校验 | `HOLDOUT_DIR` | 50/50 reject |
| `make cryo-step08-validate-chain` | 哈希链离线校验 | — | 退出码 0 |
| `make cryo-step08-stream-check` | redis-cli XRANGE 3 topic 各看 3 条 | `REDIS_URL` | 3 topic 至少各 1 条 |
| `make cryo-step08-test` | 单测 | — | `pytest -v` ≥ 10 passed |
| `make cryo-step08-all` | **端到端一键** | 同上合并 | 全部退出码 0；端到端 ≤ 10 min |
| `make cryo-step08-status` | 进度快照（只读） | — | audit_log 行数 + stream maxid + 兜底表行数 |
| `make cryo-step08-clean` | 清 audit_log（**仅 dev 环境**，需 `FORCE=1`） + 重置 stream | `FORCE` | 清空表；stream del |

**合约要求**：
1. **入参环境变量化**；阈值改 yaml 即可不改 Makefile；
2. **target 是薄包装**；
3. **可重入幂等**：alembic upgrade head 已是 head 跳过；apply 走 declarative；
4. **降级显式**：Redis 不可用时 stream-check target 报告"已走兜底队列：N 行待重试"；
5. **失败可观察**：每 target 中文 3 行摘要 + audit_log 新增数 + stream maxid。

### §7.3 给后续执行模型的指引

L4 / 执行模型按以下顺序：

1. **核对前置**：step_07 三路由 ✅ + Redis OK + SQLite OK；
2. **逐项落地 A~L**：建议顺序 A→B→C→D→E→F→G→H→I→J→K→L；
3. **集成 Makefile**：按 §7.2 实现 10 个 target；
4. **真实验证必跑**：仅单测不够；e2e-real + holdout-recall + validate-chain 三者全过才算准出；
5. **§9 准出 + L4 回写**：audit_log 总行数、3 stream 各事件数、validate_chain 耗时、哈希链长度、50 案例 reject 数；
6. **遇问题**：漏判 > 0 → 逐案分析（哪个 engine 没触发 / 阈值是否过高）→ 改阈值或回 step_04/05/06 修；Redis 不可用 → 检查兜底表 + 重启 worker；同问题 ≥ 2 次失败 § 8.4f 回收。

> **L3 责任边界**：本节给规划 + 实现要点 + 验证标准；**不**给完整 Python 类 / SQL 字面量；具体落地交给 L4 实践记录 / 后续执行模型。

## §8 部署节奏（本步在哪里跑）

| 阶段 | 形态 | 是否本步必须 | 说明 |
|---|---|---|---|
| **本机开发** | `uvicorn apps.cryo_guard.api.main:app` + `pytest` + Redis local | **必须** | 聚合器 / 审计 / stream / 单测在本机 |
| **本机 docker-compose** | — | 否 | Redis / SQLite 已在 step_01 |
| **Dev K3s** | rebuild cryo-guard 镜像 + apply（含新路由）| **必须** | step_09/10 e2e 跑本步路由 |
| **ACR + 生产 K3s** | 扩展期 Helm Chart | 否 | 启动期裸 yaml |

**本步默认运行形态**：本机开发 + Dev K3s（cryo-guard 加新路由 + 沿用 step_07 Redis）。

## §9 准出标准（同会话可执行清单 · 质量优于数量）

### §9.1 功能门槛
- [ ] `POST /api/decision-gate/check` 真实 1 case 返 GateDecision；audit_log +1 行；stream +1 事件
- [ ] `GET /api/audit/logs?symbol=X` 返已入库行
- [ ] `validate_chain.py` 退出码 0

### §9.2 数据质量门槛（§3.5 矩阵 17 项）
- [ ] **聚合 5 项（A1~A5）**：单测全过 + e2e 实测
- [ ] **审计 5 项（H1~H5）**：哈希链可校验 + 字段齐全 + 9 字段非 null
- [ ] **Stream 5 项（S1~S5）**：3 topic 名一致 + payload schema + at-least-once（含兜底）+ D0/D5 契约对齐
- [ ] **真实验证 3 项（V1~V3）**：暴雷 reject + 白名单 pass + 50 案例漏判 = 0

### §9.3 工程交付
- [ ] `pytest tests/cryo_guard/test_decision_gate.py -v` ≥ 10 passed
- [ ] `apps/cryo_guard/decision_gate/` 含 4 个 .py（gate / audit_log / streams / validate_chain）+ `__init__`
- [ ] `apps/cryo_guard/api/routes/{decision_gate,audit}.py` 注册

### §9.4 一键复现
- [ ] **Makefile 合约**（§7.2）：10 个 target 已实现且通过；`make cryo-step08-all` 端到端 ≤ 10 min
- [ ] **可重入验证**：连跑两次 `make cryo-step08-all`，第二次 alembic head 跳过 + apply 幂等 + audit_log 不重复（按 request_id 幂等）
- [ ] L4 实践记录 `04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_08_decision_gate聚合与审计.md` 已按 §8.4g 更新"二、实际进展"（audit_log 总行数、3 stream 事件数、validate_chain 结果、50 案例 reject 数、commit hash）
- [ ] commit：`feat(cryo-guard): step_08 decision_gate aggregation + audit log + Redis Stream + Makefile [Ref: 03_/01_维度一/.../step_08]`
- [ ] **同会话验证**：上述命令在当次会话执行并输出摘要

## §10 [Deploy] 段

**本步追加路由到 cryo-guard 现有镜像**（rebuild + apply），不引入新 K8s workload；仍依赖 step_07 的 cryo-guard / vllm Deployment。

| 内容 | 位置 | 启动期边界 |
|---|---|---|
| cryo-guard 镜像 rebuild | `diting-src/deploy/docker/Dockerfile` | 含新路由代码 + ORM 迁移 |
| K3s yaml | （不新增）复用 step_07 cryo-guard-deployment.yaml；仅 ConfigMap 增 `DECISION_GATE_REJECT_THRESHOLD / DEGRADE_THRESHOLD` 两键 | 启动期足够 |
| Helm Chart | （扩展期）`diting-infra/charts/cryo-guard/` 整合 | 本步**不**做 |

**deploy-engine 自检**（强制）：若改 `diting-infra/deploy-engine/`，须在平级独立 `deploy-engine/` 仓库 push 后 `make update-deploy-engine`。**禁止**在 diting-infra 子模块拷贝内做任何写操作。

## §11 依赖与被依赖

**上游**：
- `step_07`：3 engine 路由可调；
- `step_01`：Redis + SQLite；
- 用户提供：`REDIS_URL` + 阈值 yaml。

**下游**：
- `step_09` 综合 Holdout：50 案例调 `/api/decision-gate/check`；
- `step_10` 阶段验收：e2e demo；
- D0 副驾驶：消费 reject stream 推送给用户；
- D5 演进飞轮：消费三 stream 回灌 + 演化训练样本。

**严禁伪造**（no-mock-policy）：①审计行不允许 mock；②stream 事件不允许 mock；③50 案例 Holdout 漏判必须真实 = 0，不允许人工修改 audit_log。

## §12 风险与回退

| 触发条件 | 动作 |
|---|---|
| Redis 不可达 | 落兜底队列 `failed_stream_publish` + 后台 worker 重试；告警阈值 ≥ 100 行；30 min 内不恢复 ADR |
| 单引擎调用失败 ≥ 1 个 | 视为 degrade 不强 reject；超 1 个 → 整请求 degrade |
| 哈希链断裂 | 拒绝该次入库 + 抛 500 + ADR；查 prev_hash 链是否被人手改 |
| 50 案例漏判 > 0 | 本步**不通过**准出；逐案分析（哪个 engine 没触发 / 阈值过高）；改阈值或回 step_04/05/06 修 LoRA |
| audit_log 表被人手 UPDATE/DELETE | 紧急告警 + ADR；回滚到上一备份；启动期 SQLite 弱权限，扩展期切 PostgreSQL RBAC |
| 同问题修复重试 ≥ 2 次仍失败 | § 8.4f 回收 |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按新 L3 启动期 step 模板（v1.2）重写**（关键重构，与 `00_系统规则` §4.5 同步）：①删除全部嵌入完整 Python 类 / SQL / Redis 命令代码（原文 874 行 → 现 ~320 行）；②新增 §3.5 数据质量验收矩阵 17 项（A1~A5 聚合 + H1~H5 审计 + S1~S5 stream + V1~V3 真实验证）；③§7 改为"实施规划"三段式（§7.1 实现要点 12 项 + §7.2 Makefile 合约 10 个 target + §7.3 给后续执行模型指引）；④§5 性能 / 正确性门槛表只保留指标不嵌伪码；⑤§9 准出加 Makefile 合约 + 可重入验证 + audit_log 按 request_id 幂等；⑥§10 [Deploy] 含 deploy-engine 自检约束；⑦明确 L3 责任边界 |
| 2026-05-16 | 初版（含完整 Python 类 / 哈希链算法 / Redis 命令 + SQL），874 行 |
