# Step 10 · 维度五·演进飞轮·启动期阶段验收

## §1 一句话定位与本步交付物

**一句话**：用 **`validate_stage_1_super_evo.sh`** 一键跑齐 **6 大硬性验收**（4 P0 组件可运行 / 首次 LoRA 训练成功 / Kappa ≥0.80 / lora_updated 事件可发布 / Holdout CI Block 工作 / manual_gate 不可绕过）；产出 JSON+Markdown 报告 + 阶段总结；L5 锚点 **`l5-stage-d5s1`** 回写 ✅；打 tag **super-evo-v0.1.0**。

**交付物**（勾选 = 完成）：
- [ ] **A**（验收脚本）：`scripts/validate_stage_1_super_evo.sh` 6 项全 PASS
- [ ] **B**（报告）：`reports/dim5_stage_1_acceptance.json` + `阶段验收_stage_1_启动期.md`
- [ ] **C**（阶段总结）：`阶段总结_stage_1_启动期.md`（step_01~10 回顾 + 扩展期建议）
- [ ] **D**（L5 回写）：`05_/02_验收标准.md` `l5-stage-d5s1` ✅
- [ ] **E**（git tag）：`super-evo-v0.1.0`
- [ ] **F**（Makefile）：`make evo-step10-all`

> **永久规则**：验收必须基于真实蒸馏/标注/训练/发布；**禁止**用 stub 通过。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3 验收**：[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md)
> - **DNA**：`exit_criteria` 4 条 + `quantitative_goals` + `l5_stage_anchor: l5-stage-d5s1`
> - **共享**：[14_六维度启动期统一节奏表](../../../../_共享规约/14_六维度启动期统一节奏表.md) D5 step_10
> - **L4**：[实践记录_step_10_阶段验收.md](../../../../../04_阶段规划与实践/05_维度五_演进飞轮/stage_1_启动期/实践记录_step_10_阶段验收.md)
> - **L5**：[../../../../../05_成功标识与验证/02_验收标准.md](../../../../../05_成功标识与验证/02_验收标准.md) `l5-stage-d5s1`
> - **上游**：step_01~09 全部 ✅

## §3 数据采集对象 / 落库映射

本步**只读**——验证 MinIO/DVC/WandB/SQLite/Redis 既有产物。

## §3.5 数据质量验收矩阵（阶段验收 · 仅启动期）

### §3.5.1 DNA exit_criteria 对齐

| # | DNA exit | 验收检查 # | 启动期 | 降级 |
|---|---|---|---|---|
| X1 | 4 P0 组件可运行 | H1 | ✅ | — |
| X2 | 首次 LoRA 训练成功 | H2 | ✅ step_09 已勾 | — |
| X3 | 双盲 Kappa ≥0.80 | H3 | ⚠️ 至少 1 维 | <0.80 FAIL |
| X4 | lora_updated 事件可发布 | H4 | ✅ XLEN≥1 | — |

### §3.5.2 六大硬性验收

| # | 类别 | 阈值 | 验证 | 启动期 |
|---|---|---|---|---|
| H1 | 4 P0 组件可运行 | C1~C4 health ok + 至少 1 dim 流转 | curl + DB 查 | ✅ |
| H2 | 首次 LoRA 训练成功 | 至少 1 lora_versions.status=prod | DB 查 | ✅ |
| H3 | 双盲 Kappa ≥0.80 | 至少 1 dim kappa_reports 最新 ≥0.80 | DB 查 | ⚠️ |
| H4 | lora_updated 事件可发布 | XLEN ≥1 + schema 解码 OK | redis-cli + py | ✅ |
| H5 | Holdout CI Block | 模拟退化 → exit 1 | GH Actions dry-run | ✅ |
| H6 | manual_gate 不可绕过 | grep 直改 status=prod 路径 = 0；token 必校 | scripts + 单测 | ✅ |

