# L4 · 前端工程与服务 · 02 V1 全功能 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[前端工程与服务/05_实施推演_设计.md#三v1完整能力](../../03_原子目标与规约/前端工程与服务/05_实施推演_设计.md#三v1完整能力)
> - **DNA**：[`dna_frontend_v1_full.yaml`](../../03_原子目标与规约/_System_DNA/frontend/dna_frontend_v1_full.yaml)
> - **L5 准出**：[`02_验收标准.md#l5-frontend-v1-full`](../../05_成功标识与验证/02_验收标准.md#l5-frontend-v1-full)

<a id="l4-frontend-v1-full-goal"></a>
## 一、本阶段目标
- **stage_id**: `frontend_v1_full`
- **工作目录**: `diting-src/web/`
- **依赖**: `frontend_mvp`, 各模块 V1 阶段
- **里程碑**: Console 全功能 + Admin + 投研工作台 + 完整 BFF + 性能预算 + i18n + 可观测性

## 二、本步骤落实的 DNA 键
- `apps_full`：console + admin + chat-bff + ws-gateway
- `bff_full`：read aggregation + workflow_orchestration + sse / ws fanout
- `performance_budget`：LCP / INP / CLS / TTFB / JS bundle
- `i18n`：zh-CN + en-US
- `wcag_2_1_aa`
- `observability_full`：RUM + dashboards + 三类慢请求归因

## 三、实施内容（5D）
1. admin app + 角色 / 权限矩阵
2. 投研工作台（议会 / 状态机 / 审计三屏联动）
3. ws-gateway 单实例 → 多实例（一致性 hash）
4. BFF 完整：read 聚合 + workflow + fanout
5. i18n（next-intl）+ a11y 巡检
6. 性能预算 + bundle 分析 + lazy 拆包
7. 完整可观测：RUM、Dashboard、慢请求归因

## 四、可执行验证清单
| 命令 | 工作目录 | 期望 |
|------|---------|------|
| `pnpm test:v1` | diting-src/web | exit 0；覆盖率 ≥ 80% |
| `pnpm e2e:v1` | diting-src/web | 7 主流程 + 3 失败回退通过 |
| `pnpm lighthouse:strict` | diting-src/web | LCP < 2.5s；INP < 200ms；CLS < 0.1 |
| `pnpm a11y` | diting-src/web | WCAG 2.1 AA 0 critical |

## 五、准出检查清单
- [ ] 全 5 模块全功能可用
- [ ] 性能预算达标
- [ ] WCAG 2.1 AA 通过
- [ ] **已更新 [`02_验收标准.md#l5-frontend-v1-full`](../../05_成功标识与验证/02_验收标准.md#l5-frontend-v1-full)**

<a id="l4-frontend-v1-full-exit"></a>
## 六、L5 准出锚点
`l5-frontend-v1-full`

## 七、本步骤失败时
- 性能或可访问性回归 → 阻断发布；先修复
- 同 [极寒防御/01_MVP §七](../极寒防御/01_MVP_本阶段实践与验证.md#七本步骤失败时)

## 八、上一步 / 下一步
- **上一步**：[01_MVP](./01_MVP_本阶段实践与验证.md)
- **下一步**：[03_V2_pwa](./03_V2_pwa_本阶段实践与验证.md)
