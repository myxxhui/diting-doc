# Step 04 · C3 LLaMA-Factory LoRA 训练流水线

## §1 一句话定位与本步交付物

**一句话**：集成 **LLaMA-Factory 0.8+** 训练流水线——按维度从 verified JSONL 训练 **LoRA**（base Qwen2.5-7B-Instruct，rank=16/32 可调，QLoRA 可选），训练 metrics 写 WandB，权重落 MinIO `super-evo/models/{lora_name}/v{N}/`，注册 `lora_versions` 表；为 step_05 Holdout 评测、step_07 灰度发布提供候选 adapter。

**交付物**（勾选 = 完成）：
- [ ] **A**（`Trainer` 包装）：`training/scripts/train_lora.py` 调 LLaMA-Factory；config 从 yaml 注入
- [ ] **B**（训练 config 模板）：`training/configs/lora_{cryo,thrust,narrative}.yaml`（rank/alpha/epoch/lr/cutoff）
- [ ] **C**（job 启动器）：`POST /api/training/{lora_name}/run`（异步触发 + job_id）
- [ ] **D**（job 状态）：`GET /api/training/{job_id}/status`；WandB run url
- [ ] **E**（`lora_versions` ORM）：`(lora_name, version, base_model, dataset_dvc_rev, train_metrics, wandb_run_id, minio_path, status)`
- [ ] **F**（MinIO 上传）：训练完成后自动 push 权重；DVC 记录数据 commit
- [ ] **G**（Makefile）：`make evo-step04-all`

> **永久规则**：训练数据**必须** `verified=true`；step_03 未通过的样本不进训练集。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../01_实践目标与策略.md](../01_实践目标与策略.md) C3、[../04_模型训练与部署.md](../04_模型训练与部署.md)
> - **DNA**：`components[2] C3`（LLaMA-Factory 0.8+，Qwen2.5-7B，LoRA rank 16/32 + QLoRA）
> - **L4**：[实践记录_step_04_C3_LLaMA_Factory训练流水线.md](../../../../../04_阶段规划与实践/05_维度五_演进飞轮/stage_1_启动期/实践记录_step_04_C3_LLaMA_Factory训练流水线.md)
> - **上游**：step_01~03；**下游**：step_05 评测、step_07 灰度、各维 LoRA 步骤

## §3 数据采集对象 / 落库映射

| 流向 | 位置 |
|---|---|
| 训练数据 | MinIO `verified/{dim}/v{YYYYMMDD}.jsonl`（来自 step_03）|
| 训练 metrics | WandB run + `lora_versions.train_metrics` JSON |
| 权重 | MinIO `super-evo/models/{lora_name}/v{N}/` |
| 注册 | `lora_versions` 表 |
| DVC 数据快照 | training/.dvc/lock 记录 |

## §3.5 数据质量验收矩阵（训练流水线 · 仅启动期）

### §3.5.1 数据契约

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| D1 | **仅 verified** | runtime guard：训练前校验 jsonl 来自 `verified/` 路径 | ✅ | 否则 fail-fast |
| D2 | **DVC 版本固定** | dataset_dvc_rev 写入 lora_versions | ✅ | 缺失→fail |
| D3 | **train/dev/holdout 不重叠** | symbol/instruction 无 leak | ✅ pre-train check | leak→fail |
| D4 | **样本量** | 每 dim ≥100 verified；含 risk 类 ≥20% | ⚠️ | <100 等 step_03 |

### §3.5.2 训练正确性

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| T1 | **超参** | rank=16 alpha=32 lr=2e-4 epoch=3（可 yaml 改）| ✅ | 改写 ADR |
| T2 | **base model 固定** | Qwen2.5-7B-Instruct 校验 sha256 | ✅ | 错→fail |
| T3 | **train loss 下降** | 末轮 loss < 初轮 loss × 0.7 | ✅ WandB check | 异常→fail+诊断 |
| T4 | **dev metrics 写入** | per-class precision/recall | ✅ | — |
| T5 | **GPU 资源** | OOM 检测；fallback QLoRA 提示 | ✅ | OOM→改 QLoRA + ADR |

### §3.5.3 工程

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **job 异步** | API 触发返 job_id；不阻塞 HTTP | ✅ | — |
| E2 | **WandB 留痕** | run_id 入 lora_versions | ✅ | offline 也存 |
| E3 | **MinIO 路径规范** | `models/{lora_name}/v{N}/` | ✅ | — |
| E4 | **可重跑幂等** | 同 lora_name + dataset_dvc_rev → 拒重训（除非 force）| ✅ | — |

### §3.5.4 no-mock

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| N1 | **不假训练** | 无 GPU → fail-fast；不返回 fake adapter | ✅ | tests/ mock 但不入库 |
| N2 | **不写 lora_versions stub 行** | 业务库严格 | ✅ | — |

> 共 **15 项**。

## §4 凭证清单

| 凭证 | 用途 | 何时 |
|---|---|---|
| GPU（≥24GB）| 训练 | 必须（QLoRA 可 ≥16GB）|
| HF 模型镜像或本地 `models/Qwen2.5-7B-Instruct` | base | step_01 已备 |
| `WANDB_API_KEY` | 实验追踪 | 必须 |
| MinIO + DVC | 权重 + 数据版本 | step_01 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 至少 1 维 LoRA 训练完成 | ✅（DNA `首次 LoRA 训练成功`）|
| dev metrics 完整 | per-class 3 项 |
| 权重上传 MinIO | ≥1 v 目录 |
| 单测 | ≥6 |

