# L3 · Stage3-01 Module A 设计

> [!NOTE] **[TRACEBACK] 原子规约锚点**
> - **战略维度**: [技术栈与架构维度](../../02_战略维度/产品设计/02_技术栈与架构维度.md)
> - **原子规约**: [_共享规约/09_核心模块架构规约](../_共享规约/09_核心模块架构规约.md)、[_共享规约/11_数据采集与输入层规约](../_共享规约/11_数据采集与输入层规约.md)
> - **DNA**: [_System_DNA/Stage3_模块实践/dna_stage3_01.yaml](../_System_DNA/Stage3_模块实践/dna_stage3_01.yaml)、[core_modules/dna_module_a.yaml](../_System_DNA/core_modules/dna_module_a.yaml)
> - **L4 实践**: [04_阶段规划与实践/Stage3_模块实践/01_ModuleA](../../04_阶段规划与实践/Stage3_模块实践/01_ModuleA.md#l4-stage3-01-exit)
> - **L5 锚点**: [02_验收标准#l5-stage-stage3_01](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_01)

<a id="design-stage3-01-goal"></a>
## 本步目标

实现 Module A 语义分类器：基于标的代码、申万行业、营收占比等输入，输出 Domain Tag（AGRI/TECH/GEO/UNKNOWN）与置信度；单模块实现 + 与下游联动 + 全链路验证可达。

<a id="design-stage3-01-points"></a>
## 设计要点

- **输入**：标的代码、申万行业分类、营收占比数据（来源见 11_ 数据采集与输入层规约）
- **输出**：Domain Tag、置信度分数 (0.0–1.0)
- **分类规则**：AGRI（农林牧渔/营收占比）、TECH（电子计算机通信/研发投入）、GEO（有色金属石油石化/大宗商品营收）；其余 UNKNOWN
- **不做预测**：仅做分类，为 Module B/C 提供 Tag

<a id="design-stage3-01-dna-keys"></a>
## 本步落实的 _System_DNA 键

- `core_modules/dna_module_a.yaml`（classification_rules、input、output）
- `global_const.core_modules`（若已收敛）

<a id="design-stage3-01-exit"></a>
## 准出

Module A 四项 100%；单模块 + 联动 + 全链路验证通过；L5 功能验收表 [l5-stage-stage3_01](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_01) 可更新。
