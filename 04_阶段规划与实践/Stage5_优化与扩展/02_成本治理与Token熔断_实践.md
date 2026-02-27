# Phase3 · 02 · 成本治理与 Token 熔断

> [!NOTE] **[TRACEBACK] 战略追溯锚点**
> - **顶层概念**: [一句话定义与核心价值](../../01_顶层概念/01_一句话定义与核心价值.md)
> - **战略维度**: [07_成本治理维度](../../02_战略维度/产品设计/07_成本治理维度.md)
> - **原子能力**: [10_运营治理与灾备规约](../../03_原子目标与规约/_共享规约/10_运营治理与灾备规约.md)（若涉及）、[09_核心模块架构规约](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md)
> - **阶段**: [Phase3_优化与扩展](README.md)
> - **本步骤**: cost_governance 配置或熔断逻辑可落地

**本步设计文档**：[02_成本治理与Token熔断设计](../../03_原子目标与规约/Stage5_优化与扩展/02_成本治理与Token熔断设计.md#design-stage5-02-exit)  
**本步 DNA 文件**：[03_原子目标与规约/_System_DNA/Stage5_优化与扩展/dna_stage5_02.yaml](../../03_原子目标与规约/_System_DNA/Stage5_优化与扩展/dna_stage5_02.yaml)

<a id="l4-step-nav"></a>
## 步骤导航
- **上一步**：[01_可观测性与日志指标_实践](01_可观测性与日志指标_实践.md#l4-stage5-01-goal)
- **下一步**：[03_多策略池或配置扩展_实践](03_多策略池或配置扩展_实践.md#l4-stage5-03-goal)

> [!IMPORTANT] **实践测试方式约定**
> 本步以**本地 Docker Compose**（或等价本地环境）为**主要（默认）**实践测试方式，可选 K3s/实盘；无云凭证或无需真实集群时**优先**使用本地 Compose 完成验收。见 [00_系统规则_通用项目协议](../../00_系统规则_通用项目协议.md)、[02_三位一体仓库规约](../../03_原子目标与规约/_共享规约/02_三位一体仓库规约.md)#本地开发与部署文件。

<a id="l4-stage5-02-goal"></a>
## 步骤目标

- **L3 阶段目标**：优化与扩展阶段满足成本治理与 Token 可控；按 [07_成本治理维度](../../02_战略维度/产品设计/07_成本治理维度.md) 与 `global_const.cost_governance` 落地配置或熔断逻辑。
- **本步目标**：使 cost_governance 相关配置可生效（如 token_budget、technical_score 阈值、ROI 熔断）；或实现占位熔断逻辑（超预算/超 ROI 阈值时拒绝或降级 LLM 调用）。

## 关键产出物

1. cost_governance 中已定义的非空配置可被服务读取并生效（或占位生效）
2. 至少一条熔断或跳过路径可验证（如 technical_score 低于阈值时不调 LLM）
3. 熔断或预算超限时行为可判定（拒绝/降级/日志）；无明文密钥；成本逻辑引用 DNA 或配置（协议 §8.4a）
4. L5 功能验收表本步对应行已更新

## 本步骤可开始条件（Definition of Ready）

1. Phase2 已接入 MoE（含 LLM 调用路径）；存在可注入预算与熔断检查的调用点。
2. 工作目录 **diting-core** 可编辑；配置可来自 DNA 或环境变量。
3. global_const.cost_governance 键已定稿或可占位默认值。

## 推荐模型（可选）

由执行方自选；可引用 [Phase3 README](README.md)。

## 核心指令（The Prompt）

请先阅读 global_const.cost_governance、本步骤「实施内容」「占位边界」。任务：1. 从 DNA 或环境变量读取 token_budget、阈值等；2. 实现或占位熔断/跳过逻辑（technical_score 低于阈值跳过 LLM、超预算拒绝或降级）；3. 熔断触发时记录审计日志；4. **禁止明文密钥与 API Key 硬编码**；cost 仅引用 DNA 或配置。工作目录 diting-core。请输出：变更列表、配置键引用说明、单测/验证命令与结果摘要。

## Prompt 使用说明

将核心指令与 DNA cost_governance 一起喂给 AI；执行后用「验收与测试」中的可复制命令自检；确认无明文密钥。

## 技术约束（DO / DON'T / 边界）

| 类型 | 内容 |
|------|------|
| **DO** | cost_governance 从 DNA 或环境变量读取；熔断/跳过逻辑可验证；审计日志；工作目录 diting-core |
| **DON'T** | **禁止明文密钥、禁止在代码/配置中硬编码 API Key 或敏感 cost 数值**；成本与阈值仅引用 DNA 或配置（见协议 §8.4a） |
| **边界** | 未设定数值的 DNA 键可占位默认值；不要求真实计费或账单对接 |

## 必读顺序

1. global_const.cost_governance；02_战略维度/产品设计/07_成本治理维度.md
2. 本步骤「实施内容」「占位边界」「验收与测试」

## 依赖的 Stage

- 依赖 [Stage3_模块实践](../Stage3_模块实践/README.md) 或 [Stage4_MoE与执行网关](../Stage4_MoE与执行网关/README.md) 进行中。
- **前置 Phase**：Phase2 已接入 MoE（含 LLM 调用路径）。

## 前置条件

- 存在 LLM 或专家调用路径，可注入预算与熔断检查。
- 工作目录 **diting-core**（业务逻辑）、配置可来自 DNA 或环境变量。

## 实施内容

**工作目录**：`diting-core`

1. **cost_governance 配置可读**
   - 从 `global_const.cost_governance` 读取或映射：token_budget（max_token_per_decision、technical_score_skip_below、technical_score_deep_think_above、roi_fuse_threshold 等）；scale_to_zero、cold_archive 等可按需在部署侧落地。

2. **Token 预算与熔断**
   - 在调用 LLM/专家前：若 technical_score 低于 technical_score_skip_below，跳过 LLM 推理（或走轻量路径）；若配置了 max_token_per_decision，单次决策不超过该预算；若 roi_fuse_threshold 已设定，成本/收益低于阈值时触发熔断（拒绝或降级）。

3. **占位与扩展**
   - 未设定数值的 DNA 键（如 null）可先占位或使用默认值；熔断触发时记录审计日志，便于 L5 验收与追溯。

## 验收与测试

本节即本步骤验收标准。

**验收检查项**

- [ ] cost_governance 中已定义的非空配置可被服务读取并生效（或占位生效）。
- [ ] 至少一条熔断或跳过路径可验证（如 technical_score 低于阈值时不调 LLM）。
- [ ] 熔断或预算超限时行为可判定（拒绝/降级/日志），**无明文密钥**；成本相关逻辑引用 DNA 或配置（见协议 §8.4a）。

**可复制测试命令**（工作目录：`diting-core`）

```bash
cd diting-core
make test
# 或：单测/集成覆盖 technical_score_skip_below 边界
```

**成功标准**：配置可读、至少一条熔断路径可验证；代码/配置中无明文 API Key。**失败时**：见「本步骤失败时」。**与 DoD 分工**：上列为功能/产物验收；DoD 负责提交、验证、Review、L5 更新。

## 本步骤最小上下文（阈值与熔断）

- **cost_governance 键**：`token_budget.max_token_per_decision`、`technical_score_skip_below`、`technical_score_deep_think_above`、`roi_fuse_threshold`（见 DNA `global_const.cost_governance`）。
- **规则**：technical_score 低于 technical_score_skip_below → 跳过 LLM；单次决策不超过 max_token_per_decision；成本/收益低于 roi_fuse_threshold → 熔断（拒绝或降级）。

## 占位边界

DNA 中未设定数值的键（如 null）可**占位默认值**：读取时若缺失则使用文档或代码内约定的默认值；熔断触发时记录审计日志。占位满足条件：① 接口与 10_/09_ 一致；② 至少一条熔断或跳过路径可验证（如 technical_score 低于阈值时不调 LLM）；③ 不要求真实计费或账单对接。

<a id="l4-stage5-02-exit"></a>
## 本步骤准出（DoD）

- [ ] 代码/配置已提交至约定分支（工作目录 diting-core）
- [ ] cost_governance 配置可读并生效（或占位生效）；至少一条熔断/跳过路径可验证
- [ ] Code Review 通过（或标注豁免）；**无明文密钥**，成本逻辑引用 DNA 或配置（见协议 §8.4a）
- [ ] 已更新 L5 [02_验收标准](../../05_成功标识与验证/02_验收标准.md) 中**功能验收表**本步对应行及 [l5-stage-stage5_02](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage5_02)（状态与验证方式）

## 输出格式 / 期望交付形态

1. 变更/配置列表；2. cost_governance 键引用说明；3. 单测/验证命令与结果摘要；4. 确认无明文密钥

## 下一步

完成本步且通过验收、DoD 全勾后，进入 [03_多策略池或配置扩展](03_多策略池或配置扩展.md)（可选）或 [04_Level1与L5验收对齐](04_Level1与L5验收对齐.md)。**重要**：成本与安全验收（禁止明文密钥）为 Stage3/Stage4 准出项。

## 产出物

| 产出 | 说明 |
|------|------|
| cost_governance 配置读取与注入 | 从 DNA 或环境变量读取 token_budget、阈值等 |
| 熔断/跳过逻辑（或占位） | technical_score 低于阈值跳过 LLM、超预算拒绝或降级、审计日志 |
| 单测或集成验证 | 至少一条边界用例（如 technical_score_skip_below 边界） |

## 本步骤失败时

- **配置未生效**：检查 DNA 键路径与默认值约定，确保 null 键有占位默认值。
- **熔断路径不可验证**：补充 Table-Driven 或集成用例，覆盖阈值边界。
- **明文密钥或成本硬编码**：按协议 §8.4a 改为引用 DNA 或配置，禁止明文。

回退与失败分级见 [03_项目全功能开发测试实践工作流详细规划 八、失败与回退策略](../../03_原子目标与规约/开发与交付/03_项目全功能开发测试实践工作流详细规划.md)。

## Phase–Stage 接口

- **本步准出即 Stage s3 或 s4 准出条件之一**；本步验收命令纳入 [Stage3 01_](../Stage3_模块实践/01_语义分类器_实践.md#l4-stage3-01-exit)、[Stage4 01_](../Stage4_MoE与执行网关/01_ModuleC_MoE议会接入.md#l4-stage4-01-exit) 可执行验证清单。
- **本步产出**：供 Stage3/Stage4 01_ 成本与安全验收使用；禁止明文密钥与 cost 引用见各 Stage 01_。
- **本步依赖**：依赖 [Stage3](../Stage3_模块实践/README.md) 或 [Stage4](../Stage4_MoE与执行网关/README.md) 进行中；依赖 Stage4 MoE（含 LLM 调用路径）就绪。

## 本步骤涉及的 DNA 键

| DNA 键 | 用途 |
|--------|------|
| `cost_governance.token_budget` | max_token_per_decision、technical_score_skip_below、technical_score_deep_think_above、roi_fuse_threshold |
| `cost_governance.scale_to_zero` | 缩容与冷启动（可选，部署侧） |
| `cost_governance.cold_archive` | 冷归档（可选） |

## 逻辑密集说明

阈值与熔断判定为逻辑密集时可做 **5D**：锁阈值 → Table-Driven 测试（边界）→ 原子函数 → Defense。仅配置透传可简化。代码注释可标注 `[Ref: 02_成本治理与Token熔断]` 或 `[Ref: 03_10]`。
