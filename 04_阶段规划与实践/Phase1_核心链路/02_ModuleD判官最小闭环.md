# Phase1 · 02 · Module D 判官最小闭环

> [!NOTE] **[TRACEBACK] 战略追溯锚点**
> - **顶层概念**: [一句话定义与核心价值](../../01_顶层概念/01_一句话定义与核心价值.md)
> - **战略维度**: [01_产品设计维度](../../02_战略维度/产品设计/01_产品设计维度.md)
> - **原子能力**: [09_核心模块架构规约](../../03_原子目标与规约/09_核心模块架构规约.md)（Module D）、[01_核心公式与MoE架构规约](../../03_原子目标与规约/01_核心公式与MoE架构规约.md)
> - **阶段**: [Phase1_核心链路](README.md)
> - **本步骤**: Module D 判官输入（Quant + 可选 Expert 占位）、Kelly 与 Alpha 输出、单测

## 步骤目标

- **L3 阶段目标**：核心链路最小可跑通 — Module D 判官接收 Quant 信号（与可选 Expert 占位），完成投票、动态凯利与 Alpha 输出，满足 [01_核心公式与MoE架构规约](../../03_原子目标与规约/01_核心公式与MoE架构规约.md) 中 Alpha = (Quant ∩ Router) × Kelly 的判官侧闭环。
- **本步目标**：实现 Module D 的投票机制（Quant Pass + Expert 占位）、动态凯利仓位计算、Alpha 输出接口；单测覆盖公式与边界（逻辑密集，须 5D 与测试锚定）。

## 关键产出物

1. 判官输入接口（Quant 信号 + Expert 占位）与投票逻辑（Quant Pass + 至少一个 Expert Strong Buy → 有效信号）
2. 动态凯利计算（公式与 [0,1] 截断、payoff_ratio≤0 防护）及单测
3. Alpha/Verdict 输出结构（action、win_rate_prediction、kelly_fraction、primary_reasoning）与下游契约一致
4. Table-Driven 单测至少 5 行用例，覆盖边界（kelly 截断、除零、Quant 不通过、Expert 不通过）
5. 与 09_/01_ 一致的接口与公式实现，L5 功能验收表「09_ Module D」一行已更新

## 本步骤可开始条件（Definition of Ready）

1. [01_ModuleA_B骨架与接口](01_ModuleA_B骨架与接口.md) 已完成（Module B 可产出符合契约的 Quant 信号）。
2. [Stage0_骨架期](../00_交付流程步骤/Stage0_骨架期/README.md)（s0）准出，工作目录 **diting-core** 可编译/可测。
3. [09_核心模块架构规约](../../03_原子目标与规约/09_核心模块架构规约.md) Module D、[01_核心公式与MoE架构规约](../../03_原子目标与规约/01_核心公式与MoE架构规约.md) 中公式与边界已定稿。

## 推荐模型（可选）

| 用途 | 推荐模型或档次 | 理由 |
|------|----------------|------|
| 设计/公式与测试表 | Claude 3.5 Sonnet 或 DeepSeek-R1 | 公式与边界理解、Table-Driven 用例生成稳定 |
| 代码实现 | 同上或 Cursor 默认 | 与 00_5D 范例一致实现 |
| 备选 | 由执行方自选 | 建议具备规约与单测理解能力 |

## 核心指令（The Prompt）

**简短版**（步骤内）：按 **5D 顺序** 执行：Design 锁死接口与 Kelly 公式、边界（见 [00_5D范例_ModuleD判官](../00_5D范例_ModuleD判官.md) 5D-1）；Drive 写 Table-Driven 测试表并先红灯（见 00_5D 5D-2）；Decompose 实现 vote、calcKelly、assembleAlpha（见 00_5D 5D-3）；Defense 全绿 + Review + L5 更新（见 00_5D 5D-4）。工作目录 `diting-core`；必读 09_ Module D、01_ 核心公式；输出：1. 变更文件列表 2. 关键类型/公式摘录 3. 单测命令与结果摘要。

