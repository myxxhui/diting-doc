# L4 · 状态机监控

> [!NOTE] **[TRACEBACK]**
> - **L3**：[03_/状态机监控/](../../03_原子目标与规约/状态机监控/)
> - **DNA**：[`_System_DNA/state_watch/`](../../03_原子目标与规约/_System_DNA/state_watch/)
> - **关联战略**："逻辑的可观测性与衰减模型"（The Thesis State Machine）

## 阶段索引

| # | stage_id | milestone | 阶段文档 | L5 锚点 |
|---|----------|-----------|----------|---------|
| 1 | `state_watch_mvp` | mvp | [01_MVP_本阶段实践与验证.md](./01_MVP_本阶段实践与验证.md) | `l5-pillar-watch-mvp` |
| 2 | `state_watch_v1_probe` | v1 | [02_V1_probe_本阶段实践与验证.md](./02_V1_probe_本阶段实践与验证.md) | `l5-pillar-watch-v1-probe` |
| 3 | `state_watch_v1_gate` | v1 | [03_V1_gate_本阶段实践与验证.md](./03_V1_gate_本阶段实践与验证.md) | `l5-pillar-watch-v1-gate` |
| 4 | `state_watch_v1_budget` | v1 | [04_V1_budget_本阶段实践与验证.md](./04_V1_budget_本阶段实践与验证.md) | `l5-pillar-watch-v1-budget` |
| 5 | `state_watch_v2_template` | v2 | [05_V2_template_本阶段实践与验证.md](./05_V2_template_本阶段实践与验证.md) | `l5-pillar-watch-v2-template` |

## 关键最佳实践目标
- 状态可见 / 变化可知 / 节奏可控 / 建议可解释
- 实现四大退出模型（SLI Breaker / Valuation Overload / Narrative Drift Corrector / Opportunity Cost Router）
- 推荐技术栈：TimescaleDB（probe_results）+ Cron / Faust（探针调度）+ React Flow（前端可视化）

## AI 实践最佳推荐模型
| 用途 | 推荐模型 | 一句理由 |
|------|---------|---------|
| 模板 DSL 生成 | Claude Sonnet 4 | 配置化能力强 |
| 探针实现脚手架 | Cursor 默认模型 | 跨语言支持 |
| Advisory 措辞与降级文案 | DeepSeek-V3 / 豆包 | 中文表达自然 |
| **维护责任**：架构师 + 投研团队每月复审 |
