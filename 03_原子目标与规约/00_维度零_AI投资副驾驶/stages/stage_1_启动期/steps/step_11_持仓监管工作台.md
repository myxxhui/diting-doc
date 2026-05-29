# Step 11 · M5 持仓监管工作台（信息架构升级 · 标的监管驾驶舱卡 · 四维扫描聚合）

> **波次定位**：本步属 D0 启动期**波次二「信息架构升级 · 三大工作台」**（M5/M6/M7），在 M1~M4（step_01~10）已验收的最小闭环之上重构前端信息架构。**前置**：step_03（M1 持仓体检）、step_05（M3 告警）已落地；**不替换**已实现后端，仅在前端聚合 + 重组导航。

## §1 一句话定位与本步交付物

**一句话**：把现有平铺的「持仓管理 / 持仓体检 / 告警历史」三个孤立页面，**重构为一个标的视角的「持仓监管」工作台** —— 顶部 ① 组合总览条（市值/盈亏/健康度分布/待处理告警），下方 ② 每只标的一张**监管驾驶舱卡**，在一张卡内聚合：持仓盈亏（D4）+ **行情阶段**（D2 Timer 潜伏/主升/撤退）+ **四维扫描状态**（D1 极寒防御基本面 / D2 进攻逻辑 / D3 逻辑破坏告警 / D3 物理量探针）+ **操作建议标签**（D4 SP1~SP5 + D2 Timer advice，**全部 advisory · 禁止下单**）。后端未就绪的维度以**灰态占位**（`待接入`），位置先规划好。

**交付物**（勾选 = 完成）：
- [ ] **A**（导航 IA 重构）：`apps/copilot/templates/base.html` 导航由 7 平铺项收敛为 **4+1**：`总览驾驶舱 / 🛡️持仓监管 / 📡行情解析及规划 / 🕸️产业图谱 / ⚙️系统`；`持仓管理`重命名为`持仓监管`；原 `/holdings`（手工 CRUD + Excel 导入）下沉到 `⚙️系统` 作为「未绑定账户兜底入口」
- [ ] **B**（聚合服务 `PortfolioGuardService`）：`apps/copilot/modules/portfolio_guard/service.py`；对每只 SoT `active=true` 标的，**只读聚合**已有数据源（不新建采集）：持仓+行情（D4 `portfolio` / quote）、最新健康度（D3 `health_records`，step_03 已建）、thesis 置信度（D2 `thesis_pool`，step_04 已建）、极寒防御决策（D1）、Timer 阶段（D2）、卖出信号（D4 `sell_signal`）
- [ ] **C**（监管卡数据模型）：聚合为 `GuardCard`（见 §3.3），每维含 `status ∈ {ok, warn, alert, pending}` + `label` + `as_of`；缺上游 → `pending`（灰态），**禁止伪造**
- [ ] **D**（操作建议标签 `advice_tags`）：从 D4 `sell_signal`（SP1~SP5）+ D2 Timer advice 派生，如 `主升持有 / 盈满检查·建议减仓 / 关注止盈窗口 / 逻辑预警·建议复核`；每条带 `execute_mode=advisory`；**禁止**渲染任何下单/一键卖出按钮
- [ ] **E**（路由）：`GET /portfolio-guard`（HTML 工作台）、`GET /api/portfolio-guard`（JSON 组合+卡列表）、`GET /portfolio-guard/{symbol}`（单标的详情：30d 健康曲线复用 step_03 + 四维明细 + 下钻产业图谱入口）
- [ ] **F**（模板）：`templates/guard/{workbench.html, _overview_bar.html, _guard_card.html, detail.html}`；HTMX 30s 轮询 `/api/portfolio-guard`；四维用 ✅🟡🔴⚪(灰) 状态点
- [ ] **G**（监管平台 API 占位）：`PortfolioGuardService.sync_from_broker()` 留 stub + 文案「账户自动同步（扩展期）」；启动期数据源仍为持仓 SoT；**禁止**假装已接入券商/监管平台
- [ ] **H**（兼容跳转）：保留 `/health-dashboard`、`/holdings`、`/alerts` 旧路由 301/链接到新工作台对应锚，避免存量链接断裂
- [ ] **I**（单测）：≥ 12 用例（聚合四维 / pending 降级 / advice 派生 / no-order 审计 / API 结构 / HTML 文案）
- [ ] **J**（Makefile）：`copilot-step11-prep/aggregate/up/test/all/status/clean`

