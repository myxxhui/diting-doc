# L4 · 纵深进攻 · 02 V1 多 Agent 议会 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[纵深进攻/05_实施推演_设计.md#三v1完整能力](../../03_原子目标与规约/纵深进攻/05_实施推演_设计.md#三v1完整能力)
> - **DNA**：[`dna_deep_strike_v1_council.yaml`](../../03_原子目标与规约/_System_DNA/deep_strike/dna_deep_strike_v1_council.yaml)
> - **L5 准出**：[`02_验收标准.md#l5-pillar-deep-v1-council`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-deep-v1-council)

<a id="l4-deep-v1-council-goal"></a>
## 一、本阶段目标
- **stage_id**: `deep_strike_v1_council`
- **工作目录**: `diting-src/diting/deep_strike/council/`
- **依赖**: `deep_strike_mvp`
- **里程碑**: MoE Router + 多 Agent 协作 + 事件触发议程 + 用户实时议题

## 二、本步骤落实的 DNA 键
- `moe_router`：按议题难度路由专家（含 Claude/GPT/DeepSeek 等）
- `multi_agent_collaboration_with_voting`：投票 + 共识聚合 + dissent 记录
- `event_triggered_agenda`：数据层 webhook → 议程
- `user_live_topic_e2e`：用户提问 → 议程 → 议会 → 卡片

## 三、实施内容（5D）
1. Agent 框架 PoC（LangGraph）+ 性能基准
2. MoE Router 实现 + 配置中心化（按议题特征 → 专家）
3. 多 Agent 投票与共识聚合 + Dissent 记录
4. 事件触发议程（消费 cryo_guard 风险事件 + 数据层重大事件）
5. 投研对话台 → 议程接入（chat-bff）
6. tool_call 全链路记录到 `tool_calls` 表

## 四、可执行验证清单
| 命令 | 工作目录 | 期望 |
|------|---------|------|
| `make test-deep-strike-council` | diting-src | exit 0；MoE 路由准确率 ≥ 80% |
| `make e2e-user-live-topic` | diting-src | P50 < 30s；P99 < 120s |
| `make e2e-event-triggered-agenda` | diting-src | 事件 → 议程 → 卡片端到端 < 60s |

## 五、准出检查清单
- [ ] 用户议题响应 P50 < 30s
- [ ] 3+ Agent 投票 → 共识聚合通过端到端测试
- [ ] tool_call 100% 入表
- [ ] **已更新 [`02_验收标准.md#l5-pillar-deep-v1-council`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-deep-v1-council)**

<a id="l4-deep-v1-council-exit"></a>
## 六、L5 准出锚点
`l5-pillar-deep-v1-council`

## 七、本步骤失败时
- Agent 失败 → 转规则路径 + degraded=true
- 同 [极寒防御/01_MVP §七](../极寒防御/01_MVP_本阶段实践与验证.md#七本步骤失败时)

## 八、上一步 / 下一步
- **上一步**：[01_MVP](./01_MVP_本阶段实践与验证.md)
- **下一步**：[03_V1_feature](./03_V1_feature_本阶段实践与验证.md)
