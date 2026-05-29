# Step 02 · Web 骨架（HTMX + Alpine.js + Jinja2）+ SQLite 4 表 + 持仓 CRUD（v3 细化融合版）

## §1 一句话定位与本步交付物

**一句话**：在 `diting-src/apps/copilot/` 上**搭出 copilot Web 最小可用形态**——`GET /` 首页 + `GET/POST /holdings`（持仓维护 + Excel 导入）+ Jinja2 模板（base/index/portfolio + `_list_table.html` 片段）+ HTMX 1.9 / Alpine.js 3 / Tailwind 静态资源 + **SQLite 4 张表**（`users` / `holdings` / `value_snapshots` / `event_logs`）；首屏 Lighthouse Perf ≥ 90 / FCP < 800ms / TTI < 1s；持仓 SoT（`my_holdings.yaml`）与 DB **互查**而非任一方独裁；**严禁出现任何下单按钮 / 外部交易 API 调用**。

**交付物**（勾选 = 完成）：

- [ ] **A**（模板结构）：`apps/copilot/templates/{base.html, index.html, portfolio_list.html, partials/_list_table.html, partials/_holding_card.html}`；TailwindCSS（CDN 或本地构建）
- [ ] **B**（静态资源）：`apps/copilot/static/{css/, js/, img/}`；HTMX 1.9 + Alpine.js 3（启动期 **CDN 引用即可**，扩展期降级本地）
- [ ] **C**（SQLite 4 张表）：`apps/copilot/db/database.py`（`init_db / get_db / AsyncSessionLocal`）+ `apps/copilot/db/models.py`，含
  - `users`（id PK, user_id VARCHAR UNIQUE）
  - `holdings`（id PK, user_pk FK, symbol, name, shares, cost_price, **`UNIQUE(user_pk, symbol)`**）
  - `value_snapshots`（id PK, user_pk FK, snapshot_date, total_value, **`UNIQUE(user_pk, snapshot_date)`**）—— step_06 写入
  - `event_logs`（id PK, stream_key, msg_id, payload JSON, handled BOOL, error TEXT, received_at TS）—— step_03+ consumer 写入
- [ ] **D**（首页路由）：`GET /` 返回 base + 4 色卡片骨架占位（卡片内容由 step_03 注入真数据）
- [ ] **E**（持仓 CRUD + Excel 导入）：
  - `GET /holdings`：列出当前持仓（HTMX 局部刷新）
  - `POST /holdings`（form-urlencoded）：单条新增；返回 `partials/_list_table.html` 片段
  - `POST /holdings/import`（multipart/form-data .xlsx）：批量导入；中文列名映射（代码/名称/数量/成本）；upsert 语义；`ensure_default_user()` 自动建用户
- [ ] **F**（持仓 SoT 集成）：`apps/common/holdings_sot.py` 加载 `MY_HOLDINGS_YAML` → 与 DB upsert 同步；UI 只展示 `active=true` 标的
- [ ] **G**（Lighthouse）：本地 `lhci autorun` 跑 4 次取中位数，Performance ≥ 90，FCP < 800ms，TTI < 1000ms；报告保存 `diting-src/data/lhci/`
- [ ] **H**（单测）：`tests/copilot/` 含 `test_portfolio.py`（≥ 5 用例：列表空 / 创建后列出 / Excel 缺列 / Excel 解析补 0 / Excel 空解析报错）+ 旧 `test_health.py` + 新增 `test_models.py / test_sot_load.py`；本步至少 **≥ 8 用例**，全量 `tests/copilot/` ≥ 48 passed
- [ ] **I**（Makefile 合约）：`copilot-step02-prep/migrate/import-sot/lhci/notrade-check/test/all/status/clean`
- [ ] **J**（no-trade 静态审计）：`scripts/assert_no_trade_button.sh` 扫 `templates/*.html` 命中 `下单 | buy_now | sell_now | place_order` = 0

> **永久规则**：UI 上**禁止**出现"一键下单"/"立即买入"/"一键卖出"按钮；持仓导入 / CRUD 接口**禁止**触发任何外部交易 API（券商 / 第三方撮合）。"建议卖出"为文案提示是允许的；任何 `<form action="...broker">` 视为违规。

> **数据细节**：本机用 SQLAlchemy 2.x + aiosqlite 异步 + Starlette `TestClient` 时**必须**装 `greenlet`（否则 `MissingGreenlet` error）。`requires-python = ">=3.9"`（本机 3.9.6 通过 6 子用例 + 全量 48 用例 in 1.81s）。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[../01_实践目标与策略.md](../01_实践目标与策略.md) §3.2、[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md)
> - **DNA**：[`_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml`](../../../../_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml) `tech_stack`（HTMX 1.9 / Alpine 3 / Jinja2 3.x / SQLite 3.40+）+ `quantitative_goals.lighthouse_perf ≥ 90`
> - **共享规约**：[15_前后端职责与产品价值优先级](../../../../_共享规约/15_前后端职责与产品价值优先级.md)
> - **持仓 SoT**：[`diting-src/data/config/my_holdings.example.yaml`](../../../../../../diting-src/data/config/my_holdings.example.yaml) → `my_holdings.yaml`；env `MY_HOLDINGS_YAML`
> - **L4**：[实践记录_W03_Web骨架与SQLite](../../../../../04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/实践记录_W03_Web骨架与SQLite.md) — 含 6/6 + 全量 48 passed、greenlet 增补、sqlite3 .schema 输出
> - **上游**：step_01；**下游**：step_03（M1 体检消费 `events:monitor:health_change`）、step_04（M2 推荐池消费 `events:thrust:thesis_proposed`）、step_05（M3 告警）、step_06（M4 价值账本写 `value_snapshots`）

## §3 数据采集对象与落库映射

| 输入源 | 触发时机 | 落库表 | 字段映射 |
|---|---|---|---|
| 持仓 SoT yaml（`active=true`）| `make copilot-step02-import-sot` 或 web 启动时 lifespan | `users` + `holdings` | yaml.user_id → users.user_id；yaml.holdings[*] → holdings (symbol, name, shares, cost_price) |
| Web 表单 `POST /holdings` | 用户手工 | `holdings` | form fields → holdings 列 |
| Excel 导入 `POST /holdings/import` | 用户上传 .xlsx | `holdings` | 中文列名 →（代码/名称/数量/成本）→ holdings；upsert by `UNIQUE(user_pk, symbol)` |
| 5 维度事件流 payload（step_03+ consumer）| Redis stream `XREAD`/`XREADGROUP` | `event_logs` | stream_key、msg_id（Stream entry id）、payload（dict→JSON）、handled、error、received_at |
| step_06 月度统计 | scheduler 月底跑 | `value_snapshots` | snapshot_date + total_value（含 SCS/EV 等 step_06 算） |

