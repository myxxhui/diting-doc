# L3 · Stage3-06 Module F 设计

> [!NOTE] **[TRACEBACK] 原子规约锚点**
> - **05_ 对应项**: [01_顶层概念/05_谛听优先借鉴的十大开源选型](../../01_顶层概念/05_谛听优先借鉴的十大开源选型.md) 第 1 项（Vn.py）
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

<a id="design-stage3-06-integration-vnpy"></a>
### 逻辑填充期开源接入点：Vn.py（Gateway 与执行抽象）（Phase1 必选）

- **实践重点**：执行层采用 **Gateway 式**抽象：事件驱动、统一接口（连接、订阅、下单、撤单、成交流水），多柜台（CTP/IB/MiniQMT/xtquant 等）通过适配器实现同一 Gateway 接口；逻辑填充期至少完成接口定义与占位/仿真实现，实盘柜台可后续接入。保障实盘稳定性：接口设计要考虑重连、订单状态同步、错单与拒单处理，与 09_ Module F、10_ 运营治理中的熔断与 RTO 一致。
- **详细需求**：
  - **Gateway 接口**：列出与 Vn.py 对齐的核心方法（如 connect、subscribe、send_order、cancel_order、on_tick、on_order、on_trade）及事件回调契约；BrokerDriver 与 OMS Lite、Redis Streams 的衔接方式。
  - **占位/仿真实现**：逻辑填充期必须实现至少一个「仿真 Broker」：接收 order 请求、按规则模拟成交或拒绝、回写状态到 Redis/OMS；便于 E→F 与全链路 A→F 验证无需实盘。
  - **实盘对接路线**：明确后续实盘接入时，MiniQMT/xtquant 等将以「实现同一 Gateway 接口的适配器」形式接入；可简要列出 Vn.py 中对应柜台的参考点（如 C++ 封装、事件循环）。
  - **依赖与构建**：在 requirements 中显式声明 Vn.py 或 Gateway 相关包（如 `vnpy` 或项目采用的子包）；若实盘对接 CTP 等需系统库或运行时，在 Dockerfile 中说明。构建后 place_order 占位/仿真相关单测在镜像内可运行。
- **验收要点**：place_order 经 BrokerDriver 调用占位实现可验证；单测覆盖「下单 → 状态回调」路径；接口与 05_ 接口抽象层规约一致。实盘/仿真接入的进一步验证见 [Stage4-02 ModuleF 执行网关接入设计](../Stage4_MoE与执行网关/02_ModuleF执行网关接入设计.md)。

<a id="design-stage3-06-exit"></a>
## 准出

Module F 四项 100%；全链路 A→F 验证通过；L5 [l5-stage-stage3_06](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_06) 可更新。
