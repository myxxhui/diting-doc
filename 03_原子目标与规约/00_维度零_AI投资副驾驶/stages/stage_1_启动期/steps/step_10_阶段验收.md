# Step 10 · 维度零·AI 投资副驾驶·启动期阶段验收

## §1 一句话定位与本步交付物

**一句话**：用 **`validate_stage_1_copilot.sh`** 一键跑齐 **6 大硬性验收**（4 子模块 Pod Running / 首屏 <1s / 红色告警 5min ≥99.5% / 月报 T+1 100% / 用户 12 周活跃可见 / 架构师签字 + no-auto-order assert）；产出 JSON+Markdown 报告 + 阶段总结；L5 锚点 **`l5-stage-d0s1`** 回写 ✅；打 tag **copilot-v0.1.0**。

**交付物**（勾选 = 完成）：
- [ ] **A**（验收脚本）：`scripts/validate_stage_1_copilot.sh` 6 项全 PASS
- [ ] **B**（报告）：`reports/dim0_stage_1_acceptance.json` + `阶段验收_stage_1_启动期.md`
- [ ] **C**（阶段总结）：`阶段总结_stage_1_启动期.md`（step_01~10 回顾 + 扩展期建议）
- [ ] **D**（L5 回写）：`05_/02_验收标准.md` `l5-stage-d0s1` ✅
- [ ] **E**（git tag）：`copilot-v0.1.0`
- [ ] **F**（架构师签字 + 用户活跃证据）：会议纪要 + 12 周用户访问 csv（启动期可 partial）
- [ ] **G**（Makefile）：`make copilot-step10-all`

> **永久规则**：验收必须真链路真数据；**禁止**自动下单代码出现；熔断仅警示。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3 验收**：[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md)
> - **DNA**：`exit_criteria` 6 条 + `quantitative_goals` + `l5_stage_anchor: l5-stage-d0s1`
> - **共享**：[14_六维度启动期统一节奏表](../../../../_共享规约/14_六维度启动期统一节奏表.md) D0 step_10
> - **L4**：[实践记录_step_10_阶段验收.md](../../../../../04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/实践记录_step_10_阶段验收.md)
> - **L5**：[../../../../../05_成功标识与验证/02_验收标准.md](../../../../../05_成功标识与验证/02_验收标准.md) `l5-stage-d0s1`
> - **上游**：step_01~09 全部 ✅

## §3 数据采集对象 / 落库映射

本步**只读**——验证 SQLite/Redis/MinIO/PDF 既有产物 + 12 周用户活跃日志。

## §3.5 数据质量验收矩阵（阶段验收 · 仅启动期）

### §3.5.1 DNA exit_criteria 对齐（6 条）

| # | DNA exit | 验收检查 # | 启动期 | 降级 |
|---|---|---|---|---|
| X1 | 4 子模块 K8s Pod Running | H1 | ✅（本机/K3s 任一可）| — |
| X2 | 首屏 <1s（Lighthouse）| H2 | ⚠️ ≥90 Perf | <90 走 §12 |
| X3 | 红色告警 5min ≥99.5% | H3 | ⚠️ 样本 ≥20 | <99.5% 走 §12 |
| X4 | 月报 T+1 100% | H4 | ⚠️ 启动期至少 1 期 PASS | — |
| X5 | 用户连续 12 周活跃 | H5 | ⚠️ 启动期长度 12w；累计访问日志 | 周次缺记→ partial |
| X6 | 架构师签字 | H6 | ✅ 会议纪要 | 缺签字 FAIL |

### §3.5.2 六大硬性验收

| # | 类别 | 阈值 | 验证 | 启动期 |
|---|---|---|---|---|
| H1 | 4 模块运行 | M1~M4 Pod 或服务 health 200 | `/health` + UI 可达 | ✅ |
| H2 | 首屏 <1s | Lighthouse Perf ≥90 | lhci 报告 | ⚠️ |
| H3 | 红色告警 SLA | ≥99.5%（≥20 样本）| measure 报告 | ⚠️ |
| H4 | 月报 T+1 | 1 期成功 | report_sends 查 | ⚠️ |
| H5 | 12 周活跃 | 12 周访问日志覆盖 | nginx/uvicorn 日志摘要 | ⚠️ |
| H6 | 架构师签字 | 会议纪要 + git tag | docs + tag | ✅ |
| H7 | no-auto-order | grep broker SDK / 下单链接 = 0 | scripts | ✅ |

### §3.5.3 永久规则与文档

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| R1 | **assert_no_auto_order** | 全 D0 路径无下单 | ✅ |
| R2 | **assert_circuit_no_stop** | 熔断仅警示 | ✅ |
| R3 | **报告留档** | JSON + Markdown + PDF（可选）| ✅ |
| R4 | **L5 一致** | l5-stage-d0s1 状态 = 实际 | ✅ |
| R5 | **总结含未尽事项** | 扩展期 P1（反馈闭环 / 券商 API / 电话告警 / 自动驾驶限额）| ✅ |

