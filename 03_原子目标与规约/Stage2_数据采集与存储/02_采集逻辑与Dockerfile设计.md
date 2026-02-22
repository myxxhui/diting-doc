# L3 · Stage2-02 采集逻辑与 Dockerfile 设计

> [!NOTE] **[TRACEBACK] 原子规约锚点**
> - **05_ 对应项**: [01_顶层概念/05_谛听优先借鉴的十大开源选型](../../01_顶层概念/05_谛听优先借鉴的十大开源选型.md) 第 2、3 项（AkShare、OpenBB）
> - **原子规约**: [_共享规约/11_数据采集与输入层规约](../_共享规约/11_数据采集与输入层规约.md)
> - **DNA**: [_System_DNA/Stage2_数据采集与存储/dna_stage2_02.yaml](../_System_DNA/Stage2_数据采集与存储/dna_stage2_02.yaml)
> - **L4 实践**: [04_阶段规划与实践/Stage2_数据采集与存储/02_采集逻辑与Dockerfile](../../04_阶段规划与实践/Stage2_数据采集与存储/02_采集逻辑与Dockerfile.md#l4-stage2-02-exit)
> - **L5 锚点**: [02_验收标准#l5-stage-stage2_02](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage2_02)

<a id="design-stage2-02-goal"></a>
## 本步目标

OHLCV/新闻/行业 全数据结构与逻辑完整；Dockerfile 支持采集任务构建；前期可配置少存数据，code 结构与逻辑须完整。

<a id="design-stage2-02-points"></a>
## 设计要点

- **数据源**：功能深度和广度完整；前期可少存数据，结构与逻辑必须完整
- **任务**：ingest_ohlcv、ingest_industry_revenue、ingest_news（见 11_ 与 data_ingestion DNA）
- **写入**：L1 TimescaleDB、L2 知识库；遵循 DVC 版本化

<a id="design-stage2-02-deps"></a>
### 依赖与镜像构建（部署配套）

- **逻辑填充期借鉴组件**：本步实现依赖 [01_顶层概念/05_谛听优先借鉴的十大开源选型](../../01_顶层概念/05_谛听优先借鉴的十大开源选型.md) 中 **AkShare**（国内数据）、**OpenBB**（国际/宏观/基本面）。
- **要求**：采集镜像的 Dockerfile 及 requirements（或等价依赖文件）中**显式声明并安装**上述组件（如 `akshare`、`openbb-platform` 或项目采用的 OpenBB 包名）；构建后 `make ingest-test` 须在镜像内可运行。
- **验收**：L4 本步准出时须包含「依赖已写入 Dockerfile/requirements」「镜像内 make ingest-test 退出码 0」的验证。

<a id="design-stage2-02-integration-akshare"></a>
### 逻辑填充期开源接入点：AkShare（Phase1 必选）

- **实践重点**：将 AkShare 作为**国内数据唯一统一 Python 接口**；采集层仅通过该接口（或在其上的薄封装）拉取国内数据。明确 `ingest_ohlcv`（A 股）、`ingest_industry_revenue`、`ingest_news`（国内部分）必须走 AkShare，并保证 Module A 输入（申万行业、营收占比）与 L2 知识库国内侧数据可由此供给。
- **详细需求**：
  - **接口边界**：采集层对外仅暴露「按任务类型 + 日期/代码范围」的拉取接口，内部统一调用 AkShare。列出本阶段使用的 AkShare 接口子集（行情、行业分类、财报/营收、公告/龙虎榜等）及与 11_「数据类型/用途」的映射表。
  - **错误与限流**：定义 AkShare 调用失败时的重试策略（次数、退避）、限频要求（避免被封）；失败时是否写缓存/降级及是否触发告警。
  - **数据写入契约**：从 AkShare 拉取后的数据写入 L1 TimescaleDB / 约定表 / Redis / L2 知识库 的格式、主键与 DVC 版本化规则，与 11_ 的写入契约一致。准出条件之一为「Module A 所需申万行业、营收占比可仅凭当前采集逻辑从 AkShare 获取并写入约定存储」。
- **验收要点**：`make ingest-test`（或等价）至少覆盖 ingest_industry_revenue、ingest_ohlcv（A 股）、以及为 Module A 与 L2 供给的至少一条路径；单测或集成测可 Mock AkShare 返回值，但接口与错误处理逻辑必须实现。

<a id="design-stage2-02-integration-openbb"></a>
### 逻辑填充期开源接入点：OpenBB（Phase2 扩展）

- **实践重点**：用 OpenBB 覆盖**国际/宏观/大宗/基本面**（财报、营收增速、研发占比等），与 AkShare 形成「国内 + 国际」双支柱；B 轨 VC-Agent、GEO 专家与 Macro-KG 依赖此类数据。采集层采用「轻量 Core + Provider 可插拔」思路：OpenBB 的 Provider 扩展模型在 11_ 与本节中体现为「可插拔数据源抽象」，便于后续增删数据源而不改核心采集流程。
- **详细需求**：
  - **数据范围**：明确本阶段通过 OpenBB 接入的数据类型（宏观指标、大宗价格、汇率、基本面财报字段）；与 Module A、L2 Macro-KG、B 轨基本面需求的映射表。
  - **Provider 抽象**：定义「Provider」接口（如 get_macro、get_fundamentals、get_commodities 等），OpenBB 作为默认实现；其他数据源可后续实现同一 Provider 接口并替换或并行存在。
  - **与 AkShare 的分工**：同一业务字段（如某公司营收）若国内外均有，约定以哪边为主、是否做合并或优先级规则；避免双源冲突。
- **验收要点**：至少一条从 OpenBB 到 L2 知识库（或 Module A 可用缓存）的写入路径在逻辑填充期实现并可测；Provider 接口有单测或 Mock 实现。

<a id="design-stage2-02-exit"></a>
## 准出

采集逻辑实现；Dockerfile 可构建采集镜像；make ingest-test 或等价命令可运行。