### §3.1 4 张表 ORM Schema 详表

| 表 | 列 | 类型 | 约束 / 索引 | 用途 |
|---|---|---|---|---|
| **users** | id | INTEGER | PK auto | 主键 |
|  | user_id | VARCHAR(64) | NOT NULL UNIQUE | 业务标识（启动期单用户：`default`）|
|  | display_name | VARCHAR(128) | NULL | UI 显示 |
|  | created_at | DATETIME | DEFAULT NOW | — |
| **holdings** | id | INTEGER | PK auto | — |
|  | user_pk | INTEGER | NOT NULL FK users.id | 关联 |
|  | symbol | VARCHAR(16) | NOT NULL | A 股代码（6 位数字，补 0）|
|  | name | VARCHAR(64) | NULL | 中文名 |
|  | shares | INTEGER | NOT NULL ≥ 0 | 持仓股数 |
|  | cost_price | NUMERIC(12,4) | NULL | 成本价 |
|  | updated_at | DATETIME | onupdate NOW | — |
|  | **`UNIQUE(user_pk, symbol)`** | | uq_user_symbol | 防重复 |
| **value_snapshots** | id | INTEGER | PK auto | — |
|  | user_pk | INTEGER | NOT NULL FK users.id | 关联 |
|  | snapshot_date | DATE | NOT NULL | 月初快照 |
|  | total_value | NUMERIC(18,2) | NULL | 总市值（step_06 写）|
|  | scs_score | NUMERIC(6,2) | NULL | SCS（step_06）|
|  | ev_score | NUMERIC(6,2) | NULL | EV（step_06）|
|  | **`UNIQUE(user_pk, snapshot_date)`** | | uq_user_snapshot | 同月一行 |
| **event_logs** | id | INTEGER | PK auto | — |
|  | stream_key | VARCHAR(64) | NOT NULL | `events:*:*` |
|  | msg_id | VARCHAR(64) | NOT NULL | Stream entry id |
|  | payload | TEXT | NOT NULL | JSON 序列化 |
|  | handled | BOOLEAN | DEFAULT FALSE | consumer 处理后 true |
|  | error | TEXT | NULL | 处理失败原因 |
|  | received_at | DATETIME | DEFAULT NOW | — |
|  | **`UNIQUE(stream_key, msg_id)`** | | uq_stream_msg | 防重复消费 |
|  | INDEX(stream_key, handled) | | ix_stream_handled | consumer 扫未处理 |

**说明**：
- `holdings` 不存"当前价"——价格刷新由 D4 step_02 行情服务在内存或 Redis 持有；本表只存"成本/数量"等用户输入。
- `event_logs` 是 5 维度事件流的**统一审计表**；下游 step_03~05 consumer 不直接落 `payload` 全量到业务表，业务表（如未来的 `health_history`）由各模块自建。本表是"审计追溯"层。
- `value_snapshots` 启动期只在 step_06 月底 cron 写入；本步只**建表**。
- 字段类型用 SQLAlchemy 2.x type annotation：`Mapped[int]`、`Mapped[Decimal]`、`Mapped[Optional[str]]`。

## §3.5 数据质量验收矩阵

### §3.5.1 模板与首屏性能

| # | 维度 | 必产字段 / 衍生 | 启动期覆盖 | 启动期降级路径 |
|---|---|---|---|---|
| W1 | **4 色卡片骨架** | base.html + partials/_holding_card.html 渲染绿/黄/橙/红 4 卡 | ✅ 静态占位 | 数据由 step_03 push_level 注入 |
| W2 | **首屏 < 1s** | Lighthouse Performance ≥ 90、FCP < 800ms、TTI < 1000ms | ⚠️ 启动期目标 | 关键 CSS inline、HTMX/Alpine CDN preconnect、图片懒加载 |
| W3 | **响应式** | 桌面 / iPad 移动断点 OK | ✅ Tailwind `md:` `lg:` | — |
| W4 | **HTMX/Alpine 隔离** | 不引入 React/Vue/jQuery 等重型框架；package.json/CDN 黑名单扫 | ✅ | npm dep 树校验 |
| W5 | **base.html 含 `_list_table` partial 引用** | `{% include 'partials/_list_table.html' %}` 存在 | ✅ | — |

### §3.5.2 SQLite 4 张表

| # | 维度 | 必产字段 / 衍生 | 启动期覆盖 | 启动期降级路径 |
|---|---|---|---|---|
| D1 | **users 表** | `user_id UNIQUE`、`ensure_default_user()` 启动 idempotent | ✅ | — |
| D2 | **holdings 表 + UNIQUE(user_pk, symbol)** | 防同用户同 symbol 重复；upsert 用 `ON CONFLICT DO UPDATE` | ✅ | aiosqlite `INSERT OR REPLACE` 兜底 |
| D3 | **value_snapshots 表 + UNIQUE(user_pk, snapshot_date)** | schema 建好；step_06 才写入 | ✅ schema 就绪 | — |
| D4 | **event_logs 表 + UNIQUE(stream_key, msg_id)** | 防重复消费；schema 建好；step_03+ 写入 | ✅ schema 就绪 | — |
| D5 | **alembic migration 可重入** | `alembic upgrade head` 多跑 OK；offline SQL 模式可生成 .sql | ✅ | 启动期可用 `database.init_db()` 直建表替代 alembic |
| D6 | **`.schema` 输出含 4 表名** | `sqlite3 data/copilot.db ".tables"` → `event_logs holdings users value_snapshots` | ✅ | — |
| D7 | **FK 约束启用** | SQLite PRAGMA `foreign_keys=ON` lifespan 开启 | ✅ | event listener `PRAGMA foreign_keys=ON` |
| D8 | **greenlet 依赖** | `pyproject.toml` 含 `greenlet>=3`；TestClient 不抛 `MissingGreenlet` | ✅ | — |

### §3.5.3 持仓 SoT 集成

