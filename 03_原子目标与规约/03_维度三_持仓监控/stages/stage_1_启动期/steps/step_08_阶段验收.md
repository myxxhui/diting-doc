# Step 08 · 维度三·持仓监控·启动期阶段验收

## §1 一句话定位与本步交付物

**一句话**：用 **`validate_stage_1_holding_watch.sh`** 一键跑齐 **6 大硬性验收**（状态机/探针/健康度/10 持仓准确率/事件延迟/NLI Acc）+ 输出 JSON 报告 + 阶段总结 + L5 锚点 **`l5-stage-d3s1`** 回写 ✅ + 打 tag **v0.1.0**。

**交付物**（勾选 = 完成）：
- [ ] **A**（验收脚本）：`scripts/validate_stage_1_holding_watch.sh` 6 大类全 PASS
- [ ] **B**（JSON 报告）：`reports/dim3_stage_1_acceptance.json`
- [ ] **C**（PDF/Markdown）：`reports/dim3_stage_1_acceptance.pdf` 或 `阶段验收_stage_1_启动期.md`
- [ ] **D**（阶段总结）：`阶段总结_stage_1_启动期.md`（step_01~08 回顾 + 扩展期建议）
- [ ] **E**（L5）：`05_/02_验收标准.md` `l5-stage-d3s1` ✅
- [ ] **F**（git tag）：`state-watch-v0.1.0`
- [ ] **G**（Makefile）：`make watch-step08-all`

> **永久规则**：health_change 事件**不触发**任何自动建仓；验收第 5 项含此断言。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md) §一/§3.2/§4/§5
> - **DNA**：`exit_criteria`、`quantitative_goals`、`l5_stage_anchor=l5-stage-d3s1`
> - **共享**：[14_六维度启动期统一节奏表](../../../../_共享规约/14_六维度启动期统一节奏表.md) D3 step_08
> - **L4**：[实践记录_step_08_阶段验收.md](../../../../../04_阶段规划与实践/03_维度三_持仓监控/stage_1_启动期/实践记录_step_08_阶段验收.md)
> - **L5**：[../../../../../05_成功标识与验证/02_验收标准.md](../../../../../05_成功标识与验证/02_验收标准.md) `l5-stage-d3s1`
> - **上游**：step_01~07 全部 ✅

## §3 数据采集对象 / 落库映射

本步**只读**——验证既有 DB/Redis/产物，**不新增**采集。

## §3.5 数据质量验收矩阵（阶段验收 · 仅启动期）

### §3.5.1 DNA exit_criteria 对齐

| # | DNA exit | 验收检查 # | 启动期 | 降级 |
|---|---|---|---|---|
| X1 | 节点 4 态状态机可运行 | H1 | ✅ | — |
| X2 | health_change 可被 D0 消费 | H5 + schema_check | ⚠️ D0 未起→stream+schema 自检 | BLOCKED 文档 |
| X3 | NLI Accuracy ≥0.85 | H6 | ⚠️ GPU 必需 | 无 GPU→SKIP 标注 |
| X4 | 10 持仓模拟通过 | H4 | ✅ ≥0.90 | <0.90 FAIL |

### §3.5.2 六大硬性验收

| # | 类别 | 阈值 | 验证方法 | 启动期 |
|---|---|---|---|---|
| H1 | 状态机 4 态+6 转移 | 单测 100% | `pytest test_state_machine.py` | ✅ |
| H2 | 4 探针 fetch | 全 active 入库 ≥1 | scheduler --once + 查表 | ✅ |
| H3 | 健康度公式+push_level 边界 | 单测 100% | `pytest test_health_calculator/test_push_level` | ✅ |
| H4 | 10 持仓状态切换准确率 | ≥0.90 | `pytest test_e2e_10_positions` | ⚠️ |
| H5 | health_change 延迟 | P95<30s + schema diff=0 | scripts time.perf_counter + schema_check | ⚠️ |
| H6 | NLI Holdout Accuracy | ≥0.85 | `evaluate_nli.py` | ⚠️ GPU |

