# Step 08 · `events:flywheel:lora_updated` 事件流

## §1 一句话定位与本步交付物

**一句话**：实现 **LoRAUpdatedPublisher**——step_07 灰度成功（status=prod）→ XADD `events:flywheel:lora_updated`（payload 与 DNA `output_event.fields` 一致：lora_name / version / old_version / metrics / improvement / trigger）；D1/D2/D3 消费者收到后**热载** vLLM 新 adapter；至少一次投递 + 兜底队列。

**交付物**（勾选 = 完成）：
- [ ] **A**（`LoRAUpdatedPayload`）：Pydantic v2；字段含 DNA 6 项 + `event_id / ts`
- [ ] **B**（`publisher`）：XADD + maxlen 1000；失败落 `failed_stream_publish` + 后台重试
- [ ] **C**（step_07 集成）：deploy stage 成功后调 publisher
- [ ] **D**（schema 文档）：`docs/schemas/flywheel_lora_updated.md`（消费者契约）
- [ ] **E**（消费者参考实现）：`apps/super_evo/events/test_consumer.py`（dev 用，验证 stream 可消费）
- [ ] **F**（监控）：XLEN + per-consumer-group lag（可选 prometheus）
- [ ] **G**（Makefile）：`make evo-step08-all`

> **永久规则**：未经 step_07 manual_gate 的 adapter **不得**进 stream；payload 必须含 baseline 对比 metrics。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §五 事件流
> - **DNA**：`output_event.stream/fields`
> - **共享**：[13_六维度启动期集成与时序](../../../../_共享规约/13_六维度启动期集成与时序.md) §四
> - **L4**：[实践记录_step_08_lora_updated事件流.md](../../../../../04_阶段规划与实践/05_维度五_演进飞轮/stage_1_启动期/实践记录_step_08_lora_updated事件流.md)
> - **下游消费**：D1/D2/D3 各服务热载 LoRA

## §3 数据采集对象 / 落库映射

| 流向 | 表/流 |
|---|---|
| 发布事件 | Redis `events:flywheel:lora_updated` |
| 兜底 | `failed_stream_publish(stream_key, payload, retried_at)` |
| 监控 | XLEN + lag |

## §3.5 数据质量验收矩阵（事件流 · 仅启动期）

### §3.5.1 payload 与契约

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| P1 | **stream 名** | `events:flywheel:lora_updated` 与 DNA + 13_ 一致 | ✅ 常量 | — |
| P2 | **6 必填 + 2 元** | lora_name / version / old_version / metrics / improvement / trigger + event_id + ts | ✅ Pydantic | 缺字段不发 |
| P3 | **schema 文档** | 消费者参考；版本号 v1 | ✅ md | — |
| P4 | **improvement 公式** | per-metric delta；明确正负号 | ✅ 单测 | — |

### §3.5.2 投递

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| D1 | **at-least-once** | XADD 失败落兜底 + 重试 | ✅ 最小 worker | — |
| D2 | **maxlen 1000** | 启动期足够 | ✅ | — |
| D3 | **consumer group 文档** | 各维 group 名（d1_lora_hotreload 等）13_ §四 | ✅ | — |
| D4 | **XLEN 监控** | 启动期可读 cli | ✅ | — |

### §3.5.3 no-mock

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| N1 | **生产路径无 mock 事件** | publisher 仅由 step_07 deploy 成功调用 | ✅ | tests/ 例外 |
| N2 | **未签字 adapter 不发** | publisher pre-check status=prod | ✅ | — |
| N3 | **真 Redis 验收** | `make all` 不接 fakeredis | ✅ | — |

> 共 **11 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| `REDIS_URL` | XADD |
| step_07 deploy stage 成功 | 发起前置 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 至少 1 条真事件 | XLEN ≥1 |
| schema 校验通过 | 100% |
| 单测 | ≥6 |

## §6 下一步

本步 ✅ → step_09 首次 LoRA 训练联调 D1。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A payload schema** | `events/schemas.py` | Pydantic + UUID + ts | 单测 |
| **B publisher** | `events/lora_updated_publisher.py` | XADD + maxlen | mock fail |
| **C 兜底 ORM + worker** | `db/models.py` + `events/retry_worker.py` | 同 D1/D2 模式 | 单测 |
| **D step_07 hook** | `deployment/release_pipeline.py` deploy 成功后 call | publisher | e2e |
| **E schema 文档** | `docs/schemas/flywheel_lora_updated.md` | v1 草案 | md 渲染 |
| **F dev consumer** | `events/test_consumer.py` | XREADGROUP test | 1 条 |
| **G XLEN status API** | `api/routes/events.py` | 200 | curl |
| **H 单测** | `test_lora_updated_publisher.py` | ≥6 | pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `evo-step08-prep` | step_07 完成；Redis OK |
| `evo-step08-publish-once` | 一条真实 publish；XLEN +1 |
| `evo-step08-schema` | publisher 校验 + dev consumer 解码 |
| `evo-step08-retry-sim` | mock redis fail → 兜底表 +1 → 恢复后重试成功 |
| `evo-step08-test` | pytest ≥6 |
| `evo-step08-all` | 端到端 |
| `evo-step08-status` | XLEN + 兜底队列 + 最近 lora_version |
| `evo-step08-clean` | dev FORCE=1 重置 stream |

### §7.3 指引

先 payload→publisher→step_07 hook→消费者文档→兜底；XLEN 用作最简监控；下游各维消费者契约文字化在 schema md。

## §8 部署节奏

本机 + 真 Redis；扩展期统一进 ACR 镜像。

## §9 准出标准

- [ ] §3.5 11 项；XLEN ≥1 + schema 解码 OK + 兜底演练通过
- [ ] `make evo-step08-all`；L4 回写（XLEN、event_id、improvement）

## §10 [Deploy]

ConfigMap 增 `STREAM_MAXLEN=1000`、`RETRY_INTERVAL_SEC=60`。

## §11 依赖

step_07 deploy；Redis；下游消费者约定。

**严禁**：未签字 adapter 发；mock 事件进生产 stream。

## §12 风险

| 触发 | 动作 |
|---|---|
| Redis 长断 | 兜底+告警 ≥100 |
| schema 漂移 | bump v2 + 通知消费者 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 820 行嵌入 Python；§3.5 11 项；no-mock；`evo-step08-*`；820→~180 行 |
| 2026-05-16 | 初版 820 行 |
