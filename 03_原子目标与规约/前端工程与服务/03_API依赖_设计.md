# L3 · 前端工程与服务 · API 依赖与 BFF 设计

> [!NOTE] **[TRACEBACK]**
> - **同模块**：[02_组件分层与状态管理_设计](./02_组件分层与状态管理_设计.md)
> - **共享规约**：[05_接口抽象层规约](../_共享规约/05_接口抽象层规约.md)

## 一、BFF（Backend-for-Frontend）定位

前端**不直接**调用各业务模块（极寒防御 / 纵深进攻 / 状态机监控 / 超级个体进化）；统一通过 **BFF 层**：

| 职责 | 说明 |
|------|------|
| 聚合 | 一次前端请求 → BFF 内并发调多模块 → 聚合返回 |
| 裁剪 | 仅返回前端需要的字段（防过度暴露） |
| 鉴权 | 校验用户身份 + 权限 + 数据范围（多用户隔离） |
| 限流 / 缓存 | 用户级 / IP 级限流；热点 API 边缘缓存 |
| 协议转换 | 内部 gRPC / Proto → 外部 REST / SSE / GraphQL（按需）|
| 灰度 / Feature Flag | 与超级个体进化的 version_manager 联动 |

## 二、BFF 模块边界（按场景拆分）

```
bff/
├── dashboard-bff/         # S1 个性化驾驶舱
├── subject-bff/           # S2 标的工作台
├── chat-bff/              # S3 投研对话台（含 SSE 长连接）
├── watchlist-bff/         # S4 关注列表中心
├── risk-bff/              # S5 风险熔断面板
├── memory-bff/            # S6 智能记忆栈
├── admin-bff/             # S7 管理员驾驶舱
└── shared/
    ├── auth/
    ├── feature-flags/
    └── api-clients/       # 调用各业务模块的内部客户端
```

> 注：所有 BFF **不直接连数据库**；只通过各业务模块对外的 gRPC / REST API。

## 三、各场景的核心 API 依赖

### 3.1 S1 驾驶舱（dashboard-bff）

| 前端调用 | 内部聚合 |
|---------|---------|
| `GET /bff/dashboard/today` | 状态机监控：`/v1/instances?status=ACTIVE&owner=me` + 最近迁移 + 未读 Advisory；纵深进攻：`/v1/candidates?status=active&owner=me`；超级个体进化：`/v1/feedback/impact?user=me`；极寒防御：`/v1/risk-events?severity>=WARN&recent=24h&affected_owner=me` |
| `GET /bff/dashboard/notifications` | 状态机监控：`/v1/advisories?owner=me&status=pending` |

### 3.2 S2 标的工作台（subject-bff）

| 前端调用 | 内部聚合 |
|---------|---------|
| `GET /bff/subject/{id}` | 状态机监控：`/v1/instances?subject={id}`；纵深进攻：`/v1/research-cards?subject={id}` + `/v1/expectation-gaps?subject={id}`；数据层：标的元数据 + 主营 segment |
| `GET /bff/subject/{id}/timeline` | 内容理解：`/v1/comprehend/timeline?subject={id}` |
| `POST /bff/subject/{id}/agenda` | 纵深进攻：`/v1/agenda/topics`（user 来源） |

### 3.3 S3 投研对话台（chat-bff）

| 前端调用 | 内部聚合 |
|---------|---------|
| `POST /bff/chat/sessions` | 纵深进攻：`/v1/sessions`（用户议题） |
| `GET /bff/chat/sessions/{id}/events` | SSE 长连：转发 `/v1/sessions/{id}/events`；过滤敏感字段 |
| `POST /bff/chat/messages` | 在 session 内追问 → agenda topic |

### 3.4 S4 关注列表中心（watchlist-bff）

| 前端调用 | 内部聚合 |
|---------|---------|
| `GET /bff/watchlists` | 状态机监控：`/v1/watchlists` |
| `GET /bff/watchlists/{id}/states` | 状态机监控：`/v1/watchlists/{id}/states` |
| `POST /bff/watchlists/{id}/items` | 状态机监控：`/v1/watchlists/{id}/items` + 自动拉起实例（如未存在） |
| `GET /bff/watchlists/{id}/stream` | SSE 长连：转发实例状态变化 |

### 3.5 S5 风险熔断面板（risk-bff）

