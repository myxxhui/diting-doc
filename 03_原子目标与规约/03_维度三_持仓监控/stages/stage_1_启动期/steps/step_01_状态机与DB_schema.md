# Step 01 · LangGraph 节点 4 态状态机与 DB schema

## §1 一句话定位与本步交付物

**一句话**：搭建 **state-watch** 服务骨架——LangGraph **4 态**（growing/stable/warning/exit）+ **6 条转移规则** + SQLite **三表**（holdings_state / health_records / state_transitions）+ 注册/查询 API；为 step_02~08 探针与健康度链路提供唯一状态真相源。

**交付物**（勾选 = 完成）：
- [ ] **A**（包骨架）：`apps/state_watch/`（state_machine / db / api / events 占位）
- [ ] **B**（LangGraph）：4 态 + T1~T6 转移；`transitions.py` 与 DNA `deliverables.state_machine` 一致
- [ ] **C**（三表 ORM + migration）：holdings_state / health_records / state_transitions + 索引
- [ ] **D**（API）：`POST /api/state-machine/register`；`GET /api/state-machine/{node_id}`；`POST /api/state-machine/transition`（内部调 graph）
- [ ] **E**（健康检查）：`/health` 含 db + redis 探测；`service=state-watch` port **8003**
- [ ] **F**（Settings）：`upstream_streams` 含 `events:thrust:thesis_proposed`；`downstream_stream=events:monitor:health_change`
- [ ] **G**（单测 + Makefile）：状态机 ≥12；schema ≥6；`make watch-step01-all`

