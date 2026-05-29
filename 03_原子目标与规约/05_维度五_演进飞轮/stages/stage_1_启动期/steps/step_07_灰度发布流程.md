# Step 07 · 手动灰度发布流程（manual_gate · 5 stage pipeline）

## §1 一句话定位与本步交付物

**一句话**：实现 **ReleasePipeline**（DNA `release_pipeline.stages = train→evaluate→manual_gate→deploy→monitor`）——把 step_04 训出的 adapter，经 step_05/06 双闸通过后，**架构师手动签字** → `LoRADeployer` 调 vLLM 热加载 + 标记 `lora_versions.status=prod` → `MonitorAgent` 观察上线后 24h 指标 → 出问题一键回滚到上一 prod 版本。

**交付物**（勾选 = 完成）：
- [ ] **A**（`ReleasePipeline` orchestrator）：状态机 5 stage；任一 stage 失败回退
- [ ] **B**（`LoRADeployer`）：调 vLLM `/v1/load_lora`（或等价 API）；超时回滚
- [ ] **C**（`manual_gate`）：API `POST /api/release/{lora_version_id}/sign`（架构师 token）
- [ ] **D**（`MonitorAgent`）：上线后 24h 拉关键指标（命中率/延迟/错误率），异常 → 自动建议回滚（仍需人确认）
- [ ] **E**（`release_pipelines` ORM）：状态机审计；`(pipeline_id, lora_version_id, current_stage, history)`
- [ ] **F**（回滚）：`POST /api/release/{pipeline_id}/rollback`；vLLM 卸载 candidate + 加载 prev_prod
- [ ] **G**（Makefile）：`make evo-step07-all`

> **永久规则**：自动 deploy 仅在 manual_gate ✅ 后；**禁止**绕过签字；回滚也保留 audit。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../04_模型训练与部署.md](../04_模型训练与部署.md) §六 发布
> - **DNA**：`release_pipeline.stages` + `deploy_strategy: 手动灰度`
> - **L4**：[实践记录_step_07_灰度发布流程.md](../../../../../04_阶段规划与实践/05_维度五_演进飞轮/stage_1_启动期/实践记录_step_07_灰度发布流程.md)
> - **上游**：step_04~06；**下游**：step_08 lora_updated 事件流、step_09 D1 联调

## §3 数据采集对象 / 落库映射

| 流向 | 表 |
|---|---|
| 流水线状态 | `release_pipelines(stage, history, started_at, completed_at)` |
| 签字 | `manual_gate_signatures(pipeline_id, reviewer, signed_at, comment)` |
| Monitor 指标 | `release_monitor_logs(pipeline_id, metric, value, ts)` |
| 回滚审计 | `release_rollbacks(pipeline_id, reason, prev_version, new_version)` |

## §3.5 数据质量验收矩阵（灰度发布 · 仅启动期）

### §3.5.1 状态机正确性

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| S1 | **5 stage 顺序** | train→evaluate→manual_gate→deploy→monitor | ✅ 单测 | — |
| S2 | **非法跳转拒绝** | 跳过 manual_gate 抛 422 | ✅ | — |
| S3 | **失败回退** | 任一 stage fail → pipeline status=failed + rollback hint | ✅ | — |
| S4 | **幂等** | 同 lora_version 不重复开 pipeline（除非显式 force）| ✅ | — |

### §3.5.2 manual_gate 与签字

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| G1 | **签字唯一入口** | API + token；其他路径无法 status=prod | ✅ | — |
| G2 | **签字留痕** | manual_gate_signatures 写入 | ✅ | — |
| G3 | **拒绝路径** | 不签字 → pipeline status=abandoned + 通知 | ✅ | — |
| G4 | **双指标守门已过** | evaluate stage 必须 step_05 PASS + step_06 kappa≥0.80 | ✅ pre-check | — |