**完整版**（可复制，含角色与必读）：见 [00_5D范例_ModuleD判官](../00_5D范例_ModuleD判官.md)；该文档含 Design/Drive/Decompose/Defense 四步的完整变量表、Kelly 公式、Table-Driven 用例表与原子函数列表，可直接作为 Prompt 喂给 AI 或人工执行。

## Prompt 使用说明

优先将 **00_5D范例_ModuleD判官** 全文作为必读 Context；若 Token 受限则保留 5D-1 变量与公式、5D-2 用例表、5D-3 原子函数表。执行后用「验收与测试」中的可复制命令自检，全绿且与 09_/01_ 一致再准出。

## 技术约束（DO / DON'T / 边界）

| 类型 | 内容 |
|------|------|
| **DO** | 投票规则与 09_ 一致（Quant>70 Pass，至少一个 Expert BULLISH）；Kelly 公式与 01_ 一致并截断 [0,1]；payoff_ratio≤0 不除零；Table-Driven 至少 5 行；工作目录 diting-core |
| **DON'T** | 不要改 00_5D 中锁死的公式与边界定义；不要跳过 Drive 先写实现 |
| **边界** | Expert 可为占位（空列表或 Mock）；占位须满足 09_ 接口与至少 1 条用例通过；见「占位边界」小节 |

## 必读顺序

1. [00_5D范例_ModuleD判官](../00_5D范例_ModuleD判官.md)（完整 5D 四步）
2. [09_核心模块架构规约](../../03_原子目标与规约/09_核心模块架构规约.md) Module D 小节
3. [01_核心公式与MoE架构规约](../../03_原子目标与规约/01_核心公式与MoE架构规约.md) Kelly 与 Alpha
4. 本步骤「实施内容」「验收与测试」

## 依赖的 Stage

- 依赖 [Stage0_骨架期](../00_交付流程步骤/Stage0_骨架期/README.md)（s0）准出、[Stage1_逻辑填充期](../00_交付流程步骤/Stage1_逻辑填充期/README.md)（s1）进行中。
- **前置 Phase 步骤**：[01_ModuleA_B骨架与接口](01_ModuleA_B骨架与接口.md) 已完成（Quant 信号可产出）。

## 前置条件

- Phase1 步骤 01_ 已完成：Module B 可产出符合契约的 Quant 信号。
- 工作目录 **diting-core**。

## 实施内容

**工作目录**：`diting-core`

1. **判官输入**
   - 定义并接收 Quant 信号（来自 Module B 的 technical_score、win_rate_prediction 等，见 01_核心公式与 09_）。
   - Expert 意见可为占位：空列表或 Mock 的 `ExpertOpinion`（is_supported、direction、reasoning_summary），满足「Quant Pass + 至少一个 Expert Strong Buy = 有效信号」的投票规则。

2. **投票机制**
   - 实现投票逻辑：Quant 得分 > 70 为 Pass；至少一个 Expert 支持且 BULLISH 为 Expert 通过；两者同时满足时输出有效信号及综合胜率（见 09_ Module D 投票机制）。

3. **动态凯利**
   - 实现凯利公式：`kelly_fraction = (win_rate × payoff_ratio - (1 - win_rate)) / payoff_ratio`，并按 01_核心公式与 09_ 约束限制在 [0.0, 1.0]；可选按 Expert 置信度调整（见 09_ DynamicKelly）。

4. **Alpha 输出**
   - 输出 Alpha 信号结构：含 action（BUY/PASS）、win_rate_prediction、kelly_fraction、primary_reasoning 等，与下游 Module E 或执行层契约一致。

