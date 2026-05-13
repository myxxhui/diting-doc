# L4 · 超级个体进化 · 01 MVP 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[超级个体进化/05_实施推演_设计.md#二mvp最小可用产品](../../03_原子目标与规约/超级个体进化/05_实施推演_设计.md#二mvp最小可用产品)
> - **DNA**：[`dna_super_evo_mvp.yaml`](../../03_原子目标与规约/_System_DNA/super_evo/dna_super_evo_mvp.yaml)
> - **L5 准出**：[`02_验收标准.md#l5-pillar-evo-mvp`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-evo-mvp)

<a id="l4-evo-mvp-goal"></a>
## 一、本阶段目标
- **stage_id**: `super_evo_mvp`
- **工作目录**: `diting-src/diting/super_evo/`
- **依赖**: `cryo_guard_mvp`, `deep_strike_mvp`
- **里程碑**: 反馈采集 + 数据集 + 单进程 SFT + 简单评测 + 手动灰度 + 反馈中心 MVP

## 二、本步骤落实的 DNA 键
- `dna_super_evo_mvp.proto_v1`：5 类 Proto
- `dna_super_evo_mvp.feedback_capture`：rating / explicit / implicit
- `dna_super_evo_mvp.training_pipeline.sft_only_local`
- `dna_super_evo_mvp.eval_basic.runner=local;judge=llm`
- `dna_super_evo_mvp.deployment_manual_canary`

## 三、实施内容（5D）
1. Proto v1 + DB 迁移（含 6 张表）
2. feedback_capture（前端按钮 + API + 落 datasets）
3. dataset_curator（去重、对齐 schema、签名）
4. sft trainer（LLaMA-Factory + 单卡 / 单进程）
5. eval runner local（基线题 → judge）
6. deployment_executor 手动灰度（人工触发 vLLM LoRA 切换）
7. 前端"反馈中心" MVP

## 四、可执行验证清单
| 命令 | 工作目录 | 期望 |
|------|---------|------|
| `make test-super-evo-mvp` | diting-src | exit 0 |
| `make e2e-feedback-to-canary` | diting-src | 反馈 → SFT 跑通 → 评测 → 手动灰度 |
| `make smoke-eval-runner` | diting-src | 基线题评测产出报告 |

## 五、准出检查清单
- [ ] 反馈 → 数据 → SFT 跑通
- [ ] 评测产出基础指标
- [ ] 手动灰度可执行
- [ ] **已更新 [`02_验收标准.md#l5-pillar-evo-mvp`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-evo-mvp)**

<a id="l4-evo-mvp-exit"></a>
## 六、L5 准出锚点
`l5-pillar-evo-mvp`

## 七、本步骤失败时
- 训练失败：保留中间产物 + 日志；回退基线模型；通知 ML 工程师
- 同 [极寒防御/01_MVP §七](../极寒防御/01_MVP_本阶段实践与验证.md#七本步骤失败时)

## 八、上一步 / 下一步
- **上一步**：[纵深进攻/01_MVP](../纵深进攻/01_MVP_本阶段实践与验证.md)
- **下一步**：[02_V1_eval](./02_V1_eval_本阶段实践与验证.md)
