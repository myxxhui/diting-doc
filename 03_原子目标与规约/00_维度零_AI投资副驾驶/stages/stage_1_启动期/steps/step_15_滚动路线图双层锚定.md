# Step 15 · 滚动路线图双层锚定（M9 · 时间线编排+合理性 / 生命周期判定+长周期巡检）

> **波次定位**：D0 启动期**波次三**第 2 步。把「🗓️滚动路线图」从只读时间轴升级为**双层时间锚定引擎**——放在行情雷达之后，承接雷达候选的预估爆发点。**前置**：step_14（`radar_candidates.catalyst_window` + `regime_assessments` 表）。**架构总纲**：[25_ §1/§6](../../../../_共享规约/25_四区漏斗_三段流水线_架构脊柱_设计.md)。

## §1 一句话定位与本步交付物

**一句话**：实现路线图**两个独立时间维度**——
**维度一（本次作战时间线编排）**：把雷达评估的多标的预估爆发点主动加入某条 Campaign 时间线并排序，系统**评估排布合理性**（建仓时间是否充足、多标的窗口是否冲突、资金/精力是否撞车）；
**维度二（行情生命周期）**：判定标的是**单次行情 / 短期(1~2 月) / 中期(2~3 年多波) / 长期多波(5~8 年)**，对长行情设**长周期巡检**确认假设，本波归档后标的**留在路线图滚动**等下一波。

**交付物**（勾选 = 完成）：
- [ ] **A 维度一编排**：`POST /api/campaigns/{id}/timeline`（从候选 `catalyst_window` 写 `campaign_timeline`，带 `window_start/end`、`build_lead_days`、`sequence_no`）
- [ ] **B 合理性评估引擎（T0 纯规则）**：`modules/roadmap/feasibility.py` → `feasibility_flags`（建仓窗充足/窗口冲突/资金撞车/排序倒挂）+ advisory 建议
- [ ] **C 维度二生命周期判定**：`modules/roadmap/regime.py` → `regime_assessments`（horizon_class + wave_count_est + confirm_state，缺引擎 `inferred`）
- [ ] **D 长周期巡检订阅**：`regime=long/mid_multiwave` → 自动建 `monitor_subscriptions(falsify_type='regime')` 长周期巡检（T1 钉死模型 / 规则）
- [ ] **E 滚动闭环**：本波 Campaign 归档 → 若 `long_multiwave` 保留标的 + `next_wave_window`，路线图持续显示「下一波待规划」
- [ ] **F 前端**：甘特/时间轴视图（现在→年底→明年）+ 合理性 flag 高亮 + 生命周期 chip（单次/短/中/长）+「下一波待规划」入口
- [ ] **G 单测**：≥ 10（编排排序、4 类合理性 flag、生命周期分类、长周期巡检建订阅、滚动归档保留）
- [ ] **H Makefile**：`copilot-step15-prep/migrate/timeline/regime/test/all/status/clean`

> **永久红线**：所有评估/排布建议 advisory；生命周期缺专用引擎 → `inferred` + 显式代理来源，**禁伪造确定性**。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **架构脊柱**：[25_ §1.2 路线图职责 / §6 就绪度（路线图两维）](../../../../_共享规约/25_四区漏斗_三段流水线_架构脊柱_设计.md)
> - **本阶段总览**：[steps/README §一-2 波次三](./README.md)
> - **DNA 键**：[`dna_stage_1_启动期.yaml`](../../../../_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml) `deliverables.modules[M9] / roadmap_dual_anchor`
> - **L4 实践记录**：[实践记录_step_15_滚动路线图双层锚定](../../../../../04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/实践记录_step_15_滚动路线图双层锚定.md)（执行时生成）
> - **上游 step**：← step_14（`radar_candidates.catalyst_window` + `regime_assessments` schema）
> - **下游 step**：→ step_16（生命周期假设 → 证伪任务）/ step_17（执行后归档回滚路线图）
> - **跨维上游**：D2 Timer（爆发期/阶段镜像 tm1~tm7）；D2 thesis `horizon` 字段（生命周期代理）

## §3 数据采集对象 / 落库映射

| 业务对象 | ORM 表/字段 | 来源 | 缺失语义 |
|---|---|---|---|
| 时间线节点 | `campaign_timeline.{anchor_date,window_start,window_end,build_lead_days,sequence_no,feasibility_flags,confirm_state}` | 候选 catalyst_window + 用户排序 | confirm_state: 官方排期=confirmed，AI 预判=inferred |
| 合理性 flag | `campaign_timeline.feasibility_flags(JSON)` | T0 规则引擎 | — |
| 生命周期 | `regime_assessments.{horizon_class,wave_count_est,duration_est,confirm_state,next_wave_window}` | T1/thesis 代理 | 无专用引擎→inferred |
| 长周期巡检 | `monitor_subscriptions.{falsify_type='regime',hypothesis,frequency}` | 由 regime 自动派生 | — |

### §3.1 维度一合理性评估规则（T0 纯规则 · 4 类 flag）

