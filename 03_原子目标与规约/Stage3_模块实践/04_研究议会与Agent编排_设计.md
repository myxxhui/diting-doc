# L3 · Stage3-04 Module C 设计

> [!NOTE] **[TRACEBACK] 原子规约锚点**
> - **战略维度**: [平台技术栈与系统架构](../../02_战略维度/平台与产品/02_平台技术栈与系统架构.md)
> - **原子规约**: [_共享规约/09_核心模块架构规约](../_共享规约/09_核心模块架构规约.md)、[_共享规约/01_核心公式与MoE架构规约](../_共享规约/01_核心公式与MoE架构规约.md)
> - **DNA**: [04_dna_MoE议会](../_System_DNA/Stage3_模块实践/04_dna_MoE议会.yaml)、[dna_module_c.yaml](../_System_DNA/core_modules/dna_module_c.yaml)
> - **L4 实践**: [04_研究议会与Agent编排_实践](../../04_阶段规划与实践/Stage3_模块实践/04_研究议会与Agent编排_实践.md#l4-stage3-04-exit)
> - **L5 锚点**: [02_验收标准#l5-stage-stage3_04](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_04)

<a id="design-stage3-04-goal"></a>
## 本步目标

实现 Module C MoE 议会（右脑）：对到达 C 的每只股票，按**领域与主要子领域**拉取基础数据与一手利好数据并分析，输出**统一契约的专家意见**，供 Module D 决策中枢投票与 Kelly 计算。

<a id="design-stage3-04-c-output-and-d-contract"></a>
## C 模块输出与 D 模块使用契约（必读）

### C 的输出是什么（自然语言）

C 模块**唯一对外输出**为**一列「专家意见」**（每条对应一只标的或一条结论），协议即专家意见报文。每条意见必须包含：

| 输出项 | 含义（自然语言） | 决策中枢（Module D）如何使用 |
|--------|------------------|-----------------|
| 标的代码 | 哪只股票 | 与左脑量化信号的标的对齐 |
| 是否支持 | 在能力范围内且结论为「可看多」为真；不懂或不该上为假 | **为假时决策中枢直接否决**，不参与仓位计算 |
| 信号方向 | 看多 / 看空 / 中性 | **至少一条意见为「支持且看多」** 才与左脑一起通过投票 |
| 确信度 | 0～1，越大越有信心 | 决策中枢用于**动态凯利**算仓位（如 基础凯利 × 确信度） |
| 理由摘要 | 一两句人话，说明为何这么判 | 审计与人审展示 |
| 风险提示 | 可能的风险点列表 | 风控与展示 |
| 期限类型 | SHORT_TERM / LONG_TERM 等（语义见 proto） | 决策中枢据此套用不同风控规则（如 LONG_TERM 可豁免部分短周期硬止损） |

### D 对 C 的输入要求（满足以下才能正确使用）

- **输入**：决策中枢接收左脑量化信号（Module B）与专家意见列表（Module C）。
- **投票规则**：当且仅当**（1）左脑判定通过**（阈值由 B 模块或决策中枢配置约定，例如技术分 ≥ 70）**且（2）至少一条专家意见为「支持且看多」**时，决策中枢认定为有效信号；否则不通过。
- **仓位**：决策中枢用通过意见的确信度参与凯利计算。
- **要求**：C 必须保证每条意见字段完整、确信度在 [0,1]、理由摘要非空；同一标的若有多条意见，决策中枢按「至少一条通过即通过」消费。

### 决策中枢支撑要求（必须满足）

C 的输出须**最佳支撑决策中枢**，以下均为必须：

- **单标的单意见**：每标的只输出一条聚合后的意见，决策中枢无需做多意见合并。
- **确信度口径一致**：确信度与决策中枢凯利假设一致（0～1，越高仓位可越大）。
- **结构化维度摘要**：理由摘要中必须含可解析的「对齐得分、景气强度、风险等级、利好强度」；见下「C 模块设计要求」。

<a id="design-stage3-04-implementation-mode"></a>
## 判断与数据处理：代码逻辑 vs AI 模型（明确约定）

当前设计与实践文档中**未显式写出**「由代码算还是由 AI 算」，此处固定约定，实现与验收均按此执行。

### 默认实现：以代码逻辑为主

- **以下全部由代码逻辑实现**，不依赖大模型调用：
  - 细分信号解析（JSON/关键词）、利好与主营对齐得分、主营一票否决、多细分加权置信度、风险降权、认知边界四条（无主营/全无信号/主营否决/alignment<阈值）。
  - 最终 is_supported、direction、confidence、reasoning_summary、risk_factors 的赋值，均由上述规则与公式**确定性地由代码计算得出**。
- **数据流**：基础数据（标的细分列表、主营占比）+ 一手利好数据（细分信号缓存）→ **代码逻辑** → ExpertOpinion。不要求「把集合数据交给 AI 做判断」。

### AI 的可选接入方式（若后续引入）

- **方式 A（推荐）**：代码逻辑负责**结构化判断与数值**（对齐、否决、置信度）；AI 仅用于**润色 reasoning_summary** 或从 risk_tags 生成自然语言说明，不改变 is_supported/direction/confidence。这样 D 的输入仍由规则可复现。
- **方式 B**：由 AI 在代码提供的**结构化上下文**（对齐得分、主营是否利好、各细分信号摘要）基础上，输出 is_supported/direction/confidence；需在规约中明确 fallback：AI 超时/失败时回退到纯代码结果，且需可审计。

**当前阶段**：实现与验收均按「**100% 代码逻辑**」；设计文档与实践文档中凡涉及「判断」「分析」处，均指**代码按本节策略详规执行**，不默认调用 AI。

<a id="design-stage3-04-unified-mode"></a>
## 实现模式：按股配置 + 统一分析（默认且唯一）

**说明**：本节约定 C **如何组织**（单管道、按股配置数据、不分专家）；下节「C 模块设计要求」约定管道**必须实现哪些逻辑与输出**（利好强度、景气强度、风险分级、理由摘要四维度等）。

采用**按股配置 + 统一分析**：每只标的根据其领域与主营细分（来自 A 的 Tag 与 segment_list）**配置**本轮要使用的数据（segment_list、segment_signals）；经**统一分析管道**（逻辑见下节与策略详规）输出**一条**专家意见。不按领域分多套专家实现；标签「未知」或未在支持列表时，仍输出一条「不支持」意见（Trash Bin 行为）。

<a id="design-stage3-04-requirements"></a>
## C 模块设计要求

**说明**：上节约定**如何组织** C；本节约定管道**必须实现哪些逻辑与输出**（算哪些维度、输出什么格式）。

以下为 C 模块必须实现的逻辑与输出约定，与「利好与主营对齐、多细分聚合、认知边界」共同构成完整设计要求。

### 利好强度

- 该标的主营及相关细分上的利好强度，0～1。有信号且为利好的细分按营收占比加权取各细分信号的 strength（无则 0.5）；仅主营利好时取主营强度。参与最终确信度；理由摘要中输出「利好强度=0.xx」。

### 景气强度

- 该标的涉及细分中有利好信号的占比程度，0～1。**景气强度** = 有利好信号的细分其营收占比之和（固定采用此实现）。理由摘要中输出「景气强度=0.xx」。

### 风险分级（高/中/低）

- 任一细分带「高风险」标签 → 风险等级**高**；主营利空或默认 → **中**；多数利好且无高风险 → **低**。高时确信度乘 0.5、中乘 0.9、低不降权。风险提示按等级从 config 或信号填充。

### 理由摘要中的结构化维度

- 理由摘要**必须**含可解析片段：**「对齐得分=0.xx 景气强度=0.xx 风险等级=高|中|低 利好强度=0.xx」**。不支持时可省略部分维度但须含「风险等级=xxx」或原因简述。决策中枢或下游可解析；审计可追溯。

### 实现约定

- 利好强度、景气强度、风险等级、结构化摘要均由代码实现。管道顺序：先对齐、多细分聚合、认知边界；再算利好强度、景气强度、风险等级；风险等级降权后拼理由摘要并输出。

<a id="design-stage3-04-points"></a>
## 设计要点

- **入口**：统一分析入口，单管道；domain_tag 仅用于选用风险提示模板（config 中按领域 key 取 risk_factor_templates），不改变逻辑。
- **无法归类**：domain_tags 为空或仅含「未知」时，输出一条 is_supported=False 的意见。
- **输入**：Module A 的 Tag、Module B 的量化信号；**扩展**（见 [12_右脑数据支撑与细分规约](../_共享规约/12_右脑数据支撑与Segment规约.md)）：(a) 标的的细分列表（A 的主营占比或 L2 标的主营构成表）、(b) 各细分的垂直一手信号（L2 细分信号缓存表，由信号层按候选按需拉取）。
- **输出**：每标的一条专家意见，供 D 投票与凯利计算。
- **逻辑**：利好与主营对齐、多细分聚合、认知边界、利好强度/景气强度/风险分级/结构化摘要（见策略详规与 dna_module_c）。

<a id="design-stage3-04-dna-keys"></a>
## 本步落实的 _System_DNA 键

- `core_modules/dna_module_c.yaml`：`mode`（按股配置 + 统一分析）、`entry`（unified_opinion）、`router.supported_tags`、`strategy`、`pipeline_steps`、`risk_factor_templates`；策略参数与管道步骤与本文档一致。

<a id="design-stage3-04-strategy"></a>
## Module C 专家策略详规（可执行）

以下为 AI 与代码可直接实现的策略描述；实现须与本节一一对应，单测可据此断言。

### 输入数据结构约定

- **segment_list**（标的细分列表）：来自 A 的 ClassifierOutput.segment_shares 或 L2 标的主营构成表。每项为 `{"segment_id": str, "revenue_share": float, "is_primary": bool}`。同一标的下有且仅有一条 `is_primary=True`。
- **segment_signals**（各细分信号）：key 为 segment_id，value 为从 L2 细分信号缓存表读取的**解析后**结构；见下「细分信号解析约定」。缺失的 segment_id 表示该细分无缓存或已过期，按降级处理。

**细分信号解析约定**（实现时 signal_summary 为 JSON 则解析，否则按纯文本关键词回退）：

- **规范 JSON 结构**（适配器输出建议遵循）：`{"type": "policy|price|order|rnd", "direction": "bullish|bearish|neutral", "strength": 0.0~1.0, "summary_cn": "中文摘要", "risk_tags": ["可选风险标签"]}`。其中 `direction` 用于利好与主营对齐；`strength` 参与置信度加权；`risk_tags` 含「高风险」时触发风险降权。
- **纯文本回退**：若 signal_summary 非合法 JSON，则用关键词匹配：含「利好」「上涨」「支持」「政策」等取 direction=bullish，含「利空」「下跌」「风险」等取 direction=bearish，否则 neutral；无 strength 时取 0.5。

### 利好与主营对齐（必须实现）

- **定义**：仅当标的**主营细分**（is_primary=True 的 segment）在 segment_signals 中存在且该信号方向为利好（direction=bullish）时，认为「利好与主营对齐」成立；非主营细分若有信号可加权参与，但权重低于主营。
- **对齐得分公式**（标量，0~1）：
  - 设主营细分为 `s_primary`（revenue_share 记为 `r_pri`）。
  - 若 `s_primary` 不在 segment_signals 或信号 direction 非 bullish：`alignment_primary = 0.0`；否则 `alignment_primary = 1.0`（或取该信号的 strength，若存在）。
  - 非主营：`alignment_other = sum(revenue_share * I(该细分有 bullish 信号))`，仅对 segment_list 中非主营且存在于 segment_signals 且 direction=bullish 的项求和。
  - **alignment_score = 0.6 * alignment_primary + 0.4 * min(alignment_other, 1.0)**。若 segment_list 为空，则 alignment_score = 0.0。
- **与 is_supported/confidence 的绑定**：
  - 若 **alignment_score < 0.3**：**is_supported = False**，reasoning_summary 须含「利好与主营未对齐」或「主营细分无利好信号」。
  - 否则 is_supported 由后续多细分聚合与专家维度共同决定；**base_confidence** 先乘以 alignment_score 得到 **alignment_adjusted_confidence**，再参与多细分聚合。

### 多细分聚合规则（固定策略）

- **主营一票否决**：若标的的主营细分（is_primary=True）在 segment_signals 中**无**有效信号，或该信号 direction 为 bearish，则**整体 is_supported = False**，不再计算加权置信度。
- **加权置信度**（当主营未否决时）：对 segment_list 中**有信号且 direction 为 bullish** 的细分，按营收占比加权：`confidence_weighted = sum(segment_signal.strength * revenue_share) / sum(revenue_share)`，分母仅对「有 bullish 信号的细分」的 revenue_share 求和；若分母为 0 则取 0.5。
- **风险降权**：若任一细分信号的 risk_tags 中含「高风险」，则最终 confidence 乘以 **0.5**；多个高风险不重复乘。
- **无细分数据降级**：若 segment_list 为空，则不做多细分聚合，is_supported = False，reasoning_summary = "无主营构成数据"。

### 认知边界（何时必须输出「不支持」）

**含义**：在「不该表态」或「信息明显不利」时，明确输出「不支持」，不猜、不硬上。

以下任一成立时，**必须**输出「不支持」，并填写对应理由摘要（可拼接多条）：

1. **无主营构成**：标的没有细分列表或细分列表为空 → 理由含「无主营构成或细分列表为空」。
2. **全部细分无有效信号**：该标的涉及的所有细分在信号表里都没有有效条目（或都无方向）→ 理由含「全部细分无垂直信号」。
3. **主营一票否决**：主营细分没有信号，或主营细分信号为利空 → 理由含「主营细分无利好或利空」。
4. **利好与主营未对齐**：对齐得分低于阈值（如 0.3）→ 理由含「利好与主营未对齐」。

**实现**：四条条件判断；任一条满足即输出「不支持」并写清原因。**效果**：减少在信息不足或明显不对时仍给「支持」的误判，提高通过标的的可信度。

### 统一分析管道（唯一逻辑）

- **输入**：segment_list、segment_signals（已按该标配置好的数据）；domain_tag 仅用于从 config 的 `risk_factor_templates` 按领域 key 选用风险提示文案，不改变计算逻辑。
- **步骤顺序**（实现须严格按此）：① 解析 segment_signals（JSON 或关键词回退）→ ② 计算对齐得分与主营一票否决 → ③ 认知边界判断（四条任一条即「不支持」）→ ④ 多细分加权置信度、利好强度、景气强度、风险等级 → ⑤ 风险等级降权（高 0.5、中 0.9、低 1.0）→ ⑥ 拼结构化摘要（对齐得分=、景气强度=、风险等级=、利好强度=）与 risk_factors → ⑦ 输出一条 ExpertOpinion。
- **风险提示**：从信号 risk_tags 收集；缺省按 risk_level 与 config 中 `risk_factor_templates[domain_tag]` 填充（若存在）。

### 配置驱动（YAML）

- **支持标签**：config 中 `moe_router.supported_tags` 列出可走统一分析的 tag（如 农业、科技、宏观）；未在列表或 tag 为「未知」→ 输出一条「不支持」意见。
- **策略参数**：alignment 权重（主营 0.6、非主营 0.4）、veto_threshold 0.3、风险等级降权系数（高 0.5、中 0.9）、signal_parse 关键词等，均从 config 或 DNA 读取，禁止硬编码。

### 与 12_、09_ 的对应

- 本节「利好与主营对齐」对应 12_ 的「利好与主营对齐」与「多维度打分」中的匹配度；「多细分聚合」对应 12_ 的「主营一票否决或按营收占比加权」「任一细分风险达阈值则整体否决」。
- 认知边界对应 09_ 与 04_ 协议中 is_supported 的语义（不知则弃）。

<a id="design-stage3-04-impl-detail"></a>
### 实现细粒度约定（供 DNA/实践与代码对齐）

- **输入来源**：segment_list 来自 A 的 ClassifierOutput.segment_shares，或直接查 L2 标的主营构成表（按 symbol）；segment_signals 来自 L2 细分信号缓存表，按 segment_list 中的 segment_id 拉取。
- **入口**：统一分析入口函数签名约定为 `unified_opinion(symbol, quant_signal, segment_list, segment_signals, config, domain_tag)`，返回单条 ExpertOpinion；domain_tag 为「农业」|「科技」|「宏观」之一，用于 risk_factor_templates 选用。
- **调用方**：上游根据 domain_tags 取首个在 supported_tags 中的 tag 传入；若无则调用 trash_bin 等价逻辑（返回一条 is_supported=False、reasoning_summary 含「无法归类」的 ExpertOpinion），不调用 unified_opinion。
- **景气强度取数**：固定采用「有利好信号的细分其营收占比之和」作为景气强度，与 DNA 的 boom_dim 一致。

<a id="design-stage3-04-exit"></a>
## 准出

Module C 四项 100%；单测与联动验证通过；专家策略按本节实现且可配置；L5 [l5-stage-stage3_04](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_04) 可更新。
