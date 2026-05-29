# P-step_05 · GPU 推理组按需 Up · diting-vllm chart（v2）

> **本步定位**：按需起 GPU infer ECS + 装 `diting-vllm` chart 提供 multi-LoRA 推理服务（vLLM）。**v2 修订**：用独立 `diting-vllm` chart（不再 v1 在 diting-stack 内子目录）+ namespace=infer · nodeSelector=infer · **连跑多 dim 时保留节点**（DECISION 默认 keep_node=true · 省 5 min × N 启动）。

> [!NOTE] **[TRACEBACK]**
> - **P 轨入口**：[README](../../../README.md)
> - **拓扑设计**：[01_平台拓扑设计](../01_平台拓扑设计.md)
> - **前置 step**：[step_04 GPU 训练组按需 Up](./step_04_GPU训练组按需Up.md)（必须已训完 ≥1 dim LoRA · 在 NAS 内）
> - **业务对应**：D5 step_05 Holdout 评测（INFERENCE_MODE=vllm）+ D1 step_07 三引擎部署
> - **DNA**：[`shared/dna_shared_platform_baseline.yaml#steps[p_step_05]`](../../../../_System_DNA/shared/dna_shared_platform_baseline.yaml)
> - **L4**：[实践记录_step_05_GPU推理组](../../../../../04_阶段规划与实践/共享平台基础/stage_1_启动期/实践记录_step_05_GPU推理组.md)

---

## §1 本步目标

<a id="l4-p-step_05-goal"></a>

| # | 目标 |
|---|------|
| 1 | 新建 `charts/diting-vllm/` Helm chart（vLLM Deployment + Service + ConfigMap + PVC NAS RO + Secret · namespace=infer · nodeSelector=infer + nvidia.com/gpu:1）|
| 2 | `make up-stack diting-vllm` 起 GPU infer ECS（同 train 规格 · GPU 镜像 · K3s agent join · label=infer）|
| 3 | `helm install diting-infer -n infer --set vllm.loraList="cryo,thrust,narrative"` 起 vLLM Deployment（multi-LoRA · 从 NAS `/lora/` 加载）|
| 4 | vLLM `/v1/models` 返回含 base + ≥1 LoRA adapter |
| 5 | D5 step_05 真 Holdout 评测（VLLM_URL=http://diting-infer.infer.svc:8000）跑多 dim · **节点保留**直到全部评完 |
| 6 | 评完 `helm uninstall diting-infer` + `make down-stack diting-vllm` 销 infer ECS（保留 NAS + 永驻）|

**预计耗时**：~3h（含 ECS 起 5min + vLLM 启动 ~10min + 3 dim Holdout 评测 ~2h + 销节点 2min）。**成本**：~¥9 / 次（3h × ¥3/h 上限）。

---

## §2 前置条件

| # | 前置 | 检查 |
|---|------|------|
| 1 | P-step_03 准出全 ✅ | base ECS Ready + platform-base 装好 |
| 2 | P-step_04 至少 1 dim 训完 | `ls /mnt/nas/lora/<dim>/<ts>/adapter_model.safetensors` 存在 |
| 3 | vLLM 镜像已 push ACR（如 `vllm/vllm-openai:0.5.x`）| `docker pull <ACR>/vllm-openai:0.5.x` 通 |
| 4 | base 模型镜像或 HF 缓存可用 | NAS `/mnt/nas/checkpoints/<base_model>/` 或 HF_TOKEN |

---

## §3 工作目录

```bash
cd /Users/<user>/Desktop/workspace/diting-infra
```

---

## §3.5 数据质量验收矩阵（GPU 节点 + vLLM + Holdout 评测）