> **永久规则（no-auto-order）**：监管卡与详情页**仅展示与建议**；`advice_tags` 文案可含「建议减仓 / 建议复核」，**禁止**「立即/一键/下单」；通道无下单链接。与 step_03/04/05 同一红线。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[../01_实践目标与策略.md](../01_实践目标与策略.md)、[../04_前端开发与用户体验.md](../04_前端开发与用户体验.md) §2.1 信息架构（4+1 导航）
> - **DNA**：[`_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml`](../../../../_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml) `modules` 中 **M5 持仓监管工作台**
> - **上游数据维度**：D1 极寒防御 `events:cryo_guard:reject/degrade/pass`（[D1 step_08](../../../../01_维度一_极寒防御/stages/stage_1_启动期/steps/step_08_decision_gate聚合与审计.md)）· D2 Timer 三段窗口 `thesis_cards.timer_signal`（[D2 step_05](../../../../02_维度二_纵深进攻/stages/stage_1_启动期/steps/step_05_thesis卡片生成器.md)）· D3 `events:monitor:health_change` + P5/P6/P7（[D3 step_03/07](../../../../03_维度三_持仓监控/stages/stage_1_启动期/steps/step_07_health_change事件流与10持仓测试.md)）· D4 `events:exit:sell_signal` SP1~SP5（[D4 step_07](../../../../04_维度四_卖出决策/stages/stage_1_启动期/steps/step_07_冲突处理与回测.md)）
> - **复用已建**：step_03 `health_records` + 30d 曲线；step_04 `thesis_pool`；step_05 告警；step_02 `holdings` + SoT
> - **共享规约**：[14_六维度启动期统一节奏表](../../../../_共享规约/14_六维度启动期统一节奏表.md) §7 跨维契约 · [23_持仓标的售卖条件监控_需求实现表](../../../../_共享规约/23_持仓标的售卖条件监控_需求实现表.md)（SP1~SP5 → advice_tags 来源）
> - **L4**：[实践记录_step_11_持仓监管工作台](../../../../../04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/实践记录_step_11_持仓监管工作台.md)（执行时生成）
> - **下游 step**：step_12（行情规划，建仓后档案延续进监管卡）、step_13（产业图谱，监管卡下钻入口）

## §3 数据采集对象 / 聚合映射

### §3.1 四维扫描状态的数据来源（只读聚合，本步不新建采集）

| 监管卡区块 | 用户语义（需求原话） | 后端来源（已实现/契约） | 启动期可用 |
|---|---|---|---|
| 持仓盈亏 | 买入成本/当前价/盈亏比例 | D4 `portfolio` + quote（step_02/D4 step_02） | ✅ |
| 行情阶段 | 标的此次行情当前所处阶段 | D2 Timer `timer_signal`（潜伏/主升/撤退 + cycle_anchors） | ⚠️ 部分（601138 等已有 timer，其余 `pending`） |
| 🛡️ 极寒防御（基本面） | 极寒防御基础面定期安全扫描状态 | D1 `decision_gate`（pass/reject/degrade） | ⚠️ D1 三引擎部署后（★M5）；未就绪 → `pending` |
| ⚔️ 进攻逻辑扫描 | 进攻逻辑扫描监控状态 | D2 `thesis_pool` 置信度 / Scorer | ⚠️ 持仓有对应 thesis 时；否则 `pending` |
| ⚠️ 逻辑破坏告警 | 预防进攻逻辑破坏告警扫描状态 | D3 `events:monitor:health_change` → SP3 上游 | ✅（step_03 已落 `health_records`） |
| 📈 物理量探针 | （核心壁垒物理逻辑监控） | D3 P5 招标/P6 海关/P7 产能 + `monitor:{symbol}:dict` | ⚠️ watchlist 已通；持仓按标的 |
| 操作建议标签 | 行情初期加仓 / 盈满检查减仓 | D4 `sell_signal`(SP1~SP5) + D2 Timer advice | ⚠️ 触发时；无触发 → `主升持有/观察` |