| flag | 规则 | advisory |
|---|---|---|
| `build_window_tight` | 爆发点 − 今天 < `build_lead_days`(默认 15 交易日) | "建仓时间不足，建议提前或减小目标仓位" |
| `window_overlap` | 两标的 `[window_start,window_end]` 重叠 | "X 与 Y 爆发窗重叠，注意资金/精力分配" |
| `capital_collision` | 重叠期目标仓位 Σ > 100% | "重叠期目标仓位合计超 100%，需取舍" |
| `sequence_inversion` | `sequence_no` 与 `anchor_date` 不单调 | "排序与时间倒挂，建议重排" |

> 交易日历用 T0（akshare 交易日 / 工作日近似）；纯算术，免费可全量。

### §3.2 维度二生命周期分类（启动期代理 · 缺引擎 inferred）

| horizon_class | 含义 | 启动期判定来源 | confirm_state |
|---|---|---|---|
| `single` | 单次行情（本次爆发后了结） | 默认 / thesis horizon=short | inferred |
| `short` | 短期 1~2 月 | Timer 主升+无续期催化 | inferred |
| `mid` | 中期 2~3 年多波 | thesis horizon=mid + 行业景气 | inferred |
| `long_multiwave` | 长期 5~8 年多波 | thesis horizon=long + 产业趋势 | inferred → 巡检确认 confirming/confirmed/falsified |

> 启动期**无专用生命周期引擎**：用 D2 thesis `horizon` + Timer 阶段做代理，全标 `inferred`；长周期巡检逐步把 `inferred → confirmed/falsified`。专用引擎 = 扩展期（本步不展开）。

## §3.5 数据质量验收矩阵（M9 · 仅启动期负责）

| # | 分析维度 | 必产字段 | 启动期覆盖 | 降级 |
|---|---|---|---|---|
| R1 | 时间线可排布 | timeline 多节点带 window + sequence | ✅ | — |
| R2 | 建仓窗充足检测 | `build_window_tight` 真实算 | ✅ 交易日历 | 日历缺→工作日近似 |
| R3 | 多标的冲突检测 | `window_overlap`/`capital_collision` | ✅ | — |
| R4 | 生命周期分类 | `horizon_class` + confirm_state | ⚠️ 代理 inferred | 无引擎→thesis/Timer 代理，禁伪造 confirmed |
| R5 | 长周期巡检建立 | long/mid → 自动 regime 订阅 | ✅ 机制 | 巡检判定引擎缺→规则/钉死 T1 |
| R6 | 滚动闭环 | 归档保留 + next_wave_window | ✅ | — |

> **准出**：R1/R2/R3/R5/R6 必绿；R4 允许 inferred 但须显式标代理来源。

## §4 真实数据源与凭证清单

**§4.1**：交易日历 = akshare `tool_trade_date_hist_sina` → 工作日近似降级；生命周期代理 = D2 `thesis_pool.horizon` + Timer。

**§4.2 凭证**
| 凭证 | 用途 | 写在 |
|---|---|---|
| `COPILOT_REDIS_URL` | Timer/thesis 读取 | `.env` |
| `ROADMAP_BUILD_LEAD_DAYS` | 建仓窗默认门槛（默认 15） | `.env`/ConfigMap |
| 无新增密钥 | — | — |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 候选 catalyst_window 入时间线并排序 | POST 201 + 查得 sequence |
| 构造 2 标的窗口重叠 → 返回 `window_overlap` flag + advisory | jq |
| 建仓窗 < 门槛 → `build_window_tight` flag | jq |
| 生命周期判定（含 inferred 标注） | jq horizon_class+confirm_state |
| long_multiwave → 自动建 regime 巡检订阅 | 查 monitor_subscriptions |
| Campaign 归档 → long 标的保留 + next_wave_window | jq |
| 单测 | ≥ 10 passed |

## §6 下一步（一行）

本步 ✅ → **step_16 规划中证伪与持续监控**：生命周期 `inferred` 假设 + 时间线下钻 → 4 类证伪任务。触发：双层锚定产出稳定 + 长周期巡检订阅可建。

## §7 实施规划

### §7.1 实现要点

| 实现要点 | 涉及代码位置 | 关键设计决策 | 验证标准 |
|---|---|---|---|
| A 时间线编排 API | `routers/planning_routes.py`+`modules/planning/service.py` | 从候选 catalyst_window 写 timeline；sequence_no 用户可拖拽（启动期数字字段） | POST + 查序 |
| B 合理性引擎(T0) | `modules/roadmap/feasibility.py` | §3.1 4 类规则；交易日历 T0；纯函数不调 LLM；输出 advisory | R1~R3 单测 |
| C 生命周期(代理) | `modules/roadmap/regime.py` | §3.2 映射 thesis.horizon+Timer；全 inferred；写 `regime_assessments` | R4 单测 |
| D 长周期巡检 | 调 `modules/planning/monitor.py` ensure | regime=long/mid → 建 `falsify_type='regime'` 订阅 + hypothesis | R5 单测 |
| E 滚动闭环 | `service.py` archive | 归档时若 long_multiwave 保留 symbol + 写 next_wave_window；路线图查询含"待规划下一波" | R6 单测 |
| F 前端甘特 | `templates/planning/` roadmap partial | 时间轴 + flag 红黄高亮 + 生命周期 chip + 下一波入口 | curl + 截图 |
| G 单测 | `tests/copilot/test_roadmap.py` | 编排/4flag/分类/巡检/滚动 | `pytest -q` ≥ 10 |