### §3.5.4 no-mock

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| N1 | **真 Redis + 真上游** | 不接 fakeredis | ✅ |
| N2 | **真用户访问日志** | nginx/uvicorn access log | ✅ |
| N3 | **不伪造 H 项证据** | 命令+输出全留痕 | ✅ |

> 共 **19 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| step_01~09 ✅ | 硬前置 |
| 12 周访问日志 | H5 |
| 架构师签字 | H6 |
| lhci | H2 |
| measure_alert_sla.py | H3 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 6+1 大检查 | 100% PASS（H2/H3/H4/H5 可 partial+ADR）|
| L5 锚点 | `l5-stage-d0s1` ✅ |
| 验收耗时 | 脚本 ≤20min |

## §6 下一步

D0 启动期 ✅ → **六维度全部启动期 ✅**；扩展期见各 `stage_2_扩展期/`。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A validate shell** | `scripts/validate_stage_1_copilot.sh` | 6+1 check；任一 FAIL exit ≠0 | 退码 |
| **B noauto/nocircuit assert** | scripts/ | grep | 0 命中 |
| **C 阶段验收 md** | `04_/00_.../阶段验收_*.md` | 命令+输出+阈值 | 人可读 |
| **D 阶段总结 md** | `阶段总结_*.md` | 10 步回顾 + 扩展期 P1 | — |
| **E L5 回写** | `05_/02_验收标准.md` | `l5-stage-d0s1` ✅ | diff |
| **F git tag** | diting-src | `copilot-v0.1.0` | tag -l |
| **G 用户活跃摘要** | `scripts/user_activity_summary.py` | nginx/access log 周聚合 | csv |
| **H 架构师签字纪要** | `docs/sign_off/d0_stage_1.md` | 会议要点 + 签字日期 | md |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `copilot-step10-prep` | step_01~09 L4 均勾选 |
| `copilot-step10-validate` | shell 6+1 PASS |
| `copilot-step10-lhci` | Perf ≥90 |
| `copilot-step10-sla` | 红色 SLA ≥99.5% |
| `copilot-step10-monthly` | 月报 1 期 PASS |
| `copilot-step10-activity` | 12 周活跃摘要 |
| `copilot-step10-noauto-check` | broker/auto-order grep 0 |
| `copilot-step10-nocircuit-check` | 熔断 stop 路径 grep 0 |
| `copilot-step10-docs` | 两篇 md 更新 |
| `copilot-step10-l5` | L5 行只读 diff |
| `copilot-step10-tag` | tag 存在 |
| `copilot-step10-test` | pytest acceptance ≥6 |
| `copilot-step10-all` | 全流程 |
| `copilot-step10-status` | 上次 validate 摘要 |

### §7.3 指引

先 shell→lhci→sla→monthly→activity→noauto→nocircuit→签字→文档→L5；任一未达 partial 即 partial，不强 PASS；架构师签字后再 tag。

## §8 部署节奏

本机；可选 K3s `kubectl get pods -l app=copilot`；无新部署。

## §9 准出标准

### §9.1 六+一大检查
| # | 项 | 阈值 |
|---|---|---|
| 1 | 4 模块运行 | health 全 ok |
| 2 | 首屏 <1s | Perf ≥90 |
| 3 | 红色 SLA | ≥99.5%（≥20 样本）|
| 4 | 月报 T+1 | ≥1 期 PASS |
| 5 | 12 周活跃 | 12 周日志覆盖 |
| 6 | 架构师签字 | 会议纪要 |
| 7 | no-auto-order + no-circuit-stop | 0 命中 |

### §9.2 文档与 L5
- [ ] §3.5 19 项
- [ ] `make copilot-step10-all`
- [ ] L5 `l5-stage-d0s1` ✅
- [ ] L4 实践记录 + 阶段总结

## §10 [Deploy]

仅验证既有 copilot Deployment；tag 标记镜像版本。

## §11 依赖

step_01~09。**严禁**：stub 验收；伪造 H 项证据；引入自动下单 SDK；熔断停服务。

## §12 风险

| 触发 | 动作 |
|---|---|
| H2~H5 FAIL | 回相应 step 调优；partial + ADR；不勾 L5 |
| H7 FAIL（发现自动下单 / 熔断停服）| 紧急修 + ADR |
| 12 周不到 | 启动期 8w 起算→partial 文档 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 849 行嵌入 bash；6+1 大检查含 assert_no_auto_order + assert_circuit_no_stop；§3.5 19 项；`copilot-step10-*`；849→~230 行 |
| 2026-05-16 | 初版 849 行 |
