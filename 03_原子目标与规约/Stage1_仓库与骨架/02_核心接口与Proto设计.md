# L3 · Stage1-02 核心接口与 Proto 设计

> [!NOTE] **[TRACEBACK] 原子规约锚点**
> - **战略维度**: [开发与交付流程维度](../../02_战略维度/开发与交付/01_开发与交付流程维度.md)
> - **原子规约**: [_共享规约/04_全链路通信协议矩阵](../_共享规约/04_全链路通信协议矩阵.md)、[_共享规约/05_接口抽象层规约](../_共享规约/05_接口抽象层规约.md)
> - **DNA**: [_System_DNA/Stage1_仓库与骨架/dna_stage1_02.yaml](../_System_DNA/Stage1_仓库与骨架/dna_stage1_02.yaml)
> - **L4 实践**: [04_阶段规划与实践/Stage1_仓库与骨架/02_核心接口与Proto占位](../../04_阶段规划与实践/Stage1_仓库与骨架/02_核心接口与Proto占位.md#l4-stage1-02-exit)
> - **L5 锚点**: [02_验收标准#l5-stage-stage1_02](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage1_02)

<a id="design-stage1-02-goal"></a>
## 本步目标

核心接口、Proto 占位与目录占位实现；本地单测通过。

<a id="design-stage1-02-points"></a>
## 设计要点

- **目录**：按 02_三位一体 repo_i.directories（diting/abstraction/、drivers/、moe/、risk/、strategy/、tests/、design/）
- **Proto**：与 04_ 协议矩阵一致；brain/expert.proto、verdict.proto、execution/order.proto、classifier/classifier_output.proto、quant/quant_signal.proto 等占位
- **抽象层**：BrokerDriver、MarketDataFeed、CognitiveEngine 接口与占位
- **Schema First**：接口与 Proto 定稿；后续接口变更在 Stage1 完成

<a id="design-stage1-02-exit"></a>
## 准出

核心接口存在且本地单测通过；目录与占位实现可运行。
