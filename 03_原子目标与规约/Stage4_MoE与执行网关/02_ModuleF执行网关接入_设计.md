# L3 · Stage4-02 Module F 执行网关接入设计

> [!NOTE] **[TRACEBACK] 原子规约锚点**
> - **05_ 对应项**: [01_顶层概念/05_谛听优先借鉴的十大开源选型](../../01_顶层概念/05_谛听优先借鉴的十大开源选型.md) 第 1 项（Vn.py）
> - **战略维度**: [技术栈与架构维度](../../02_战略维度/产品设计/02_技术栈与架构维度.md)、[经纪商解耦与冗余维度](../../02_战略维度/产品设计/08_经纪商解耦与冗余维度.md)
> - **原子规约**: [_共享规约/09_核心模块架构规约](../_共享规约/09_核心模块架构规约.md)、[_共享规约/05_接口抽象层规约](../_共享规约/05_接口抽象层规约.md)
> - **DNA**: [_System_DNA/Stage4_MoE与执行网关/dna_stage4_02.yaml](../_System_DNA/Stage4_MoE与执行网关/dna_stage4_02.yaml)
> - **L4 实践**: [04_阶段规划与实践/Stage4_MoE与执行网关/02_ModuleF执行网关接入](../../04_阶段规划与实践/Stage4_MoE与执行网关/02_ModuleF执行网关接入.md#l4-stage4-02-exit)
> - **L5 锚点**: [02_验收标准#l5-stage-stage4_02](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage4_02)

<a id="design-stage4-02-goal"></a>
## 本步目标

Module F 执行网关接入：Broker 抽象与占位/仿真实现，E→F 衔接；place_order 调用可验证。

<a id="design-stage4-02-points"></a>
## 设计要点

- **BrokerDriver**：抽象与占位/仿真实现；**深度参考 [Vn.py](https://github.com/vnpy/vnpy) 的 Gateway 设计**（事件驱动、多柜台统一接口），与 [01_顶层概念/05_谛听优先借鉴的十大开源选型](../../01_顶层概念/05_谛听优先借鉴的十大开源选型.md) 一致。
- **E→F**：风控通过后指令至执行网关
- **验证**：单测或 place_order 调用验证

<a id="design-stage4-02-vnpy"></a>
### Vn.py 对接要点（实盘/仿真接入与验证）

本小节与 [Stage3-06 Module F 设计](../Stage3_模块实践/04_热路径判官风控与执行_设计.md#design-stage3-04-integration-vnpy) 中「逻辑填充期开源接入点：Vn.py」互补：Stage3-06 侧重接口形态与占位实现，本步侧重**实盘或仿真接入**与 E→F 验证。

- **实盘接入**：MiniQMT/xtquant 等柜台以「实现同一 BrokerDriver/Gateway 接口的适配器」形式接入；对接逻辑（CTP/IB/米筐等封装方式、Python 对接 C++ 柜台）应参考 Vn.py 的 Gateway 与多柜台工程实践，保障实盘稳定性（重连、订单状态同步、错单与拒单处理）。
- **仿真接入**：占位/仿真 Broker 在本步须在 Docker 或 K3s 下可运行，接收 E 层指令、模拟成交或拒绝、回写状态；便于全链路与回测/仿真验证无需实盘。
- **依赖与构建**：执行网关镜像的依赖与 [Stage3-06 Module F 设计](../Stage3_模块实践/04_热路径判官风控与执行_设计.md#design-stage3-04-integration-vnpy) 中「依赖与构建」一致，确保占位/仿真或实盘适配器在镜像内可运行。
- **验收**：E→F 衔接可验证（place_order 经 BrokerDriver 至占位或实盘适配器、状态回调可观测）；与 10_ 运营治理中的熔断与 RTO 要求一致。

<a id="design-stage4-02-dna-keys"></a>
## 本步落实的 _System_DNA 键

- `dna_stage4_02.yaml`；`abstraction_layer.broker_driver`、`core_modules`（Module F）

<a id="design-stage4-02-exit"></a>
## 准出

执行网关接入；E→F 衔接可验证；L5 [l5-stage-stage4_02](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage4_02) 可更新。
