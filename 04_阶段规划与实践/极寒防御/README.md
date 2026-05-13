# L4 · 极寒防御

> [!NOTE] **[TRACEBACK]**
> - **L3**：[03_/极寒防御/](../../03_原子目标与规约/极寒防御/)
> - **DNA**：[`_System_DNA/cryo_guard/`](../../03_原子目标与规约/_System_DNA/cryo_guard/) + `dna_dev_workflow.yaml#workflow_stages[pillar=cryo_guard]`
> - **关联战略**："欺诈解构与逻辑验尸"（The Fraud Deconstruction Engine）

## 阶段索引

| # | stage_id | milestone | 阶段文档 | L5 锚点 |
|---|----------|-----------|----------|---------|
| 1 | `cryo_guard_mvp` | mvp | [01_MVP_本阶段实践与验证.md](./01_MVP_本阶段实践与验证.md) | `l5-pillar-cryo-mvp` |
| 2 | `cryo_guard_v1` | v1 | [02_V1_本阶段实践与验证.md](./02_V1_本阶段实践与验证.md) | `l5-pillar-cryo-v1` |
| 3 | `cryo_guard_v2` | v2 | [03_V2_本阶段实践与验证.md](./03_V2_本阶段实践与验证.md) | `l5-pillar-cryo-v2` |

## 关键最佳实践目标

- 不可信不放过；坏环境进入冻结；坏决策不出门
- 任意决策可回放（审计链 + payload_hash）
- 配合 SFT「排雷模型」做"现金流造假 / 高管言行不一"等红线一票否决

## AI 实践最佳推荐模型

| 用途 | 推荐模型 | 一句理由 |
|------|---------|---------|
| 决策门禁规则编写 | Claude Sonnet 4 系列 | 严谨；遵循结构化规则 |
| Proto / Schema 设计 | GPT-5 系列 | 类型推理强 |
| 红队对抗用例生成 | Claude Sonnet 4 + GPT-5 双跑 | 互相挑刺，覆盖更全 |
| 嵌入式 SDK 抽象 | Cursor 默认模型 | 跨语言重构友好 |
| **维护责任**：架构师 + 安全组每季度复审 |
