# Step 08 · 维度四·卖出决策·启动期阶段验收

## §1 一句话定位与本步交付物

**一句话**：用 **`validate_stage_1_exit_engine.sh`** 一键跑齐 **6 大硬性验收**（4 协议触发 / sell_signal 可被 D0 消费 / 100 笔回测 ≥0.95 / 冲突逻辑 / 延迟 <30s / 永久规则不自动下单）；产出 JSON + Markdown 报告 + 阶段总结；L5 锚点 **`l5-stage-d4s1`** 回写 ✅；打 tag **exit-engine-v0.1.0**。

**交付物**（勾选 = 完成）：
- [ ] **A**（验收脚本）：`scripts/validate_stage_1_exit_engine.sh` 6 项全 PASS
- [ ] **B**（延迟测量）：`scripts/measure_sell_signal_latency.py` 输出 4 协议端到端 mean+P95
- [ ] **C**（总结脚本）：`scripts/stage_1_summary.py` 汇总审计 + Stream → Markdown
- [ ] **D**（文档）：`阶段验收_stage_1_启动期.md` + `阶段总结_stage_1_启动期.md`
- [ ] **E**（L5）：`05_/02_验收标准.md` `l5-stage-d4s1` ✅
- [ ] **F**（PDF · 可选）：`_artifacts/exit_engine_stage_1_验收.pdf`
- [ ] **G**（git tag）：`exit-engine-v0.1.0`
- [ ] **H**（Makefile）：`make exit-step08-all`

> **永久规则**：第 6 项 `assert_no_auto_order` **必须** PASS；任一违例则整体 FAIL。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3 验收**：[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md) §一/§3/§4
> - **DNA**：`exit_criteria` 4 条 + `quantitative_goals` + `l5_stage_anchor: l5-stage-d4s1` + `output_event`
> - **共享**：[14_六维度启动期统一节奏表](../../../../_共享规约/14_六维度启动期统一节奏表.md) D4 step_08
> - **L4**：[实践记录_step_08_阶段验收.md](../../../../../04_阶段规划与实践/04_维度四_卖出决策/stage_1_启动期/实践记录_step_08_阶段验收.md)
> - **L5**：[../../../../../05_成功标识与验证/02_验收标准.md](../../../../../05_成功标识与验证/02_验收标准.md) `l5-stage-d4s1`
> - **上游**：step_01~07 全部 ✅

## §3 数据采集对象 / 落库映射

本步**只读**——验证既有 DB/Redis/产物；**不新增**采集。

## §3.5 数据质量验收矩阵（阶段验收 · 仅启动期）

### §3.5.1 DNA exit_criteria 对齐（4 条）

| # | DNA exit | 验收检查 # | 启动期 | 降级 |
|---|---|---|---|---|
| X1 | 4 类卖出协议全部可触发 | H1 | ✅ 4 协议各一笔 | — |
| X2 | sell_signal 可被 D0 消费 | H2 | ⚠️ D0 未起→stream+schema 自检 | BLOCKED 文档 |
| X3 | 100 笔回测准确率 ≥0.95 | H3 | ⚠️ 启动期目标 | <0.95 FAIL |
| X4 | 冲突处理逻辑正确 | H4 | ✅ 7 场景 | — |

### §3.5.2 六大硬性验收

| # | 类别 | 阈值 | 验证方法 | 启动期 |
|---|---|---|---|---|
| H1 | 4 协议触发 | 各一笔真实/回测样本触发 | `evaluate_all_holdings.py --protocol all` | ✅ |
| H2 | sell_signal 推送 | XLEN ≥1 + schema diff=0 | XADD 1 笔；schema_check | ⚠️ |
| H3 | 100 笔回测 | 准确率 ≥0.95 | `backtest_100_history.py` 报告 | ⚠️ |
| H4 | 冲突处理 7 场景 | 单测 100% | `pytest test_conflict_resolver.py` | ✅ |
| H5 | sell_signal 延迟 | P95 <30s | `measure_sell_signal_latency.py` | ✅ |
| H6 | 永久规则 | `assert_no_auto_order` 退出码 0 | grep + 路径扫描 | ✅ |

### §3.5.3 永久规则与文档

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| R1 | **assert_no_auto_order** | publisher/orchestrator 路径无下单调用 | ✅ |
| R2 | **报告留档** | JSON + Markdown（PDF 可选）| ✅ |
| R3 | **L5 一致** | l5-stage-d4s1 状态与本步结果一致 | ✅ |
| R4 | **总结含未尽事项** | 扩展期建议（缓冲复杂策略 / 卖飞豁免）| ✅ |

