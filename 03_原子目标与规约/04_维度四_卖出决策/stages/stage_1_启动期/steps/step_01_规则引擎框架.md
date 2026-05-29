# Step 01 · 规则引擎框架与 exit-engine 服务骨架

## §1 一句话定位与本步交付物

**一句话**：搭起 **exit-engine** 服务骨架（FastAPI `apps/exit_engine/`，port **8004**，DB `exit_engine.db`）+ 自研规则引擎抽象（`BaseSellProtocol` + `ProtocolRegistry` + `ConflictResolver`）+ ORM 三表（`positions / sell_signals / protocol_logs`）+ `events:exit:sell_signal` Stream 常量定义；为 step_02~08 的 4 类卖出协议（SP1~SP4）+ 冲突处理 + 回测提供地基。

**交付物**（勾选 = 完成）：
- [ ] **A**（骨架）：`apps/exit_engine/{api,db,protocols,events,engine}/`
- [ ] **B**（`BaseSellProtocol`）：抽象 `evaluate(position, context) -> SellDecision | None`；`priority`、`buffer_days` 属性
- [ ] **C**（ORM）：`positions / sell_signals / protocol_logs` + 索引
- [ ] **D**（ConflictResolver）：多协议触发时按 `priority` 升序选最高；**全部**触发记入 `protocol_logs` 审计
- [ ] **E**（`/health`）：含 db + redis + upstream `events:monitor:health_change` 探测
- [ ] **F**（Settings + Stream 常量）：`upstream_streams=[monitor:health_change]`；`downstream_stream=events:exit:sell_signal`
- [ ] **G**（单测 + Makefile）：`pytest` ≥10；`make exit-step01-all`

> **永久规则**：本步与全 D4 **只产卖出 `advice`**，**不**直接执行任何卖出；最终由架构师人工执行。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../01_实践目标与策略.md](../01_实践目标与策略.md)、[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md)
> - **DNA**：`_System_DNA/04_exit_engine/dna_stage_1_启动期.yaml` → `service_name: exit-engine`、`tech_stack.rule_engine`
> - **共享**：[13_六维度启动期集成与时序](../../../../_共享规约/13_六维度启动期集成与时序.md) §四 stream 表
> - **L4**：[实践记录_step_01_规则引擎框架.md](../../../../../04_阶段规划与实践/04_维度四_卖出决策/stage_1_启动期/实践记录_step_01_规则引擎框架.md)
> - **下游**：step_02~08

## §3 数据采集对象 / 落库映射

| 对象 | 表 | 关键字段 |
|---|---|---|
| 持仓 | `positions` | symbol, cost_price, current_price, holding_ratio, entered_at, thesis_id |
| 卖出信号 | `sell_signals` | signal_id, symbol, signal_type(SP1~4), trigger_price, current_price, advice, ts |
| *(SP5 预留)* | — | `sp5_window_protocol`：财报披露窗口协议字段，**待 Lighthouse-Alpha stage_2 SP5 step_01 落地**，本步无实现，仅占字段槽位；参考 `_drafts/lighthouse_alpha_stage_0_1.md` R07 |
| 协议触发审计 | `protocol_logs` | symbol, protocol_id, triggered, reason, conflict_winner, ts |

## §3.5 数据质量验收矩阵（骨架与规则引擎 · 仅启动期）

### §3.5.1 规则引擎契约

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| R1 | **BaseSellProtocol 抽象** | evaluate/priority/buffer_days | ✅ | — |
| R2 | **ProtocolRegistry** | 启动期注册 4 占位（实现在 step_03~06）| ✅ | — |
| R3 | **ConflictResolver** | priority 升序；全部记录 | ✅ 单测 4 协议同触发 | — |
| R4 | **advice 字段** | 必含人话建议（如 "建议卖出 50%"）| ✅ | — |

