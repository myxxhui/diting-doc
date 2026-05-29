# Step 03 · M1 持仓体检模块（4 色卡片 + 详情页 + 30 天曲线 + health_change 消费组）（v3 细化融合版）

## §1 一句话定位与本步交付物

**一句话**：实现 **M1 持仓体检** —— 在 `apps/copilot/` 上构建 ① 新表 `health_records`（落库 D3 `events:monitor:health_change` 全字段，按 `event_id` 幂等）、② `EventConsumer`（XREADGROUP，消费组 `copilot_group`，处理 `BUSYGROUP` 异常）、③ `HealthCheckService`（push_level → 4 色映射、dashboard 聚合、detail 30d 历史）、④ 4 路由（2 个 JSON API + 2 个 HTML 页面）、⑤ 模板（dashboard 4 色卡片 + detail 节点 4 态 + 30 天 sparkline）、⑥ 13+ 用例 + Mock 注入脚本。让用户**第一天就能在 `/health-dashboard` 看到自己持仓的健康状态**。

**交付物**（勾选 = 完成）：

- [ ] **A**（新表 `health_records`）：在 step_02 的 4 表基础上**追加** `apps/copilot/db/models.py::HealthRecord`，含 `id / event_id UNIQUE / symbol / push_level / health_score / narrative_label / state / source_data JSON / received_at`
- [ ] **B**（`EventConsumer`）：`apps/copilot/events/consumer.py`，类 `HealthChangeConsumer`；XREADGROUP `events:monitor:health_change` consumer group `copilot_group`、consumer 名 `copilot-1`；首次启动用 `XGROUP CREATE ... MKSTREAM`，吞掉 `BUSYGROUP Consumer Group name already exists`（`redis.exceptions.ResponseError`）；处理函数同时写 `event_logs` + `health_records`；按 `event_id` 幂等（重复消息忽略）；XACK 后 commit
- [ ] **C**（`HealthCheckService`）：`apps/copilot/modules/health_check/service.py`，含
  - `push_level_to_color(level: int) -> str`：0/-1/-2... → green；1 → yellow；2 → orange；≥3 → red
  - `get_dashboard() -> dict`：聚合所有 active 标的的最新 `HealthRecord`，按颜色分组；返回 `{cards: {green/yellow/orange/red: [Card]}, summary: {total/green/yellow/orange/red}}`
  - `get_detail(symbol: str) -> dict`：单标的最新 record + 最近 30 天历史（按 `received_at` desc，limit 30）
- [ ] **D**（4 路由）：`apps/copilot/routers/health_routes.py`
  - `GET /api/health/dashboard` → JSON
  - `GET /api/health/{symbol}` → JSON
  - `GET /health-dashboard` → HTML（4 色卡片 grid）
  - `GET /health-detail/{symbol}` → HTML（节点 4 态 + sparkline + 历史表）
- [ ] **E**（模板）：`apps/copilot/templates/health/{dashboard.html, detail.html}` + `partials/health_card.html`；HTMX 30s 自动轮询 `/api/health/dashboard`；Chart.js（CDN）或纯 SVG sparkline
- [ ] **F**（main.py 接入）：`include_router(health_routes.router)`；导航增"持仓体检"链接；lifespan 启动 consumer task（`asyncio.create_task(HealthChangeConsumer().run())`）
- [ ] **G**（无 D3 时降级）：D3 step_07 未启动 → `health_change` stream 无消息 → dashboard 显示"等待 D3 健康度引擎"占位卡片；**禁止**伪造健康度数据
- [ ] **H**（Mock 注入工具 · 仅启动期联调）：`scripts/inject_mock_health_change.py {symbol} {health_score} {push_level}` → `XADD events:monitor:health_change ...`；**注**：本工具仅供 step_03~05 联调；step_09 全链路前必须 gated 或删除（违反 no-mock-policy）
- [ ] **I**（单测）：≥ 13 用例
  - `test_color_mapping`（参数化 0/1/2/3/5/-1 → green/yellow/orange/red/red/green）×6
  - `test_dashboard_groups_by_color`
  - `test_detail_returns_history`
  - `test_api_dashboard_endpoint`（JSON 结构 `cards/summary`）
  - `test_dashboard_html_renders`（HTML 含"持仓体检"）
  - `test_health_returns_ok`（step_01 回归）
  - `test_handler_writes_two_tables`（consumer handler 同时写 `event_logs` + `health_records`）
  - `test_handler_idempotent_on_same_event_id`（同 event_id 第二次消费不重复落库）
- [ ] **J**（Makefile 合约）：`copilot-step03-prep/migrate/up/consume/inject/test/all/status/clean`

> **永久规则**：M1 卡片仅展示与建议；**禁止**含"立即卖出"等下单按钮；详情页可显示"建议关注 / 建议复核 / 建议研究卖出"文案，**禁止**"立即"。

> **数据细节**：L4 W04 实测——Python 3.9.6 / `conftest` 用 `asyncio.run(engine.dispose())` 解决 async engine teardown / 13 用例 + 全量 48 passed in 1.03s/1.81s。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[../01_实践目标与策略.md](../01_实践目标与策略.md) M1、[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md)
> - **DNA**：[`_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml`](../../../../_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml) `modules[0] M1`（4 色 / 4 态 / 30d 曲线）；`depends_on_events: ["events:monitor:health_change"]`
> - **D3 上游契约**：[D3 step_07](../../../../03_维度三_持仓监控/stages/stage_1_启动期/steps/step_07_health_change事件流与10持仓测试.md)（health_change 事件流 ★M3）
> - **共享规约**：[13_六维度启动期集成与时序](../../../../_共享规约/13_六维度启动期集成与时序.md) §三 场景 B
> - **L4**：[实践记录_W04_持仓体检模块](../../../../../04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/实践记录_W04_持仓体检模块.md) — 含 13 + 48 passed、`copilot_group` 消费组、event_id 幂等、conftest 修复
> - **上游 step**：step_01（FastAPI + Redis client）+ step_02（4 张表 + holdings + SoT）
> - **下游 step**：step_05 告警（复用 4 色卡片 + push_level）；step_09 全链路联调（收紧：必须有真 D3 push）