### §3.5.3 永久规则与文档

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| R1 | **无 auto-trade** | e2e 后 0 建仓动作 | ✅ assert |
| R2 | **报告留档** | JSON + Markdown/PDF | ✅ |
| R3 | **L5 一致** | l5-stage-d3s1 状态与本步结果一致 | ✅ |
| R4 | **总结含未尽事项** | 列扩展期建议 | ✅ |

### §3.5.4 no-mock

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| N1 | **验收基于真实 DB/Redis** | 不接 stub | ✅ |
| N2 | **GPU 不可用 SKIP H6** | 明示原因；不伪造分数 | ✅ |

> 共 **17 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| step_01~07 ✅ | 硬前置 |
| `REDIS_URL` / `DATABASE_URL` | H2/H5 |
| GPU 或 D5 远程 | H6（缺则 SKIP）|

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 6 大类 | 100% PASS（H6 GPU 不可用 SKIP 允许）|
| L5 锚点 | ✅ |
| 验收耗时 | ≤20min |

## §6 下一步

D3 启动期 ✅ → 按 14_ 节奏进入 **D4 维度四·卖出决策**；扩展期见 `stage_2_扩展期/`。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A validate shell** | `scripts/validate_stage_1_holding_watch.sh` | 6 check 函数；tee 日志 | 退出码 |
| **B json report** | shell 写 JSON | results+notes+timestamp | jq 解析 |
| **C 阶段验收 md** | `04_/03_.../阶段验收_*.md` | 6 类表 + 命令输出摘要 | 人可读 |
| **D 阶段总结 md** | `阶段总结_*.md` | 10 段回顾 + 扩展期 P1~P4 | — |
| **E L5 回写** | `05_/02_验收标准.md` | `l5-stage-d3s1` 行 ✅ | grep |
| **F pdf（可选）** | `scripts/build_acceptance_pdf.py` | WeasyPrint | PDF 可看 |
| **G git tag** | `state-watch-v0.1.0` | `git tag -l` | — |
| **H acceptance test** | `test_stage_acceptance.py` | 测脚本自身 ≥4 | pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `watch-step08-prep` | step_01~07 L4 全勾选 |
| `watch-step08-validate` | shell 6/6（或 5+SKIP H6）|
| `watch-step08-report` | JSON 落 reports/ |
| `watch-step08-docs` | md 两篇生成 |
| `watch-step08-l5` | 检查 L5 行状态（diff）|
| `watch-step08-tag` | 标签存在 |
| `watch-step08-test` | pytest ≥4 |
| `watch-step08-all` | 全流程 |
| `watch-step08-status` | 最近验收摘要 |

### §7.3 指引

先 shell→json→md→L5→tag；H6 无 GPU 明示 SKIP+说明（不伪造）；任一 FAIL 不写 L5 ✅；总结含未尽事项与扩展期建议（4×4 调仓矩阵、议会模式等）。

## §8 部署节奏

仅验证既有 state-watch；无新部署。

## §9 准出标准

- [ ] §3.5 17 项
- [ ] H1~H5 PASS；H6 PASS 或 SKIP（GPU 缺）+ 文档
- [ ] `make watch-step08-all`；L4 回写；L5 ✅；tag 标好

## §10 [Deploy]

无新 workload。

## §11 依赖

step_01~07。

**严禁**：stub 通过验收；手改 L5 无证据。

## §12 风险

| 触发 | 动作 |
|---|---|
| H4<0.90 | 回 step_06/07 调阈值/权重 |
| H5 schema diff>0 | 修后重跑；D0/D4 协同 |
| H6<0.85 | 重训 LoRA 或扩数据；不勾 L5 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 642 行 bash 嵌入；§3.5 17 项；`watch-step08-*`；642→~240 行 |
| 2026-05-16 | 初版 642 行 |
