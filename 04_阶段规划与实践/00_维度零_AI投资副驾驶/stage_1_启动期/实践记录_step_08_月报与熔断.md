# 实践记录 · 维度零·AI 投资副驾驶 · 启动期 · step_08 · 月报与熔断

> [!NOTE] **[TRACEBACK] 实践锚点**
> - **L3 step**: [step_08_月报与熔断.md](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_08_月报与熔断.md)
> - **DNA**: [_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml)
> - **本阶段看板**: [README.md](./README.md)

---

## 一、本步计划（来自 L3）

- 引用：[step_08_月报与熔断.md](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_08_月报与熔断.md)
- 目标：`services/reports/monthly.py` + `pdf.py` + `templates/reports/*`、`services/circuit_breaker.py`（`SelfCircuitBreaker`）、`GET /api/reports/monthly/{YYYY-MM}/pdf`、管理路由、`report_jobs` 月调度、`audit_logs`、`pytest`（≥8 用例）、`.env.template` 架构师 webhook / admin token。

---

## 二、实际进展

| §3.x / 项 | 状态 | 说明 |
|---|---|---|
| 3.1 骨架 | ✅ | `reports/monthly.py`、`reports/pdf.py`、`services/circuit_breaker.py`、`templates/reports/monthly_report.html`（含 SVG 柱图）+ `monthly_report.css` |
| 3.2 WeasyPrint / 字体 | ✅ | **自定义镜像**：`diting-src/Dockerfile`（`python:3.11-slim-bookworm` + Pango/Cairo 栈 + `fonts-noto-cjk` + `pip install -e ".[pdf-verify]"` 含 `pdfminer.six`）。**容器内** `pytest`：**10 passed，PDF 与中文 glyph 均不 skip**（见 **§三-B**）。 |
| 3.3 monthly 聚合 | ✅ | `AttributionRecord` / `ThesisCard` / `UserDecision`+`User` / `AlertLog`；`ReportLedgerAdapter.compute_earned`→`EVCalculator.gain_value` |
| 3.4 PDF | ✅ | `WeasyPDFRenderer` |
| 3.5 模板/CSS | ✅ | 与 L3 §3.5 对齐（封面+目录+章节） |
| 3.6 SelfCircuitBreaker | ✅ | Redis TTL 24h、`AuditLog`、`architect_wechat_webhook` 通知 |
| 3.7 调度 | ✅ | `report_jobs` 注册 `copilot.monthly_report`（`monthly_cron_day/hour`）；`LedgerScheduler` 仅保留 **backfill**，不再独享 AsyncIO 月任务 |
| 3.8 路由 | ✅ | `GET /api/reports/monthly/{year_month}/pdf`；`admin`：`/api/admin/circuit-breaker/status`、`POST .../reset`（`x-admin-token`） |
| 3.9～3.10 测试 | ✅ | `test_monthly_pdf.py` + `test_circuit_breaker.py`；`conftest` 增加 `db_session` / `fake_redis` |
| 3.11 手工冒烟 | ✅ | **见 §三-C**：非「仅 Redis」问题——需 **Redis 健康 + 应用成功 lifespan**；镜像内缺 **`/app/data`** 会导致 SQLite 无法建库 → 已在 **Dockerfile** `mkdir -p /app/data` 修复。`docker compose` 起 `redis`+`copilot-app` 后 **status HTTP 200、月报 PDF ~332KB、reset HTTP 200**。 |
| 3.12 pytest | ✅ | 本机可无 Pango（skip PDF）；**准出以对镜像 `make docker-step08-pytest` 为准**（10 passed） |
| 3.13 commit | ⚠️ | 未执行（用户规则） |

### 偏离与决策

| 项 | 决策 |
|---|---|
| **两套熔断** | **B+H 窗口** 仍为 `services/ledger/circuit_breaker.py`（`CircuitBreaker`，配合 `AlertDispatcher` 暂停）；**step08** 为 `SelfCircuitBreaker`（3 条件 + Redis 暂停 + `audit_logs`）。 |
| **两套月报生成器** | `ledger/monthly_report.py` 的 `MonthlyReportGenerator` **仍由 `main` 注入 `app.state.ledger["report"]`**（兼容既有价值页/接口）；**step08** 完整月报为 `services/reports/monthly.py` 的同名类（通过包路径区分）。 |
| **ORM 与 L3 片段** | L3 示例 `Attribution`/`MonthlyReport(db)` 等 → 本仓 **`AttributionRecord`**、`ledger.models.MonthlyReport`，`UserDecision` 经 **`user_pk`→`User.user_id`**。 |
| **路由** | L3 仅写 `/api/reports/monthly/...`；本仓 **保留** `value` 路由 `GET /api/value/monthly-report/{period}`（旧入口），新 PDF 用 **`/api/reports/monthly/{YYYY-MM}/pdf`**。 |
| **本机 macOS** | 无 `libgobject` 时 PDF 单测可 **skip**；**不以 skip 作为镜像/CI 准出**。 |
| **Python 3.9** | `admin` 路由注解使用 `Optional[str]`，避免 `str \| None` 收集失败。 |
| **§3.11 归因** | 此前 L4 写「未起 uvicorn」——**不完整**：即使起了 uvicorn，**主机**未起 Redis 会导致连 Redis 失败；**容器**内还需 **`data` 目录** 可写，否则 SQLite `unable to open database file`，应用 **startup 即退出**，curl 得到空响应（误以为是 Redis 单因）。 |