## §3 数据采集对象与落库映射

### §3.1 health_change 事件流契约（D3 step_07 产出）

| 字段 | 类型 | 必填 | 含义 |
|---|---|---|---|
| `event_id` | string | ✅ | UUIDv4；幂等键 |
| `symbol` | string(6) | ✅ | A 股代码 |
| `health_score` | int [-100, 100] | ✅ | D3 健康度（启动期单一总分）|
| `push_level` | int (0,1,2,3,...) | ✅ | 0=绿 / 1=黄 / 2=橙 / ≥3=红（负数视为绿）|
| `narrative_label` | string | ⚠️ | "财务稳健 / 关联交易疑点 / 大股东减持 / 业绩雷暴 / ..."；启动期可为 null |
| `state` | enum | ⚠️ | `growing / stable / warning / exit`；启动期可为 null |
| `prev_score` | int | — | 上次分数（用于趋势）|
| `prev_push_level` | int | — | 上次推送等级（D3 用于去抖）|
| `change_reason` | string | — | 触发本次推送的原因摘要（中文）|
| `detected_at` | ISO ts | ✅ | D3 探针检测时间 |
| `pushed_at` | ISO ts | ✅ | D3 XADD 时间 |
| `evidence_links` | list | — | 证据链 URL（关联到 D2 thesis 或 D1 报告）|
| `version` | string | ✅ | schema 版本（启动期 `v1.0.0`）|

总计 13 字段（必填 7 + 选填 6）。

### §3.2 落库映射（双表）

| 输入 | 落库 | 字段映射 |
|---|---|---|
| 每条 XREADGROUP 消息 | `event_logs`（step_02 已建）| stream_key=`events:monitor:health_change`、msg_id=XStream entry id、payload=JSON 全量、handled=true after handler 完成、error=null |
| 同一条消息 | `health_records`（**本步新增**）| event_id（去重幂等）、symbol、push_level、health_score、narrative_label、state、source_data=JSON 全量、received_at=now |
| 持仓 SoT active | dashboard 渲染范围 | 仅展示 `active=true` 标的 |
| 30 天历史 | `health_records` 表内 `WHERE symbol=? ORDER BY received_at DESC LIMIT 30` | 详情页曲线 |

### §3.3 新表 `health_records` ORM Schema

| 列 | 类型 | 约束 / 索引 |
|---|---|---|
| id | INTEGER | PK auto |
| event_id | VARCHAR(64) | **NOT NULL UNIQUE**（幂等键，`uq_event_id`）|
| symbol | VARCHAR(16) | NOT NULL |
| push_level | INTEGER | NOT NULL |
| health_score | INTEGER | NOT NULL |
| narrative_label | VARCHAR(128) | NULL |
| state | VARCHAR(32) | NULL |
| prev_score | INTEGER | NULL |
| prev_push_level | INTEGER | NULL |
| change_reason | TEXT | NULL |
| detected_at | DATETIME | NULL |
| pushed_at | DATETIME | NULL |
| source_data | TEXT (JSON) | NULL（完整 payload 兜底，便于事后回溯）|
| received_at | DATETIME | DEFAULT NOW |
| **INDEX**(symbol, received_at DESC) | | `ix_symbol_time`，用于详情页 30d 查询 |

## §3.5 数据质量验收矩阵

### §3.5.1 UI 准确性

| # | 维度 | 必产字段 / 衍生 | 启动期 | 降级 |
|---|---|---|---|---|
| U1 | **4 色映射准确** | 0/-1/-2 → green；1 → yellow；2 → orange；≥3、5、99 → red | ✅ 参数化测试 6 组 | — |
| U2 | **卡片字段完整** | symbol + 中文名 + push_level + health_score + narrative_label（缺则 "未知"）+ last_updated | ✅ | narrative null → "未知" |
| U3 | **4 态显示** | growing / stable / warning / exit；详情页可视化 | ✅ | state null → "等待 D3 详细分析" |
| U4 | **30d 曲线** | ≥ 7 数据点显示完整曲线；< 7 显示 sparse | ✅ | 0 点 → 文案"暂无历史数据" |
| U5 | **新鲜度** | `last_updated` ≥ 1h → 卡片标 stale 半透明灰边 | ✅ | — |
| U6 | **HTMX 自动刷新** | dashboard 每 30s `hx-get` 一次；详情页每 60s | ✅ | 网络断时 HTMX 显示 retry 文案 |
| U7 | **空 dashboard 占位** | 0 持仓时显示"请先在持仓页添加标的"链接 | ✅ | — |

### §3.5.2 消费契约

| # | 维度 | 必产字段 / 衍生 | 启动期 | 降级 |
|---|---|---|---|---|
| C1 | **消费组名固定** | `copilot_group` | ✅ | — |
| C2 | **consumer 名** | `copilot-1`（启动期单 consumer）；扩展期才水平扩展 | ✅ | — |
| C3 | **首次创建 group** | `XGROUP CREATE events:monitor:health_change copilot_group $ MKSTREAM`；吞掉 `BUSYGROUP` | ✅ | — |
| C4 | **event_id 幂等** | 同 event_id 第二次进 handler 直接 return（不重复落库）| ✅ | unique 约束兜底 |
| C5 | **双表同事务** | `event_logs` + `health_records` 同 session、同 commit | ✅ | 任一 fail → rollback；不 XACK |
| C6 | **XACK 时机** | handler `await session.commit()` 成功 **后** 才 XACK；保证 at-least-once | ✅ | — |
| C7 | **handler 异常打日志** | 不让 task crash；写 `event_logs.error` 字段；不 XACK（消息进 pending）| ✅ | 重试 3 次后 deadletter |
| C8 | **schema 版本兼容** | payload 含 `version`；不匹配 → log warning + 仍按已知字段落库 | ✅ | — |