| # | 维度 | 必产字段 / 衍生 | 启动期覆盖 | 启动期降级路径 |
|---|---|---|---|---|
| S1 | **SoT 加载器** | `apps/common/holdings_sot.py` 单一加载器；env `MY_HOLDINGS_YAML` 不存在则报错（不静默）| ✅ 复用共享 | — |
| S2 | **仅 active=true 展示** | UI 列表过滤 `active==true`；inactive 标的不出现在 `/holdings` | ✅ | — |
| S3 | **SoT → DB upsert** | 启动期 lifespan 或手动 `make copilot-step02-import-sot` 同步；不删 DB 已有但 yaml 删除的持仓（保留人工录入） | ✅ | — |
| S4 | **不在前端硬编码** | grep `templates/*.html` 含具体 symbol 代码（如 `600519`）= 0；UI 永远从 SoT/DB 渲染 | ✅ | — |
| S5 | **A 股代码补零** | `symbol="6"` 自动补到 `"000006"`（excel_importer 已实现）；symbol 长度 = 6 | ✅ | `parse_excel` 单测覆盖 |

### §3.5.4 工程 no-trade

| # | 维度 | 必产 | 启动期覆盖 |
|---|---|---|---|
| E1 | **无下单按钮 HTML 静态扫** | `rg -i "下单\|buy_now\|sell_now\|place_order\|submit_order" apps/copilot/templates/` = 0 命中 | ✅ |
| E2 | **导入接口不调外部 API** | grep `apps/copilot/services/excel_importer.py` 含 `requests\|httpx.*http://[^l]` 外部域 = 0 命中 | ✅ |
| E3 | **CSRF / 表单只本域提交** | 所有 `<form>` 无 `action=` 或 `action="/holdings*"`（不指向第三方）| ✅ |

**共 19 项**；启动期标的可以少，但 19 项必须全绿。逐项验证命令见 §9。

## §4 凭证清单与环境模板

### §4.1 用户必须提供的凭证

| 凭证 / 环境变量 | 用途 | 默认值 | 写在哪 | 是否必填 |
|---|---|---|---|---|
| `MY_HOLDINGS_YAML` | 持仓 SoT 路径 | `data/config/my_holdings.yaml` | `diting-src/.env` | **必填**（启动期前先 `cp data/config/my_holdings.example.yaml my_holdings.yaml` 改填真实持仓）|
| `COPILOT_DATABASE_URL` | SQLite 异步 URL | `sqlite+aiosqlite:///./data/copilot.db` | `.env` | 可不填 |
| `COPILOT_LHCI_TARGET_PERF` | Lighthouse Perf 门槛 | `90` | `.env` | 可不填 |

### §4.2 `.env.template` 增补片段

```text
# ============ persistence ============
COPILOT_DATABASE_URL=sqlite+aiosqlite:///./data/copilot.db
MY_HOLDINGS_YAML=data/config/my_holdings.yaml

# ============ lhci ============
COPILOT_LHCI_TARGET_PERF=90
COPILOT_LHCI_TARGET_FCP=800
COPILOT_LHCI_TARGET_TTI=1000
```

### §4.3 `data/config/my_holdings.yaml` 示例（用户填后取消注释）

```yaml
user_id: default
display_name: 我的实盘
holdings:
  - symbol: "600519"   # A 股 6 位
    name: 贵州茅台
    shares: 100
    cost_price: 1800.50
    active: true       # 启动期仅 active=true 拉真实数据
  - symbol: "601398"
    name: 工商银行
    shares: 5000
    cost_price: 5.20
    active: true
  - symbol: "000333"
    name: 美的集团
    shares: 200
    cost_price: 65.00
    active: false      # 不参与启动期真流
```

> **安全**：`my_holdings.yaml` 已在 `.gitignore`；**禁止 commit 真实持仓**。

## §5 启动期目标

| 指标 | 启动期门槛 | 测量方式 |
|---|---|---|
| `GET /` 状态码 | 200 | `curl -sI / \| head -1` |
| `GET /holdings` 状态码 | 200 | `curl -sI /holdings` |
| `POST /holdings` 表单写入后 list 含 symbol | 200 + 含 `<td>{symbol}</td>` | `curl -sX POST /holdings -d "..." \| grep -o "{symbol}"` |
| `POST /holdings/import` xlsx 上传 | 200 + DB 新增 N 行 | sqlite3 count |
| **Lighthouse Performance** | ≥ 90（中位数）| `lhci autorun --collect.numberOfRuns=4` |
| **FCP** | < 800ms | lhci 同上 |
| **TTI** | < 1000ms | lhci 同上 |
| `sqlite3 .tables` 含 4 表 | `event_logs holdings users value_snapshots` | `sqlite3 data/copilot.db ".tables"` |
| `tests/copilot/test_portfolio.py` | ≥ 5 用例全过 | `pytest -v` |
| `tests/copilot/` 全量 | ≥ 48 passed（与 step_01 链接合）| `pytest -q` |
| **no-trade 静态扫** | 命中 = 0 | `bash scripts/assert_no_trade_button.sh` |

## §6 下一步

本步 ✅ → **step_03 持仓体检模块（M1）**：消费 `events:monitor:health_change` → 4 色卡片填真色 + 详情页（30 天健康度曲线）。

不展开扩展期（候选池扩到 30 持仓 / 多用户）/ 完善期细节。

## §7 实施规划（细化版 · 给后续执行模型）

### §7.1 实现要点（位置 / 输入 / 核心逻辑 / 关键字段 / 错误处理 / 验证）