### §3.5.2 表结构

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| D1 | **positions.symbol UNIQUE** | 单标的单行 | ✅ | — |
| D2 | **sell_signals 仅 INSERT** | 不可改 | ✅ | — |
| D3 | **protocol_logs 全量记录** | 触发与否都写 | ✅ | — |
| D4 | **idempotent** | (signal_id) 唯一约束 | ✅ | — |

### §3.5.3 永久规则与契约

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| P1 | **不自动执行** | 无任何路径调用券商/交易 API | ✅ assert | — |
| P2 | **stream 名** | `events:exit:sell_signal` = 13_ §四 | ✅ | — |
| P3 | **upstream subscribe** | 订阅 `events:monitor:health_change`（SP3 用）| ⚠️ step_05 才硬需 | 启动期可 degraded |
| P4 | **stub-free** | 业务库不写假持仓 | ✅ | tests fixture 例外 |

> 共 **12 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| `DATABASE_URL` | exit_engine.db |
| `REDIS_URL` | upstream 探测 + 后续 publisher |
| 持仓 SoT（启动期可手填一次）| positions 初始化 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| /health 返 ok | ✅ |
| 单测 | ≥10 |
| 4 协议 placeholder | 注册（实现见 step_03~06）|

## §6 下一步

本步 ✅ → step_02 持仓数据接入与行情。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A 包骨架** | `apps/exit_engine/` | api/db/protocols/engine/events | tree |
| **B BaseSellProtocol** | `protocols/base.py` | 抽象 + dataclass SellDecision | 子类签名 |
| **C ProtocolRegistry** | `engine/registry.py` | dict id→protocol | 注册 4 占位 |
| **D ConflictResolver** | `engine/conflict.py` | priority 升序 + 审计 | 单测 4 同触发 |
| **E ORM 三表 + migration** | `db/models.py` + alembic | 索引 (symbol)、(signal_id) | alembic head |
| **F main + /health** | `api/main.py` | port 8004；探测 redis+db | curl 200 |
| **G config** | `config.py` | stream 常量；Settings | 打印可读 |
| **H 单测** | `test_engine.py` | ≥10 | pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `exit-step01-prep` | deps；redis 探测 |
| `exit-step01-migrate` | alembic head；3 表在 |
| `exit-step01-up` | uvicorn 8004；/health ok |
| `exit-step01-test` | pytest ≥10 |
| `exit-step01-all` | migrate+up+test |
| `exit-step01-status` | 注册协议数 + 表行数 |
| `exit-step01-clean` | dev only FORCE=1 |

### §7.3 关键代码片段（中间道）

#### 7.3.1 永久规则横幅 + no-auto-execute 常量（核心 ~8 行）

```python
# apps/exit_engine/__init__.py
"""
exit-engine · 卖出决策 · D4 服务模块

【永久规则】（与 L1 哲学基石⑤纪律一致）：
- 本模块**只**产 advice（建议），**不**调用任何券商/交易 API；
- 永久禁止 import broker SDK；最终卖出由架构师人工执行；
- 所有 SP1~SP4 协议**只**写 sell_signals.advice，不写"已卖出"状态。
"""
PERMANENT_RULE_NO_AUTO_EXECUTE = True
```

#### 7.3.2 BaseSellProtocol 抽象 + SellDecision dataclass（核心 ~15 行）

```python
@dataclass
class SellDecision:
    symbol: str
    signal_type: Literal["SP1","SP2","SP3","SP4"]
    advice: str                                       # 中文人话："建议卖出 50% 仓位"
    trigger_price: Optional[float]
    sell_ratio: float = Field(ge=0.0, le=1.0)          # 建议卖出比例
    reason_zh: str
    metadata: dict = field(default_factory=dict)       # SP1: 止损价；SP2: 估值；SP3: thesis_id 等

class BaseSellProtocol(ABC):
    protocol_id: str             # 'SP1'/'SP2'/'SP3'/'SP4'
    priority: int                # 1~4，越小越优先（SP1 止损=1）
    buffer_days: int = 0         # 缓冲日（避免抖动）

    @abstractmethod
    async def evaluate(self, position: Position, ctx: EvalContext) -> Optional[SellDecision]: ...
```

