# 实践记录 · 维度零·AI 投资副驾驶 · 启动期 · step_07 · 日报与周报

> [!NOTE] **[TRACEBACK] 实践锚点**
> - **L3 step**: [step_07_日报周报推送.md](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_07_日报周报推送.md)
> - **DNA**: [_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml)
> - **本阶段看板**: [README.md](./README.md)

---

## 一、本步计划（来自 L3）

- 引用：[step_07_日报周报推送.md](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_07_日报周报推送.md)
- 目标：`services/reports/*`、模板 HTML+Markdown、APScheduler 注册、`daily_reports`/`weekly_reports` 表、`/api/reports/*`、`test_reports.py`（≥6 用例）、`dry_run_reports` CLI；推送复用 M3 `AlertDispatcher`。

---

## 二、实际进展

| §3.x / 项 | 状态 | 说明 |
|---|---|---|
| 3.1 目录骨架 | ✅ | `apps/copilot/services/reports/`、`scheduler/jobs/report_jobs.py`、`cli/dry_run_reports.py`、`routers/reports.py` |
| 3.2 ORM | ✅ | `DailyReport` / `WeeklyReport` 追加至 `apps/copilot/db/models.py` |
| 3.3～3.7 生成/渲染/推送 | ✅ | 见 **偏离**：路径对齐本仓 `services.alerts` / `HealthRecord` / `Holding` / `User` |
| 3.8 调度 | ✅ | `AsyncIOScheduler` 在 `main.py` lifespan 注册；与 M4 `LedgerScheduler` 并存 |
| 3.9 模板 | ✅ | `templates/reports/*.html` + `*.md.j2` |
| 3.10 路由 | ✅ | `GET /api/reports/daily/{YYYY-MM-DD}`、`GET /api/reports/weekly/{YYYY-Www}` |
| 3.11 CLI | ✅ | `python -m apps.copilot.cli.dry_run_reports` |
| 3.12 测试 | ✅ | `tests/copilot/test_reports.py` **6 passed** |
| 3.13 手工冒烟（Redis+uvicorn） | ✅ | **2026-05-17**：按更新后 L3 §3.13（Docker Redis + `COPILOT_REDIS_URL` + `uvicorn` + `curl` + `dry_run` + `register_report_jobs`+Mock）；见 **§三-C** |
| 3.14 git commit | ⚠️ | 未执行（用户规则） |

### 偏离与决策

| 项 | 决策 |
|---|---|
| **L3 代码路径** | 文档示例为 `modules.alert` / `Portfolio` / `HealthHistory`；实现为 **`services.alerts`**、**`Holding`**、**`HealthRecord`**，`UserDecision` 经 **`User.user_id`** 关联。 |
| **`AlertDispatcher`** | 无 `send_markdown`/`send_html`；**`ReportDispatcher`** 构造 `Alert` + `payload.html_override` / `email_subject`，**`dispatch(..., force=True)`** 绕过熔断暂停；**`EmailChannel`** 支持 `html_override`。 |
| **账本接口** | 无统一 `LedgerService`；使用 **`ReportLedgerAdapter`** 包装 `SCSCalculator` / `EVCalculator`（`snapshot_scs` 按日、`compute_avoided_loss`→EV **hedge_value**）。 |
| **L3 §1 三种格式** | 条文写 PDF；**§3 仅 HTML+MD**，本实现与 **§3** 一致，日报/周报 **未生成 PDF**。 |
| **`register_report_jobs`** | 需传入 **`session_factory`** 与 **`alert_dispatcher`**（由 `main.py` 注入），与 L3 仅传 `scheduler` 的片段不同。 |
| **单测 `test_renderer_html_contains_label`** | L3 写「HTML 不含 🔴」与自带 HTML 模板矛盾；本仓断言改为 **含「红色」/标题**。 |

### 关键代码变更（`diting-src`）

- `apps/copilot/services/reports/{base,daily,weekly,renderer,dispatcher,ledger_adapter}.py`
- `apps/copilot/scheduler/jobs/report_jobs.py`、`apps/copilot/routers/reports.py`、`apps/copilot/cli/dry_run_reports.py`
- `apps/copilot/templates/reports/*`、`apps/copilot/db/models.py`、`apps/copilot/db/database.py`（`get_async_session`）、`apps/copilot/config.py`、`apps/copilot/main.py`
- `apps/copilot/services/alerts/dispatcher.py`（`force`）、`apps/copilot/services/alerts/channels/email.py`（`html_override` / `email_subject`）
- `tests/copilot/test_reports.py`、`.env.template`（日报周报小节注释）

