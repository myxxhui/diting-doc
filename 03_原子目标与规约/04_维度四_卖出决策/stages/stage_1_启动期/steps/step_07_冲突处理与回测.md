# Step 07 · 冲突处理 + 100 笔历史回测 + `events:exit:sell_signal` 发布

## §1 一句话定位与本步交付物

**一句话**：把 4 协议串联成 **ExitEngineOrchestrator**——评估 → **ConflictResolver**（按 priority 升序选最高、同优 stable sort、**全部触发入审计**）→ Buffer 处理 → **SellSignalPublisher** `XADD events:exit:sell_signal` 给 D0；提供 **100 笔历史回测** 脚本验证触发准确率 **≥0.95**；发布延迟 P95 **<30s**（实测应 <1s）。

**交付物**（勾选 = 完成）：
- [ ] **A**（`ConflictResolver`）：串行评估 4 协议；选最高 priority；同优按协议名 stable sort；主审计 + 子审计
- [ ] **B**（`SellSignalPublisher`）：XADD `events:exit:sell_signal`；payload 与 DNA `output_event.fields` 一致 + `pass_event_id / evidence_ref / protocol / advice`
- [ ] **C**（`ExitEngineOrchestrator`）：顶层编排 portfolio→4 protocol→conflict→buffer→publish
- [ ] **D**（API）：`POST /api/engine/evaluate/{user_id}`；`.../{position_id}`
- [ ] **E**（回测脚本）：`scripts/backtest_100_history.py --csv tests/exit_engine/fixtures/backtest_history.csv` → 准确率报告
- [ ] **F**（回测 fixture）：`backtest_history.csv` 100 行（含 4 协议各≥20 笔 + 冲突场景 ≥10 笔）
- [ ] **G**（失败兜底）：XADD 失败落 `failed_stream_publish` + 后台 worker 重试
- [ ] **H**（单测 + Makefile）：≥25 passed；`make exit-step07-all`

