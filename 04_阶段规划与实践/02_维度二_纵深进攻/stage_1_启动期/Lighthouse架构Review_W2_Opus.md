# Lighthouse-Alpha 架构 Review · W2 Opus 阶段

> **作者**：Claude Opus（W2 实施）
> **日期**：2026-05-23
> **范围**：D2 维度二 Lighthouse 五场景代码骨架 + 状态机边界 + 事件链一致性
> **代码位置**：`diting-src/apps/deep_strike/lighthouse/`

[TRACEBACK]
- **L1 哲学**：[06_投资哲学体系总纲 §基石⑥ 物理证伪 ≥ 财务证伪](../../../01_顶层概念/06_投资哲学体系总纲.md)
- **L2 实践规划**：[02_维度二_纵深进攻 · 04_实践策略规划](../../../02_战略维度/02_维度二_纵深进攻/04_实践策略规划.md)
- **L3 设计**：[step_02~07](../../../03_原子目标与规约/02_维度二_纵深进攻/stages/stage_1_启动期/steps/)
- **共享规约**：[19_异构AI调度栈](../../../03_原子目标与规约/_共享规约/19_异构AI调度栈规约.md)、[20_监控字典](../../../03_原子目标与规约/_共享规约/20_监控字典规约.md)
- **L4 代码**：`diting-src/apps/deep_strike/lighthouse/`
- **DNA 键**：`_System_DNA/02_deep_strike/theme_sniffer.yaml`（待 D03 设计文档新增）

---

## §1 五场景状态机边界

### §1.1 顺序图

```
                ┌───────────┐
   raw_texts ─→ │  Sniffer  │ ─→ clusters
                └───────────┘     │
                                  ▼
                            ┌──────────┐
                            │  Critic  │ ─→ physical_gate ?
                            └──────────┘     │
                              false ─→ DROP（dropped_by_critic）
                              true
                                  ▼
                            ┌──────────┐
                            │  Scorer  │ ─→ composite + decision
                            └──────────┘     │
                              discard ─→ DROP（dropped_by_scorer）
                              propose / watch
                                  ▼
                ┌─────────────────┴─────────────────┐
                ▼                                   ▼
          ┌───────────┐                       ┌─────────┐
          │ Architect │ ─→ monitor_matrix     │  Timer  │ ─→ 三段窗口
          │  (D3 探针 │                       │ + cycle │
          │   消费)   │                       │ anchors │
          └───────────┘                       └─────────┘
                │                                   │
                ▼                                   ▼
       ┌────────────────┐                  ┌─────────────────┐
       │ Redis monitor: │                  │ thesis_cards    │
       │ {symbol}:dict  │                  │ .timer_signal   │
       └────────────────┘                  └─────────────────┘
                │                                   │
                ▼                                   ▼
         D3 step_03 探针                   D4 step_05 SP5 披露窗口协议
```

### §1.2 关键边界（不可逾越）

| # | 边界 | 落地强制 | 违反后果 |
|---|------|----------|---------|
| **B1** | **Critic 不通过即拦截**（physical_gate=false）| `orchestrator.py` 显式 `continue`，不进 Scorer/Architect/Timer | 节省 Opus 调用成本；防止"概念股"漂白 |
| **B2** | **AI 调用唯一入口** | 五场景全部 `AIDispatcher.call()`，禁止 raw httpx | 预算软上限可观察 + 路由统一 |
| **B3** | **propose ≠ 建仓** | `ScorerOutput.model_json_schema()` 不含 `auto_trade/buy/execute/qmt/place_order` 字段（单测覆盖）| `tests/test_lighthouse.py::test_orchestrator_no_auto_trade_field` 保护 |
| **B4** | **monitor_matrix 必须有可追溯节点** | Pydantic `mapped_logic_chain_nodes: list[str] = Field(min_length=1)` | 字段无来源即拒绝 |
| **B5** | **alert_threshold 双形式** | `AlertThresholdStruct` 与自然语言 `alert_threshold` 同时落库 | D3 探针自动判定不可少；人类复审不可少 |
| **B6** | **弹性比 < 5% 强制拦截** | `CriticOutput` 本地确定性计算，不信任 LLM | LC3 启动期硬约束 |
| **B7** | **Architect operator 归一化** | `TheArchitect._normalize_operator()` 把 LLM 自由风格收敛到 5 枚举 | 避免 LLM 自创 `mom_pct_or_yoy_pct` 等组合值拒绝写库 |

### §1.3 路由策略（共享规约 19）

| 场景 | scene | 默认路由 | 远程模型 | 备注 |
|------|-------|---------|----------|------|
| Sniffer | `etl` | local（vLLM）| Qwen-14B | 本地不可用 → mock；开发期可 `force_route="remote"` 走 Opus |
| Critic | `critic` | remote | claude-opus-4-6 | 物理证伪需要强推理 |
| Scorer | `scorer_policy` | remote | claude-opus-4-6 | 三维需要政策/产业/映射综合判断 |
| Architect | `architect` | remote | claude-opus-4-6 | monitor_matrix 结构化输出 |
| Timer | `timer` | remote | claude-opus-4-6 | 财报日历推理 |

---

## §2 事件链一致性

### §2.1 上下游 schema 对账

