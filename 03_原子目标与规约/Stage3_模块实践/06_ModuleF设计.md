# L3 · Stage3-06 Module F 设计

> [!NOTE] **[TRACEBACK] 原子规约锚点**
> - **战略维度**: [技术栈与架构维度](../../02_战略维度/产品设计/02_技术栈与架构维度.md)、[经纪商解耦与冗余维度](../../02_战略维度/产品设计/08_经纪商解耦与冗余维度.md)
> - **原子规约**: [_共享规约/09_核心模块架构规约](../_共享规约/09_核心模块架构规约.md)、[_共享规约/05_接口抽象层规约](../_共享规约/05_接口抽象层规约.md)
> - **DNA**: [dna_stage3_06.yaml](../_System_DNA/Stage3_模块实践/dna_stage3_06.yaml)、[dna_module_f.yaml](../_System_DNA/core_modules/dna_module_f.yaml)
> - **L4 实践**: [04_阶段规划与实践/Stage3_模块实践/06_ModuleF](../../04_阶段规划与实践/Stage3_模块实践/06_ModuleF.md#l4-stage3-06-exit)
> - **L5 锚点**: [02_验收标准#l5-stage-stage3_06](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_06)

<a id="design-stage3-06-goal"></a>
## 本步目标

实现 Module F 执行网关：Redis Streams、OMS Lite、Broker 抽象（MiniQMT/xtquant）、Human-in-the-Loop；E→F 衔接；全链路 A→F 验证在本步准出时执行。

<a id="design-stage3-06-points"></a>
## 设计要点

- **Broker 抽象**：BrokerDriver 接口；占位/仿真实现
- **通道**：Redis Streams → OMS Lite → MiniQMT 或人工确认
- **输入**：Module E 风控通过后的执行指令
- **输出**：订单提交、执行反馈

<a id="design-stage3-06-dna-keys"></a>
## 本步落实的 _System_DNA 键

- `core_modules/dna_module_f.yaml`；`abstraction_layer.broker_driver`

<a id="design-stage3-06-exit"></a>
## 准出

Module F 四项 100%；全链路 A→F 验证通过；L5 [l5-stage-stage3_06](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_06) 可更新。
