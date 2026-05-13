# _System_DNA（机器可读真相源）

> 本目录是 Diting 项目的**单一真相源**：L2/L3 写规则 → 此处收敛为键值对 → L4 按键执行与验收、L5 以本目录为源或强一致。

## 当前状态（2026-05-13 第 2 批后）

```
_System_DNA/
├── README.md                        # 本文件
├── global_const.yaml                # ✅ v2.0：四大模块 + frontend + 平台基础顶层 DNA
├── dna_dev_workflow.yaml            # ✅ v2.0：workflow_stages 按四大模块 + 前端 + 平台基础重组
├── cryo_guard/                      # ✅ 极寒防御步骤级 DNA
│   ├── README.md
│   └── dna_cryo_guard_mvp.yaml      # （V1/V2 由后续 Phase 补齐）
├── deep_strike/                     # ✅ 纵深进攻步骤级 DNA
│   ├── README.md
│   └── dna_deep_strike_mvp.yaml
├── state_watch/                     # ✅ 状态机监控步骤级 DNA
│   ├── README.md
│   └── dna_state_watch_mvp.yaml
├── super_evo/                       # ✅ 超级个体进化步骤级 DNA
│   ├── README.md
│   └── dna_super_evo_mvp.yaml
├── frontend/                        # ✅ 前端工程与服务步骤级 DNA
│   ├── README.md
│   └── dna_frontend_mvp.yaml
└── core_modules/                    # 跨模块共享元数据（待 Phase 内继续填充）
    └── README.md
```

## 设计-DNA-实践 1:1:1

每条 `dna_dev_workflow.yaml#workflow_stages[]` 满足：
- 关联一份 L3 设计文档（`design_doc`，带锚点）
- 关联一份步骤级 DNA（`dna_file`）
- 关联一份 L4 实践文档（第 3 批创建）
- 关联一个 L5 行锚（`l5_stage_anchor`）

## 引用约定

- L4 / 代码 / 配置中引用 DNA 路径示例：
  - `_System_DNA/global_const.yaml#cryo_guard_top.slo.decision_gate_p50_ms`
  - `_System_DNA/dna_dev_workflow.yaml#workflow_stages[stage_id=cryo_guard_mvp].verification_commands`
  - `_System_DNA/cryo_guard/dna_cryo_guard_mvp.yaml#decision_gate_layers`

## 后续

- 第 3 批将填充 V1 / V2 阶段的步骤级 DNA、补齐 `core_modules/` 的跨模块元数据，并创建 L4 实践文档与 L5 验收行
- 任何 DNA 变更须按 `00_系统规则_通用项目协议.md §4.5` 同步 L4 / L5 / 06_ 与本协议