| # | 要点 | 位置 | 输入 | 核心逻辑 | 关键字段 / 输出 | 错误处理 | 验证标准 |
|---|---|---|---|---|---|---|---|
| 1 | **依赖增补** | `pyproject.toml` | step_01 基线 | 追加 `sqlalchemy>=2 / aiosqlite / openpyxl / pandas / greenlet>=3 / alembic` | 依赖锁版本 | `pip check` 无 conflict | `pip install -e . && pip show greenlet` |
| 2 | **database.py** | `apps/copilot/db/database.py` | `COPILOT_DATABASE_URL` | `create_async_engine` + `async_sessionmaker(class_=AsyncSession)` + `init_db()` + `get_db()` dep | `engine / AsyncSessionLocal / Base / init_db / get_db` | 启动失败 fail-fast | `await init_db()` 后 `data/copilot.db` 存在 |
| 3 | **models.py 4 表** | `apps/copilot/db/models.py` | Base | `User / Holding / ValueSnapshot / EventLog` 4 个 ORM 类；含 `UniqueConstraint` | `__tablename__` 4 个；ORM 字段见 §3.1 | type annotation 检查 | `python3 -c "from apps.copilot.db.models import *; print(Base.metadata.tables.keys())"` 返回 4 |
| 4 | **`PRAGMA foreign_keys=ON`** | `database.py` | engine | `@event.listens_for(Engine, "connect")` 监听 connect 事件，发 PRAGMA | listener 注册 | 异常打日志 | `sqlite3 data/copilot.db "PRAGMA foreign_keys;"` = 1 |
| 5 | **holdings_sot.py** | `apps/common/holdings_sot.py` | `MY_HOLDINGS_YAML` | yaml 读取 → Pydantic 模型 → `load_active() -> list[HoldingDto]` | `Holding(symbol, name, shares, cost_price, active)`；`load_active()` 过滤 active=true | yaml 缺失 raise；symbol 长度 != 6 raise | `test_sot_load.py::test_active_only_returns_active_true` |
| 6 | **excel_importer** | `apps/copilot/services/excel_importer.py` | UploadFile（.xlsx）| openpyxl 读 → pandas DataFrame → 中文列名映射 →（代码/名称/数量/成本）→ `parse_excel()` 返回 `list[dict]`；补 0 symbol；空 raise | dict keys = symbol/name/shares/cost_price | 缺列报 `ImportError("缺少列: ...")` ；空 raise `ValueError` | `test_excel_import_missing_columns / test_parse_excel_pad_symbol / test_parse_excel_empty_raises` |
| 7 | **routers/portfolio.py** | 同 | request + db dep | `GET /holdings` 返完整页；`POST /holdings` form 表单 upsert + 返回 `partials/_list_table.html` 片段（HTMX swap）；`POST /holdings/import` multipart 上传 + 调用 importer + bulk upsert | 3 路由 | upsert 用 `select ... where unique → update else insert`；表单缺字段 422 | `test_holdings_page_empty / test_create_holding_and_list` |
| 8 | **routers/web.py** | 同 | request | `GET /` 返 `index.html`，含 4 色卡片骨架占位（数据 step_03 注入）| 1 路由 | — | `test_index_returns_200` |
| 9 | **templates** | `apps/copilot/templates/` | — | `base.html`（html shell + nav + Tailwind CDN）；`index.html`（{% extends base %}）；`portfolio_list.html`；`partials/_list_table.html`（仅 `<table>` 片段，供 HTMX swap）；`partials/_holding_card.html`（单卡） | 5 个 .html | Jinja2 严格模式（`autoescape=True`）| 浏览器渲染 + grep 关键文案 |
| 10 | **static** | `apps/copilot/static/` | — | `static/css/app.css`（少量自定义）；`static/js/`（启动期空）；`static/img/logo.svg`（占位）| 3 子目录 | StaticFiles mount | `curl -sI /static/css/app.css` 200 |
| 11 | **main.py lifespan 接入** | `apps/copilot/main.py` | settings | startup: `await init_db()` + `await sync_sot_to_db()`；mount `/static`；include `routers.web / routers.portfolio` | 与 step_01 main.py 兼容 | DB 锁失败 fail-fast | uvicorn 起 + `/health` + `/holdings` |
| 12 | **lhci 脚本** | `scripts/lhci_run.sh` | uvicorn 已启 | `lhci autorun --collect.numberOfRuns=4 --collect.url=http://127.0.0.1:8080/`；assert ≥ 90 | `data/lhci/lhci-report-*.json` + summary md | < 90 退出码 1 | `bash scripts/lhci_run.sh` |
| 13 | **no-trade 扫** | `scripts/assert_no_trade_button.sh` | `apps/copilot/templates/` | `rg -i "下单\|buy_now\|sell_now\|place_order\|submit_order" \| (! grep .)` | 命中数 = 0 | 命中 raise | `bash scripts/assert_no_trade_button.sh` |
| 14 | **tests** | `tests/copilot/test_portfolio.py / test_models.py / test_sot_load.py` | conftest | 5 + 2 + 1 = 8 用例 | 见 §7.2.8 | — | `pytest -q` 全过 |
| 15 | **Makefile** | `diting-src/Makefile` | settings | 暴露 `copilot-step02-*` 8 target | `.PHONY` 行 | target 退出码 != 0 | `make -n copilot-step02-all` |

### §7.2 详细实施步骤

#### 7.2.1 目录与依赖

```bash
# 工作目录：diting-src
mkdir -p apps/copilot/db apps/copilot/services apps/common
mkdir -p apps/copilot/templates/partials apps/copilot/static/{css,js,img}
mkdir -p data data/config data/lhci
touch apps/copilot/db/__init__.py apps/copilot/services/__init__.py
touch apps/common/__init__.py
```

`pyproject.toml` 追加：

```toml
dependencies = [
  # ... step_01 已有 ...
  "sqlalchemy>=2",
  "aiosqlite>=0.19",
  "openpyxl>=3.1",
  "pandas>=2",
  "greenlet>=3",        # SQLAlchemy 2 async + TestClient 必备
  "alembic>=1.13",
  "pyyaml>=6",
]
```

> **关键坑**：不装 greenlet 时，`pytest tests/copilot/test_portfolio.py` 会报 `MissingGreenlet: greenlet_spawn has not been called`。L4 W03 记录已注明此偏离。

#### 7.2.2 `apps/copilot/db/database.py`（异步 engine + lifespan）

```python
from sqlalchemy.ext.asyncio import (
    create_async_engine, async_sessionmaker, AsyncSession
)
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import event
from sqlalchemy.engine import Engine
from apps.copilot.config import settings


class Base(DeclarativeBase):
    pass


engine = create_async_engine(settings.database_url, future=True)
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)


@event.listens_for(Engine, "connect")
def _set_sqlite_pragma(dbapi_conn, _):
    cursor = dbapi_conn.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()


async def init_db() -> None:
    from apps.copilot.db import models  # noqa  importing registers tables
    import os
    os.makedirs("data", exist_ok=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def get_db() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        yield session
```

#### 7.2.3 `apps/copilot/db/models.py`（4 张表骨架）

