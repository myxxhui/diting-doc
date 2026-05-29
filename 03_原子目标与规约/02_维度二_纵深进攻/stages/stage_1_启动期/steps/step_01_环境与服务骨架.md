# Step 01 · 环境与服务骨架（deep-strike FastAPI + SQLite + Redis 契约）

## §1 一句话定位与本步交付物

**一句话**：搭起 `deep-strike` 服务骨架（FastAPI 8082 + SQLite 业务表 + Redis Stream 契约探测），让 step_02~10 有地基；**永久规则**在代码层显式声明「AI 不可自动建仓」。

**交付物**（勾选 = 完成）：
- [ ] **A**（项目骨架）：`apps/deep_strike/` 包结构齐全（`api/`、`db/`、`engines/`、`events/`、`playbooks/`、`data/`、`config.py`）；`pyproject.toml` 依赖齐
- [ ] **B**（永久规则横幅）：`apps/deep_strike/__init__.py` 顶部声明 + 注释约束；`_promote_to_confirmed` 唯一入口占位（step_08 实现）
- [ ] **C**（FastAPI 骨架）：`uvicorn apps.deep_strike.main:app --port 8082` 可起；`/health` 含 `dependencies/upstream_streams/downstream_stream` 三段
- [ ] **D**（SQLite 4 张业务表）：`thesis_cards / scan_logs / evidence_records / human_confirmations` schema 就绪（空表）
- [ ] **E**（Settings + Redis 契约）：`upstream_streams` 含 `events:cryo_guard:pass`；`downstream_stream=events:thrust:thesis_proposed`；Redis 连通性探测
- [ ] **F**（API 路由空壳）：`/api/playbooks`、`/api/thesis`（占位 501/initializing）
- [ ] **G**（单测）：`pytest tests/deep_strike/test_health.py -v` ≥ 5 passed
- [ ] **H**（Makefile 一键复现）：`make deep-step01-all` 端到端通过

