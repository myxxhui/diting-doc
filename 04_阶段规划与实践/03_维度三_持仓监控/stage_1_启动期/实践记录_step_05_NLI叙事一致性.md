# L4 · 维度三持仓监控 · 启动期 · 实践记录 step_05 NLI 叙事一致性 LoRA

> **状态**：✅ tier-1 完成（2026-05-25）；tier-2 BLOCKED(gpu_unavailable)

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[step_05_叙事一致性NLI_LoRA.md](../../../03_原子目标与规约/03_维度三_持仓监控/stages/stage_1_启动期/steps/step_05_叙事一致性NLI_LoRA.md)
> - **DNA**：`narrative_nli_lora` 训练配置 + 降级客户端
> - **L5**：`02_验收标准.md#l5-stage-watch_05`
> - **上游**：← step_04 探针调度器 / **下游**：→ step_06 health_change 集成

## 一、本步骤目标

实现 `NarrativeNLIClient`（vLLM + 降级模式），准备 NLI LoRA 训练数据 ≥150 条（train / dev / holdout），配置 LLaMA-Factory 训练 config，Makefile 合约绿。

## 二、实际进展（2026-05-25 W5）

| 项 | 状态 | 证据 |
|----|------|------|
| `apps/state_watch/health/narrative_nli.py` | ✅ | `NarrativeNLIClient` + degraded 模式 |
| `training/data/narrative_nli/train.jsonl` | ✅ | **148 条**（超 100 门槛） |
| `training/data/narrative_nli/dev.jsonl` | ✅ | 20 条 |
| `training/data/narrative_nli/holdout.jsonl` | ✅ | 30 条 |
| 标签分布 | ✅ | entailment 77 / neutral 27 / contradiction 44 |
| `training/configs/narrative_nli_lora.yaml` | ✅ | LLaMA-Factory Qwen2.5-7B-Instruct |
| `training/scripts/train_nli.sh` | ✅ | GPU 检查 + llamafactory-cli |
| `pytest tests/state_watch/test_narrative_nli.py` | ✅ | **11 passed** |
| `make watch-step05-all` | ✅ | prep + data-check + pytest 全绿 |
| NLI LoRA 真实训练（watch-step05-train）| ⏳ | **BLOCKED(gpu_unavailable)**：等 P-step_04 Spot 回流 |

## 三、命令与输出摘要

```
make watch-step05-all
  train=148  dev=20  holdout=30  total=198
  标签分布: {entailment:77, neutral:27, contradiction:44}
✅ 数据质量检查通过
  11 passed in 0.02s
✅ [watch-step05-all] D3 step_05 tier-1 准出
  BLOCKED(gpu_unavailable): watch-step05-train 需 GPU，tier-2 走 P-step_04
```

## 四、DECISION_PENDING 与 SKIP_REASON

| 项 | 类型 | 说明 |
|----|------|------|
| `watch-step05-train` NLI LoRA 训练 | SKIP_REASON | `BLOCKED(gpu_unavailable)`：diting-training Spot SoldOut |
| Holdout 准确率 ≥80% | SKIP_REASON | 依赖训练完成；等 P-step_04 成功 |

## 五、准出复核（tier-1）

- [x] `NarrativeNLIClient` degraded 模式返回 `label=degraded`，不伪造 entailment/neutral
- [x] train ≥100 / dev ≥20 / holdout ≥30 全满足
- [x] 标签分布三类均有
- [x] pytest 11 passed（含 no-mock stub 规则守卫）
- [x] `make watch-step05-all` 退码 0
- [ ] tier-2：NLI LoRA 训练 + Holdout ≥80%（等 GPU）

## 六、修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-25 | W5 tier-1 完成：148 条数据 + 降级客户端 + pytest 11 passed；BLOCKED(gpu_unavailable) 已记录 |