```python
from datetime import datetime, date
from decimal import Decimal
from typing import Optional
from sqlalchemy import (
    Integer, String, ForeignKey, DateTime, Numeric, Date,
    Boolean, Text, UniqueConstraint, Index, func
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from apps.copilot.db.database import Base


class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[str] = mapped_column(String(64), unique=True, nullable=False)
    display_name: Mapped[Optional[str]] = mapped_column(String(128))
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    holdings: Mapped[list["Holding"]] = relationship(back_populates="user")


class Holding(Base):
    __tablename__ = "holdings"
    __table_args__ = (UniqueConstraint("user_pk", "symbol", name="uq_user_symbol"),)
    id: Mapped[int] = mapped_column(primary_key=True)
    user_pk: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    symbol: Mapped[str] = mapped_column(String(16), nullable=False)
    name: Mapped[Optional[str]] = mapped_column(String(64))
    shares: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    cost_price: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 4))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )
    user: Mapped["User"] = relationship(back_populates="holdings")


class ValueSnapshot(Base):
    __tablename__ = "value_snapshots"
    __table_args__ = (UniqueConstraint("user_pk", "snapshot_date", name="uq_user_snapshot"),)
    id: Mapped[int] = mapped_column(primary_key=True)
    user_pk: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    snapshot_date: Mapped[date] = mapped_column(Date, nullable=False)
    total_value: Mapped[Optional[Decimal]] = mapped_column(Numeric(18, 2))
    scs_score: Mapped[Optional[Decimal]] = mapped_column(Numeric(6, 2))
    ev_score: Mapped[Optional[Decimal]] = mapped_column(Numeric(6, 2))


class EventLog(Base):
    __tablename__ = "event_logs"
    __table_args__ = (
        UniqueConstraint("stream_key", "msg_id", name="uq_stream_msg"),
        Index("ix_stream_handled", "stream_key", "handled"),
    )
    id: Mapped[int] = mapped_column(primary_key=True)
    stream_key: Mapped[str] = mapped_column(String(64), nullable=False)
    msg_id: Mapped[str] = mapped_column(String(64), nullable=False)
    payload: Mapped[str] = mapped_column(Text, nullable=False)
    handled: Mapped[bool] = mapped_column(Boolean, default=False)
    error: Mapped[Optional[str]] = mapped_column(Text)
    received_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
```

#### 7.2.4 `apps/common/holdings_sot.py`（SoT 加载器 · 跨维度复用）

```python
import os
import yaml
from dataclasses import dataclass
from typing import List, Optional


@dataclass(frozen=True)
class HoldingDto:
    symbol: str
    name: Optional[str]
    shares: int
    cost_price: Optional[float]
    active: bool


def load_all(path: Optional[str] = None) -> List[HoldingDto]:
    p = path or os.environ.get("MY_HOLDINGS_YAML", "data/config/my_holdings.yaml")
    if not os.path.exists(p):
        raise FileNotFoundError(f"holdings SoT yaml not found: {p}")
    with open(p, "r", encoding="utf-8") as f:
        raw = yaml.safe_load(f) or {}
    items = []
    for h in raw.get("holdings", []):
        sym = str(h["symbol"]).zfill(6)
        items.append(HoldingDto(
            symbol=sym, name=h.get("name"),
            shares=int(h.get("shares", 0)),
            cost_price=float(h["cost_price"]) if h.get("cost_price") is not None else None,
            active=bool(h.get("active", True)),
        ))
    return items


def load_active(path: Optional[str] = None) -> List[HoldingDto]:
    return [h for h in load_all(path) if h.active]


def get_user_id(path: Optional[str] = None) -> str:
    p = path or os.environ.get("MY_HOLDINGS_YAML", "data/config/my_holdings.yaml")
    with open(p, "r", encoding="utf-8") as f:
        raw = yaml.safe_load(f) or {}
    return raw.get("user_id", "default")
```

> **跨维度复用**：本模块**所有维度共享**——D1 数据采集只对 `load_active()` 标的拉财报；D2 thesis 生成同；D3 探针调度同；D4 sell_signal 同；D0 UI 展示同。**禁止**任一维度自建 SoT 加载器。

#### 7.2.5 `apps/copilot/services/excel_importer.py`（中文列名 + symbol 补零 + upsert）

```python
import io
import pandas as pd
from typing import List


CHINESE_COLUMN_MAP = {
    "代码": "symbol",
    "股票代码": "symbol",
    "名称": "name",
    "股票名称": "name",
    "数量": "shares",
    "持仓": "shares",
    "持仓数量": "shares",
    "成本": "cost_price",
    "成本价": "cost_price",
}

REQUIRED_COLUMNS = ["symbol", "shares"]


class ImportError(ValueError):
    pass


def parse_excel(file_bytes: bytes) -> List[dict]:
    """Parse uploaded .xlsx; map Chinese columns; pad symbol to 6 digits."""
    if not file_bytes:
        raise ValueError("empty file")
    df = pd.read_excel(io.BytesIO(file_bytes), dtype=str)
    df.columns = [CHINESE_COLUMN_MAP.get(c.strip(), c.strip()) for c in df.columns]
    missing = [c for c in REQUIRED_COLUMNS if c not in df.columns]
    if missing:
        raise ImportError(f"缺少必需列: {missing}（已识别列: {list(df.columns)}）")
    rows: List[dict] = []
    for _, r in df.iterrows():
        sym = str(r["symbol"]).strip().zfill(6) if pd.notna(r["symbol"]) else None
        if not sym:
            continue
        rows.append({
            "symbol": sym,
            "name": str(r["name"]).strip() if "name" in df.columns and pd.notna(r.get("name")) else None,
            "shares": int(float(r["shares"])) if pd.notna(r["shares"]) else 0,
            "cost_price": float(r["cost_price"]) if "cost_price" in df.columns and pd.notna(r.get("cost_price")) else None,
        })
    if not rows:
        raise ValueError("解析后无有效行")
    return rows


async def ensure_default_user(session) -> int:
    """Idempotent: return users.id for user_id='default'."""
    from sqlalchemy import select
    from apps.copilot.db.models import User
    from apps.common.holdings_sot import get_user_id
    uid = get_user_id()
    res = await session.execute(select(User).where(User.user_id == uid))
    user = res.scalar_one_or_none()
    if user is None:
        user = User(user_id=uid)
        session.add(user)
        await session.flush()
    return user.id


async def upsert_holdings(session, user_pk: int, rows: List[dict]) -> int:
    """Upsert by UNIQUE(user_pk, symbol); return affected count."""
    from sqlalchemy import select
    from apps.copilot.db.models import Holding
    count = 0
    for r in rows:
        existing = (await session.execute(
            select(Holding).where(Holding.user_pk == user_pk, Holding.symbol == r["symbol"])
        )).scalar_one_or_none()
        if existing:
            existing.shares = r["shares"]
            if r.get("name"): existing.name = r["name"]
            if r.get("cost_price") is not None: existing.cost_price = r["cost_price"]
        else:
            session.add(Holding(user_pk=user_pk, **r))
        count += 1
    await session.commit()
    return count
```

#### 7.2.6 `apps/copilot/routers/portfolio.py`（3 路由）

