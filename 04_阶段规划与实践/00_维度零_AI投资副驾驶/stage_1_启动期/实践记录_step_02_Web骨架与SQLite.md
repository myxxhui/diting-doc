# 实践记录 · 维度零·AI 投资副驾驶 · 启动期 · step_02 · Web 骨架与 SQLite

> [!NOTE] **[TRACEBACK] 实践锚点**
> - **L3 step**: [step_02_Web骨架与SQLite.md](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_02_Web骨架与SQLite.md)
> - **DNA**: [_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml)
> - **本阶段看板**: [README.md](./README.md)

---

## 一、本步计划（来自 L3）

- 引用：[step_02_Web骨架与SQLite.md](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_02_Web骨架与SQLite.md)
- 目标：SQLite 四表、Jinja2/HTMX 模板、`/holdings` CRUD + Excel 导入；**单测**：`test_portfolio.py` **5** 条 + `test_health.py`（同仓 step_01 扩展）与 step_02 一并复验时 **共 16 passed**；**全量** `tests/copilot/` **70 passed, 3 skipped**（2026-05-17 复验）

---

## 二、实际进展

| §3.x / 项 | 状态 | 说明 |
|---|---|---|
| 3.1 依赖 openpyxl/pandas | ✅ | 已写入 `pyproject.toml`；补充 **greenlet**（SQLAlchemy asyncio + TestClient 依赖） |
| 3.2 database.py | ✅ | `init_db` / `get_db` / `AsyncSessionLocal` |
| 3.3 models.py 四表 | ✅ | users / holdings / value_snapshots / event_logs |
| 3.4 main.py 接入 | ✅ | lifespan 内 `init_db`，静态 `/static`，`portfolio` 路由 |
| 3.5 模板 | ✅ | base/index/portfolio list + `_list_table` |
| 3.6 excel_importer | ✅ | 中文列名、ensure_default_user、upsert |
| 3.7 portfolio 路由 | ✅ | `/` `/holdings` POST 表单、multipart 导入 |
| 3.8 pytest | ✅ | `test_portfolio.py` **5** + `test_health.py` **11**（同仓健康/Dashboard 用例，与 step_01/step_03 演进一致）⇒ **16 passed**；**全量** `tests/copilot/` **70 passed, 3 skipped**（2026-05-17 本会话复验） |
| 3.9 commit/push | ⚠️ | **未执行**（与用户「显式才提交」规则一致；工作区已落地） |

### 关键代码变更

- 工作目录：`diting-src`：`apps/copilot/db/`、`routers/`、`services/`、`templates/`、`main.py`、`pyproject.toml`、`tests/copilot/conftest.py`、`test_portfolio.py`

---

## 三、测试运行（须含实测证据 — §3.5.3 / §8.4g）

### 命令

```bash
cd /Users/huishaoqi/Desktop/workspace/diting-src
python3 -m pip install -e .
python3 -m pytest tests/copilot/ -v --tb=short
# （已释放 8080）uvicorn + curl 见下方「集成烟测」
```

### 输出（pytest 摘要：`test_health` + `test_portfolio`）

```
tests/copilot/test_health.py::test_color_mapping[0-green] PASSED         ...
tests/copilot/test_health.py::test_health_returns_ok PASSED              ...
tests/copilot/test_portfolio.py::test_holdings_page_empty PASSED         ...
tests/copilot/test_portfolio.py::test_parse_excel_empty_raises PASSED    [100%]

============================== 16 passed in 1.54s ==============================
```

### 全量回归（`tests/copilot/`，与 step_01～step_06 同仓）

```
...................................................ss............s...... [ 98%]
.                                                                        [100%]
70 passed, 3 skipped in ~3s
```

### 集成烟测（curl + uvicorn；**2026-05-17** 本会话）

前置：`lsof -ti:8080 | xargs kill -9`（若有占用）。本轮为**避免污染**默认库，使用  
`export COPILOT_DB_URL=sqlite+aiosqlite:///./data/copilot_smoke_w03.db`、`mkdir -p data`，再 `uvicorn`（`127.0.0.1:8080`）。

| 检查项 | 结果 |
|---|---|
| `GET /` | **200** |
| `GET /holdings` | **200** |
| `POST /holdings`（`symbol=600519`…） | **200** |
| `GET /holdings` 含 **600519** | `grep -c` ⇒ **2** |
| `sqlite3 data/copilot_smoke_w03.db ".tables"` | 含 **`users` `holdings` `value_snapshots` `event_logs`**；其余表为 `init_db` 注册的后继 step 表，属当前代码仓正常形态 |

