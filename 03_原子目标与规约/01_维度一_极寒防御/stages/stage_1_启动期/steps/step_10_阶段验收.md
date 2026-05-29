# Step 10 · 阶段验收（automation + 验收 PDF + 阶段总结）

## §1 一句话定位与本步交付物

**一句话**：对 step_01~09 全部产出做**一键自动化验收**（按 DNA `exit_criteria` + L3 §7.1 P0），生成验收 PDF + L4 阶段总结 + 回写 L5 看板与 L6 战略追溯矩阵，架构师签字后 D1 启动期正式准出。

**交付物**（勾选 = 完成）：
- [ ] **A**（一键验收脚本）：`scripts/validate_stage_1_cryo_guard.sh` 按 DNA `exit_criteria` 5 条 + L3 §7.1 P0 9 大检查逐项跑通；退出码 0
- [ ] **B**（验收 PDF）：`output/validation/stage_1_cryo_guard_validation_<date>.pdf`（指标表 + 错判明细 + 签字栏；从 step_09 评测 JSON + 审计统计渲染）
- [ ] **C**（L4 阶段总结）：`diting-doc/04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/01_阶段总结_启动期完成情况.md`（10 step 完成度 + DNA exit_criteria + quantitative_goals + 风险记录 + 扩展期门禁 4 条）
- [ ] **D**（L5 看板回写）：`diting-doc/05_成功标识与验证/01_完成情况.md` 中 D1·stage_1 行 ⏳ → ✅，链到阶段总结
- [ ] **E**（L6 追溯矩阵回写）：`diting-doc/06_追溯与审计/02_战略追溯矩阵.md` D1 stage_1 触达状态 ✅
- [ ] **F**（10 份 L4 实践记录齐）：`实践记录_step_01` ~ `实践记录_step_09` 全部"二、实际进展"=已核验准出
- [ ] **G**（架构师签字）：PDF + L4 总结同步签字栏
- [ ] **H**（单测）：`pytest tests/cryo_guard/test_stage_validation.py -v` ≥ 6 passed
- [ ] **I**（Makefile 一键复现）：`make cryo-step10-all` 端到端通过

> **本步是 D1 启动期的最终闸门**：任何 P0 项失败 → 不准出，回退到对应 step。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2 哲学**：[01_维度一_极寒防御 · 04_防御实践策略规划](../../../../../02_战略维度/01_维度一_极寒防御/04_防御实践策略规划.md)
> - **本阶段总览**：[stage_1_启动期/README](../README.md)
> - **L3 验收**：[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md) §七 综合验收清单（P0 必须项 + P1 应完成项 + 签字）
> - **L3 策略**：[../01_实践目标与策略.md](../01_实践目标与策略.md) §1.2 量化目标、§六 成功标准
> - **DNA 键**：`_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml` → `exit_criteria` 5 条、`quantitative_goals` 5 条、`verification_commands`、`l5_stage_anchor`
> - **L5 看板**：[05_成功标识与验证/01_完成情况.md](../../../../../05_成功标识与验证/01_完成情况.md) D1·stage_1 行
> - **L4 实践索引**：[04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/README.md](../../../../../04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/README.md)
> - **L4 实践记录**：[实践记录_step_10_阶段验收.md](../../../../../04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_10_阶段验收.md)
> - **上游 step**：← step_01~09 全部 ✅
> - **下游**：→ `stages/stage_2_扩展期/` 启动门禁（本步 §7.1·G 4 条进阶条件）

## §3 数据采集对象 / 落库映射

**本步不采集数据**——汇总 step_01~09 产出 + 生成验收工件 + 回写 L5/L6。

