# Step 09 · 端到端联调（PassEvent 消费 + D0 推送）

## §1 一句话定位与本步交付物

**一句话**：实现 **PassEventConsumer** 订阅 D1 `events:cryo_guard:pass`，触发 profit_capture 扫描 → thesis 生成（**永远** `status=proposed`）→ 架构师经 step_08 confirm → `events:thrust:thesis_proposed`；验证全链路 SLO（扫描+生成 ≤5min）与 D0 schema 100% 对齐。

**交付物**（勾选 = 完成）：
- [ ] **A**（`PassEventConsumer`）：consumer group `deep-strike-pass`；`XREADGROUP` → scan → generate → `event_logs` 审计
- [ ] **B**（`EventLog` 表）：stream_key/msg_id/payload/handled/error；幂等 UniqueConstraint
- [ ] **C**（服务集成）：`DEEP_STRIKE_AUTO_CONSUMER=true` 时 main 启动 consumer
- [ ] **D**（状态 API）：`GET /api/consumer/status` 最近 N 条 PassEvent 处理记录
- [ ] **E**（e2e 测试）：≥8 用例；生产路径**真实** Redis pass 或 staging 真流
- [ ] **F**（TEST_ONLY 注入）：`tests/fixtures/inject_pass_event.py` **仅** tests/；**禁止**进入业务 Makefile 默认路径
- [ ] **G**（Makefile）：`make deep-step09-all`

> **永久规则**：PassEvent 触发的自动生成**不得**跳过 HumanGate 直达 confirmed。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md)、[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md) §4.1 事件可被 D0 消费
> - **DNA**：`dependencies.upstream`、`exit_criteria[3]`
> - **共享**：[13_六维度启动期集成与时序](../../../../_共享规约/13_六维度启动期集成与时序.md) §三场景 A（≤5min）
> - **D1 产出**：`events:cryo_guard:pass`（cryo_guard step_08）
> - **D0**：[step_04_推荐池](../../../../00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_04_推荐池模块.md) `ThesisProposedPayload`
> - **L4**：[实践记录_step_09_端到端联调.md](../../../../../04_阶段规划与实践/02_维度二_纵深进攻/stage_1_启动期/实践记录_step_09_端到端联调.md)
> - **上游**：step_01~08；**下游**：step_10

## §3 数据采集对象 / 落库映射

| 事件 | 处理 | 落库 |
|---|---|---|
| `events:cryo_guard:pass` | consumer 拉取 | `event_logs` + 触发 scan/thesis |
| 生成 thesis | ThesisGenerator | `thesis_cards` proposed |
| confirm 后 | publisher（step_08）| `events:thrust:thesis_proposed` |

## §3.5 数据质量验收矩阵（端到端 · 仅启动期）

### §3.5.1 Pass 消费质量

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **consumer group 幂等** | 重复启动不重复建 group 报错 | ✅ MKSTREAM 可选 | — |
| E2 | **payload 解码** | symbol/pass_event_id/audit_id 必填 | ✅ | 缺字段 ack+error 日志 |
| E3 | **handled 幂等** | 同 msg_id 不重复 scan | ✅ uq(stream,msg_id) | — |
| E4 | **失败可观测** | error 列 + 不 silent drop | ✅ | — |
| E5 | **5min SLO** | pass→thesis 落库 P95 ≤300s（真数据）| ⚠️ 依赖 D1 真 pass | 超时告警+event_log |

### §3.5.2 永久规则链路

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| R1 | **自动生成仅 proposed** | consumer 路径无 confirmed | ✅ e2e 断言 | — |
| R2 | **confirm 后才推送** | e2e：confirm 前后 XLEN 差 ≥1 | ✅ | D0 未起则 stream 自检 |
| R3 | **无 auto confirm** | consumer 不调 HumanGate.confirm | ✅ | — |

### §3.5.3 D0 契约

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| S1 | **schema field diff** | `schema_check_d0.py` = 0 | ⚠️ 与 step_05 共用脚本 | 漂移修后再 e2e |
| S2 | **pass_event_id 回填** | 来自 pass payload audit_id | ✅ | — |
| S3 | **5 必填完整** | e2e 推送 payload 全绿 | ✅ completeness | — |

