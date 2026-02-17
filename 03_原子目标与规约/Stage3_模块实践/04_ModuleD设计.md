# L3 · Stage3-04 Module D 设计

> [!NOTE] **[TRACEBACK] 原子规约锚点**
> - **战略维度**: [技术栈与架构维度](../../02_战略维度/产品设计/02_技术栈与架构维度.md)
> - **原子规约**: [_共享规约/09_核心模块架构规约](../_共享规约/09_核心模块架构规约.md)、[_共享规约/01_核心公式与MoE架构规约](../_共享规约/01_核心公式与MoE架构规约.md)
> - **DNA**: [dna_stage3_04.yaml](../_System_DNA/Stage3_模块实践/dna_stage3_04.yaml)、[dna_module_d.yaml](../_System_DNA/core_modules/dna_module_d.yaml)
> - **L4 实践**: [04_阶段规划与实践/Stage3_模块实践/04_ModuleD](../../04_阶段规划与实践/Stage3_模块实践/04_ModuleD.md#l4-stage3-04-exit)
> - **L5 锚点**: [02_验收标准#l5-stage-stage3_04](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_04)

<a id="design-stage3-04-goal"></a>
## 本步目标

实现 Module D 判官（决策中枢）：投票机制（Quant + Expert）、动态凯利仓位、现金拖累监控、防御性复利；Alpha 与 01_ 核心公式一致。

<a id="design-stage3-04-points"></a>
## 设计要点

- **投票**：Quant 信号与专家意见加权投票
- **凯利**：动态仓位计算，满足不可能三角约束
- **现金拖累**：空仓 > 5 天触发监控
- **公式**：Alpha = (Quant_Signal ∩ Router(Experts)) × Kelly_Position

<a id="design-stage3-04-dna-keys"></a>
## 本步落实的 _System_DNA 键

- `core_modules/dna_module_d.yaml`；`core_formula`、`constraints`（胜率/复利/回撤）

<a id="design-stage3-04-exit"></a>
## 准出

Module D 四项 100%；判官投票+Kelly+Alpha 与 01_ 核心公式一致；Table-Driven 单测与边界覆盖；L5 [l5-stage-stage3_04](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_04) 可更新。