### §3.2 聚合落库映射

| 输入 | 落库/缓存 | 说明 |
|---|---|---|
| 各维最新状态 | **不新建持久表**；运行时聚合 | 健康度查 `health_records`；thesis 查 `thesis_pool`；卖出查 D4 stream/`sell_signal` 落库表 |
| D1 decision / D2 timer / D4 sell_signal | 复用各自 consumer 落库表；本步只读 | 若 D0 尚无对应 consumer，新增轻量 consumer 落 `event_logs`（不污染业务表） |
| `advice_tags` 派生 | 内存计算（不持久）；可选审计写 `event_logs` | 来源 `sell_signal` + `timer_signal` |

### §3.3 `GuardCard` 聚合结构（运行时对象，非建表）

```text
GuardCard:
  symbol, name
  position: { shares, cost_price, last_price, pnl_pct, market_value }     # D4
  stage:    { phase: 潜伏|主升|撤退|pending, window_left_days, as_of }     # D2 Timer
  scans:
    cryo:     { status: ok|warn|alert|pending, label, as_of }            # D1 decision_gate
    offense:  { status, confidence, label, as_of }                       # D2 thesis
    breakage: { status, health_score, change_reason, as_of }            # D3 health_change
    physical: { status, hits: {p5,p6,p7}, as_of }                       # D3 P5/P6/P7
  advice_tags: [ { text, source: SP1..SP5|timer, execute_mode: advisory } ]
overview:
  total_market_value, day_pnl, total_pnl_pct
  health_dist: { red, orange, yellow, green }
  pending_alerts
```

> **状态映射约定**：`ok=✅绿` / `warn=🟡` / `alert=🔴` / `pending=⚪灰（待接入）`。任一维上游未就绪一律 `pending`，**禁止**回退为 `ok` 或伪造数值。

## §3.5 数据质量验收矩阵（M5）

### §3.5.1 聚合准确性
| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| A1 | 四维状态来源真实 | 每维 `as_of` 时间戳 + 源标识 | ✅ | 缺源 → `pending` |
| A2 | 盈亏计算 | `pnl_pct = (last-cost)/cost`；缺 quote → `—` | ✅ | quote 缺 → 标 stale |
| A3 | 健康度映射沿用 step_03 | push_level→4 色一致 | ✅ | — |
| A4 | 行情阶段 | timer 缺 → `pending`，不猜 | ✅ | — |
| A5 | 组合总览 | total/盈亏/健康度分布求和正确 | ✅ | — |

### §3.5.2 操作建议（advisory）
| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| B1 | advice 来源可溯 | 每 tag 标 `source`(SP1..SP5/timer) | ✅ |
| B2 | execute_mode=advisory | 所有 tag 强制；无 `buy/qmt/order` 字段 | ✅ |
| B3 | 无触发时默认 tag | `主升持有/观察`（不空白） | ✅ |

### §3.5.3 no-auto-order（永久红线）
| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| E1 | 模板无下单按钮 | `rg "立即\|一键\|下单\|place_order\|submit_order" templates/guard/` = 0 | ✅ |
| E2 | 服务无券商 SDK | `rg "broker\|qmt\|xtquant" modules/portfolio_guard/` = 0 | ✅ |
| E3 | 监管平台 sync 为 stub | `sync_from_broker` 抛 `NotImplementedError` 或返回占位 + 文案 | ✅ |

