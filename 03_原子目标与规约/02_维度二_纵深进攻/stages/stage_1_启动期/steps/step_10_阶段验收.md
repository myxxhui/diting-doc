# Step 10 · 维度二·纵深进攻·启动期阶段验收

## §1 一句话定位与本步交付物

**一句话**：用 **`validate_stage_1_deep_strike.sh`** + `stage_validate.py --report` 一键跑齐 **8 大检查**（服务/DB/剧本/5必填/置信度/一致率≥80%/e2e推送/永久规则），产出阶段验收报告与总结，回写 L5 锚点 **`l5-stage-d2s1`**，打 tag **v0.1.0**。

**交付物**（勾选 = 完成）：
- [ ] **A**（验收脚本）：`scripts/validate_stage_1_deep_strike.sh` 8 项全 PASS
- [ ] **B**（CLI 报告）：`apps/deep_strike/cli/stage_validate.py --report` JSON
- [ ] **C**（文档）：`阶段验收_stage_1_启动期.md` + `阶段总结_stage_1_启动期.md`
- [ ] **D**（L5）：`05_成功标识与验证/02_验收标准.md` 中 `l5-stage-d2s1` → ✅
- [ ] **E**（git tag）：`deep-strike-v0.1.0`（diting-src）
- [ ] **F**（Makefile）：`make deep-step10-all`

> **永久规则**：第 8 项 `assert_no_bypass` **必须** PASS，否则整体验收 FAIL。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3 验收**：[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md) §一、§4.1 P0
> - **DNA**：`exit_criteria` 5 条 + `quantitative_goals` + `l5_stage_anchor: l5-stage-d2s1`
> - **共享**：[14_六维度启动期统一节奏表](../../../../_共享规约/14_六维度启动期统一节奏表.md) D2 step_10
> - **L4**：[实践记录_step_10_阶段验收.md](../../../../../04_阶段规划与实践/02_维度二_纵深进攻/stage_1_启动期/实践记录_step_10_阶段验收.md)
> - **上游**：step_01~09 全部 ✅

## §3 数据采集对象 / 落库映射

本步**不新增采集**——只读验证 step_01~09 产出（DB 表、stream、API、报告 JSON）。

## §3.5 数据质量验收矩阵（阶段验收 · 仅启动期）

### §3.5.1 DNA exit_criteria 对齐（5 条）

| # | DNA exit | 验收检查 # | 启动期 | 降级 |
|---|---|---|---|---|
| X1 | 利润截留扫描仪可运行 | #3 | ✅ propose/watch/discard | — |
| X2 | thesis 5 必填 100% | #4 | ✅ batch completeness | <100% FAIL |
| X3 | 一致率 ≥80% | #6 | ⚠️ ≥10 样本 | insufficient→FAIL 或补种子 |
| X4 | thesis_proposed 可被 D0 消费 | #7 | ⚠️ D0 未起则 stream+schema | BLOCKED 须文档 |
| X5 | 周输出 ≤5 | 报告统计 | ✅ 计数 | 超标 WARN |

### §3.5.2 八大检查质量

| # | 检查 | 必证据 | 启动期 |
|---|---|---|---|
| V1 | 服务 /health | curl 200 + body ok | ✅ |
| V2 | 9 表存在 | SQLite `.tables` 或 information_schema | ✅ |
| V3 | 剧本 CLI/API | 1 symbol 全三档 | ✅ |
| V4 | 5 必填 | evaluate_completeness 100% | ✅ |
| V5 | 三路置信度 | GET confidence 含三路 | ✅ |
| V6 | 一致率 | GET consistency overall≥0.8 | ⚠️ |
| V7 | e2e push | XLEN thrust≥1 + schema=0 | ⚠️ |
| V8 | 永久规则 | assert_no_bypass=0 | ✅ |

### §3.5.3 验收报告质量

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| D1 | 命令输出粘贴 | 每检查 PASS/FAIL + 原始输出摘要 | ✅ |
| D2 | 未达标项改进计划 | FAIL 必有 owner+下一步 | ✅ |
| D3 | step_01~10 回顾 | 阶段总结 1 页/步要点 | ✅ |

