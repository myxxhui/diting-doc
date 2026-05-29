# Step 07 · `events:monitor:health_change` 事件流 + 10 持仓 e2e

## §1 一句话定位与本步交付物

**一句话**：实现 **`events:monitor:health_change`** Redis Stream 发布器（state 切换或 push_level 变化时推送，**延迟 <30s**）+ **10 持仓 fixture** + e2e（状态切换准确率 **≥90%**）；D0 副驾驶/D4 卖出决策可消费；payload schema 与 D0/D4 字段级对齐。

**交付物**（勾选 = 完成）：
- [ ] **A**（`HealthChangeEvent` dataclass + publisher）：含 `event_id / node_id / symbol / old_state / new_state / old_health / new_health / old_push_level / new_push_level / rule_id / reason / thesis_status / narrative_label / sli_snapshot / ts`
- [ ] **B**（`publisher.py` 通用）：maxlen ~10000；XADD 失败落 `failed_stream_publish` 兜底；后台 worker 重试
- [ ] **C**（Orchestrator 升级）：state 变化或 push_level 变化时调 publisher
- [ ] **D**（10 持仓 fixture）：`tests/state_watch/fixtures/positions_10.py`；含预期初始/最终态
- [ ] **E**（e2e 测试）：注入 fixture → 触发探针 → orchestrator → 断言状态切换准确率 ≥90%
- [ ] **F**（schema 校验）：`scripts/schema_check_d0_d4.py` 与下游 payload 0 diff
- [ ] **G**（Makefile）：`make watch-step07-all`

> **永久规则**：本事件**不**触发自动操作；D4/D0 收到后由人决策。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §3.3、[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md) §3.2
> - **DNA**：`quantitative_goals` 推送 <30s + 状态切换准确率 ≥0.90
> - **共享**：[13_六维度启动期集成与时序](../../../../_共享规约/13_六维度启动期集成与时序.md) §三场景 B、§四 stream 表
> - **下游 D4**：`04_维度四_卖出决策/stages/stage_1_启动期/steps/step_05_SP3_Thesis失效协议.md`
> - **下游 D0**：`00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_03_EventConsumer.md`
> - **L4**：[实践记录_step_07_health_change事件流与10持仓测试.md](../../../../../04_阶段规划与实践/03_维度三_持仓监控/stage_1_启动期/实践记录_step_07_health_change事件流与10持仓测试.md)
> - **上游**：step_06；**下游**：step_08 验收

## §3 数据采集对象 / 落库映射

| 触发 | 输出 |
|---|---|
| state 变化（T1~T6 任一）| XADD `events:monitor:health_change` + state_transitions+1 |
| push_level 变化（颜色跨级）| XADD（rule_id=PUSH_*）|
| XADD 失败 | `failed_stream_publish` 兜底表 + 后台重试 |
| 全部事件 | 同步备份 `health_records.event_id`（可选）|

`thesis_status="invalid"` 触发：`new_state=exit` OR `narrative_label=contradiction AND narrative_invalid_count≥3` → D4 SP3 协议。

## §3.5 数据质量验收矩阵（事件流与 e2e · 仅启动期）

### §3.5.1 事件 schema 与契约

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| S1 | **stream 名** | `events:monitor:health_change` = 13_ §四 | ✅ 常量 | — |
| S2 | **payload 完整** | 14 字段非空（sli_snapshot 可空数组）| ✅ Pydantic | 缺字段不发；落兜底 |
| S3 | **D0 字段对齐** | schema_check diff=0 | ⚠️ | 漂移修后再 e2e |
| S4 | **D4 字段对齐** | schema_check diff=0；含 `thesis_status / narrative_label` | ⚠️ | 同 |
| S5 | **去重 / event_id** | UUID v4 每事件唯一 | ✅ | — |

### §3.5.2 推送质量

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| P1 | **推送延迟 <30s** | state 变化到 XADD 时间差 P95 <30s | ✅ time.perf_counter 测 | 超时告警 |
| P2 | **at-least-once** | XADD 失败落 SQLite + worker 重试 | ✅ 最小 worker | Redis 不可用积压告警≥100 |
| P3 | **maxlen** | `MAXLEN ~ 10000` | ✅ | — |
| P4 | **consumer group** | D0 `dim_zero` / D4 `dim_four` 各自 ACK | ✅ 文档约定 | D0/D4 未起→只发不消费 |

### §3.5.3 10 持仓 e2e 质量

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **fixture 多样性** | 4 态均≥1 标的；含触发 T1~T6 至少 4 条规则的样本 | ✅ | — |
| E2 | **状态切换准确率** | 期望转移与实际转移一致率 ≥0.90 | ⚠️ | <0.90 走 §12 回退 |
| E3 | **e2e 端到端** | 注入 SLI 值 → orchestrator → publisher → stream 有事件 | ✅ fakeredis 或真 Redis | — |
| E4 | **不触发建仓** | e2e 后无业务侧建仓动作 | ✅ assert | — |

### §3.5.4 no-mock

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| N1 | **生产路径不发假事件** | publisher 路径不允许 fixture | ✅ | tests/ 例外 |
| N2 | **生产 Redis 真实** | `make watch-step07-all` 用真 Redis 或文档 BLOCKED | ✅ | — |

> 共 **15 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| `REDIS_URL` | XADD |
| step_01~06 完成 | 硬前置 |
| D0/D4 step 文档（schema 参考）| schema_check |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 状态切换准确率 | ≥0.90（10 持仓）|
| 推送延迟 P95 | <30s |
| schema diff | 0 |