### §7.2 Makefile 合约

| target | 用途 | 入参 | 验证 |
|---|---|---|---|
| `copilot-step15-prep` | 校验 step_14 候选/regime 表 | `COPILOT_REDIS_URL` | 退出码 0 |
| `copilot-step15-migrate` | 扩展 timeline 列 + regime 表 | — | `.schema` 反映 |
| `copilot-step15-timeline` | demo：2 候选入时间线 + 评估合理性 | `ROADMAP_BUILD_LEAD_DAYS` | flag 落库 |
| `copilot-step15-regime` | demo：生命周期判定 + 建巡检 | — | regime + 订阅 |
| `copilot-step15-test` | 单测 | — | ≥ 10 passed |
| `copilot-step15-all` | 端到端 | 合并 | 全退出码 0 |
| `copilot-step15-status` | timeline 数 + flag 分布 + regime 分布 | — | 快照 |
| `copilot-step15-clean` | 删 demo | — | 已删 |

### §7.3 给后续执行模型的指引

1. **维度一全 T0 纯规则**（最快出价值），不调 LLM；交易日历缺则工作日近似并在 L4 注明。
2. **维度二全 inferred**：用 thesis.horizon + Timer 代理，**禁标 confirmed**（confirmed 由 step_16 巡检证据驱动）。
3. **长周期巡检钉死模型控成本**（ModelProfile `patrol.pinned=true`）。
4. **滚动闭环**：归档不删 long 标的，写 `next_wave_window` 让其回流规划区（漏斗 §1.3）。
5. **L4 回写**：2 标的重叠 demo 的 flag JSON、生命周期分类（含 inferred）、巡检订阅、归档保留证据、≥10 pytest。

## §8 部署节奏

| 项 | 本 step |
|---|---|
| 部署面 | 本机 uvicorn + redis |
| Chart | 不改（扩列 + 路由 + ConfigMap lead_days） |
| 必须层级 | 本机开发 |

## §9 准出标准

```bash
cd diting-src
make copilot-step15-migrate
sqlite3 data/copilot.db ".schema campaign_timeline" | grep -E "window_start|build_lead_days|sequence_no|feasibility_flags"
sqlite3 data/copilot.db ".tables" | grep regime_assessments
# 维度一：2 标的入时间线 + 合理性
make copilot-step15-timeline
curl -s "http://127.0.0.1:8080/api/campaigns/1/timeline" | jq '[.[].feasibility_flags]'
# 维度二：生命周期 + 巡检
make copilot-step15-regime
curl -s "http://127.0.0.1:8080/api/campaigns/1/regime" | jq '{horizon_class,confirm_state,next_wave_window}'
curl -s "http://127.0.0.1:8080/api/campaigns/1/monitors" | jq '[.[]|select(.falsify_type=="regime")]|length'
# 单测
pytest tests/copilot/test_roadmap.py -q   # ≥ 10
pytest tests/copilot/ -q
make copilot-step15-all && make copilot-step15-status
```

### §9.1 准出确认
- [ ] §3.5 R1~R6（必绿全绿；R4 inferred 显式）
- [ ] §9 本机跑通
- [ ] L4 `实践记录_step_15_*.md` 回写
- [ ] 通知 step_16 owner：生命周期假设可下钻为证伪任务

## §10 [Deploy]

ConfigMap 增 `ROADMAP_BUILD_LEAD_DAYS`、`ROADMAP_PATROL_FREQ`（长周期巡检频率）。

## §11 依赖与被依赖

- **上游**：step_14 候选 catalyst_window + regime 表；D2 thesis.horizon/Timer（代理）
- **下游**：step_16（生命周期假设 → 证伪）/ step_17（归档回滚）
- **不能 mock**：生命周期 confirmed 必须有巡检证据；启动期一律 inferred

## §12 风险与回退

| 触发 | 应对 | 重试 |
|---|---|---|
| 交易日历源不可达 | 工作日近似 + L4 注明 | — |
| 无生命周期专用引擎 | thesis/Timer 代理 inferred | — |
| 同问题 > 2 次 | §8.4f：先交付维度一（纯规则合理性）最小闭环，维度二迭代 | — |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-30 | 初版（波次三 M9）：滚动路线图双层时间锚定——维度一时间线编排+T0 合理性评估引擎（建仓窗/窗口冲突/资金撞车/排序倒挂 4 flag）+ 维度二行情生命周期分类（single/short/mid/long_multiwave，启动期 thesis/Timer 代理全 inferred）+ 长周期巡检订阅（regime 类型）+ 滚动闭环（归档保留 long 标的 + next_wave_window）；扩展 campaign_timeline 列 + regime_assessments 表；R1~R6 质量矩阵；advisory/no-mock 红线 |