| 数据流向 | 来源 / 落库 | 用途 |
|---|---|---|
| step_09 评测 JSON | `output/eval_reports/stage_1_holdout_e2e.json` | PDF 指标表 + 验收脚本校验 |
| 3 单引擎 Holdout JSON | `output/eval_reports/{financial_fraud,shareholder,related_party}_holdout_v1.json` | 验收脚本校验 |
| audit_log 统计 | step_08 SQLite | PDF 审计段 + 验收脚本 |
| K8s Pod 状态 | step_07 Dev K3s | 验收脚本 |
| 验收 PDF | `output/validation/stage_1_cryo_guard_validation_<date>.pdf` | 架构师签字 |
| L4 阶段总结 | `diting-doc/04_.../01_阶段总结_启动期完成情况.md` | 人类可读准出证明 |
| L5 看板 | `05_成功标识与验证/01_完成情况.md` | 项目级进度 |
| L6 追溯矩阵 | `06_追溯与审计/02_战略追溯矩阵.md` | 战略追溯 |

## §3.5 数据质量验收矩阵（按 L5/L6 回写需求反推 · 仅启动期负责）

> **本步范围**：自动化验收脚本 + PDF + L4 总结 + L5/L6 回写五个环节。每行 ✅ 或 ⚠️。**不**列扩展期内容。

### §3.5.1 DNA exit_criteria 5 条核验质量

| # | DNA exit_criteria | 验收脚本检查项 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| X1 | **3 LoRA 训练完成 + Holdout 通过** | 3 adapter 文件存在 + 3 holdout JSON `passed=true` | ✅ validate 脚本第 1~3 节 | 任一 false → 脚本退出码 1 |
| X2 | **decision_gate 漏判 = 0** | step_09 JSON `false_negative_count = 0` | ✅ 脚本第 4 节 | 不达回 step_08/09 |
| X3 | **100 白名单误伤 ≤ 5** | step_09 JSON `whitelist_false_positive_reject ≤ 5` | ✅ 脚本第 5 节 | 不达回 step_09 调参 |
| X4 | **audit_log 哈希链 OK** | `validate_chain.py` 退出码 0 | ✅ 脚本第 6 节 | 链断紧急 ADR |
| X5 | **K8s 全 Running** | `kubectl get pods -n diting` 4 Pod Running | ✅ 脚本第 7 节 | 降级 docker compose 时标 ADR |

### §3.5.2 DNA quantitative_goals 5 条实际值质量

| # | quantitative_goal | 阈值 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| Q1 | 综合 Recall | ≥ 0.90 | ⚠️ 从 step_09 JSON 读取 | 不达 ADR |
| Q2 | 综合 Precision | ≥ 0.70 | ⚠️ 同 | 同 |
| Q3 | 综合 F1 | ≥ 0.78 | ⚠️ 同 | 同 |
| Q4 | 漏判 FN | = 0 | ⚠️ 同 | 硬约束 |
| Q5 | 白名单误伤 reject | ≤ 5 | ⚠️ 同 | 同 |

### §3.5.3 L4 阶段总结质量

| # | 维度 | 必产内容 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| S1 | **10 step 完成度表** | 10/10 ✅ + 每 step commit hash + L4 实践记录链接 | ✅ 模板固定 | 任一 ⏳ 不准出 |
| S2 | **5 exit_criteria 逐项** | 每条 ✅/❌ + 证据（命令输出摘要）| ✅ | — |
| S3 | **5 quantitative_goals 实际值** | 实际值 vs 阈值表格 | ✅ | — |
| S4 | **风险与决策记录** | 汇总 step_01~09 L4 "问题与风险" + ADR 链接 | ✅ | — |
| S5 | **扩展期门禁 4 条** | L3 §8.1 4 条进阶条件逐项 ✅/⚠️ | ⚠️ 启动期可能部分 ⚠️（如 Helm Chart 未建）| ⚠️ 项须在总结中写明 + ADR |

### §3.5.4 L5 / L6 回写质量