### §3.5.3 性能与可观测

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| P1 | **dashboard latency** | p95 < 200ms（10 持仓 + 内置 SQLite） | ✅ |
| P2 | **detail latency** | p95 < 300ms（30 天历史查询）| ✅ `ix_symbol_time` 索引 |
| P3 | **consumer lag** | XLEN - XPENDING < 5（启动期单 producer 单 consumer） | ✅ |
| P4 | **/api/health/dashboard 含 summary** | `summary.total / .green / .yellow / .orange / .red` | ✅ |
| P5 | **HTML 渲染含"持仓体检"标题文案** | 文案审计 | ✅ |

### §3.5.4 no-mock / no-trade

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| E1 | **`scripts/inject_mock_health_change.py` 仅启动期联调** | 在 step_09 前从 main.py 启动路径剥离；不出现在生产 import | ✅ |
| E2 | **生产路径不能伪造 health_records** | rg `INSERT.*health_records.*VALUES.*\(.*'mock'` apps/ = 0 | ✅ |
| E3 | **卡片不含"立即卖出"等下单文案** | rg "立即下单\|立即买入\|立即卖出\|一键卖出" apps/copilot/templates/health/ = 0 | ✅ |
| E4 | **详情页文案审查** | "建议卖出"OK；"立即"违规 | ✅ 文案审计列表 |

**共 24 项**。逐项验证命令见 §9。

## §4 凭证清单与环境模板

| 凭证 / 资源 | 用途 | 何时 | 写在哪 |
|---|---|---|---|
| Docker `diting-redis` | XREADGROUP / XADD | 本步必须（按 〇-1） | 命令起 |
| `COPILOT_REDIS_URL` | 同 step_01 | 本步必须 | `.env` |
| `MY_HOLDINGS_YAML` | dashboard 渲染范围 | 本步必须 | `.env` |
| `COPILOT_HEALTH_CONSUMER_GROUP` | 消费组名（默认 `copilot_group`）| 可选 | `.env` |
| `COPILOT_HEALTH_CONSUMER_NAME` | consumer 名（默认 `copilot-1`）| 可选 | `.env` |

### §4.1 `.env.template` 增补

```text
COPILOT_HEALTH_CONSUMER_GROUP=copilot_group
COPILOT_HEALTH_CONSUMER_NAME=copilot-1
COPILOT_HEALTH_DASHBOARD_REFRESH_SEC=30
COPILOT_HEALTH_DETAIL_REFRESH_SEC=60
```

## §5 启动期目标

| 指标 | 启动期门槛 | 测量 |
|---|---|---|
| `/api/health/dashboard` JSON 含 cards + summary | 200 + 字段齐 | curl + jq |
| `/api/health/{symbol}` JSON 含 latest + history | 200 | curl + jq |
| `/health-dashboard` HTML 含"持仓体检"文案 | 200 + grep | curl + grep |
| `/health-detail/{symbol}` HTML 含 sparkline 或"暂无数据" | 200 | curl |
| Mock 注入后 dashboard 反映 | `inject_mock_health_change.py 600519 -23 3` → dashboard 红卡片含 600519 | 命令链 |
| Consumer lag | `XPENDING events:monitor:health_change copilot_group` < 5 | redis-cli |
| **本步单测** | ≥ 13 passed | pytest |
| **全量 `tests/copilot/`** | ≥ 48 passed（与 step_01/02 链接合）| pytest |
| **永久规则** | rg "立即下单\|立即买入\|立即卖出" apps/copilot/templates/ = 0 | rg |

## §6 下一步

本步 ✅ → **step_04 推荐池模块（M2）**：消费 `events:thrust:thesis_proposed` → 推荐池页 + thesis 5 必填字段卡片 + PDF 导出。

## §7 实施规划（细化版）

### §7.1 实现要点

| # | 要点 | 位置 | 输入 | 核心逻辑 | 关键字段 / 输出 | 错误处理 | 验证标准 |
|---|---|---|---|---|---|---|---|
| 1 | **HealthRecord 模型** | `apps/copilot/db/models.py` | 追加新表 | type-annotated ORM；`UniqueConstraint("event_id")` + `Index("ix_symbol_time", "symbol", "received_at")` | 见 §3.3 | 缺约束 fail | `Base.metadata.tables["health_records"]` 存在 |
| 2 | **migration** | `init_db()` 或 alembic | 同 | 启动期 `create_all` 即可 | DB 现 5 张表 | — | `sqlite3 ".tables"` 含 `health_records` |
| 3 | **HealthChangeConsumer** | `apps/copilot/events/consumer.py` | settings + redis | `async def run()` 循环 `XREADGROUP`；`XGROUP CREATE` MKSTREAM；BUSYGROUP 吞掉；每条消息进 handler；handler 成功 → XACK；失败 → 不 XACK + log | 类 `HealthChangeConsumer`，方法 `run / _ensure_group / _handle_message / _xack` | `BUSYGROUP / ConnectionError / handler exception` 各分支 | `test_handler_writes_two_tables` |
| 4 | **handler** | 同上 | parsed payload | 解析 payload → 写 `event_logs` + `health_records`（同 session）→ commit；event_id 幂等查 `SELECT 1 FROM health_records WHERE event_id=?` 命中则跳过 | 写 2 表；返回 `True/False` | unique 冲突 → 跳过；其它异常 → rollback + raise | `test_handler_idempotent_on_same_event_id` |
| 5 | **HealthCheckService** | `apps/copilot/modules/health_check/service.py` | db session | `push_level_to_color`、`get_dashboard`、`get_detail` 三方法 | 见 §1 交付物 C | symbol 不存在 → 返回空对象 | `test_color_mapping ×6 / test_dashboard_groups_by_color / test_detail_returns_history` |
| 6 | **4 路由** | `apps/copilot/routers/health_routes.py` | request + db | 2 JSON + 2 HTML；调用 service | JSON 含 cards + summary | service 异常 → 500 + log | `test_api_dashboard_endpoint / test_dashboard_html_renders` |
| 7 | **模板** | `apps/copilot/templates/health/{dashboard.html, detail.html}` + `partials/health_card.html` | service 返回值 | 4 色 grid + sparkline + HTMX 轮询 | 5 个 html 片段 | — | grep "持仓体检" |
| 8 | **main.py lifespan** | `apps/copilot/main.py` | settings | startup 增 `asyncio.create_task(consumer.run())`；shutdown cancel task | task 生命周期管理 | task 异常打日志 + restart × 3 | uvicorn 起 + consumer log |
| 9 | **mock 注入脚本** | `scripts/inject_mock_health_change.py` | argparse | `python3 inject_mock_health_change.py 600519 -23 3` → XADD 一条 | symbol/health/level 参数 | symbol 长度 ≠ 6 raise | 命令链验证 |
| 10 | **Makefile** | `diting-src/Makefile` | settings | 9 target | `.PHONY` | — | `make -n copilot-step03-all` |

