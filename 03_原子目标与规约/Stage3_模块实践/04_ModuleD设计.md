# L3 · Stage3-04 Module D 设计

> [!NOTE] **[TRACEBACK] 原子规约锚点**
> - **05_ 对应项**: [01_顶层概念/05_谛听优先借鉴的十大开源选型](../../01_顶层概念/05_谛听优先借鉴的十大开源选型.md) 第 5 项（PyPortfolioOpt）
> - **战略维度**: [技术栈与架构维度](../../02_战略维度/产品设计/02_技术栈与架构维度.md)
> - **原子规约**: [_共享规约/09_核心模块架构规约](../_共享规约/09_核心模块架构规约.md)、[_共享规约/01_核心公式与MoE架构规约](../_共享规约/01_核心公式与MoE架构规约.md)
> - **DNA**: [dna_stage3_04.yaml](../_System_DNA/Stage3_模块实践/dna_stage3_04.yaml)、[dna_module_d.yaml](../_System_DNA/core_modules/dna_module_d.yaml)
> - **L4 实践**: [04_阶段规划与实践/Stage3_模块实践/04_ModuleD](../../04_阶段规划与实践/Stage3_模块实践/04_ModuleD.md#l4-stage3-04-exit)
> - **L5 锚点**: [02_验收标准#l5-stage-stage3_04](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_04)

<a id="design-stage3-04-goal"></a>
## 本步目标

实现 Module D 判官（决策中枢）：投票机制（Quant + Expert）、动态凯利仓位、现金拖累监控、防御性复利；Alpha 与 01_ 核心公式一致。

<a id="design-stage3-04-points"></a>
## 设计要点

- **投票**：Quant 信号与专家意见加权投票
- **凯利**：动态仓位计算，满足不可能三角约束
- **现金拖累**：空仓 > 5 天触发监控
- **公式**：Alpha = (Quant_Signal ∩ Router(Experts)) × Kelly_Position
- **双轨分流**：实现时根据 `ExpertOpinion.horizon` 分支：`LONG_TERM` 豁免 2% 硬止损与现金拖累，仅施加逻辑证伪与大周期反转；`SHORT_TERM` 或未设置时按现有规则。见 [09_ Module D 双轨分流](../_共享规约/09_核心模块架构规约.md)。

<a id="design-stage3-04-dna-keys"></a>
## 本步落实的 _System_DNA 键

- `core_modules/dna_module_d.yaml`；`core_formula`、`constraints`（胜率/复利/回撤）

<a id="design-stage3-04-integration-pfo"></a>
### 逻辑填充期开源接入点：PyPortfolioOpt（Phase1 必选）

- **实践重点**：「买多少」的闭环由判官层完成：MoE 选出候选标的后，用 PyPortfolioOpt 做**组合优化**（均值-方差、有效前沿、Black-Litterman、CVaR、行业约束等）得到权重，再与动态凯利或现金拖累规则结合，形成最终仓位；直接支撑不可能三角中的复利与生存底线。
- **详细需求**：
  - **输入**：判官投票后的候选列表（含 Quant 与 Expert 信号）、可选的历史收益/协方差或因子协方差；若用 Black-Litterman，需约定观点来源（如专家观点、先验）。
  - **优化目标与约束**：明确本阶段采用的优化目标（如最大夏普、最小波动、CVaR）及约束（行业上限、单标的上限、做空与否）；与 09_ Module D 的约束（胜率/复利/回撤）的对应关系。
  - **与凯利与现金拖累的衔接**：组合优化得到的权重如何与动态凯利系数结合（如先 PyPortfolioOpt 得权重，再按 Kelly 缩放总仓位）；现金拖累监控是否在权重计算之后、仅做监控与告警。
  - **依赖与构建**：在 requirements 及 Dockerfile 中显式声明并安装 PyPortfolioOpt（如 `pyportfolioopt`）；构建后判官相关单测在镜像内可运行。
- **验收要点**：给定固定输入，判官输出的各标的权重与 PyPortfolioOpt 参考调用结果一致（或误差在约定范围）；单测覆盖至少一种优化配置（如均值-方差 + 行业约束）。

<a id="design-stage3-04-exit"></a>
## 准出

Module D 四项 100%；判官投票+Kelly+Alpha 与 01_ 核心公式一致；Table-Driven 单测与边界覆盖；L5 [l5-stage-stage3_04](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_04) 可更新。