| # | 检查项 | 验证方式 | 启动期标准 |
|---|--------|---------|-----------|
| **GPU 节点** | | | |
| G1 | infer ECS 起 · Spot 中标 | `kubectl get nodes -L stack.diting/node | grep infer` | 1 行 Ready ✅ |
| G2 | GPU 可调度 | `kubectl describe node -l stack.diting/node=infer | grep nvidia.com/gpu` | `Allocatable: nvidia.com/gpu: 1` ✅ |
| G3 | NVIDIA Driver + CUDA 就绪 | 同 step_04 G3 | ✅ |
| G4 | NAS 已挂到 infer 节点 RO | `kubectl exec -n infer <pod> -- ls /mnt/nas/lora/` | ≥1 dim 子目录 ✅ |
| **diting-vllm chart** | | | |
| V1 | helm release diting-infer 在 infer ns | `helm list -n infer | grep diting-infer` | ✅ |
| V2 | vLLM Deployment Ready | `kubectl wait --for=condition=available deployment/diting-infer -n infer --timeout=10m` | 退码 0 ✅ |
| V3 | vLLM 用了 GPU | `kubectl exec -n infer deploy/diting-infer -- nvidia-smi` | GPU 占用 ✅ |
| V4 | /v1/models 返回 base + adapters | `kubectl exec -n infer deploy/diting-infer -- curl -s localhost:8000/v1/models | jq '.data[].id'` | 含 base + ≥1 LoRA ✅ |
| V5 | /v1/completions 单次推理 < 5s | `time curl -s -X POST -d '{"model":"<base>","prompt":"test","max_tokens":10}' localhost:8000/v1/completions` | < 5s ✅ |
| V6 | multi-LoRA 切换（≥2 dim）| 同上 curl 改 model="lora-<dim>" 切换测试 | 不同 dim 返回不同结果 ✅ |
| **业务联动 D5 Holdout** | | | |
| H1 | D5 Holdout 评测 1 dim 跑通 | `make holdout DIM=cryo BACKEND=vllm VLLM_URL=http://diting-infer.infer.svc:8000` | 退码 0 + 报告生成 ✅ |
| H2 | D5 Holdout 评测多 dim 连跑（节点保留）| `for d in cryo thrust narrative; do make holdout DIM=$d BACKEND=vllm; done` | 3 dim 全跑完 + 节点 keep ✅ |
| H3 | 非 fallback（真 vLLM 调用）| 检查 Holdout 报告 `inference_mode` 字段 | `vllm` 而非 `mock` ✅ |
| **销节点** | | | |
| R1 | helm uninstall 后 K8s 资源清干净 | `kubectl get all -n infer` | 空 ✅ |
| R2 | down-stack 后 infer ECS 销 | `terraform state list | grep stack..infer` | 空 ✅ |
| R3 | down-stack 后 NAS LoRA 仍在 | `kubectl exec -n platform busybox -- ls /mnt/nas/lora/` | ≥1 dim 仍在 ✅ |
| R4 | down-stack 后 VPC + 网络仍在（永驻）| `terraform output vpc_id` | ✅ |
| **成本** | | | |
| C1 | 本轮成本 ≤ ¥15 / 3h | `make platform-step05-cost-snapshot` | ✅ |

---

## §4 / §5 启动期数据量预期 / 凭证

- vLLM 镜像：~10GB（首次拉慢 · 之后缓存）
- base 模型：~30GB（14B）/ ~14GB（7B）· 从 NAS 加载或 HF 拉
- LoRA adapter：~50-200MB / dim
- 用户凭证：`HF_TOKEN`（可选 · 从 HF 拉模型时）+ `TF_VAR_instance_password`

---

## §6 下一步

→ Holdout 全 ✅ → 训练-推理闭环 OK · 持续打磨
→ 评完 `make down-stack diting-vllm` · 待下次评测再 up
→ 任意时刻：[P-step_06 三档释放纪律](./step_06_Stack_Down与三档释放纪律.md)

---

## §7 实施步骤（设计规划推演）

### 7.1 实现要点

| 实现要点 | 涉及位置 | 关键设计决策 | 验证标准 |
|---------|---------|-------------|---------|
| 新建 `charts/diting-vllm/` chart | `diting-infra/charts/diting-vllm/{Chart.yaml,values.yaml,templates/}` | 独立 chart · namespace=infer · 长服务 Deployment | V1~V2 ✅ |
| vLLM Deployment 启动参数 | `templates/vllm-deployment.yaml`：`args: ["--model","/mnt/nas/checkpoints/<base>","--enable-lora","--lora-modules","lora-cryo=/mnt/nas/lora/cryo/...","--max-loras","4"]` | multi-LoRA · 从 NAS 直接加载 | V4 ✅ |
| Service ClusterIP（不暴露公网）| `templates/vllm-service.yaml`：type=ClusterIP · port=8000 | 仅集群内调（Holdout 通过 svc DNS）| H1 ✅ |
| PVC NAS RO | `templates/pvc-nas-lora.yaml`：storageclass=nas · access RWX · mountPath=/mnt/nas/lora · readOnly=true | 防 vLLM 误写 | G4 ✅ |
| ConfigMap | `templates/configmap-vllm.yaml`：base_model / loraList / tensor_parallel | helm `--set` 覆盖 | — |
| 起 infer ECS | `make up-stack diting-vllm` → terraform apply -target=stack["infer"]（image_family=ubuntu_22_04_gpu）| 复用 VPC/SG/NAS · 仅新建 ECS | G1~G4 ✅ |
| 销 infer ECS | `make down-stack diting-vllm` → helm uninstall + terraform destroy -target=stack["infer"] | 保留 NAS + 永驻 | R1~R4 ✅ |

### 7.2 Makefile 合约