```python
from fastapi import APIRouter, Depends, Form, UploadFile, File, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from apps.copilot.db.database import get_db
from apps.copilot.db.models import Holding
from apps.copilot.services.excel_importer import (
    parse_excel, ensure_default_user, upsert_holdings
)

router = APIRouter()
templates = Jinja2Templates(directory="apps/copilot/templates")


@router.get("/holdings", response_class=HTMLResponse)
async def list_holdings(request: Request, db: AsyncSession = Depends(get_db)):
    user_pk = await ensure_default_user(db)
    rows = (await db.execute(
        select(Holding).where(Holding.user_pk == user_pk).order_by(Holding.symbol)
    )).scalars().all()
    return templates.TemplateResponse(
        "portfolio_list.html", {"request": request, "holdings": rows}
    )


@router.post("/holdings", response_class=HTMLResponse)
async def create_holding(
    request: Request,
    symbol: str = Form(...), name: str = Form(""),
    shares: int = Form(0), cost_price: float = Form(0.0),
    db: AsyncSession = Depends(get_db),
):
    user_pk = await ensure_default_user(db)
    sym = symbol.strip().zfill(6)
    await upsert_holdings(db, user_pk, [{
        "symbol": sym, "name": name or None,
        "shares": shares, "cost_price": cost_price,
    }])
    rows = (await db.execute(
        select(Holding).where(Holding.user_pk == user_pk).order_by(Holding.symbol)
    )).scalars().all()
    # HTMX swap: 仅返回表格 partial
    return templates.TemplateResponse(
        "partials/_list_table.html", {"request": request, "holdings": rows}
    )


@router.post("/holdings/import", response_class=HTMLResponse)
async def import_holdings(
    request: Request, file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
):
    content = await file.read()
    rows = parse_excel(content)
    user_pk = await ensure_default_user(db)
    n = await upsert_holdings(db, user_pk, rows)
    all_rows = (await db.execute(
        select(Holding).where(Holding.user_pk == user_pk).order_by(Holding.symbol)
    )).scalars().all()
    return templates.TemplateResponse(
        "portfolio_list.html",
        {"request": request, "holdings": all_rows, "import_count": n},
    )
```

#### 7.2.7 模板骨架（5 个 .html）

`templates/base.html`：

```html
<!doctype html>
<html lang="zh"><head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>{% block title %}diting · copilot{% endblock %}</title>
  <link rel="preconnect" href="https://cdn.tailwindcss.com">
  <script src="https://cdn.tailwindcss.com"></script>
  <script defer src="https://unpkg.com/htmx.org@1.9.10"></script>
  <script defer src="https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js"></script>
  <link rel="stylesheet" href="/static/css/app.css">
</head><body class="min-h-screen bg-gray-50">
  <nav class="bg-white shadow p-4"><a href="/" class="font-bold">diting · 副驾驶</a> · <a href="/holdings">持仓</a></nav>
  <main class="p-6">{% block content %}{% endblock %}</main>
</body></html>
```

`templates/portfolio_list.html`：

```html
{% extends "base.html" %}
{% block content %}
<h1 class="text-2xl mb-4">当前持仓（{{ holdings|length }} 只）</h1>
{% if import_count %}<p class="text-green-600">已导入 {{ import_count }} 条 ✅</p>{% endif %}
<div id="holdings-table">{% include "partials/_list_table.html" %}</div>
<form hx-post="/holdings" hx-target="#holdings-table" hx-swap="innerHTML"
      class="mt-6 flex gap-2">
  <input name="symbol" placeholder="代码（如 600519）" required class="border p-2">
  <input name="name" placeholder="名称" class="border p-2">
  <input name="shares" type="number" placeholder="数量" class="border p-2">
  <input name="cost_price" type="number" step="0.01" placeholder="成本" class="border p-2">
  <button class="bg-blue-600 text-white px-4">添加</button>
</form>
<form action="/holdings/import" method="post" enctype="multipart/form-data" class="mt-4">
  <input type="file" name="file" accept=".xlsx">
  <button class="bg-gray-600 text-white px-4">导入 Excel</button>
</form>
{% endblock %}
```

`templates/partials/_list_table.html`：

```html
<table class="w-full border-collapse">
  <thead><tr class="bg-gray-100">
    <th class="p-2 text-left">代码</th><th class="p-2 text-left">名称</th>
    <th class="p-2 text-right">数量</th><th class="p-2 text-right">成本</th>
  </tr></thead>
  <tbody>{% for h in holdings %}
    <tr><td class="p-2">{{ h.symbol }}</td><td class="p-2">{{ h.name or "—" }}</td>
        <td class="p-2 text-right">{{ h.shares }}</td>
        <td class="p-2 text-right">{{ h.cost_price or "—" }}</td></tr>
  {% endfor %}</tbody>
</table>
```

`templates/index.html`（4 色卡片占位 · 数据由 step_03 注入）：

```html
{% extends "base.html" %}
{% block content %}
<h1 class="text-2xl mb-4">持仓体检（M1 · 占位）</h1>
<div class="grid grid-cols-2 md:grid-cols-4 gap-4">
  {% for level in ["green","yellow","orange","red"] %}
  <div class="border-l-8 p-4 bg-white shadow {{ {'green':'border-green-500','yellow':'border-yellow-500','orange':'border-orange-500','red':'border-red-500'}[level] }}">
    <p class="font-bold">{{ level|upper }}</p>
    <p class="text-sm text-gray-500">step_03 接入后展示真实健康度</p>
  </div>
  {% endfor %}
</div>
{% endblock %}
```

> **no-trade 纪律**：以上 4 个模板**绝不包含**"立即下单/一键买入"等文案；step_03 注入数据后允许"建议关注/建议卖出"文案，**禁止**"立即"。

#### 7.2.8 `tests/copilot/test_portfolio.py`（5 用例骨架）

```python
import io
import pytest
from httpx import AsyncClient
from apps.copilot.main import app
from apps.copilot.db.database import init_db


@pytest.fixture(autouse=True, scope="session")
async def _init_db():
    await init_db()


@pytest.mark.asyncio
async def test_holdings_page_empty():
    async with AsyncClient(app=app, base_url="http://t") as ac:
        r = await ac.get("/holdings")
    assert r.status_code == 200
    assert "当前持仓（0 只）" in r.text


@pytest.mark.asyncio
async def test_create_holding_and_list():
    async with AsyncClient(app=app, base_url="http://t") as ac:
        r = await ac.post("/holdings", data={
            "symbol": "600519", "name": "贵州茅台",
            "shares": "100", "cost_price": "1800.50",
        })
    assert r.status_code == 200
    assert "<td class=\"p-2\">600519</td>" in r.text or "600519" in r.text


@pytest.mark.asyncio
async def test_excel_import_missing_columns():
    import pandas as pd
    df = pd.DataFrame({"无关列": [1, 2]})
    buf = io.BytesIO()
    df.to_excel(buf, index=False)
    async with AsyncClient(app=app, base_url="http://t") as ac:
        r = await ac.post("/holdings/import",
                          files={"file": ("x.xlsx", buf.getvalue())})
    assert r.status_code in (400, 422, 500)  # ImportError 冒泡或被路由 422


def test_parse_excel_pad_symbol():
    from apps.copilot.services.excel_importer import parse_excel
    import pandas as pd
    df = pd.DataFrame({"代码": ["6", "600519"], "数量": [100, 200]})
    buf = io.BytesIO(); df.to_excel(buf, index=False)
    rows = parse_excel(buf.getvalue())
    assert rows[0]["symbol"] == "000006"
    assert rows[1]["symbol"] == "600519"


def test_parse_excel_empty_raises():
    from apps.copilot.services.excel_importer import parse_excel
    with pytest.raises(ValueError):
        parse_excel(b"")
```

