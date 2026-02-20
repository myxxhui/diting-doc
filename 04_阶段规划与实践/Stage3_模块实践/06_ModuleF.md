# Phase1 · 按模块实践 · 06 · Module F 执行网关

> [!NOTE] **[TRACEBACK] 战略追溯锚点**
> - **顶层概念**: [一句话定义与核心价值](../../01_顶层概念/01_一句话定义与核心价值.md)
> - **战略维度**: [01_产品设计维度](../../02_战略维度/产品设计/01_产品设计维度.md)
> - **原子能力**: [09_核心模块架构规约](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md)（Module F）、[05_接口抽象层规约](../../03_原子目标与规约/_共享规约/05_接口抽象层规约.md)
> - **阶段**: [Phase1_按模块实践](README.md)

**本步设计文档**：[06_ModuleF设计](../../03_原子目标与规约/Stage3_模块实践/06_ModuleF设计.md#design-stage3-06-exit)  
**本步 DNA 文件**：[03_原子目标与规约/_System_DNA/Stage3_模块实践/dna_stage3_06.yaml](../../03_原子目标与规约/_System_DNA/Stage3_模块实践/dna_stage3_06.yaml)  
**逻辑填充期接入点**：本步须按设计文档中「逻辑填充期开源接入点：Vn.py（Gateway 与执行抽象）」小节实现并达标，见 [design-stage3-06-integration-vnpy](../../03_原子目标与规约/Stage3_模块实践/06_ModuleF设计.md#design-stage3-06-integration-vnpy)。

<a id="l4-step-nav"></a>
## 步骤导航
- **上一步**：[05_ModuleE](05_ModuleE.md#l4-stage3-05-goal)
- **下一步**：[07_全链路验证](07_全链路验证.md#l4-stage3-07-goal)

<a id="l4-stage3-06-goal"></a>
## 步骤目标

实现 Module F 执行网关，Redis Streams、OMS Lite、Broker 抽象、Human-in-the-Loop；完成 **四项 100% 验证**。

## 本步骤落实的 DNA 键

- `core_modules/dna_module_f.yaml`：`architecture`、`human_in_the_loop`、`order_splitting`

## 实现部分

**工作目录**：`diting-core`

1. 建立 `diting/execution` 或 `diting/drivers` 包
2. Broker 抽象（05_ 规约）；占位/仿真实现
3. 配置写 **YAML**；Human-in-the-Loop 审核状态可配置

## 验证部分

### 四项 100%

| 维度 | 验收标准 | 验证方法 |
|------|----------|----------|
| **接口 100%** | Broker 接口与 05_ 一致 | 契约单测 |
| **结构 100%** | 目录与 DNA 一致 | 目录与配置 |
| **逻辑功能 100%** | place_order 占位/仿真可调用 | 单测或集成 |
| **代码测试 100%** | 单测覆盖 Broker 抽象与占位 | `make test` 覆盖率 |

### 三层验证

- **单模块**：place_order 占位调用验证
- **联动**：E→F 衔接
- **全链路**：A→F 全链路真实数据产品逻辑验证（本步为最后一环）

## 核心指令（The Prompt）

```
你是在 diting-core 中实现 Module F 执行网关的开发者。必读：03_原子目标与规约/_共享规约/09_核心模块架构规约.md（Module F 小节）、03_原子目标与规约/_共享规约/05_接口抽象层规约.md、03_原子目标与规约/_System_DNA/core_modules/dna_module_f.yaml。

任务：1. 实现 Broker 抽象与占位（Gateway 式，深度参考 Vn.py）；2. 按设计文档「逻辑填充期开源接入点：Vn.py」小节实现并达标；3. 配置写 YAML；4. place_order 可调用；5. 单测覆盖。

工作目录：diting-core。代码含 [Ref: 06_ModuleF]。
```

<a id="l4-stage3-06-exit"></a>
## 验收与测试、DoD、本步骤失败时

同前；L3 逻辑填充期接入点（Vn.py Gateway）按设计文档达标；L5 [l5-mod-F](../../05_成功标识与验证/02_验收标准.md#l5-mod-F)、[l5-stage-stage3_06](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_06) 行已更新；**全链路 A→F 验证**在本步准出时执行。