| target | 行为 |
|--------|------|
| `make up-stack diting-vllm` | 起 infer ECS + 等 K3s + 等 device-plugin |
| `make platform-step05-install-infer LORAS="cryo,thrust,narrative"` | helm install diting-infer + 等 Ready + 探活 /v1/models |
| `make platform-step05-holdout-multi DIMS="cryo thrust narrative"` | 循环跑 D5 Holdout 多 dim（**节点保留**）|
| `make platform-step05-cost-snapshot` | 本轮成本 |
| `make down-stack diting-vllm` | helm uninstall + 销 infer ECS |

### 7.3 给后续执行模型的指引

- **必须**先做 P-step_04（至少 1 dim 训完）· 否则 vLLM `/v1/models` 只有 base 模型 · Holdout 退到 base 模式（标 DECISION）；
- **连跑多 dim 保留节点**（`keep_node_for_multi_dim=true`）：vLLM 启动需 ~5 min（加载 base 30GB + LoRA），连跑 3 dim 若每次 down/up 浪费 15 min；
- **若 BLOCKED(no_lora_weight)**：回 P-step_04 训完再上；或允许仅 base 模型 serve（标 DECISION_PENDING）；
- **若 BLOCKED(vllm_oom)**：T4 16G 跑 14B + 4 LoRA 可能 OOM → 调小 `--max-loras=2` 或切 7B base 模型 或切 gn7i（贵 50%）；
- **评完一定 down-stack**：vLLM ¥3/h 跑着不用浪费钱；
- **NAS RO 挂载**：防 vLLM 进程意外写坏权重（训练写 RW · 推理只读 RO）。

---

## §8 本步在哪里跑

| 操作 | 位置 |
|------|------|
| make up-stack / Holdout / 销节点 | `diting-infra/`（本地）|
| chart 编辑 | `diting-infra/charts/diting-vllm/`（新建）|
| Holdout 业务代码 | `diting-src/apps/super_evo/quality/holdout_evaluator.py`（已实现 · 通过 VLLM_URL 调用）|

---

## §9 准出（Exit Criteria）

- [ ] §3.5 G1~G4, V1~V5, H1, R1~R4 全 ✅（V6 视 LoRA 数；H2~H3 多 dim 优 ✅）
- [ ] 至少 1 dim 真 Holdout 评测（vllm 模式 · 非 fallback）
- [ ] down-stack 后 infer ECS 销 · NAS + 网络全保留
- [ ] 本轮成本 ≤ ¥15
- [ ] 已更新 L5 02_验收标准 中 `l5-shared-platform-baseline-step05` 对应行
- [ ] L4 实践记录_step_05 回填完成

---

## §10 [Deploy] 部署节奏

| 阶段 | 部署内容 | 触发 |
|------|---------|------|
| W5+ 首次 | 1 dim 真 Holdout（cryo）| P-step_04 训完 cryo |
| W5~W12 | 多 dim 连跑（节点保留）| 每次新 LoRA 训完 |
| ★M5 | D1 step_07 三引擎上线 · vLLM 转长服务 | 完善期触发 |

---

## §11 依赖

- P-step_03 ✅（base ECS + platform-base）
- P-step_04 ≥1 dim ✅（LoRA 权重在 NAS）
- P-new-02 deploy-engine 扩展 ✅
- D5 step_05 Holdout 代码已实现（diting-src）

---

## §12 风险与降级

| 风险 | 概率 | 影响 | 降级 |
|------|------|------|------|
| Spot 库存 0 | 中 | 高 | 换可用区 · 临时按量 ≤2h |
| vLLM OOM（14B + 多 LoRA）| 高 | 高 | 减 --max-loras / 7B base / 切 gn7i |
| vLLM 启动慢（首次拉模型 ~10 min）| 高 | 中 | 预热（首次接受慢 · 连跑保留节点）|
| LoRA 加载失败（NAS 权限 / 路径错）| 低 | 高 | 检查 RO 挂载 + ls /mnt/nas/lora |
| Holdout 评测全 fallback | 低 | 中（不达 tier-2）| 检查 VLLM_URL + svc DNS · 重试 |
| 评完忘记 down 浪费钱 | 中 | 中 | Makefile auto-down on success or CronJob 监控 |

---

## §13 修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-24 v1 | 在 diting-stack 内加 vllm 子目录方案（未实现）|
| **2026-05-24 v2** | **改为独立 chart diting-vllm**：①命令 `make up-stack diting-vllm`②release `diting-infer` -n infer③NAS RO 挂载防误写④**连跑多 dim 保留节点**（DECISION 默认 keep_node=true · 省 5min × N）⑤加 §3.5 G/V/H/R/C 17 项矩阵 |