> **本步阻塞** step_02~08；无上游硬依赖。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2/L3**：[../01_实践目标与策略.md](../01_实践目标与策略.md) §1.2 四态、[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §3.1
> - **DNA**：`_System_DNA/03_holding_watch/dna_stage_1_启动期.yaml` → `deliverables.state_machine`、`service_name: state-watch`
> - **共享**：[13_六维度启动期集成与时序](../../../../_共享规约/13_六维度启动期集成与时序.md) §三场景 B
> - **持仓 SoT**：`diting-src/data/config/my_holdings.yaml`（`MY_HOLDINGS_YAML`）
> - **L4**：[实践记录_step_01_状态机与DB_schema.md](../../../../../04_阶段规划与实践/03_维度三_持仓监控/stage_1_启动期/实践记录_step_01_状态机与DB_schema.md)
> - **下游**：→ step_02~08；D4/D0 消费 `health_change`（step_07 产出）

## §3 数据采集对象 / 落库映射

**本步不采外部行情**——仅状态注册与转移审计。

| 对象 | 表 | 关键字段 |
|---|---|---|
| 节点当前态 | `holdings_state` | node_id, symbol, state, thesis_id, entered_at |
| 体检快照 | `health_records` | node_id, score, sli_json, narrative_score, recorded_at |
| 转移审计 | `state_transitions` | from_state, to_state, reason, trigger_probe, created_at |

注册来源：SoT `active=true` 标的 + 可选 D2 `thesis_id`（D2 未就绪时 thesis_id 可 null+备注）。

## §3.5 数据质量验收矩阵（状态机与 schema · 仅启动期）

### §3.5.1 状态机语义

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| S1 | **四态枚举** | growing/stable/warning/exit 与 DNA 一致 | ✅ | — |
| S2 | **T1~T6 全覆盖** | 6 条转移各 1 正例单测 | ✅ | — |
| S3 | **非法转移拒绝** | 如 exit→growing 抛 422 | ✅ | — |
| S4 | **初始态** | register 默认 growing | ✅ | — |
| S5 | **转移 reason** | 每次 transition 写 state_transitions.reason 非空 | ✅ | — |

### §3.5.2 表结构与 SoT

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| D1 | **symbol 唯一** | holdings_state.symbol UNIQUE | ✅ | — |
| D2 | **SoT 驱动注册** | register 读 `my_holdings.yaml` active；**禁止**硬编码列表 | ✅ | 0 active→BLOCKED |
| D3 | **health_records 可追加** | 仅 INSERT；按 node_id+时间查询 | ✅ | — |
| D4 | **transitions 不可改** | 无 UPDATE/DELETE API | ✅ | — |
| D5 | **thesis_id 可追溯** | 来自 D2 时填真实 id；否则 null+`thesis_pending` | ⚠️ D2 后补 | — |

### §3.5.3 工程与契约

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **Redis 连通** | /health redis=ok 或 explicit degraded | ⚠️ step_07 才硬需 | 本步可 degraded |
| E2 | **stream 名常量** | upstream/downstream 与 13_ §四一致 | ✅ | — |
| E3 | **no-mock 注册** | 生产 register 不用 fake symbol 列表 | ✅ | tests/ 可 fixture |

> 共 **13 项**。

## §4 凭证清单

| 凭证 | 用途 | 何时 |
|---|---|---|
| `MY_HOLDINGS_YAML` | 注册标的 | 必须 |
| `DATABASE_URL` | SQLite `state_watch.db` | 必须 |
| `REDIS_URL` | health 探测（可选）| 建议 |

> **禁止**在 L3/代码硬编码 symbol 列表。

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 注册节点数 | = SoT active 数（典型 1~10）|
| 状态机单测 | ≥12 passed |
| schema 单测 | ≥6 passed |

### 5.1 六条转移（权威）

| # | from | to | 条件（摘要）|
|---|---|---|---|
| T1 | growing | stable | 持仓>6月且 thesis 仍成立 |
| T2 | growing | warning | 健康度 < 60 |
| T3 | stable | warning | 健康度 < 60 或叙事 contradiction |
| T4 | stable | exit | thesis 失效（narrative<30 连续 3 次）|
| T5 | warning | stable | 健康度 > 75 持续 ≥7 天 |
| T6 | warning | exit | 健康度 < 30 或 thesis 失效 |

## §6 下一步

本步 ✅ → step_02 财务与新闻探针（P1/P2）。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A 目录与依赖** | `apps/state_watch/`、`pyproject.toml` | fastapi/sqlalchemy/aiosqlite/langgraph/apscheduler/redis | tree 齐全 |
| **B states + transitions** | `state_machine/states.py`、`transitions.py` | 枚举+条件函数可单测 | T1~T6 |
| **C LangGraph graph** | `state_machine/graph.py` | compile 后可 invoke | 1 路径 |
| **D ORM 三表** | `db/models.py` + alembic | 索引 symbol/node_id | migration |
| **E registry** | `state_machine/registry.py` | 读 SoT；upsert holdings_state | active 数一致 |
| **F API routes** | `api/routes/state_machine.py` | register/get/transition | curl 200 |
| **G main + health** | `main.py` | port 8003；redis ping | /health |
| **H config** | `config.py` | stream 常量+Settings | 打印可读 |
| **I 单测** | `test_state_machine.py`、`test_db_schema.py` | ≥18 合计 | pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `watch-step01-prep` | SoT 存在且≥1 active |
| `watch-step01-migrate` | alembic head；三表在 |
| `watch-step01-register-sot` | 按 yaml 注册全部 active |
| `watch-step01-test` | pytest ≥18 |
| `watch-step01-all` | migrate+register+test+health |
| `watch-step01-status` | 节点数+态分布 |
| `watch-step01-clean` | dev only FORCE=1 |

### §7.3 关键代码片段（中间道）

#### 7.3.1 四态枚举 + 转移规则字典（核心 ~15 行）

```python
class HoldingState(str, Enum):
    GROWING = "growing"
    STABLE = "stable"
    WARNING = "warning"
    EXIT = "exit"

# T1~T6 转移条件函数：(node_ctx) -> bool
TRANSITIONS = {
    ("growing", "stable"):  lambda c: c.hold_days > 180 and c.thesis_intact,        # T1
    ("growing", "warning"): lambda c: c.health_score < 60,                           # T2
    ("stable",  "warning"): lambda c: c.health_score < 60 or c.narrative_contradiction, # T3
    ("stable",  "exit"):    lambda c: c.narrative_score < 30 and c.narrative_consecutive >= 3, # T4
    ("warning", "stable"):  lambda c: c.health_score > 75 and c.high_health_days >= 7, # T5
    ("warning", "exit"):    lambda c: c.health_score < 30 or not c.thesis_intact,    # T6
}

LEGAL_TRANSITIONS = set(TRANSITIONS.keys())
# 任何不在 LEGAL_TRANSITIONS 的转移 → 422
```

#### 7.3.2 三表 ORM schema（核心 ~15 行）

```python
class HoldingsState(Base):
    __tablename__ = "holdings_state"
    node_id = Column(String(32), primary_key=True)           # uuid4
    symbol = Column(String(16), unique=True, nullable=False, index=True)
    thesis_id = Column(String(32), nullable=True)            # D2 未就绪可 null
    state = Column(Enum(HoldingState), nullable=False, default=HoldingState.GROWING)
    entered_at = Column(DateTime, nullable=False, default=utcnow)

class HealthRecord(Base):
    __tablename__ = "health_records"
    id = Column(Integer, primary_key=True)
    node_id = Column(String(32), ForeignKey("holdings_state.node_id"), index=True)
    score = Column(Numeric(5, 2))                            # 0~100
    sli_json = Column(JSON)                                  # 各探针 SLI
    narrative_score = Column(Numeric(5, 2))
    recorded_at = Column(DateTime, nullable=False, default=utcnow, index=True)

class StateTransition(Base):
    __tablename__ = "state_transitions"
    id = Column(Integer, primary_key=True)
    node_id = Column(String(32), ForeignKey("holdings_state.node_id"), index=True)
    from_state = Column(Enum(HoldingState))
    to_state = Column(Enum(HoldingState), nullable=False)
    reason = Column(String(256), nullable=False)             # 不可空
    trigger_probe = Column(String(32))                       # P1/P2/P3/P4/composite
    created_at = Column(DateTime, default=utcnow, index=True)
    # 仅 INSERT；API 不暴露 UPDATE/DELETE
```

#### 7.3.3 LangGraph 状态机骨架（核心 ~12 行）

```python
from langgraph.graph import StateGraph, END

def build_state_graph():
    graph = StateGraph(NodeContext)
    for state in HoldingState:
        graph.add_node(state.value, make_state_handler(state))

    def route(ctx: NodeContext) -> str:
        for (frm, to), cond in TRANSITIONS.items():
            if frm == ctx.current_state and cond(ctx):
                return to
        return ctx.current_state          # 保持当前态

    for state in HoldingState:
        graph.add_conditional_edges(state.value, route)
    graph.set_entry_point(HoldingState.GROWING.value)
    return graph.compile()
```

#### 7.3.4 SoT 驱动注册（核心 ~10 行）

```python
async def register_from_sot(session: AsyncSession) -> dict:
    from apps.common.holdings_sot import active_symbols
    symbols = active_symbols()                # 读 my_holdings.yaml
    if not symbols:
        raise RuntimeError("BLOCKED: 0 active symbol in SoT")
    n_new, n_skip = 0, 0
    for sym in symbols:
        existing = await session.execute(
            select(HoldingsState).where(HoldingsState.symbol == sym))
        if existing.scalar_one_or_none():
            n_skip += 1; continue
        node = HoldingsState(node_id=uuid4().hex, symbol=sym, state="growing")
        session.add(node); n_new += 1
    await session.commit()
    return {"registered": n_new, "skipped_existing": n_skip}
```

### §7.4 指引

先骨架→ORM→转移规则→Graph→API→SoT 注册；D2 thesis 可后补字段。

## §8 部署节奏

本机 `uvicorn apps.state_watch.main:app --port 8003`；K3s 扩展期。

## §9 准出标准

- [ ] §3.5 13 项；T1~T6 单测绿
- [ ] SoT 注册数=active 数
- [ ] `make watch-step01-all`；L4 回写

## §10 [Deploy]

启动期本机为主；无新 ACR 镜像要求（骨架 commit 即可）。

## §11 依赖

无硬上游；软依赖 D2 thesis（D5/D2 未就绪不阻塞本步）。

**严禁**：硬编码标的；生产 mock 注册。

## §12 风险

| 触发 | 动作 |
|---|---|
| 0 active | 改 yaml 或 BLOCKED |
| LangGraph 版本差异 | pin langgraph 版本 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v3 中间道细化**：保留 v2 §3.5 13 项；§7.3 新增 4 个关键片段（四态枚举 + T1~T6 转移字典 / 三表 ORM 完整 schema / LangGraph 状态机骨架 / SoT 驱动注册）；170→~330 行 |
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 1300 行嵌入代码/bash；§3.5 13 项；SoT；`watch-step01-*`；1300→~220 行 |
| 2026-05-16 | 初版 1300 行 |
