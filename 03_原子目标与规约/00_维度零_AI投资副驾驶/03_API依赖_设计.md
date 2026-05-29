# L3 · 前端工程与服务 · API 依赖与 BFF 设计

> [!NOTE] **[TRACEBACK]**
> - **同模块**：[02_组件分层与状态管理_设计](./02_组件分层与状态管理_设计.md)
> - **共享规约**：[05_接口抽象层规约](../_共享规约/05_接口抽象层规约.md)
> - **L2 主源**：[维度零·04_与5维度后端的契约](../../02_战略维度/00_维度零_AI投资副驾驶/04_与5维度后端的契约.md)（Stream 事件 schema 唯一权威）
> - **L2↔L3 映射**：[00_产品模块到L3模块的映射](../../02_战略维度/00_维度零_AI投资副驾驶/00_产品模块到L3模块的映射.md)

> [!IMPORTANT] **验证后资源释放（全模块强制）**
> 凡本文档涉及或引用的 **本地/联调验证**（单测、集成测、`docker compose`、前后端 dev server、`uvicorn`、临时 worker 等），在 **测试结论已确认并完成准出/实践记录** 后，须 **停止相关进程并释放资源**。检查项与示例命令见 [_共享规约/17_L3设计文档_验证后资源释放规约.md](../_共享规约/17_L3设计文档_验证后资源释放规约.md)。


## 一、章节定位

本章是 L3 前端工程的"**前端 ↔ 后端通讯契约**"权威规约，回答三个问题：

1. **前端通过哪些 BFF 调用 5 个 L3 后端模块**？
2. **5 个 L2 维度后端通过哪些 Redis Stream 事件流主动推送给前端**？
3. **延迟、SLO、限流、降级、版本兼容**如何保障？

> 本章相对于上一版的关键变化：BFF **按 product_module 重组**（而非旧 7 大场景）；新增"**Stream 订阅契约**"作为一等公民（与 REST 端点并列）；与 [维度零 04_后端契约](../../02_战略维度/00_维度零_AI投资副驾驶/04_与5维度后端的契约.md) 强一致。

## 二、BFF（Backend-for-Frontend）定位

前端**不直接**调用各业务模块（cryo_guard / deep_strike / state_watch / super_evo）；统一通过 **BFF 层**：

| 职责 | 说明 |
|------|------|
| 聚合 | 一次前端请求 → BFF 内并发调多模块 → 聚合返回 |
| 裁剪 | 仅返回前端需要的字段（防过度暴露） |
| 鉴权 | 校验用户身份 + 权限 + 数据范围（多用户隔离） |
| 限流 / 缓存 | 用户级 / IP 级限流；热点 API 边缘缓存 |
| 协议转换 | 内部 gRPC / Proto → 外部 REST / SSE / GraphQL |
| 灰度 / Feature Flag | 与超级个体进化的 version_manager 联动 |
| **Stream 中继**（新增） | 把 Redis Stream 转换为 SSE/WS 推送给浏览器 |

## 三、BFF 模块边界（按 product_module 重组）

```
bff/
├── dashboard-bff/         # product_module 1·持仓体检报告
├── subject-bff/           # product_module 2·推荐池与 thesis 卡（标的工作台）
├── chat-bff/              # product_module 2·投研对话（含 SSE 长连接）
├── risk-bff/              # product_module 1+3·风险面板共享
├── notification-bff/      # product_module 3·告警推送（多通道：微信/Telegram/Email/Voice）
├── ledger-bff/            # product_module 4·价值账本
├── memory-bff/            # product_module 4+回忆类·智能记忆栈
├── verified-bff/          # product_module 5·反馈闭环（阶段 2 启用）
├── autopilot-bff/         # 自动驾驶限额（阶段 3 启用）
├── admin-bff/             # 管理员（旧 S7 高阶视图保留）
└── shared/
    ├── auth/
    ├── feature-flags/
    ├── stream-relay/      # Redis Stream → SSE/WS 中继器
    └── api-clients/       # 调用各业务模块的内部客户端
```

> 注：所有 BFF **不直接连数据库**；只通过各业务模块对外的 gRPC / REST API。

## 四、各 product_module 的 REST 端点依赖

### 4.1 product_module 1·持仓体检（dashboard-bff）