### §3.5.4 no-mock-policy

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| N1 | **生产 Makefile 无 inject_mock** | `deep-step09-all` 用真 pass 或跳过并文档说明 | ✅ | D1 未就绪：准出阻塞+「待 cryo pass 真流」|
| N2 | **tests 注入标注 TEST_ONLY** | `tests/` 内 fixture 文件名含 TEST_ONLY | ✅ | 不得写业务库训练集 |
| N3 | **禁止 THESIS_GENERATOR_MODE=stub** | e2e 与 make all 不得设 stub | ✅ runtime guard | — |

> 共 **14 项**。

## §4 凭证清单

| 凭证 | 用途 | 何时 |
|---|---|---|
| `REDIS_URL` | 消费 pass + 推送 thrust | 必须 |
| D1 `events:cryo_guard:pass` 有真消息 | e2e 主路径 | D1 step_08 ✅ 后 |
| 架构师 confirm token | e2e 后半段 | step_08 |

> D1 未就绪：**不得**用 mock 冒充准出；L4 记「阻塞：待 pass 真流」。

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| e2e 用例 | ≥8 passed |
| pass→proposed 时延 | ≤5min（DNA/13_）|
| schema diff | 0 |

## §6 下一步

本步 ✅ → step_10 阶段验收脚本。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A EventLog ORM** | `db/models.py` | §3 字段 + 唯一约束 | migration |
| **B PassEventConsumer** | `events/consumer.py` | asyncio 后台；阻塞 XREADGROUP | 1 条真 pass |
| **C 编排** | consumer 内调 playbook+generator | 仅 proposed | e2e |
| **D main 开关** | `main.py` | `DEEP_STRIKE_AUTO_CONSUMER` | 启停 |
| **E status API** | `api/routes/consumer.py` | 最近 N event_logs | 200 |
| **F e2e** | `test_e2e_workflow.py` | 8 场景含 schema+SLO | pytest |
| **G TEST_ONLY fixture** | `tests/fixtures/inject_pass_event.py` | 仅 pytest 调用 | CI 不含于 make all |
| **H 超时告警** | consumer | >300s logger.warning | 日志 |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `deep-step09-prep` | Redis + D1 pass stream 存在或显式 BLOCKED |
| `deep-step09-consumer-up` | 启服务+consumer |
| `deep-step09-e2e-real` | 真 pass 或文档 BLOCKED | proposed+confirm+stream |
| `deep-step09-schema` | schema_check diff=0 |
| `deep-step09-slo` | 单条耗时日志 ≤300s |
| `deep-step09-test` | pytest e2e ≥8 |
| `deep-step09-all` | 非 BLOCKED 时全绿 |
| `deep-step09-status` | event_logs 计数 + XLEN 两 stream |

### §7.3 指引

先 EventLog→Consumer→e2e；**生产** `deep-step09-all` 不接 mock 脚本；D1 阻塞时 honesty 写 L4 不伪造通过。

## §8 部署节奏

本机/deep-strike Pod + Redis；consumer 与 API 同进程（启动期）。

## §9 准出标准

- [ ] §3.5 14 项；8 e2e passed
- [ ] 真 pass 路径跑通 **或** L4 明示 BLOCKED+已执行 tests TEST_ONLY
- [ ] `make deep-step09-all`（无 stub）；L4 回写（时延、XLEN、schema）

## §10 [Deploy]

无新 workload；Deployment env 增 `DEEP_STRIKE_AUTO_CONSUMER=true`（可选）。

## §11 依赖

step_08；D1 pass stream；Redis。

**严禁**：`inject_mock_pass_event.py` 进 `deep-step09-all`；stub 生成 thesis 准出。

## §12 风险

| 触发 | 动作 |
|---|---|
| D1 无 pass | BLOCKED；仅 tests 注入 |
| SLO 超时 | 查 scan/LLM；缩 active |
| schema 漂移 | 对齐 D0 后重跑 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 942 行代码；mock 仅 tests TEST_ONLY；§3.5 14 项；no-mock；942→~300 行 |
| 2026-05-16 | 初版含 `inject_mock_pass_event` 默认可执行路径 |
