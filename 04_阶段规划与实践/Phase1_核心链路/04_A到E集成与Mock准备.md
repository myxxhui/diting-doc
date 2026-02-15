# Phase1 · 04 · A 到 E 集成与 Mock 准备

> [!NOTE] **[TRACEBACK] 战略追溯锚点**
> - **顶层概念**: [一句话定义与核心价值](../../01_顶层概念/01_一句话定义与核心价值.md)
> - **战略维度**: [01_产品设计维度](../../02_战略维度/产品设计/01_产品设计维度.md)
> - **原子能力**: [09_核心模块架构规约](../../03_原子目标与规约/09_核心模块架构规约.md)、[01_需求与产品范围](../../03_原子目标与规约/产品设计/01_需求与产品范围.md)
> - **阶段**: [Phase1_核心链路](README.md)
> - **本步骤**: A→B→D→E 最小路径串起，Table-Driven 或 Mock 可跑通，为 s1b 做准备

## 步骤目标

- **L3 阶段目标**：核心链路最小可跑通 — 从 Module A 到 Module E 的最小路径可串起，本地或 Mock 数据下可跑通，满足 Stage1 准出并为 [Stage1b_Mock数据验证准出](../00_交付流程步骤/Stage1b_Mock数据验证准出/README.md) 做准备。
- **本步目标**：在 diting-core 内实现或验证 A→B→D→E 的调用链（可全部或部分使用 Table-Driven/Mock 数据）；验收与 Stage1/Stage1b 的 exit_criteria 对齐。

## 关键产出物

1. A→B→D→E 最小路径可执行（单次调用或集成测试可跑通）
2. 至少一组 Table-Driven 或 Mock 用例覆盖该路径，结果可判定（Allow/Reject 与原因符合预期）
3. 与 Stage1 准出条件一致；为 Stage1b 准备的 Mock 数据或入口已就绪（文档或代码标注）
4. 集成测试或主路径可执行命令（如 `make integration-test`）

## 本步骤可开始条件（Definition of Ready）

1. Phase1 [01_](01_ModuleA_B骨架与接口.md)、[02_](02_ModuleD判官最小闭环.md)、[03_](03_ModuleE风控占位.md) 均已准出。
2. 工作目录 **diting-core** 可编译、单测可运行。
3. [Stage1 01_](../00_交付流程步骤/Stage1_逻辑填充期/01_本阶段实践与验证.md) exit_criteria 已可引用。

## 推荐模型（可选）

由执行方自选；可引用 [Phase1 README](README.md)。

## 核心指令（The Prompt）

请先阅读 [09_核心模块架构规约](../../03_原子目标与规约/09_核心模块架构规约.md)、本步骤「实施内容」。任务：1. 在 diting-core 内实现或组装 A→B→D→E 调用链（可 Mock）；2. 至少一组 Table-Driven 或集成用例覆盖路径，期望 E 的 Allow/Reject；3. 为 s1b 准备 Mock 数据格式或入口，与 09_/01_ 一致。工作目录 diting-core。请输出：变更文件列表、集成命令、Mock 入口说明、单测/集成结果摘要。

## Prompt 使用说明

将核心指令与 09_ 契约一起喂给 AI；执行后用「验收与测试」中的可复制命令自检。

## 技术约束（DO / DON'T / 边界）

| 类型 | 内容 |
|------|------|
| **DO** | 调用链与 09_ 契约一致；Mock 数据格式与 01_/09_ 一致；验收与 Stage1 exit_criteria 对齐；工作目录 diting-core |
| **DON'T** | 不要依赖真实行情或外部服务（本步可用内存/Mock） |
| **边界** | 数据源可为内存/Mock；为 s1b 准备的 Mock 可后续在 Stage1b 替换 |

## 必读顺序

1. [09_核心模块架构规约](../../03_原子目标与规约/09_核心模块架构规约.md)（A/B/D/E 接口串联）
2. [Stage1 01_](../00_交付流程步骤/Stage1_逻辑填充期/01_本阶段实践与验证.md) exit_criteria
3. 本步骤「实施内容」「验收与测试」

## 依赖的 Stage

- 依赖 [Stage0_骨架期](../00_交付流程步骤/Stage0_骨架期/README.md)（s0）准出、[Stage1_逻辑填充期](../00_交付流程步骤/Stage1_逻辑填充期/README.md)（s1）进行中。
- **前置 Phase 步骤**：[01_ModuleA_B骨架与接口](01_ModuleA_B骨架与接口.md)、[02_ModuleD判官最小闭环](02_ModuleD判官最小闭环.md)、[03_ModuleE风控占位](03_ModuleE风控占位.md) 已完成。

## 前置条件

- Phase1 步骤 01_、02_、03_ 均已完成。
- 工作目录 **diting-core**（集成与 Mock 代码同仓）。

## 实施内容

**工作目录**：`diting-core`

1. **最小路径串联**
   - 实现或组装一条调用链：输入（如标的代码或 Mock 标的）→ A 分类 → B 量化信号 → D 判官（投票 + Kelly）→ E 风控（Allow/Reject）。
   - 数据源可为内存/Mock：如固定标的、预置 OHLCV 或技术得分，不依赖真实行情或外部服务。