## §6 下一步

本步 ✅ → step_05 Holdout 评测器 + CI Block。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A train_lora.py** | `training/scripts/train_lora.py` | 调 LLaMA-Factory CLI；CONFIG 注入 | dry-run OK |
| **B configs** | `training/configs/lora_*.yaml` | 3 维各 1 | 解析 |
| **C 数据校验** | `training/scripts/verify_dataset.py` | verified 来源 + leak | pre-train hook |
| **D job runner** | `training/job_runner.py` | asyncio + subprocess | job_id 返回 |
| **E status API** | `api/routes/training.py` | run + status + abort | 200 |
| **F `lora_versions` ORM** | `db/models.py` + alembic | §3 字段 | migration |
| **G MinIO 上传** | `storage/lora_uploader.py` | 训练结束 hook | sha256 校验 |
| **H 单测** | `test_train_runner.py`、`test_verify_dataset.py` | ≥6（含 mock GPU）| pytest |
| **I QLoRA fallback** | config 注入 | bitsandbytes | OOM 测 |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `evo-step04-prep` | GPU 可用；base 模型在；verified jsonl 有 |
| `evo-step04-train-cryo` | D1 LoRA 训练 1 个 epoch dry-run + 完整跑（GPU 可用时）|
| `evo-step04-train-thrust` | D2 LoRA |
| `evo-step04-train-narrative` | D3 LoRA |
| `evo-step04-upload` | 权重 push MinIO + 写 lora_versions |
| `evo-step04-test` | pytest ≥6 |
| `evo-step04-all` | 端到端（最少 1 维完成）|
| `evo-step04-status` | 最近 N 次训练 metrics + status |
| `evo-step04-clean` | dev FORCE=1 清失败 job |

### §7.3 指引

先 verify_dataset→train_lora→runner→API→upload；GPU 不可用时只跑 dry-run + mock test，**不**虚报准出。

## §8 部署节奏（P 轨 · 真实基建对齐）

| 阶段 | 形态 | 是否本步必须 | 说明 |
|---|---|---|---|
| **tier-1 · 本机** | `llamafactory-cli train` + `pytest` + dry-run | **必须** | 训练脚本 + 单测在本机完成；验证 loss 下降 + adapter 落盘 + Makefile 合约通过 |
| **tier-2 · P轨 GPU（★M2 锁死）** | `make up-stack diting-training` → K8s Job → `make down-stack diting-training` | **M2 必须** | 须先完成 **P-step_04**（`diting-infra/charts/diting-training/` Job）；维度从 `--set training.dim=evo` 注入；训练完后 GPU ECS 按次回收、NAS LoRA 权重保留于 `/lora/evo/` |

**M2 链（锁死顺序）**：`P-step_03 diting-stack` ✅ → `P-step_04 make up-stack diting-training` → `D5 step_04 train` → `make down-stack diting-training` → P-step_05 → D5 step_05 Holdout。

**缺 GPU 处理**：标 `BLOCKED(gpu_unavailable)`；已跑 dry-run + 单测通过视为 tier-1 准出；等 P-step_04 GPU DECISION_PENDING 用户确认后执行 tier-2。**禁止**伪造 metrics。

**扩展期**：增 RLHF / DPO；多维 LoRA 并行（多 `diting-train-cryo` / `diting-train-thrust` / ... release）。

## §9 准出标准

- [ ] §3.5 15 项；至少 1 维完整训练 + 权重上传 + lora_versions 写入
- [ ] `make evo-step04-all`（GPU 不可用：标 BLOCKED + 已跑 dry-run）
- [ ] L4 回写（per-dim metrics + WandB url + MinIO path）

## §10 [Deploy]

ConfigMap 增 `LORA_DEFAULT_RANK=16`、`QLORA_FALLBACK=true`；GPU node 标签。

**P 轨 chart 对齐（tier-2）**：
- 训练 Job 由 `diting-infra/charts/diting-training/` 管理；启动参数（base_model / rank / dataset_path / lora_output_dir）通过 `--set` 或 values 文件注入；
- `LORA_DEFAULT_RANK`、`QLORA_FALLBACK` 等超参写入对应 ConfigMap，由 `diting-training` chart template 渲染；
- 本步**不**修改 `diting-infra/deploy-engine/`；如需改 chart，须在与 diting-infra 平级的 deploy-engine 独立仓库操作后 `make update-deploy-engine`。

## §11 依赖

step_01~03；GPU；base 模型；verified 数据。

**严禁**：未 verified 数据训练；伪造训练 metrics。

## §12 风险

| 触发 | 动作 |
|---|---|
| OOM | QLoRA + 减 batch；ADR |
| 数据量<100 | 等 step_03 补；不强训 |
| WandB 离线 | offline mode；定期 sync |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-25 | **P 轨基建对齐（回写）**：§8 改为 tier-1/tier-2 双路径表（tier-2 = P-step_04 `diting-training` chart；M2 链顺序；BLOCKED 处理）；§10 补 chart 对齐说明 |
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 1045 行嵌入 bash/yaml；§3.5 15 项；no-fake-training；`evo-step04-*`；1045→~230 行 |
| 2026-05-16 | 初版 1045 行 |