> **本步是 step_02~10 的硬阻塞**；与 D1 step_01 可并行，但本步**不**重复建 vLLM（复用 D1 集群 vllm-svc）。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2 哲学**：[02_维度二_纵深进攻 · 04_实践策略规划](../../../../../02_战略维度/02_维度二_纵深进攻/04_实践策略规划.md)（能力圈 + 纵深）
> - **L1 哲学**：[06_投资哲学体系总纲](../../../../../01_顶层概念/06_投资哲学体系总纲.md) 基石 ③能力圈、⑥纵深
> - **本阶段总览**：[stage_1_启动期/README](../README.md)
> - **L3 技术方案**：[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §一 技术选型、§二 代码结构、§四 API、§五 DB
> - **L3 策略**：[../01_实践目标与策略.md](../01_实践目标与策略.md) §1.3 交付物、§3.1 决策机制、永久规则
> - **DNA 键**：`_System_DNA/02_deep_strike/dna_stage_1_启动期.yaml` → `service_name=deep-strike`、`work_dir`、`tech_stack`、`dependencies.upstream`
> - **共享规约**：[13_六维度启动期集成与时序](../../../../_共享规约/13_六维度启动期集成与时序.md) §三 推荐池闭环、§四 事件流 · [14_六维度启动期统一节奏表](../../../../_共享规约/14_六维度启动期统一节奏表.md)
> - **L4 实践记录**：[实践记录_step_01_环境与服务骨架.md](../../../../../04_阶段规划与实践/02_维度二_纵深进攻/stage_1_启动期/实践记录_step_01_环境与服务骨架.md)
> - **上游 step**：← 无（D2 启动期入口）；软依赖 D1 Redis、D5 训练底座（未就绪时本步仅探测 + 标 degraded）
> - **下游 step**：→ step_02（ORM 扩展 + 采集）、step_03~10

## §3 数据采集对象 / 落库映射

**本步不涉及数据采集**——仅建 ORM 表结构与空 SQLite。

### §3.1 4 张表 schema 简表（启动期空表）

| 表 | 关键列 | 约束 / 索引 |
|---|---|---|
| `thesis_cards` | id PK / thesis_id VARCHAR(32) UNIQUE / symbol / company_name / status ENUM(proposed/confirmed/rejected/deferred) / playbook_id / catalyst / valuation_json TEXT / risk_json TEXT / exit_conditions TEXT / created_at / updated_at | `INDEX(symbol, status)`、`INDEX(playbook_id)` |
| `scan_logs` | id PK / scan_id UNIQUE / playbook_id VARCHAR(64) / symbol / scan_time DATETIME / signal_features JSON / triggered BOOLEAN / score NUMERIC(6,4) / latency_ms | `INDEX(playbook_id, scan_time DESC)` |
| `evidence_records` | id PK / evidence_id UNIQUE / thesis_id FK / source_type ENUM(financial_report/announcement/related_party/news) / source_id / source_period / human_readable_reason TEXT / weight NUMERIC(4,2) | `INDEX(thesis_id)` |
| `human_confirmations` | id PK / thesis_id FK UNIQUE / decision ENUM(confirm/reject/defer) / reviewer_email VARCHAR(128) / decided_at DATETIME / comment TEXT | **本表是 confirmed 状态的唯一入口**（step_08 实现 `_promote_to_confirmed()` 仅在此写入后才能改 thesis_cards.status） |

> **永久规则强化**：UI 或 API 调用直接将 `thesis_cards.status` 改为 `confirmed` 而不经 `human_confirmations` 视为违规（step_08 加 trigger 强约束）。

## §3.5 数据质量验收矩阵（工程基座 + 永久规则审计 · 共 12 项）

### §3.5.1 服务可用

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| I1 | **FastAPI :8082 起** | `curl :8082/health` 200 | ✅ |
| I2 | **健康检查三段** | dependencies + upstream_streams + downstream_stream 字段齐 | ✅ |
| I3 | **Redis db=2 隔离** | `redis-cli -n 2 PING` PONG；与 D0/D1 区分 | ✅ |
| I4 | **vLLM 共享 D1 探测** | health 中 dependencies.vllm 可达或标 unavailable | ✅ / ⚠️ |

### §3.5.2 ORM & 永久规则

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| I5 | **4 张表全建** | `.tables` 4 张含 `human_confirmations` | ✅ |
| I6 | **status 枚举完整** | 4 枚举值（proposed/confirmed/rejected/deferred）| ✅ schema check |
| I7 | **human_confirmations.thesis_id UNIQUE** | 1 thesis 仅 1 次人工确认 | ✅ |
| I8 | **永久规则横幅** | `apps/deep_strike/__init__.py` 含 `PERMANENT_RULE_NO_AUTO_TRADE = True` 常量 + 中文 docstring | ✅ |
| I9 | **`_promote_to_confirmed` 唯一入口** | grep 全仓 `thesis_cards.*confirmed.*update` 仅出现在 `step_08` 路径 | ⚠️ 本步预留约束 |
| I10 | **no broker / no auto-order** | `rg "broker_api\|place_order\|auto_buy\|auto_sell" apps/deep_strike/` = 0 | ✅ |
| I11 | **Stream 名固定** | upstream=`events:cryo_guard:pass`、downstream=`events:thrust:thesis_proposed`；env 化但 default 一致 | ✅ |
| I12 | **single source of recommendation** | UI 推荐池**只**显示 status=confirmed 的 thesis；UI 测试 grep `status.in_(['proposed','rejected'])` 不出现在公开页 | ✅ |

## §4 真实数据源与凭证清单

### §4.1 资源来源

| 资源 | 来源 | 备注 |
|---|---|---|
| Redis 7 | step_01 D0/D1 已起 | db=2 建议给 D2（与 D0 db=0、D1 db=1 区分）|
| SQLite | 本机 `data/deep_strike.db` | 与 `cryo_guard.db` 分离 |
| vLLM | D1 step_01 已部署 | 本步仅 health 探测，不重复部署 |

### §4.2 用户须提供的凭证

| 凭证 | 用途 | 何时需要 | 写在哪里 |
|---|---|---|---|
| `MY_HOLDINGS_YAML` | 持仓 SoT（step_02 起用）| step_02 前配置 | `diting-src/.env` |
| `REDIS_URL` | Stream 契约探测 | 本步 | `diting-src/.env`（默认 `redis://localhost:6379/2`）|

> **本步无需** Teacher key / GPU / ACR。

## §5 启动期目标

### §5.1 服务设计

| 项 | 取值 | 理由 |
|---|---|---|
| 服务名 | `deep-strike` | DNA 约定 |
| 端口 | 8082 | 与 cryo-guard 8081 区分 |
| 包路径 | `apps/deep_strike/` | 与 D1 `apps/cryo_guard/` 平行 |
| 上游 Stream | `events:cryo_guard:pass` | D1 decision_gate 放行后 D2 消费 |
| 下游 Stream | `events:thrust:thesis_proposed` | D0 副驾驶消费 |
| 永久规则 | 代码横幅 + 文档约束 | L1 禁止自动建仓 |

### §5.2 数据量预期（必要不充分）

| 指标 | 启动期最小值 | 验证 |
|---|---|---|
| ORM 表 | 4 张 | `sqlite3 data/deep_strike.db ".tables"` |
| `/health` 200 | 含 upstream_streams 探测结果 | `curl :8082/health` |
| Redis PING | PONG（db=2）| `redis-cli -n 2 PING` |

### §5.3 可接受退化

- `events:cryo_guard:pass` 尚未有消息 → health 标 `upstream_ready=false`，**不阻塞**本步准出；
- Redis 不可用 → health 标 degraded，step_09 前必须修复。

## §6 下一步（一行触发条件）

- **触发条件**：本步全部 ✅ → step_02 可开工（扩展 ORM + 真实财务/公告采集）。
- **下一阶段方向**：扩展期多副本 + Helm Chart；详见 `stages/stage_2_扩展期/`。

## §7 实施规划（L3 设计 · 给后续执行模型的工作指引）

> **L3 定位**：设计规划 + 实现要点 + 验证标准；**不嵌入**完整 Python 类 / FastAPI 路由代码。

### §7.1 实现要点

| 实现要点 | 涉及代码位置 | 关键设计决策 | 验证标准 |
|---|---|---|---|
| **A 目录骨架** | `apps/deep_strike/{api,db,engines,events,playbooks,data}/` | 与 L3 §二 代码结构 1:1；每子包 `__init__.py` | `find apps/deep_strike -name "*.py" \| wc -l` ≥ 15 |
| **B 永久规则横幅** | `apps/deep_strike/__init__.py` | 模块 docstring 声明「禁止自动建仓」；导出 `PERMANENT_RULE_NO_AUTO_TRADE=True` 常量供测试断言 | 单测 import 可读横幅文本 |
| **C Settings** | `apps/deep_strike/config.py` | pydantic-settings：`database_url / redis_url / upstream_streams / downstream_stream / vllm_base_url`；从 `.env` 加载 | `settings.dict()` 含 5 键 |
| **D DB session + 4 表 ORM** | `db/database.py`、`db/models.py` | `ThesisCard`（thesis_id PK, status enum proposed/confirmed/rejected/deferred）；`ScanLog`；`EvidenceRecord`；`HumanConfirmation`（thesis_id + decision + reviewer + decided_at）| `alembic upgrade head` 后 4 表存在 |
| **E FastAPI main + health** | `main.py`、`api/routes/health.py` | `/health` 三段：dependencies（redis/vllm 可达性）、upstream_streams（XINFO 或 XRANGE 探测 pass 流是否存在）、downstream_stream（配置展示）| curl JSON 结构完整 |
| **F API 空壳路由** | `api/routes/playbooks.py`、`api/routes/thesis.py` | 返回 `status=initializing` + 501 占位；不实现业务 | 路由注册不 404 |
| **G 单测** | `tests/deep_strike/test_health.py` | mock Redis；TestClient `/health`；永久规则常量断言 | ≥ 5 passed |

### §7.2 Makefile 一键复现合约

| target | 用途 | 入参 | 验证标准 |
|---|---|---|---|
| `make deep-step01-skeleton` | 创建目录 + 空 `__init__.py` | — | py 文件数 ≥ 15 |
| `make deep-step01-deps` | `uv pip install -e .` | — | import fastapi, sqlalchemy, redis 成功 |
| `make deep-step01-db-init` | alembic + 4 表 | `DATABASE_URL` | `.tables` 含 4 张 |
| `make deep-step01-run` | 起 uvicorn 8082 | — | `/health` 200 |
| `make deep-step01-test` | 单测 | — | ≥ 5 passed |
| `make deep-step01-all` | 端到端一键 | 同上 | 全部退出码 0 |
| `make deep-step01-status` | 只读快照 | — | 表数 + health 摘要 |
| `make deep-step01-clean` | 清 db（**不**清 models/）| `FORCE=1` | 表清空 |

**合约要求**：入参环境变量化；可重入幂等；失败中文 3 行摘要。

### §7.3 关键代码片段（中间道 · 非完整模块）

#### 7.3.1 永久规则横幅（核心 ~8 行）

```python
# apps/deep_strike/__init__.py
"""
deep-strike · 纵深进攻 · D2 服务模块

【永久规则】（与 L1 哲学基石③能力圈、⑥纵深一致）：
- 本模块**禁止**调用任何券商交易 API；
- thesis_cards.status 改为 'confirmed' **必须**先在 human_confirmations 写入；
- 任何 AI 推荐**只**到 'proposed' 为止，confirm 是人类不可代理的动作。
"""
PERMANENT_RULE_NO_AUTO_TRADE = True
PERMANENT_RULE_HUMAN_CONFIRM_ONLY = True
```

#### 7.3.2 `/health` JSON schema（核心 ~15 行 · response 示例）

```json
{
  "status": "ok",
  "service": "deep-strike",
  "version": "0.1.0",
  "permanent_rule_no_auto_trade": true,
  "dependencies": {
    "redis": {"ok": true, "db": 2, "url_masked": "redis://localhost:6379/2"},
    "sqlite": {"ok": true, "tables": 4},
    "vllm": {"ok": false, "reason": "shared with cryo_guard · not required in step_01"}
  },
  "upstream_streams": {
    "events:cryo_guard:pass": {"exists": false, "latest_id": null, "lag_ms": null, "ready": false}
  },
  "downstream_stream": "events:thrust:thesis_proposed",
  "configured_playbooks": [],
  "uptime_s": 12
}
```

#### 7.3.3 `thesis_cards` + `human_confirmations` ORM 关键约束（核心 ~15 行）

```python
class ThesisCard(Base):
    __tablename__ = "thesis_cards"
    id = Column(Integer, primary_key=True)
    thesis_id = Column(String(32), unique=True, nullable=False, index=True)
    symbol = Column(String(16), nullable=False)
    status = Column(
        Enum("proposed", "confirmed", "rejected", "deferred", name="thesis_status"),
        nullable=False, default="proposed", server_default="proposed", index=True,
    )
    # ... playbook_id, catalyst, valuation_json, risk_json, exit_conditions, created_at, updated_at

class HumanConfirmation(Base):
    __tablename__ = "human_confirmations"
    thesis_id = Column(String(32), ForeignKey("thesis_cards.thesis_id"),
                       unique=True, nullable=False)   # 1:1 强约束
    decision = Column(Enum("confirm","reject","defer", name="confirm_decision"))
    reviewer_email = Column(String(128), nullable=False)
    decided_at = Column(DateTime, nullable=False)
```

#### 7.3.4 Stream 上游存在性探测（核心 ~10 行）

```python
async def probe_upstream(redis: Redis, stream: str) -> dict:
    try:
        info = await redis.xinfo_stream(stream)
        return {"exists": True, "latest_id": info["last-generated-id"],
                "length": info["length"], "ready": info["length"] > 0}
    except ResponseError as e:
        if "no such key" in str(e).lower():
            return {"exists": False, "latest_id": None, "length": 0, "ready": False}
        raise
```

### §7.4 给后续执行模型的指引

1. 核对 `.env` 含 `REDIS_URL`、`MY_HOLDINGS_YAML`（step_02 用）；
2. 顺序 A→G；每步可独立验证；
3. 集成 Makefile 后跑 `make deep-step01-all`；
4. §9 准出 + L4 回写；
5. 遇问题先 Verify First；同问题 ≥ 2 次失败 §8.4f 回收。

> **L3 责任边界**：不给完整 Python 实现；交给 L4 / 后续模型。

## §8 部署节奏（本步在哪里跑）

| 阶段 | 形态 | 必须 | 说明 |
|---|---|---|---|
| **本机开发** | uvicorn + pytest | **是** | 骨架 / ORM / 单测 |
| **Dev K3s** | — | 否 | step_09 前再部署 deep-strike Pod |
| **ACR + 生产** | 扩展期 | 否 | 启动期本机 + 8082 足够 |

**默认形态**：仅本机。

## §9 准出标准

### §9.1 骨架与依赖
- [ ] `find apps/deep_strike -name "*.py" \| wc -l` ≥ 15
- [ ] `uvicorn apps.deep_strike.main:app --port 8082` + `curl :8082/health` 200

### §9.2 工程 + 一键复现
- [ ] `make deep-step01-all` 通过
- [ ] `pytest tests/deep_strike/test_health.py -v` ≥ 5 passed
- [ ] L4 实践记录已更新（含 Redis db 号、永久规则横幅截图/摘要）
- [ ] commit：`feat(deep-strike): step_01 服务骨架 + 永久规则 + Makefile [Ref: 03_/02_维度二/.../step_01]`

## §10 [Deploy] 段

本步**不**产出 K8s 镜像；扩展期在 `deploy/k3s/deep-strike-deployment.yaml` 落地。deploy-engine 自检同 D1。

## §11 依赖与被依赖

**上游**：Redis（D0/D1 共用实例）；软依赖 D1 `events:cryo_guard:pass`（未就绪可 degraded）。

**下游**：step_02~10 全部阻塞本步 ORM + FastAPI。

**严禁伪造**：health 不得伪造 `upstream_ready=true` 当 Stream 不存在且无 ADR。

## §12 风险与回退

| 触发条件 | 动作 |
|---|---|
| Redis 不可达 | 修 REDIS_URL；本步可 degraded 准出但 L4 须写明阻塞 step_09 |
| alembic 冲突 | 新 revision；禁止手改 db |
| 同问题 ≥ 2 次失败 | §8.4f 回收 |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v3 中间道细化**：保留 v2 三段式 §7；新增 §3.1 4 张表 schema 简表（含 human_confirmations 唯一入口约束）、§3.5 工程基座 + 永久规则审计矩阵 12 项（I1~I12 grep 永久规则）；§7.3 5 个关键片段（永久规则横幅 / health JSON schema / ThesisCard+HumanConfirmation ORM 强约束 / Stream 上游探测）；186→~340 行 |
| 2026-05-20 | **v2 按 L3 启动期模板 v1.2 重写**：删除嵌入 Python；§7 实施规划 + Makefile `deep-step01-*`；清除 mock 策略表述；永久规则 + Stream 契约；持仓 SoT 前置说明；846 行 → ~280 行 |
| 2026-05-16 | 初版（含完整 Python + mock 策略），846 行 |