| # | 维度 | 必产内容 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| L5-1 | **L5 看板行更新** | D1·stage_1 状态 ⏳ → ✅；链接到阶段总结 | ✅ | — |
| L5-2 | **L5 锚点一致** | 行锚点 = DNA `l5_stage_anchor`（如 `l5-stage-stage1_10`）| ✅ | — |
| L6-1 | **战略追溯矩阵行更新** | D1 stage_1 触达 ✅ + 验证日期 | ✅ | — |
| L6-2 | **TRACEBACK 不断链** | 阶段总结含 [TRACEBACK] 上溯 L2 + 下沉 L3 DNA | ✅ | — |

> 共 **16 项启动期质量要求**（X1~X5 / Q1~Q5 / S1~S5 / L5-1~L6-2）。矩阵中**无 ❌**。

### §3.5.5 质量门槛（合并到 §9.2）

矩阵每行须满足之一：
- **✅ 覆盖**：本步已实现且验收脚本 / 人工 review 通过；
- **⚠️ 启动期降级**：明确 ADR + 扩展期补项，不影响本阶段准出（仅 S5 扩展期门禁项可 ⚠️）。

**禁止**：①P0 项失败仍改 L5 为 ✅；②PDF 指标与 step_09 JSON 不一致；③阶段总结编造未跑过的命令输出。

## §4 真实数据源与凭证清单

### §4.1 资源

| 资源 | 来源 | 备注 |
|---|---|---|
| step_01~09 全部产出 | 各 step output / deploy / L4 | 验收输入 |
| step_09 评测 JSON | `stage_1_holdout_e2e.json` | PDF + 脚本 |
| weasyprint | pip install | PDF 渲染 |
| kubectl | step_01 K3s | Pod 检查 |

### §4.2 用户须提供的凭证

| 凭证 | 用途 | 何时需要 | 写在哪里 |
|---|---|---|---|
| `KUBECONFIG` | kubectl 检查 | 验收前 | 默认 |
| 架构师签字 | PDF + L4 总结 | 准出前 | 人工 |

> **本步无新增模型 / 数据凭证**。

## §5 启动期目标

### §5.1 验收脚本 9 大检查

| # | 检查项 | 验证命令 / 条件 | 对应 DNA |
|---|---|---|---|
| 1 | 3 LoRA adapter 存在 | `ls output/*_lora_v1/adapter_model.safetensors` × 3 | exit_criteria[0] |
| 2 | 3 单引擎 Holdout passed | 3 JSON `passed=true` | exit_criteria[0] |
| 3 | decision_gate 健康 | `curl /api/decision-gate/health` 200 ready | — |
| 4 | FN = 0 | step_09 JSON | exit_criteria[1] |
| 5 | 白名单 FP ≤ 5 | step_09 JSON | exit_criteria[2] |
| 6 | 哈希链 OK | `validate_chain.py` 退出码 0 | exit_criteria[3] |
| 7 | K8s 4 Pod Running | `kubectl get pods -n diting` | exit_criteria[4] |
| 8 | 10 L4 实践记录齐 | grep "已核验准出" × 10 | — |
| 9 | Makefile 一键 target 全绿 | `make cryo-step01-status` ~ `cryo-step09-status` 抽样 | — |

### §5.2 阶段总结必含章节

| 章节 | 内容 |
|---|---|
| 一、step 里程碑完成度 | 10/10 表 |
| 二、DNA exit_criteria 5 条 | 逐项 ✅ + 证据 |
| 三、quantitative_goals 5 条 | 实际值 vs 阈值 |
| 四、关键产出 | 3 LoRA + decision_gate + 50 案例报告 |
| 五、风险与决策记录 | ADR 汇总 |
| 六、进阶扩展期 4 条 | L3 §8.1 核验 |
| 七、未完成 / 留扩展期 | 诚实列出 |
| 八、签字 | 架构师 + 日期 |

### §5.3 可接受退化