### §3.5.3 永久规则与文档

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| R1 | **assert_no_bypass** | manual_gate/holdout 路径无绕过 | ✅ |
| R2 | **报告留档** | JSON + Markdown | ✅ |
| R3 | **L5 一致** | l5-stage-d5s1 状态 = 实际 | ✅ |
| R4 | **总结含未尽事项** | 扩展期 P1（8 象限路由 / 自动灰度 / DPO）| ✅ |

### §3.5.4 no-mock

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| N1 | **真实链路验收** | 无 stub teacher / 无 fake training / 无 fake event | ✅ |
| N2 | **GPU 不可用透明** | 标 partial 不伪 PASS | ✅ |

> 共 **16 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| step_01~09 ✅ | 硬前置 |
| `REDIS_URL` / `DATABASE_URL` / `MINIO_*` / `WANDB_API_KEY` | 各 H 项 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 6 大检查 | 100% PASS（H3 至少 1 dim）|
| L5 锚点 | `l5-stage-d5s1` ✅ |
| 验收耗时 | 脚本 ≤15min |

## §6 下一步

D5 启动期 ✅ → **D0 维度零·副驾驶**；扩展期见 `stage_2_扩展期/`。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A validate shell** | `scripts/validate_stage_1_super_evo.sh` | 6 check；任一 FAIL exit ≠0 | 退码 |
| **B noauto/nobypass 检查** | scripts/ | grep 路径 | 0 命中 |
| **C 阶段验收 md** | `04_/05_.../阶段验收_*.md` | 命令+输出+阈值 | 人可读 |
| **D 阶段总结 md** | `阶段总结_*.md` | 10 步回顾 + P1 建议 | — |
| **E L5 回写** | `05_/02_验收标准.md` | `l5-stage-d5s1` ✅ | diff |
| **F git tag** | diting-src | `super-evo-v0.1.0` | tag -l |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `evo-step10-prep` | step_01~09 L4 均勾选 |
| `evo-step10-validate` | shell 6/6 PASS |
| `evo-step10-noauto-check` | bypass 0 命中 |
| `evo-step10-docs` | 两篇 md 更新 |
| `evo-step10-l5` | L5 行只读 diff |
| `evo-step10-tag` | tag 存在（可选 push 由人）|
| `evo-step10-test` | pytest acceptance ≥6 |
| `evo-step10-all` | 全流程 |
| `evo-step10-status` | 上次 validate 摘要 |

### §7.3 指引

先 shell→noauto→文档→L5；禁止 stub 通过；任一 FAIL 不写 ✅ 到 L5。

## §8 部署节奏

本机；可选 K3s `kubectl get pods -l app=super-evo`；无新部署。

## §9 准出标准

### §9.1 六大检查
| # | 项 | 阈值 |
|---|---|---|
| 1 | 4 P0 组件 | health 全 ok |
| 2 | 首次 LoRA prod | ≥1 lora_versions.status=prod |
| 3 | Kappa | ≥0.80（至少 1 dim）|
| 4 | lora_updated | XLEN≥1 + schema OK |
| 5 | CI Block | 模拟退化 exit 1 |
| 6 | manual_gate noauto | 0 绕过 |

### §9.2 文档与 L5
- [ ] §3.5 16 项
- [ ] `make evo-step10-all`
- [ ] L5 `l5-stage-d5s1` ✅
- [ ] L4 实践记录 + 阶段总结

## §10 [Deploy]

仅验证既有 super-evo Deployment；tag 标记镜像版本。

## §11 依赖

step_01~09。**严禁**：stub 验收；伪造 H 项证据。

## §12 风险

| 触发 | 动作 |
|---|---|
| H3 FAIL | 回 step_06；不勾 L5 |
| H6 FAIL（发现绕过）| 紧急修 + ADR |
| GPU 缺 | H5 partial + 文档 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 837 行嵌入 bash；6 大检查含 assert_no_bypass；§3.5 16 项；`evo-step10-*`；837→~190 行 |
| 2026-05-16 | 初版 837 行 |
