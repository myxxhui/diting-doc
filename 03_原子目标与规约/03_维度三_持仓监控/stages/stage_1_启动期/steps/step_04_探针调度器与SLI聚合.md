# Step 04 · ProbeScheduler 统一调度 + SLI 加权聚合

## §1 一句话定位与本步交付物

**一句话**：把 step_02/03 的 P1~P4 探针统一管理——**ProbeScheduler**（APScheduler，按 DNA 间隔触发、失败重试、Redis 心跳）+ **SLI 聚合器**（4 类 metric 阈值评分 + 加权融合 → `sli_score ∈ [0,100]`）+ `node_sli_values` 表（INSERT-only history + upsert latest）。

**交付物**（勾选 = 完成）：
- [ ] **A**（`ProbeScheduler`）：注册 P1~P4；CronTrigger/IntervalTrigger；失败重试 3 次
- [ ] **B**（`heartbeat`）：每次 job 写 Redis 心跳（key `probe:hb:{probe_id}:{symbol}`）+ 同步 `state_watch.db`
- [ ] **C**（`SLIAggregator`）：纯函数；按 metric 阈值表评分（命中→100，90% 边缘→60，临界→30，违反→0）；加权融合
- [ ] **D**（`NodeSLIValue` ORM）：`(node_id, metric, value, score, source, recorded_at)`；索引 (node_id, metric)
- [ ] **E**（API）：`POST /api/probes/{node_id}/trigger`（手动一次性触发四类）；`GET /api/probes/{node_id}/status`（最近 N 次心跳 + score）
- [ ] **F**（单测）：≥10 aggregator + ≥6 scheduler（mock clock，不真实 sleep）
- [ ] **G**（Makefile）：`make watch-step04-all`

> **依赖**：step_02 P1/P2、step_03 P3/P4；step_01 holdings_state 已注册。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §3.2 `_calc_sli_score`、[../03_数据采集与预处理.md](../03_数据采集与预处理.md) §3.2
> - **DNA**：`deliverables.sli_probes` 全部 4 项的 interval_hours + 评分逻辑
> - **L4**：[实践记录_step_04_探针调度器与SLI聚合.md](../../../../../04_阶段规划与实践/03_维度三_持仓监控/stage_1_启动期/实践记录_step_04_探针调度器与SLI聚合.md)
> - **上游**：step_01~03；**下游**：step_06 健康度（消费 sli_score）

## §3 数据采集对象 / 落库映射

| 流向 | 落库 |
|---|---|
| 每次 probe.fetch | `node_sli_values`（INSERT-only history）+ `latest_metric_view`（视图或覆写表）|
| 心跳 | Redis `probe:hb:*` + `probe_heartbeats`（可选）|
| SLI 聚合 | `health_records.sli_score` 在 step_06 写入；本步函数返结果 |

## §3.5 数据质量验收矩阵（调度与聚合 · 仅启动期）

### §3.5.1 调度质量

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| C1 | **DNA 间隔一致** | P1=24h CronHour9；P2=1h；P3=0.5h（交易时段）；P4=6h | ✅ | DNA 修改→改 yaml 不改代码 |
| C2 | **失败重试** | 3 次指数退避；on_failure 写日志 | ✅ | — |
| C3 | **心跳新鲜度** | Redis hb key TTL=2×间隔；超时标 stale | ✅ | Redis 不可用→落 SQLite |
| C4 | **misfire 处理** | misfire_grace_time=600s；漏触发不积压 | ✅ | — |
| C5 | **mock-clock test** | 单测用 freezegun 不真实 sleep | ✅ | — |

