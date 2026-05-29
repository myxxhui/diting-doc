# L4 · 共享平台基础 · 启动期 · 实践记录 step_04 GPU 训练组按需 Up · diting-training chart（v2）

> **状态**：⏳ BLOCKED(spot_inventory_zero) · W5 2026-05-25 定时重试中（2h/次）

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[step_04_GPU训练组按需Up](../../../03_原子目标与规约/共享平台基础/stages/stage_1_启动期/steps/step_04_GPU训练组按需Up.md)
> - **DNA**：`dna_shared_platform_baseline.yaml#steps.p_step_04`
> - **L5**：[`02_验收标准.md#l5-shared-platform-baseline-step04`](../../../05_成功标识与验证/02_验收标准.md)
> - **上游**：← [实践记录_step_03_CPU_Stack_按需Up](./实践记录_step_03_CPU_Stack_按需Up.md)
> - **下游**：→ [实践记录_step_05_GPU推理组](./实践记录_step_05_GPU推理组.md)（用本步训出的 LoRA）

## 一、本步骤目标

按 L3 设计完成：①新建 `charts/diting-training/` chart；②`make up-stack diting-training` 起 GPU train ECS（gn6i-c4g1 · GPU 镜像 · K3s agent · label=train + nvidia.com/gpu=present）；③helm install `diting-train-<dim>` 提交 LoRA Job（可多 dim 并行）；④LoRA 权重落 NAS `/mnt/nas/lora/<dim>/<ts>/`；⑤训完 `make down-stack diting-training` 销节点（保留 NAS + 网络）。

## 二、实际进展（**待执行时覆盖**）

| 项 | 状态 | 证据 |
|----|------|------|
| GPU train ECS Spot ID + 抢价 | ⏳ | `terraform state show 'alicloud_instance.stack["train"]'` |
| GPU 可调度（nvidia.com/gpu: 1）| ⏳ | `kubectl describe node -l stack.diting/node=train | grep nvidia` |
| Job 状态（每 dim 一份）| ⏳ | `kubectl get job -n train -l app=diting-train` |
| LoRA 权重落 NAS | ⏳ | `ls -lh /mnt/nas/lora/<dim>/<ts>/adapter_model.safetensors` |
| 本轮跑时（小时）+ 成本（¥）| ⏳ | `make platform-step04-cost-snapshot` |
| down 后永驻仍在（VPC + NAS LoRA）| ⏳ | `terraform output vpc_id nas_id` + `kubectl exec ... -- ls /mnt/nas/lora/` |

## 三、命令与输出摘要

（待执行时填）

## 四、DECISION_PENDING 与 SKIP_REASON

| 项 | 类型 | 说明 | 建议 |
|----|------|------|------|
| WandB online/offline | DECISION_PENDING | 启动期默认 offline | 启动期 offline |
| 多卡训练 | DECISION_PENDING | 启动期 1 卡（T4 16G）| 启动期 1 卡 |
| `BLOCKED(spot_inventory_zero)` | **实际发生** | 2026-05-25 22:09 香港三可用区 gn6i-c4g1.xlarge Spot 均 SoldOut（API 查证）| `diting-infra/scripts/retry-up-stack-training.sh` 定时重试（每 2h）；按量备选 ¥8-12/h |
| `BLOCKED(deploy_engine_lifecycle_missing)` | SKIP_REASON 例 | new-02 未完成时退到整体 deploy | 退 + L4 BLOCKED |

## 五、准出复核

- [ ] §3.5 G1~G4, T1~T7, R1~R4 共 15 项必 ✅
- [ ] 至少 1 dim sanity-train 或真训完
- [ ] LoRA 权重落 NAS · ls 可见
- [ ] down-stack 后 train ECS 销 · 永驻 10 项全在
- [ ] 本轮成本 ≤ ¥30
- [ ] L5 `l5-shared-platform-baseline-step04` ✅

## 六、修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-24 | 占位创建 |
| **2026-05-24 v2** | **改用 diting-training chart**：①release 名 `diting-train-<dim>` 支持多 dim②命令 `make up-stack diting-training`③NAS subPath `/lora/<dim>/<ts>/`④down 保留永驻 10 项 |
| **2026-05-25 W5** | **BLOCKED(spot_inventory_zero)**：tfvars `count=1`，执行 `make up-stack diting-training`→`OperationDenied.NoStock`；阿里云 API 确认香港 b/c/d 三区 gn6i Spot 均 SoldOut；新加坡同样 SoldOut；按量 cn-hongkong-b Available。已启动 `retry-up-stack-training.sh`（2h 间隔，pid 跟踪），成功后继续 D5 step_04 tier-2 sanity。 |
