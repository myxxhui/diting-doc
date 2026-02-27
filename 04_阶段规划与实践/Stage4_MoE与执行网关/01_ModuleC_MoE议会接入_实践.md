# Phase2 · 01 · Module C MoE 议会接入

> [!NOTE] **[TRACEBACK] 战略追溯锚点**
> - **顶层概念**: [一句话定义与核心价值](../../01_顶层概念/01_一句话定义与核心价值.md)
> - **战略维度**: [01_产品设计维度](../../02_战略维度/产品设计/01_产品设计维度.md)
> - **原子能力**: [09_核心模块架构规约](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md)（Module C）、[01_核心公式与MoE架构规约](../../03_原子目标与规约/_共享规约/01_核心公式与MoE架构规约.md)
> - **阶段**: [Phase2_MoE与执行网关](README.md)
> - **本步骤**: Router、专家调用与投票/聚合，与 D 的 Alpha 链路对接

**本步设计文档**：[01_ModuleC_MoE议会接入设计](../../03_原子目标与规约/Stage4_MoE与执行网关/01_ModuleC_MoE议会接入设计.md#design-stage4-01-exit)  
**本步 DNA 文件**：[03_原子目标与规约/_System_DNA/Stage4_MoE与执行网关/dna_stage4_01.yaml](../../03_原子目标与规约/_System_DNA/Stage4_MoE与执行网关/dna_stage4_01.yaml)

<a id="l4-step-nav"></a>
## 步骤导航
- **上一步**：[05_全链路验证](../Stage3_模块实践/05_全链路验证_实践.md#l4-stage3-05-goal)
- **下一步**：[02_ModuleF执行网关接入](02_ModuleF执行网关接入.md#l4-stage4-02-goal)

> [!IMPORTANT] **实践测试方式约定**
> 本步以**本地 Docker Compose**（或等价本地环境）为**主要（默认）**实践测试方式，可选 K3s/实盘；无云凭证或无需真实集群时**优先**使用本地 Compose 完成验收。见 [00_系统规则_通用项目协议](../../00_系统规则_通用项目协议.md)、[02_三位一体仓库规约](../../03_原子目标与规约/_共享规约/02_三位一体仓库规约.md)#本地开发与部署文件。

<a id="l4-stage4-01-goal"></a>
## 步骤目标

- **L3 阶段目标**：MoE（混合专家）议会与执行网关接入；Module C 根据 Domain Tag 路由到对应专家，专家意见与 D 判官投票链路对接，形成 Alpha = (Quant ∩ Router) × Kelly 的完整链路。
- **本步目标**：实现 Router（根据 Tag 分发）、专家调用（Agri/Tech/Geo 等或占位）、专家意见聚合/投票与 D 的 Alpha 链路对接；逻辑密集处标 5D 与测试锚定。

## 关键产出物

1. Router 按 Domain Tag 正确分发；UNKNOWN 返回不支持意见
2. 至少一个专家（或占位）可返回 ExpertOpinion，与 09_ 结构一致
3. C 输出可作为 D 输入，Alpha 链路（Quant + Expert → D → Alpha）可执行
4. 单测或集成测试通过；路由与聚合有边界用例
5. L5 功能验收表「09_ Module C」一行已更新

## 本步骤可开始条件（Definition of Ready）

1. [Stage3_模块实践](../Stage3_模块实践/README.md) 已完成（A/B/D/E 最小闭环或 Module A～F 逐项准出）。
2. [Stage1_仓库与骨架](../Stage1_仓库与骨架/README.md) 准出，工作目录 **diting-core** 可编译/可测。
3. [09_](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md) Module C、Router 与 ExpertOpinion 已定稿。

## 推荐模型（可选）

由执行方自选；建议具备规约与路由/聚合逻辑理解能力。可引用 [Phase2 README](README.md)。

## 核心指令（The Prompt）

请先阅读 03_原子目标与规约/_共享规约/09_核心模块架构规约.md（Module C）、本步骤「实施内容」。任务：1. 实现 MoE Router（按 Tag 分发，UNKNOWN→Trash Bin）；2. 至少一个专家接口或占位，输出 ExpertOpinion 与 D 契约一致；3. C→D Alpha 链路可跑通；4. 单测/集成通过。工作目录 diting-core。请输出：变更文件列表、关键类型摘录、单测命令与结果摘要。

## Prompt 使用说明

将核心指令与 09_ Module C 一起喂给 AI；执行后用「验收与测试」中的可复制命令自检。

## 技术约束（DO / DON'T / 边界）

| 类型 | 内容 |
|------|------|
| **DO** | Router 与 09_ Tag 约定一致；ExpertOpinion 与 D 的 vote 输入一致；工作目录 diting-core |
| **DON'T** | 不要改变 D 判官已约定的 ExpertOpinion 结构（可扩展字段如 `horizon`，见 expert.proto） |
| **可选** | 专家池可包含 VC-Agent（信仰专家），输出 `TimeHorizon = LONG_TERM` 的 ExpertOpinion，供判官双轨分流；见 [09_ Module C VC-Agent](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md) |
| **边界** | 其他专家可为 Mock/占位；占位替换见 [Phase2 README 占位与真实实现衔接](README.md#占位与真实实现衔接) |

## 必读顺序

1. [09_核心模块架构规约](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md) Module C
2. 本步骤「实施内容」「验收与测试」

## 依赖的 Stage

- 依赖 [Stage1_仓库与骨架](../Stage1_仓库与骨架/README.md)（s1）准出。
- **前置**：[Stage3_模块实践](../Stage3_模块实践/README.md) 已完成（A/B/D/E 最小闭环或 Module A～F 逐项准出）。

## 前置条件

- Phase1 准出：D 判官可接收 Quant + Expert 意见并输出 Alpha。
- 工作目录 **diting-core**。

## 实施内容

**工作目录**：`diting-core`

1. **Router**
   - 实现 MoE Router：输入 symbol、domain_tags（来自 Module A）、quant_signal（来自 Module B）；按 Tag 分发到对应专家（AGRI/TECH/GEO），UNKNOWN 进 Trash Bin（见 09_ Module C）。

2. **专家调用与占位**
   - 至少实现一个垂类专家接口（如 Agri-Agent）或统一占位：输入 symbol、quant_signal，输出 ExpertOpinion（is_supported、direction、confidence、reasoning_summary）。
   - 其他专家可为 Mock/占位，保证 Router 输出 List[ExpertOpinion] 与 D 契约一致。

3. **与 D 的 Alpha 链路对接**
   - Module D 已支持 Expert 意见列表；本步确保 C 的输出格式与 D 的 vote(quant_signal, expert_opinions) 输入一致，端到端 Quant + Router(Experts) → D → Alpha 可跑通。

4. **5D（若逻辑密集）**
   - 路由分支、专家聚合逻辑建议 Table-Driven 单测；Design 锁路由规则 → Drive 锚测试 → Decompose 单职责 → Defense 人把关。

## 验收与测试

本节即本步骤验收标准。

**验收检查项**

- [ ] Router 按 Domain Tag 正确分发；UNKNOWN 返回不支持意见。
- [ ] 至少一个专家（或占位）可返回 ExpertOpinion，与 09_ 结构一致。
- [ ] C 输出可作为 D 输入，Alpha 链路（Quant + Expert → D → Alpha）可执行。
- [ ] 单测或集成测试通过（见下方可复制命令）；路由与聚合有边界用例。

**可复制测试命令**（工作目录：`diting-core`）

```bash
cd diting-core
make test
# 或：go test ./...
```

**成功标准**：退出码 0。**失败时**：见「本步骤失败时」。**与 DoD 分工**：上列为功能/产物验收；DoD 负责提交、单测、Review、L5 更新。

## 本步骤最小上下文（逻辑密集时）

- **路由规则**：按 Domain Tag（AGRI/TECH/GEO 等）分发；UNKNOWN → Trash Bin，返回不支持意见。
- **ExpertOpinion 结构**：与 09_、Phase1 D 判官输入一致（is_supported、direction、confidence、reasoning_summary）；C 输出 List[ExpertOpinion] 可直接作为 D 的 vote(quant_signal, expert_opinions) 输入。

## 5D 执行顺序（逻辑密集时）

| 5D 步 | 输出物 |
|-------|--------|
| 5D-1 Design | Router 输入/输出、专家接口与 ExpertOpinion 结构锁死 |
| 5D-2 Drive | Table-Driven：Tag→专家分配、UNKNOWN→不支持；聚合边界用例 |
| 5D-3 Decompose | route、invokeExpert、aggregate 等单职责函数 |
| 5D-4 Defense | 单测全绿；C→D 端到端可跑通；L5 对应行更新 |

<a id="l4-stage4-01-exit"></a>
## 本步骤准出（DoD）

- [ ] 代码已提交至约定分支/目录（工作目录 diting-core）
- [ ] Router 与至少一个专家（或占位）可运行，单测或集成测试通过
- [ ] Code Review 通过（或标注豁免）
- [ ] 已更新 L5 [02_验收标准](../../05_成功标识与验证/02_验收标准.md) 中**功能验收表**「09_ Module C」一行及 [l5-stage-stage4_01](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage4_01)（状态与验证方式）

## 输出格式 / 期望交付形态

1. 变更/新增文件列表；2. 关键类型摘录（Router 输入输出、ExpertOpinion）；3. 单测命令与结果摘要

## 下一步

完成本步且通过验收、DoD 全勾后，进入 [02_ModuleF执行网关接入](02_ModuleF执行网关接入.md)。**重要**：02_ 依赖 E 风控输出可流入执行层，C 未就绪不影响 02_ 占位，但完整链路需 01_ 准出。

## 产出物

| 产出 | 说明 |
|------|------|
| Router 包/模块 | 按 Tag 分发，UNKNOWN 处理 |
| 专家接口与至少一个实现/占位 | ExpertOpinion 与 D 契约一致 |
| C→D Alpha 链路可执行 | 集成测试或主路径验证 |

## 本步骤失败时

- **路由或聚合单测不通过**：核对 Tag 与 09_ 约定是否一致，修正分支或 Mock 数据。
- **D 无法消费 C 输出**：确认 ExpertOpinion 字段与类型与 Phase1 02_ 的 vote 输入一致。
- **依赖未就绪**：确认 Phase1 与 02_ Module D 准出；否则先完成 Phase1。

回退与失败分级见 [03_项目全功能开发测试实践工作流详细规划 八、失败与回退策略](../../03_原子目标与规约/开发与交付/03_项目全功能开发测试实践工作流详细规划.md)。

## Phase–Stage 接口

- **本步准出即 Stage s2 准出条件之一**；本步验收命令纳入 [Stage2_数据采集与存储 01_](../Stage2_数据采集与存储/01_基础设施与依赖实践.md#l4-stage2-01-exit) 可执行验证清单。
- **本步产出**：供 Stage2 01_ 或对应 Stage 可执行验证清单使用；Alpha 链路 Quant+Expert→D 可跑通。
- **本步依赖**：依赖 [Stage1_仓库与骨架](../Stage1_仓库与骨架/README.md)（s1）准出；依赖 Stage1 全步骤准出。

## 本步骤涉及的 DNA 键

| DNA 键 | 用途 |
|--------|------|
| `product_scope.phases` Phase2-xxx | 本 Phase 范围 |
| `core_modules.module_c`（若存在） | Router 与专家配置 |
| `dna_stage4_01.semantic_refs`、`global_const.core_formula` | Router(Experts) 与 Alpha 定义（见本步 DNA） |

## 逻辑密集说明

路由与专家聚合为逻辑密集时可走 **5D**；CRUD/透传占位可简化。代码注释可标注 `[Ref: 01_ModuleC_MoE议会接入]` 或 `[Ref: 03_09]`。
