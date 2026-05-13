# L4 · 状态机监控 · 04 V1 通知预算 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[状态机监控/05_实施推演_设计.md#三v1完整能力](../../03_原子目标与规约/状态机监控/05_实施推演_设计.md#三v1完整能力)
> - **DNA**：[`dna_state_watch_v1_budget.yaml`](../../03_原子目标与规约/_System_DNA/state_watch/dna_state_watch_v1_budget.yaml)
> - **L5 准出**：[`02_验收标准.md#l5-pillar-watch-v1-budget`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-watch-v1-budget)

<a id="l4-watch-v1-budget-goal"></a>
## 一、本阶段目标
- **stage_id**: `state_watch_v1_budget`
- **工作目录**: `diting-src/diting/state_watch/notification/`
- **依赖**: `state_watch_v1_probe`, `state_watch_v1_gate`, `deep_strike_mvp`
- **里程碑**: 通知预算 + digest + 与纵深进攻候选 active 联动 + SSE + OpenSearch

## 二、本步骤落实的 DNA 键
- `notification_budget_with_digest`：超预算合并为 digest
- `integration_with_deep_strike_candidate_active`：候选 active → 自动拉起实例
- `sse_realtime`：浏览器实时
- `opensearch_indexer`：检索 P99 < 1s

## 三、实施内容（5D）
1. 通知预算策略实现（按用户角色配额；高严重度 bypass）
2. digest 合并器（按主题聚合；定时下发）
3. candidate active webhook → 实例自动创建
4. SSE 推送通道
5. OpenSearch indexer for transitions / breaches / advisories

## 四、可执行验证清单
| 命令 | 工作目录 | 期望 |
|------|---------|------|
| `make test-state-watch-budget` | diting-src | exit 0 |
| `make notification-budget-bench` | diting-src | 超预算转 digest |
| `make e2e-candidate-to-instance` | diting-src | 候选 active → 实例创建端到端 |
| `make sse-state-watch-bench` | diting-src | 推送延迟 P99 < 1s |

## 五、准出检查清单
- [ ] 单用户单日通知 ≤ 配置上限；超出走 digest
- [ ] 候选 active → 自动拉起实例
- [ ] SSE 实时通道稳定
- [ ] **已更新 [`02_验收标准.md#l5-pillar-watch-v1-budget`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-watch-v1-budget)**

<a id="l4-watch-v1-budget-exit"></a>
## 六、L5 准出锚点
`l5-pillar-watch-v1-budget`

## 七、本步骤失败时
- 通知通道全失败 → 写"未送达"队列 + RiskEvent
- 同 [极寒防御/01_MVP §七](../极寒防御/01_MVP_本阶段实践与验证.md#七本步骤失败时)

## 八、上一步 / 下一步
- **上一步**：[03_V1_gate](./03_V1_gate_本阶段实践与验证.md)
- **下一步**：[05_V2_template](./05_V2_template_本阶段实践与验证.md)
