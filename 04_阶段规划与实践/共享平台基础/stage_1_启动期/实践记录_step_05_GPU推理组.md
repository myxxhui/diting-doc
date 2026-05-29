# L4 · 共享平台基础 · 启动期 · 实践记录 step_05 GPU 推理组按需 Up · diting-vllm chart（v2）

> **状态**：⏳ 待执行 · 按需触发（step_04 训完 ≥1 LoRA 或 D1 step_07 三引擎部署）

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[step_05_GPU推理组按需Up](../../../03_原子目标与规约/共享平台基础/stages/stage_1_启动期/steps/step_05_GPU推理组按需Up.md)
> - **DNA**：`dna_shared_platform_baseline.yaml#steps.p_step_05`
> - **L5**：[`02_验收标准.md#l5-shared-platform-baseline-step05`](../../../05_成功标识与验证/02_验收标准.md)
> - **上游**：← [实践记录_step_04_GPU训练组](./实践记录_step_04_GPU训练组.md)
> - **下游**：→ [实践记录_step_06_三档释放纪律](./实践记录_step_06_三档释放纪律.md)

## 一、本步骤目标

按 L3 设计完成：①新建 `charts/diting-vllm/` chart；②`make up-stack diting-vllm` 起 GPU infer ECS（同 train 规格 · label=infer）；③helm install `diting-infer -n infer` 起 vLLM Deployment（multi-LoRA 从 NAS `/lora/` 加载）；④`/v1/models` 含 base + ≥1 adapter；⑤D5 step_05 真 Holdout 评测（节点保留连跑多 dim）；⑥评完 `make down-stack diting-vllm` 销节点。

## 二、实际进展（**待执行时覆盖**）

| 项 | 状态 | 证据 |
|----|------|------|
| GPU infer ECS Spot ID + 抢价 | ⏳ | `terraform state show 'alicloud_instance.stack["infer"]'` |
| vLLM Deployment Ready + GPU 用上 | ⏳ | `kubectl wait --for=condition=available deployment/diting-infer -n infer` + nvidia-smi |
| `/v1/models` 返回 base + adapters | ⏳ | `kubectl exec -n infer deploy/diting-infer -- curl -s localhost:8000/v1/models | jq '.data[].id'` |
| Holdout 真评测多 dim（节点保留）| ⏳ | `for d in cryo thrust narrative; do make holdout DIM=$d BACKEND=vllm; done` 报告 |
| 非 fallback 验证（inference_mode=vllm）| ⏳ | grep Holdout 报告 |
| 本轮跑时（小时）+ 成本（¥）| ⏳ | `make platform-step05-cost-snapshot` |
| down 后永驻仍在 | ⏳ | `terraform output vpc_id nas_id` |

## 三、命令与输出摘要

（待执行时填）

## 四、DECISION_PENDING 与 SKIP_REASON

| 项 | 类型 | 说明 | 建议 |
|----|------|------|------|
| 连跑多 dim 是否保留节点 | DECISION_PENDING | 默认 keep_node_for_multi_dim=true（省 5min×N 启动）| 保留 ✅ |
| 是否切 gn7i | DECISION_PENDING | 快 50% 但贵 50% · 启动期不需 | 启动期 gn6i |
| `BLOCKED(no_lora_weight)` | SKIP_REASON 例 | 回 step_04 训完 or 仅 base serve | 标 L4 BLOCKED |
| `BLOCKED(vllm_oom)` | SKIP_REASON 例 | 调小 --max-loras / 切 7B | 标 L4 BLOCKED |

## 五、准出复核

- [ ] §3.5 G1~G4, V1~V5, H1, R1~R4 共 14 项必 ✅
- [ ] 至少 1 dim 真 Holdout 评测（vllm 模式 · 非 fallback）
- [ ] down-stack 后 infer ECS 销 · 永驻 10 项全在
- [ ] 本轮成本 ≤ ¥15
- [ ] L5 `l5-shared-platform-baseline-step05` ✅

## 六、修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-24 | 占位创建 |
| **2026-05-24 v2** | **改用 diting-vllm chart**：①release `diting-infer` -n infer②NAS RO 挂载③**连跑多 dim 保留节点**④down 保留永驻 10 项 |
