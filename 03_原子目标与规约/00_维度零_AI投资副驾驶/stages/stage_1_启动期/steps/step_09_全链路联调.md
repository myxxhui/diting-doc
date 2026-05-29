# Step 09 · 全链路联调（5 维度真流 · 5 个 e2e 场景）

## §1 一句话定位与本步交付物

**一句话**：把 **D1/D2/D3/D4/D5** 的真实事件流全部"接通"，跑 **5 个 e2e 场景**（A 启动期全链路演示 / B 持仓体检 / C 推荐池 / D 卖出告警 / E 模型更新热载），在 D0 副驾驶里**全数可视**；本步是 **`step_01` 的联调收紧口**——必须**真 Redis + 全量 Stream + Consumer 同构**，无 fakeredis、无 mock 数据。

**交付物**（勾选 = 完成）：
- [ ] **A**（5 e2e 脚本）：`scripts/e2e_{a..e}.py`；每脚本逐步注入/等待事件 → 验证 D0 UI 反映
- [ ] **B**（消费同构）：5 上游 stream 全部消费者 group 起；XLEN+lag 监控
- [ ] **C**（schema 全对齐）：`scripts/schema_check_all.py` 对每条 stream payload 与 D0 Pydantic 0 diff
- [ ] **D**（性能 SLA）：红色告警 5min ≥99.5%、月报准时 100%、首屏<1s、health 推送<60s 到 UI
- [ ] **E**（演练 BLOCKED 场景）：D5 缺失 → fallback；D2 慢 → 推荐池更新延迟告警
- [ ] **F**（联调报告）：`reports/d0_full_chain_e2e.md`；含 5 场景命令+输出+UI 截图
- [ ] **G**（Makefile）：`make copilot-step09-all`

> **永久规则**：联调用真链路真数据；**禁止**用 stub 通过；缺凭证标 BLOCKED。

<a id="l3-step09-tightening"></a>

### §1.1 联调收紧（对 step_01 的强约束）

step_01 允许 stream not_ready 不视为失败；**本步开始硬要求**：
1. 全部 5 stream 在 Redis 上存在
2. 全部 D0 consumer group 注册
3. payload schema 与 D0 Pydantic 0 diff
4. 关键 e2e 在 30 分钟内完成全链

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md)
> - **DNA**：`exit_criteria`、`quantitative_goals`、`dependencies.upstream`
> - **共享**：[13_六维度启动期集成与时序](../../../../_共享规约/13_六维度启动期集成与时序.md) §三/§四
> - **L4**：[实践记录_step_09_全链路联调.md](../../../../../04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/实践记录_step_09_全链路联调.md)
> - **上游**：step_01~08 + D1/D2/D3/D4/D5 全部 ✅；**下游**：step_10

## §3 数据采集对象 / 落库映射

本步**只读 + 验证**——不新增 D0 业务表。验证既有 D0 链路是否正确反映真实事件。

## §3.5 数据质量验收矩阵（全链路 e2e · 仅启动期）

### §3.5.1 5 e2e 场景

| # | 场景 | 上游 | 验证 D0 | 启动期 | 降级 |
|---|---|---|---|---|---|
| E1 | **A 启动期演示** | 5 维联跑（极寒+推荐+体检+卖出+训练）| 4 卡片+推荐池+告警+月报片段 | ✅ | 任一上游 BLOCKED→ partial |
| E2 | **B 持仓体检** | D3 inject 1 health_change(push_level=2)| 卡片 30s 内变橙 | ✅ | — |
| E3 | **C 推荐池** | D2 真 thesis_proposed | 推荐池新增；5 必填全 | ✅ | — |
| E4 | **D 卖出告警** | D4 真 sell_signal | 红色告警 + 5min 到达 | ✅ | — |
| E5 | **E 模型热载** | D5 lora_updated | D1/D2/D3 服务热载后行为变化（log）| ⚠️ D5 GPU 缺→ partial | — |

