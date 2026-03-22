# Stage3-04 Module C MoE 议会

> [!NOTE] **[TRACEBACK] 战略追溯锚点**
> - **顶层概念**: [一句话定义与核心价值](../../01_顶层概念/01_一句话定义与核心价值.md)
> - **战略维度**: [01_产品设计维度](../../02_战略维度/产品设计/01_产品设计维度.md)
> - **原子能力**: [09_核心模块架构规约](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md)（Module C）、[Expert Protocol](../../03_原子目标与规约/_共享规约/04_全链路通信协议矩阵.md)
> - **DNA stage_id**: `stage3_04`
> - **本步设计文档**: [04_A轨_MoE议会_设计](../../03_原子目标与规约/Stage3_模块实践/04_A轨_MoE议会_设计.md#design-stage3-04-exit)
> - **本步 DNA 文件**: [04_dna_MoE议会](../../03_原子目标与规约/_System_DNA/Stage3_模块实践/04_dna_MoE议会.yaml)、[dna_module_c.yaml](../../03_原子目标与规约/_System_DNA/core_modules/dna_module_c.yaml)
> - **阶段**: [Stage3_模块实践](README.md)

<a id="l4-step-nav"></a>
## 步骤导航
- **上一步**：[03_量化扫描引擎_实践](03_量化扫描引擎_实践.md#l4-stage3-03-goal)
- **下一步**：[05_热路径判官风控与执行_实践](05_热路径判官风控与执行_实践.md#l4-stage3-05-goal)

> [!IMPORTANT] **实践测试方式约定**
> 本步以**本地 Docker Compose**（或等价本地环境）为**主要（默认）**实践测试方式，可选 K3s/实盘；无云凭证或无需真实集群时**优先**使用本地 Compose 完成验收。见 [00_系统规则_通用项目协议](../../00_系统规则_通用项目协议.md)、[02_三位一体仓库规约](../../03_原子目标与规约/_共享规约/02_三位一体仓库规约.md)#本地开发与部署文件。

<a id="l4-stage3-04-goal"></a>
## 步骤目标

实现 Module C MoE 议会，Router 按 Domain Tag 分发、专家输出 ExpertOpinion；完成 **四项 100% 验证**。

## 本步骤落实的 DNA 键

- `core_modules/dna_module_c.yaml`：`mode`（按股配置 + 统一分析）、`entry`（unified_opinion）、`router.supported_tags`、`strategy`、`pipeline_steps`、`risk_factor_templates`；`expert_logic_required` 与设计策略一一对应。
- 策略详规见 [04_A轨_MoE议会_设计#design-stage3-04-strategy](../../03_原子目标与规约/Stage3_模块实践/04_A轨_MoE议会_设计.md#design-stage3-04-strategy)

**必读（设计文档中已明确）**：
- **C 输出与判官要求**：[设计#C 模块输出与判官支撑要求](../../03_原子目标与规约/Stage3_模块实践/04_A轨_MoE议会_设计.md#design-stage3-04-c-output-and-d-contract) — 每标的一条专家意见，判官用「是否支持」「方向」「确信度」做投票与凯利；单标的单意见、确信度口径一致、理由摘要含四维度均为必须。
- **按股配置 + 统一分析**：[设计#实现模式](../../03_原子目标与规约/Stage3_模块实践/04_A轨_MoE议会_设计.md#design-stage3-04-unified-mode) — 默认且唯一：统一分析管道输出一条意见；domain_tag 仅用于风险提示模板选用。
- **判断与数据处理**：[设计#判断与数据处理](../../03_原子目标与规约/Stage3_模块实践/04_A轨_MoE议会_设计.md#design-stage3-04-implementation-mode) — 全部由代码逻辑实现。
- **C 模块设计要求**：[设计#C 模块设计要求](../../03_原子目标与规约/Stage3_模块实践/04_A轨_MoE议会_设计.md#design-stage3-04-requirements) — 利好强度、景气强度、风险分级、理由摘要四维度。
- **实现细粒度**：[设计#实现细粒度约定](../../03_原子目标与规约/Stage3_模块实践/04_A轨_MoE议会_设计.md#design-stage3-04-impl-detail) — 入口 `unified_opinion(...)`、管道步骤顺序、输入来源见设计文档。

## 实现部分

**工作目录**：`diting-core`

**输入数据来源**：`segment_list`、`segment_signals` 由上游按 [12_右脑数据支撑与Segment规约](../../03_原子目标与规约/_共享规约/12_右脑数据支撑与Segment规约.md) 提供（如 A 的 ClassifierOutput.segment_shares 或 L2 标的主营构成表、L2 细分信号缓存表）；C 假定调用 `unified_opinion` 时已传入，不在此步实现数据拉取。

**本地一键脚本与部署形态**：`scripts/run_module_c_local.py` 支持 `MOE_SEGMENT_SOURCE=classifier`（默认，内存跑 `SemanticClassifier`，与 A 逻辑一致）与 `MOE_SEGMENT_SOURCE=snapshot`（从 L2 表 `classifier_output_snapshot` 读取 `tags_json`、`segment_shares_json`，**不重跑 Module A**，适合 C 独立进程/与 A 异步解耦）；可选 `MOE_CLASSIFIER_BATCH_ID` 与 A 当批 `batch_id` 对齐。解析实现见 `diting/classifier/snapshot_reader.py`。

### 步骤 1：配置与包结构

1. 在 `diting-core/config/` 下维护 `moe_router.yaml`，包含：
   - `moe_router.supported_tags`：可走统一分析的标签列表（如 `[农业, 科技, 宏观]`）；不在此列表或为「未知」则输出一条「不支持」。
   - 策略参数（与 DNA 一致）：`alignment.primary_weight`、`veto_threshold`、`multi_segment.primary_veto`、`risk_discount`、`signal_parse` 关键词；`risk_factor_templates` 按 农业/科技/宏观 键提供风险提示文案。
2. 确保 `diting/moe/` 包存在，且含 `__init__.py`、`router.py`、统一分析入口（见步骤 4）。

### 步骤 2：细分信号解析

3. 实现 `diting/moe/signal_parse.py`（或等价模块）：
   - 函数 `parse_segment_signal(signal_summary: str) -> dict`：若为合法 JSON 则解析出 `type`、`direction`、`strength`、`summary_cn`、`risk_tags`；否则按纯文本关键词回退（利好/利空关键词与 DNA 的 `fallback_keywords_bullish`、`fallback_keywords_bearish` 一致），返回 `direction`（bullish/bearish/neutral）、`strength`（默认 0.5）、`risk_tags`（可选）。
   - 实现须与设计文档「细分信号解析约定」一致。

### 步骤 3：利好与主营对齐 + 多细分聚合

4. 实现 `diting/moe/alignment.py`（或合入专家模块）：
   - 输入：`segment_list: List[dict]`（每项含 segment_id, revenue_share, is_primary）、`segment_signals: Dict[str, dict]`（segment_id -> 解析后信号）。
   - 输出：`alignment_score`（0~1）、是否触发主营一票否决、加权置信度、是否含高风险降权。
   - 公式与阈值与设计文档完全一致：alignment_score = 0.6*主营对齐 + 0.4*非主营加权；alignment_score < 0.3 则标记 is_supported=False；主营无信号或 bearish 则一票否决；任一 risk_tags 含「高风险」则 confidence *= 0.5。
   - **认知边界四条**（任一条满足即必须输出「不支持」，理由摘要写清原因）：① 无主营构成（细分列表为空）；② **全部细分无有效信号**（该标的所有细分在信号表均无有效条目或均无方向）→ 理由含「全部细分无垂直信号」；③ 主营一票否决（主营无信号或主营信号为利空）；④ 利好与主营未对齐（alignment_score < 0.3）。

### 步骤 4：统一分析入口与 Router

5. 实现 `diting/moe/experts.py` 中**统一分析入口** `unified_opinion(symbol, quant_signal, segment_list, segment_signals, config, domain_tag)`：
   - 按设计文档「统一分析管道」步骤顺序：解析信号 → 对齐与主营否决 → 认知边界 → 多细分加权与利好强度/景气强度/风险等级 → 风险等级降权 → 拼结构化摘要与 risk_factors → **根据主营/细分信号方向与聚合结果设置 `ExpertOpinion.direction`（看多/看空/中性）** → 返回一条 ExpertOpinion。
   - **期限类型**：本步为 A 轨 MoE 议会，产出的 ExpertOpinion **必须设置 `horizon = SHORT_TERM`**（或等价枚举），供判官分流使用。
   - `domain_tag` 仅用于从 config 的 `risk_factor_templates[domain_tag]` 选用风险提示文案；逻辑与 tag 无关。
6. 在 `diting/moe/router.py` 中：若 `domain_tags` 为空或首个有效 tag 不在 `moe_router.supported_tags`（或为「未知」），则返回 `[trash_bin_opinion(symbol, ...)]`；否则取首个 supported tag，调用 `unified_opinion(..., domain_tag=该 tag)`，返回 `[op]`。每标的一条意见。

### 步骤 5：结构化维度（利好强度、景气强度、风险分级、理由摘要）

7. 在 alignment 或统一分析层**由代码**计算：**利好强度**、**景气强度**（利好细分营收占比之和）、**风险等级**（高/中/低）；风险等级为高时确信度乘 0.5，中乘 0.9，低不降权。
8. 每条专家意见的**理由摘要**须含可解析片段：**「对齐得分=0.xx 景气强度=0.xx 风险等级=高|中|低 利好强度=0.xx」**；不支持时至少含「风险等级=xxx」或原因简述。

### 步骤 6：契约与单测

9. **ExpertOpinion 全字段**：输出须符合 [设计#C 模块输出](../../03_原子目标与规约/Stage3_模块实践/04_A轨_MoE议会_设计.md#design-stage3-04-c-output-and-d-contract) 及 `expert.proto`，必填字段包括：`symbol`、`domain`、`is_supported`、`direction`（看多/看空/中性）、`confidence`、`reasoning_summary`、`risk_factors`、`horizon`（本步为 SHORT_TERM）；domain 可按 domain_tag 映射（农业→1、科技→2、宏观→3）。单测须断言上述字段存在且类型正确。
10. 单测覆盖：
    - **统一入口**：给定 segment_list/signals 下输出一条意见且含四维度摘要；**horizon** 为 SHORT_TERM；**direction** 随聚合结果：主营利好且支持 → direction 为看多，主营利空或否决 → 看空或中性。
    - **Router**：supported tag 时返回一条、未知时返回一条「不支持」。
    - **认知边界**：无主营→不支持；**全部细分无有效信号→不支持且 reasoning_summary 含「全部细分无垂直信号」或等价表述**；主营无信号→一票否决；对齐<0.3→不支持。
    - **支持路径**：主营利好→支持且确信度>0；风险等级高时确信度降权。

## 验证部分

### 四项 100%

| 维度 | 验收标准 | 验证方法 |
|------|----------|----------|
| **接口 100%** | ExpertOpinion 符合 expert.proto，含全部必填字段 | 单测断言 symbol、domain、is_supported、**direction**、confidence、reasoning_summary、risk_factors、**horizon** 等存在且类型正确；本步产出 **horizon = SHORT_TERM** |
| **结构 100%** | moe 目录、config/moe_router.yaml、supported_tags 与策略参数与 DNA 一致 | `ls diting/moe config/moe_router.yaml`；配置含 supported_tags、alignment、risk_factor_templates |
| **逻辑功能 100%** | 统一分析管道（unified_opinion）；Router 按 supported_tags 决定一条意见或一条「不支持」；对齐、聚合、认知边界四条按设计实现 | 单测：无主营→不支持；**全部细分无有效信号→不支持且理由含「全部细分无垂直信号」**；主营无信号→否决；对齐<0.3→不支持；有主营利好→支持；**主营利好且支持时 direction 为看多** |
| **结构化维度 100%** | 利好强度、景气强度、风险分级、理由摘要含四维度；风险等级高时确信度降权 | 单测：理由摘要含四维度；高风险时 confidence 降权 |
| **代码测试 100%** | 单测覆盖 unified_opinion、Router、alignment、signal_parse、Trash Bin、结构化维度、horizon/direction、认知边界四条 | `cd diting-core && python3 -m pytest tests/unit/test_moe*.py -v` 通过 |

### 三层验证

- **单模块**：Mock A/B 输出，验证 Router 分发与专家输出
- **联动**：A+B+C 联调，C 消费 A/B 输出
- **全链路**：参与 A→F 全链路验证

## 核心指令（The Prompt）

```
你是在 diting-core 中实现 Module C 的开发者。采用「按股配置 + 统一分析」：唯一入口 unified_opinion(symbol, quant_signal, segment_list, segment_signals, config, domain_tag)，按设计文档管道步骤输出一条 ExpertOpinion；Router 根据 supported_tags 调用统一入口或返回一条「不支持」。ExpertOpinion 须含全字段：symbol、domain、is_supported、direction（由聚合结果填看多/看空/中性）、confidence、reasoning_summary、risk_factors、horizon（本步固定 SHORT_TERM）；认知边界四条（含「全部细分无有效信号」）必须实现。必读：04_A轨_MoE议会_设计（策略详规、实现细粒度约定）、dna_module_c.yaml、expert.proto。工作目录：diting-core。
```

<a id="l4-stage3-04-exit"></a>
## 验收与测试、DoD、本步骤失败时

### 可执行验证命令

- **单测**：`cd diting-core && python3 -m pytest tests/unit/test_moe*.py -v`
- **结构**：`ls -la diting-core/diting/moe/ diting-core/config/moe_router.yaml 2>/dev/null || true`
- **契约**：单测中构造专家意见并断言具备 **symbol、domain、is_supported、direction、confidence、reasoning_summary、risk_factors、horizon** 等全字段；**horizon 为本步默认 SHORT_TERM**；主营利好且支持时 **direction 为看多**。
- **结构化维度**：单测断言理由摘要含「对齐得分=」「景气强度=」「风险等级=」「利好强度=」；风险等级高时确信度≤0.5。
- **认知边界第四条**：单测断言当所有细分均无有效信号时，输出不支持且 reasoning_summary 含「全部细分无垂直信号」或等价表述。

### 准出检查清单

- [ ] 设计文档中策略与 C 模块设计要求已实现且与文档一致
- [ ] config/moe_router.yaml 存在且含 routing 与策略参数
- [ ] 细分信号解析、对齐、多细分聚合、**统一分析入口 unified_opinion**、Router（supported_tags）、Trash Bin、利好强度/景气强度/风险分级/结构化摘要 已实现
- [ ] **ExpertOpinion 全字段**：symbol、domain、is_supported、**direction**、confidence、reasoning_summary、risk_factors、**horizon**（本步 SHORT_TERM）均已赋值；**认知边界四条**（含「全部细分无有效信号」）均已实现
- [ ] 单测通过且覆盖：统一入口输出一条意见且含四维度；**horizon=SHORT_TERM、direction 随聚合结果**；supported tag→一条意见、未知→一条不支持；无主营、**全部细分无信号**、主营否决、对齐阈值、主营利好、风险等级降权
- [ ] 已更新 L5 02_验收标准 中本阶段对应行（若适用）

### 本步骤失败时

先分析失败原因（设计描述不清、实践步骤缺项、实现错误）；修复后重试。同一问题修复重试超过 2 次仍失败则回收环境并记录，见 03_ 工作流详细规划「失败与回退策略」。

同 01_/02_ 模板；L5 [l5-mod-C](../../05_成功标识与验证/02_验收标准.md)、[l5-stage-stage3_04](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_04) 行准出时更新。
