# Step 06 · Thesis LoRA v1 训练（绑 D5 流水线 + 永久规则训练集）

## §1 一句话定位与本步交付物

**一句话**：用 step_05 产出的 thesis 卡片 + 种子案例（≥100 thesis + ≥100 risk）经 D5 LLaMA-Factory 流水线训练 `thesis_lora_v1`（Qwen2.5-7B rank=16），并含**永久规则负样本**（自动建仓意图 → 输出必须拒识），供 step_07 LoRA 路与 D1 vLLM 热加载。

**交付物**（勾选 = 完成）：
- [ ] **A**（训练数据）：`training/data/deep_strike/thesis_{train,val,test}.json` alpaca；≥100+100 行
- [ ] **B**（永久规则样本）：≥10 条「全仓买入」类 → label 含 `auto_trade_forbidden=true`
- [ ] **C**（LoRA）：`output/thesis_lora_v1/adapter_model.safetensors` >60MB
- [ ] **D**（D5 绑定）：`llamafactory-cli train training/configs/thesis_lora.yaml`；WandB 收敛
- [ ] **E**（完整性回归）：训后 val `batch_completeness` 仍 100%
- [ ] **F**（Makefile）：`make deep-step06-all`

> **硬依赖**：D5 C3 训练流水线 + step_05 卡片；**禁止** mock jsonl 充数。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3 训练**：[../04_模型训练与部署.md](../04_模型训练与部署.md)
> - **DNA**：`training_data_scale`、`deliverables.playbooks[0].lora_name=thesis_lora_v1`
> - **D5**：[05_维度五 step_04 C3](../../../../05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_04_C3_LLaMA_Factory训练流水线.md)
> - **L4**：[实践记录_step_06_Thesis_LoRA训练.md](../../../../../04_阶段规划与实践/02_维度二_纵深进攻/stage_1_启动期/实践记录_step_06_Thesis_LoRA训练.md)
> - **上游**：step_05、D5；**下游**：step_07、09

## §3 数据采集对象 / 落库映射

| 流向 | 路径 |
|---|---|
| `thesis_cards` + seeds | → jsonl |
| 产物 | `output/thesis_lora_v1/` |

## §3.5 数据质量验收矩阵（训练数据 · 仅启动期）

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| D1 | thesis 样本 | ≥100 | ⚠️ | 不足回 step_05/D5 蒸馏 |
| D2 | risk 样本 | ≥100 | ⚠️ | 同上 |
| D3 | output JSON 含 5 必填 | precheck schema | ✅ | 缺字段拒绝 |
| D4 | 永久规则负样本 | ≥10 拒识 | ✅ `permanent_rule_forbidden.jsonl` | — |
| D5 | 无 mock/stub 训练集 | 来自真实卡片或 D5 verified | ✅ | mock 禁止 |
| D6 | 按 symbol 切分 Holdout | 不与评测 symbol 混 | ✅ | — |
| D7 | 训后 completeness | val 100% | ⚠️ | 不达调 epoch/lr |

> 共 **7 项**。

## §4 凭证

`WANDB_API_KEY`、GPU（复用 D1 vLLM 节点）、D5 训练环境。

## §5 启动期目标

| 项 | 值 |
|---|---|
| rank/alpha | 16/32；epochs 3 |
| adapter | >60MB |
| val completeness | 100% |

## §6 下一步

本步 ✅ → step_07 三路置信度（LoRA 路启用）。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A export jsonl** | `export_thesis_training_data.py` | alpaca 三列 | ≥100 |
| **B forbidden 样本** | `data/permanent_rule_forbidden.jsonl` | 10+ 模板 | precheck 含 |
| **C thesis_lora.yaml** | `training/configs/` | 同 D1 超参 | 解析 OK |
| **D precheck** | `precheck_thesis_training.py` | D1~D7 | 0 |
| **E train** | llamafactory-cli | WandB | adapter |
| **F completeness 回归** | generator+LoRA on val | 100% | — |
| **G 单测** | `test_thesis_training_export.py` | ≥5 | — |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `deep-step06-precheck` | 0 |
| `deep-step06-train` | adapter>60MB |
| `deep-step06-completeness` | 100% |
| `deep-step06-all` | 0 |
| `deep-step06-status` | WandB run id |
| `deep-step06-clean` | 清 output 保留 base |

OOM 同 D1 三级降级。

### §7.3 指引

export → precheck → train → completeness；样本不足先补 step_05 或 D5。

## §8 部署节奏

本机 GPU 训练；LoRA 挂 D1 vllm `/loras/thesis/`（step_09 前可本地挂载测试）。

## §9 准出标准

- [ ] §3.5 全过 + adapter + completeness 100% + `make deep-step06-all`
- [ ] L4 + commit

## §10 [Deploy]

vLLM 热加载约定同 D1 step_07；deploy-engine 自检同前。

## §11 依赖

D5 C3、step_05、GPU。**禁止** mock 训练集。

## §12 风险

| 触发 | 动作 |
|---|---|
| 样本不足 | D5 蒸馏 |
| 永久规则漏训 | 补 forbidden |
| completeness 降 | 调参 ≤3 轮 |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2.1 深度补全**：§3.5 7 项；D5 绑定；永久规则负样本；Makefile 6 target；982→~310 行 |
| 2026-05-20 | v2 瘦身 |
| 2026-05-16 | 初版 982 行 |
