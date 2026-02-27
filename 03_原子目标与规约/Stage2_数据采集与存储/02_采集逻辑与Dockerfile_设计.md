# L3 · Stage2-02 采集逻辑与 Dockerfile 设计

> [!NOTE] **[TRACEBACK] 原子规约锚点**
> - **05_ 对应项**: [01_顶层概念/05_谛听优先借鉴的十大开源选型](../../01_顶层概念/05_谛听优先借鉴的十大开源选型.md) 第 2、3 项（AkShare、OpenBB）
> - **原子规约**: [_共享规约/11_数据采集与输入层规约](../_共享规约/11_数据采集与输入层规约.md)
> - **DNA**: [_System_DNA/Stage2_数据采集与存储/dna_stage2_02_采集逻辑与Dockerfile.yaml](../_System_DNA/Stage2_数据采集与存储/dna_stage2_02_采集逻辑与Dockerfile.yaml)
> - **L4 实践**: [04_阶段规划与实践/Stage2_数据采集与存储/02_采集逻辑与Dockerfile](../../04_阶段规划与实践/Stage2_数据采集与存储/02_采集逻辑与Dockerfile实践.md#l4-stage2-02-exit)
> - **L5 锚点**: [02_验收标准#l5-stage-stage2_02](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage2_02)

<a id="design-stage2-02-goal"></a>
## 本步目标

OHLCV/新闻/行业 全数据结构与逻辑完整；Dockerfile 支持采集任务构建；前期可配置少存数据，code 结构与逻辑须完整。

<a id="design-stage2-02-points"></a>
## 设计要点

- **数据源**：功能深度和广度完整；前期可少存数据，结构与逻辑必须完整
- **任务**：ingest_ohlcv、ingest_industry_revenue、ingest_news（见 11_ 与 data_ingestion DNA）
- **写入**：L1 TimescaleDB、L2 知识库；遵循 DVC 版本化

<a id="design-stage2-02-consumes"></a>
### 前置依赖与关键配置（设计约束）

本步**消耗** Stage2-01 准出；设计层约定下游（本步）所需输入与配置来源，L4 实践中的「依赖部署步骤检查」「关键参数获取」须与本小节一致。

| 类型 | 约定 | L4 对应 |
|------|------|---------|
| **准入条件** | Stage2-01 验证项 V1～V7 全部符合，含下游 `make verify-db-connection` 可过 | [02_采集逻辑与Dockerfile实践#本步依赖检查与关键参数获取](../../04_阶段规划与实践/Stage2_数据采集与存储/02_采集逻辑与Dockerfile实践.md#l4-stage2-02-deps-check) |
| **关键配置项** | `TIMESCALE_DSN`（L1）、`PG_L2_DSN`（L2）、`REDIS_URL`（可选）；来源为 Sealed-Secrets 或 diting-core `.env`，占位与说明见 `.env.template` | 同上「关键参数列表与获取方式」「获取关键配置的步骤」 |
| **表与契约** | L1 表 `ohlcv`、L2 表 `data_versions` 及知识库由 Stage2-01 的 Schema init Job 创建；本步仅 INSERT/读写，不执行 DDL | L4「数据采集逻辑细节」中 L1/L2 表结构引用 diting-infra schemas/sql |
| **验证顺序** | 先 `make verify-db-connection` 通过，再执行 `make ingest-test`；镜像构建后在镜像内执行 `make ingest-test` 作为准出项 | L4「验证目标与验证过程」「示例与验证」 |

<a id="design-stage2-02-deps"></a>
### 依赖与镜像构建（部署配套）

- **逻辑填充期借鉴组件**：本步实现依赖 [01_顶层概念/05_谛听优先借鉴的十大开源选型](../../01_顶层概念/05_谛听优先借鉴的十大开源选型.md) 中 **AkShare**（国内数据）、**OpenBB**（国际/宏观/基本面）。
- **要求**：采集镜像的 Dockerfile 及 requirements（或等价依赖文件）中**显式声明并安装**上述组件（如 `akshare`、`openbb-platform` 或项目采用的 OpenBB 包名）；构建后 `make ingest-test` 须在镜像内可运行。
- **一键构建**：Makefile 须提供单一 target（如 `make build-images`），一次执行即可构建本阶段所涉全部镜像（当前为采集镜像），便于 CI 与本地复现；L4 验证项 V-BUILD-ALL 对应此验收。
- **验收**：L4 本步准出时须包含「依赖已写入 Dockerfile/requirements」「镜像内 make ingest-test 退出码 0」「make build-images 退出码 0、全部镜像构建成功」的验证。

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

<a id="design-stage2-02-feature-mapping"></a>
### 功能项与验收映射（供 L4 勾选对照）

L4 实践文档中的 [功能实践项清单](../../04_阶段规划与实践/Stage2_数据采集与存储/02_采集逻辑与Dockerfile实践.md#l4-stage2-02-feature-checklist) 须与本表一一对应；执行者按「功能项 ID」勾选实践状态。

| 功能项 ID | 功能描述 | 对应本设计文档小节 | 验收方式 |
|-----------|----------|--------------------|----------|
| F1 | ingest_ohlcv：AkShare A 股日线 → L1 ohlcv | [AkShare 接入点](#design-stage2-02-integration-akshare) | make ingest-test 覆盖；写入 L1 ohlcv |
| F2 | ingest_industry_revenue：AkShare 行业/财报/营收 → L2 或约定存储 | 同上 | make ingest-test 覆盖；写入 L2 或 Module A 可用缓存 |
| F3 | ingest_news：AkShare 国内 + OpenBB 国际 → L2 | [OpenBB 接入点](#design-stage2-02-integration-openbb) | make ingest-test 覆盖；至少一条 OpenBB→L2 路径 |
| F4 | AkShare 接口边界与错误/限流（重试、退避） | AkShare 详细需求 | 代码中重试策略、限频或退避可查 |
| F5 | OpenBB 至少一条到 L2 的写入路径 | OpenBB 验收要点 | 代码中 OpenBB 调用并 write_data_version |
| F6 | Makefile 新增 ingest-test target | [依赖与镜像构建](#design-stage2-02-deps) | make ingest-test 存在且可执行 |
| F7 | Dockerfile/requirements 显式 akshare、openbb-platform | 同上 | Dockerfile 及 requirements 中显式列出 |
| F8 | ingest-test 目标数据约定 | L4 [2.5 确认采集到的目标数据](../../04_阶段规划与实践/Stage2_数据采集与存储/02_采集逻辑与Dockerfile实践.md#l4-stage2-02-target-data) | diting-core 内文档或配置约定 symbol、data_type 等 |
| F9 | 一键构建所有镜像 | [依赖与镜像构建](#design-stage2-02-deps) | make build-images（或约定名）存在且可执行；退出码 0 表示全部镜像构建成功 |

<a id="design-stage2-02-verification"></a>
### 验证与可执行验收（设计层定义）

L4 实践中的「示例与验证」须满足下列设计层验收定义；具体执行方式与命令见 [02_采集逻辑与Dockerfile实践#示例与验证](../../04_阶段规划与实践/Stage2_数据采集与存储/02_采集逻辑与Dockerfile实践.md#l4-stage2-02-examples-verify)。L4 [验证与测试结果清单](../../04_阶段规划与实践/Stage2_数据采集与存储/02_采集逻辑与Dockerfile实践.md#l4-stage2-02-verify-checklist) 中的验证项 ID（V-DB、V-INGEST、V-DATA、V-IMAGE）与本表对应。

| 验收维度 | 设计层定义 | 可执行证明 | L4 验证项 ID |
|----------|------------|------------|--------------|
| **采集逻辑符合预期** | 三个任务按 11_ 与 AkShare/OpenBB 设计写入 L1/L2 或约定缓存；接口与错误处理逻辑已实现 | `make ingest-test` 退出码 0；单测/集成测可 Mock 并断言写入结构 | V-INGEST |
| **数据量、类型、内容符合预期** | 写入满足 L1 `ohlcv`、L2 `data_versions` 表结构与 07_ 版本化；前期可少存数据，结构完整 | psql 对 ohlcv、data_versions 的 COUNT/SELECT 样例；无主键/非空违反；与目标数据约定一致 | V-DATA |
| **依赖链实践完整** | Stage2-01 准出 → 本步配置 → verify-db-connection → ingest-test → 镜像内 ingest-test，全链路可复现 | L4 依赖链验证顺序表 1～5 步执行通过 | V-DB、V-INGEST |
| **镜像按预期运行并采集** | 镜像内显式安装 akshare、openbb-platform；容器内 `make ingest-test` 退出码 0 | 构建镜像 → 容器内执行 make ingest-test；可选：对比宿主机/集群内 L1/L2 数据与本地执行一致 | V-IMAGE |
| **一键构建所有镜像** | Makefile 提供 build-images（或约定名）；一次执行构建本阶段所涉全部镜像 | make build-images 退出码 0；可辅以 docker images 或 Make 内自检 | V-BUILD-ALL |

<a id="design-stage2-02-exit"></a>
## 准出

1. **采集逻辑实现**：ingest_ohlcv、ingest_industry_revenue、ingest_news 按 11_ 与设计文档「逻辑填充期开源接入点」实现；Dockerfile 可构建采集镜像；make ingest-test 或等价命令可运行。
2. **前置验证**：本步执行前须已通过 `make verify-db-connection`（依赖 Stage2-01 准出与关键配置就绪）；见 [设计约束](#design-stage2-02-consumes)。
3. **准出验证**：L4 实践文档 [验证与准出](../../04_阶段规划与实践/Stage2_数据采集与存储/02_采集逻辑与Dockerfile实践.md#l4-stage2-02-exit) 表中全部命令通过：`make verify-db-connection`、`make ingest-test`、**镜像内** `make ingest-test`；验收维度满足 [验证与可执行验收](#design-stage2-02-verification)。