| 前端调用 | 内部聚合 | 主要 L3 后端 service |
|---------|---------|---|
| `GET /bff/dashboard/today` | state_watch:`/v1/instances?status=ACTIVE&owner=me` + state_watch:`/v1/advisories?owner=me&status=pending` + cryo_guard:`/v1/risk-events?severity>=WARN&recent=24h&affected_owner=me` | template_instance_registry / advisory_generator / risk_event_bus |
| `GET /bff/dashboard/portfolio-health` | state_watch:`/v1/instances/health-score?owner=me` + 各持仓 SLI 健康度 | transition_evaluator / advisory_generator |
| `GET /bff/dashboard/rebalance-advice` | state_watch:`/v1/advisories?type=rebalance&owner=me` | advisory_generator |

### 4.2 product_module 2·推荐池（subject-bff + chat-bff）

| 前端调用 | 内部聚合 | 主要 L3 后端 service |
|---------|---------|---|
| `GET /bff/recommendation-pool` | deep_strike:`/v1/candidates?status=active&pass_gate=true` | candidate_registry |
| `GET /bff/thesis/{id}` | deep_strike:`/v1/research-cards/{id}` + `/v1/expectation-gaps?subject={id}` + content_comprehension:`/v1/comprehend/timeline?subject={id}` | research_council_service / expectation_gap_quantifier / content_comprehension_service |
| `GET /bff/thesis/{id}/evidence` | deep_strike:`/v1/research-cards/{id}/evidence` | candidate_registry / knowledge_base |
| `POST /bff/thesis/{id}/action` | deep_strike:`/v1/candidates/{id}/action`（accept/defer/reject）+ super_evo:`/v1/feedback/explicit` 写入 | candidate_registry / feedback_collector |
| `POST /bff/chat/sessions` | deep_strike:`/v1/sessions`（用户议题） | research_council_service |
| `GET /bff/chat/sessions/{id}/events` | **SSE 长连**：转发 deep_strike:`/v1/sessions/{id}/events` | research_council_service |

### 4.3 product_module 3·紧急告警（risk-bff + notification-bff）

| 前端调用 | 内部聚合 | 主要 L3 后端 service |
|---------|---------|---|
| `GET /bff/alerts/feed` | cryo_guard:`/v1/risk-events?recent=24h` + state_watch:`/v1/advisories?type=alert&owner=me` | risk_event_bus / notification_dispatcher |
| `GET /bff/alerts/{id}` | cryo_guard:`/v1/risk-events/{id}` + cryo_guard:`/v1/audit/entries?correlation_id={id}` | risk_event_bus / audit_log_service |
| `POST /bff/alerts/{id}/ack` | cryo_guard:`/v1/risk-events/{id}/ack` | risk_event_bus |
| `GET /bff/alerts/breakers` | cryo_guard:`/v1/breakers` | circuit_breaker |
| `GET /bff/notification/preferences` | super_evo:`/v1/profiles/{me}.preferences.notification` | user_profile_service |
| `PUT /bff/notification/preferences` | super_evo:`/v1/profiles/{me}` | user_profile_service |

### 4.4 product_module 4·价值账本（ledger-bff + memory-bff）

| 前端调用 | 内部聚合 | 主要 L3 后端 service |
|---------|---------|---|
| `GET /bff/ledger/decisions` | super_evo:`/v1/feedback/explicit?user=me` + 本地 SQLite `decision_log` | feedback_collector |
| `GET /bff/ledger/scs` | super_evo:`/v1/profiles/{me}.growth_metrics.scs` | user_profile_service |
| `GET /bff/ledger/ev` | super_evo:`/v1/profiles/{me}.growth_metrics.ev` + 用户输入的实际盈亏数据 | user_profile_service |
| `GET /bff/ledger/eight-quadrant` | super_evo:`/v1/retro/reports?user=me&type=eight_quadrant` | retrospective_service |
| `GET /bff/ledger/monthly-report` | super_evo:`/v1/retro/reports?scope=MONTHLY&user=me` | retrospective_service |
| `POST /bff/ledger/monthly-report/export` | super_evo:`/v1/retro/reports/{id}/export?format=pdf` | retrospective_service |
| `GET /bff/memory/knowledge` | super_evo:`/v1/knowledge/entries?owner=me` | knowledge_base |