2. **Table-Driven 或 Mock**
   - 至少一组 Table-Driven 用例或集成测试：给定输入（如 symbol、Mock Quant 输出），期望链路过一遍后得到 E 的 Allow 或 Reject 及可追溯的中间结果（Alpha、kelly_fraction、风控原因）。
   - 为 s1b 准备的 Mock 数据格式与 01_需求与产品范围、09_ 契约一致，便于 Stage1b 替换为统一 Mock 数据集。

3. **验收与 Stage1/Stage1b 对齐**
   - 满足 [Stage1 01_本阶段实践与验证](../00_交付流程步骤/Stage1_逻辑填充期/01_本阶段实践与验证.md) 的 exit_criteria：业务逻辑按 L3 与 5D 填充完毕；本地单测 + 必要集成测试通过。
   - 集成测试或主路径可执行（如 `make integration-test` 或等价），为 s1b 提供可验证入口。

## 验收与测试

本节即本步骤验收标准。

**验收检查项**

- [ ] A→B→D→E 最小路径可执行（单次调用或集成测试可跑通）。
- [ ] 至少一组 Table-Driven 或 Mock 用例覆盖该路径，结果可判定（Allow/Reject 与原因符合预期）。
- [ ] 与 Stage1 准出条件一致；为 Stage1b 准备的 Mock 数据或入口已就绪（文档或代码标注）。

**可复制测试命令**（工作目录：`diting-core`）

```bash
cd diting-core
make test
# 集成：make integration-test 或等价
```

**成功标准**：退出码 0，路径跑通、用例符合预期。**失败时**：见「本步骤失败时」。**与 DoD 分工**：上列为功能/产物验收；DoD 负责提交、测试、Review、L5 更新。

## 本步骤准出（DoD）

- [ ] 代码已提交至约定分支/目录（工作目录 diting-core）
- [ ] A→B→D→E 最小路径可执行，单测或集成测试通过（`make test` / `make integration-test` 或等价）
- [ ] Code Review 通过（或标注豁免）
- [ ] 已更新 L5 [02_验收标准](../../05_成功标识与验证/02_验收标准.md) 中**功能验收表**本 Phase/Stage1 对应行（状态与验证方式）；为 Stage1b 准备的 Mock 入口已标注或文档化

## 输出格式 / 期望交付形态

1. 变更/新增文件列表与集成调用链说明
2. 集成测试命令与 Mock 入口说明
3. 单测/集成结果摘要

## 下一步

完成本步且通过验收、DoD 全勾后，Phase1 核心链路准出；可进入 [Stage1b_Mock数据验证准出](../00_交付流程步骤/Stage1b_Mock数据验证准出/README.md) 或 [Stage2_Docker统一环境期](../00_交付流程步骤/Stage2_Docker统一环境期/README.md)。**重要**：与 Stage1 准出条件对齐后再进入后续 Stage。

## 产出物

| 产出 | 说明 |
|------|------|
| 集成调用链代码（或测试/主入口） | A→B→D→E 串联，可 Table-Driven 或 Mock 跑通 |
| Mock 数据格式或入口 | 与 01_需求与产品范围、09_ 契约一致，供 Stage1b 使用 |
| 集成测试用例或主路径可执行命令 | 如 `make integration-test` |

## 本步骤失败时

- **路径跑不通**：逐模块检查 A/B/D/E 接口与调用顺序，确认 01_/02_/03_ 均已准出且接口未变。
- **Mock 数据与契约不一致**：对照 09_、01_ 修正 Mock 字段与类型，确保 Stage1b 可复用。
- **Stage1 准出未满足**：对照 [Stage1 01_](../00_交付流程步骤/Stage1_逻辑填充期/01_本阶段实践与验证.md) exit_criteria，补全单测或集成用例。

回退与失败分级见 [03_项目全功能开发测试实践工作流详细规划 八、失败与回退策略](../../03_原子目标与规约/开发与交付/03_项目全功能开发测试实践工作流详细规划.md)。

## Phase–Stage 接口

- **本步准出即 Stage s1 准出条件之一**，并纳入 [Stage1_逻辑填充期 01_](../00_交付流程步骤/Stage1_逻辑填充期/01_本阶段实践与验证.md)、[Stage1b_Mock数据验证准出 01_](../00_交付流程步骤/Stage1b_Mock数据验证准出/01_本阶段实践与验证.md) 可执行验证清单。
- **本步产出**：供 Stage1b 01_ 与 Stage1 可执行验证清单使用；Mock 入口与数据格式供 s1b 验证。
- **本步依赖**：依赖 [Stage0_骨架期](../00_交付流程步骤/Stage0_骨架期/README.md)（s0）准出；依赖 Phase1 [01_](01_ModuleA_B骨架与接口.md)、[02_](02_ModuleD判官最小闭环.md)、[03_](03_ModuleE风控占位.md) 准出。

## 本步骤涉及的 DNA 键

| DNA 键 | 用途 |
|--------|------|
| `product_scope.phases` Phase1-xxx | 本 Phase 范围 |
| `dna_dev_workflow.workflow_stages[s1].exit_criteria` | 准出条件对齐 |
| `dna_dev_workflow.workflow_stages[s1b]`（若存在） | 为 s1b Mock 验证准备 |

## 逻辑密集说明

本步骤以集成与数据流为主，**不强制全 5D**；若集成路径中含复杂分支可对关键分支做 Table-Driven 用例。代码注释可标注 `[Ref: 04_A到E集成与Mock准备]` 或 `[Ref: 03_09]`。