### §3.5.2 聚合质量

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| A1 | **per-metric score** | 命中 100 / 90% 60 / 临界 30 / 违反 0 / null 50 | ✅ pure function | yaml 阈值表 |
| A2 | **per-probe weight** | P1=0.30 / P2=0.20 / P3=0.30 / P4=0.20（可 yaml）| ✅ | weights yaml |
| A3 | **加权可复现** | 单测手算与函数一致 | ✅ | — |
| A4 | **缺探针降级** | 某 probe 全 metric null → 仅按其他 probe 加权 | ✅ | weights 重归一 |
| A5 | **sli_score 范围** | 0~100 | ✅ assert | clip |

### §3.5.3 工程

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **only active** | scheduler 范围=SoT active | ✅ | — |
| E2 | **NodeSLIValue idempotent** | (node, metric, day_or_window) upsert latest；history append | ✅ | — |
| E3 | **API status** | 最近 10 次心跳 + sli_score 当前值 | ✅ | — |
| E4 | **no-stub** | scheduler 路径不写假心跳 | ✅ | — |

> 共 **14 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| `REDIS_URL` | 心跳；不可用走 SQLite 降级 |
| `DATABASE_URL` | NodeSLIValue |
| `PROBE_WEIGHTS_YAML` | 阈值与权重 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 4 探针均按 DNA 间隔触发 | ✅ |
| sli_score 计算可复现 | 单测全过 |
| 心跳上报成功率 | ≥99% Redis 可达 |

## §6 下一步

本步 ✅ → step_05 NLI LoRA。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A NodeSLIValue ORM** | `db/models.py` + alembic | 字段 §3；索引 (node, metric, recorded_at) | migration |
| **B ProbeScheduler** | `probes/scheduler.py` | APScheduler + DNA 注入；on_failure | mock test |
| **C heartbeat** | `probes/heartbeat.py` | Redis SETEX；SQLite fallback | TTL OK |
| **D weights/thresholds yaml** | `configs/probe_aggregator.yaml` | 评分阈值 + weights | 解析 |
| **E SLIAggregator** | `health/sli_aggregator.py` | 纯函数；输入 metric list → score | 手算 10 |
| **F API routes** | `api/routes/probes.py` | trigger + status | 200 |
| **G CLI** | `scheduler.py` `__main__` | `--start / --once` | 启动 OK |
| **H 单测** | `test_sli_aggregator.py` / `test_scheduler.py` | ≥16 合计 | pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `watch-step04-prep` | NodeSLIValue 表在；yaml OK |
| `watch-step04-migrate` | alembic head |
| `watch-step04-scheduler-up` | start +5s 后看心跳 |
| `watch-step04-once-all` | 4 探针各 1 次；NodeSLIValue +N 行 |
| `watch-step04-aggregate` | 全 active 调 aggregator；输出 sli_score |
| `watch-step04-test` | pytest ≥16 |
| `watch-step04-all` | migrate+once+aggregate+test |
| `watch-step04-status` | 心跳新鲜度 + sli_score 表 |
| `watch-step04-clean` | dev only FORCE=1 |

### §7.3 指引

先 ORM→aggregator 纯函数→scheduler→API；mock-clock 测试调度；权重&阈值放 yaml 可调。

## §8 部署节奏

本机 + Redis；K3s 扩展期。

## §9 准出标准

- [ ] §3.5 14 项；4 探针按 DNA 间隔实跑
- [ ] sli_score 每 active 标的当前值有
- [ ] `make watch-step04-all`；L4 回写（心跳率、sli_score 分布）

## §10 [Deploy]

启动期单进程；扩展期 scheduler 独立 Pod。

## §11 依赖

step_01~03；Redis（软）；SoT。

**严禁**：scheduler 假心跳；硬编码阈值。

## §12 风险

| 触发 | 动作 |
|---|---|
| Redis 不可用 | SQLite fallback；告警 |
| misfire 频繁 | 调 grace_time；查源延迟 |
| 阈值频繁改 | 改 yaml 不改代码 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 881 行 Python；§3.5 14 项；`watch-step04-*`；881→~260 行 |
| 2026-05-16 | 初版 881 行 |