| 上游 → 下游 | 字段映射 | 校验 |
|------------|---------|------|
| Sniffer → Critic | `SnifferCluster.cluster_id / keyword / sample_doc_idx` → `CriticInput.cluster_id / cluster_keyword / sample_raw_texts` | orchestrator 直接传递 |
| Critic → Scorer | `physical_gate=true` 才传 | orchestrator `if not physical_gate: continue` |
| Scorer → Architect | `decision in {propose, watch}` 才生成 monitor_matrix | orchestrator `if ctx.logic_chain_nodes:` |
| Architect → D3 探针 | `MonitorField.alert_threshold_struct` → D3 探针 `compare(...)` | **跨服务**，需共享规约 20 jsonschema 兜底 |
| Timer → D4 SP5 | `TimerOutput.cycle_anchors` → D4 step_05 SP5 披露窗口协议 | **待 D4 SP5 实现**；当前仅生成不消费 |

### §2.2 持仓表保护（永久规则 1）

`apps/deep_strike/__init__.py` 已声明永久规则：
> **AI 不可自动建仓**：所有 thesis 卡片最终必须经"架构师建仓确认"API 才能进入用户持仓表。

代码侧验证：
- `LighthouseOrchestrator` 完全无 DB 写入；返回的 `OrchestratorResult` 是纯 dataclass
- `thesis_cards.status` 默认 `proposed`；`confirmed` 仅 D2 step_08 HumanGate API 设置
- `ScorerOutput` schema 无任何执行类字段（`test_orchestrator_no_auto_trade_field` 强制）

### §2.3 与 D3 / D4 / D5 的解耦

| 维度 | 与 D2 Lighthouse 的解耦 |
|------|------------------------|
| D3 state_watch | Lighthouse 只**生产** Redis `monitor:{symbol}:dict:*`；D3 探针通过键名约定**自取**，无直接函数调用 |
| D4 exit_engine | Lighthouse 只**生成** `timer_signal` 落 `thesis_cards.timer_signal` 列；D4 SP5 自取，无双向依赖 |
| D5 super_evo | Teacher 与 Lighthouse 共用 `ANTHROPIC_API_KEY`，但模型分层（`TEACHER_MODEL=claude-sonnet-4-5` / `LIGHTHOUSE_REMOTE_MODEL=claude-opus-4-6`）；预算独立计 |

---

## §3 测试覆盖与成本

### §3.1 单测（全 mock，无需 API Key）

`tests/deep_strike/test_lighthouse.py` — **19 passed**：
- Sniffer parse 与 fallback (2)
- Architect parse + normalize_operator + fallback (4)
- Critic 三种物理证伪场景 (3)
- Scorer 三档阈值 + source 减分 (3)
- Timer 三段窗口 (1)
- Orchestrator 拦截 + 端到端 + 永久规则 (3)
- extract_json 工具 (3)

### §3.2 Opus 真实联调（5 次调用）

`scripts/lighthouse_opus_smoke.py` — 单次完整链路成本 ≈ **¥2.50**：

| 调用 | 结果 |
|------|------|
| Sniffer (force remote) | 3 个簇（液冷服务器/PUE/智算中心）|
| Critic | physical_gate=True, 弹性 24.29% |
| Scorer | composite=8.05 → propose (cap=0.85) |
| Architect | 3 个监控字段（含 P6 HS Code + P5 ccgp 关键词）|
| Timer | 三段窗口 + 4 cycle_anchors |

### §3.3 成本预估

| 场景 | 单次成本 | 备注 |
|------|---------|------|
| 单 cluster 全链路（5 场景）| ≈ ¥2.5 | 见 §3.2 实测 |
| 每日新增 5 簇 | ≈ ¥12.5/天 | 启动期实际预算 |
| 每日 100 候选（扩展期）| ≈ ¥250/天 | 软上限 ¥1000 保护，Scorer industry_space 可降本地小模型 |

---

## §4 后续待办（W3+）

| 优先级 | 任务 | 触发条件 |
|--------|------|---------|
| **P0** | D3 探针消费 Redis `monitor:{symbol}:dict:*` | 本 Review 后立即可做 |
| **P0** | D4 SP5 消费 `thesis_cards.timer_signal` | 与 D3 并行 |
| **P1** | Sniffer 改用本地 vLLM Qwen-14B 替代 mock | 启动期成本控制 |
| **P1** | Scorer.industry_space 拆出本地路由（force_route="local"）| 成本节省 50% |
| **P2** | 物理采集层（Playwright）落地 ccgp/research/overseas spider | step_02 §3.5.4 LA1 |
| **P2** | sniffer_clusters / monitor_dict_history ClickHouse 落库 | step_02 §3.5.4 LA7 |
| **P2** | LoRA Self-Critic（D5 step_06）| Teacher 蒸馏数据集就绪后 |

---

## §5 一致性检查

- [x] 五场景全部走 `AIDispatcher.call()`，符合共享规约 19 §SDK1
- [x] 永久规则覆盖：`test_orchestrator_no_auto_trade_field` 防止 schema 出现执行字段
- [x] LC1~LC6 物理证伪 6 项约束全部代码化（含弹性比本地计算）
- [x] PRD §2.3 Scorer 三维 + §3.3 Architect monitor_matrix + §3.4 Timer 三段全部落地
- [x] L1 §基石⑥「物理证伪 ≥ 财务证伪」体现在 `physical_gate = physical AND (commercial OR financial)`
- [x] 19 单测 + 5 次 Opus 真实联调全部通过
- [x] 成本 ≈ ¥2.5/簇全链路，远低于软上限 ¥1000/天

---

## §6 修订记录

| 日期 | 内容 |
|------|------|
| 2026-05-23 | W2 Opus 阶段初版：五场景代码 + 19 单测 + 5 次 Opus 联调通过；Architect operator 归一化；事件链 4 边界 + 跨维解耦说明 |