> **永久规则**：sell_signal 仅 advice；**不**触发下单；D0/前端展示由人确认。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../01_实践目标与策略.md](../01_实践目标与策略.md) §3.1 优先级、§3.2 冲突；[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §3.6/§3.8
> - **DNA**：`conflict_resolution`、`quantitative_goals(0.95 回测，<30s 延迟)`、`output_event(stream + fields)`
> - **共享**：[13_六维度启动期集成与时序](../../../../_共享规约/13_六维度启动期集成与时序.md) §四（sell_signal SLA）
> - **D0**：消费 `events:exit:sell_signal`（D0 step_05）
> - **L4**：[实践记录_step_07_冲突处理与回测.md](../../../../../04_阶段规划与实践/04_维度四_卖出决策/stage_1_启动期/实践记录_step_07_冲突处理与回测.md)
> - **上游**：step_03~06；**下游**：step_08 阶段验收

## §3 数据采集对象 / 落库映射

| 流向 | 表/流 |
|---|---|
| 协议评估结果 | `protocol_logs`（trigger/abstain 子审计）|
| 冲突解决 | `protocol_logs(decision=conflict_resolved, triggered_protocols=[...], final_protocol=...)` |
| 发布事件 | Redis `events:exit:sell_signal` + `sell_signals` 表 |
| 失败兜底 | `failed_stream_publish(stream_key,payload,error,retried_at)` |
| 回测 | `tests/exit_engine/fixtures/backtest_history.csv`（**仅** tests/）|

## §3.5 数据质量验收矩阵（冲突 + 回测 + 发布 · 仅启动期）

### §3.5.1 冲突解决

| # | 场景 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| C1 | SP1 + SP3 同 priority=1 | stable sort 选 stop_loss；两子审计 + 主审计 | ✅ 单测 | — |
| C2 | SP2 + SP4 | SP2（priority=2 升序最高）| ✅ | — |
| C3 | SP1 + SP2 + SP4 | SP1 | ✅ | — |
| C4 | 4 协议全触发 | SP1（与 SP3 同优 stable sort）；triggered_protocols=4 | ✅ | — |
| C5 | 仅 SP4 | SP4 直返 | ✅ | — |
| C6 | 0 触发 | 仅 abstain 子审计；无 final | ✅ | — |
| C7 | **全部触发入审计** | priority>=1 触发协议各 1 条 trigger 子审计 + 主审计 conflict_resolved | ✅ | 缺审计 FAIL |

### §3.5.2 发布契约（D0）

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| P1 | **stream 名** | `events:exit:sell_signal` = DNA + 13_ | ✅ 常量 | — |
| P2 | **payload 字段** | symbol / signal_type / trigger_price / current_price / protocol / advice + event_id + ts | ✅ Pydantic | — |
| P3 | **schema 对齐 D0** | `schema_check_d0.py` diff=0 | ⚠️ | 漂移修后再 e2e |
| P4 | **at-least-once** | XADD 失败落 `failed_stream_publish` + 重试 | ✅ 最小 worker | Redis 长断累积告警≥100 |
| P5 | **延迟 P95** | <30s（实测应 <1s）| ✅ | 超时告警 |
| P6 | **审计 evidence_ref** | SP3 含 health_change.event_id；其他可空 | ✅ | — |

### §3.5.3 100 笔回测

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| B1 | **样本量** | 100 行；4 协议各≥20；冲突≥10 | ✅ csv | <100 不准出 |
| B2 | **触发准确率** | ≥0.95（与 expected_protocol 一致）| ⚠️ 启动期目标 | <0.95 走 §12 回退 |
| B3 | **样本来源** | 真实历史价格 + 真实历史 health_change（或人工标注）| ⚠️ 启动期可人工合成 ≤30% | 标注比例写报告 |
| B4 | **可重跑幂等** | 同 csv 同结果 | ✅ deterministic | — |
| B5 | **混淆矩阵** | 报告含 per-protocol precision/recall | ✅ | — |

### §3.5.4 工程 no-mock

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **不自动下单** | publisher 仅 XADD；无下单调用 | ✅ assert | — |
| E2 | **回测 fixture 仅 tests/** | `tests/exit_engine/fixtures/*.csv` 标 TEST_ONLY | ✅ | — |
| E3 | **生产 publisher 用真 Redis** | `make exit-step07-all` 不接 fakeredis | ✅ | tests 例外 |
| E4 | **审计完整** | 主审计 + 子审计 + sell_signals 一致 | ✅ | — |

> 共 **22 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| `REDIS_URL` | publisher XADD |
| step_03~06 协议已注册 | 4 协议串评估 |
| 回测 csv | 100 行 fixture |

> D0 未就绪：仍可 XADD + redis-cli XLEN 自检；schema_check_d0 仍跑。

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 回测准确率 | ≥0.95 |
| sell_signal 延迟 P95 | <30s（实测应 <1s）|
| 冲突单测 | 7 场景全过 |
| 单测合计 | ≥25 passed |

## §6 下一步

本步 ✅ → step_08 阶段验收。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A ConflictResolver** | `services/conflict_resolver.py` | priority 升序；同优协议名 stable sort | 7 场景单测 |
| **B Orchestrator** | `services/exit_engine_orchestrator.py` | portfolio→4 protocol→conflict→buffer→publish | e2e 一笔 |
| **C SellSignalPublisher** | `events/sell_signal_publisher.py` | XADD + Pydantic payload + 兜底 | mock fail OK |
| **D failed_stream_publish ORM + worker** | `db/models.py` + `events/retry_worker.py` | 同 D1/D2 模式 | 重试单测 |
| **E engine_router** | `routers/engine_router.py` | user/position 两级 | 200 |
| **F 回测脚本** | `scripts/backtest_100_history.py` | 读 csv → 模拟时间 → 跑 orchestrator → 统计 | 报告 |
| **G fixture csv** | `tests/exit_engine/fixtures/backtest_history.csv` | 100 行；TEST_ONLY 标注 | 列校验 |
| **H 单测** | `test_conflict_resolver / publisher / orchestrator / backtest` | ≥25 | pytest |
| **I run_one_evaluation** | `scripts/run_one_evaluation.py` | `--publish` 真 XADD 联调 | XLEN≥1 |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `exit-step07-prep` | step_03~06 已注册；Redis OK |
| `exit-step07-conflict-test` | 7 场景单测 |
| `exit-step07-publish-once` | run_one_evaluation --publish；XLEN+1 |
| `exit-step07-backtest` | backtest 100 笔；准确率报告 ≥0.95 |
| `exit-step07-schema` | schema_check_d0 diff=0 |
| `exit-step07-latency` | measure 4 协议端到端延迟 P95<30s |
| `exit-step07-test` | pytest ≥25 |
| `exit-step07-all` | 端到端 |
| `exit-step07-status` | XLEN + 最近 10 sell_signals + 兜底队列 |
| `exit-step07-clean` | dev FORCE=1 清当日 |

### §7.3 指引

先 ConflictResolver→Publisher→Orchestrator→回测→延迟测量；csv 严格 TEST_ONLY；生产 `make all` **必须**用真 Redis；准确率<0.95 不准出，回查协议阈值/缓冲。

## §8 部署节奏（P 轨 · 真实基建对齐）

| 阶段 | 形态 | 是否本步必须 | 说明 |
|---|---|---|---|
| **tier-1 · 本机** | 本机进程 + 本地 Redis + `pytest` | **必须** | ConflictResolver / Publisher / 回测逻辑 + 单测在本机完成；回测 csv 严格 `TEST_ONLY` 不入库 |
| **P轨 中间件（★M4 / tier-2）** | P-step_03 `diting-stack` Up；platform Redis + TimescaleDB | **M4 必须** | Redis Stream：`redis-svc.platform:6379`（NodePort 30379）；`sell_signal_stream` XADD 写 platform Redis；schema diff=0 由 `diting-stack` ConfigMap 中 `SELL_SIGNAL_STREAM_MAXLEN` 控制 |

**M4 链（★ 锁死 · W8）**：P-step_03 `diting-stack` Up ✅ → exit-engine Pod 连 platform Redis → `sell_signal` 真流 XADD → D0 消费端可见 → M4 准出。

**tier-1 准出**：本机 + 本地 Redis + 100 笔回测 csv（TEST_ONLY）准确率 ≥0.95 + `make exit-step07-all`。
**tier-2 / ★M4**：连接 `redis-svc.platform:6379`（`REDIS_HOST` 指向 NodePort）；真 `sell_signal_stream` XADD 1 条 + XLEN +1 验证；D0 consumer 可选（stream 自检即可）。

**扩展期**：exit-engine 上 K3s Deployment；retry worker 独立 sidecar；多实例 Redis Cluster。

## §9 准出标准

### §9.1 功能
- [ ] 7 个冲突场景全通过
- [ ] 100 笔回测准确率 ≥0.95（报告 csv + JSON）
- [ ] XADD 1 条真 publish；XLEN +1；schema diff=0

### §9.2 质量（§3.5 22 项）
- [ ] C1~C7 + P1~P6 + B1~B5 + E1~E4 全勾

### §9.3 工程
- [ ] `pytest tests/exit_engine/` ≥25 passed
- [ ] `make exit-step07-all`；L4 回写（XLEN、准确率、延迟 P95、混淆矩阵）

## §10 [Deploy]

ConfigMap 增 `SELL_SIGNAL_STREAM_MAXLEN=10000`、`RETRY_INTERVAL_SEC=60`。

**P 轨中间件对齐（tier-2 / ★M4）**：
- Redis：`SELL_SIGNAL_STREAM_MAXLEN`、`RETRY_INTERVAL_SEC` 写入 `diting-stack` ConfigMap（或独立 exit-engine ConfigMap）；**不写死** Makefile / 脚本；
- `REDIS_HOST` 环境变量 tier-1 指向 `localhost`，tier-2 指向 `redis-svc.platform:6379` 或 NodePort（从 prod.conn 读取）；
- exit-engine Pod（扩展期 K3s Deployment）通过 `diting-stack` chart 中 platform ns Service 访问 Redis，**不**自建独立 Redis 实例。

## §11 依赖

step_03~06；**P-step_03 `diting-stack` Up**（platform Redis `redis-svc.platform:6379`）；D0 可未起（stream 自检即可）。

**严禁**：回测 csv 进生产业务库；publisher 自动下单；准确率<0.95 强 push L5。

## §12 风险

| 触发 | 动作 |
|---|---|
| 准确率<0.95 | 回查协议阈值；调 buffer；增样本 |
| schema 漂移 | 修 Pydantic+重 e2e |
| Redis 不可达 | 走兜底；告警≥100 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-25 | **P 轨基建对齐（回写）**：§8 改为 tier-1/P轨中间件双行表（platform Redis `redis-svc.platform:6379`；M4 链锁死 W8）；§10 [Deploy] 补 Redis ConfigMap 指向与 REDIS_HOST 双态说明；§11 依赖加 P-step_03 `diting-stack` |
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 1380 行嵌入 Python/bash/csv；§3.5 22 项；TEST_ONLY；no-auto；`exit-step07-*`；1380→~320 行 |
| 2026-05-16 | 初版 1380 行 |
