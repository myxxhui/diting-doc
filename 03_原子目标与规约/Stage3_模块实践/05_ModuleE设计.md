# L3 · Stage3-05 Module E 设计

> [!NOTE] **[TRACEBACK] 原子规约锚点**
> - **战略维度**: [技术栈与架构维度](../../02_战略维度/产品设计/02_技术栈与架构维度.md)、[生产保障与可观测性维度](../../02_战略维度/产品设计/04_生产保障与可观测性维度.md)
> - **原子规约**: [_共享规约/09_核心模块架构规约](../_共享规约/09_核心模块架构规约.md)
> - **DNA**: [dna_stage3_05.yaml](../_System_DNA/Stage3_模块实践/dna_stage3_05.yaml)、[dna_module_e.yaml](../_System_DNA/core_modules/dna_module_e.yaml)
> - **L4 实践**: [04_阶段规划与实践/Stage3_模块实践/05_ModuleE](../../04_阶段规划与实践/Stage3_模块实践/05_ModuleE.md#l4-stage3-05-exit)
> - **L5 锚点**: [02_验收标准#l5-stage-stage3_05](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_05)

<a id="design-stage3-05-goal"></a>
## 本步目标

实现 Module E 风控盾：硬止损（单笔 > 2%）、盈亏比检查（< 1.5 拒绝）、组合相关性/Domain 上限；风控接口与占位可验证。

<a id="design-stage3-05-points"></a>
## 设计要点

- **硬止损**：单笔风险 < 2%
- **盈亏比**：≥ 1.5 方通过
- **组合**：Domain 相关性上限
- **接口**：与 Module D 输出、Module F 输入衔接

<a id="design-stage3-05-dna-keys"></a>
## 本步落实的 _System_DNA 键

- `core_modules/dna_module_e.yaml`；`constraints`（生存底线）

<a id="design-stage3-05-exit"></a>
## 准出

Module E 四项 100%；风控接口与占位（硬止损 2%、盈亏比≥1.5）可验证；L5 [l5-stage-stage3_05](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_05) 可更新。
