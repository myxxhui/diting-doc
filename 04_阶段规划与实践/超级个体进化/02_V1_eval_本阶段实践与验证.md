# L4 · 超级个体进化 · 02 V1 评测中枢 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[超级个体进化/05_实施推演_设计.md#三v1完整能力](../../03_原子目标与规约/超级个体进化/05_实施推演_设计.md#三v1完整能力)
> - **DNA**：[`dna_super_evo_v1_eval.yaml`](../../03_原子目标与规约/_System_DNA/super_evo/dna_super_evo_v1_eval.yaml)
> - **L5 准出**：[`02_验收标准.md#l5-pillar-evo-v1-eval`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-evo-v1-eval)

<a id="l4-evo-v1-eval-goal"></a>
## 一、本阶段目标
- **stage_id**: `super_evo_v1_eval`
- **工作目录**: `diting-src/diting/super_evo/eval_center/`
- **依赖**: `super_evo_mvp`, `deep_strike_v1_eval`
- **里程碑**: eval_datasets 治理 + 多评测官 + 评测报告中心 + 与议会对接

## 二、本步骤落实的 DNA 键
- `eval_dataset_governance`：版本化 + 签名 + 防污染
- `multi_judge_strategies`：rule + llm + human
- `eval_report_center`：可视化看板
- `integration_with_deep_strike`：评测结果同步议会"灰度对照"

## 三、实施内容（5D）
1. eval_datasets 表 + 数据集 CRUD + 签名
2. evaluator runner pool（rule/llm/human 三类）
3. eval_reports 聚合 + 排行榜
4. Webhook → 议会"灰度对照"看板
5. 评测集污染防护（cross-leak detector）

## 四、可执行验证清单
| 命令 | 工作目录 | 期望 |
|------|---------|------|
| `make test-eval-center` | diting-src | exit 0 |
| `make eval-pollution-check` | diting-src | 无评测集污染 |
| `make multi-judge-bench` | diting-src | 三类 judge 并行跑通 |

## 五、准出检查清单
- [ ] 数据集签名校验
- [ ] 多评测官并行
- [ ] 评测报告与议会同步
- [ ] **已更新 [`02_验收标准.md#l5-pillar-evo-v1-eval`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-evo-v1-eval)**

<a id="l4-evo-v1-eval-exit"></a>
## 六、L5 准出锚点
`l5-pillar-evo-v1-eval`

## 七、本步骤失败时
- judge 不一致 → 触发人工复评 + 记录 dispute
- 同 [极寒防御/01_MVP §七](../极寒防御/01_MVP_本阶段实践与验证.md#七本步骤失败时)

## 八、上一步 / 下一步
- **上一步**：[01_MVP](./01_MVP_本阶段实践与验证.md)
- **下一步**：[03_V1_retro](./03_V1_retro_本阶段实践与验证.md)
