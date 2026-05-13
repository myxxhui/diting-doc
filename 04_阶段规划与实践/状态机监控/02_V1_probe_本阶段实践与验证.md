# L4 · 状态机监控 · 02 V1 多探针与自适应 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[状态机监控/05_实施推演_设计.md#三v1完整能力](../../03_原子目标与规约/状态机监控/05_实施推演_设计.md#三v1完整能力)
> - **DNA**：[`dna_state_watch_v1_probe.yaml`](../../03_原子目标与规约/_System_DNA/state_watch/dna_state_watch_v1_probe.yaml)
> - **L5 准出**：[`02_验收标准.md#l5-pillar-watch-v1-probe`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-watch-v1-probe)

<a id="l4-watch-v1-probe-goal"></a>
## 一、本阶段目标
- **stage_id**: `state_watch_v1_probe`
- **工作目录**: `diting-src/diting/state_watch/probe/`
- **依赖**: `state_watch_mvp`
- **里程碑**: 多类探针（行情/新闻/衍生）+ 自适应频率 + 越界保护带

## 二、本步骤落实的 DNA 键
- `probe_news_realtime`：流式触发
- `probe_derivative`：事件 / 特征
- `adaptive_frequency`：高活跃缩短、低活跃拉长
- `guards_hard_and_soft`：硬阈值 + 软趋势

## 三、实施内容（5D）
1. 新闻探针（消费 Kafka 事件流 → 实例触发）
2. 衍生探针（订阅 super_evo eval 结果 / 数据层事件）
3. 自适应频率算法（基于近 N 次迁移密度）
4. 越界保护带（hard threshold + soft trend）+ 触发动作
5. SLI Breaker / Narrative Drift Corrector 配置示例（参考 [战略文档 §模型 1/3]）

## 四、可执行验证清单
| 命令 | 工作目录 | 期望 |
|------|---------|------|
| `make test-state-watch-probe` | diting-src | exit 0 |
| `make adaptive-frequency-bench` | diting-src | 高活跃 interval 缩短；低活跃拉长 |
| `make guards-breach-bench` | diting-src | hard / soft 阈值都能触发 |

## 五、准出检查清单
- [ ] 实时新闻可触发迁移
- [ ] 高活跃实例 interval 自动缩短
- [ ] 越界保护带 hard / soft 全部生效
- [ ] **已更新 [`02_验收标准.md#l5-pillar-watch-v1-probe`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-watch-v1-probe)**

<a id="l4-watch-v1-probe-exit"></a>
## 六、L5 准出锚点
`l5-pillar-watch-v1-probe`

## 七、本步骤失败时
- 探针失败 N 次 → 标记 unhealthy + 通知极寒防御
- 同 [极寒防御/01_MVP §七](../极寒防御/01_MVP_本阶段实践与验证.md#七本步骤失败时)

## 八、上一步 / 下一步
- **上一步**：[01_MVP](./01_MVP_本阶段实践与验证.md)
- **下一步**：[03_V1_gate](./03_V1_gate_本阶段实践与验证.md)
