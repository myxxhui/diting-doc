# L4 · 超级个体进化 · 05 V2 在线持续学习 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[超级个体进化/05_实施推演_设计.md#四v2生产稳态](../../03_原子目标与规约/超级个体进化/05_实施推演_设计.md#四v2生产稳态)
> - **DNA**：[`dna_super_evo_v2.yaml`](../../03_原子目标与规约/_System_DNA/super_evo/dna_super_evo_v2.yaml)
> - **L5 准出**：[`02_验收标准.md#l5-pillar-evo-v2-online`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-evo-v2-online)

<a id="l4-evo-v2-online-goal"></a>
## 一、本阶段目标
- **stage_id**: `super_evo_v2_online`
- **工作目录**: `diting-src/diting/super_evo/`
- **依赖**: `super_evo_v1_version`, `super_evo_v1_eval`, `super_evo_v1_retro`
- **里程碑**: 在线持续学习 + DPO/RLHF + 多模型 MoE 微调 + 安全防护 + 自动数据标注流水线

## 二、本步骤落实的 DNA 键
- `online_continual_learning`：增量训练管线
- `dpo_rlhf_pipeline`：人类偏好对齐
- `multi_model_moe_finetune`：多 LoRA 共训 + 路由学习
- `safety_guards`：训练前后毒性 / 越权检测
- `auto_labeling_pipeline`：教师模型蒸馏 + 人工抽检

## 三、实施内容（5D）
1. online learning（按窗口增量更新；防灾难性遗忘）
2. DPO 流水线（成对偏好数据 → TRL）
3. MoE 多 LoRA 共训
4. 安全检测（毒性 / 越权 / 长尾失败模式）
5. auto labeling（教师蒸馏 + 抽检）

## 四、可执行验证清单
| 命令 | 工作目录 | 期望 |
|------|---------|------|
| `make test-online-learning` | diting-src | exit 0；遗忘率指标达标 |
| `make dpo-pipeline-bench` | diting-src | 偏好对齐指标 ≥ baseline |
| `make safety-guard-bench` | diting-src | 毒性 / 越权 检出 ≥ 95% |
| `make auto-label-pipeline-bench` | diting-src | 标注质量抽检通过率 ≥ 90% |

## 五、准出检查清单
- [ ] 在线学习不引发回归
- [ ] DPO 偏好对齐有效
- [ ] 安全防护通过
- [ ] **已更新 [`02_验收标准.md#l5-pillar-evo-v2-online`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-evo-v2-online)**

<a id="l4-evo-v2-online-exit"></a>
## 六、L5 准出锚点
`l5-pillar-evo-v2-online`

## 七、本步骤失败时
- 在线学习引发回归 → 自动暂停 + 回滚 + lineage 复盘
- 同 [极寒防御/01_MVP §七](../极寒防御/01_MVP_本阶段实践与验证.md#七本步骤失败时)

## 八、上一步 / 下一步
- **上一步**：[04_V1_version](./04_V1_version_本阶段实践与验证.md)
- **下一步**：本模块完结