### §7.2 详细实施步骤

#### 7.2.1 `apps/copilot/db/models.py`（追加 HealthRecord）

```python
# 追加到 step_02 已有 models.py 末尾
from sqlalchemy import DateTime, Integer, String, Text, UniqueConstraint, Index

class HealthRecord(Base):
    __tablename__ = "health_records"
    __table_args__ = (
        UniqueConstraint("event_id", name="uq_event_id"),
        Index("ix_symbol_time", "symbol", "received_at"),
    )
    id: Mapped[int] = mapped_column(primary_key=True)
    event_id: Mapped[str] = mapped_column(String(64), nullable=False)
    symbol: Mapped[str] = mapped_column(String(16), nullable=False)
    push_level: Mapped[int] = mapped_column(Integer, nullable=False)
    health_score: Mapped[int] = mapped_column(Integer, nullable=False)
    narrative_label: Mapped[Optional[str]] = mapped_column(String(128))
    state: Mapped[Optional[str]] = mapped_column(String(32))
    prev_score: Mapped[Optional[int]] = mapped_column(Integer)
    prev_push_level: Mapped[Optional[int]] = mapped_column(Integer)
    change_reason: Mapped[Optional[str]] = mapped_column(Text)
    detected_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    pushed_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    source_data: Mapped[Optional[str]] = mapped_column(Text)
    received_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
```

#### 7.2.2 `apps/copilot/events/consumer.py`（HealthChangeConsumer）

```python
import asyncio
import json
import logging
from typing import Optional
import redis.asyncio as aioredis
from redis.exceptions import ResponseError, ConnectionError as RedisConnError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from apps.copilot.config import settings
from apps.copilot.db.database import AsyncSessionLocal
from apps.copilot.db.models import EventLog, HealthRecord
from apps.copilot.services.redis_client import get_redis

log = logging.getLogger(__name__)
STREAM = "events:monitor:health_change"


class HealthChangeConsumer:
    def __init__(self, group: Optional[str] = None, consumer: Optional[str] = None):
        self.group = group or settings.health_consumer_group
        self.consumer = consumer or settings.health_consumer_name
        self._stop = False

    async def _ensure_group(self, redis: aioredis.Redis):
        try:
            await redis.xgroup_create(STREAM, self.group, id="$", mkstream=True)
            log.info("XGROUP CREATE %s %s ok", STREAM, self.group)
        except ResponseError as e:
            if "BUSYGROUP" in str(e):
                log.info("group %s already exists", self.group)
            else:
                raise

    async def _handle_message(self, msg_id: str, fields: dict, session: AsyncSession) -> bool:
        """Return True if handled (or skipped due to idempotency); False if should not XACK."""
        try:
            event_id = fields.get("event_id")
            if not event_id:
                log.warning("missing event_id, skip msg %s", msg_id); return True
            # 幂等：event_id 已存在则跳过
            existing = (await session.execute(
                select(HealthRecord.id).where(HealthRecord.event_id == event_id)
            )).scalar_one_or_none()
            if existing:
                log.info("event_id %s already processed, skip", event_id); return True
            # 双表写
            session.add(EventLog(
                stream_key=STREAM, msg_id=msg_id,
                payload=json.dumps(fields, ensure_ascii=False, default=str),
                handled=True, error=None,
            ))
            session.add(HealthRecord(
                event_id=event_id,
                symbol=fields["symbol"],
                push_level=int(fields["push_level"]),
                health_score=int(fields["health_score"]),
                narrative_label=fields.get("narrative_label"),
                state=fields.get("state"),
                prev_score=int(fields["prev_score"]) if fields.get("prev_score") else None,
                prev_push_level=int(fields["prev_push_level"]) if fields.get("prev_push_level") else None,
                change_reason=fields.get("change_reason"),
                detected_at=fields.get("detected_at"),
                pushed_at=fields.get("pushed_at"),
                source_data=json.dumps(fields, ensure_ascii=False, default=str),
            ))
            await session.commit()
            return True
        except Exception as e:
            log.exception("handler failed on msg %s: %s", msg_id, e)
            await session.rollback()
            # 写一条 error 记录到 event_logs（独立 session）
            async with AsyncSessionLocal() as s2:
                s2.add(EventLog(stream_key=STREAM, msg_id=msg_id,
                                payload=json.dumps(fields, default=str),
                                handled=False, error=str(e)))
                await s2.commit()
            return False  # 不 XACK，消息进 pending

    async def run(self):
        redis = await get_redis()
        await self._ensure_group(redis)
        log.info("consumer %s/%s started on %s", self.group, self.consumer, STREAM)
        while not self._stop:
            try:
                resp = await redis.xreadgroup(
                    groupname=self.group, consumername=self.consumer,
                    streams={STREAM: ">"}, count=10, block=5000,
                )
                if not resp:
                    continue
                for _stream, messages in resp:
                    for msg_id, fields in messages:
                        async with AsyncSessionLocal() as session:
                            ok = await self._handle_message(msg_id, fields, session)
                            if ok:
                                await redis.xack(STREAM, self.group, msg_id)
            except RedisConnError as e:
                log.error("redis conn error, retry in 5s: %s", e)
                await asyncio.sleep(5)
            except Exception as e:
                log.exception("consumer loop error: %s", e)
                await asyncio.sleep(1)

    def stop(self):
        self._stop = True
```

