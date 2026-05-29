# Step 01 · copilot 后端依赖 + 服务骨架 + 7 stream 健康检查（v3 细化融合版）

## §1 一句话定位与本步交付物

**一句话**：在 `diting-src` 仓内搭起 **copilot** FastAPI 服务骨架（port **8080**）+ HTMX/Alpine.js/Jinja2/SQLite/Redis 技术栈，落地 **`/health` 端点对 7 条上游事件流的可达性自检**，并为 step_02~10 的 4 个子模块（M1 体检 / M2 推荐池 / M3 告警 / M4 价值账本）提供"地基"（包结构 + 依赖 + 配置 + Redis 异步客户端 + 测试夹具）。

**交付物**（勾选 = 完成）：

- [ ] **A**（包骨架）：`apps/copilot/{main.py,config.py,routers/,services/,models/,events/,templates/,static/,scheduler/}` + `tests/copilot/`
- [ ] **B**（依赖）：`fastapi / uvicorn[standard] / redis>=5 / sqlalchemy>=2 / aiosqlite / jinja2 / httpx / pydantic-settings / apscheduler / python-multipart / WeasyPrint`，并写进 `pyproject.toml`（`requires-python = ">=3.9"`）
- [ ] **C**（FastAPI 起服务）：`python3 -m uvicorn apps.copilot.main:app --host 127.0.0.1 --port 8080` 成功；`curl /health` 返回 200 且包含 `status: ok`
- [ ] **D**（7 stream 自检）：`/health` 体内 `upstream` 字段对 **7 条 stream** 各报告 `{ok, length|reason}`，含
  - `events:cryo_guard:reject` / `events:cryo_guard:degrade` / `events:cryo_guard:pass`
  - `events:thrust:thesis_proposed`
  - `events:monitor:health_change`
  - `events:exit:sell_signal`
  - `events:flywheel:lora_updated`
- [ ] **E**（Settings）：`CopilotSettings`（pydantic-settings v2，前缀 `COPILOT_`）覆盖 Redis URL、DB URL、stream 名常量、告警渠道占位；`.env.template` 同步
- [ ] **F**（Redis 异步客户端）：`apps/copilot/services/redis_client.py` 暴露 `get_redis()` lifespan 单例 + `xlen_safe()` 包装（连不上时返 `reason="connection refused"`，不抛异常）
- [ ] **G**（单测）：`tests/copilot/` 含 `test_health.py` / `test_settings.py` / `test_stream_constants.py`，至少 **≥6 条用例**，目标全套 ≥ 40 条，全部通过
- [ ] **H**（Makefile 合约）：`copilot-step01-prep/up/health/test/all/status` 一键复现

> **联调收紧口**：本步允许某些 stream **不存在**（`XLEN` 报 `no such key` 视为 `mock mode`，不视为失败）；真正的"7 条都必须有真消息"在 **step_09 全链路联调** 时收紧（届时 `upstream.*.length` 必须均 ≥ 1）。

> **永久规则（D0）**：副驾驶**观察者模式**——系统建议 → 用户自主决定 → 系统记录；**禁止**自动下单/自动建仓的任何代码路径（含但不限于：调用券商 API、写入"已下单"状态、Notify "已成交"）。本步若在搜索引擎中出现 `place_order / submit_order / trade.*execute` 等关键字必须人工复核。

