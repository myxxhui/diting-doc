# L4 · 超级个体进化 · 03 V1 复盘归档与知识库 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[超级个体进化/05_实施推演_设计.md#三v1完整能力](../../03_原子目标与规约/超级个体进化/05_实施推演_设计.md#三v1完整能力)
> - **DNA**：[`dna_super_evo_v1_retro.yaml`](../../03_原子目标与规约/_System_DNA/super_evo/dna_super_evo_v1_retro.yaml)
> - **L5 准出**：[`02_验收标准.md#l5-pillar-evo-v1-retro`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-evo-v1-retro)

<a id="l4-evo-v1-retro-goal"></a>
## 一、本阶段目标
- **stage_id**: `super_evo_v1_retro`
- **工作目录**: `diting-src/diting/super_evo/retrospective/`
- **依赖**: `super_evo_mvp`, `state_watch_v1_budget`, `cryo_guard_v1`
- **里程碑**: 自动复盘归档 + 知识库 + 跨议题学习

## 二、本步骤落实的 DNA 键
- `auto_retrospective_archive`：每日 / 重要事件触发
- `knowledge_base`：抽取关键 lesson 入库
- `cross_topic_recall`：议会下次同类议题主动召回

## 三、实施内容（5D）
1. retrospective_archiver（消费 cryo_guard 审计 + state_watch transitions + deep_strike sessions）
2. knowledge_base schema + lesson 抽取（LLM 提炼 + 人工审核）
3. 给 deep_strike council 提供"召回 API"
4. 周期 review 报告（自动 + 人工标注）

## 四、可执行验证清单
| 命令 | 工作目录 | 期望 |
|------|---------|------|
| `make test-retrospective` | diting-src | exit 0 |
| `make e2e-knowledge-recall` | diting-src | 议会下次同类议题召回 lesson |
| `make weekly-review-report` | diting-src | 报告生成完整 |

## 五、准出检查清单
- [ ] 复盘日报自动生成
- [ ] 知识库可被议会召回
- [ ] **已更新 [`02_验收标准.md#l5-pillar-evo-v1-retro`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-evo-v1-retro)**

<a id="l4-evo-v1-retro-exit"></a>
## 六、L5 准出锚点
`l5-pillar-evo-v1-retro`

## 七、本步骤失败时
- lesson 抽取错误 → 人工审核标记 + 不入库
- 同 [极寒防御/01_MVP §七](../极寒防御/01_MVP_本阶段实践与验证.md#七本步骤失败时)

## 八、上一步 / 下一步
- **上一步**：[02_V1_eval](./02_V1_eval_本阶段实践与验证.md)
- **下一步**：[04_V1_version](./04_V1_version_本阶段实践与验证.md)
