# Step 12 · M6 行情解析与规划工作台（Campaign 模型 · 图谱+计划双层 · 三支柱监控）

> **波次定位**：D0 启动期**波次二**第 2 步。把现有「推荐池」（step_04）升级为「**发现 → 关注 → 规划 → 跟踪 → 建仓**」完整闭环。**前置**：step_04（M2 推荐池 / `thesis_pool`）、step_11（M5 持仓监管，建仓后档案延续目标）。

## §1 一句话定位与本步交付物

**一句话**：实现 **M6 行情解析与规划** —— 以**滚动演进的"作战计划(Campaign)"**为中心，每个 Campaign 由两部分组成：**Part A 产业知识关系图谱**（认知层，见 step_13）+ **Part B 计划**（行动层：**利好爆发时间线** + **动作链节点** + **三支柱监控**：核心壁垒物理逻辑 / 关键核心利好 / 关键核心风险，各自定时数据收集+监控判断）。计划有状态流转 **`规划中 → 执行中 → 归档`**，时间轴**滚动延展**（现在→年底→明年）。提供 4 视图：**🔭行情雷达 / 📝规划中 / 🚀执行中 / 🗓️滚动路线图**。**所有动作建议 advisory，禁止下单。**

**交付物**（勾选 = 完成）：
- [ ] **A**（数据模型 6 表）：`campaigns / campaign_symbols(标的档案) / campaign_nodes(动作链) / campaign_timeline(利好爆发点) / monitor_subscriptions(三支柱订阅) / watchlist(关注清单)`（见 §3.3）
- [ ] **B**（🔭行情雷达）：消费 D2 The Sniffer 三源 + Scorer 三维评分 → 每日「潜力行情标签」卡（主题 + 政策0.35/产业空间0.35/A股映射0.30 + 关联标的）；操作「➕ 据此新建规划 / ➕ 加入关注」
- [ ] **C**（📝规划中 / 🚀执行中）：Campaign 列表按 `status` 分两视图；执行中 = 含已触发/已执行节点；规划中 = 仅调研/待触发节点
- [ ] **D**（标的调研/监控档案卡 `campaign_symbols`）：6 区块 = ① 产业图谱位置（下钻 step_13）② 当前阶段（D2 Timer）③ 已执行动作（动作链日志）④ 核心壁垒物理逻辑 ⑤ 关键核心利好 ⑥ 关键核心风险
- [ ] **E**（三支柱监控 `monitor_subscriptions`）：每条 = `pillar ∈ {moat, catalyst, risk}` + `indicator` + `source` + `frequency` + `verdict ∈ {ok,warn,alert,pending}`；moat→D3 P5/P6/P7+monitor:dict；catalyst→D2 Sniffer；risk→D1 极寒防御+D3 health
- [ ] **F**（动作链 `campaign_nodes`）：节点 = `触发条件 → 建议动作(advisory) → 状态{规划中,待触发,已触发,已执行,已跳过}`；**只有选定标的的执行点才进动作链**；节点状态驱动 Campaign 状态
- [ ] **G**（🗓️滚动路线图）：跨 Campaign 时间轴/甘特视图（现在→年底→明年）；年底自动追加明年节点（初始 `规划中`）
- [ ] **H**（新建 Campaign 流程）：`POST /campaigns`（命名主题 → 关联标的可多选 → 配置三支柱订阅 → 拉动作链节点 → 存 `规划中`）
- [ ] **I**（关注清单闭环）：watchlist 标的同样跑 D3 体检扫描（复用 step_11 监管卡，标「未持仓·观察中」）；建仓后转入 step_11 监管
- [ ] **J**（推荐池并入）：原 step_04 `thesis_pool` 作为「经人工确认门禁的正式推荐」tab 并入本工作台
- [ ] **K**（单测）：≥ 15（建/查 Campaign、状态流转、三支柱 verdict、动作链 advisory、雷达评分排序、watchlist 体检）
- [ ] **L**（Makefile）：`copilot-step12-prep/migrate/radar/campaign/up/test/all/status/clean`

