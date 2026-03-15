# Phase2 · 02 · Module F 执行网关接入

> [!NOTE] **[TRACEBACK] 战略追溯锚点**
> - **顶层概念**: [一句话定义与核心价值](../../01_顶层概念/01_一句话定义与核心价值.md)
> - **战略维度**: [01_产品设计维度](../../02_战略维度/产品设计/01_产品设计维度.md)、[08_经纪商解耦与冗余维度](../../02_战略维度/产品设计/08_经纪商解耦与冗余维度.md)
> - **原子能力**: [09_核心模块架构规约](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md)（Module F）、[05_接口抽象层规约](../../03_原子目标与规约/_共享规约/05_接口抽象层规约.md)
> - **阶段**: [Phase2_MoE与执行网关](README.md)
> - **本步骤**: 执行层抽象、Broker 驱动占位或仿真

**本步设计文档**：[02_ModuleF执行网关接入设计](../../03_原子目标与规约/Stage4_MoE与执行网关/02_ModuleF执行网关接入设计.md#design-stage4-02-exit)  
**本步 DNA 文件**：[03_原子目标与规约/_System_DNA/Stage4_MoE与执行网关/dna_stage4_02.yaml](../../03_原子目标与规约/_System_DNA/Stage4_MoE与执行网关/dna_stage4_02.yaml)  
**逻辑填充期接入点**：本步须按设计文档「Vn.py 对接要点」小节实现实盘/仿真接入与验证，见 [design-stage4-02-vnpy](../../03_原子目标与规约/Stage4_MoE与执行网关/02_ModuleF执行网关接入设计.md#design-stage4-02-vnpy)。

<a id="l4-step-nav"></a>
## 步骤导航
- **上一步**：[01_ModuleC_MoE议会接入](01_ModuleC_MoE议会接入.md#l4-stage4-01-goal)
- **下一步**：[03_回测或仿真验证](03_回测或仿真验证.md#l4-stage4-03-goal)

> [!IMPORTANT] **实践测试方式约定**
> 本步以**本地 Docker Compose**（或等价本地环境）为**主要（默认）**实践测试方式，可选 K3s/实盘；无云凭证或无需真实集群时**优先**使用本地 Compose 完成验收。见 [00_系统规则_通用项目协议](../../00_系统规则_通用项目协议.md)、[02_三位一体仓库规约](../../03_原子目标与规约/_共享规约/02_三位一体仓库规约.md)#本地开发与部署文件。

<a id="l4-stage4-02-goal"></a>
## 步骤目标

- **L3 阶段目标**：执行网关接入，策略与经纪商解耦；Module F 通过抽象接口对接 Redis Streams、OMS Lite、MiniQMT（xtquant）或 Human-in-the-Loop。
- **本步目标**：实现执行层抽象（BrokerDriver 或等价接口）、Broker 驱动占位或仿真实现，使 E 风控通过后的信号可进入执行流水线（可为占位/仿真，不真实下单）。

**依赖与构建**：执行网关镜像的依赖与 [04_热路径判官风控与执行_实践](../Stage3_模块实践/04_热路径判官风控与执行_实践.md) 及 dna_module_f.integration_packages 一致；确保占位/仿真或实盘适配器在镜像内可运行。

## 关键产出物

1. Broker 抽象接口与 05_ 一致（get_cash_balance、place_order 等）
2. 至少一个占位/仿真实现（MockBroker 或 BacktestBroker）可被调用
3. E 通过信号可流入执行层（占位或仿真），无真实资金风险
4. 单测或集成测试通过；L5 功能验收表「09_ Module F」一行已更新

## 本步骤可开始条件（Definition of Ready）

1. Phase1 03_ Module E 准出（E 可输出 Allow 及订单相关字段）。
2. 工作目录 **diting-core** 可编译/可测；若涉及 Redis/K8s 则 diting-infra 就绪。
3. [05_接口抽象层规约](../../03_原子目标与规约/_共享规约/05_接口抽象层规约.md)、[09_](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md) Module F 已定稿。

## 推荐模型（可选）

由执行方自选；可引用 [Phase2 README](README.md)。

## 核心指令（The Prompt）

请先阅读 03_原子目标与规约/_共享规约/05_接口抽象层规约.md、03_原子目标与规约/_共享规约/09_核心模块架构规约.md（Module F）、本步骤「实施内容」及设计文档「Vn.py 对接要点」小节。任务：1. 定义 Broker 抽象接口（与 05_ 一致，深度参考 Vn.py Gateway）；2. 按设计文档「Vn.py 对接要点」实现实盘/仿真接入并达标；3. 实现至少一个占位/仿真（MockBroker 或 BacktestBroker）；4. E 通过信号可转换为 TradeOrder 并调用 place_order；5. 单测通过。工作目录 diting-core。请输出：变更文件列表、关键接口摘录、单测命令与结果摘要。

## Prompt 使用说明

将核心指令与 05_、09_ Module F 一起喂给 AI；执行后用「验收与测试」中的可复制命令自检。

## 技术约束（DO / DON'T / 边界）

| 类型 | 内容 |
|------|------|
| **DO** | 接口与 05_ 一致；占位/仿真不真实下单；E→F 订单结构与 09_ 一致；工作目录 diting-core |
| **DON'T** | 不要在本步引入真实 Broker 或真实资金操作 |
| **边界** | 本步允许占位/仿真；**占位替换**：真实 Broker 适配与订单状态机见 [Phase2 README 占位与真实实现衔接](README.md#占位与真实实现衔接)（05_、实盘环境接入） |

## 必读顺序

1. [05_接口抽象层规约](../../03_原子目标与规约/_共享规约/05_接口抽象层规约.md)
2. [09_核心模块架构规约](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md) Module F
3. 本步骤「实施内容」「验收与测试」

## 依赖的 Stage

- 依赖 [Stage1_仓库与骨架](../Stage1_仓库与骨架/README.md) 或 [Stage2_数据采集与存储](../Stage2_数据采集与存储/README.md) 进行中。
- **前置 Phase 步骤**：[01_ModuleC_MoE议会接入](01_ModuleC_MoE议会接入.md) 可选；Phase1 的 E 风控输出已存在即可。

## 前置条件

- Phase1 准出：E 可输出 Allow 及订单相关字段（symbol、quantity、side 等）。
- 工作目录 **diting-core**（接口与占位实现同仓；部署侧为 diting-infra 若涉及 Redis/K8s）。

## 实施内容

**工作目录**：`diting-core`

1. **执行层抽象**
   - 按 [05_接口抽象层规约](../../03_原子目标与规约/_共享规约/05_接口抽象层规约.md) 定义 Broker 抽象接口（如 get_cash_balance、get_positions、place_order、cancel_order、get_order_status），与 09_ Module F 及研产同构目标一致。

2. **Broker 驱动占位或仿真**
   - 实现至少一个 BrokerDriver 实现：**BacktestBroker** 或 **MockBroker**（占位），不真实下单；可写 Redis Streams 或内存队列，供后续 OMS/MiniQMT 消费。
   - 若项目约定先走仿真：仿真实现与回测使用同一套接口，满足「研产同构」。

3. **E → F 衔接**
   - E 风控通过后的信号可转换为标准订单结构（如 TradeOrder），调用 BrokerDriver.place_order（占位实现可仅落日志或写入队列）。

## 验收与测试

本节即本步骤验收标准。

**验收检查项**

- [ ] Broker 抽象接口与 05_ 一致；至少一个占位/仿真实现可被调用。
- [ ] E 通过信号可流入执行层（占位或仿真），无真实资金风险。
- [ ] 单测或集成测试通过（见下方可复制命令）；place_order 等调用可验证。

**可复制测试命令**（工作目录：`diting-core`）

```bash
cd diting-core
make test
# 或：go test ./diting/broker/...
```

**成功标准**：退出码 0。**失败时**：见「本步骤失败时」。**与 DoD 分工**：上列为功能/产物验收；DoD 负责提交、单测、Review、L5 更新。

<a id="l4-stage4-02-exit"></a>
## 本步骤准出（DoD）

- [ ] 代码已提交至约定分支/目录（工作目录 diting-core）
- [ ] Broker 抽象接口与至少一个占位/仿真实现存在，单测或集成测试通过
- [ ] Code Review 通过（或标注豁免）
- [ ] L3 Vn.py 对接要点按设计文档达标；已更新 L5 [02_验收标准](../../05_成功标识与验证/02_验收标准.md) 中**功能验收表**「09_ Module F」一行及 [l5-stage-stage4_02](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage4_02)（状态与验证方式）

## 输出格式 / 期望交付形态

1. 变更/新增文件列表；2. 关键接口摘录（BrokerDriver、TradeOrder）；3. 单测命令与结果摘要

## 下一步

完成本步且通过验收、DoD 全勾后，进入 [03_回测或仿真验证](03_回测或仿真验证.md)。**重要**：03_ 依赖 C 与 F 已接入，回测/仿真使用同一套 Broker 抽象。

## 产出物

| 产出 | 说明 |
|------|------|
| 执行层抽象接口（BrokerDriver 或等价） | 与 05_ 一致：get_cash_balance、place_order 等 |
| 至少一个 Broker 实现（Mock/Backtest） | 可被 E 通过信号调用，不真实下单 |
| E→F 衔接代码或测试 | 订单结构转换与 place_order 调用可验证 |

## 本步骤失败时

- **接口与 05_ 不一致**：对照 [05_接口抽象层规约](../../03_原子目标与规约/_共享规约/05_接口抽象层规约.md) 修正方法签名与契约。
- **E 信号无法流入**：确认 E 输出（Allow 及 symbol、quantity、side 等）与 TradeOrder/place_order 输入结构一致。
- **依赖未就绪**：确认 Phase1 03_ Module E 准出；否则先完成 Phase1。

回退与失败分级见 [03_项目全功能开发测试实践工作流详细规划 八、失败与回退策略](../../03_原子目标与规约/开发与交付/03_项目全功能开发测试实践工作流详细规划.md)。

## Phase–Stage 接口

- **本步准出即 Stage s2 准出条件之一**；本步验收命令纳入 [Stage2_数据采集与存储 01_](../Stage2_数据采集与存储/01_基础设施与依赖实践.md#l4-stage2-01-exit) 可执行验证清单。
- **本步产出**：供 Stage2 01_ 与 [03_回测或仿真验证](03_回测或仿真验证.md) 使用；回测/仿真使用同一套 Broker 抽象。
- **本步依赖**：依赖 [Stage1_仓库与骨架](../Stage1_仓库与骨架/README.md) 或 [Stage2](../Stage2_数据采集与存储/README.md) 进行中；依赖 Stage3 Module E 准出。

## 路径与命名

- **代码路径**：`diting-core/diting/abstraction/` 或 `broker/`（Broker 接口）、`diting-core/diting/broker/mock.go` 或 `backtest.go`（占位/仿真实现）；以项目 [02_三位一体仓库规约](../../03_原子目标与规约/_共享规约/02_三位一体仓库规约.md) 为准。
- **业务词 → 英文**：执行网关 → Execution Gateway / BrokerDriver；经纪商 → Broker；下单 → place_order；订单 → TradeOrder。

## 本步骤涉及的 DNA 键

| DNA 键 | 用途 |
|--------|------|
| `product_scope.phases` Phase2-xxx | 本 Phase 范围 |
| `core_modules.module_f`（若存在） | 执行网关与 Broker 配置 |
| `data_architecture`（若存在） | Redis Streams 等数据层约定 |
| `dna_stage4_02.semantic_refs`、`global_const.abstraction_layer.broker_driver` | 接口抽象约定（见本步 DNA） |

## 逻辑密集说明

本步骤以接口与驱动占位为主，**不强制 5D**；若含订单状态机或重试逻辑可对关键分支做单测。代码注释可标注 `[Ref: 02_ModuleF执行网关接入]` 或 `[Ref: 03_05]`。
