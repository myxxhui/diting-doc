# 实践记录 · 维度五·演进飞轮 · 启动期 · step_04 · C3 LLaMA-Factory（L3 全量代码）

> [!NOTE] **[TRACEBACK] 实践锚点**
> - **L3 step**: [step_04_C3_LLaMA_Factory训练流水线.md](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_04_C3_LLaMA_Factory训练流水线.md)
> - **本阶段看板**: [README.md](./README.md)

---

## 一、范围说明

本轮在 `diting-src` 按 L3 §3 落地 **训练流水线全量代码**：数据准备、GPU 检查、LoRA 模板与训练封装、训练完成事件、端到端 CLI、pytest 与 Makefile；并提交仓库内 **100 条** sanity JSONL 供 `make sanity-train-dry` / `sanity-train` 使用。

**环境级准出**（需本机/服务器自行满足，未在本环境验证）：`pip install -e ".[training]"`、`llamafactory-cli version`、基座模型目录、`llamafactory-cli train` 真训与 loss 曲线。

---

## 二、实际进展（W4 tier-1 · 已核验）

| L3 准出项 | 状态 | 说明 |
|---|---|---|
| **`make evo-step04-all`** | ✅ | **2026-05-25** 同会话复验退码 0 |
| sanity dry-run | ✅ | train_loss=0.42 eval_loss=0.55；adapter 占位文件存在 |
| pytest pipeline | ✅ | **8 passed** |
| **BLOCKED(verified<100)** | ⏳ | Label Studio 共 **31** verified（cryo 10 / thrust 8 / narrative 13）；L3 要求每维 ≥100 · **不强训** |
| **BLOCKED(gpu_unavailable)** | ⏳ | 本机无 torch/GPU；真训练需 P-step_04 GPU stack |
| ★M2 tier-2 | ⏳ | 延 W5+（verified 补步 + P-step_04/05 + step_05 Holdout）|
| `apps/super_evo/training/data_prep.py` | ✅ | Verified JSONL → alpaca + 80/10/10 + `dataset_info.json` |
| `apps/super_evo/training/gpu_check.py` | ✅ | `check_gpu` / `is_llamafactory_installed` |
| `apps/super_evo/training/trainer.py` | ✅ | `TrainRequest` / `render_config` / `run_training`（含 dry-run 产物） |
| `training/configs/_template_lora.yaml` | ✅ | 与 L3 §3.5 模板对齐 |
| `apps/super_evo/events/training_complete.py` | ✅ | `TrainingCompletedEvent` + `TrainingEventPublisher` → `events:flywheel:training_completed` |
| `scripts/training/train_lora.py` | ✅ | 切分 → GPU/CLI 检查 → 训练 → 发布（失败仅 warning） |
| `pyproject.toml` `training` optional-deps | ✅ | 保留 `pdf-verify`，`setuptools` `include` 增补 `scripts*` |
| `Makefile` `test-llama-factory-train` 等 | ✅ | 含 `sanity-train-dry` / `sanity-train`（`SANITY_TRAIN_DATA` 可覆盖） |
| `training/data/distilled/financial_fraud/sanity_dry_run.jsonl` | ✅ | 100 条、含 `metadata.verified` |
| `pytest tests/super_evo/test_training_pipeline.py` | ✅ | **8 passed**（本机 2026-05-17） |
| `make sanity-train-dry` | ✅ | 切分 80/10/10；无 Redis 时发布失败为预期 warning |
| commit / push | — | 未按用户要求执行 |

---

## 三、验证（W4 · 一键合约）

**工作目录**：`diting-src`

```bash
cd diting-src && make evo-step04-all
```

**2026-05-25 输出摘要**：

| target | 结果 |
|---|---|
| `evo-step04-prep` | 3 维 lora yaml ✅；llamafactory-cli ⚠️ 未安装；GPU 不可用 |
| `evo-step04-sanity-train` | dry_run 通过；sanity train=16 val=2 test=2 |
| `evo-step04-test` | **8 passed** |

**L4 BLOCKED 必填字段**（14 表 §9.1.1）：

| 码 | 原因 | 后续补步 |
|---|---|---|
| `BLOCKED(verified<100)` | LS 31 条 verified，未达每维 100 | D5 step_02→03 蒸馏+标注 → `evo-step03-export` |
| `BLOCKED(gpu_unavailable)` | 无 GPU / llamafactory-cli | P-step_04 GPU 训练组 Up 后 `evo-step04-train-*` |

---

## 四、问题与风险

- 本环境 **未安装** optional `training` / `torch`，`check_gpu` 返回 `torch not installed`，CLI 在显式 `--dry-run` 下仍可跑通；真训须在 GPU 环境 `pip install -e ".[training]"` 并保证 `llamafactory-cli` 在 PATH。
- 事件发布依赖 **Redis** 可达；本地未起 Redis 时见 `publish event failed (non-fatal)`，与 L3 非致命约定一致。

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-17 | 骨架：training 目录 + 模板 yaml + trainer 占位 |
| 2026-05-17 | L3 全量：data_prep / gpu_check / trainer / events / CLI / pytest / Makefile / sanity jsonl；8 pytest + sanity-train-dry 已执行 |
| 2026-05-25 | **W4 tier-1 复验**：`make evo-step04-all` 绿 · BLOCKED(verified<100)+BLOCKED(gpu_unavailable) 已写入 |