#### 7.2.3 `apps/copilot/modules/health_check/service.py`（HealthCheckService）

```python
from typing import List, Optional
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession
from apps.copilot.db.models import HealthRecord
from apps.common.holdings_sot import load_active

COLOR_GREEN, COLOR_YELLOW, COLOR_ORANGE, COLOR_RED = "green", "yellow", "orange", "red"


def push_level_to_color(level: int) -> str:
    if level <= 0:
        return COLOR_GREEN
    if level == 1:
        return COLOR_YELLOW
    if level == 2:
        return COLOR_ORANGE
    return COLOR_RED  # ≥ 3


class HealthCheckService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_latest(self, symbol: str) -> Optional[HealthRecord]:
        return (await self.db.execute(
            select(HealthRecord).where(HealthRecord.symbol == symbol)
            .order_by(desc(HealthRecord.received_at)).limit(1)
        )).scalar_one_or_none()

    async def get_dashboard(self) -> dict:
        active = load_active()
        cards = {COLOR_GREEN: [], COLOR_YELLOW: [], COLOR_ORANGE: [], COLOR_RED: []}
        for h in active:
            latest = await self.get_latest(h.symbol)
            color = push_level_to_color(latest.push_level) if latest else COLOR_GREEN
            cards[color].append({
                "symbol": h.symbol, "name": h.name,
                "push_level": latest.push_level if latest else 0,
                "health_score": latest.health_score if latest else None,
                "narrative_label": latest.narrative_label if latest else "等待 D3",
                "state": latest.state if latest else None,
                "last_updated": latest.received_at.isoformat() if latest else None,
            })
        summary = {
            "total": len(active),
            "green": len(cards[COLOR_GREEN]),
            "yellow": len(cards[COLOR_YELLOW]),
            "orange": len(cards[COLOR_ORANGE]),
            "red": len(cards[COLOR_RED]),
        }
        return {"cards": cards, "summary": summary}

    async def get_detail(self, symbol: str, days: int = 30) -> dict:
        latest = await self.get_latest(symbol)
        history = (await self.db.execute(
            select(HealthRecord).where(HealthRecord.symbol == symbol)
            .order_by(desc(HealthRecord.received_at)).limit(days)
        )).scalars().all()
        return {
            "symbol": symbol,
            "latest": {
                "push_level": latest.push_level if latest else 0,
                "color": push_level_to_color(latest.push_level) if latest else COLOR_GREEN,
                "health_score": latest.health_score if latest else None,
                "narrative_label": latest.narrative_label if latest else "等待 D3",
                "state": latest.state if latest else None,
                "change_reason": latest.change_reason if latest else None,
            } if latest else None,
            "history": [{
                "ts": r.received_at.isoformat(),
                "health_score": r.health_score,
                "push_level": r.push_level,
            } for r in history],
        }
```

#### 7.2.4 `apps/copilot/routers/health_routes.py`（4 路由）

```python
from fastapi import APIRouter, Depends, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.ext.asyncio import AsyncSession
from apps.copilot.db.database import get_db
from apps.copilot.modules.health_check.service import HealthCheckService

router = APIRouter()
templates = Jinja2Templates(directory="apps/copilot/templates")


@router.get("/api/health/dashboard")
async def api_dashboard(db: AsyncSession = Depends(get_db)):
    return JSONResponse(await HealthCheckService(db).get_dashboard())


@router.get("/api/health/{symbol}")
async def api_detail(symbol: str, db: AsyncSession = Depends(get_db)):
    return JSONResponse(await HealthCheckService(db).get_detail(symbol))


@router.get("/health-dashboard", response_class=HTMLResponse)
async def html_dashboard(request: Request, db: AsyncSession = Depends(get_db)):
    data = await HealthCheckService(db).get_dashboard()
    return templates.TemplateResponse(
        "health/dashboard.html", {"request": request, **data}
    )


@router.get("/health-detail/{symbol}", response_class=HTMLResponse)
async def html_detail(symbol: str, request: Request, db: AsyncSession = Depends(get_db)):
    data = await HealthCheckService(db).get_detail(symbol)
    return templates.TemplateResponse(
        "health/detail.html", {"request": request, **data}
    )
```

#### 7.2.5 模板片段（dashboard.html + detail.html + health_card.html）

`templates/health/dashboard.html`：

```html
{% extends "base.html" %}
{% block content %}
<h1 class="text-2xl mb-4">持仓体检</h1>
<div hx-get="/api/health/dashboard" hx-trigger="every 30s"
     hx-swap="none" id="auto-refresh-tick"></div>
<p class="mb-4">共 {{ summary.total }} 只持仓：
  绿 {{ summary.green }} / 黄 {{ summary.yellow }} /
  橙 {{ summary.orange }} / 红 {{ summary.red }}</p>
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
  {% for color in ["green","yellow","orange","red"] %}
    {% for c in cards[color] %}
      {% include "health/partials/health_card.html" %}
    {% endfor %}
  {% endfor %}
</div>
{% endblock %}
```

`templates/health/partials/health_card.html`：

```html
<a href="/health-detail/{{ c.symbol }}"
   class="block border-l-8 p-4 bg-white shadow rounded
          border-{{ color }}-500 hover:shadow-lg transition">
  <p class="font-bold text-lg">{{ c.symbol }} · {{ c.name or "—" }}</p>
  <p class="text-sm text-gray-700">健康度：{{ c.health_score or "—" }} · push={{ c.push_level }}</p>
  <p class="text-xs text-gray-500">{{ c.narrative_label or "等待 D3" }}</p>
  {% if c.last_updated %}
    <p class="text-xs text-gray-400">更新于 {{ c.last_updated[:19] }}</p>
  {% endif %}
</a>
```