> **永久规则（no-auto-execute）**：动作链节点动作 = 建议；强制 `execute_mode=advisory` + `human_confirmation_required=true`；schema **禁止** `buy/qmt/auto_trade/order_id/webhook_target/api_endpoint`（与 D4 SP5 翻译契约一致）。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[../04_前端开发与用户体验.md](../04_前端开发与用户体验.md) §2.1 信息架构（📡行情解析及规划）、[../01_实践目标与策略.md](../01_实践目标与策略.md)
> - **DNA**：[`dna_stage_1_启动期.yaml`](../../../../_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml) **M6 行情解析与规划**
> - **上游数据维度**：D2 The Sniffer 三源 + Scorer + Timer（[D2 step_02/05/07](../../../../02_维度二_纵深进攻/stages/stage_1_启动期/steps/step_07_置信度评分器.md) · [D2 07 主动嗅探层](../../../../02_维度二_纵深进攻/07_主动嗅探层_设计.md)）· D3 P5/P6/P7 物理量探针 + `monitor:{symbol}:dict`（[D3 step_03](../../../../03_维度三_持仓监控/stages/stage_1_启动期/steps/step_03_价格与事件探针.md)）· D1 极寒防御（risk 支柱）
> - **复用已建**：step_04 `thesis_pool`（推荐池并入）；step_11 监管卡（关注/建仓延续）
> - **DNA [L-α]**：[Y01 theme_sniffer](../../../../_System_DNA/02_deep_strike/dna_deep_strike_theme_sniffer.yaml)（`sniffer.* / scorer.dimensions.* / timer.tm1~tm7`）· [Y03 physical_probes](../../../../_System_DNA/03_holding_watch/dna_state_watch_physical_probes.yaml)（三支柱 moat 数据源）
> - **共享规约**：[14_ §7 跨维契约](../../../../_共享规约/14_六维度启动期统一节奏表.md) · [20_监控字典规约](../../../../_共享规约/20_监控字典规约.md)（三支柱订阅指标字典）
> - **需求实现主表**：[24_行情解析与规划工作台_需求实现表](../../../../_共享规约/24_行情解析与规划工作台_需求实现表.md)（先 UI 骨架 → 持仓入规划 → 6 维分析：行情/阶段/生态位/壁垒/风险/监控；执行序 ①~④）
> - **L4**：[实践记录_step_12_行情解析与规划工作台](../../../../../04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/实践记录_step_12_行情解析与规划工作台.md)（执行时生成）
> - **下游 step**：step_13（每个 Campaign 的 Part A 图谱）

## §3 数据采集对象 / 落库映射

### §3.1 4 视图数据来源

| 视图 | 用户语义 | 后端来源 | 启动期可用 |
|---|---|---|---|
| 🔭 行情雷达 | 每日扫描潜力行情标签 | D2 Sniffer 三源 + Scorer（`events:thrust:thesis_proposed` 上游 / monitor:dict） | ⚠️ D2 嗅探真流就绪程度；未就绪 → 空雷达「待 D2 推送」 |
| 📝 规划中 | 还在调研、未建仓的计划 | 本地 `campaigns.status='planning'` | ✅（本地实体） |
| 🚀 执行中 | 已落地节点的计划 | `campaigns.status='executing'`（有 `executed` 节点） | ✅ |
| 🗓️ 滚动路线图 | 现在→年底→明年时间轴 | `campaign_timeline` + `campaign_nodes` | ✅ |

### §3.2 三支柱监控的数据源（为建仓做前期数据沉淀）

| 支柱 `pillar` | 用户原话 | 挂在 | 后端源 | 频率 |
|---|---|---|---|---|
| 🧱 `moat` 核心壁垒物理逻辑 | 物理逻辑关键数据定期收集+监控判断 | 环节/标的节点 | D3 P5 招标/P6 海关/P7 产能 + `monitor:{symbol}:dict` | 日/月 |
| 📈 `catalyst` 关键核心利好 | 利好数据定时收集分析监控 | 时间线利好点 | D2 Sniffer 三源（研报/政策/海外） | 定时 |
| ⚠️ `risk` 关键核心风险 | 风险数据收集分析监控 | 标的节点 | D1 极寒防御 + D3 `health_change` | 周期+事件 |