- weasyprint 装不上 → PDF 降级为 Markdown 版 `stage_1_validation.md`（须在 L4 说明）；
- K8s 临时不可用 → 标 ADR + docker compose 备选证据，扩展期再验 K8s；
- S5 扩展期门禁 4 条可部分 ⚠️（如 Helm Chart 未建），但须在总结诚实列出 + ADR。

## §6 下一步（一行触发条件）

- **触发条件**：本步全部 ✅ + 架构师签字 → D1 启动期正式准出 → 可启动 `stages/stage_2_扩展期/`（须满足 L3 §8.1 4 条进阶条件，⚠️ 项先 ADR）。
- **下一阶段方向**：扩展期多副本 + HPA + ACR + Helm Chart + 1000 白名单 + 夜间回归 CI；详见 `stages/stage_2_扩展期/`。

## §7 实施规划（L3 设计 · 给后续执行模型的工作指引）

> **L3 定位**：本节是**设计规划 + 实现要点 + 验证标准**——**不嵌入完整 bash 验收脚本 / HTML PDF 模板 / L4 总结全文**。具体落地由 L4 实践记录 / 后续执行模型按本节规划自行完成。

### §7.1 实现要点（按交付物拆分）

| 实现要点 | 涉及代码位置 | 关键设计决策 | 验证标准 |
|---|---|---|---|
| **A 一键验收脚本** | `scripts/validate_stage_1_cryo_guard.sh` | 9 大检查顺序执行；每节输出 ✅/❌ + 中文 3 行摘要；任一 ❌ 立即退出码 1；最后汇总 PASS/FAIL | 全绿退出码 0 |
| **B PDF 渲染器** | `scripts/render_validation_pdf.py` + `templates/stage_1_validation.html` | 读 step_09 JSON + 3 holdout JSON + audit 统计 → Jinja2 渲染 HTML → weasyprint 转 PDF；含指标表 + 错判表 + 签字栏 | PDF 文件存在且可打开 |
| **C L4 阶段总结生成器** | `scripts/generate_stage_summary.py` → 输出 `diting-doc/04_.../01_阶段总结_启动期完成情况.md` | 按 §5.2 8 章节模板；自动填 quantitative_goals 实际值（从 JSON）；step 完成度从 git log + L4 实践记录扫描；含 [TRACEBACK] | 8 章节齐全 |
| **D L5 看板回写脚本** | `scripts/update_l5_stage1.py` | 解析 `05_成功标识与验证/01_完成情况.md` D1·stage_1 行；改 ⏳ → ✅；插入阶段总结链接；保持 `l5_stage_anchor` 锚点 | L5 行状态 ✅ |
| **E L6 追溯矩阵回写** | 同脚本或 `scripts/update_l6_trace.py` | 更新 `06_追溯与审计/02_战略追溯矩阵.md` D1 stage_1 行：触达 ✅ + 验证日期 + 证据链接 | 矩阵行 ✅ |
| **F L4 实践记录齐检** | validate 脚本第 8 节 | 扫描 `实践记录_step_01` ~ `09` "二、实际进展"含"已核验准出" | 10/10 |
| **G 扩展期门禁 4 条** | 阶段总结第六节 | L3 §8.1：① Helm Chart 就绪；② ACR 推送链路；③ 多副本 HPA 设计；④ 1000 白名单扩量计划 | 每条 ✅/⚠️ + ADR |
| **H 单测** | `tests/cryo_guard/test_stage_validation.py` | 覆盖：①validate 脚本 mock 全绿/单红；②PDF 渲染 fixture；③L5 回写不破坏其他行；④阶段总结模板 8 章；⑤exit_criteria 映射 | `pytest -v` ≥ 6 passed |

### §7.2 Makefile 一键复现合约（L3 约定 · L4 实现）

**设计目的**：step_09 通过后跑 `make cryo-step10-all` 完成"9 大检查 → PDF → L4 总结 → L5/L6 回写 → 单测"全套。

**target 合约表**：

