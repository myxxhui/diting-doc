# Phase1 · 按模块实践 · 03 · Module C MoE 议会

> [!NOTE] **[TRACEBACK] 战略追溯锚点**
> - **顶层概念**: [一句话定义与核心价值](../../01_顶层概念/01_一句话定义与核心价值.md)
> - **战略维度**: [01_产品设计维度](../../02_战略维度/产品设计/01_产品设计维度.md)
> - **原子能力**: [09_核心模块架构规约](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md)（Module C）、[Expert Protocol](../../03_原子目标与规约/_共享规约/04_全链路通信协议矩阵.md)
> - **阶段**: [Phase1_按模块实践](README.md)

**本步设计文档**：[03_ModuleC设计](../../03_原子目标与规约/Stage3_模块实践/03_ModuleC设计.md#design-stage3-03-exit)  
**本步 DNA 文件**：[03_原子目标与规约/_System_DNA/Stage3_模块实践/dna_stage3_03.yaml](../../03_原子目标与规约/_System_DNA/Stage3_模块实践/dna_stage3_03.yaml)

<a id="l4-step-nav"></a>
## 步骤导航
- **上一步**：[02_ModuleB](02_ModuleB.md#l4-stage3-02-goal)
- **下一步**：[04_ModuleD](04_ModuleD.md#l4-stage3-04-goal)

<a id="l4-stage3-03-goal"></a>
## 步骤目标

实现 Module C MoE 议会，Router 按 Domain Tag 分发、专家输出 ExpertOpinion；完成 **四项 100% 验证**。

## 本步骤落实的 DNA 键

- `core_modules/dna_module_c.yaml`：`module_c_moe_council.router`、`sub_agents`

## 实现部分

**工作目录**：`diting-core`

1. 建立 `diting/moe` 包，实现 `MoERouter`、Agri/Tech/Geo Agent
2. 输入：symbol、ClassifierOutput、QuantSignal；输出 `ExpertOpinion` 列表
3. Router 规则与专家权重写 **YAML 配置**
4. 专家占位或 LLM 接入按项目约定

## 验证部分

### 四项 100%

| 维度 | 验收标准 | 验证方法 |
|------|----------|----------|
| **接口 100%** | ExpertOpinion 符合 expert.proto | 契约单测 |
| **结构 100%** | moe 目录、config 与 DNA 一致 | 目录与配置验证 |
| **逻辑功能 100%** | Router 按 Tag 正确分发；专家输出 is_supported、confidence | 配置驱动 + 真实/模拟数据 |
| **代码测试 100%** | 单测覆盖 Router、各 Agent、Trash Bin | `make test` 覆盖率 |

### 三层验证

- **单模块**：Mock A/B 输出，验证 Router 分发与专家输出
- **联动**：A+B+C 联调，C 消费 A/B 输出
- **全链路**：参与 A→F 全链路验证

## 核心指令（The Prompt）

```
你是在 diting-core 中实现 Module C MoE 议会的开发者。必读：03_原子目标与规约/_共享规约/09_核心模块架构规约.md（Module C 小节）、03_原子目标与规约/_System_DNA/core_modules/dna_module_c.yaml、expert.proto。

任务：1. 实现 MoERouter、Agri/Tech/Geo Agent；2. Router 规则写 YAML；3. 单测覆盖 AGRI/TECH/GEO/UNKNOWN 分发；4. ExpertOpinion 契约满足。

工作目录：diting-core。代码含 [Ref: 03_ModuleC]。
```

<a id="l4-stage3-03-exit"></a>
## 验收与测试、DoD、本步骤失败时

同 01_/02_ 模板；L5 [l5-mod-C](../../05_成功标识与验证/02_验收标准.md#l5-mod-C)、[l5-stage-stage3_03](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_03) 行已更新。
