# L4 · 阶段规划与实践

> [!NOTE] **[TRACEBACK] 阶段实践锚点**
> - **顶层概念**: [项目定义与核心价值](../01_顶层概念/01_项目定义与核心价值.md)
> - **战略维度**: [L2 · 双目标与战略维度关系](../02_战略维度/00_双目标与战略维度关系.md)
> - **原子规约**: [03_原子目标与规约](../03_原子目标与规约/README.md)
> - **DNA 真相源**: [_System_DNA/dna_dev_workflow.yaml](../03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml)

## 一、L4 组织结构（2026-05-13 重构后）

L4 已按 **L2 四大战略主轴 + 前端 + 共享平台基础** 重组，与 [`dna_dev_workflow.yaml`](../03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml#workflow_stages) 的 22 个 `workflow_stages` 严格 1:1。

```
04_阶段规划与实践/
├── 共享平台基础/                # shared_platform_baseline
├── 极寒防御/                    # cryo_guard MVP/V1/V2
├── 纵深进攻/                    # deep_strike MVP/V1*/V2
├── 状态机监控/                  # state_watch MVP/V1*/V2
├── 超级个体进化/                # super_evo MVP/V1*/V2
├── 前端工程与服务/              # frontend MVP/V1/V2
├── 00_四阶段提问体系_完整规约.md
└── README.md
```

每个模块目录含一份 `README.md`（模块导航 + 阶段索引 + AI 推荐模型）+ 各阶段 `0N_本阶段实践与验证.md`。

## 二、22 个 workflow_stages 索引

| stage_id | pillar | milestone | L4 实践文档 | L5 锚点 |
|----------|--------|-----------|------------|---------|
| `shared_platform_baseline` | shared_platform | mvp | [共享平台基础/01_本阶段实践与验证.md](./共享平台基础/01_本阶段实践与验证.md) | `l5-shared-platform-baseline` |
| `cryo_guard_mvp` | cryo_guard | mvp | [极寒防御/01_MVP_本阶段实践与验证.md](./极寒防御/01_MVP_本阶段实践与验证.md) | `l5-pillar-cryo-mvp` |
| `cryo_guard_v1` | cryo_guard | v1 | [极寒防御/02_V1_本阶段实践与验证.md](./极寒防御/02_V1_本阶段实践与验证.md) | `l5-pillar-cryo-v1` |
| `cryo_guard_v2` | cryo_guard | v2 | [极寒防御/03_V2_本阶段实践与验证.md](./极寒防御/03_V2_本阶段实践与验证.md) | `l5-pillar-cryo-v2` |
| `deep_strike_mvp` | deep_strike | mvp | [纵深进攻/01_MVP_本阶段实践与验证.md](./纵深进攻/01_MVP_本阶段实践与验证.md) | `l5-pillar-deep-mvp` |
| `deep_strike_v1_council` | deep_strike | v1 | [纵深进攻/02_V1_council_本阶段实践与验证.md](./纵深进攻/02_V1_council_本阶段实践与验证.md) | `l5-pillar-deep-v1-council` |
| `deep_strike_v1_feature` | deep_strike | v1 | [纵深进攻/03_V1_feature_本阶段实践与验证.md](./纵深进攻/03_V1_feature_本阶段实践与验证.md) | `l5-pillar-deep-v1-feature` |
| `deep_strike_v1_eval` | deep_strike | v1 | [纵深进攻/04_V1_eval_本阶段实践与验证.md](./纵深进攻/04_V1_eval_本阶段实践与验证.md) | `l5-pillar-deep-v1-eval` |
| `deep_strike_v2_runtime` | deep_strike | v2 | [纵深进攻/05_V2_runtime_本阶段实践与验证.md](./纵深进攻/05_V2_runtime_本阶段实践与验证.md) | `l5-pillar-deep-v2-runtime` |
| `state_watch_mvp` | state_watch | mvp | [状态机监控/01_MVP_本阶段实践与验证.md](./状态机监控/01_MVP_本阶段实践与验证.md) | `l5-pillar-watch-mvp` |
| `state_watch_v1_probe` | state_watch | v1 | [状态机监控/02_V1_probe_本阶段实践与验证.md](./状态机监控/02_V1_probe_本阶段实践与验证.md) | `l5-pillar-watch-v1-probe` |
| `state_watch_v1_gate` | state_watch | v1 | [状态机监控/03_V1_gate_本阶段实践与验证.md](./状态机监控/03_V1_gate_本阶段实践与验证.md) | `l5-pillar-watch-v1-gate` |
| `state_watch_v1_budget` | state_watch | v1 | [状态机监控/04_V1_budget_本阶段实践与验证.md](./状态机监控/04_V1_budget_本阶段实践与验证.md) | `l5-pillar-watch-v1-budget` |
| `state_watch_v2_template` | state_watch | v2 | [状态机监控/05_V2_template_本阶段实践与验证.md](./状态机监控/05_V2_template_本阶段实践与验证.md) | `l5-pillar-watch-v2-template` |
| `super_evo_mvp` | super_evo | mvp | [超级个体进化/01_MVP_本阶段实践与验证.md](./超级个体进化/01_MVP_本阶段实践与验证.md) | `l5-pillar-evo-mvp` |
| `super_evo_v1_eval` | super_evo | v1 | [超级个体进化/02_V1_eval_本阶段实践与验证.md](./超级个体进化/02_V1_eval_本阶段实践与验证.md) | `l5-pillar-evo-v1-eval` |
| `super_evo_v1_retro` | super_evo | v1 | [超级个体进化/03_V1_retro_本阶段实践与验证.md](./超级个体进化/03_V1_retro_本阶段实践与验证.md) | `l5-pillar-evo-v1-retro` |
| `super_evo_v1_version` | super_evo | v1 | [超级个体进化/04_V1_version_本阶段实践与验证.md](./超级个体进化/04_V1_version_本阶段实践与验证.md) | `l5-pillar-evo-v1-version` |
| `super_evo_v2_online` | super_evo | v2 | [超级个体进化/05_V2_online_本阶段实践与验证.md](./超级个体进化/05_V2_online_本阶段实践与验证.md) | `l5-pillar-evo-v2-online` |
| `frontend_mvp` | frontend | mvp | [前端工程与服务/01_MVP_本阶段实践与验证.md](./前端工程与服务/01_MVP_本阶段实践与验证.md) | `l5-frontend-mvp` |
| `frontend_v1_full` | frontend | v1 | [前端工程与服务/02_V1_full_本阶段实践与验证.md](./前端工程与服务/02_V1_full_本阶段实践与验证.md) | `l5-frontend-v1-full` |
| `frontend_v2_pwa` | frontend | v2 | [前端工程与服务/03_V2_pwa_本阶段实践与验证.md](./前端工程与服务/03_V2_pwa_本阶段实践与验证.md) | `l5-frontend-v2-pwa` |

## 三、Phase 规划

| Phase | 内容 | 包含 stages |
|-------|------|------------|
| `phase1_mvp_e2e` | 全 5 模块 MVP 串通；首批用户可用 | shared_platform_baseline、cryo_guard_mvp、deep_strike_mvp、state_watch_mvp、super_evo_mvp、frontend_mvp |
| `phase2_v1_production_grade` | 全模块 V1 上线；生产级稳态 | cryo_guard_v1、deep_strike_v1_*、state_watch_v1_*、super_evo_v1_*、frontend_v1_full |
| `phase3_v2_evolution` | V2 进化；多端 + 高级能力 | cryo_guard_v2、deep_strike_v2_runtime、state_watch_v2_template、super_evo_v2_online、frontend_v2_pwa |

## 四、L4 执行规则（强制）

1. **DNA 为权威**：每个步骤的 `工作目录` / `可执行验证命令` / `准出 L5 行` 须从 [DNA `workflow_stages[].verification_commands` / `l5_stage_anchor`](../03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml#workflow_stages) 引用或与之严格一致
2. **1:1:1 同步**：本阶段实践文档与 03_ 设计文档、`_System_DNA/<pillar>/` 步骤级 DNA 形成 1:1:1，任一变更须同时更新另两个
3. **失败原则**：步骤失败 → 先分析、修复、重试；同一问题重试 ≥ 2 次仍失败 → 按 `01_本阶段实践与验证.md#本步骤失败时` 回退
4. **准出更新 L5**：每个阶段准出后必须勾选 [`05_成功标识与验证/02_验收标准.md`](../05_成功标识与验证/02_验收标准.md) 对应行
5. **AI 推荐模型**：各模块 README 内含本阶段推荐模型表（依规则 §8.4c 须填具体模型名）

## 五、四阶段提问体系（保留）

需求 / 设计变更入口仍走 [00_四阶段提问体系_完整规约.md](./00_四阶段提问体系_完整规约.md)，按规约产出待办清单后再分配到上述 22 个 stage 之一。

## 六、本次重构（2026-05-13 第 3 批）变更

- 删除旧 `Stage1_仓库与骨架/` ~ `Stage5_优化与扩展/` 五个目录
- 删除旧 `00_5D范例_ModuleD决策中枢.md`、`00_5D范例_ModuleD判官.md`、`00_从零到第一次准出.md`
- 新建 `共享平台基础/` + `极寒防御/` + `纵深进攻/` + `状态机监控/` + `超级个体进化/` + `前端工程与服务/`
- 22 份 `0N_本阶段实践与验证.md` 与 22 个 DNA workflow_stages 严格对齐
- 详见 `00_系统规则_通用项目协议.md` 协议修订记录