## §6 下一步

本步 ✅ → step_08 阶段验收。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A HealthChangeEvent + Pydantic schema** | `events/health_change.py` | 14 字段；UUID | 序列化 |
| **B Publisher** | `events/publisher.py` | XADD MAXLEN ~10000；fail→fallback | mock fail |
| **C 兜底表 + worker** | `db/models.py` + `events/retry_worker.py` | 60s 轮询；指数退避 | 单测 |
| **D Orchestrator 升级** | `health/orchestrator.py` | state 变 or push 变→publish | e2e |
| **E fixtures positions_10** | `tests/state_watch/fixtures/positions_10.py` | 4 态分布；含 T1~T6 触发集 | pytest |
| **F e2e test** | `test_e2e_10_positions.py` | 模拟 SLI 注入→断言准确率 | ≥0.90 |
| **G schema_check** | `scripts/schema_check_d0_d4.py` | 字段对比 | diff=0 |
| **H 延迟测试** | `test_event_publish.py` | time.perf_counter | <30s |
| **I 单测** | event_publish/e2e | ≥10 合计 | pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `watch-step07-prep` | Redis 连通；step_06 health 可算 |
| `watch-step07-publisher-smoke` | 1 节点 force transition → XLEN+1 |
| `watch-step07-fixture-10` | 注入 10 持仓 |
| `watch-step07-e2e` | 准确率 ≥0.90 |
| `watch-step07-schema` | D0+D4 schema diff=0 |
| `watch-step07-latency` | P95 <30s |
| `watch-step07-test` | pytest ≥10 |
| `watch-step07-all` | 全链路；非 BLOCKED 全绿 |
| `watch-step07-status` | XLEN + 兜底表行数 |
| `watch-step07-clean` | dev only `redis-cli DEL` |

### §7.3 指引

先 publisher+兜底→Orchestrator 升级→fixture→e2e；schema_check 与 D0/D4 同步推；准确率 < 0.90 时回 step_06 调权重或 T4 滚动窗口。

## §8 部署节奏（P 轨 · 真实基建对齐）

| 阶段 | 形态 | 是否本步必须 | 说明 |
|---|---|---|---|
| **tier-1 · 本机** | `uvicorn` + 本地 Redis + `pytest` | **必须** | publisher / Orchestrator / schema 逻辑 + 单测在本机完成 |
| **P轨 中间件（★M3 / tier-2）** | P-step_03 `diting-stack` 已 Up；使用 platform ns Redis + TimescaleDB | **M3 必须** | Redis：`redis-svc.platform:6379`（NodePort 30379）；`health_change` Stream XADD 写入 platform Redis；DB 事件落入 `diting-stack` TimescaleDB（prod.conn 30001）|

**M3 链（★ 锁死 · W7）**：P-step_03 `diting-stack` Up ✅ → watch Orchestrator 读 `health_change_signal` stream（platform Redis）→ 10 持仓 e2e 准确率 ≥0.90 → M3 准出。

**tier-1 准出**：本机 + 本地 Redis（`redis://localhost:6379`）单测全绿 + `make watch-step07-test`。
**tier-2 / ★M3**：必须连接 `redis-svc.platform:6379`（prod.conn 环境变量 `REDIS_HOST` 指向 NodePort / ClusterIP）；真 10 持仓 stream 事件发布 + 准确率满足准出。

**扩展期**：watch Deployment 上 K3s + retry_worker sidecar；接 HPA；Redis Sentinel。

## §9 准出标准

- [ ] §3.5 15 项
- [ ] 10 持仓 e2e 准确率 ≥0.90；P95<30s
- [ ] `make watch-step07-all`；L4 回写（准确率、延迟、stream XLEN、schema diff）

## §10 [Deploy]

复用 watch Deployment；Deployment env 增 `EVENT_RETRY_INTERVAL=60`。

**P 轨中间件对齐（tier-2 / ★M3）**：
- Redis Stream：platform ns `redis-svc.platform:6379`（`diting-stack` chart 管理，P-step_03 ✅）；`REDIS_HOST` / `REDIS_PORT` 环境变量写入 ConfigMap；
- TimescaleDB：`timescaledb-svc.platform:5432` / NodePort 30001；`health_events` 表落 `diting-stack` PVC（独立数据盘）；
- `EVENT_RETRY_INTERVAL=60` 写入 `diting-stack` ConfigMap 或独立 ConfigMap；**不写死** Makefile / 脚本。

## §11 依赖

step_01~06；**P-step_03 `diting-stack` Up**（platform Redis + TimescaleDB）；D0/D4 schema 文档。

**严禁**：业务路径用 fixture 假事件；忽略 schema diff 上线。

## §12 风险与回退

| 触发 | 动作 |
|---|---|
| 准确率<0.90 | 回 step_06 调权重/阈值；超 2 次 ADR |
| 延迟>30s | 查 NLI 调用；启动期可异步队列 |
| schema 漂移 | 修后重跑；D0/D4 协同 |
| Redis 长期不可用 | 兜底表>100 告警；服务降级 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-25 | **P 轨基建对齐（回写）**：§8 改为 tier-1/P轨中间件双行表（platform Redis `redis-svc.platform:6379` + TimescaleDB；M3 链锁死）；§10 [Deploy] 补 Redis/DB ConfigMap 指向；§11 依赖加 P-step_03 `diting-stack` |
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 968 行嵌入；§3.5 15 项；no-mock；`watch-step07-*`；968→~310 行 |
| 2026-05-16 | 初版 968 行 |