### §3.5.2 schema & SLA

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| S1 | **6 stream schema 0 diff** | schema_check_all 全 PASS | ✅ | 漂移修后再 e2e |
| S2 | **红色告警 5min** | E4 测样本 ≥10 | ⚠️ ≥99.5% | <99.5% 走 §12 |
| S3 | **首屏<1s** | Lighthouse on 全数据状态下 | ✅ Perf ≥90 | — |
| S4 | **health 推送 <60s 到 UI** | E2 测样本 ≥5 | ✅ | — |

### §3.5.3 no-mock & 真链路

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| N1 | **真 Redis** | `make all` 不接 fakeredis | ✅ |
| N2 | **真上游事件** | 至少 4/5 来自真服务；缺 1 标 partial | ✅ |
| N3 | **报告含命令+输出** | 全链路证据完整 | ✅ |

> 共 **12 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| D1~D5 各服务可达 | 真链路 |
| step_01~08 全 PASS | 前置 |
| Redis 真实 | stream + consumer |
| 通道（≥2）| E4 告警 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 5 场景全 PASS（或 partial 文档）| ✅ |
| schema 6 stream | 0 diff |
| 红色 SLA、首屏 | 达标 |

## §6 下一步

本步 ✅ → step_10 阶段验收。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A 5 e2e 脚本** | `scripts/e2e_{a..e}.py` | 步骤化打印 PASS/FAIL | 退码 |
| **B schema_check_all** | `scripts/schema_check_all.py` | 对 6 stream payload | 0 diff |
| **C consumer 健康仪表** | `api/routes/m0.py` `/api/consumers/health` | lag + last_handled_at | curl |
| **D SLA 测量** | 复用 step_05 measure；扩展 e2e 模式 | 报告 | md |
| **E 联调报告** | `scripts/gen_e2e_report.py` | 5 场景汇总 | md |
| **F BLOCKED 场景演练** | 各脚本 phase 9 | partial 出报告 | — |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `copilot-step09-prep` | D1~D5 + step_01~08 全 PASS；Redis OK |
| `copilot-step09-schema-all` | 6 stream 0 diff |
| `copilot-step09-e2e-a` | 启动期演示场景 |
| `copilot-step09-e2e-b` | 持仓体检 |
| `copilot-step09-e2e-c` | 推荐池 |
| `copilot-step09-e2e-d` | 卖出告警（含 SLA）|
| `copilot-step09-e2e-e` | 模型热载（GPU 缺→ partial）|
| `copilot-step09-blocked-drill` | 模拟 D5/D2 BLOCKED |
| `copilot-step09-report` | 联调报告 md |
| `copilot-step09-test` | pytest acceptance ≥6 |
| `copilot-step09-all` | 端到端 |
| `copilot-step09-status` | 5 stream XLEN + consumer lag + 报告路径 |

### §7.3 指引

先 schema_check_all→A→B→C→D→E；任一失败先排查 stream / consumer 同构；缺 GPU 等真因 partial 但不假 PASS。

## §8 部署节奏

本机 + Dev K3s（最好集中一套）；扩展期独立 e2e 流水线。

## §9 准出标准

- [ ] §3.5 12 项；5 场景 PASS 或 partial 文档；schema 6/6
- [ ] `make copilot-step09-all`；L4 回写（5 场景命令+输出+指标）
- [ ] 报告 md commit

## §10 [Deploy]

无新 workload；ConfigMap 增 `E2E_REPORT_DIR`。

## §11 依赖

step_01~08；D1/D2/D3/D4/D5；通道；持仓 SoT。

**严禁**：stub 通过 e2e；fakeredis；伪造 schema diff=0；伪造 SLA。

## §12 风险

| 触发 | 动作 |
|---|---|
| 上游缺 | partial + 详写 BLOCKED 原因 |
| SLA 不达 | 优化 sender / consumer；ADR |
| schema 漂移 | 修后回测 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 862 行嵌入 Python；§3.5 12 项；联调收紧口；`copilot-step09-*`；862→~210 行 |
| 2026-05-16 | 初版 862 行 |
