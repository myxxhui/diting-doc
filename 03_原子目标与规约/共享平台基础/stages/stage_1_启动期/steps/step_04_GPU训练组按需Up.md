# P-step_04 · GPU 训练组按需 Up · diting-training chart（v2）

> **本步定位**：按需起 GPU train ECS + 装 `diting-training` chart 跑 LoRA 训练。**v2 修订**：用独立 `diting-training` chart（不再 v1 在 diting-stack 内子目录）+ release 名 `diting-train-<dim>` 支持多 dim 并行 + namespace=train · nodeSelector=train · 训完即销 GPU 节点（保留 NAS LoRA + 网络）。

> [!NOTE] **[TRACEBACK]**
> - **P 轨入口**：[README](../../../README.md)
> - **拓扑设计 §2 4 chart × 3 stack 矩阵**：[01_平台拓扑设计 §2](../01_平台拓扑设计.md#§2-4-chart-×-3-stack-矩阵v2-核心架构)
> - **前置 step**：[step_03 CPU stack 按需 Up](./step_03_CPU_Stack_按需Up.md) + base ECS Ready + platform-base 已装
> - **业务对应**：D5 step_04 LoRA 训练（详见 `04_/01_维度五/stage_1_启动期/`）
> - **DNA**：[`shared/dna_shared_platform_baseline.yaml#steps[p_step_04]`](../../../../_System_DNA/shared/dna_shared_platform_baseline.yaml)
> - **L4**：[实践记录_step_04_GPU训练组](../../../../../04_阶段规划与实践/共享平台基础/stage_1_启动期/实践记录_step_04_GPU训练组.md)

---

## §1 本步目标

<a id="l4-p-step_04-goal"></a>

| # | 目标 |
|---|------|
| 1 | 新建 `charts/diting-training/` Helm chart（LoRA Job + ConfigMap + Secret + PVC NAS RW · namespace=train · nodeSelector=train + nvidia.com/gpu:1）|
| 2 | `make up-stack diting-training` 起 GPU train ECS（gn6i-c4g1 · GPU 镜像 · K3s agent join · label=train · device-plugin 自动生效）|
| 3 | `helm install diting-train-<dim>` 提交 LoRA Job（可多 dim 并行：cryo/thrust/narrative 多 release）|
| 4 | LoRA 训完 weights 写 NAS `/lora/<dim>/<ts>/adapter_model.safetensors` |
| 5 | `helm uninstall` + `make down-stack diting-training` 销 train ECS（保留 NAS LoRA + 永驻资源）|
| 6 | 每次跑后 cost-snapshot 入 L4 实践记录 |

**预计耗时**：~5h（含 ECS 起 5min + LoRA 训练 ~4h + 销节点 2min）。**成本**：~¥15 / 次（5h × ¥3/h 上限）。

---

## §2 前置条件

| # | 前置 | 检查 |
|---|------|------|
| 1 | P-step_03 准出全 ✅ | base ECS Ready + platform-base 装好 |
| 2 | D5 verified ≥100/dim 或 冲 ★M2 sanity-train | D5 step_03 状态 |
| 3 | base 模型镜像已 push ACR（如 `qwen2.5-14b-instruct`） | `docker pull <ACR>/qwen2.5-14b:latest` 通 |
| 4 | 训练数据已就绪 NAS `/mnt/nas/datasets/<dim>/` | `kubectl exec -n platform <pod> -- ls /mnt/nas/datasets/cryo/` |
| 5 | 当前 NAS LoRA 目录留空 `/mnt/nas/lora/<dim>/`（未训过 · 或前次已归档）| `ls /mnt/nas/lora/` |

---

## §3 工作目录

```bash
cd /Users/<user>/Desktop/workspace/diting-infra
```

---

## §3.5 数据质量验收矩阵（GPU 节点 + 训练 + 权重落地）

| # | 检查项 | 验证方式 | 启动期标准 |
|---|--------|---------|-----------|
| **GPU 节点** | | | |
| G1 | train ECS 起 · Spot 中标 | `kubectl get nodes -L stack.diting/node | grep train` | 1 行 Ready ✅ |
| G2 | GPU 可调度（device-plugin 注入资源）| `kubectl describe node -l stack.diting/node=train | grep nvidia.com/gpu` | `Allocatable: nvidia.com/gpu: 1` ✅ |
| G3 | NVIDIA Driver + CUDA 就绪 | `kubectl run -n train --rm -it gpu-test --image=nvidia/cuda:12.8-base --restart=Never --overrides='{"spec":{"nodeSelector":{"stack.diting/node":"train"}}}' -- nvidia-smi` | 输出 GPU 信息 ✅ |
| G4 | NAS 已挂到 train 节点 `/mnt/nas` | `ssh root@<train-EIP> 'df -h /mnt/nas'` 或 kubectl exec | ✅ |
| **diting-training chart** | | | |
| T1 | helm release 已起（至少 1 dim） | `helm list -n train | grep diting-train-` | ≥1 行 ✅ |
| T2 | LoRA Job 状态 | `kubectl get job -n train -l app=diting-train` | Active or Complete ✅ |
| T3 | LoRA Pod 调度到 train 节点 + 用了 GPU | `kubectl get pod -n train -l app=diting-train -o wide` + `kubectl exec ... -- nvidia-smi` | 调对 + GPU 占用 ✅ |
| T4 | Job 5 min 内日志出 train_loss | `kubectl logs -n train -l app=diting-train --tail=50 | grep train_loss` | 含 train_loss=数字 ✅ |
| T5 | 训练完成 Job Complete | `kubectl wait --for=condition=complete job/diting-train-<dim> -n train --timeout=4h` | 退码 0 ✅ |
| T6 | LoRA 权重写入 NAS | `ls -lh /mnt/nas/lora/<dim>/<ts>/adapter_model.safetensors` | 文件存在 + 大小合理（几十 MB~几百 MB）✅ |
| T7 | training_args.json 落 NAS | `cat /mnt/nas/lora/<dim>/<ts>/training_args.json | jq .` | 含 base_model + lora_r + maxSteps ✅ |
| **多 dim 并行（可选）** | | | |
| M1 | 2+ 个 helm release 并行 | `helm list -n train | wc -l` | ≥2 ✅（如 cryo + thrust）|
| M2 | 多 Job 共用 train 节点（共享 GPU 或排队 nvidia-mig）| `kubectl get pod -n train` | 多 pod Running 或 Pending(GPU 排队)✅ |
| **销节点** | | | |
| R1 | helm uninstall 后 K8s 资源清干净 | `kubectl get all -n train` | 空 ✅ |
| R2 | down-stack 后 train ECS 销 | `terraform state list | grep stack..train` | 空 ✅ |
| R3 | down-stack 后 NAS LoRA 仍在 | `kubectl exec -n platform busybox -- ls /mnt/nas/lora/<dim>/<ts>/` | 文件仍在 ✅ |
| R4 | down-stack 后 VPC + 网络仍在（永驻）| `terraform output vpc_id` | 仍 `vpc-j6cuhmska9vfwqa6my16q` ✅ |
| **成本** | | | |
| C1 | 本轮成本 ≤ ¥30 / 5h | `make platform-step04-cost-snapshot` | ✅ |

---

## §4 启动期数据量预期 / §4.1 凭证

- LoRA 权重大小：~50-200MB / dim · 累计 ~600MB (3 dim × 200MB)
- 训练日志：~10MB / 跑次
- 用户须提供：`WANDB_API_KEY`（可选 · 默认 offline）+ `HF_TOKEN`（HuggingFace 拉 base 模型时）+ `TF_VAR_instance_password`

---

## §5 启动期数据量预期

见 §4。

---

## §6 下一步

→ 训完出 LoRA 权重 → [P-step_05 GPU 推理组按需 Up](./step_05_GPU推理组按需Up.md)（用本步训出的 LoRA 跑 Holdout）
→ 任意时刻：[P-step_06 三档释放纪律](./step_06_Stack_Down与三档释放纪律.md)

---

## §7 实施步骤（设计规划推演）

### 7.1 实现要点

| 实现要点 | 涉及位置 | 关键设计决策 | 验证标准 |
|---------|---------|-------------|---------|
| 新建 `charts/diting-training/` chart | `diting-infra/charts/diting-training/{Chart.yaml,values.yaml,templates/}` | 独立 chart · namespace=train · release 名 `diting-train-<dim>` 可多 release 并行 | T1~T2 ✅ |
| Job 模板带 nodeSelector + GPU resources | `templates/train-lora-job.yaml`：`spec.template.spec.nodeSelector={stack.diting/node:train}` + `containers[0].resources.limits.nvidia.com/gpu=1` | 强制调度到 GPU 节点 | T3 ✅ |
| PVC 挂 NAS 子路径 | `templates/pvc-nas-lora.yaml` → storageclass=nas · mountPath=/mnt/nas/lora/<dim>/<ts>/ | RW 给训练写权重 | T6 ✅ |
| ConfigMap 训练超参 | `templates/configmap-train.yaml`：base_model / dim / maxSteps / lora_r / dataset_path | helm `--set` 覆盖 | T4 ✅ |
| Secret WandB | `templates/secret-wandb.yaml` · `--set wandb.apiKey=$WANDB_API_KEY` 注入 | 启动期默认 offline | — |
| 起 train ECS | `make up-stack diting-training` → terraform apply -target=stack["train"]（image_family=ubuntu_22_04_gpu）| 复用 VPC/SG/NAS · 仅新建 ECS+EIP+系统盘 | G1~G4 ✅ |
| 销 train ECS | `make down-stack diting-training` → helm uninstall + terraform destroy -target=stack["train"] | 保留 NAS LoRA + 永驻 | R1~R4 ✅ |

### 7.2 Makefile 合约

| target | 行为 |
|--------|------|
| `make up-stack diting-training` | 起 train ECS + 等 K3s agent join + 等 device-plugin Ready |
| `make platform-step04-sanity-train DIM=<dim>` | helm install diting-train-<dim> --set maxSteps=50 + 等 Job Complete |
| `make platform-step04-real-train DIM=<dim>` | helm install --set maxSteps=500（真训练 · 仅 verified ≥100 时）|
| `make platform-step04-cost-snapshot` | 输出本轮 ECS 跑时 + 成本估算 |
| `make down-stack diting-training` | helm uninstall 所有 diting-train-* + 销 train ECS |

### 7.3 给后续执行模型的指引

- **必须**先做 P-step_03（base ECS + platform-base 就绪），否则 K3s server 不存在 train 无法 join；
- **GPU 镜像**用 ubuntu_22_04_gpu family（在 P-new-02 deploy-engine 扩展规约已实现）· 开箱即用 NVIDIA Driver + CUDA + Container Toolkit · **不需要**手装；
- **多 dim 并行**：同 train ECS 可同时跑多 release（如 cryo + thrust），但 GPU 只有 1 张 T4 16G，**会排队**（kubectl pod 状态 Pending until GPU 空闲）· 若想真并行 → 切多 GPU 实例 gn7i 等（成本高）；
- **训完一定要 down-stack**：GPU ¥3/h 跑着不用浪费钱；
- **降级**：若 BLOCKED(gpu_unavailable) → sanity-train 跑 CPU（很慢 · 仅验证 pipeline）+ 标 L4 BLOCKED；
- **降级 deploy-engine 未完成**：若 P-new-02 未做 → 退到 `make deploy diting prod` 整体 Up（CPU+GPU 一起 · 不分 stack）· 但无法独立 down GPU。

---

## §8 本步在哪里跑

| 操作 | 位置 |
|------|------|
| make up-stack / 训练 / 销节点 | `diting-infra/`（本地 · 配 kubeconfig）|
| chart 编辑 | `diting-infra/charts/diting-training/`（新建）|
| 业务训练代码 | `diting-src/apps/super_evo/training/`（不在本步内 · 通过镜像调用）|

---

## §9 准出（Exit Criteria）

- [ ] §3.5 G1~G4, T1~T7, R1~R4 全 ✅（多 dim M1~M2 可选）
- [ ] 至少 1 dim sanity-train（maxSteps=50）或真训完
- [ ] LoRA 权重落 NAS · ls 可见
- [ ] down-stack 后 train ECS 销 · NAS LoRA + VPC + 网络全保留
- [ ] 本轮成本 ≤ ¥30
- [ ] 已更新 L5 02_验收标准 中 `l5-shared-platform-baseline-step04` 对应行
- [ ] L4 实践记录_step_04 回填完成

---

## §10 [Deploy] 部署节奏

| 阶段 | 部署内容 | 触发 |
|------|---------|------|
| W4 sanity | sanity-train（DIM=cryo · maxSteps=50）| 冲 ★M2 |
| W4~W5 真训 | real-train（3 dim 各 maxSteps=500）| D5 verified ≥100/dim |
| 后续按需 | 每次新数据触发 retrain | DECISION_PENDING（用户决定）|

---

## §11 依赖

- P-step_03 ✅（base ECS + platform-base）
- P-new-02 deploy-engine 扩展 ✅（多 stack for_each + GPU 镜像支持）
- D5 step_02/03 verified 样本（启动期允许少 → sanity-train 不依赖）

---

## §12 风险与降级

| 风险 | 概率 | 影响 | 降级 |
|------|------|------|------|
| Spot 库存 0（gn6i 香港）| 中 | 高 | 换 cn-hongkong-b/a · 或临时按量 ¥10/h ≤2h |
| GPU 镜像拉失败（首次镜像 ~10GB）| 低 | 中 | image_family 退到 ubuntu_22_04 + user-data 手装 driver（慢 ~20min）|
| LoRA OOM（T4 16G 不够 14B）| 中 | 高 | 切 LoRA r=4 + max_seq=512 · 或换 base 模型小（7B）|
| WandB 上传超时 | 低 | 低 | offline 模式（默认）|
| Job 跑超 4h（启动期上限）| 低 | 中 | maxSteps 调小 · 分多次跑 |
| down-stack 时残留 LoRA Pod 未 graceful | 低 | 低 | helm uninstall 自动 SIGTERM · 30s 内退出 |

---

## §13 修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-24 v1 | 在 diting-stack 内加 training 子目录方案（未实现）|
| **2026-05-24 v2** | **改为独立 chart diting-training**：①命令 `make up-stack diting-training`②release 名 `diting-train-<dim>` 支持多 dim 并行③namespace=train + nodeSelector=train④NAS subPath `/lora/<dim>/<ts>/`⑤训完即销 GPU 节点（保留 NAS + 网络）⑥加 §3.5 G/T/M/R/C 27 项矩阵 |