| target | 用途 | 入参（环境变量 · 均有默认） | 验证标准 |
|---|---|---|---|
| `make cryo-step10-validate` | 跑 `validate_stage_1_cryo_guard.sh` | `KUBECONFIG` | 退出码 0 |
| `make cryo-step10-pdf` | 渲染验收 PDF | `VALIDATION_DATE` | PDF 存在 |
| `make cryo-step10-summary` | 生成 L4 阶段总结 | — | `01_阶段总结_启动期完成情况.md` 8 章齐全 |
| `make cryo-step10-l5-l6` | 回写 L5 + L6 | — | L5 行 ✅ + 矩阵行 ✅ |
| `make cryo-step10-test` | 单测 | — | `pytest -v` ≥ 6 passed |
| `make cryo-step10-all` | **端到端一键** | 同上合并 | 全部退出码 0；≤ 15 min |
| `make cryo-step10-status` | 进度快照（只读） | — | 打印 9 大检查最近一次结果 |
| `make cryo-step10-clean` | 清 PDF（不清总结 / L5） | — | validation/ 清空 |

**合约要求**：
1. **入参环境变量化**；
2. **target 是薄包装**；
3. **可重入幂等**：PDF 按日期命名不覆盖；L5 已是 ✅ 则跳过；
4. **失败显式**：validate 任一 ❌ → 后续 pdf/summary/l5 不执行（依赖链）；
5. **双仓 commit**：diting-src（脚本 + PDF）+ diting-doc（总结 + L5/L6）分两次 commit。

### §7.3 给后续执行模型的指引

L4 / 执行模型按以下顺序：

1. **核对前置**：step_01~09 全部 ✅ + step_09 JSON `passed=true` + 10 L4 实践记录齐；
2. **逐项落地 A~H**：建议顺序 A→B→C→D→E→F→G→H；
3. **集成 Makefile**：按 §7.2 实现 8 个 target；
4. **validate 必须先绿**：PDF / 总结 / L5 都依赖 validate 退出码 0；
5. **架构师 review**：阶段总结 + PDF 人工 review 后签字；
6. **§9 准出 + 双仓 commit**：diting-src + diting-doc；
7. **遇问题**：任一 P0 失败 → 停止，回对应 step，不在本步"带病准出"；同问题 ≥ 2 次失败 § 8.4f 回收 + ADR。

> **L3 责任边界**：本节给规划 + 实现要点 + 验证标准；**不**给完整 bash / HTML / L4 总结全文；具体落地交给 L4 实践记录 / 后续执行模型。

## §8 部署节奏（本步在哪里跑）

| 阶段 | 形态 | 是否本步必须 | 说明 |
|---|---|---|---|
| **本机开发** | `bash scripts/validate_stage_1_cryo_guard.sh` + `pytest` | **必须** | 验收脚本 + 单测 |
| **本机 docker-compose** | — | 否 | — |
| **Dev K3s** | validate 脚本 kubectl 检查 | **必须** | 第 7 大检查 |
| **ACR + 生产 K3s** | 扩展期门禁项 | 否 | S5 可 ⚠️ |

**本步默认运行形态**：本机跑验收脚本 + 远程 kubectl 查 Dev K3s；PDF / 总结落 diting-doc。

## §9 准出标准（同会话可执行清单 · 质量优于数量）

### §9.1 自动化验收
- [ ] `scripts/validate_stage_1_cryo_guard.sh` 退出码 0（9 大检查全 ✅）
- [ ] `make cryo-step10-validate` 退出码 0

### §9.2 数据质量门槛（§3.5 矩阵 16 项）
- [ ] **exit_criteria 5 项（X1~X5）**：脚本全绿
- [ ] **quantitative_goals 5 项（Q1~Q5）**：实际值达阈值（从 step_09 JSON）
- [ ] **阶段总结 5 项（S1~S5）**：8 章齐全 + TRACEBACK + 扩展期门禁诚实标注
- [ ] **L5/L6 4 项（L5-1~L6-2）**：看板 ✅ + 锚点一致 + 矩阵 ✅ + 不断链

