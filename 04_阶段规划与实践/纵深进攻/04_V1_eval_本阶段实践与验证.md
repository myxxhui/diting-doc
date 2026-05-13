# L4 · 纵深进攻 · 04 V1 失败兜底与评测 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[纵深进攻/05_实施推演_设计.md#三v1完整能力](../../03_原子目标与规约/纵深进攻/05_实施推演_设计.md#三v1完整能力)
> - **DNA**：[`dna_deep_strike_v1_eval.yaml`](../../03_原子目标与规约/_System_DNA/deep_strike/dna_deep_strike_v1_eval.yaml)
> - **L5 准出**：[`02_验收标准.md#l5-pillar-deep-v1-eval`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-deep-v1-eval)

<a id="l4-deep-v1-eval-goal"></a>
## 一、本阶段目标
- **stage_id**: `deep_strike_v1_eval`
- **工作目录**: `diting-src/diting/deep_strike/`
- **依赖**: `deep_strike_v1_council`, `super_evo_v1_eval`
- **里程碑**: 推理熔断时规则路径覆盖 + 评测集自动跑

## 二、本步骤落实的 DNA 键
- `fallback_rule_paths`：推理熔断时议题仍能输出
- `eval_dataset_and_runner`：与 super_evo `eval_center` 对接

## 三、实施内容（5D）
1. 规则路径库（按议题分类）+ 失败时自动切换 + degraded=true
2. 评测集（先期 200 题）→ 上传到 super_evo eval_datasets
3. 评测任务 cron（每周）→ 触发 super_evo eval_runner
4. 评测报告自动同步到议会"灰度对照"看板

## 四、可执行验证清单
| 命令 | 工作目录 | 期望 |
|------|---------|------|
| `make test-deep-strike-eval` | diting-src | exit 0 |
| `make redteam-deep-strike-fallback` | diting-src | 推理熔断时 ≥ 95% 议题仍能输出 |
| `make weekly-eval-dryrun` | diting-src | 评测报告生成；指标 ≥ baseline |

## 五、准出检查清单
- [ ] 推理熔断时 ≥ 95% 议题仍能输出
- [ ] 每周评测自动跑并报告至超级个体进化
- [ ] **已更新 [`02_验收标准.md#l5-pillar-deep-v1-eval`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-deep-v1-eval)**

<a id="l4-deep-v1-eval-exit"></a>
## 六、L5 准出锚点
`l5-pillar-deep-v1-eval`

## 七、本步骤失败时
- 评测集污染：evals 数据集签名校验 + 多版本对照；不混入正式版本
- 同 [极寒防御/01_MVP §七](../极寒防御/01_MVP_本阶段实践与验证.md#七本步骤失败时)

## 八、上一步 / 下一步
- **上一步**：[03_V1_feature](./03_V1_feature_本阶段实践与验证.md)
- **下一步**：[05_V2_runtime](./05_V2_runtime_本阶段实践与验证.md)