### 4.5 product_module 5·反馈闭环（verified-bff，阶段 2 启用）

| 前端调用 | 内部聚合 | 主要 L3 后端 service |
|---------|---------|---|
| `GET /bff/verified/queue` | super_evo:`/v1/feedback/queue?type=verified&user=me` | feedback_collector |
| `POST /bff/verified/{id}/label` | super_evo:`/v1/feedback/explicit`（写入 verified 标注） | feedback_collector |
| `GET /bff/verified/double-blind/queue` | super_evo:`/v1/feedback/queue?type=double_blind&user=me` | feedback_collector |
| `POST /bff/verified/double-blind/{id}/label` | super_evo:`/v1/feedback/explicit`（写入双盲标注） | feedback_collector |
| `GET /bff/verified/kappa` | super_evo:`/v1/profiles/{me}.growth_metrics.kappa` + 历史趋势 | user_profile_service |
| `POST /bff/verified/dpo-pair` | super_evo:`/v1/feedback/dpo-pair`（构建 DPO 偏好对） | feedback_collector |

### 4.6 自动驾驶限额（autopilot-bff，阶段 3 启用）

| 前端调用 | 内部聚合 | 主要 L3 后端 service |
|---------|---------|---|
| `GET /bff/autopilot/limit` | super_evo:`/v1/profiles/{me}.preferences.autopilot_limit` | user_profile_service |
| `PUT /bff/autopilot/limit` | super_evo:`/v1/profiles/{me}` | user_profile_service |
| `GET /bff/autopilot/draft-orders` | super_evo:`/v1/external-actions?status=PENDING_GATE&user=me&kind=TRADE_ORDER` | external_action_boundary |
| `POST /bff/autopilot/draft-orders/{id}/approve` | super_evo:`/v1/external-actions/{id}/user-approve` | external_action_boundary |
| `POST /bff/autopilot/draft-orders/{id}/reject` | super_evo:`/v1/external-actions/{id}/user-reject` | external_action_boundary |

### 4.7 管理员驾驶舱（admin-bff，旧 S7 保留 + 议会管理新增）

| 前端调用 | 内部聚合 |
|---------|---------|
| `GET /bff/admin/templates` | state_watch:`/v1/templates`；super_evo:`/v1/versions/{type}/{id}` |
| `POST /bff/admin/templates/{id}/publish` | state_watch:`/v1/templates/{id}` PUT + super_evo:`/v1/versions/.../rollout` |
| `GET /bff/admin/eval/reports` | super_evo:`/v1/eval/reports` |
| `POST /bff/admin/versions/.../rollback` | super_evo:`/v1/versions/.../rollback`（强审计） |
| `GET /bff/admin/parliament-sessions` | deep_strike:`/v1/parliament/sessions`（阶段 3） |
| `GET /bff/admin/config` | 动态配置中心：聚合视图（仅授权） |

## 五、Redis Stream 订阅契约（一等公民）

> 完整 Stream schema 见 [维度零·04_与5维度后端的契约 §三、§四](../../02_战略维度/00_维度零_AI投资副驾驶/04_与5维度后端的契约.md)。

### 5.1 BFF 中继器（stream-relay）

```
浏览器 ←─SSE/WS─→ BFF.stream-relay ←─XREAD─→ Redis Streams
```

stream-relay 是 BFF 内的服务，负责：
- 维护用户级订阅（每个用户订阅自己 owner 的事件）
- 鉴权 + 数据隔离（注入 `owner=current_user`）
- 心跳 + 断线重连 + 消息序号去重
- Stream 退化为 SSE 时的格式转换（含 retry-after）

### 5.2 各 product_module 订阅的 Stream 清单