> **数据细节**：本机已通过 `Python 3.9.6` 全套 48 用例（耗时 ~2.27s），证明 `requires-python = ">=3.9"` 合理；若团队推 3.10+ 走 ADR。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[../01_实践目标与策略.md](../01_实践目标与策略.md)、[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §代码结构
> - **DNA**：[`_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml`](../../../../_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml) 中 `tech_stack`、`service_name: copilot`、`product_mode: 观察者模式`、`dependencies.upstream`（5 个维度对应 7 条 stream）
> - **共享规约**：[13_六维度启动期集成与时序](../../../../_共享规约/13_六维度启动期集成与时序.md) §四（事件流契约）、[14_六维度启动期统一节奏表](../../../../_共享规约/14_六维度启动期统一节奏表.md)
> - **L4**：[实践记录_W01_后端依赖与服务骨架](../../../../../04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/实践记录_W01_后端依赖与服务骨架.md) — 含本机 48 passed、Python 3.9.6 实测、`COPILOT_REDIS_URL` 环境变量约定
> - **下游 step**：step_02（Web 骨架与 SQLite）/ step_03（M1 体检）/ step_04（M2 推荐池）/ step_05（M3 告警）/ step_06（M4 价值账本）/ step_09（全链路联调，收紧 stream 必填）
> - **跨仓约定**：Redis 容器统一为 `diting-redis`、`127.0.0.1:6379/0`（见 [steps/README · 〇-1 redis-docker-lifecycle](../README.md#redis-docker-lifecycle)）

## §3 数据采集对象与落库映射

**本步不采集业务数据**——仅依赖、骨架、配置；SQLite 与 Redis 数据写入留待 step_02+。

| 数据/资源 | 位置 | 本步状态 | 下游何时写 |
|---|---|---|---|
| `copilot.db`（SQLite） | `diting-src/data/copilot.db` | **空文件占位**（不建表） | step_02 建表（`users / portfolios / holdings / events_audit / value_ledger`） |
| Redis stream 探测 | `diting-redis @ 127.0.0.1:6379/0` | **只读 XLEN**；可空 | step_03~08 各 consumer 接入 |
| 静态资源 | `apps/copilot/static/` | 空目录占位 | step_02 引入 HTMX/Alpine.js |
| 模板 | `apps/copilot/templates/` | 空目录占位 | step_02 起 Jinja2 base.html |

### §3.1 7 条 upstream stream 详表（本步只检测可达性）

| # | Stream Key | 上游维度 | Producer step | 本步 `/health` 期望 | step_09 收紧后期望 |
|---|---|---|---|---|---|
| 1 | `events:cryo_guard:reject` | D1 极寒防御 | D1 step_06+ | `mock mode` 或 `length=N` | `length ≥ 1`（真拒绝事件） |
| 2 | `events:cryo_guard:degrade` | D1 极寒防御 | D1 step_06+ | `mock mode` 或 `length=N` | `length ≥ 1`（真降级事件） |
| 3 | `events:cryo_guard:pass` | D1 极寒防御 | D1 step_06+ | `mock mode` 或 `length=N` | `length ≥ 1`（真通过事件） |
| 4 | `events:thrust:thesis_proposed` | D2 纵深进攻 | D2 step_08+ | `mock mode` 或 `length=N` | `length ≥ 1`（5 必填齐全） |
| 5 | `events:monitor:health_change` | D3 持仓监控 | D3 step_07+ | `mock mode` 或 `length=N` | `length ≥ 1`（push_level/score） |
| 6 | `events:exit:sell_signal` | D4 卖出决策 | D4 step_07+ | `mock mode` 或 `length=N` | `length ≥ 1`（含 protocol_id） |
| 7 | `events:flywheel:lora_updated` | D5 演进飞轮 | D5 step_08+ | `mock mode` 或 `length=N` | `length ≥ 1`（含 lora_version） |

**约定**：以上 stream key 在 `apps/copilot/events/stream_names.py` 集中常量化，禁止散落硬编码；与 13_共享规约 §四（事件流契约表）保持完全一致。

## §3.5 数据质量验收矩阵（本步：工程质量视角）

本步无业务数据采集；§3.5 矩阵以"地基工程的可观测性"为主。

| 分析维度 | 必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|
| **服务存活** | `GET /health` 200，`status="ok"`、`service="copilot"`、`version` | ✅ | 不允许降级；若 200 失败则本步 fail |
| **Redis 可达** | `/health` 体内 `redis.ok=true`，`redis.latency_ms`（毫秒） | ✅ | Redis down 时 `redis.ok=false` + `reason`；服务级仍 200 |
| **7 stream 自检结构** | 每条 stream 报 `{key, ok, length?, reason?}` | ✅ | 流不存在 → `reason="stream not found (mock mode)"`；连接拒绝 → `reason="connection refused"` |
| **stream 名常量化** | `apps/copilot/events/stream_names.py` 含 7 条 key | ✅ | 必填；本步禁止散落字符串 |
| **依赖锁版本** | `pyproject.toml` 全部依赖含下限版本（FastAPI ≥0.110、redis ≥5、SQLAlchemy ≥2） | ✅ | 锁版本写入 ADR；不锁会被工程拒收 |
| **环境模板** | `.env.template` 与代码 `Settings` 字段 1:1 | ✅ | 缺一项失败；用 `pytest tests/copilot/test_settings.py` 校验 |
| **目录骨架** | `apps/copilot/{routers,services,models,events,templates,static,scheduler}/__init__.py` 存在 | ✅ | 缺包导致后续 step 路径冲突；CI 校验 |
| **lifespan 释放** | `redis.aclose()` 在 shutdown；进程退出 30s 内 fd 被回收 | ✅ | 不可降级；写测试 `test_lifespan_close.py` |
| **错误处理纪律** | `xlen_safe()` 包装所有 `XLEN`，错误转结构化 reason 不冒泡 | ✅ | 任何 `XLEN` 抛错冒泡到 `/health` 路由 → 本步 fail |
| **测试覆盖** | `tests/copilot/` ≥6 条，目标 ≥40（含 health/settings/stream/redis_client/lifespan） | ✅ | <6 不准出 |
| **no-mock 资产** | 业务路径不出现 `events:thrust:thesis_proposed` 等的伪造 payload | ✅ | 仅 health 路由用 `mock mode` 文字描述"流未创建"；不得伪造业务消息 |
| **永久规则（no-auto-order）** | `rg "place_order|submit_order|broker_api"` 在 `apps/copilot/` 下命中数 = 0 | ✅ | 任何命中本步 fail |

**启动期标的可以少，但本步质量项必须全绿**。逐项验证命令见 §9。

## §4 凭证清单与环境模板

### §4.1 用户必须提供的凭证

| 凭证 / 环境变量 | 用途 | 何时需要 | 落地位置 |
|---|---|---|---|
| `COPILOT_REDIS_URL` | Redis stream 探测 | 本步即需（默认 `redis://127.0.0.1:6379/0`） | `diting-src/.env` |
| `COPILOT_DATABASE_URL` | SQLite 路径 | step_02 起 | `diting-src/.env`，默认 `sqlite+aiosqlite:///./data/copilot.db` |
| `COPILOT_SERVICE_NAME` | 服务标识 | 可选 | `.env`，默认 `copilot` |
| `COPILOT_LOG_LEVEL` | 日志级别 | 可选 | `.env`，默认 `INFO` |
| `WECHAT_WEBHOOK_URL` | M3 告警渠道 | step_05 前 | `.env` 占位 |
| `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID` | M3 告警渠道 | step_05 前 | `.env` 占位 |
| `RESEND_API_KEY` / `RESEND_FROM_EMAIL` | M3 告警邮件 | step_05 前 | `.env` 占位（免费额度内） |
| `ANTHROPIC_API_KEY` | 月报 LLM 解读（可选）| step_08 前 | `.env` 占位 |

### §4.2 `.env.template` 必含片段

```text
# ============ copilot service ============
COPILOT_SERVICE_NAME=copilot
COPILOT_LOG_LEVEL=INFO
COPILOT_REDIS_URL=redis://127.0.0.1:6379/0
COPILOT_DATABASE_URL=sqlite+aiosqlite:///./data/copilot.db

# ---------- 7 upstream streams ----------
COPILOT_STREAM_CRYO_REJECT=events:cryo_guard:reject
COPILOT_STREAM_CRYO_DEGRADE=events:cryo_guard:degrade
COPILOT_STREAM_CRYO_PASS=events:cryo_guard:pass
COPILOT_STREAM_THESIS=events:thrust:thesis_proposed
COPILOT_STREAM_HEALTH=events:monitor:health_change
COPILOT_STREAM_SELL=events:exit:sell_signal
COPILOT_STREAM_LORA=events:flywheel:lora_updated

# ---------- M3 alert channels (step_05) ----------
WECHAT_WEBHOOK_URL=
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=
RESEND_API_KEY=
RESEND_FROM_EMAIL=

# ---------- optional ----------
ANTHROPIC_API_KEY=
```

> 合并到 `diting-src/.env` 时遵守 §7.2 第 13 条：**不得覆盖用户已填的密钥/真实值**；仅追加缺失键并保留注释。

## §5 启动期目标

| 指标 | 启动期门槛 | 测量方式 |
|---|---|---|
| `GET /health` 状态码 | 200（无论 Redis 是否就绪） | `curl -o /dev/null -w "%{http_code}" /health` |
| `/health` 体格式 | 含 `status / service / version / redis / upstream(7 keys)` | `jq` 校验字段集合 |
| 7 stream 自检字段齐 | `upstream` 必须有 7 键 | `test_health.py::test_health_upstream_has_seven` |
| Redis 探测耗时 | 单 stream `XLEN` < 100ms（本机 localhost） | `/health.redis.latency_ms < 100` |
| `/health` 整体耗时 | < 500ms（含 7 次 `XLEN`） | `time curl -s /health` |
| `pytest tests/copilot/` | 全过；本步至少 ≥6 用例 | `pytest -q --maxfail=1` |
| 依赖装齐 | `pip install -e .` 退出码 0 | install 输出末尾 `Successfully installed` |
| no-auto-order 扫描 | `apps/copilot/` 命中 `place_order|submit_order|broker_api` 数 = 0 | `rg -c "place_order\|submit_order\|broker_api" apps/copilot/` |

## §6 下一步

本步 ✅ → **step_02 Web 骨架与 SQLite**（建表 `users/portfolios/holdings/events_audit/value_ledger`、Jinja2 `base.html`、Lighthouse ≥90）。

不展开扩展期/完善期细节（扩展期触发：架构师在 L5 标 `d0s1` 通过后启动）。

## §7 实施规划（细化版 · 给后续执行模型）

### §7.1 实现要点（位置 / 输入 / 核心逻辑 / 关键字段 / 错误处理 / 验证）

| # | 要点 | 位置 | 输入 | 核心逻辑 | 关键字段 / 输出 | 错误处理 | 验证标准 |
|---|---|---|---|---|---|---|---|
| 1 | **包骨架** | `apps/copilot/` | — | 创建 9 子包 + 各自 `__init__.py` | `routers/services/models/events/templates/static/scheduler` | 缺包 CI fail | `find apps/copilot -name __init__.py \| wc -l ≥ 9` |
| 2 | **依赖 + pyproject** | `diting-src/pyproject.toml` | 依赖清单 | 追加 11 个依赖（含版本下限）；`packages` 含 `apps*` | `pyproject.toml` 末段 `[tool.setuptools.packages.find]` 含 `apps*` | conflict 用 `pip install -e . --dry-run` 预检 | `pip install -e . && pip show fastapi \| grep Version` |
| 3 | **CopilotSettings** | `apps/copilot/config.py` | `.env` | pydantic-settings v2；`SettingsConfigDict(env_prefix="COPILOT_", env_file=".env")`；含 7 stream 字段 + DB + Redis + 告警渠道 | `redis_url / database_url / stream_* / service_name` | 缺字段 → ValidationError；写 `test_settings_loads_minimal` | `python3 -c "from apps.copilot.config import settings; print(settings.dict())"` |
| 4 | **stream 名常量** | `apps/copilot/events/stream_names.py` | settings | 集中导出 `STREAM_CRYO_REJECT / ...` 7 个常量 + `ALL_STREAMS: list[str]` | 7 行常量 | 与 settings 不一致 → 单测拦截 | `test_stream_constants_match_settings` |
| 5 | **redis client** | `apps/copilot/services/redis_client.py` | settings | 异步 `redis.asyncio.Redis.from_url(...)`；`get_redis()` lifespan 单例；`xlen_safe(stream)` → `{ok, length\|reason}` | `get_redis() -> Redis`、`xlen_safe(stream) -> dict` | `redis.ConnectionError` 转 `reason="connection refused"`；`ResponseError("no such key")` 转 `reason="stream not found (mock mode)"` | `test_redis_client.py` 覆盖三分支 |
| 6 | **FastAPI main + lifespan** | `apps/copilot/main.py` | settings | `@asynccontextmanager` lifespan：startup 装载 redis；shutdown 调 `redis.aclose()`；mount `routers.health` | `app = FastAPI(title="copilot", version=...)` | 启动失败 fail-fast；shutdown 异常打日志 | `uvicorn` 起；ctrl+c 后 30s 内退出 |
| 7 | **/health 路由** | `apps/copilot/routers/health.py` | request.app.state.redis | 并发 `XLEN` 7 stream（`asyncio.gather`）；汇总；服务级 ok = redis ok ∧ 无未知异常 | 见 §7.2.7 JSON 结构 | `gather(return_exceptions=True)`；任何异常进 `reason` | `curl -s /health \| jq '.upstream \| keys \| length'` = 7 |
| 8 | **测试夹具** | `tests/copilot/conftest.py` | — | `pytest-asyncio` `event_loop`；`async_client` 用 `httpx.AsyncClient(app=app)`；可选 `redis_or_skip` fixture | conftest | 无 Redis 时 skip 真探测，保留 mock | `pytest --collect-only \| grep test_` ≥ 6 |
| 9 | **Makefile** | `diting-src/Makefile` | settings + venv | 暴露 `copilot-step01-*` 6 个 target | `.PHONY` 行含全部 | target 失败退出码 != 0 | `make -n copilot-step01-all` 干跑 |

### §7.2 详细实施步骤

#### 7.2.1 目录与占位

```bash
# 工作目录：diting-src
mkdir -p apps/copilot/{routers,services,models,events,templates,static,scheduler}
mkdir -p tests/copilot
touch apps/copilot/__init__.py
for d in routers services models events templates static scheduler; do
  touch apps/copilot/$d/__init__.py
done
touch tests/copilot/__init__.py tests/copilot/conftest.py
```

#### 7.2.2 `pyproject.toml` 追加（关键片段）

```toml
[project]
name = "diting"
requires-python = ">=3.9"
dependencies = [
  "fastapi>=0.110",
  "uvicorn[standard]>=0.27",
  "redis>=5",
  "sqlalchemy>=2",
  "aiosqlite>=0.19",
  "jinja2>=3",
  "httpx>=0.27",
  "pydantic-settings>=2",
  "apscheduler>=3.10",
  "python-multipart>=0.0.9",
  "weasyprint>=60",
]

[tool.setuptools.packages.find]
include = ["diting*", "apps*"]
```

> 维护者保留对 `requires-python` 的最终决定权；本步以 `3.9.6` 实测通过为基线。

#### 7.2.3 `apps/copilot/config.py`（CopilotSettings 骨架）

```python
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class CopilotSettings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_prefix="COPILOT_", extra="ignore"
    )

    service_name: str = "copilot"
    log_level: str = "INFO"

    redis_url: str = "redis://127.0.0.1:6379/0"
    database_url: str = "sqlite+aiosqlite:///./data/copilot.db"

    # 7 upstream streams
    stream_cryo_reject: str = "events:cryo_guard:reject"
    stream_cryo_degrade: str = "events:cryo_guard:degrade"
    stream_cryo_pass: str = "events:cryo_guard:pass"
    stream_thesis: str = "events:thrust:thesis_proposed"
    stream_health: str = "events:monitor:health_change"
    stream_sell: str = "events:exit:sell_signal"
    stream_lora: str = "events:flywheel:lora_updated"

    # M3 channels (step_05 onwards)
    wechat_webhook_url: str | None = None
    telegram_bot_token: str | None = None
    telegram_chat_id: str | None = None
    resend_api_key: str | None = None
    resend_from_email: str | None = None

    def all_streams(self) -> list[str]:
        return [
            self.stream_cryo_reject, self.stream_cryo_degrade, self.stream_cryo_pass,
            self.stream_thesis, self.stream_health, self.stream_sell, self.stream_lora,
        ]


settings = CopilotSettings()
```

#### 7.2.4 `apps/copilot/events/stream_names.py`（常量层）

```python
from apps.copilot.config import settings

STREAM_CRYO_REJECT = settings.stream_cryo_reject
STREAM_CRYO_DEGRADE = settings.stream_cryo_degrade
STREAM_CRYO_PASS = settings.stream_cryo_pass
STREAM_THESIS = settings.stream_thesis
STREAM_HEALTH = settings.stream_health
STREAM_SELL = settings.stream_sell
STREAM_LORA = settings.stream_lora

ALL_STREAMS: list[str] = settings.all_streams()
```

> **纪律**：任何业务模块只能从此处导入 stream 名；禁止散落字符串 `"events:..."`。`grep -RIn 'events:.*:' apps/copilot/ --exclude=stream_names.py --exclude=config.py` 命中数 = 0。

#### 7.2.5 `apps/copilot/services/redis_client.py`（异步 + xlen_safe）

```python
import logging
from typing import Optional
import redis.asyncio as aioredis
from apps.copilot.config import settings

log = logging.getLogger(__name__)
_client: Optional[aioredis.Redis] = None


async def get_redis() -> aioredis.Redis:
    global _client
    if _client is None:
        _client = aioredis.from_url(
            settings.redis_url, encoding="utf-8", decode_responses=True
        )
    return _client


async def close_redis() -> None:
    global _client
    if _client is not None:
        try:
            await _client.aclose()
        finally:
            _client = None


async def xlen_safe(stream: str) -> dict:
    """Return {key, ok, length|reason}; never raise."""
    try:
        client = await get_redis()
        length = await client.xlen(stream)
        if length == 0:
            return {"key": stream, "ok": True, "length": 0,
                    "reason": "stream not found (mock mode)"}
        return {"key": stream, "ok": True, "length": int(length)}
    except aioredis.ConnectionError as e:
        return {"key": stream, "ok": False, "reason": f"connection refused: {e}"}
    except aioredis.ResponseError as e:
        if "no such key" in str(e).lower():
            return {"key": stream, "ok": True, "length": 0,
                    "reason": "stream not found (mock mode)"}
        return {"key": stream, "ok": False, "reason": f"redis error: {e}"}
    except Exception as e:  # 兜底
        log.exception("xlen_safe unexpected")
        return {"key": stream, "ok": False, "reason": f"unexpected: {e}"}
```

#### 7.2.6 `apps/copilot/main.py`（FastAPI + lifespan）

```python
import time
from contextlib import asynccontextmanager
from fastapi import FastAPI

from apps.copilot.config import settings
from apps.copilot.services.redis_client import get_redis, close_redis
from apps.copilot.routers import health as health_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.start_ts = time.time()
    app.state.redis = await get_redis()
    yield
    await close_redis()


app = FastAPI(title="diting · copilot", version="0.1.0", lifespan=lifespan)
app.include_router(health_router.router, prefix="", tags=["health"])
```

#### 7.2.7 `apps/copilot/routers/health.py`（/health 完整契约）

```python
import asyncio
import time
from fastapi import APIRouter, Request
from apps.copilot.config import settings
from apps.copilot.events.stream_names import ALL_STREAMS
from apps.copilot.services.redis_client import xlen_safe

router = APIRouter()


@router.get("/health")
async def health(request: Request) -> dict:
    t0 = time.perf_counter()
    redis_ok, redis_reason = True, None
    try:
        await request.app.state.redis.ping()
    except Exception as e:
        redis_ok, redis_reason = False, str(e)
    redis_latency_ms = int((time.perf_counter() - t0) * 1000)

    upstream_results = await asyncio.gather(
        *(xlen_safe(s) for s in ALL_STREAMS), return_exceptions=False
    )
    upstream = {r["key"]: r for r in upstream_results}

    return {
        "status": "ok",
        "service": settings.service_name,
        "version": "0.1.0",
        "redis": {"ok": redis_ok, "latency_ms": redis_latency_ms,
                  "reason": redis_reason},
        "upstream": upstream,
    }
```

`curl /health` 响应示例（流尚未创建时）：

```json
{
  "status": "ok",
  "service": "copilot",
  "version": "0.1.0",
  "redis": {"ok": true, "latency_ms": 2, "reason": null},
  "upstream": {
    "events:cryo_guard:reject":   {"key": "...", "ok": true, "length": 0, "reason": "stream not found (mock mode)"},
    "events:cryo_guard:degrade":  {"key": "...", "ok": true, "length": 0, "reason": "stream not found (mock mode)"},
    "events:cryo_guard:pass":     {"key": "...", "ok": true, "length": 0, "reason": "stream not found (mock mode)"},
    "events:thrust:thesis_proposed":  {"key": "...", "ok": true, "length": 0, "reason": "stream not found (mock mode)"},
    "events:monitor:health_change":   {"key": "...", "ok": true, "length": 1, "reason": null},
    "events:exit:sell_signal":    {"key": "...", "ok": true, "length": 0, "reason": "stream not found (mock mode)"},
    "events:flywheel:lora_updated":   {"key": "...", "ok": true, "length": 0, "reason": "stream not found (mock mode)"}
  }
}
```

未起 `diting-redis` 时 `redis.ok=false` 且 `upstream.*.reason` 含 `connection refused`，服务级仍 `status: ok` —— 这是设计意图（D0 副驾驶不能因为上游未就绪而自身宕掉）。

#### 7.2.8 `tests/copilot/test_health.py`（最小 5 条用例）

```python
import pytest
from httpx import AsyncClient
from apps.copilot.main import app

@pytest.mark.asyncio
async def test_health_returns_ok():
    async with AsyncClient(app=app, base_url="http://t") as ac:
        r = await ac.get("/health")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "ok"
    assert body["service"] == "copilot"

@pytest.mark.asyncio
async def test_health_upstream_has_seven():
    async with AsyncClient(app=app, base_url="http://t") as ac:
        r = await ac.get("/health")
    body = r.json()
    assert set(body["upstream"].keys()) == {
        "events:cryo_guard:reject", "events:cryo_guard:degrade",
        "events:cryo_guard:pass", "events:thrust:thesis_proposed",
        "events:monitor:health_change", "events:exit:sell_signal",
        "events:flywheel:lora_updated",
    }

@pytest.mark.asyncio
async def test_health_each_upstream_has_ok_field():
    async with AsyncClient(app=app, base_url="http://t") as ac:
        body = (await ac.get("/health")).json()
    for k, v in body["upstream"].items():
        assert "ok" in v and "key" in v

# + test_settings_loads_minimal, test_stream_constants_match_settings, ...
```

#### 7.2.9 `inject_mock_health_change.py`（可选；调试 health.length）

```bash
# diting-src/scripts/inject_mock_health_change.py 600519 -5 2
# 向 events:monitor:health_change XADD 一条 mock 消息，让 /health 的 length 变为 1+
# 与 step_03 真实 push 区分；仅在本机调试时使用
```

> 该脚本**仅用于本步及 step_02/03 之前**的 `/health.length` 演示；step_03 起以真实 D3 producer 写入为唯一来源；step_09 前删除或 gated。

### §7.3 Makefile 合约（一键复现 · 配置驱动 · 可重入幂等）

| target | 用途 | 入参（env） | 验证标准（输出末段） |
|---|---|---|---|
| `copilot-step01-prep` | 起 `diting-redis`（按 〇-1）+ `pip install -e .` + 校验 `.env` | `COPILOT_REDIS_URL` | `Redis: PONG ✅`、`pyproject installed ✅` |
| `copilot-step01-up` | 后台启动 `uvicorn apps.copilot.main:app --port 8080`；写 pid | `COPILOT_PORT?=8080` | `pid=NNN listening on :8080 ✅` |
| `copilot-step01-health` | `curl -s :8080/health` → `jq` 校验 7 stream | — | `7 upstream keys ✅ \| redis ok ✅` |
| `copilot-step01-test` | `pytest tests/copilot/ -q` | — | `≥6 passed in Ns ✅` |
| `copilot-step01-all` | prep → up → health → test → down（清理 pid） | — | 6 段全绿 |
| `copilot-step01-status` | 单查：redis ping + `/health` + 7 stream XLEN 当前值 | — | 表格输出，每行带 ✅/⚠️ |
| `copilot-step01-clean` | 停 `diting-redis`、删 pid、不删 `.env` | — | `diting-redis stopped ✅` |

**合约要求**：
1. 入参全部 env 化（`COPILOT_PORT`、`COPILOT_REDIS_URL`），Makefile 不写死；
2. `*-all` 端到端可重入：第二次跑跳过 `pip install -e .`、不重启已活进程；
3. 失败可观察：每个 target **必须**输出"做了什么 / 期望什么 / 实际什么"3 行中文摘要；
4. **配置驱动验证**：临时将 `COPILOT_PORT=8088` 跑 `make copilot-step01-all` 端到端通过；恢复 8080 后 `make copilot-step01-status` 仍可读 ✅。

**L3 只定义合约**（target 名 / 用途 / 入参 / 验证标准）；**实现交 L4 / `diting-src/Makefile`**（注释引用本文档 §7.3）。

### §7.4 给后续执行模型的指引

1. **顺序刚性**：先建包骨架（7.2.1）→ 装依赖（7.2.2）→ Settings（7.2.3）→ stream 常量（7.2.4）→ redis client（7.2.5）→ main（7.2.6）→ /health（7.2.7）→ tests（7.2.8）→ Makefile（7.3）；任一环节 fail 不得跳过。
2. **不嵌入完整生产代码**：本文档 §7.2.3–7.2.7 的代码块是**骨架/锚点**（30~80 行/模块）；具体 docstring / 注释 / 错误日志格式由 L4 实践记录回写。
3. **遇环境问题先验证后改**：`curl /health` 出现 `connection refused` 时**先**核 `docker ps | grep diting-redis`、`echo $COPILOT_REDIS_URL`，**再**改代码（参见 .cursorrules §7.2 第 6 条 Verify First）。
4. **同问题修复重试 ≤ 2 次**：超过则按 §12 回退（卸载 Python venv 重建 / 切回 sqlite 默认 / docker 重启 redis）。
5. **L4 回写内容**：本步执行后须在 `04_阶段规划与实践/00_维度零/stage_1_启动期/实践记录_W01_...` 回写：
   - 实际 Python 版本（如 `3.9.6` 或 `3.11.x`）；
   - `pytest -q` 全套通过用例数（不止 health，含 settings/stream/redis_client）；
   - `/health` 的真实 JSON 截取（脱敏）；
   - Makefile 配置驱动验证（`COPILOT_PORT=8088` 切换）。
6. **永久规则审计**：本步实施完成后必须执行：
   ```bash
   rg "place_order|submit_order|broker_api|execute_order" apps/copilot/
   ```
   命中数必须 = 0；否则违反 D0 永久规则（no-auto-order），本步立刻 fail。

## §8 部署节奏

| 项 | 本 step |
|---|---|
| 部署面 | **本机** `uvicorn` + Docker `diting-redis`；**不**上 K3s |
| Chart / `diting-infra` | **不改** |
| **deploy-engine** | 未涉及；禁止在 `diting-infra/deploy-engine/` 拷贝内开发 |
| 镜像（ACR） | **不构建、不推送** |
| Helm release | **—** |
| 何时上 K3s | **step_10 阶段验收**或扩展期；本步只把"地基"备好 |

详见：[16 · 阿里云 ECS+K3s+Helm+ACR](../../../../_共享规约/16_阿里云ECS_K3s_ACR_Helm部署与deploy-engine链路.md)。

## §9 准出标准

### §9.1 数据量（本步不涉业务数据）

不适用；下游 step_02 起以 SQLite 表行数为门槛。

### §9.2 工程质量（本步主项 · 逐项可执行验证）

```bash
# 1) 包结构 ≥ 9 个 __init__.py
find apps/copilot -name __init__.py | wc -l  # 期望 ≥ 9

# 2) 依赖装齐
cd diting-src && python3 -m pip install -e . && pip show fastapi | grep Version

# 3) Redis 起 + uvicorn 起 + /health 7 stream
docker run -d --name diting-redis -p 127.0.0.1:6379:6379 redis:7-alpine
docker exec diting-redis redis-cli ping  # 期望 PONG
export COPILOT_REDIS_URL=redis://127.0.0.1:6379/0
python3 -m uvicorn apps.copilot.main:app --port 8080 &
sleep 2
curl -s :8080/health | jq '.upstream | keys | length'   # 期望 7
curl -s :8080/health | jq '.status'                      # 期望 "ok"
curl -s :8080/health | jq '.redis.ok'                    # 期望 true

# 4) 单测
python3 -m pytest tests/copilot/ -q   # 期望 ≥6 passed（目标 ≥40）

# 5) 永久规则审计
rg "place_order|submit_order|broker_api|execute_order" apps/copilot/   # 期望 0 命中

# 6) Makefile 合约
make copilot-step01-all              # 期望 6 段全绿
make copilot-step01-status           # 期望 7 stream + redis 状态表

# 7) 配置驱动验证
COPILOT_PORT=8088 make copilot-step01-all   # 期望端口切换后仍全绿
```

### §9.3 锁库（无）

本步不写 SQLite/Redis；不涉锁库。

### §9.4 准出确认

- [ ] §9.2 全部 7 条命令本机跑通 ✅
- [ ] L4 实践记录 `实践记录_W01_后端依赖与服务骨架.md` 已回写 §9.2 全部输出
- [ ] `git add apps/copilot tests/copilot pyproject.toml Makefile .env.template` 提交
- [ ] 通知 step_02 owner 启动

## §10 [Deploy]

启动期 ConfigMap / Secret / Helm Chart **不创建**；待 step_10 阶段验收时统一上 K3s。本步只在 `diting-src/.env` 写 dev 配置；**禁止**把生产 Redis URL 写到本地 `.env`（用 `diting-redis` 本机隔离）。

## §11 依赖（上游 / 下游）

| 类型 | 依赖项 | 当前就绪状态 | 缺失时处理 |
|---|---|---|---|
| 硬依赖 | Python 3.9+ | ✅ 实测 3.9.6 | 升级或 ADR |
| 硬依赖 | Docker Desktop（起 `diting-redis`） | 用户本机 | 缺则跳过真 stream 探测；mock mode |
| 软依赖 | D1~D5 stream（7 条） | 启动期不强制 | step_09 前不强制；本步 7 stream 均允许 mock mode |
| 软依赖 | M3 告警渠道凭证 | step_05 前 | 本步留空占位 |

**严禁**：
- 引入任何券商/交易 API SDK（违反 no-auto-order）；
- stream 缺失时伪造业务 payload（违反 no-mock）；
- 在 `apps/copilot/` 下硬编码 `events:cryo_guard:reject` 等字符串（必须从 `stream_names.py` 导入）。

## §12 风险与回退

| 触发 | 影响 | 应对 | 重试上限 |
|---|---|---|---|
| Redis 不可达 | `/health.redis.ok=false`、`upstream.*.reason=connection refused` | health 仍 200（设计意图）；写 ADR；继续 step_02 | 不计入 step fail |
| 依赖版本冲突（如 pydantic v1 残留） | `pip install -e .` 失败 | 锁版本下限；卸载冲突包；查 `pip check` | 2 次 |
| stream 名不一致（与 13_共享规约 不符） | 跨维度联调失败 | 以 13_共享规约 §四为真相源；同步修正 `stream_names.py` | 1 次 |
| pytest 卡死（`AsyncClient` 配置错） | 测试超时 | 用 `httpx>=0.27` + `asgi_transport`；不要 mix 同步/异步 fixture | 2 次 |
| WeasyPrint libgobject 告警 | 启动日志告警 | 与 `/health`/pytest 无关；step_08 前忽略 | — |
| 同问题修复 > 2 次 | 阻塞 | 按 .cursorrules §8.4f 回退：卸载 venv 重建 / docker 重启 / 切默认 sqlite 路径 | — |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v3 细化融合**：基于 L4 W01 实践记录回填真实事实——7 stream（非 5）、`requires-python = ">=3.9"`（实测 3.9.6）、`COPILOT_` 前缀、`xlen_safe()` 设计、`/health` JSON 响应示例、`inject_mock_health_change.py`、配置驱动 Makefile 验证；§7 从 4 行扩到完整实施步骤（7.2.1~7.2.9）；§3.5 从"不适用"细化为 12 项工程质量；123→~600 行 |
| 2026-05-20 | v2 按 L3 v1.2 重写：删 356 行嵌入 Python；§3.5 不适用；no-auto-order；356→~150 行 |
| 2026-05-16 | 初版 356 行 |