> 每条订阅 = 一个「指标 + 源 + 频率 + 当前判定」。**建仓前就跑监控管线；建仓后该订阅无缝延续到 step_11 监管卡**（同一份 `monitor_subscriptions`，仅 Campaign 关联变持仓关联）。

### §3.3 数据模型（6 表 · SQLite）

| 表 | 关键列 |
|---|---|
| `campaigns` | id, theme(主题), status{planning,executing,archived}, horizon_to(滚动至日期), created_at, updated_at, notes |
| `campaign_symbols`（标的档案） | id, campaign_id FK, symbol(可空·未选定为概念), name, graph_position(产业链位置文本/节点ref), stage(D2 Timer 镜像), is_executing_point(bool), added_at |
| `campaign_nodes`（动作链） | id, campaign_id FK, symbol(执行点), seq, name, trigger_condition, advice_action, **execute_mode='advisory'**, **human_confirmation_required=1**, status{planning,pending,triggered,executed,skipped}, planned_at |
| `campaign_timeline`（利好爆发点） | id, campaign_id FK, anchor_date, title, kind{catalyst,moat_confirm,plan_gen}, confirm_state{confirmed,inferred}, status{expected,realized,missed} |
| `monitor_subscriptions`（三支柱） | id, campaign_id FK, symbol(可空), pillar{moat,catalyst,risk}, indicator, source, frequency, verdict{ok,warn,alert,pending}, last_checked_at, evidence_ref |
| `watchlist`（关注清单） | id, symbol, name, theme, plan_note(行情规划), entry_plan(计划买点/目标仓位), source{radar,manual}, added_at |

> `campaign_timeline.confirm_state` 与 step_13 图谱节点的「确认/推演」两态一致：官方排期(财报日历/政策时间表)=`confirmed`；AI 预判=`inferred`。

## §3.5 数据质量验收矩阵（M6）

### §3.5.1 Campaign 生命周期
| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| C1 | 状态流转 | 节点 0 executed → planning；≥1 executed → executing；全完成/退出 → archived | ✅ |
| C2 | 滚动延展 | `horizon_to` 到期前可追加明年节点（初始 planning） | ✅ |
| C3 | 概念→实体 | `campaign_symbols.symbol` 可空（概念阶段）；选定后填实体 | ✅ |
| C4 | 执行点才进动作链 | 未选定标的的环节不出现在 `campaign_nodes` | ✅ |

### §3.5.2 三支柱监控
| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| M1 | 三支柱齐 | 每档案至少 moat/catalyst/risk 各 1 订阅（可 pending） | ✅ | 源未就绪→`pending` |
| M2 | verdict 真实 | 每条带 `last_checked_at` + `source` | ✅ | — |
| M3 | moat 接物理探针 | 至少 1 条接 P5/P6/P7 真实 hit | ⚠️ | watchlist 已通标的优先 |
| M4 | 不伪造 verdict | 缺源 → pending，禁止默认 ok | ✅ | — |

### §3.5.3 雷达与评分
| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| R1 | Scorer 三维权重 | 政策0.35/产业空间0.35/A股映射0.30（严格对齐 PRD §2.3） | ✅ 透传 D2，不重算 |
| R2 | 按总分排序 | desc | ✅ |
| R3 | D2 未就绪 | 空雷达「待 D2 推送」，不假数据 | ✅ |

### §3.5.4 no-auto-execute（永久红线）
| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| E1 | 动作 advisory | 全节点 `execute_mode='advisory'` + `human_confirmation_required=1` | ✅ |
| E2 | schema 无禁字段 | `rg "buy\|qmt\|auto_trade\|order_id\|webhook_target" modules/planning/` = 0 | ✅ |
| E3 | 模板无下单按钮 | `rg "立即\|一键\|下单" templates/planning/` = 0 | ✅ |