### §9.3 工程交付
- [ ] `output/validation/stage_1_cryo_guard_validation_<date>.pdf`（或降级 md）存在
- [ ] `01_阶段总结_启动期完成情况.md` 存在且 8 章齐全
- [ ] `pytest tests/cryo_guard/test_stage_validation.py -v` ≥ 6 passed
- [ ] 10 份 `实践记录_step_01` ~ `09` "二、实际进展"=已核验准出

### §9.4 一键复现 + 签字
- [ ] **Makefile 合约**（§7.2）：8 个 target 已实现且通过；`make cryo-step10-all` ≤ 15 min
- [ ] **架构师签字**：PDF + L4 总结第八节
- [ ] L4 实践记录 `04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_10_阶段验收.md` 已按 §8.4g 更新
- [ ] commit（双仓）：`feat(cryo-guard): step_10 stage_1 validation + 阶段总结 + L5/L6 回写 [Ref: 03_/01_维度一/.../step_10]`
- [ ] **同会话验证**：validate 脚本输出摘要 + L5 行截图/文本证据

## §10 [Deploy] 段

本步**不**新增 K8s workload；仅 kubectl 检查 step_07 已部署的 Pod 状态。

> 扩展期门禁（S5）涉及 Helm Chart + ACR：须在 `stages/stage_2_扩展期/` 完成，本步可标 ⚠️ + ADR。
> deploy-engine 自检约定与前置 step 一致。

## §11 依赖与被依赖

**上游**：
- `step_01~09` 全部 ✅；
- step_09 `stage_1_holdout_e2e.json` `passed=true`；
- 架构师可 review + 签字。

**下游**：
- `stages/stage_2_扩展期/` 启动（须 L3 §8.1 4 条进阶条件）；
- 全项目 L5 看板 D1 维度进度对外可见。

**严禁伪造**（no-mock-policy）：①validate 脚本不得 skip 失败项；②L5 不得在 P0 失败时改 ✅；③PDF 指标不得与 JSON 不一致。

## §12 风险与回退

| 触发条件 | 动作 |
|---|---|
| 任一 P0 检查 ❌ | **停止准出**；阶段总结写明未达项；回退对应 step（见 validate 脚本输出）|
| step_09 JSON `passed=false` | 不准出；回 step_09 调参循环 |
| weasyprint 装不上 | 降级 Markdown PDF 替代 + L4 说明 + 扩展期补 PDF |
| L5 回写破坏其他行 | 回滚 git；用手工 diff 只改 D1·stage_1 行 |
| 扩展期门禁 4 条全 ❌ | 可准出启动期，但**不得**启动扩展期实践直到 4 条全 ✅ 或 ADR |
| 同问题修复重试 ≥ 2 次仍失败 | § 8.4f 回收 + ADR 架构师裁决 |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按新 L3 启动期 step 模板（v1.2）重写**（关键重构，与 `00_系统规则` §4.5 同步）：①删除全部嵌入完整 bash / HTML PDF / L4 总结全文 / 5 份附录（原文 704 行 → 现 ~300 行）；②新增 §3.5 数据质量验收矩阵 16 项（X1~X5 exit_criteria + Q1~Q5 quantitative + S1~S5 总结 + L5/L6 回写）；③§7 改为"实施规划"三段式（§7.1 实现要点 8 项 + §7.2 Makefile 合约 8 个 target + §7.3 给后续执行模型指引）；④把附录 A~E（DNA 索引 / 扩展期预防清单 / 模板字段 / 门禁 checklist / 偏差排查）合并到 §5 / §7.1·G / §12；⑤§9 准出强调 validate 必须先绿 + 双仓 commit + 架构师签字；⑥明确 L3 责任边界 + 禁止带病准出 |
| 2026-05-16 | 初版（含完整 bash + HTML + L4 总结模板 + 5 附录），704 行 |