5. **5D 与测试锚定**（逻辑密集）
   - **Design**：接口与数据结构、公式与边界条件在 L3 与本文档中锁死。
   - **Drive**：Table-Driven 单测：输入（quant_signal、expert_opinions、payoff_ratio），期望输出（Verdict、kelly_fraction）；覆盖边界：win_rate=0/1、payoff_ratio 极小/极大、kelly>1 截断、无 Expert 占位时仅 Quant 等。
   - **Decompose**：投票、凯利、Alpha 组装拆成可单测的原子函数（建议单函数 <50 行）。
   - **Defense**：单测全绿后人工 Code Review，确认业务规则与 09_/01_ 一致。

## 验收与测试

本节即本步骤验收标准。

**验收检查项**

- [ ] 投票逻辑与 09_ 一致：Quant Pass + Expert（占位）Strong Buy → 有效信号；否则 PASS。
- [ ] 凯利公式与 01_ 一致，输出在 [0.0, 1.0]，有 Table-Driven 单测覆盖边界。
- [ ] Alpha 输出结构可被下游消费（接口契约明确）。
- [ ] 本地单测全部通过（见下方可复制命令）。

**可复制测试命令**（工作目录：`diting-core`）

```bash
cd diting-core
go test ./diting/gavel/...
# 或与项目一致：go test ./internal/gavel/... 或 make test
```

**成功标准**：退出码 0，所有 Table-Driven 用例通过。**失败时**：见「本步骤失败时」与失败分级。**与 DoD 分工**：上列为功能/产物验收；DoD 负责提交、单测全绿、Review、L5 更新。

## 本步骤最小上下文

以下摘录供本步执行时最小可读上下文，完整范例见 [00_5D范例_ModuleD判官](../00_5D范例_ModuleD判官.md)。

- **Kelly 公式**：`kelly_fraction = (win_rate × payoff_ratio - (1 - win_rate)) / payoff_ratio`；约束 [0.0, 1.0]；payoff_ratio ≤ 0 不除零。
- **Verdict 字段**：action（BUY/PASS）、win_rate_prediction、kelly_fraction、primary_reasoning。
- **Table-Driven 用例（3 行示例）**：① technical_score=80, win_rate=0.6, payoff_ratio=2 → action=BUY, kelly≈0.4；② technical_score=60 → action=PASS；③ payoff_ratio=0 → 不 panic，kelly=0。

## 5D 执行顺序

| 5D 步 | 输出物 |
|-------|--------|
| 5D-1 Design | 接口与 Verdict/Kelly 公式、边界（payoff=0、kelly 截断）锁死；见上「本步骤最小上下文」与 00_5D 范例 |
| 5D-2 Drive | Table-Driven 测试表（至少 5 行）+ `*_test.go`，先红灯 |
| 5D-3 Decompose | vote、calcKelly、assembleAlpha 等原子函数实现，单测全绿 |
| 5D-4 Defense | `go test ./...` 全绿；Code Review 确认与 09_/01_ 一致；L5 对应行更新 |

## 本步骤失败时与失败分级

| 情形 | 分级 | 处理 |
|------|------|------|
| 单测不通过（公式/边界与 09_/01_ 不符） | **阻塞** | 回到 5D-2 Drive，核对用例与 01_/09_ 一致，修正实现或用例后再跑；修完再准出 |
| Review 发现投票规则或 Kelly 截断与 L3 不符 | **阻塞** | 列出差异项，先改设计/接口再改实现，重新单测与 Review |
| 依赖未就绪（01_ Module B 接口不存在） | **阻塞** | 先完成 [01_ModuleA_B骨架与接口](01_ModuleA_B骨架与接口.md)，再执行本步 |
| 命名/风格与项目不一致 | **建议修正** | 可记技术债后准出，或本步内修正 |

其余回退与策略见 [03_项目全功能开发测试实践工作流详细规划 八、失败与回退策略](../../03_原子目标与规约/开发与交付/03_项目全功能开发测试实践工作流详细规划.md)。

## 本步骤准出（DoD）

