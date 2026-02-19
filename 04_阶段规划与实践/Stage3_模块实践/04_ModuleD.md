# Phase1 · 按模块实践 · 04 · Module D 判官

> [!NOTE] **[TRACEBACK] 战略追溯锚点**
> - **顶层概念**: [一句话定义与核心价值](../../01_顶层概念/01_一句话定义与核心价值.md)
> - **战略维度**: [01_产品设计维度](../../02_战略维度/产品设计/01_产品设计维度.md)
> - **原子能力**: [09_核心模块架构规约](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md)（Module D）、[01_核心公式与MoE架构规约](../../03_原子目标与规约/_共享规约/01_核心公式与MoE架构规约.md)
> - **阶段**: [Phase1_按模块实践](README.md)

**本步设计文档**：[04_ModuleD设计](../../03_原子目标与规约/Stage3_模块实践/04_ModuleD设计.md#design-stage3-04-exit)  
**本步 DNA 文件**：[03_原子目标与规约/_System_DNA/Stage3_模块实践/dna_stage3_04.yaml](../../03_原子目标与规约/_System_DNA/Stage3_模块实践/dna_stage3_04.yaml)

<a id="l4-step-nav"></a>
## 步骤导航
- **上一步**：[03_ModuleC](03_ModuleC.md#l4-stage3-03-goal)
- **下一步**：[05_ModuleE](05_ModuleE.md#l4-stage3-05-goal)

<a id="l4-stage3-04-goal"></a>
## 步骤目标

实现 Module D 判官，投票机制 + 动态凯利 + Cash Drag Monitor + Defensive Mode；完成 **四项 100% 验证**。

## 本步骤落实的 DNA 键

- `core_modules/dna_module_d.yaml`：`voting_mechanism`、`dynamic_kelly`、`cash_drag_monitor`、`defensive_mode`

## 实现部分

**工作目录**：`diting-core`

1. 建立 `diting/gavel` 或项目约定判官包
2. 输入：QuantSignal、ExpertOpinion；输出 CouncilVerdict（Alpha、suggested_position_ratio）
3. 凯利公式、投票权重、Cash Drag 阈值写 **YAML 配置**
4. 逻辑密集，须走 5D（Design-Drive-Decompose-Defense）
5. **双轨分流**：根据 `ExpertOpinion.horizon`（或上游传入的轨标识）分支——当 `TimeHorizon = LONG_TERM` 时，不施加 2% 硬止损与现金拖累监控，仅施加逻辑证伪与大周期反转规则；`SHORT_TERM` 或未设置时按现有规则。见 [09_ Module D 双轨分流](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md#双轨分流timehorizon)。

## 验证部分

### 四项 100%

| 维度 | 验收标准 | 验证方法 |
|------|----------|----------|
| **接口 100%** | CouncilVerdict 符合 verdict.proto | 契约单测 |
| **结构 100%** | 判官包、config 与 DNA 一致 | 目录与配置 |
| **逻辑功能 100%** | 公式与 01_ 一致；配置驱动 | Table-Driven 单测、边界覆盖 |
| **代码测试 100%** | 单测覆盖投票、Kelly、Cash Drag、Defensive | `make test` 覆盖率 |

### 三层验证

- **单模块**：Table-Driven 用例验证公式
- **联动**：B+C+D 联调
- **全链路**：参与 A→F 验证

## 核心指令（The Prompt）

```
你是在 diting-core 中实现 Module D 判官的开发者。必读：03_原子目标与规约/_共享规约/09_核心模块架构规约.md（Module D 小节）、03_原子目标与规约/_共享规约/01_核心公式与MoE架构规约.md、03_原子目标与规约/_System_DNA/core_modules/dna_module_d.yaml、verdict.proto。

任务：1. 实现投票+Kelly+Cash Drag+Defensive；2. 公式与阈值写 YAML；3. Table-Driven 单测覆盖边界；4. 5D 执行：Design 锁逻辑、Drive 锚测试、Decompose 原子、Defense 人把关。

工作目录：diting-core。代码含 [Ref: 04_ModuleD]。
```

<a id="l4-stage3-04-exit"></a>
## 验收与测试、DoD、本步骤失败时

同前；L5 [l5-mod-D](../../05_成功标识与验证/02_验收标准.md#l5-mod-D)、[l5-stage-stage3_04](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_04) 行已更新。