> 共 **11 项**。逐项验证见 §9。

## §4 凭证清单

| 凭证 / 资源 | 用途 | 启动期 |
|---|---|---|
| `MY_HOLDINGS_YAML` | 聚合范围（active 标的） | 必须 |
| `COPILOT_REDIS_URL` | 读 D1/D2/D4 stream | 必须 |
| `COPILOT_GUARD_REFRESH_SEC`（默认 30） | HTMX 轮询间隔 | 可选 |
| 券商/监管平台 API key | `sync_from_broker`（扩展期） | **启动期不需要**（stub） |

## §5 启动期目标

| 指标 | 门槛 | 测量 |
|---|---|---|
| `/portfolio-guard` HTML 含「持仓监管」+ 组合总览条 | 200 + grep | curl |
| `/api/portfolio-guard` JSON 含 overview + cards[]，每卡四维 | 200 + jq | curl+jq |
| 四维至少 2 维点亮（D3 健康 + D4 盈亏），其余可 `pending` | 真实数据 | jq |
| advice_tags 全部 advisory | 无禁字段 | jq + rg |
| 导航 4+1 渲染；旧路由可跳转 | 200 | curl |
| 单测 | ≥ 12 passed | pytest |
| no-order 审计 | E1/E2/E3 = 0 命中 | rg |

## §6 下一步

本步 ✅ → **step_12 行情解析与规划工作台（M6）**：把推荐池升级为「行情雷达 + 关注清单 + 行情规划(Campaign)」闭环；建仓后标的档案无缝延续回本工作台监管卡。

## §7 实施规划

### §7.1 实现要点
| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| 导航 IA 4+1 | `templates/base.html` | 收敛 7→4+1；持仓管理→持仓监管 | grep 导航项 |
| `PortfolioGuardService` | `modules/portfolio_guard/service.py` | 只读聚合 4 源；缺源 `pending` | 单测 |
| advice 派生器 | 同模块 `advice.py` | `sell_signal`+`timer`→tags；强制 advisory | 单测 B2 |
| 轻量 consumer（按需） | `events/` 复用模式 | D1/D2/D4 stream 若 D0 未消费则补落 `event_logs` | XPENDING |
| 路由 + 模板 | `routers/guard_routes.py` + `templates/guard/` | 3 路由 + 4 模板 | curl + grep |
| 旧路由跳转 | 兼容层 | `/health-dashboard`→`/portfolio-guard` 链接 | curl |
| no-order 审计脚本 | `scripts/assert_no_auto_order.sh` 复用 | grep 红线词 | 0 命中 |

### §7.2 Makefile 合约
| target | 用途 | 验证 |
|---|---|---|
| `copilot-step11-prep` | 起 redis + 校验 step_03/04 表（health_records/thesis_pool）存在 | tables ✅ |
| `copilot-step11-aggregate` | 跑一次聚合打印 JSON | overview+cards ✅ |
| `copilot-step11-up` | 启 uvicorn | `/portfolio-guard` 200 |
| `copilot-step11-test` | pytest ≥ 12 + 全量 | passed ✅ |
| `copilot-step11-all` | prep→aggregate→up→curl→test | 端到端绿 |
| `copilot-step11-status` | 各维 `pending`/已点亮计数 | 表 |
| `copilot-step11-clean` | 停服务（不删 redis） | cleaned ✅ |

### §7.3 给后续执行模型的指引
1. **只聚合不造数**：本步严禁新建采集脚本或伪造任何维度；缺上游 → `pending` 灰态。
2. **顺序**：导航 IA（base.html）→ Service 聚合 → advice 派生 → routes → templates → 旧路由跳转 → 单测 → Makefile。
3. **复用 step_03**：30d 健康曲线与 4 色映射直接调用 `HealthCheckService`，不重写。
4. **L4 回写内容**：`/api/portfolio-guard` 完整 JSON（脱敏）、四维 pending/点亮统计、advice_tags 来源分布、no-order rg 三条 0 命中、≥12 pytest 片段。
5. **永久规则审计**：
   ```bash
   rg -i "立即|一键|下单|place_order|submit_order|qmt|xtquant" apps/copilot/templates/guard/ apps/copilot/modules/portfolio_guard/   # 期望 0
   ```