> 配合 step_01 的 `test_health.py` + `test_settings.py` + `test_stream_constants.py`，本子集应 ≥ 8 用例；全量 `tests/copilot/` ≥ 48 用例（与 W04~W08 合并后）。

### §7.3 Makefile 合约（一键复现 · 配置驱动 · 可重入幂等）

| target | 用途 | 入参（env） | 验证标准（输出末段） |
|---|---|---|---|
| `copilot-step02-prep` | 确认 `.env` 关键 key 在；建 `data/` 目录；起 `diting-redis` | `MY_HOLDINGS_YAML` | `env keys ✅ \| data/ ready ✅` |
| `copilot-step02-migrate` | `python3 -c "from apps.copilot.db.database import init_db; import asyncio; asyncio.run(init_db())"` 或 alembic | — | `4 tables created ✅`（含 `sqlite3 .tables` 输出）|
| `copilot-step02-import-sot` | 加载 `my_holdings.yaml` → DB upsert | `MY_HOLDINGS_YAML` | `imported N rows from SoT ✅` |
| `copilot-step02-lhci` | 启 uvicorn 后台 + `lhci autorun --numberOfRuns=4`；assert Perf ≥ 90 | `COPILOT_LHCI_TARGET_PERF?=90` | `Perf=92 (median) ✅` 或 fail |
| `copilot-step02-notrade-check` | `bash scripts/assert_no_trade_button.sh` | — | `no-trade check passed ✅` 或 fail |
| `copilot-step02-test` | `pytest tests/copilot/ -q` | — | `≥ 48 passed ✅` |
| `copilot-step02-all` | prep → migrate → import-sot → up → lhci → notrade → test → clean | — | 8 段全绿 |
| `copilot-step02-status` | DB `holdings count` + SoT 计数 + 4 表存在 | — | 表格输出 |
| `copilot-step02-clean` | 删 `.lhci/` 缓存；不删 DB / .env | — | `clean ✅` |

**合约要求**：
1. 入参全部 env 化（`MY_HOLDINGS_YAML`、`COPILOT_LHCI_TARGET_PERF`），Makefile 不写死 symbol/年份；
2. **配置驱动验证**：在 `my_holdings.yaml` 增 1 个 active 标的，跑 `make copilot-step02-all` 端到端通过；移除后跑 `make copilot-step02-status` 验证 DB 仍有该行（保留人工录入语义）；
3. **8080 占用兜底**：`copilot-step02-up` 启 uvicorn 前必须 `lsof -ti:8080 | xargs -r kill -9`（这是 L4 W03 实测发现的"小坑"，写入 Makefile）；
4. **可重入幂等**：`copilot-step02-all` 第二次跑跳过已建表、SoT 已同步检测、lhci 报告覆盖式生成。

### §7.4 给后续执行模型的指引

1. **顺序刚性**：依赖装齐（7.2.1）→ database.py（7.2.2）→ models.py 4 表（7.2.3）→ holdings_sot.py（7.2.4）→ excel_importer.py（7.2.5）→ routers/portfolio.py（7.2.6）→ 模板（7.2.7）→ tests（7.2.8）→ Makefile（7.3）；任一环节 fail 必须先修再继续。
2. **greenlet 必装**：未装时 TestClient + SQLAlchemy async 会抛 `MissingGreenlet`；这是 L4 W03 的关键经验。
3. **8080 端口释放**：本地反复跑 uvicorn 时残留进程会占口；`lsof -ti:8080 | xargs -r kill -9` 在 Makefile 与文档中固化。
4. **不嵌入完整生产代码**：本文档 §7.2 代码块是骨架（30~80 行/模块）；docstring / 详细异常消息 / 日志格式由 L4 实践记录回写。
5. **L4 回写内容**：执行后须在 `04_阶段规划与实践/00_维度零/stage_1_启动期/实践记录_W03_*` 回写：
   - `sqlite3 data/copilot.db ".tables"` 实际输出（应为 4 张表）；
   - `sqlite3 data/copilot.db ".schema holdings"` 验证 `uq_user_symbol` 约束；
   - `lhci-report-*.json` 中 Performance 中位数；
   - 全量 `pytest -q` 通过用例数（启动期目标 48+）。
6. **持仓 SoT 私有副本**：用户填 `my_holdings.yaml` 时**必须**确认 `.gitignore` 已含该文件；任何 commit 前自检 `git status` 不能出现 `data/config/my_holdings.yaml`（只有 `.example.yaml` 入仓）。
7. **永久规则审计**：
   ```bash
   rg -i "下单|buy_now|sell_now|place_order|submit_order|broker_api" apps/copilot/
   ```
   命中数必须 = 0；UI 文案审计也必须由人复核（"建议卖出"OK，"立即卖出"违规）。

## §8 部署节奏

| 项 | 本 step |
|---|---|
| 部署面 | **本机** uvicorn + SQLite 文件 + Docker `diting-redis` |
| Chart / `diting-infra` | **不改** |
| **deploy-engine** | 不涉及 |
| 镜像 ACR | **不构建**（D0 的 `Dockerfile`/WeasyPrint 在 step_08 月报时启用）|
| Helm release | **—** |
| 何时上 K3s | step_10 阶段验收；本步只把 Web + DB + SoT 基座备好 |

详见：[16 · 阿里云 ECS+K3s+Helm+ACR](../../../../_共享规约/16_阿里云ECS_K3s_ACR_Helm部署与deploy-engine链路.md)。

## §9 准出标准

### §9.1 数据量（本步：DB 行数）

