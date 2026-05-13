# L4 · 前端工程与服务

> [!NOTE] **[TRACEBACK]**
> - **L3**：[03_/前端工程与服务/](../../03_原子目标与规约/前端工程与服务/)
> - **DNA**：[`_System_DNA/frontend/`](../../03_原子目标与规约/_System_DNA/frontend/)

## 阶段索引

| # | stage_id | milestone | 阶段文档 | L5 锚点 |
|---|----------|-----------|----------|---------|
| 1 | `frontend_mvp` | mvp | [01_MVP_本阶段实践与验证.md](./01_MVP_本阶段实践与验证.md) | `l5-frontend-mvp` |
| 2 | `frontend_v1_full` | v1 | [02_V1_full_本阶段实践与验证.md](./02_V1_full_本阶段实践与验证.md) | `l5-frontend-v1-full` |
| 3 | `frontend_v2_pwa` | v2 | [03_V2_pwa_本阶段实践与验证.md](./03_V2_pwa_本阶段实践与验证.md) | `l5-frontend-v2-pwa` |

## 关键最佳实践目标
- 一站式 SPA / PWA + BFF + 强可观测
- Web Vitals 达标 + WCAG 2.1 AA
- 推荐技术栈：Next.js App Router + pnpm + Turborepo + TanStack Query + Zustand + React Hook Form + Tailwind + Radix + i18n（next-intl）+ Sentry / OTel

## AI 实践最佳推荐模型
| 用途 | 推荐模型 | 一句理由 |
|------|---------|---------|
| 组件 / 页面脚手架 | Cursor 默认模型 | 前端模板生成强 |
| 接口 SDK 自动生成 | Claude Sonnet 4 | OpenAPI / Proto → TS 客户端 |
| BFF 编排 | Claude Sonnet 4 | 服务编排 + 错误处理 |
| 性能优化 / 排障 | GPT-5 | 现场推理强 |
| **维护责任**：架构师 + 前端 Tech Lead 每月复审 |