---

## 三、测试运行

### 命令（本会话）

```bash
cd /Users/huishaoqi/Desktop/workspace/diting-src
python3 -m pytest tests/copilot/test_reports.py -v
python3 -m pytest tests/copilot/ -v
python3 -m apps.copilot.cli.dry_run_reports --kind daily --date 2026-05-15 --user default
```

### 输出（摘录）

`tests/copilot/test_reports.py`:

```
6 passed in 0.83s
```

全量 `tests/copilot/`（本会话）：

```
62 passed, 1 skipped in 3.06s
```

（`1 skipped` 为 step_04 **WeasyPrint** 本机 PDF，与 step_07 无关。）

`dry_run_reports`：

```
✅ 写出 tmp/reports/daily_2026-05-15.html 与 tmp/reports/daily_2026-05-15.md
```

### 三-C、§3.13 手工冒烟（**本次复验，曾失败项**）

**环境**：`diting-src`；Docker Redis `diting-redis:6379`；`COPILOT_REDIS_URL=redis://127.0.0.1:6379/0`；`python3 -m uvicorn apps.copilot.main:app --host 127.0.0.1 --port 8080`（后台进程，验毕已 `pkill`）；验毕 `docker stop/rm diting-redis`。

| 步骤 | 结果 |
|---|---|
| `curl /api/reports/daily/$(date +%F)?user_id=default` | **HTTP 200**；响应含 **`持仓体检日报 · 2026-05-17`**（与日期随 `date +%F` 变） |
| `dry_run_reports --date $(date +%F)` | 写出 `tmp/reports/daily_2026-05-17.html` / `.md` |
| `register_report_jobs(..., MagicMock×2)` | 打印 `copilot.daily_report cron[hour='18', minute='0']`、`copilot.weekly_report cron[day_of_week='6', ...]` |

### 三-2、复验命令（准出清单）

```bash
cd /Users/huishaoqi/Desktop/workspace/diting-src
python3 -m pip install -e .   # 若尚未安装
python3 -m pytest tests/copilot/test_reports.py -v
# 期望：6 passed

# ---------- §3.13（须先启 Redis；验毕 stop/rm）----------
docker rm -f diting-redis 2>/dev/null || true
docker run -d --name diting-redis -p 6379:6379 redis:7-alpine
until docker exec diting-redis redis-cli ping 2>/dev/null | grep -q PONG; do sleep 0.5; done

COPILOT_REDIS_URL=redis://127.0.0.1:6379/0 python3 -m uvicorn apps.copilot.main:app --host 127.0.0.1 --port 8080 &
sleep 3
curl -s -w "\nHTTP %{http_code}\n" "http://127.0.0.1:8080/api/reports/daily/$(date +%F)?user_id=default" | head -20
python3 -m apps.copilot.cli.dry_run_reports --kind daily --date "$(date +%F)" --user default
python3 -c "
from unittest.mock import MagicMock
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apps.copilot.scheduler.jobs.report_jobs import register_report_jobs
s = AsyncIOScheduler()
register_report_jobs(s, session_factory=MagicMock(), alert_dispatcher=MagicMock())
for j in s.get_jobs():
    print(j.id, j.trigger)
"

pkill -f 'uvicorn apps.copilot.main:app' || true
docker stop diting-redis && docker rm diting-redis

# 可选：全量
python3 -m pytest tests/copilot/ -q
```

---

## 四、问题与风险

| 问题 | 影响 | 应对 |
|---|---|---|
| 同日重复跑 `run_daily_for_all` 可能 **UNIQUE** 冲突 | 调度外重复触发入库失败 | 生产侧控制幂等或捕获后更新；未在本次实现 |

---

## 五、下一步

- [ ] [step_08_月报与熔断](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_08_月报与熔断.md)

---

## 六、引用

- L3：[step_07_日报周报推送.md](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_07_日报周报推送.md)

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-17 | 初版：按 L3 §3 落地代码 + L4 验证摘录 |
| 2026-05-17 | **§3.13 复验 ✅**：Docker Redis + `uvicorn` + `curl` **200** + `dry_run` + `register_report_jobs`(Mock)；L4 **三-C** / **三-2** 已写入可粘贴命令 |