### §3.5.4 no-mock

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| N1 | **真 Redis 验收** | 不接 fakeredis | ✅ |
| N2 | **真协议执行** | 不接 stub orchestrator | ✅ |
| N3 | **回测 fixture 仅 tests/** | csv 不入业务库 | ✅ |

> 共 **17 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| step_01~07 ✅ | 硬前置 |
| `REDIS_URL` / `DATABASE_URL` | H1~H5 |
| D0 可未起 | H2 走自检 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 6 大检查 | 100% PASS（H2 可 BLOCKED 文档）|
| L5 锚点 | l5-stage-d4s1 ✅ |
| 验收耗时 | 脚本 ≤15min |

## §6 下一步

D4 启动期 ✅ → **D5 维度五·演进飞轮** 或按 14_ 节奏表下一维。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A validate shell** | `scripts/validate_stage_1_exit_engine.sh` | 6 check；任意 FAIL 退码 ≠0 | 退码 0 |
| **B 延迟测量** | `scripts/measure_sell_signal_latency.py` | time.perf_counter 4 协议 | mean+P95 报告 |
| **C 总结脚本** | `scripts/stage_1_summary.py` | 读审计 + Stream | Markdown |
| **D 阶段验收 md** | `04_/04_.../阶段验收_*.md` | 阈值对比表 + 命令输出 | 人可读 |
| **E 阶段总结 md** | `阶段总结_*.md` | step_01~08 回顾 + 扩展期 P1 | — |
| **F L5 回写** | `05_/02_验收标准.md` | `l5-stage-d4s1` ✅ | 检查 |
| **G git tag** | diting-src | `exit-engine-v0.1.0` | `git tag -l` |
| **H assert_no_auto_order** | scripts/ | grep 下单 API/SDK 调用 | 0 命中 |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `exit-step08-prep` | step_01~07 L4 均勾选 |
| `exit-step08-validate` | shell 6/6 PASS |
| `exit-step08-latency` | P95 < 30s |
| `exit-step08-backtest-replay` | 重跑 100 笔，准确率 ≥0.95 |
| `exit-step08-noauto-check` | assert_no_auto_order 退码 0 |
| `exit-step08-docs` | 两篇 md 生成/更新 |
| `exit-step08-l5` | 检查 L5 行（只读 diff）|
| `exit-step08-tag` | tag 存在（可选 push 由人）|
| `exit-step08-test` | pytest acceptance ≥6 |
| `exit-step08-all` | 全流程 |
| `exit-step08-status` | 上次 validate 摘要 + XLEN 主 stream |

### §7.3 指引

先 shell→延迟→回测重跑→noauto check→文档→L5；**禁止** stub/mock 通过；任一 FAIL 不写 ✅ 到 L5。

## §8 部署节奏

验收在本机；可选 K3s `kubectl get pods -l app=exit-engine`；无新部署。

## §9 准出标准

### §9.1 六大检查（与 DNA 对齐）

| # | 项 | 阈值 |
|---|---|---|
| 1 | 4 协议触发 | 各 1 笔 |
| 2 | sell_signal stream | XLEN ≥1 + schema diff=0（或 BLOCKED）|
| 3 | 100 笔回测 | ≥0.95 |
| 4 | 冲突 7 场景 | 100% pass |
| 5 | 延迟 P95 | <30s |
| 6 | assert_no_auto_order | 0 命中 |

### §9.2 文档与 L5
- [ ] §3.5 17 项
- [ ] `make exit-step08-all`
- [ ] L5 `l5-stage-d4s1` ✅
- [ ] L4 实践记录 + 阶段总结更新

## §10 [Deploy]

仅验证既有 exit-engine Deployment；tag 标记镜像版本。

## §11 依赖

step_01~07。**严禁**：stub 模式跑验收；手改 L5 无证据；引入自动下单 SDK。

## §12 风险

| 触发 | 动作 |
|---|---|
| H3 准确率 FAIL | 回 step_07 调阈值；不勾 L5 |
| H6 FAIL（自动下单代码引入）| 紧急回滚；ADR |
| D0 未起 | H2 BLOCKED + stream 自检 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 644 行嵌入 bash；6 大检查（含 assert_no_auto_order）；§3.5 17 项；Makefile；644→~290 行 |
| 2026-05-16 | 初版 644 行 |