### §3.5.4 no-mock-policy

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| N1 | 验收脚本**禁止**默认 stub | 不得 `THESIS_GENERATOR_MODE=stub` | ✅ |
| N2 | 8 项基于真实 DB/Redis | 非纯 mock 断言 | ✅ |

> 共 **15 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| step_01~09 已全部准出 | 硬前置 |
| `REDIS_URL` / `DATABASE_URL` | 检查 7、2 |
| 可选 D0 copilot 运行 | 检查 7 完整消费 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 8 大检查 | 100% PASS（或 BLOCKED 已文档且非 P0 项）|
| L5 锚点 | l5-stage-d2s1 ✅ |
| 验收耗时 | 脚本 ≤15min |

## §6 下一步

D2 启动期 ✅ → **D3 维度三·持仓监控**（或按 14_ 节奏表下一维）；扩展期见 `stage_2_扩展期/`。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A validate shell** | `scripts/validate_stage_1_deep_strike.sh` | 8 check 函数；tee 报告 | 退出码 0 |
| **B stage_validate.py** | `cli/stage_validate.py` | `--report` JSON 与 shell 同口径 | diff 一致 |
| **C test_stage_acceptance** | `test_stage_acceptance.py` | ≥6 测脚本自身 | pytest |
| **D 阶段验收 md** | `04_/02_.../阶段验收_*.md` | 阈值对比表 | 人可读 |
| **E 阶段总结 md** | `阶段总结_*.md` | 10 步回顾+P1 剧本 | — |
| **F L5 回写** | `05_/02_验收标准.md` | l5-stage-d2s1 行 | ✅ |
| **G git tag** | diting-src | deep-strike-v0.1.0 | git tag -l |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `deep-step10-prep` | step_01~09 L4 均勾选 |
| `deep-step10-validate` | shell 8/8 PASS |
| `deep-step10-report` | JSON 报告落 reports/ |
| `deep-step10-docs` | 两篇 md 生成/更新 |
| `deep-step10-l5` | 检查 L5 行状态（只读 diff）|
| `deep-step10-tag` | tag 存在（可选 push 由人）|
| `deep-step10-test` | pytest acceptance ≥6 |
| `deep-step10-all` | 全流程 |
| `deep-step10-status` | 上次 validate 摘要 |

### §7.3 指引

先 shell→py 报告→文档→L5；**禁止** stub 通过验收；任一 FAIL 不写 ✅ 到 L5。

## §8 部署节奏

验收在本机 + 可选 Dev K3s（`kubectl get pods -l app=deep-strike`）；无新部署。

## §9 准出标准

### §9.1 八大检查（与 DNA 对齐）

| # | 项 | 阈值 |
|---|---|---|
| 1 | /health | ok |
| 2 | DB 9 表 | 全在 |
| 3 | 利润截留 | 三档可跑 |
| 4 | 5 必填 | 100% |
| 5 | 三路置信度 | 有输出 |
| 6 | 一致率 | ≥80% |
| 7 | e2e+stream+schema | PASS 或 BLOCKED 文档 |
| 8 | assert_no_bypass | 0 违例 |

### §9.2 文档与 L5
- [ ] §3.5 15 项
- [ ] `make deep-step10-all`
- [ ] L5 `l5-stage-d2s1` ✅
- [ ] L4 实践记录更新

## §10 [Deploy]

仅验证既有 deep-strike Deployment；tag 标记镜像版本（可选 CI）。

## §11 依赖

step_01~09。**严禁**：stub 模式跑验收；手改 L5 无证据。

## §12 风险

| 触发 | 动作 |
|---|---|
| 检查 6/7 FAIL | 回 step_08/09 修；不勾 L5 |
| 检查 8 FAIL | 紧急修 HumanGate |
| D0 未起 | 检查 7 BLOCKED+stream 自检 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 824 行 bash 嵌入；移除 `THESIS_GENERATOR_MODE=stub` 默认；§3.5 15 项；Makefile；824→~300 行 |
| 2026-05-16 | 初版含完整 bash 与 stub 默认 |