### §3.5.3 deploy 与 monitor

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| D1 | **vLLM 热加载** | `load_lora` API 调用成功 | ✅ | 失败 → 自动回滚 |
| D2 | **prod 标记** | lora_versions.status=prod；前一版自动 status=archived | ✅ | — |
| D3 | **monitor 24h** | 命中率/延迟/错误率定时拉；阈值告警 | ✅ scheduler | 缺监控源 → 标 partial |
| D4 | **回滚可执行** | rollback API 一键回前一 prod；audit 完整 | ✅ | — |

### §3.5.4 no-mock

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| N1 | **真 vLLM** | 热加载用真 vLLM；不接 stub | ✅ | tests/ 例外 |
| N2 | **签字不可伪造** | token 校验；token 缺→拒 | ✅ | — |

> 共 **14 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| 架构师 `RELEASE_REVIEWER_TOKEN` | manual_gate |
| vLLM 服务地址 | deploy |
| `WANDB_API_KEY` | monitor 拉指标 |
| step_05/06 PASS | deploy 前置 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 至少 1 个 pipeline 走完 5 stage | ✅ |
| 回滚演练 | ✅ |
| 单测 | ≥10 |

## §6 下一步

本步 ✅ → step_08 `events:flywheel:lora_updated` 事件流。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A ReleasePipeline** | `deployment/release_pipeline.py` | 状态机；5 stage handler | 单测 5 路径 |
| **B LoRADeployer** | `deployment/lora_deployer.py` | httpx 调 vLLM；超时回滚 | mock vLLM |
| **C manual_gate API** | `api/routes/release.py` | sign + reject | token 校验 |
| **D MonitorAgent** | `deployment/monitor_agent.py` | scheduler 24h；阈值表 | mock data |
| **E `release_pipelines` ORM** | `db/models.py` + alembic | §3 字段 | migration |
| **F rollback API** | 同 routes | 一键回前一 prod | e2e |
| **G 单测** | `test_release_pipeline.py` 等 | ≥10 | pytest |
| **H runtime guard** | 状态机检查 step_05 PASS + kappa | pre-deploy | 单测 |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `evo-step07-prep` | step_04~06 全 PASS；vLLM 可达 |
| `evo-step07-start-pipeline` | 一条新 pipeline 至 manual_gate stop |
| `evo-step07-sign` | manual_gate API sign（dev token） |
| `evo-step07-deploy` | vLLM 加载 + 状态 prod |
| `evo-step07-monitor-once` | 拉一次指标 |
| `evo-step07-rollback-sim` | rollback API；前一版回 prod |
| `evo-step07-test` | pytest ≥10 |
| `evo-step07-all` | 端到端（含回滚演练）|
| `evo-step07-status` | 当前 prod adapter + pipeline history |
| `evo-step07-clean` | dev FORCE=1 失败 pipeline 清理 |

### §7.3 指引

先状态机→Deployer→manual_gate→Monitor→rollback；签字 token 必须从 env 注入；rollback 不依赖人工"手快"，一条 API 即回。

## §8 部署节奏

本机 + 真 vLLM；K3s 扩展期。

## §9 准出标准

- [ ] §3.5 14 项；1 个完整 pipeline + 1 次回滚演练
- [ ] `make evo-step07-all`；L4 回写（pipeline id、prod adapter、监控阈值）

## §10 [Deploy]

ConfigMap 增 `RELEASE_REVIEWER_TOKEN`、`MONITOR_THRESHOLDS_YAML`。

## §11 依赖

step_04/05/06；vLLM；WandB；架构师 token。

**严禁**：自动 deploy 不经签字；伪造 monitor 指标。

## §12 风险

| 触发 | 动作 |
|---|---|
| vLLM 热加载失败 | 自动回滚 + 告警 |
| monitor 异常 | 建议回滚（仍人决策）|
| 签字 token 泄漏 | 立即轮换 + ADR |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 1128 行嵌入 Python/yaml；§3.5 14 项；manual_gate 强制；`evo-step07-*`；1128→~220 行 |
| 2026-05-16 | 初版 1128 行 |
