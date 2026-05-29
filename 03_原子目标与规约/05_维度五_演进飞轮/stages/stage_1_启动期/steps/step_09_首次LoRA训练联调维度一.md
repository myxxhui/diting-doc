# Step 09 · 首次 LoRA 训练联调（与维度一·极寒防御）

## §1 一句话定位与本步交付物

**一句话**：用 **D1·极寒防御** 的 3 个 P0 LoRA（财务测谎 / 大股东诚信 / 关联交易）做"首次 LoRA 训练 + 灰度 + 热载"完整链路联调——把 super-evo C1~C4 + step_07/08 串成一条**真实可演示**的 e2e；DNA `quantitative_goals.首次 LoRA 训练成功` 在此勾选。

**交付物**（勾选 = 完成）：
- [ ] **A**（联调脚本）：`scripts/e2e_first_lora_with_dim1.py` 串：distill → label → kappa → train → holdout → manual_gate → deploy → publish → D1 热载
- [ ] **B**（D1 协作）：D1 step_04~07 已就绪；vLLM 加载 candidate；推理结果可比对
- [ ] **C**（数据快照）：联调时刻 DVC tag + lora_versions 记录
- [ ] **D**（验证）：D1 极寒判定 1 暴雷标的（真实）→ reject 概率提升 ≥5%（vs base）
- [ ] **E**（演练**回滚**）：手动触发 step_07 rollback → D1 回 base / prev_prod adapter
- [ ] **F**（联调报告）：`reports/dim5_first_lora_e2e.md`（步骤、命令、指标、回滚演练截图）
- [ ] **G**（Makefile）：`make evo-step09-all`

> **永久规则**：联调用真数据真训练真发布；**禁止**用 stub 跑通"假胜利"。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md) §五 首次 LoRA
> - **DNA**：`quantitative_goals` + `provides_to_downstream`
> - **D1 联调对端**：[01_维度一_极寒防御 step_04~07](../../../01_维度一_极寒防御/stages/stage_1_启动期/steps/README.md)
> - **L4**：[实践记录_step_09_首次LoRA训练联调维度一.md](../../../../../04_阶段规划与实践/05_维度五_演进飞轮/stage_1_启动期/实践记录_step_09_首次LoRA训练联调维度一.md)
> - **上游**：step_02~08；**下游**：step_10 验收

## §3 数据采集对象 / 落库映射

| 流向 | 位置 |
|---|---|
| 蒸馏 D1 样本 | MinIO + DVC（step_02）|
| verified D1 样本 | step_03 |
| kappa D1 | step_06 |
| LoRA 候选 | step_04（≥1 D1 lora）|
| Holdout 评测 | step_05 D1 50 案例 |
| 灰度 + 发布 | step_07 + step_08 |
| D1 推理结果 | D1 服务 audit_log |

## §3.5 数据质量验收矩阵（首次 LoRA e2e · 仅启动期）

### §3.5.1 链路完整性

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| L1 | **distill→verify→kappa→train→holdout→deploy→publish** | 8 步全 PASS | ✅ | 任一 step FAIL → 本步 fail |
| L2 | **D1 热载** | vLLM models 显示 candidate adapter | ✅ | — |
| L3 | **真实 1 暴雷** | 例如康美药业等历史样本 | ⚠️ 真实数据需手工选定 | 找不到→ ADR + 替代标的 |
| L4 | **base/prod 对比** | reject 概率提升 ≥5% | ⚠️ 启动期目标 | 不达→走 §12 |

### §3.5.2 回滚演练

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| R1 | **rollback API 调用** | step_07 rollback；返 prev_prod | ✅ | 失败紧急 ADR |
| R2 | **D1 行为回归** | rollback 后同一标的 reject 概率回到 base 水平 | ✅ | — |
| R3 | **审计完整** | release_rollbacks + lora_versions 状态迁移 | ✅ | — |

### §3.5.3 no-mock

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| N1 | **真 vLLM + 真 Redis** | 全链路无 stub | ✅ | tests/ 例外 |
| N2 | **真实历史样本** | 不允许人造"假暴雷"过 D1 | ✅ | — |
| N3 | **报告含命令+输出** | 不能仅"已验证"无证据 | ✅ | — |

> 共 **10 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| step_01~08 全部 PASS | 前置 |
| D1 step_04~07 PASS | 联调对端 |
| 真实历史暴雷标的 ≥1 | 验证用例 |
| 架构师 token | manual_gate |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| e2e 端到端 PASS | ✅ |
| reject 概率提升 | ≥5%（base vs prod adapter）|
| 回滚演练 | ✅ |

## §6 下一步

本步 ✅ → step_10 D5 阶段验收。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A e2e 脚本** | `scripts/e2e_first_lora_with_dim1.py` | 串 8 步；每步打印 PASS/FAIL | 退码 0 |
| **B 暴雷案例 fixture** | `tests/super_evo/fixtures/dim1_blowup_samples.txt`（**仅 list 不含答案**）| 真实标的代码 | 人审 |
| **C base 对比脚本** | `scripts/compare_base_vs_prod.py` | 调 D1 API 双跑 | 概率差 |
| **D 报告生成** | `scripts/gen_e2e_report.py` | pandoc/markdown | md 输出 |
| **E rollback 演练** | 同 e2e 脚本 phase 9 | 调 step_07 rollback；再跑 1 标的 | base 行为 |
| **F 联调日志收集** | logs + WandB 记录 | — | 完整链 |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `evo-step09-prep` | D1 step_04~07 + 本维 step_01~08 全 PASS |
| `evo-step09-e2e-distill-to-deploy` | 8 步串联跑通 |
| `evo-step09-validate-d1` | 真实暴雷标的 reject 概率提升 ≥5% |
| `evo-step09-rollback-drill` | rollback 后行为回 base |
| `evo-step09-report` | 生成 md 报告 |
| `evo-step09-all` | 端到端联调 |
| `evo-step09-status` | 当前 D1 prod adapter + 联调时间线 |

### §7.3 指引

先 D1 协作确认；e2e 脚本拆 phase 各自可断点重跑；演练**真**回滚不是"模拟"；reject 概率不达 5% 不强 PASS，回查 step_02~04。

## §8 部署节奏

本机 + Dev K3s（D1 + super-evo + vLLM 同集群）。

## §9 准出标准

- [ ] §3.5 10 项；e2e PASS + reject 提升 ≥5% + 回滚演练
- [ ] `make evo-step09-all`；L4 回写（e2e 时间线、概率对比、回滚演练）
- [ ] 报告 md commit

## §10 [Deploy]

无新 workload；env 增 `E2E_REPORT_DIR`。

## §11 依赖

step_01~08；D1 step_04~07；vLLM；真实标的。

**严禁**：stub/mock 通过联调；伪造 reject 概率；用 holdout 训练后又用同案例验证。

## §12 风险

| 触发 | 动作 |
|---|---|
| reject 提升<5% | 回查蒸馏质量 + 重训 + 加 label |
| 回滚失败 | 紧急 ADR + 手工 vLLM 卸载 |
| 暴雷标的找不到 | 选已退市的真实案例 + ADR |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 815 行嵌入 bash/python；§3.5 10 项；真实暴雷强约束；`evo-step09-*`；815→~200 行 |
| 2026-05-16 | 初版 815 行 |
