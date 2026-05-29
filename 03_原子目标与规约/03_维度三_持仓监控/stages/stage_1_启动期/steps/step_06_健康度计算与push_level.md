# Step 06 · HealthCalculator + push_level 映射 + 状态转移规则

## §1 一句话定位与本步交付物

**一句话**：实现 **HealthCalculator** 纯函数 `health = 0.5·sli + 0.3·narrative + 0.2·freshness ∈ [0,100]` + **push_level** 映射（0-29→3 红 / 30-59→2 橙 / 60-79→1 黄 / 80-100→0 绿）+ **HealthOrchestrator**（查 NodeSLIValue → 调 NLI → 算 health → 评估 T1~T6 → 写 health_records & 触发 transition）+ `POST /api/health/calculate/{node_id}`。

**交付物**（勾选 = 完成）：
- [ ] **A**（`HealthCalculator`）：权重 yaml 可调；freshness 衰减（探针最近更新时长）
- [ ] **B**（`push_level`）：纯函数 + 单测覆盖所有边界
- [ ] **C**（`HealthOrchestrator`）：编排 SLI/NLI/freshness；写 `health_records`；评估 T1~T6 触发 transition（**不**直接 publish 事件，事件流在 step_07）
- [ ] **D**（API）：`POST /api/health/calculate/{node_id}` 返 score+push_level+transition_hint；`GET /api/health/{node_id}/history?limit=20`
- [ ] **E**（单测）：≥15（calculator≥5、push_level≥6 边界、orchestrator≥4）
- [ ] **F**（Makefile）：`make watch-step06-all`

> **本步不发事件**——状态变化只入库；事件流（health_change）在 step_07。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §3.2、[../01_实践目标与策略.md](../01_实践目标与策略.md) §2.2/§2.3
> - **DNA**：`deliverables.health_score`（range+push_level mapping）+ `state_machine.transitions`
> - **L4**：[实践记录_step_06_健康度计算与push_level.md](../../../../../04_阶段规划与实践/03_维度三_持仓监控/stage_1_启动期/实践记录_step_06_健康度计算与push_level.md)
> - **上游**：step_01（transitions）、step_04（sli_aggregator）、step_05（NLI）
> - **下游**：step_07 事件流；step_08 验收

## §3 数据采集对象 / 落库映射

| 输入 | 计算 | 落库 |
|---|---|---|
| 最新 NodeSLIValue + per-probe weights | `sli_score` | — |
| NLI 调用 thesis vs 最新公告 | `narrative_score` ∈[0,100] |（可选 `narrative_scores` 表）|
| 探针最近更新时长 | `freshness_score` | — |
| 三者加权 | `health` + `push_level` | `health_records`（INSERT-only history）|
| T1~T6 评估 | `transition_hint` | 触发 `state_transitions`（step_01 ORM）|

## §3.5 数据质量验收矩阵（健康度计算 · 仅启动期）

### §3.5.1 公式与映射

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| F1 | **权重 0.5/0.3/0.2** | yaml 可调；默认 DNA 取值 | ✅ | — |
| F2 | **sli 来自 step_04 aggregator** | 同口径；不重复实现 | ✅ | sli 缺→health 仅按 narrative+freshness 加权 |
| F3 | **narrative_score 映射** | entailment=100；neutral=60；contradiction=20；degraded→narrative 权重置 0 + 归一 | ✅ | — |
| F4 | **freshness** | 4 探针 max 更新时长；越新越高（指数衰减）| ✅ | 全 stale→freshness=30 |
| F5 | **health 范围** | clip [0,100] | ✅ | — |
| F6 | **push_level 边界** | 0/29/30/59/60/79/80/100 各 1 单测 | ✅ | — |

### §3.5.2 状态转移评估