#### 7.3.3 ProtocolRegistry + ConflictResolver（核心 ~15 行）

```python
class ProtocolRegistry:
    def __init__(self):
        self._protocols: dict[str, BaseSellProtocol] = {}

    def register(self, protocol: BaseSellProtocol):
        if protocol.protocol_id in self._protocols:
            raise ValueError(f"duplicate protocol_id: {protocol.protocol_id}")
        self._protocols[protocol.protocol_id] = protocol

    def all(self) -> list[BaseSellProtocol]:
        return list(self._protocols.values())

class ConflictResolver:
    async def resolve(self, position, ctx, registry) -> tuple[Optional[SellDecision], list[dict]]:
        decisions, logs = [], []
        for proto in registry.all():
            decision = await proto.evaluate(position, ctx)
            logs.append({"protocol_id": proto.protocol_id,
                          "triggered": decision is not None,
                          "reason": decision.reason_zh if decision else "not triggered"})
            if decision: decisions.append((proto.priority, proto.protocol_id, decision))
        if not decisions: return None, logs
        decisions.sort(key=lambda x: (x[0], x[1]))      # 同优先级→protocol_id 升序
        winner = decisions[0][2]
        for log in logs:
            if log["protocol_id"] == decisions[0][1]: log["conflict_winner"] = True
        return winner, logs
```

#### 7.3.4 三表 ORM 关键约束（核心 ~12 行）

```python
class Position(Base):
    __tablename__ = "positions"
    symbol = Column(String(16), primary_key=True)
    cost_price = Column(Numeric(10, 4), nullable=False)
    current_price = Column(Numeric(10, 4))
    holding_ratio = Column(Numeric(5, 4), nullable=False)   # 0~1
    thesis_id = Column(String(32), nullable=True)
    entered_at = Column(DateTime, nullable=False)

class SellSignal(Base):
    __tablename__ = "sell_signals"
    signal_id = Column(String(32), primary_key=True)        # 仅 INSERT 不 UPDATE
    symbol = Column(String(16), index=True, nullable=False)
    signal_type = Column(Enum("SP1","SP2","SP3","SP4", name="signal_type"))
    advice = Column(String(256), nullable=False)            # 中文人话
    sell_ratio = Column(Numeric(5, 4), nullable=False)
    ts = Column(DateTime, nullable=False, index=True)
    # ★ 不存在 "executed_at" / "broker_order_id" 字段（永久规则强制）
```

### §7.4 指引

先骨架→ORM→Base/Registry/Resolver→main/health；4 协议占位仅返 None，实现在 step_03~06；ConflictResolver 单测覆盖"同优先级取协议 id 升序"边界。

## §8 部署节奏

本机 `uvicorn apps.exit_engine.main:app --port 8004`；K3s 扩展期。

## §9 准出标准

- [ ] §3.5 12 项；/health ok
- [ ] 4 占位协议已注册；ConflictResolver 单测全过
- [ ] `make exit-step01-all`；L4 回写

## §10 [Deploy]

启动期本机；后续与 step_07 publisher 同包合并。

## §11 依赖

无硬上游；软依赖 D3 health_change（SP3 用）。

**严禁**：自动执行卖出；硬编码持仓列表；stub 写业务库。

## §12 风险

| 触发 | 动作 |
|---|---|
| 4 协议优先级歧义 | 见 DNA 表；ADR 写边界 |
| Redis 不可用 | /health degraded；不阻塞本步 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v3 中间道细化**：保留 v2 §3.5 12 项；§7.3 新增 4 个关键片段（永久规则横幅 + no-auto-execute 常量 / BaseSellProtocol 抽象 + SellDecision dataclass / ProtocolRegistry + ConflictResolver 完整算法 / 三表 ORM 强约束含禁字段注释）；151→~330 行 |
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 1144 行嵌入；§3.5 12 项；no-auto-execute；`exit-step01-*`；1144→~210 行 |
| 2026-05-16 | 初版 1144 行 |