- [ ] 代码已提交至约定分支/目录（工作目录 diting-core）
- [ ] `go test ./...` 或 `make test` 在 diting-core 下全绿
- [ ] Code Review 通过（或标注豁免原因）
- [ ] 已更新 L5 [02_验收标准](../../05_成功标识与验证/02_验收标准.md) 中「09_ Module D」对应行（状态或验证方式）

## 占位边界

本步允许 **Expert 占位**（空列表或 Mock）。占位满足条件：① 接口与 09_ 一致（Verdict、ExpertOpinion 结构）；② 至少 1 条 Table-Driven 用例通过（如 Quant Pass + 1 个 Mock Expert BULLISH → BUY）；③ 不要求真实 Module C 调用。超出则视为需真实 Expert 接入。

## 产出物

| 产出 | 说明 |
|------|------|
| `gavel/voting.go`（或等价包路径） | 投票逻辑 |
| `gavel/kelly.go` | 凯利计算 |
| `gavel/verdict.go`（或与 voting 同包） | Alpha/Verdict 组装 |
| `gavel/*_test.go` | Table-Driven 单测 |

## 路径与命名

- **代码路径**：`diting-core/diting/gavel/`（或项目约定等价路径，见 [02_三位一体仓库规约](../../03_原子目标与规约/02_三位一体仓库规约.md)）。
- **业务词 → 英文**：判官 → Gavel；凯利 → Kelly；胜率 → WinRate；盈亏比 → PayoffRatio；裁决 → Verdict。

## L3 快照

本步骤依据 [09_核心模块架构规约](../../03_原子目标与规约/09_核心模块架构规约.md) Module D、[01_核心公式与MoE架构规约](../../03_原子目标与规约/01_核心公式与MoE架构规约.md) 当前版；若 L3 或 DNA 变更，须按 [01_L3_DNA_变更对L4影响表](../../06_追溯与审计/01_L3_DNA_变更对L4影响表.md) 复核本步。

## Phase–Stage 接口

- **本步准出即 Stage s1 准出条件之一**；本步验收命令（如 `make test` 覆盖 gavel 包）纳入 [Stage1_逻辑填充期 01_](../00_交付流程步骤/Stage1_逻辑填充期/01_本阶段实践与验证.md) 可执行验证清单。
- **本步产出**：供 Stage1 01_ 可执行验证清单使用。
- **本步依赖**：依赖 [Stage0_骨架期](../00_交付流程步骤/Stage0_骨架期/README.md)（s0）准出。

## 本步骤涉及的 DNA 键

| DNA 键 | 用途 |
|--------|------|
| `product_scope.phases` Phase1-xxx | 本 Phase 范围 |
| `core_modules.module_d`（若存在） | 判官配置与阈值（如 technical_score > 70） |
| `dna_01_core_formula_moe`（若存在） | 凯利公式与 Alpha 定义 |
| `dna_dev_workflow.workflow_stages[s1].delivery_scope` | 交付范围含 D 判官最小闭环 |

## 逻辑密集说明与人/AI 角色

本步骤涉及公式、边界与投票规则，**须走 5D**：Design 锁逻辑 → Drive 锚 Table-Driven 测试 → Decompose 拆原子 → Defense 人把关。测试锚定位置：diting-core 内 Module D 对应包下的 `*_test.go` 或等价。代码注释须标注 `[Ref: 02_ModuleD判官最小闭环]` 或 `[Ref: 03_09]`。

**人/AI 角色表**

| 5D 步 | 人 | AI |
|-------|----|-----|
| Design | 锁死公式、边界、用例表（或采纳 00_5D） | 理解并确认无歧义 |
| Drive | 定义 Table-Driven 用例（或采纳 00_5D） | 生成 `*_test.go`，先红灯 |
| Decompose | 拆原子函数职责 | 实现 vote、calcKelly、assembleAlpha |
| Defense | 运行单测、Code Review、确认与 09_/01_ 一致、L5 更新 | 根据失败日志与 Review 意见修复 |