> 共 **14 项**。逐项验证见 §9。

## §4 凭证清单

| 凭证 / 资源 | 用途 | 启动期 |
|---|---|---|
| `COPILOT_REDIS_URL` | 读 D2 Sniffer/Scorer + monitor:dict | 必须 |
| `MY_HOLDINGS_YAML` | watchlist/持仓关联 | 必须 |
| `ANTHROPIC_API_KEY` | （仅 D2 上游需要；D0 不直接调） | — |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| `/planning` HTML 含 4 视图入口（雷达/规划中/执行中/路线图） | 200 + grep |
| 新建 1 个 Campaign（含 ≥1 标的档案 + 三支柱各 1 订阅 + ≥1 动作链节点） | POST 201 + 查得 |
| 三支柱至少 moat 1 条接真实物理探针 hit | jq verdict≠pending |
| 动作链全 advisory，无禁字段 | jq + rg |
| 滚动路线图渲染 ≥1 时间点 | 200 |
| 雷达接 D2 真流或空态「待推送」 | 不假数据 |
| 单测 | ≥ 15 passed |

## §6 下一步

本步 ✅ → **step_13 产业图谱关系链研究（M7）**：为每个 Campaign 落地 Part A 产业知识关系图谱（节点确认/推演两态 + 概念→标的实体演进）。

## §7 实施规划

### §7.1 实现要点
| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| 6 表 ORM + migrate | `db/models.py`（追加） | §3.3 schema | `.tables` 含 6 表 |
| `CampaignService` | `modules/planning/service.py` | 建/查/状态流转/三支柱聚合 | C1~C4 单测 |
| `RadarService` | `modules/planning/radar.py` | 透传 D2 Scorer 排序，不重算 | R1~R3 |
| 动作链 advisory 校验 | Pydantic `NodeSchema` validator | 禁字段 + execute_mode | E1/E2 |
| 三支柱聚合 | `monitor.py` | moat→P5/P6/P7；catalyst→Sniffer；risk→D1/D3 | M1~M4 |
| watchlist 体检复用 | 调 step_11 `PortfolioGuardService` | 标「未持仓·观察中」 | I |
| 路由 + 模板 | `routers/planning_routes.py` + `templates/planning/` | 4 视图 + 档案卡 + 新建表单 | curl |

### §7.2 Makefile 合约
| target | 验证 |
|---|---|
| `copilot-step12-prep` | 起 redis + 校验 step_04 thesis_pool 存在 |
| `copilot-step12-migrate` | 建 6 表 |
| `copilot-step12-radar` | 拉一次雷达（D2 真流或空态） |
| `copilot-step12-campaign` | 脚本建 1 demo Campaign（标的+三支柱+节点） |
| `copilot-step12-up` | uvicorn `/planning` 200 |
| `copilot-step12-test` | pytest ≥ 15 |
| `copilot-step12-all` | 端到端 |
| `copilot-step12-status` | Campaign 数 + status 分布 + 三支柱 verdict 分布 |
| `copilot-step12-clean` | 删 demo Campaign 痕迹 |

### §7.3 给后续执行模型的指引
1. **Campaign = 图谱(step_13) + 计划(本步)**；本步先把 Part B（计划/时间线/动作链/三支柱）落地，图谱节点 ref 字段留给 step_13 填充。
2. **概念先于实体**：新建 Campaign 可不选标的（纯主题调研）；`campaign_symbols.symbol` 允许空。
3. **三支柱即监控订阅**：复用 D3 monitor:dict 读取器（[20_监控字典](../../../../_共享规约/20_监控字典规约.md)）；缺源 → `pending`，禁止默认 ok。
4. **建仓后延续**：标的从 watchlist/campaign 真建仓 → 其 `monitor_subscriptions` 关联切到持仓，step_11 监管卡读同一份。
5. **L4 回写**：1 个 demo Campaign 的 JSON、三支柱 verdict 分布、动作链 advisory rg 0 命中、雷达 JSON（或空态截图）、≥15 pytest。
6. **永久规则审计**：
   ```bash
   rg -i "buy|qmt|auto_trade|order_id|webhook_target|立即|一键|下单" apps/copilot/modules/planning/ apps/copilot/templates/planning/   # 0
   ```

