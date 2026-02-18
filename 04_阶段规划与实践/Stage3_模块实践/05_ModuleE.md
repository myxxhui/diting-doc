# Phase1 · 按模块实践 · 05 · Module E 风控盾

> [!NOTE] **[TRACEBACK] 战略追溯锚点**
> - **顶层概念**: [一句话定义与核心价值](../../01_顶层概念/01_一句话定义与核心价值.md)
> - **战略维度**: [01_产品设计维度](../../02_战略维度/产品设计/01_产品设计维度.md)
> - **原子能力**: [09_核心模块架构规约](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md)（Module E）
> - **阶段**: [Phase1_按模块实践](README.md)

**本步设计文档**：[05_ModuleE设计](../../03_原子目标与规约/Stage3_模块实践/05_ModuleE设计.md#design-stage3-05-exit)  
**本步 DNA 文件**：[03_原子目标与规约/_System_DNA/Stage3_模块实践/dna_stage3_05.yaml](../../03_原子目标与规约/_System_DNA/Stage3_模块实践/dna_stage3_05.yaml)

<a id="l4-step-nav"></a>
## 步骤导航
- **上一步**：[04_ModuleD](04_ModuleD.md#l4-stage3-04-goal)
- **下一步**：[06_ModuleF](06_ModuleF.md#l4-stage3-06-goal)

<a id="l4-stage3-05-goal"></a>
## 步骤目标

实现 Module E 风控盾，硬止损 2%、盈亏比 ≥ 1.5、组合相关性限制；完成 **四项 100% 验证**。

## 本步骤落实的 DNA 键

- `core_modules/dna_module_e.yaml`：`hard_stop_loss`、`payoff_ratio`、`correlation_limit`

## 实现部分

**工作目录**：`diting-core`

1. 建立 `diting/risk` 包，实现 RiskShield
2. 输入：CouncilVerdict、PortfolioState；输出通过/否决及原因
3. 规则阈值写 **YAML 配置**（硬止损 2%、盈亏比 1.5 等）

## 验证部分

### 四项 100%

| 维度 | 验收标准 | 验证方法 |
|------|----------|----------|
| **接口 100%** | 风控接口与 09_ 一致 | 契约单测 |
| **结构 100%** | risk 目录、config 与 DNA 一致 | 目录与配置 |
| **逻辑功能 100%** | 规则由 YAML 驱动；拦截率 100% 验证 | 单测 + 高波动模拟 |
| **代码测试 100%** | 单测覆盖各规则路径 | `make test` 覆盖率 |

### 三层验证

- **单模块**：Mock Verdict，验证通过/否决逻辑
- **联动**：D+E 联调
- **全链路**：参与 A→F 验证

## 核心指令（The Prompt）

```
你是在 diting-core 中实现 Module E 风控盾的开发者。必读：03_原子目标与规约/_共享规约/09_核心模块架构规约.md（Module E 小节）、03_原子目标与规约/_System_DNA/core_modules/dna_module_e.yaml。

任务：1. 实现 RiskShield；2. 规则阈值写 YAML；3. 单测覆盖硬止损、盈亏比、相关性；4. 高波动模拟验证拦截率 100%。

工作目录：diting-core。代码含 [Ref: 05_ModuleE]。
```

<a id="l4-stage3-05-exit"></a>
## 验收与测试、DoD、本步骤失败时

同前；L5 [l5-mod-E](../../05_成功标识与验证/02_验收标准.md#l5-mod-E)、[l5-stage-stage3_05](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_05) 行已更新。
