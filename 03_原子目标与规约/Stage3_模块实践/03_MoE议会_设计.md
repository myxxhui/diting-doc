# L3 · Stage3-03 Module C 设计

> [!NOTE] **[TRACEBACK] 原子规约锚点**
> - **战略维度**: [技术栈与架构维度](../../02_战略维度/产品设计/02_技术栈与架构维度.md)
> - **原子规约**: [_共享规约/09_核心模块架构规约](../_共享规约/09_核心模块架构规约.md)、[_共享规约/01_核心公式与MoE架构规约](../_共享规约/01_核心公式与MoE架构规约.md)
> - **DNA**: [03_dna_MoE议会](../_System_DNA/Stage3_模块实践/03_dna_MoE议会.yaml)、[dna_module_c.yaml](../_System_DNA/core_modules/dna_module_c.yaml)
> - **L4 实践**: [03_MoE议会_实践](../../04_阶段规划与实践/Stage3_模块实践/03_MoE议会_实践.md#l4-stage3-03-exit)
> - **L5 锚点**: [02_验收标准#l5-stage-stage3_03](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_03)

<a id="design-stage3-03-goal"></a>
## 本步目标

实现 Module C MoE 议会（右脑）：Router 按 Domain Tag 分发至 Agri/Tech/Geo 专家（及 Trash Bin）；专家意见与 Module D 判官对接。

<a id="design-stage3-03-points"></a>
## 设计要点

- **Router**：按 Tag 选择专家；无法归类进 Trash Bin
- **专家**：Agri-Agent（季节性/期货）、Tech-Agent（研发/大基金）、Geo-Agent（大宗/汇率）
- **输入**：Module A 的 Tag、Module B 的量化信号
- **输出**：专家意见（辩论协议），供 D 投票与 Kelly 计算

<a id="design-stage3-03-dna-keys"></a>
## 本步落实的 _System_DNA 键

- `core_modules/dna_module_c.yaml`；`core_formula`（Router 与 Alpha 定义）

<a id="design-stage3-03-exit"></a>
## 准出

Module C 四项 100%；单测与联动验证通过；L5 [l5-stage-stage3_03](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_03) 可更新。