## §8 部署节奏

| 项 | 本 step |
|---|---|
| 部署面 | 本机 uvicorn + redis |
| Chart | 不改（新增表 + 路由） |
| 上 K3s | 随 D0 整体；6 表随 SQLite/PVC |

## §9 准出标准

```bash
# 1) 建表
make copilot-step12-migrate
sqlite3 data/copilot.db ".tables" | grep -E "campaigns|campaign_symbols|campaign_nodes|campaign_timeline|monitor_subscriptions|watchlist"

# 2) 建 demo Campaign
make copilot-step12-campaign
curl -s http://127.0.0.1:8080/api/campaigns | jq '.[0] | {theme,status,symbols:(.symbols|length)}'

# 3) 三支柱
curl -s http://127.0.0.1:8080/api/campaigns/1/monitors | jq 'group_by(.pillar) | map({pillar:.[0].pillar, n:length})'
# 期望含 moat/catalyst/risk

# 4) 动作链全 advisory
curl -s http://127.0.0.1:8080/api/campaigns/1/nodes | jq '[.[].execute_mode]|unique'   # ["advisory"]

# 5) no-auto-execute 审计
rg -i "buy|qmt|auto_trade|order_id|webhook_target|立即|一键|下单" apps/copilot/modules/planning/ apps/copilot/templates/planning/   # 0

# 6) 4 视图 HTML
curl -s http://127.0.0.1:8080/planning | grep -oE "行情雷达|规划中|执行中|路线图"

# 7) 单测
pytest tests/copilot/test_planning.py -v   # ≥ 15 passed
pytest tests/copilot/ -q                   # 全量不退化

# 8) Makefile
make copilot-step12-all && make copilot-step12-status
```

### §9.1 准出确认
- [ ] §3.5 14 项全绿
- [ ] §9 命令本机跑通
- [ ] L4 `实践记录_step_12_行情解析与规划工作台.md` 已回写
- [ ] 通知 step_13 owner：Campaign Part A 图谱可挂接

## §10 [Deploy]

ConfigMap 增 `COPILOT_RADAR_REFRESH_SEC`、`COPILOT_PLANNING_HORIZON_DEFAULT`（默认到当年底）。

## §11 依赖与禁忌

| 类型 | 依赖 | 就绪 | 缺失处理 |
|---|---|---|---|
| 硬上游 | step_04 thesis_pool + step_11 监管卡 | ✅ | 回前置 |
| 软上游 | D2 Sniffer/Scorer 真流（雷达）+ D3 monitor:dict（moat 支柱） | 部分 | 雷达空态 / moat pending |

**严禁**：动作链含下单语义；三支柱伪造 verdict；雷达假数据；放宽 advisory 约束。

## §12 风险与回退

| 触发 | 应对 | 重试 |
|---|---|---|
| D2 嗅探真流未就绪 | 雷达空态「待 D2 推送」；规划/三支柱仍可手工建 | — |
| 三支柱多为 pending | 优先接通 moat（P5/P6/P7 已通的 watchlist 标的） | — |
| Campaign 模型过重 | 启动期先支持单标的 Campaign + 手工三支柱；雷达自动喂养迭代 | — |
| 同问题 > 2 次 | §8.4f：先交付「规划中/执行中 + 三支柱」最小闭环，雷达/路线图迭代 | — |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-29 | 初版（波次二 M6）：Campaign 模型（图谱+计划双层）+ 4 视图（雷达/规划中/执行中/路线图）+ 标的调研档案（6 区块）+ 三支柱监控（moat/catalyst/risk 定时数据收集）+ 滚动时间轴 + advisory 动作链；6 表 schema；no-auto-execute 永久红线 |