| product_module | 订阅的 Stream | 用途 |
|---|---|---|
| **01·持仓体检** | `events:cryo_guard:reject` | 实时显示新拒绝事件到 RiskFeed |
| **01·持仓体检** | `events:cryo_guard:degrade` | 在受影响组件上叠加 DegradedBadge |
| **01·持仓体检** | `events:monitor:health_change` | 4 色风险标记实时更新 |
| **01·持仓体检** | `events:monitor:rebalance_advice` | 调仓建议卡新增/更新 |
| **02·推荐池** | `events:thrust:thesis_proposed` | 推荐池新 thesis 卡推送 |
| **02·推荐池** | `events:thrust:thesis_evidence_updated` | 证据链增量更新 |
| **03·紧急告警** | `events:cryo_guard:reject`（severity>=critical） | 4 红告警弹窗 + 多通道推送 |
| **03·紧急告警** | `events:monitor:health_change`（status=broken） | broken 状态告警 |
| **03·紧急告警** | `events:exit:sell_signal` | 卖出建议告警 |
| **04·价值账本** | `events:flywheel:lora_updated` | 决策日志卡标记对应模型版本 |
| **05·反馈闭环** | （**写入**）`events:co_pilot:verified_dpo_pair_ready` | DPO 偏好对推送给 super_evo |
| **阶段 3·议会** | `events:parliament:decision_made` | 议会决议结果 |
| **阶段 3·自动驾驶** | `events:autopilot:order_drafted` | 待审批订单 |
| **阶段 3·自动驾驶** | `events:autopilot:anomaly` | 自动驾驶异常 |

### 5.3 SSE 端点（按 product_module 暴露给浏览器）

| 前端调用 | 中继的 Stream |
|---|---|
| `GET /bff/dashboard/stream` | events:cryo_guard:reject + degrade ; events:monitor:health_change + rebalance_advice |
| `GET /bff/research/stream` | events:thrust:thesis_proposed + thesis_evidence_updated |
| `GET /bff/alerts/stream` | events:cryo_guard:reject(critical) ; events:monitor:health_change(broken) ; events:exit:sell_signal |
| `GET /bff/ledger/stream` | events:flywheel:lora_updated |
| `GET /bff/parliament/stream` | events:parliament:decision_made（阶段 3） |
| `GET /bff/autopilot/stream` | events:autopilot:order_drafted ; events:autopilot:anomaly（阶段 3） |

### 5.4 Stream 事件 → 前端动作映射

```ts
// stream-client/src/router.ts
const streamRouter = {
  'events:cryo_guard:reject': (event) => {
    queryClient.setQueryData(['risk-feed'], (old) => prepend(old, event));
    if (event.severity === 'critical') {
      notificationService.popup(event);
      audioService.playAlertSound();
    }
  },
  'events:monitor:health_change': (event) => {
    queryClient.invalidateQueries(['portfolio-health']);
    if (event.status === 'broken') {
      notificationService.popup(event);
    }
  },
  'events:thrust:thesis_proposed': (event) => {
    queryClient.invalidateQueries(['recommendation-pool']);
    if (event.confidence >= 0.85) {
      toast.info(`新推荐：${event.subject_name}`);
    }
  },
  'events:exit:sell_signal': (event) => {
    queryClient.invalidateQueries(['portfolio-health']);
    notificationService.popup(event);
  },
  'events:flywheel:lora_updated': (event) => {
    queryClient.invalidateQueries(['ledger-decisions']);
  },
};
```

## 六、横切能力

### 6.1 鉴权
- 前端：登录 → BFF 颁发短期 Token（HttpOnly cookie + CSRF token）
- BFF → 业务模块：服务间用 mTLS + JWT（含用户上下文）
- Stream 订阅：BFF 在握手时校验 + 注入 owner=current_user

### 6.2 用户隔离
- BFF 强制 `owner=current_user` 注入；业务模块校验
- Stream 中继器按 user_id 过滤事件
- 跨用户聚合视图（如管理员）走 admin-bff，权限分级

### 6.3 限流
- 用户级：每用户每分钟 N 次（按 product_module 配置）
  - dashboard-bff: 300/min
  - subject-bff: 200/min
  - chat-bff: 60/min（高成本）
  - notification-bff: 30/min
  - ledger-bff: 60/min
  - verified-bff: 120/min
  - autopilot-bff: 60/min
- IP 级：每 IP 每秒 M 次
- 高成本 API（议会会话、RAG 大检索）：单独配额 + 排队

### 6.4 缓存
- 静态查询（模板列表 / 知识库元数据）：边缘缓存 30s~5min
- 用户敏感数据（自己的 instance / advisory）：仅短期内存缓存（≤ 10s）+ ETag
- Stream 实时数据：不缓存
- 月报 PDF：用户生成后缓存到 24h（CDN）

