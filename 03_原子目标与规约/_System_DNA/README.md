# _System_DNA（机器可读真相源）

> 本目录是 Diting 项目的**单一真相源**：L2/L3 写规则 → 此处收敛为键值对 → L4 按键执行与验收、L5 以本目录为源或强一致。

## 当前状态（2026-05-16 启动期 DNA 重组完成）

```
_System_DNA/
├── README.md                         # 本文件
├── global_const.yaml                 # 顶层 DNA（待按六维度同步）
├── dna_dev_workflow.yaml             # workflow_stages（待按六维度同步）
├── 00_co_pilot/                      # ✅ 维度零·AI 投资副驾驶
│   ├── dna_stage_1_启动期.yaml      # ✅ 启动期 DNA（本批次新增）
│   ├── README.md                     # (待重写)
│   └── 旧 frontend MVP/V1/V2 yaml    # 保留作历史参考
├── 01_cryo_guard/                    # ✅ 维度一·极寒防御
│   ├── dna_stage_1_启动期.yaml      # ✅ 启动期 DNA
│   └── 旧 MVP/V1/V2 yaml             # 保留作历史参考
├── 02_deep_strike/                   # ✅ 维度二·纵深进攻
│   ├── dna_stage_1_启动期.yaml      # ✅ 启动期 DNA
│   └── 旧 MVP/V1 yaml                # 保留作历史参考
├── 03_holding_watch/                 # ✅ 维度三·持仓监控（原 state_watch 拆出）
│   ├── dna_stage_1_启动期.yaml      # ✅ 启动期 DNA
│   └── 旧 state_watch MVP/V1 yaml    # 保留作历史参考（含监控相关键值）
├── 04_exit_engine/                   # ✅ 维度四·卖出决策（新建）
│   └── dna_stage_1_启动期.yaml      # ✅ 启动期 DNA
├── 05_super_evo/                     # ✅ 维度五·演进飞轮
│   ├── dna_stage_1_启动期.yaml      # ✅ 启动期 DNA
│   └── 旧 MVP/V1/V2 yaml             # 保留作历史参考
├── core_modules/                     # 跨模块共享元数据
└── shared/                           # 平台基础元数据
```

## 设计-DNA-实践 1:1:1（按启动期）

| 维度 | L3 设计 | DNA | L4 实践（批次 3 重组） | L5 锚点 |
|---|---|---|---|---|
| 维度零 | [00_维度零/stages/stage_1_启动期/](../00_维度零_AI投资副驾驶/stages/stage_1_启动期/) | [00_co_pilot/dna_stage_1_启动期.yaml](./00_co_pilot/dna_stage_1_启动期.yaml) | `04_/00_维度零/stage_1_启动期/` | `l5-stage-d0s1` |
| 维度一 | [01_维度一/stages/stage_1_启动期/](../01_维度一_极寒防御/stages/stage_1_启动期/) | [01_cryo_guard/dna_stage_1_启动期.yaml](./01_cryo_guard/dna_stage_1_启动期.yaml) | `04_/01_维度一/stage_1_启动期/` | `l5-stage-d1s1` |
| 维度二 | [02_维度二/stages/stage_1_启动期/](../02_维度二_纵深进攻/stages/stage_1_启动期/) | [02_deep_strike/dna_stage_1_启动期.yaml](./02_deep_strike/dna_stage_1_启动期.yaml) | `04_/02_维度二/stage_1_启动期/` | `l5-stage-d2s1` |
| 维度三 | [03_维度三/stages/stage_1_启动期/](../03_维度三_持仓监控/stages/stage_1_启动期/) | [03_holding_watch/dna_stage_1_启动期.yaml](./03_holding_watch/dna_stage_1_启动期.yaml) | `04_/03_维度三/stage_1_启动期/` | `l5-stage-d3s1` |
| 维度四 | [04_维度四/stages/stage_1_启动期/](../04_维度四_卖出决策/stages/stage_1_启动期/) | [04_exit_engine/dna_stage_1_启动期.yaml](./04_exit_engine/dna_stage_1_启动期.yaml) | `04_/04_维度四/stage_1_启动期/` | `l5-stage-d4s1` |
| 维度五 | [05_维度五/stages/stage_1_启动期/](../05_维度五_演进飞轮/stages/stage_1_启动期/) | [05_super_evo/dna_stage_1_启动期.yaml](./05_super_evo/dna_stage_1_启动期.yaml) | `04_/05_维度五/stage_1_启动期/` | `l5-stage-d5s1` |

## 引用约定

- L4 / 代码 / 配置中引用 DNA 路径示例：
  - `_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml#quantitative_goals`
  - `_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml#deliverables.engines[0].holdout_recall_threshold`
  - `_System_DNA/04_exit_engine/dna_stage_1_启动期.yaml#deliverables.sell_protocols`

## 启动期 DNA 关键约定

1. **YAML 单文件**：每个维度启动期一份 `dna_stage_1_启动期.yaml`，扩展期/完善期后续再增
2. **work_dir = diting-src**：所有维度启动期都在源代码仓 `diting-src` 下开发
3. **base_model = Qwen2.5-7B-Instruct**：所有 LoRA 微调基座统一
4. **6 个 service_name**：copilot / cryo-guard / deep-strike / state-watch / exit-engine / super-evo
5. **Redis Stream 事件契约**：`events:{dimension_code}:{event_type}`

## 后续

- **扩展期 / 完善期 DNA**：后续按需新增 `dna_stage_2_扩展期.yaml`、`dna_stage_3_完善期.yaml`
- **global_const.yaml 同步**：按六维度重写顶层常量（下一轮）
- **dna_dev_workflow.yaml 同步**：workflow_stages 重组对齐六维度（下一轮）
- 任何 DNA 变更须按 `00_系统规则_通用项目协议.md §4.5` 同步 L4 / L5 / 06_ 与本协议