| 表 | 启动期门槛 | 测量 |
|---|---|---|
| `users` | ≥ 1（`default`）| `sqlite3 data/copilot.db "SELECT COUNT(*) FROM users"` |
| `holdings` | = SoT `active=true` 标的数（典型 1~10）| `sqlite3 ... "SELECT COUNT(*) FROM holdings"` |
| `value_snapshots` | 0（schema 就绪，step_06 写）| 同上 |
| `event_logs` | 0（schema 就绪，step_03+ 写）| 同上 |

### §9.2 数据质量（§3.5 19 项必须全绿）

逐项验证命令：

```bash
# 1) 依赖装齐 + greenlet
cd diting-src && pip install -e . && pip show greenlet | grep Version

# 2) DB 建表
python3 -c "from apps.copilot.db.database import init_db; import asyncio; asyncio.run(init_db())"
sqlite3 data/copilot.db ".tables"
# 期望：event_logs holdings users value_snapshots

# 3) UNIQUE 约束
sqlite3 data/copilot.db ".schema holdings" | grep -i uq_user_symbol

# 4) SoT 加载
python3 -c "from apps.common.holdings_sot import load_active; print(len(load_active()))"
# 期望：≥ 1（用户已填 my_holdings.yaml）

# 5) Web 起 + curl
lsof -ti:8080 | xargs -r kill -9
python3 -m uvicorn apps.copilot.main:app --port 8080 &
sleep 2
curl -sI http://127.0.0.1:8080/                | head -1   # 期望 200
curl -sI http://127.0.0.1:8080/holdings        | head -1   # 期望 200
curl -sX POST -d "symbol=600519&shares=100&cost_price=1800" \
     http://127.0.0.1:8080/holdings | grep -o "600519"     # 期望命中
sqlite3 data/copilot.db "SELECT symbol FROM holdings"      # 期望含 600519

# 6) Lighthouse
bash scripts/lhci_run.sh                                    # 期望 Perf ≥ 90

# 7) no-trade 静态扫
bash scripts/assert_no_trade_button.sh                      # 期望 0 命中
rg -i "下单|buy_now|sell_now|place_order|submit_order" apps/copilot/

# 8) 单测
pytest tests/copilot/ -q                                    # 期望 ≥ 48 passed

# 9) Makefile
make copilot-step02-all                                     # 期望 8 段全绿
make copilot-step02-status                                  # 期望 4 表 + SoT 计数表
```

### §9.3 锁库（无）

本步不锁库；下游 step_03+ 写 `event_logs` 时按 `UNIQUE(stream_key, msg_id)` 防重。

### §9.4 准出确认

- [ ] §9.2 全部 9 条命令本机跑通 ✅
- [ ] §3.5 19 项全绿
- [ ] L4 实践记录 `实践记录_W03_Web骨架与SQLite.md` 已回写 §9.2 全部输出（含 `.tables`、`.schema holdings`、lhci 中位数、pytest 输出）
- [ ] 通知 step_03 owner（M1 体检模块）可启动消费 `events:monitor:health_change`

## §10 [Deploy]

启动期 ConfigMap / Helm Chart **不创建**。上 K3s 时（step_10 或扩展期）：
- ConfigMap 增 `COPILOT_DATABASE_URL`、`MY_HOLDINGS_YAML`（**只读挂载**真实持仓 yaml 为 Secret，不入 ConfigMap）；
- Liveness/readiness 指向 `/health`；
- StatefulSet 持久化 SQLite 文件至 PVC（启动期单副本即可，扩展期评估迁 Postgres）。

## §11 依赖与禁忌

| 类型 | 依赖项 | 当前就绪 | 缺失时处理 |
|---|---|---|---|
| 硬依赖 | step_01 完成（FastAPI + Settings + redis client） | ✅ | 回 step_01 |
| 硬依赖 | `my_holdings.yaml` 已填 active 标的 ≥ 1 | 用户提供 | 阻塞；提示用户复制 `.example.yaml` |
| 硬依赖 | `greenlet>=3` 装 | pip | 不装 → TestClient `MissingGreenlet` |
| 软依赖 | Node.js + `lhci` CLI | 用户本机 | 缺则 lhci 跳过；启动期允许 ⚠️ 标记 |
| 软依赖 | xlsx 样例文件（用于 import 测试） | 可选 | 用 pandas 生成临时 .xlsx fixture |

**严禁**：
- UI 引入"立即下单/一键买入/一键卖出"按钮或链接；
- 持仓导入接口调用券商 API / 第三方撮合服务；
- 在模板中硬编码具体股票代码（违反 SoT 唯一性）；
- 把 `my_holdings.yaml` commit 到 git（违反隐私）；
- 在 `event_logs.payload` 中明文存储凭证或个人 token。

## §12 风险与回退

| 触发 | 影响 | 应对 | 重试上限 |
|---|---|---|---|
| Lighthouse Perf < 90 | 启动期目标 fail | 减少 HTMX/Alpine 初始 bundle 大小；图片懒加载；inline 关键 CSS；本机环境差异允许 ⚠️ 标记并 L4 注明 | 2 次 |
| SoT 缺 active 持仓 | UI 空、下游无标的可拉数 | 阻塞；提示用户编辑 `my_holdings.yaml`；**不假数据** | — |
| alembic migration 冲突 | DB schema 不一致 | dev 环境 reset migration；ADR；启动期可绕过用 `init_db()` 直建表 | 2 次 |
| 8080 端口占用 | uvicorn 起不来 | Makefile 内 `lsof -ti:8080 \| xargs -r kill -9` | — |
| `MissingGreenlet` 抛错 | 测试失败 | 装 `greenlet>=3`；写入 pyproject 锁 | 1 次 |
| Excel 解析中文乱码 | 导入失败 | `pd.read_excel(..., dtype=str)`；显式 utf-8 | 2 次 |
| 同问题修复 > 2 次 | 阻塞 | 按 .cursorrules §8.4f 回退：重建 venv / 切回最小依赖集 / DB 重建 | — |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v3 细化融合**：基于 L4 W03 实践记录回填真实事实——4 张表（非 3 组：users/holdings/value_snapshots/event_logs）、增补 `greenlet>=3` 依赖、`UNIQUE(user_pk, symbol)` / `UNIQUE(stream_key, msg_id)` 约束、Excel 中文列名映射、`ensure_default_user` 幂等、symbol 补零、`lsof -ti:8080` 端口释放、L4 全量 48 passed；§3.5 从 13 项扩到 19 项；§7 从 4 行扩到完整实施步骤（7.2.1~7.2.8）；165→~700 行 |
| 2026-05-20 | v2 按 L3 v1.2 重写：删 915 行嵌入 HTML/Python；§3.5 13 项；915→~165 行 |
| 2026-05-16 | 初版 915 行 |
