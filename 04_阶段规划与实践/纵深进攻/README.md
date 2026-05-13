# L4 · 纵深进攻

> [!NOTE] **[TRACEBACK]**
> - **L3**：[03_/纵深进攻/](../../03_原子目标与规约/纵深进攻/)
> - **DNA**：[`_System_DNA/deep_strike/`](../../03_原子目标与规约/_System_DNA/deep_strike/)
> - **关联战略**："产业链暗网与动量折现"（The Deep-Chain Momentum Harvester）

## 阶段索引

| # | stage_id | milestone | 阶段文档 | L5 锚点 |
|---|----------|-----------|----------|---------|
| 1 | `deep_strike_mvp` | mvp | [01_MVP_本阶段实践与验证.md](./01_MVP_本阶段实践与验证.md) | `l5-pillar-deep-mvp` |
| 2 | `deep_strike_v1_council` | v1 | [02_V1_council_本阶段实践与验证.md](./02_V1_council_本阶段实践与验证.md) | `l5-pillar-deep-v1-council` |
| 3 | `deep_strike_v1_feature` | v1 | [03_V1_feature_本阶段实践与验证.md](./03_V1_feature_本阶段实践与验证.md) | `l5-pillar-deep-v1-feature` |
| 4 | `deep_strike_v1_eval` | v1 | [04_V1_eval_本阶段实践与验证.md](./04_V1_eval_本阶段实践与验证.md) | `l5-pillar-deep-v1-eval` |
| 5 | `deep_strike_v2_runtime` | v2 | [05_V2_runtime_本阶段实践与验证.md](./05_V2_runtime_本阶段实践与验证.md) | `l5-pillar-deep-v2-runtime` |

## 关键最佳实践目标
- 把高维碎片压成有解释、有证据的研究结论
- 议会输出 100% 自带证据链 + 置信度 + 失败兜底
- 推荐技术栈：LangGraph（议会编排）+ vLLM（推理网关）+ Milvus / pgvector（嵌入索引）+ Feast（特征仓库可选）

## AI 实践最佳推荐模型
| 用途 | 推荐模型 | 一句理由 |
|------|---------|---------|
| Agent 编排 / 议会内推理 | Claude Sonnet 4 + GPT-5 + DeepSeek-V3 三选一（按议题难度） | MoE Router 按难度分配 |
| 内容理解（NER / 事件抽取） | DeepSeek-V3 / 豆包 | 中文公告 / 研报性价比高 |
| 嵌入模型 | bge-m3 / text-embedding-3-large | 中英混合 |
| 工具调用脚手架 | Claude Sonnet 4 | LangGraph 友好 |
| **维护责任**：架构师 + 投研团队每月复审 |