### 关键代码变更（`diting-src`）

- `Dockerfile`：`mkdir -p /app/data`；`pip install -e ".[pdf-verify]"`
- `docker-compose.copilot.yml`：`redis` + `copilot-app`（冒烟）+ `copilot-test`（pytest）
- `Makefile`：`docker-copilot-build`、`docker-step08-pytest`、`docker-step08-smoke-up/down/verify`
- `pyproject.toml`：`[project.optional-dependencies]` **`pdf-verify`** → `pdfminer.six`
- 其余见前版清单：`reports/monthly.py`、`pdf.py`、`circuit_breaker.py`、`routers/*`、`report_jobs.py`、`scheduler.py`、测试与 `.env.template`

---

## 三、测试运行

### 三-A、本机（macOS，可选）

```bash
cd /Users/huishaoqi/Desktop/workspace/diting-src
python3 -m pip install 'fakeredis>=2.23'
python3 -m pytest tests/copilot/test_monthly_pdf.py tests/copilot/test_circuit_breaker.py -v
```

本机若缺 WeasyPrint 系统库：**8 passed，2 skipped**（与首次记录一致）。

### 三-B、自定义镜像（**推荐准出**，2026-05-17）

```bash
cd /Users/huishaoqi/Desktop/workspace/diting-src
make docker-copilot-build
make docker-step08-pytest
```

**输出（摘录）**：

```
tests/copilot/test_monthly_pdf.py:: ... PASSED
...
============================== 10 passed in 12.77s ==============================
```

（含 **`test_monthly_pdf_render`**、**`test_monthly_pdf_contains_chinese_glyph`**，无 skip。）

### 三-C、§3.11 冒烟（Docker：`redis` + `copilot-app`，2026-05-17）

```bash
cd /Users/huishaoqi/Desktop/workspace/diting-src
make docker-step08-smoke-up
sleep 12
make docker-step08-smoke-verify
make docker-step08-smoke-down
```

**实际输出（摘录）**：

- `GET /api/admin/circuit-breaker/status` → `{"paused": false, "ttl_seconds": 0, "reason": null}`
- `GET /api/reports/monthly/$(date +%Y-%m)/pdf?user_id=default` → **HTTP 200**，PDF 约 **332342 字节**
- `POST /api/admin/circuit-breaker/reset?...` + `x-admin-token: devtoken` → `{"ok": true, "operator": "docker"}`

### 三-2、复验命令（准出清单）

```bash
cd /Users/huishaoqi/Desktop/workspace/diting-src
# 1) 镜像内全绿（WeasyPrint + pdfminer）
make docker-step08-pytest

# 2) §3.11 冒烟（验毕 down）
make docker-step08-smoke-up
# 等待应用就绪 ~10–15s
make docker-step08-smoke-verify
make docker-step08-smoke-down

# 3) 本机快速（可无 PDF）
python3 -m pytest tests/copilot/test_circuit_breaker.py -v
```

---

## 四、问题与风险

- **`AlertDispatcher` 未接 `SelfCircuitBreaker.is_paused`**：启动期由 **ledger `CircuitBreaker`** 管推送暂停；Redis 熔断为 **并行** 能力，全链路收紧在 step_09。

---

## 五、下一步

- [step_09 全链路联调](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_09_全链路联调.md)

---

## 六、一致性检查（L4 自检）

- [x] §3.11 归因写清：Redis + 应用启动 + SQLite 目录
- [x] §3.2 以 **Dockerfile + make** 为权威验证路径
- [x] §三 附 **10 passed** 与 **smoke** 可核实输出

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-17 | 初版：对齐 step_08 落地与本会话 pytest 证据 |
| 2026-05-17 | **Docker 准出**：Dockerfile `/app/data`、`pdf-verify`、`docker-compose.copilot.yml`、`Makefile`；更新 §3.2/3.11、§三-B/C、三-2；**smoke 实测通过** |
