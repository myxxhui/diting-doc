# _System_DNA / cryo_guard

> 极寒防御（Cryo-Guard）模块的步骤级 DNA。 
> **真相源职责**：与 03_/极寒防御/ 设计文档、04_/极寒防御/ 实践文档形成 **1:1:1**。 
> 顶层全局常量见 `../global_const.yaml#cryo_guard_top`；工作流见 `../dna_dev_workflow.yaml`。

## 文件清单

| 文件 | 阶段 | 对应 design_doc | 对应 L4 | 对应 L5 锚点 |
|------|------|----------------|---------|--------------|
| `dna_cryo_guard_mvp.yaml` | MVP | 极寒防御/05_实施推演_设计.md#二mvp最小可用产品 | 04_/极寒防御/01_MVP_本阶段实践与验证.md | l5-pillar-cryo-mvp |
| `dna_cryo_guard_v1.yaml` | V1 | 极寒防御/05_实施推演_设计.md#三v1完整能力 | 04_/极寒防御/02_V1_本阶段实践与验证.md | l5-pillar-cryo-v1 |
| `dna_cryo_guard_v2.yaml` | V2 | 极寒防御/05_实施推演_设计.md#四v2生产稳态 | 04_/极寒防御/03_V2_本阶段实践与验证.md | l5-pillar-cryo-v2 |

## 维护规则
- 步骤级 DNA 与设计文档、L4 步骤文档须保持 1:1:1
- 任何键值变更须同步更新对应 04_/L5 文档
- 新增步骤须先在 `../dna_dev_workflow.yaml#workflow_stages` 注册