| # | 规则 | 评估输入 | 启动期 | 降级 |
|---|---|---|---|---|
| T1 | growing→stable | held_days>180 + narrative != contradiction | ✅ | thesis_id 缺→视 entry_date |
| T2 | growing→warning | health<60 | ✅ | — |
| T3 | stable→warning | health<60 或 narrative=contradiction | ✅ | — |
| T4 | stable→exit | narrative_score<30 连续 3 次 | ✅ 用 health_records 滚动 | <3 次不触发 |
| T5 | warning→stable | health>75 且 持续 7d | ✅ | — |
| T6 | warning→exit | health<30 或 thesis 失效 | ✅ | — |

### §3.5.3 工程

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **idempotent** | 同 node 同 minute 不重复算 | ✅ throttle | — |
| E2 | **history 追溯** | `/history?limit=20` 返时间序列 | ✅ | — |
| E3 | **no auto-buy** | health 高不会触发任何建仓事件 | ✅ | 永远 |
| E4 | **stub-free** | 业务路径不接受 stub narrative_score | ✅ | tests fixture 例外 |

> 共 **16 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| step_04 `node_sli_values` 有当日数据 | 必须 |
| step_05 NLI 客户端可调（或 degraded） | 必须 |
| weights yaml | health 权重 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| health 计算可复现 | 单测全过 |
| 6 转移规则全覆盖 | T1~T6 单测各 1 |
| API 端到端 | curl POST 返完整结构 |

## §6 下一步

本步 ✅ → step_07 health_change 事件流 + 10 持仓 e2e。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A weights yaml** | `configs/health_weights.yaml` | 0.5/0.3/0.2 + freshness 衰减 | 解析 |
| **B HealthCalculator** | `health/calculator.py` | 纯函数；输入 sli/narrative/last_updates | 手算 |
| **C push_level** | `health/push_level.py` | DNA 映射；边界单测 | 8 边界 |
| **D Orchestrator** | `health/orchestrator.py` | 查 SLI+NLI+计算+history+评估转移 | e2e 1 节点 |
| **E narrative invalid 滚动计数** | orchestrator | 用 health_records 最近 3 条 | T4 单测 |
| **F transition 写库** | 调 step_01 state_machine.transition | 仅记录；不发事件 | state_transitions+1 |
| **G API routes** | `api/routes/health.py` | POST calculate + GET history | 200 |
| **H 单测** | 3 文件 ≥15 | — | pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `watch-step06-prep` | step_04 NodeSLIValue 有 + step_05 NLI 可达或 degraded |
| `watch-step06-calc-all` | 全 active 算 health；返分布 |
| `watch-step06-transition-check` | T1~T6 单测各 1 正例 |
| `watch-step06-history` | GET history 返 ≥1 行 |
| `watch-step06-test` | pytest ≥15 |
| `watch-step06-all` | calc+transition+history+test |
| `watch-step06-status` | health 分布 + push_level 分布 |
| `watch-step06-clean` | dev only |

### §7.3 指引

权重/阈值进 yaml；narrative degraded 时**不**伪造分数，**改归一**权重；narrative_invalid_count 用历史滚动窗口；transition 写库但不发事件（事件流在 step_07）。

## §8 部署节奏

本机；扩展期合并 watch Deployment。

## §9 准出标准

- [ ] §3.5 16 项；T1~T6 单测全过
- [ ] 全 active 标的当日有 health_records 行
- [ ] `make watch-step06-all`；L4 回写（health/push 分布、转移触发数）

## §10 [Deploy]

启动期单进程；与 step_07 publisher 同包合并部署。

## §11 依赖

step_01/04/05；weights yaml。

**严禁**：自动建仓；伪造 narrative_score 进 health 公式。

## §12 风险

| 触发 | 动作 |
|---|---|
| narrative degraded 持续 | health 仅靠 sli+freshness；明确 ADR |
| sli 全 null | health 不计算，输出 insufficient |
| 频繁 push_level 抖动 | 加迟滞 hysteresis（启动期可不做，记 ADR）|
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 946 行嵌入；§3.5 16 项；T1~T6 评估；`watch-step06-*`；946→~280 行 |
| 2026-05-16 | 初版 946 行 |