启动日志可出现 **WeasyPrint / libgobject** 降级提示，**不阻塞** L3 §2 的页面与 SQLite 准出（与 [step_01 实践记录](./实践记录_step_01_后端依赖与服务骨架.md#l4-step01-redis-verify) 备注一致）。**Copilot PDF 与镜像内 pytest 准出**以 L3 [step_04](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_04_推荐池模块.md) §3.10 为准。

> **L3 §2 默认路径**：复验也可使用 `data/copilot.db`（见「三-2」）；响应 **UTF-8**，终端或显乱码时以浏览器为准。

### 数据库 schema（摘录，`.schema` 前 80 行内）

```sql
CREATE TABLE users (
	id INTEGER NOT NULL, 
	user_id VARCHAR(64) NOT NULL, 
	...
);
CREATE TABLE event_logs (...);
CREATE TABLE holdings (
	...
	CONSTRAINT uq_user_symbol UNIQUE (user_pk, symbol), 
	FOREIGN KEY(user_pk) REFERENCES users (id)
);
CREATE TABLE value_snapshots (
	...
	CONSTRAINT uq_user_snapshot UNIQUE (user_pk, snapshot_date), 
	FOREIGN KEY(user_pk) REFERENCES users (id)
);
```

### 执行元信息

- 时间：**2026-05-17**（本会话按 L3 step_02 §2 / §2.5 复验并回写 L4）
- 环境：macOS，Python **3.9.6**；`diting-src` `git`：**59dab65**
- 偏离：L3 checklist「Python ≥ 3.10」与本机 3.9.6 → **以 `pyproject.toml` requires-python >=3.9 为准**

### 结果

- **step_02 子集**：**16/16**（`test_health` + `test_portfolio`）；**全量 70 passed, 3 skipped**（`pytest tests/copilot/ -q`，约 **3s**）
- **curl 烟测**：见上表（与 L3 §2 `curl` / SQLite 表项对齐）
- 失败：无

---

## 三-A、Redis（〇-1）与 step_01 实践记录对齐

> **规约**：[steps/README · 〇-1](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/README.md#redis-docker-lifecycle)。**实践记录维护**：单一最佳结果，见 [00_系统规则 §8.4g](../../../00_系统规则_通用项目协议.md#l4-practice-record-best-only)。

**step_02** 不以 Stream 为准出；与同仓 **step_03/step_05** 联调前，按 〇-1 启 Redis，并以 [实践记录_step_01 · 三 / 三-A #l4-step01-redis-verify](./实践记录_step_01_后端依赖与服务骨架.md#l4-step01-redis-verify) 为 **唯一** Stream/`/health` 证据口径。

| 项 | 当前结论 |
|---|---|
| 本步 pytest | 子集 **`test_health`+`test_portfolio` 共 16** + 全量 **`tests/copilot/` 70 passed, 3 skipped**（与 `diting-src` 一致） |
| Redis / `/health` | **不重复粘贴**；以 **step_01 实践记录** 为准（真 Redis + `COPILOT_REDIS_URL` 后非 `Connection refused`） |

---

## 三-2、复验命令（必填，与 §3.5.3 对齐）

```bash
cd /path/to/diting-src

python3 -m pip install -e .

# step_02 子集（须 16 passed：health + portfolio，与当前仓 test_health 用例数一致）
python3 -m pytest tests/copilot/test_health.py tests/copilot/test_portfolio.py -v --tb=short

# 全量 copilot（须 70 passed、3 skipped，含 step_01～step_06 链）
python3 -m pytest tests/copilot/ -q

# 手动烟测（无进程占 8080）
rm -f data/copilot.db
mkdir -p data
python3 -m uvicorn apps.copilot.main:app --port 8080
# 另终端：
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8080/
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8080/holdings
curl -s -X POST -d "symbol=600519&name=贵州茅台&shares=100&cost_price=1800" http://127.0.0.1:8080/holdings | head -c 400
curl -s http://127.0.0.1:8080/holdings | grep -q 600519 && echo "holdings_ok"
sqlite3 data/copilot.db ".tables"
```

---

## 四、偏离与决策

| 偏离 | 原因 | 决策 | 决策人 |
|---|---|---|---|
| 增补 **greenlet** 依赖 | SQLAlchemy 2 异步在 Starlette `TestClient` 下需 greenlet | 写入 `pyproject.toml` | 执行会话 |
| conftest 建 **data/** | `test_copilot.db` 路径父目录须存在 | `mkdir(parents=True)` | 执行会话 |
| L3 写 Python≥3.10 / 本机 3.9 | 环境约束 | 维持 `requires-python>=3.9`，以实测通过为准 | 执行会话 |
| 8080 占用 | 本机残留 uvicorn | 复验前先 `kill` 占口进程 | 执行会话 |
| Redis 非 step_02 准出 | — | 证据与命令见 [step_01 实践记录](./实践记录_step_01_后端依赖与服务骨架.md#l4-step01-redis-verify)；本记录不另存多轮会话全文 |

---

## 五、问题与风险

| 问题 | 影响 | 应对 | 负责人 |
|---|---|---|---|
| 无 | — | — | — |

---

## 六、下一步

- [ ] [step_03_持仓体检模块](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_03_持仓体检模块.md)
- [ ] （可选）`git commit` / `push`：`feat(copilot): SQLite schema + 持仓维护页 [Ref: .../step_02]`

---

## 七、部署快照（本 step）

**本 step 无上架**，仅 `diting-src` 本地；未推 ACR、未改 Helm。

| 项 | 本 step |
|---|---|
| Chart / diting-infra | **不改** |
| ACR tag | **—** |
| helm release | **—** |

---

## 八、引用

- [02_技术方案与代码架构.md](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/02_技术方案与代码架构.md)
- [16 · ECS+K3s](../../../03_原子目标与规约/_共享规约/16_阿里云ECS_K3s_ACR_Helm部署与deploy-engine链路.md)

---

## 九、一致性检查（L4 回写）

- [x] §2 准出可核验（pytest + curl + sqlite）
- [x] 「三」含实测输出；「三-A」Redis 〇-1 与全量 **70 passed, 3 skipped**；「三-2」含完整复验命令
- [x] 部署快照占位
- [x] stage README / steps README 已更新