## §8 部署节奏

| 项 | 本 step |
|---|---|
| 部署面 | 本机 uvicorn + Docker `diting-redis` |
| Chart | 不改（纯前端聚合 + 路由） |
| 上 K3s 时机 | 随 D0 整体；ConfigMap 增 `COPILOT_GUARD_REFRESH_SEC` |

## §9 准出标准

```bash
# 1) 导航 IA
curl -s http://127.0.0.1:8080/ | grep -o "持仓监管"
curl -s http://127.0.0.1:8080/portfolio-guard | grep -o "持仓监管"

# 2) 聚合 API
curl -s http://127.0.0.1:8080/api/portfolio-guard | jq '.overview, (.cards[0].scans | keys)'
# 期望 scans 含 cryo/offense/breakage/physical

# 3) advice 全 advisory（无禁字段）
curl -s http://127.0.0.1:8080/api/portfolio-guard | jq '[.cards[].advice_tags[].execute_mode] | unique'
# 期望 ["advisory"]
curl -s http://127.0.0.1:8080/api/portfolio-guard | grep -iE "qmt|order_id|auto_trade|buy\"" && echo "VIOLATION" || echo "ok"

# 4) no-order 审计
rg -i "立即|一键|下单|place_order|submit_order|qmt|xtquant" apps/copilot/templates/guard/ apps/copilot/modules/portfolio_guard/   # 0

# 5) 单测
pytest tests/copilot/test_portfolio_guard.py -v   # ≥ 12 passed
pytest tests/copilot/ -q                          # 全量回归不退化

# 6) Makefile
make copilot-step11-all && make copilot-step11-status
```

### §9.1 准出确认
- [ ] §3.5 11 项全绿
- [ ] §9 全部命令本机跑通
- [ ] L4 `实践记录_step_11_持仓监管工作台.md` 已回写
- [ ] 通知 step_12 owner：监管卡可作为「建仓后档案延续」目标

## §10 [Deploy]

ConfigMap 增 `COPILOT_GUARD_REFRESH_SEC`；无新镜像依赖。监管平台/券商 API 凭据**启动期不配置**（stub）。

## §11 依赖与禁忌

| 类型 | 依赖 | 就绪 | 缺失处理 |
|---|---|---|---|
| 硬上游 | step_03（health_records）+ step_04（thesis_pool）+ step_02（holdings/SoT） | ✅ | 回前置 |
| 软上游 | D1 decision / D2 timer / D4 sell_signal 真流 | 部分 | 未就绪维 `pending` |

**严禁**：伪造任一扫描维度数值；下单/一键按钮；假装已接入券商/监管平台；advice 出现 `buy/qmt/auto_trade/order_id`。

## §12 风险与回退

| 触发 | 应对 | 重试 |
|---|---|---|
| 多维 pending 看起来"空" | 文案明确「待接入 D? · stage W?」+ 已点亮维优先排版 | — |
| D2 timer 仅个别标的有 | 仅该标的显示阶段，其余 pending；不猜 | — |
| 聚合慢（多源串行） | 并发 gather + 30s 轮询缓存 | — |
| 同问题 > 2 次 | 按 §8.4f 回退：先只点亮 D3+D4 两维上线，其余迭代 | — |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-29 | 初版（波次二 M5）：信息架构 4+1 重构 + 标的监管驾驶舱卡（四维扫描聚合 + Timer 阶段 + advisory 建议标签）；只读聚合已实现后端，缺上游 `pending`；no-auto-order 永久红线 |