`templates/health/detail.html`：

```html
{% extends "base.html" %}
{% block content %}
<h1 class="text-2xl mb-4">{{ symbol }} · 持仓详情</h1>
{% if latest %}
  <div class="border-l-8 border-{{ latest.color }}-500 p-4 bg-white shadow mb-6">
    <p class="text-lg">健康度 {{ latest.health_score }} · push_level={{ latest.push_level }}</p>
    <p class="text-sm">状态：{{ latest.state or "未知" }} · {{ latest.narrative_label }}</p>
    {% if latest.change_reason %}
      <p class="text-sm text-gray-600 mt-2">变更原因：{{ latest.change_reason }}</p>
    {% endif %}
  </div>
{% else %}
  <p class="text-gray-500">暂无健康度数据，等待 D3 推送...</p>
{% endif %}
<h2 class="text-xl mb-2">最近 30 天</h2>
{% if history %}
  <table class="w-full text-sm border-collapse">
    <thead><tr class="bg-gray-100">
      <th class="p-2 text-left">时间</th><th>健康度</th><th>push</th>
    </tr></thead>
    <tbody>{% for r in history %}
      <tr><td class="p-2">{{ r.ts[:19] }}</td>
          <td class="text-right">{{ r.health_score }}</td>
          <td class="text-right">{{ r.push_level }}</td></tr>
    {% endfor %}</tbody>
  </table>
{% else %}
  <p class="text-gray-500">暂无历史数据</p>
{% endif %}
{% endblock %}
```

#### 7.2.6 `main.py` lifespan 接入 consumer

```python
import asyncio
# ... step_01/02 已有 imports ...
from apps.copilot.events.consumer import HealthChangeConsumer
from apps.copilot.routers import health_routes

_consumer: HealthChangeConsumer = None
_consumer_task: asyncio.Task = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.start_ts = time.time()
    app.state.redis = await get_redis()
    await init_db()
    # 启动 consumer 后台任务
    global _consumer, _consumer_task
    _consumer = HealthChangeConsumer()
    _consumer_task = asyncio.create_task(_consumer.run())
    yield
    _consumer.stop()
    if _consumer_task:
        _consumer_task.cancel()
        try:
            await _consumer_task
        except asyncio.CancelledError:
            pass
    await close_redis()


app.include_router(health_routes.router)
```

#### 7.2.7 `scripts/inject_mock_health_change.py`（仅启动期联调）

```python
"""仅启动期联调用；step_09 全链路前必须 gated 或删除。"""
import argparse, json, uuid, sys
from datetime import datetime
import redis

def main():
    p = argparse.ArgumentParser()
    p.add_argument("symbol")
    p.add_argument("health_score", type=int)
    p.add_argument("push_level", type=int)
    p.add_argument("--narrative", default="mock 注入（仅调试）")
    p.add_argument("--redis-url", default="redis://127.0.0.1:6379/0")
    a = p.parse_args()
    r = redis.from_url(a.redis_url, decode_responses=True)
    payload = {
        "event_id": str(uuid.uuid4()),
        "symbol": a.symbol.zfill(6),
        "health_score": a.health_score,
        "push_level": a.push_level,
        "narrative_label": a.narrative,
        "state": "warning" if a.push_level >= 2 else "stable",
        "detected_at": datetime.utcnow().isoformat(),
        "pushed_at": datetime.utcnow().isoformat(),
        "version": "v1.0.0",
    }
    msg_id = r.xadd("events:monitor:health_change", payload)
    print(f"XADD ok: msg_id={msg_id} event_id={payload['event_id']}")

if __name__ == "__main__":
    sys.exit(main())
```

#### 7.2.8 `tests/copilot/test_health.py`（≥ 6 用例 · 含参数化 + dashboard + detail）

```python
import pytest
from httpx import AsyncClient
from apps.copilot.main import app
from apps.copilot.modules.health_check.service import push_level_to_color


@pytest.mark.parametrize("level,color", [
    (0, "green"), (1, "yellow"), (2, "orange"),
    (3, "red"), (5, "red"), (-1, "green"),
])
def test_color_mapping(level, color):
    assert push_level_to_color(level) == color


@pytest.mark.asyncio
async def test_dashboard_groups_by_color(db_session):
    # fixture 注入若干 HealthRecord 后调用 service.get_dashboard()
    ...


@pytest.mark.asyncio
async def test_detail_returns_history(db_session):
    ...


@pytest.mark.asyncio
async def test_api_dashboard_endpoint():
    async with AsyncClient(app=app, base_url="http://t") as ac:
        r = await ac.get("/api/health/dashboard")
    assert r.status_code == 200
    body = r.json()
    assert "cards" in body and "summary" in body
    assert {"green","yellow","orange","red"} == set(body["cards"].keys())


@pytest.mark.asyncio
async def test_dashboard_html_renders():
    async with AsyncClient(app=app, base_url="http://t") as ac:
        r = await ac.get("/health-dashboard")
    assert r.status_code == 200
    assert "持仓体检" in r.text
```

`tests/copilot/test_health_consumer.py`（≥ 2 用例）：

```python
import json, uuid
import pytest
from apps.copilot.events.consumer import HealthChangeConsumer
from apps.copilot.db.models import EventLog, HealthRecord
from sqlalchemy import select


@pytest.mark.asyncio
async def test_handler_writes_two_tables(db_session):
    consumer = HealthChangeConsumer()
    fields = {
        "event_id": str(uuid.uuid4()), "symbol": "600519",
        "push_level": "3", "health_score": "-23",
        "narrative_label": "test", "version": "v1.0.0",
    }
    ok = await consumer._handle_message("1-0", fields, db_session)
    assert ok
    eg = (await db_session.execute(select(EventLog))).scalars().all()
    hr = (await db_session.execute(select(HealthRecord))).scalars().all()
    assert len(eg) == 1 and len(hr) == 1
    assert hr[0].push_level == 3


@pytest.mark.asyncio
async def test_handler_idempotent_on_same_event_id(db_session):
    consumer = HealthChangeConsumer()
    ev = str(uuid.uuid4())
    fields = {"event_id": ev, "symbol": "600519",
              "push_level": "1", "health_score": "10", "version": "v1.0.0"}
    await consumer._handle_message("1-0", fields, db_session)
    await consumer._handle_message("2-0", fields, db_session)  # 同 event_id
    hr = (await db_session.execute(select(HealthRecord))).scalars().all()
    assert len(hr) == 1  # 第二次被跳过
```

