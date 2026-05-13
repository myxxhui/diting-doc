# L4 · 状态机监控 · 01 MVP 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[状态机监控/05_实施推演_设计.md#二mvp最小可用产品](../../03_原子目标与规约/状态机监控/05_实施推演_设计.md#二mvp最小可用产品)
> - **DNA**：[`dna_state_watch_mvp.yaml`](../../03_原子目标与规约/_System_DNA/state_watch/dna_state_watch_mvp.yaml)
> - **L5 准出**：[`02_验收标准.md#l5-pillar-watch-mvp`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-watch-mvp)

<a id="l4-watch-mvp-goal"></a>
## 一、本阶段目标
- **stage_id**: `state_watch_mvp`
- **工作目录**: `diting-src/diting/state_watch/`
- **依赖**: `shared_platform_baseline`
- **里程碑**: 内置 1~2 模板 + 行情探针 + 简单迁移 + Advisory（无门禁）+ 关注列表中心 MVP

## 二、本步骤落实的 DNA 键
- `dna_state_watch_mvp.proto_v1`：6 类 Proto
- `dna_state_watch_mvp.templates_seed`：tmpl_breakout_v1 + tmpl_distress_reversal_v1
- `dna_state_watch_mvp.probe.quote.interval_sec=300`
- `dna_state_watch_mvp.advisory.on_create_call_decision_gate=false`（V1 开）
- `dna_state_watch_mvp.notification.budget_enforced=false`（V1 开）

## 三、实施内容（5D）
1. Proto v1 + 代码生成
2. DB 迁移（含 TimescaleDB hypertable: probe_results）
3. 内置 2 模板（YAML → templates 表）
4. probe_scheduler 行情探针（cron 5min）
5. transition_evaluator 表达式 DSL（白名单 + 沙箱化）
6. advisory_generator 基础（无门禁）
7. notification_dispatcher（push + email）
8. watchlist CRUD
9. 前端"关注列表中心" MVP

## 四、可执行验证清单
| 命令 | 工作目录 | 期望 |
|------|---------|------|
| `make test-state-watch-mvp` | diting-src | exit 0 |
| `make smoke-state-watch-mvp` | diting-src | 实例创建 + 探针 + 迁移 + Advisory + 通知 端到端 |

## 五、准出检查清单
- [ ] 行情触发的迁移 < 10s 在前端可见
- [ ] 通知能投递（push/email）
- [ ] 单元测试覆盖率 ≥ 70%
- [ ] **已更新 [`02_验收标准.md#l5-pillar-watch-mvp`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-watch-mvp)**

<a id="l4-watch-mvp-exit"></a>
## 六、L5 准出锚点
`l5-pillar-watch-mvp`

## 七、本步骤失败时
- 模板加载失败 → 实例锁定 + 触发 RiskEvent
- 同 [极寒防御/01_MVP §七](../极寒防御/01_MVP_本阶段实践与验证.md#七本步骤失败时)

## 八、上一步 / 下一步
- **上一步**：[共享平台基础/01](../共享平台基础/01_本阶段实践与验证.md)
- **下一步**：[02_V1_probe](./02_V1_probe_本阶段实践与验证.md)
