# L4 · 前端工程与服务 · 01 MVP 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[前端工程与服务/05_实施推演_设计.md#二mvp最小可用产品](../../03_原子目标与规约/前端工程与服务/05_实施推演_设计.md#二mvp最小可用产品)
> - **DNA**：[`dna_frontend_mvp.yaml`](../../03_原子目标与规约/_System_DNA/frontend/dna_frontend_mvp.yaml)
> - **L5 准出**：[`02_验收标准.md#l5-frontend-mvp`](../../05_成功标识与验证/02_验收标准.md#l5-frontend-mvp)

<a id="l4-frontend-mvp-goal"></a>
## 一、本阶段目标
- **stage_id**: `frontend_mvp`
- **工作目录**: `diting-src/web/`
- **依赖**: `shared_platform_baseline`, `cryo_guard_mvp`, `deep_strike_mvp`, `state_watch_mvp`, `super_evo_mvp`
- **里程碑**: Monorepo + console（4 模块四张面板）+ chat-bff 单实例

## 二、本步骤落实的 DNA 键
- `dna_frontend_mvp.monorepo`：pnpm + Turborepo
- `dna_frontend_mvp.apps`：console + chat-bff
- `dna_frontend_mvp.panels`：风险 / 候选广场 / 关注列表 / 反馈中心 4 个 MVP 面板
- `dna_frontend_mvp.observability_basic`：Sentry + 基础 OTel
- `dna_frontend_mvp.tech_stack`：Next.js + TanStack Query + Zustand + Tailwind + Radix

## 三、实施内容（5D）
1. Monorepo 搭建（pnpm + Turborepo）+ shared / ui-kit / sdk 分包
2. SDK 客户端自动生成（OpenAPI / Proto → TS）
3. console app（4 个面板 MVP）
4. chat-bff（接 deep_strike）
5. WS / SSE 实时通道
6. Sentry + OTel 集成
7. CI（lint + typecheck + test + build + e2e MVP）

## 四、可执行验证清单
| 命令 | 工作目录 | 期望 |
|------|---------|------|
| `pnpm test` | diting-src/web | exit 0；覆盖率 ≥ 70% |
| `pnpm e2e:mvp` | diting-src/web | 4 大面板核心流程通过 |
| `pnpm lighthouse` | diting-src/web | LCP < 3.5s；INP < 300ms |
| `pnpm build` | diting-src/web | 产物体积达标 |

## 五、准出检查清单
- [ ] 4 大面板可被首批用户操作
- [ ] WS 实时风险事件可见
- [ ] SDK 自动生成
- [ ] **已更新 [`02_验收标准.md#l5-frontend-mvp`](../../05_成功标识与验证/02_验收标准.md#l5-frontend-mvp)**

<a id="l4-frontend-mvp-exit"></a>
## 六、L5 准出锚点
`l5-frontend-mvp`

## 七、本步骤失败时
- e2e 失败 → 修复并重试 ≤ 2 次；超出 → 回滚最近发布
- 同 [极寒防御/01_MVP §七](../极寒防御/01_MVP_本阶段实践与验证.md#七本步骤失败时)

## 八、上一步 / 下一步
- **上一步**：所有 MVP 后端阶段
- **下一步**：[02_V1_full](./02_V1_full_本阶段实践与验证.md)
