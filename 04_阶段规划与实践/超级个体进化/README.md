# L4 · 超级个体进化

> [!NOTE] **[TRACEBACK]**
> - **L3**：[03_/超级个体进化/](../../03_原子目标与规约/超级个体进化/)
> - **DNA**：[`_System_DNA/super_evo/`](../../03_原子目标与规约/_System_DNA/super_evo/)
> - **关联战略**："闭环反哺与数字分身"（The Cognitive Cloner）

## 阶段索引

| # | stage_id | milestone | 阶段文档 | L5 锚点 |
|---|----------|-----------|----------|---------|
| 1 | `super_evo_mvp` | mvp | [01_MVP_本阶段实践与验证.md](./01_MVP_本阶段实践与验证.md) | `l5-pillar-evo-mvp` |
| 2 | `super_evo_v1_eval` | v1 | [02_V1_eval_本阶段实践与验证.md](./02_V1_eval_本阶段实践与验证.md) | `l5-pillar-evo-v1-eval` |
| 3 | `super_evo_v1_retro` | v1 | [03_V1_retro_本阶段实践与验证.md](./03_V1_retro_本阶段实践与验证.md) | `l5-pillar-evo-v1-retro` |
| 4 | `super_evo_v1_version` | v1 | [04_V1_version_本阶段实践与验证.md](./04_V1_version_本阶段实践与验证.md) | `l5-pillar-evo-v1-version` |
| 5 | `super_evo_v2_online` | v2 | [05_V2_online_本阶段实践与验证.md](./05_V2_online_本阶段实践与验证.md) | `l5-pillar-evo-v2-online` |

## 关键最佳实践目标
- 把每一次决策 / 反馈 / 复盘转化为系统肌肉记忆
- 数据闭环 → SFT/DPO 微调 → 评测 → 灰度 → 上线 → 观测 → 复盘
- 推荐技术栈：LLaMA-Factory（SFT/LoRA/DPO 流水线）+ TRL + vLLM（推理）+ Argo Workflows（流水线）+ MLflow（实验追踪）

## AI 实践最佳推荐模型
| 用途 | 推荐模型 | 一句理由 |
|------|---------|---------|
| 数据合成 / 蒸馏 | Claude Sonnet 4 + GPT-5（教师）| 高质标签产出 |
| 评测官 LLM-as-Judge | Claude Sonnet 4 / GPT-5 | 严格遵循 rubric |
| 微调编排脚本 | Cursor 默认模型 | 跨语言友好 |
| 数据集质检 | DeepSeek-V3 | 性价比 |
| **维护责任**：架构师 + ML 工程师每月复审 |