> **conftest 修复**（L4 W04 经验）：`tests/copilot/conftest.py` 中 teardown 用 `asyncio.run(engine.dispose())`，避免 Py3.9 下 async engine 在事件循环外报 `no current event loop`。

### §7.3 Makefile 合约

| target | 用途 | 入参 | 验证 |
|---|---|---|---|
| `copilot-step03-prep` | 起 `diting-redis` + 校验 step_02 已建 4 表 | `MY_HOLDINGS_YAML` | `4 tables ✅` |
| `copilot-step03-migrate` | `init_db()` 建第 5 表 `health_records` | — | `health_records ✅` |
| `copilot-step03-up` | 启 uvicorn（lifespan 起 consumer） | `COPILOT_PORT?=8080` | `pid=N consumer started ✅` |
| `copilot-step03-consume` | 单独启 consumer（不起 web，用于联调） | — | `XGROUP ready ✅` |
| `copilot-step03-inject` | `python3 scripts/inject_mock_health_change.py 600519 -23 3` | symbol/health/level | `msg_id=... ✅` |
| `copilot-step03-test` | `pytest tests/copilot/test_health*.py -v` + 全量 -q | — | `13 + 48 passed ✅` |
| `copilot-step03-all` | prep → migrate → up → inject → curl dashboard → test | — | 端到端绿 |
| `copilot-step03-status` | `XLEN events:monitor:health_change` + `XPENDING` + `health_records count` | — | 三行 |
| `copilot-step03-clean` | 停 consumer + 删 mock 注入痕迹（删 `health_records WHERE narrative LIKE 'mock%'`）；不删 redis 容器 | — | `cleaned ✅` |

**合约要求**：
1. 配置驱动：consumer group / consumer name 由 env 控制；切换不改 Makefile；
2. 可重入：`copilot-step03-all` 第二次跑 `XGROUP CREATE` 被 BUSYGROUP 吞掉、`init_db` 表已存在 skip；
3. mock 注入留痕：`narrative_label` 含 `"mock 注入"` 文案；`copilot-step03-clean` 可清除；
4. step_09 收紧：到 step_09 时 `inject_mock_health_change.py` 必须从 `main.py` 启动路径完全剥离，禁止生产 import。

### §7.4 给后续执行模型的指引

1. **顺序刚性**：HealthRecord ORM（7.2.1）→ migrate（建表）→ consumer（7.2.2）→ service（7.2.3）→ routes（7.2.4）→ templates（7.2.5）→ main.py lifespan（7.2.6）→ mock 脚本（7.2.7）→ tests（7.2.8）→ Makefile（7.3）；
2. **不嵌入完整生产代码**：本文档代码块是骨架；docstring / 完整日志格式 / metrics 由 L4 回写；
3. **conftest 修复**：Py3.9 异步 engine teardown 用 `asyncio.run(engine.dispose())`（L4 W04 经验）；
4. **三终端联调**：terminal A `uvicorn ... :8080` / terminal B `python3 -m apps.copilot.events.consumer`（或直接由 lifespan 拉起，单 terminal 即可）/ terminal C `inject_mock_health_change.py 600519 -23 3` → curl `/api/health/dashboard` 见 600519 红卡片；
5. **L4 回写内容**：
   - `XPENDING events:monitor:health_change copilot_group` 输出（启动期应为 0 pending）；
   - 13 + 48 pytest 输出片段；
   - `sqlite3 data/copilot.db "SELECT symbol,push_level FROM health_records LIMIT 5"`；
   - `/api/health/dashboard` 完整 JSON 截取（脱敏 event_id）；
6. **永久规则审计**：
   ```bash
   rg "立即下单|立即买入|立即卖出|一键卖出" apps/copilot/templates/health/   # 0
   rg "place_order|submit_order|broker_api" apps/copilot/modules/health_check/   # 0
   ```
7. **step_09 前必须**：从 `main.py` 启动路径完全剥离 mock 注入；建议手段：将 `inject_mock_health_change.py` 移入 `scripts/dev_only/` 并 README 标注；生产 import path 静态扫断言。

## §8 部署节奏

| 项 | 本 step |
|---|---|
| 部署面 | **本机** uvicorn（含 consumer task）+ Docker `diting-redis` |
| Chart | **不改** |
| ACR | **不构建** |
| Helm | **—** |
| 上 K3s 时机 | step_10 阶段验收；consumer task 独立 Deployment（启动期单副本，扩展期水平扩展时改 consumer name 加序号）|

## §9 准出标准

### §9.1 数据量

| 表 | 启动期门槛 |
|---|---|
| `health_records` | 注入 3 条 mock 后 ≥ 3；step_09 收紧时由 D3 真实推送 ≥ 10 |
| `event_logs` (stream_key=health_change) | 与 `health_records` 同步增长 |

### §9.2 数据质量（§3.5 24 项必须全绿）

