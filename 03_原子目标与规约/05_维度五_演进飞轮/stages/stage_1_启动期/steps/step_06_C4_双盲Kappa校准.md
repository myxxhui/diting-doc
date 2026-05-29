# Step 06 · C4 双盲 Kappa 校准（标注质量控制）

## §1 一句话定位与本步交付物

**一句话**：实现 **C4 KappaCalibrator**——对 step_03 双盲样本（≥10%）算 **Cohen's Kappa**；启动期阈值 **≥0.80**；不达标触发"标注培训 + 模板细化 + 重标"循环；定期产出 `kappa_reports`，作为数据准入第二道闸（与 Holdout 共同守门）。

**交付物**（勾选 = 完成）：
- [ ] **A**（`KappaCalibrator`）：按 dim 读 `labelings` 双标行；计算 Cohen's Kappa（含 Fleiss' Kappa 多标场景）
- [ ] **B**（`kappa_reports` 表）：`(dim, period, n_double_labels, kappa, ci_low, ci_high, status)`
- [ ] **C**（培训 trigger）：kappa <0.80 → 状态 `needs_training` + 通知 ADR；当批数据**不**进入 step_04
- [ ] **D**（API）：`POST /api/quality/kappa/calc?dim=&since=`；`GET /api/quality/kappa/history`
- [ ] **E**（培训记录）：`annotator_trainings` 表（标注员、培训日期、培训类型）
- [ ] **F**（数据闸联动）：step_04 训练前校验：当批 verified 数据所在 period 的 kappa ≥0.80 才放行
- [ ] **G**（Makefile）：`make evo-step06-all`

> **永久规则**：kappa<0.80 期数据**不得**进入训练；不容许"先训后修"。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../03_数据采集与预处理.md](../03_数据采集与预处理.md) §四 双盲、[../01_实践目标与策略.md](../01_实践目标与策略.md) C4
> - **DNA**：`components[3] C4`（kappa_threshold ≥0.80）+ `quantitative_goals.Kappa 双盲一致性 ≥0.80`
> - **L4**：[实践记录_step_06_C4_双盲Kappa校准.md](../../../../../04_阶段规划与实践/05_维度五_演进飞轮/stage_1_启动期/实践记录_step_06_C4_双盲Kappa校准.md)
> - **上游**：step_03 双盲样本；**下游**：step_04 训练守门

## §3 数据采集对象 / 落库映射

| 输入 | 输出 |
|---|---|
| `labelings`（双标行）| `kappa_reports` per dim per period |
| 培训记录 | `annotator_trainings` |
| Block 决策 | 当批训练数据 verified→`kappa_blocked` |

## §3.5 数据质量验收矩阵（Kappa 校准 · 仅启动期）

### §3.5.1 双标样本与算法

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| K1 | **双标占比** | ≥10%（step_03 Q4）| ✅ | <10%→增分配 |
| K2 | **Cohen's Kappa 公式** | sklearn `cohen_kappa_score`；含置信区间 | ✅ bootstrap CI | — |
| K3 | **Fleiss' Kappa（多标）** | ≥3 标注员时切换 | ✅ | 启动期 2 人占多 |
| K4 | **per-dim 分别算** | D1/D2/D3 独立 | ✅ | — |
| K5 | **可复现** | 同输入同 seed 同 kappa | ✅ | — |

### §3.5.2 阈值与守门

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| G1 | **阈值 0.80** | DNA；yaml 可调 | ✅ | — |
| G2 | **<0.80 阻断** | 当 period verified 不进 step_04；status=needs_training | ✅ | — |
| G3 | **培训后重测** | 培训记录后 7 天内重测；通过 → unblock | ✅ | 仍<0.80 升级 ADR |
| G4 | **审计** | kappa_reports 全留档；status 历史 | ✅ | — |

### §3.5.3 工程

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **API 触发** | calc on demand + scheduled weekly | ✅ APScheduler | — |
| E2 | **联动 step_04** | training/verify_dataset 调 GET kappa；非通过 fail-fast | ✅ | 短链 hook |
| E3 | **可视化** | kappa 历史曲线（WandB 或简单 chart）| ⚠️ 启动期 csv 即可 | — |
| E4 | **no-mock** | 双标样本来自真实 LS payload；不允许人工编 | ✅ | — |

> 共 **13 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| LS 双标数据已就绪 | step_03 Q4 |
| `WANDB_API_KEY` | 可选可视化 |
| 标注员名册 | annotator_trainings |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 至少 1 dim kappa 算完 | ✅ |
| 阈值 0.80 守门工作 | 模拟 0.7 →阻断生效 |
| 培训记录可写 | ✅ |
| 单测 | ≥8 |

## §6 下一步

本步 ✅ → step_07 灰度发布流程（manual_gate）。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A KappaCalibrator** | `quality/kappa_calibrator.py` | sklearn cohen_kappa + bootstrap CI | 手算+单测 |
| **B `kappa_reports` ORM** | `db/models.py` + alembic | §3 字段 | migration |
| **C `annotator_trainings` ORM** | 同上 | 培训记录 | migration |
| **D API routes** | `api/routes/quality.py` | calc + history | 200 |
| **E scheduler** | APScheduler weekly | per-dim | mock-clock test |
| **F step_04 联动 hook** | `training/scripts/verify_dataset.py` | call kappa API | fail-fast |
| **G 单测** | `test_kappa_calibrator.py`、`test_quality_gate.py` | ≥8 | pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `evo-step06-prep` | LS 双标数据 ≥10% |
| `evo-step06-calc-cryo` | D1 kappa + CI |
| `evo-step06-calc-thrust` | D2 |
| `evo-step06-calc-narrative` | D3 |
| `evo-step06-block-sim` | 模拟 0.7 → step_04 verify_dataset 失败 |
| `evo-step06-train-log` | 写一条 annotator_training（dev）|
| `evo-step06-test` | pytest ≥8 |
| `evo-step06-all` | 端到端 |
| `evo-step06-status` | 各 dim 最近 kappa + status |

### §7.3 指引

先算 kappa→落表→守门 hook→培训记录；严格执行"<0.80 不训练"。

## §8 部署节奏

本机 + 与 super-evo 同进程；scheduler 同进程后台。

## §9 准出标准

- [ ] §3.5 13 项；至少 1 dim kappa 算完 + 守门联动验证
- [ ] `make evo-step06-all`；L4 回写（per-dim kappa、培训记录）

## §10 [Deploy]

ConfigMap 增 `KAPPA_THRESHOLD=0.80`、`KAPPA_SCHEDULE=weekly`。

## §11 依赖

step_03 双标；step_04 verify_dataset 联动。

**严禁**：kappa<0.80 强行训练；编造双标数据。

## §12 风险

| 触发 | 动作 |
|---|---|
| kappa<0.80 频发 | 改模板 + 培训 + 增双标比例 |
| 双标样本不足 | step_03 增分配 |
| 阈值争议 | yaml 调 + ADR |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 902 行嵌入 Python；§3.5 13 项；阈值守门与培训闭环；`evo-step06-*`；902→~200 行 |
| 2026-05-16 | 初版 902 行 |
