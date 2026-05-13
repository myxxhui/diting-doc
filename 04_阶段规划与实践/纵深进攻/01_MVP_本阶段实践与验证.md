# L4 · 纵深进攻 · 01 MVP 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[纵深进攻/05_实施推演_设计.md#二mvp最小可用产品](../../03_原子目标与规约/纵深进攻/05_实施推演_设计.md#二mvp最小可用产品)
> - **DNA**：[`dna_deep_strike_mvp.yaml`](../../03_原子目标与规约/_System_DNA/deep_strike/dna_deep_strike_mvp.yaml)
> - **L5 准出**：[`02_验收标准.md#l5-pillar-deep-mvp`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-deep-mvp)

<a id="l4-deep-mvp-goal"></a>
## 一、本阶段目标
- **stage_id**: `deep_strike_mvp`
- **工作目录**: `diting-src/diting/deep_strike/`
- **依赖**: `cryo_guard_mvp`, `shared_platform_baseline`
- **里程碑**: 议会单 Agent + 候选注册表 + 周期议程 + 基础内容理解 + 与极寒防御门禁对接 + 候选广场 MVP

## 二、本步骤落实的 DNA 键
- `dna_deep_strike_mvp.proto_v1`：5 类 Proto
- `dna_deep_strike_mvp.db_tables`：含 9 张表
- `dna_deep_strike_mvp.agenda.cron_jobs`：daily_market_scan + nightly_news_sweep
- `dna_deep_strike_mvp.council`：单 Agent；`evidence_required=true`；`fallback_required=true`
- `dna_deep_strike_mvp.candidate_registry.on_active_notify=state_watch`

## 三、实施内容（5D）

| # | 步骤 | 5D | 工作目录 |
|---|------|----|---------|
| 1 | Proto v1 + 代码生成 | Design | `diting-src/design/protocols/deep_strike/` |
| 2 | DB 迁移 | Decompose | `diting-src/diting/deep_strike/migrations/` |
| 3 | content_comprehension（基础 NER + 事件 + 主营对齐） | Decompose | `diting-src/diting/deep_strike/comprehension/` |
| 4 | research_council 单 Agent + 推理网关 + 检索工具 | Decompose | `diting-src/diting/deep_strike/council/` |
| 5 | candidate_registry CRUD + 状态流转 | Decompose | `diting-src/diting/deep_strike/candidate_registry/` |
| 6 | agenda_orchestrator 周期 cron | Decompose | `diting-src/diting/deep_strike/agenda/` |
| 7 | 与极寒防御 decision_gate 对接 | Defense | 联调 |
| 8 | 前端"研究候选广场" + "卡片详情" | Defense | `diting-src/web/apps/console/app/(research)/` |

## 四、可执行验证清单
| 命令 | 工作目录 | 期望 |
|------|---------|------|
| `make test-deep-strike-mvp` | diting-src | exit 0 |
| `make smoke-deep-strike-mvp` | diting-src | 周期议程触发 + 候选生成 + 极寒防御门禁通过 |
| `pytest tests/deep_strike/comprehension/ -v` | diting-src | 全通过 |

## 五、准出检查清单
- [ ] 周期议程稳定（每日 ≥ 1 议题）
- [ ] 卡片 100% 含证据链且能被门禁放行
- [ ] Session transcript 可被回放
- [ ] **已更新 [`02_验收标准.md#l5-pillar-deep-mvp`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-deep-mvp)**

<a id="l4-deep-mvp-exit"></a>
## 六、L5 准出锚点
`l5-pillar-deep-mvp`

## 七、本步骤失败时
- 议会输出失败 → 自动转规则路径（degraded=true）；不阻塞门禁
- 同 [极寒防御/01_MVP §七](../极寒防御/01_MVP_本阶段实践与验证.md#七本步骤失败时)

## 八、上一步 / 下一步
- **上一步**：[极寒防御/01_MVP](../极寒防御/01_MVP_本阶段实践与验证.md)
- **下一步**：[02_V1_council](./02_V1_council_本阶段实践与验证.md)