| 前端调用 | 内部聚合 |
|---------|---------|
| `GET /bff/risk/feed` | 极寒防御：`/v1/risk-events?recent=24h` |
| `GET /bff/risk/breakers` | 极寒防御：`/v1/breakers` |
| `GET /bff/risk/audit/{decision_id}` | 极寒防御：`/v1/audit/entries?decision_id={id}` + `/v1/gate/decisions/{id}` |
| `POST /bff/risk/breakers/{service}/reset` | 极寒防御：`/v1/breakers/{service}/reset`（高权限） |

### 3.6 S6 智能记忆栈（memory-bff）

| 前端调用 | 内部聚合 |
|---------|---------|
| `GET /bff/memory/knowledge` | 超级个体进化：`/v1/knowledge/entries?owner=me` |
| `POST /bff/memory/knowledge/{id}/feedback` | 超级个体进化：`/v1/knowledge/entries/{id}/feedback` |
| `GET /bff/memory/retro` | 超级个体进化：`/v1/retro/reports?user=me` |
| `GET /bff/memory/profile` | 超级个体进化：`/v1/profiles/{me}` |
| `POST /bff/memory/profile/export` | 超级个体进化：`/v1/profiles/{me}/export` |

### 3.7 S7 管理员驾驶舱（admin-bff）

| 前端调用 | 内部聚合 |
|---------|---------|
| `GET /bff/admin/templates` | 状态机监控：`/v1/templates`；超级个体进化：`/v1/versions/{type}/{id}` |
| `POST /bff/admin/templates/{id}/publish` | 状态机监控：`/v1/templates/{id}` PUT + 超级个体进化：`/v1/versions/.../rollout` |
| `GET /bff/admin/eval/reports` | 超级个体进化：`/v1/eval/reports` |
| `POST /bff/admin/versions/.../rollback` | 超级个体进化：`/v1/versions/.../rollback`（强审计） |
| `GET /bff/admin/config` | 动态配置中心：聚合视图（仅授权） |

## 四、横切能力

### 4.1 鉴权
- 前端：登录 → BFF 颁发短期 Token（HttpOnly cookie + CSRF token）
- BFF → 业务模块：服务间用 mTLS + JWT（含用户上下文）

### 4.2 用户隔离
- BFF 强制 `owner=current_user` 注入；业务模块校验
- 跨用户聚合视图（如管理员）走 admin-bff，权限分级

### 4.3 限流
- 用户级：每用户每分钟 N 次（按场景配置）
- IP 级：每 IP 每秒 M 次
- 高成本 API（议会会话、RAG 大检索）：单独配额 + 排队

### 4.4 缓存
- 静态查询（模板列表 / 知识库元数据）：边缘缓存 30s~5min
- 用户敏感数据（自己的 instance / advisory）：仅短期内存缓存（≤ 10s）+ ETag
- SSE 实时数据：不缓存

### 4.5 实时通道
- **SSE 优先**：服务端推送（议会进度、状态迁移、风险事件）
- **WebSocket**：双向交互（投研对话台的高级模式 / 协作）
- 心跳 + 断线重连 + 消息序号去重

### 4.6 错误透明
- 业务模块返回的错误码（如 `CG.GATE_REJECTED`）BFF 透传 + 附 `display_hint`
- 前端按错误码显示对应 UI（拒绝详情卡 / 重试按钮 / 联系管理员）

## 五、版本兼容

- BFF 对前端暴露 `Accept-Version` header；多版本并存
- BFF 内部对业务模块的调用按业务模块的版本兼容策略（详见各模块 03_）
- 重大破坏性变更走 ADR + 灰度

## 六、SLO（服务等级目标）

| 维度 | 目标 |
|------|------|
| BFF P50 延迟（聚合 ≤ 3 个内部调用） | < 200ms |
| BFF P99 延迟 | < 1s |
| BFF 可用性 | 99.9% |
| SSE 断线重连 | 自动；< 3s |
| 错误率（5xx） | < 0.1% |

## 七、与共享规约的对齐

| 共享规约 | 对齐点 |
|---------|--------|
| [04_全链路通信协议](../_共享规约/04_全链路通信协议矩阵.md) | BFF → 业务模块必带 `correlation_id` 透传 |
| [05_接口抽象层](../_共享规约/05_接口抽象层规约.md) | BFF 是 API Port 的一种实例 |
| [06_动态配置中心](../_共享规约/06_动态配置中心规约.md) | Feature flag / 限流配置 |
| [10_运营治理与灾备](../_共享规约/10_运营治理与灾备规约.md) | DR / 限流 / 审计 |
