# L4 · 状态机监控 · 03 V1 与极寒防御联动 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[状态机监控/05_实施推演_设计.md#三v1完整能力](../../03_原子目标与规约/状态机监控/05_实施推演_设计.md#三v1完整能力)
> - **DNA**：[`dna_state_watch_v1_gate.yaml`](../../03_原子目标与规约/_System_DNA/state_watch/dna_state_watch_v1_gate.yaml)
> - **L5 准出**：[`02_验收标准.md#l5-pillar-watch-v1-gate`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-watch-v1-gate)

<a id="l4-watch-v1-gate-goal"></a>
## 一、本阶段目标
- **stage_id**: `state_watch_v1_gate`
- **工作目录**: `diting-src/diting/state_watch/advisory/`
- **依赖**: `state_watch_mvp`, `cryo_guard_v1`
- **里程碑**: Advisory 必经极寒防御 decision_gate；缺 evidence/fallback 被拒

## 二、本步骤落实的 DNA 键
- `advisory_with_evidence_and_fallback`：必填 evidence + fallback
- `integration_with_cryo_guard_decision_gate`：Advisory 同步走门禁

## 三、实施内容（5D）
1. Advisory 数据结构补齐 evidence 与 fallback 字段（schema_version 升）
2. AdvisoryGenerator → CryoGuard decision_gate 客户端
3. 缺字段或 reject 时的回退（实例进 ARCHIVED + 复盘）
4. 端到端审计链验证

## 四、可执行验证清单
| 命令 | 工作目录 | 期望 |
|------|---------|------|
| `make test-state-watch-gate` | diting-src | exit 0 |
| `make e2e-advisory-gate` | diting-src | 缺 evidence/fallback Advisory 被门禁 reject |
| `make audit-chain-watch-advisory` | diting-src | 审计链完整 |

## 五、准出检查清单
- [ ] 缺 evidence 或 fallback 的 Advisory 被门禁 reject
- [ ] 端到端审计链完整
- [ ] **已更新 [`02_验收标准.md#l5-pillar-watch-v1-gate`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-watch-v1-gate)**

<a id="l4-watch-v1-gate-exit"></a>
## 六、L5 准出锚点
`l5-pillar-watch-v1-gate`

## 七、本步骤失败时
- 门禁连接失败：Advisory 暂存 + 重试；超时则触发 RiskEvent
- 同 [极寒防御/01_MVP §七](../极寒防御/01_MVP_本阶段实践与验证.md#七本步骤失败时)

## 八、上一步 / 下一步
- **上一步**：[02_V1_probe](./02_V1_probe_本阶段实践与验证.md)
- **下一步**：[04_V1_budget](./04_V1_budget_本阶段实践与验证.md)