### 6.5 实时通道
- **SSE 优先**：服务端推送（议会进度、状态迁移、风险事件、调仓建议）
- **Stream → SSE 中继**：把 Redis Stream 持久化事件流推送给浏览器（替代直接 SSE 模型，更可靠）
- **WebSocket**：双向交互（投研对话台的高级模式 / 议会模式协作）
- 心跳 + 断线重连 + 消息序号去重

### 6.6 错误透明
- 业务模块返回的错误码（如 `CG.GATE_REJECTED`）BFF 透传 + 附 `display_hint`
- 前端按错误码显示对应 UI（拒绝详情卡 / 重试按钮 / 联系管理员）
- Stream 退化（partial=true）：UI 显示"实时数据降级"标记

## 七、版本兼容

- BFF 对前端暴露 `Accept-Version` header；多版本并存
- BFF 内部对业务模块的调用按业务模块的版本兼容策略（详见各模块 03_）
- Stream 事件 schema 版本（schema_version 字段）：BFF 中继器仅转发已知 schema_version；未知版本写入 dlq
- 重大破坏性变更走 ADR + 灰度

## 八、SLO（服务等级目标）

> 与 [维度零·04_后端契约 §六 SLO 与降级](../../02_战略维度/00_维度零_AI投资副驾驶/04_与5维度后端的契约.md) 强一致。

| 维度 | 目标 |
|------|------|
| BFF P50 延迟（聚合 ≤ 3 个内部调用） | < 200ms |
| BFF P99 延迟 | < 1s |
| BFF 可用性 | 99.9% |
| Stream → SSE 中继延迟（事件入 stream → 浏览器收到） | P50 < 500ms ; P99 < 2s |
| SSE 断线重连 | 自动；< 3s |
| 错误率（5xx） | < 0.1% |
| 4 红告警端到端延迟（reject 事件 → 微信/Telegram 推达） | P99 < 30s |

## 九、降级与灾备

| 后端模块降级 | BFF 行为 | 前端 UI 表现 |
|---|---|---|
| cryo_guard 不可用 | dashboard-bff/risk-bff 返回 503 + cached_risk_events | "极寒防御暂时不可用，显示最近 1h 缓存数据"+`<DegradedBadge>` |
| deep_strike 不可用 | subject-bff/chat-bff 返回 503 + cached_thesis_cards | "纵深进攻暂时不可用，显示最近缓存推荐"+`<DegradedBadge>` |
| state_watch 不可用 | dashboard-bff 返回 503 + cached_health_score | "持仓健康度暂时不可用"+`<DegradedBadge>` |
| super_evo 不可用 | ledger-bff/verified-bff 返回 503 ; 本地 SQLite 接管决策日志 | "进化飞轮暂时不可用，本地决策日志正常"+`<DegradedBadge>` |
| Redis Stream 中断 | stream-relay 退化为轮询（每 30s 拉一次）| "实时推送暂时不可用，已切换为定时刷新" |

## 十、与共享规约的对齐

| 共享规约 | 对齐点 |
|---------|--------|
| [04_全链路通信协议](../_共享规约/04_全链路通信协议矩阵.md) | BFF → 业务模块必带 `correlation_id` 透传；Stream 事件带 schema_version |
| [05_接口抽象层](../_共享规约/05_接口抽象层规约.md) | BFF 是 API Port 的一种实例 |
| [06_动态配置中心](../_共享规约/06_动态配置中心规约.md) | Feature flag / 限流配置 |
| [10_运营治理与灾备](../_共享规约/10_运营治理与灾备规约.md) | DR / 限流 / 审计 |

## 十一、修订记录

| 日期 | 触发 | 内容 |
|---|---|---|
| 2026-05-16 | 批 2·按 L2 维度零最新设计补全 L3 frontend | BFF 按 product_module 重组（dashboard-bff/subject-bff/chat-bff/risk-bff/notification-bff/ledger-bff/memory-bff/verified-bff/autopilot-bff）；新增 §五 Redis Stream 订阅契约（一等公民）；REST 端点表完全重写以贴合 5 product_modules；新增降级与灾备表（§九）；SLO 与维度零 04_后端契约强一致 |
