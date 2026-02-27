# Stage1-02 核心接口与 Proto 占位

> [!NOTE] **[TRACEBACK] 步骤锚点**
> - **原子规约**: [_共享规约/04_全链路通信协议矩阵](../../03_原子目标与规约/_共享规约/04_全链路通信协议矩阵.md)、[_共享规约/05_接口抽象层规约](../../03_原子目标与规约/_共享规约/05_接口抽象层规约.md)
> - **DNA stage_id**: `stage1_02`
> - **本步设计文档**: [02_核心接口与Proto设计](../../03_原子目标与规约/Stage1_仓库与骨架/02_核心接口与Proto设计.md#design-stage1-02-exit)
> - **本步 DNA 文件**: [dna_stage1_02.yaml](../../03_原子目标与规约/_System_DNA/Stage1_仓库与骨架/dna_stage1_02.yaml)

<a id="l4-step-nav"></a>
## 步骤导航
- **上一步**：[01_三位一体仓库初始化](01_三位一体仓库初始化.md#l4-stage1-01-goal)
- **下一步**：[03_基础设施ECS与K3s_实践](03_基础设施ECS与K3s_实践.md#l4-stage1-03-goal)

> [!IMPORTANT] **实践测试方式约定**
> 本步以**本地 Docker Compose**（或等价本地环境）为**主要（默认）**实践测试方式，可选 K3s/实盘；无云凭证或无需真实集群时**优先**使用本地 Compose 完成验收。见 [00_系统规则_通用项目协议](../../00_系统规则_通用项目协议.md)、[02_三位一体仓库规约](../../03_原子目标与规约/_共享规约/02_三位一体仓库规约.md)#本地开发与部署文件。

<a id="l4-stage1-02-goal"></a>
## 本步目标
核心接口与 Proto 占位；make test 通过。

## 工作目录

**diting-core** 根目录

## 本步骤落实的 DNA 键

`dna_dev_workflow.workflow_stages[stage1_02]`、`global_const.trinity_repos.repo_i`

## 核心指令

```
你是在 diting-core 中执行 Stage1-02（核心接口与 Proto 占位）的开发者。必读：dna_dev_workflow.workflow_stages[stage1_02]、03_原子目标与规约/_共享规约/04_全链路通信协议矩阵.md、03_原子目标与规约/_共享规约/05_接口抽象层规约.md。

任务：
1. 按 repo_i.directories 建立目录：diting/abstraction/、drivers/、moe/、risk/、strategy/、tests/、design/。
2. 定义核心接口（Protocol/抽象类），与 03_原子目标与规约/_共享规约/04_全链路通信协议矩阵.md、03_原子目标与规约/_共享规约/05_接口抽象层规约.md 对齐。
3. Proto 占位：brain/expert.proto、verdict.proto、execution/order.proto、classifier/classifier_output.proto、quant/quant_signal.proto、trade_signal.proto、risk/telemetry.proto。
4. 为关键接口编写占位实现或 Mock，使「导入 + 最小调用」可运行；make test 可运行。
```

<a id="l4-stage1-02-exit"></a>
## 验证与准出

### 可执行验证

| 命令 | 工作目录 | 期望结果 |
|------|----------|----------|
| `make test` | diting-core | 退出码 0；单测全绿 |

### 接口/Proto 逐项验收

| 名称 | 作用/设计目标 | 验收 |
|------|---------------|------|
| **Proto** | | |
| `expert.proto` | 规范 MoE 专家辩论输出（ExpertOpinion、认知边界、双轨分流） | □ |
| `verdict.proto` | 判官裁决书（CouncilVerdict），下发执行层 | □ |
| `order.proto` | 执行层与券商交互（TradeOrder、人工审核、幂等） | □ |
| `classifier_output.proto` | 语义分类器输出（Domain Tag、置信度） | □ |
| `quant_signal.proto` | 量化扫描输出（technical_score、strategy_source） | □ |
| `trade_signal.proto` | 判官至执行层统一格式；核心公式 Alpha 输出形态 | □ |
| `telemetry.proto` | 风控遥测（PortfolioState）：回撤监控、利润锁定线、支撑 A 轨生存底线 | □ |
| **接口** | | |
| `BrokerDriver` | 交易网关抽象：研产同构、经纪商解耦 | □ |
| `CognitiveEngine` | 认知引擎抽象：模型切换、Mock 测试 | □ |
| `MarketDataFeed` | 行情数据源抽象：冷热分离、数据校验 | □ |

**准出**：上表全部勾选通过 + `make test` 退出码 0；**已更新 L5 [02_验收标准 对应行](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage1_02)**。