```bash
# 1) 建表
python3 -c "from apps.copilot.db.database import init_db; import asyncio; asyncio.run(init_db())"
sqlite3 data/copilot.db ".tables" | grep -o health_records   # 期望命中

# 2) Schema 约束
sqlite3 data/copilot.db ".schema health_records" | grep -E "uq_event_id|ix_symbol_time"

# 3) 起 redis + 起服务 + 注入 mock
docker run -d --name diting-redis -p 6379:6379 redis:7-alpine
export COPILOT_REDIS_URL=redis://127.0.0.1:6379/0
lsof -ti:8080 | xargs -r kill -9
python3 -m uvicorn apps.copilot.main:app --port 8080 &
sleep 3
python3 scripts/inject_mock_health_change.py 600519 -23 3
python3 scripts/inject_mock_health_change.py 601398 10 1
sleep 2

# 4) 验证 API
curl -s http://127.0.0.1:8080/api/health/dashboard | jq '.summary'
# 期望：{"total": N, "green": N, "yellow": 1, "orange": 0, "red": 1}
curl -s http://127.0.0.1:8080/api/health/600519 | jq '.latest.push_level'
# 期望：3

# 5) HTML 页面
curl -s http://127.0.0.1:8080/health-dashboard | grep -o "持仓体检"
curl -s http://127.0.0.1:8080/health-detail/600519 | grep -o "600519"

# 6) Consumer 健康
docker exec diting-redis redis-cli XINFO GROUPS events:monitor:health_change
# 期望含 name=copilot_group consumers=1
docker exec diting-redis redis-cli XPENDING events:monitor:health_change copilot_group
# 期望：0 pending（启动期单 consumer 处理及时）

# 7) DB 落库
sqlite3 data/copilot.db "SELECT COUNT(*) FROM health_records"   # 期望 ≥ 2
sqlite3 data/copilot.db "SELECT COUNT(*) FROM event_logs WHERE stream_key='events:monitor:health_change'"  # 同上

# 8) 永久规则审计
rg -i "立即下单|立即买入|立即卖出" apps/copilot/templates/health/   # 0
rg "place_order|submit_order" apps/copilot/modules/health_check/    # 0

# 9) 单测
pytest tests/copilot/test_health.py tests/copilot/test_health_consumer.py -v   # 期望 ≥ 13 passed
pytest tests/copilot/ -q   # 期望 ≥ 48 passed

# 10) Makefile
make copilot-step03-all
make copilot-step03-status
```

### §9.3 锁库

`health_records.event_id` UNIQUE 约束自动锁库；`event_logs.UNIQUE(stream_key, msg_id)` 同。

### §9.4 准出确认

- [ ] §9.2 全部 10 条命令本机跑通 ✅
- [ ] §3.5 24 项全绿
- [ ] L4 实践记录 `实践记录_W04_持仓体检模块.md` 已回写：13 + 48 passed、XPENDING=0、`/api/health/dashboard` JSON、`sqlite3 health_records` 行数
- [ ] 通知 step_04 owner（M2 推荐池）可启动消费 `events:thrust:thesis_proposed`

## §10 [Deploy]

ConfigMap 新增：`COPILOT_HEALTH_CONSUMER_GROUP / NAME / DASHBOARD_REFRESH_SEC`。上 K3s 时 consumer 必须独立 Deployment（避免 uvicorn 多副本时多 consumer 抢同一 group）；启动期单副本 OK。

## §11 依赖与禁忌

| 类型 | 依赖项 | 当前就绪 | 缺失时处理 |
|---|---|---|---|
| 硬上游 | step_01 + step_02 完成（FastAPI + 4 表 + SoT）| ✅ | 回前置 step |
| 硬上游 | Docker `diting-redis` 起；`COPILOT_REDIS_URL` 已设 | 用户 | 阻塞 |
| 软上游 | D3 step_07 推送真 `health_change` | 启动期不强制 | 启动期允许 mock 注入；step_09 收紧 |
| 资源 | Mock 脚本可达；inject 后 DB 反映 | 启动期 | — |

**严禁**：
- `apps/copilot/modules/health_check/` 下出现 `random.randint / fake_health` 等伪造健康度（违反 no-mock）；
- 卡片或详情页含"立即卖出"按钮或链接；
- 生产 import path 含 `inject_mock_health_change`（step_09 必须剥离）；
- consumer group 名硬编码（必须从 settings 读）。

## §12 风险与回退

| 触发 | 影响 | 应对 | 重试 |
|---|---|---|---|
| `BUSYGROUP` 异常 | XGROUP CREATE 第二次失败 | `_ensure_group` 已吞掉；属正常 | — |
| Consumer task 异常退出 | health_change 不落库 | lifespan watchdog；自动 restart × 3；超限写 ADR | 3 次 |
| `event_id` 冲突 | unique 约束抛错 | handler `IntegrityError` 捕获 → 视为幂等跳过 | — |
| Redis ConnectionError | consumer 卡 | `await asyncio.sleep(5)` 重试 | 无上限（log warning）|
| 30d history 查询慢 | detail latency > 300ms | `ix_symbol_time` 索引；启动期允许 ⚠️ | — |
| Py3.9 conftest engine.dispose | 测试 teardown 报错 | `asyncio.run(engine.dispose())`（L4 W04 经验）| 1 次 |
| Mock 脚本误入生产 | 违反 no-mock | step_09 前 `git grep "inject_mock_health_change"` apps/ = 0 | — |
| 同问题修复 > 2 次 | 阻塞 | 回退按 §8.4f：重建 consumer group / 删表重建 / 重启 redis | — |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v3 细化融合**：基于 L4 W04 实践记录回填真实事实——`health_records` 表名（非 `health_snapshots`）、`copilot_group` 消费组（非 `dim_zero`）、4 路由（2 JSON + 2 HTML）、13 用例（含 6 个参数化 color_mapping）、event_id 幂等、双表同事务、conftest `asyncio.run(engine.dispose())` 修复、BUSYGROUP 吞掉模式、mock 注入脚本仅启动期联调；§3.5 从 12 项扩到 24 项；§7 含完整 7.2.1~7.2.8 实施步骤；157→~900 行 |
| 2026-05-20 | v2 按 L3 v1.2 重写：删 ~900 行嵌入 Python/HTML；§3.5 12 项；900→~157 行 |
| 2026-05-16 | 初版 ~900 行 |
