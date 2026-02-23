# Stage2-02 采集逻辑与 Dockerfile

> [!NOTE] **[TRACEBACK] 步骤锚点**
> - **原子规约**: [_共享规约/11_数据采集与输入层规约](../../03_原子目标与规约/_共享规约/11_数据采集与输入层规约.md)
> - **DNA stage_id**: `stage2_02`
> - **本步设计文档**: [02_采集逻辑与Dockerfile设计](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile设计.md#design-stage2-02-exit)
> - **本步 DNA 文件**: [dna_stage2_02.yaml](../../03_原子目标与规约/_System_DNA/Stage2_数据采集与存储/dna_stage2_02.yaml)
> - **逻辑填充期接入点**：本步须按设计文档中「逻辑填充期开源接入点」小节实现并达标，见 [AkShare](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile设计.md#design-stage2-02-integration-akshare)、[OpenBB](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile设计.md#design-stage2-02-integration-openbb)。

<a id="l4-step-nav"></a>
## 步骤导航
- **上一步**：[01_基础设施与依赖部署](01_基础设施与依赖部署.md#l4-stage2-01-goal)
- **下一步**：[03_本地测试与K3s连调](03_本地测试与K3s连调.md#l4-stage2-03-goal)

**上下游关系总览**：本步**消耗** Stage2-01 准出（数据库与连接配置、表已建、`make verify-db-connection` 可过）；**产出** 采集任务（ingest_ohlcv、ingest_industry_revenue、ingest_news）、Dockerfile 与 `make ingest-test`，供 Stage2-03（本地测试与 K3s 连调）、Stage2-04/05（镜像打包与采集模块部署）使用。

## 关键下游依赖（来自 Stage2-01）

本步依赖 [01_基础设施与依赖部署](01_基础设施与依赖部署.md#l4-stage2-01-goal) 产出的数据库与连接方式。Stage2-01 准出时已包含**下游如何添加数据库连接配置并调用表数据**的验证；本步须与下列约定一致，并可作为 Stage2-01 的「下游引用示例」验证执行方。

| 依赖项 | 说明 | 本步用法 |
|--------|------|----------|
| **数据库连接配置** | 由 Sealed-Secrets 或 .env 提供；占位项见 diting-core `.env.template`（如 `TIMESCALE_DSN`、`REDIS_URL`、`PG_L2_DSN`），与 diting-infra 部署的 Service/NodePort 对应 | 采集任务写入 L1 TimescaleDB、L2 知识库时使用上述 DSN；配置来源见 [01_基础设施与依赖部署#关键下游引用与验证要求](01_基础设施与依赖部署.md#l4-stage2-01-downstream) |
| **调用表数据** | Stage2-01 的 init Job 已建表；下游通过 DSN 连接并对约定表执行 INSERT/SELECT | 本步 `make ingest-test` 会写入 L1/L2 表；Stage2-01 准出验证含「在 diting-core 执行 make verify-db-connection 或等价」以确认可调用表数据 |
| **示例与验证** | Stage2-01 文档中「关键下游引用与验证要求」要求：在 diting-core 中提供最小验证（如 `make verify-db-connection`），连接 DB 并对 init 所建表执行 SELECT，退出码 0 | 本步实现时须提供该 make target 或等价脚本，供 Stage2-01 准出时执行；实现方式见 [01_基础设施与依赖设计](../../03_原子目标与规约/Stage2_数据采集与存储/01_基础设施与依赖设计.md#design-stage2-01-exit) 与 11_ 规约 |

**验证归属**：上述「下游添加连接配置并调用表数据」的**验证执行**归属 Stage2-01 的准出检查清单（V7）；本步实现须保证该验证可被 Stage2-01 执行者复现（即本仓具备 `make verify-db-connection` 或等价）。

<a id="l4-stage2-02-deps-check"></a>
## 本步依赖检查与关键参数获取

执行本步前，必须确认 **Stage2-01 已准出**，并完成下列检查与参数准备。

### 1. 依赖部署步骤检查清单

本步依赖 [01_基础设施与依赖部署](01_基础设施与依赖部署.md#l4-stage2-01-exit) 的验证项 V1～V7 全部通过。执行本步前建议逐项核对：

| 检查项 | 说明 | 本步用途 |
|--------|------|----------|
| V1 | Chart/中间件版本已固定并缓存 | 无需本步操作，仅确认 Stage2-01 已做 |
| V2 | TimescaleDB 部署并可用 | 采集任务写入 L1 表 `ohlcv` |
| V3 | Redis 部署并可用 | 可选缓存（如行业/营收）；按 11_ 规约 |
| V4 | PostgreSQL（L2）部署并可用 | 采集任务写入 L2 表 `data_versions` 及知识库相关 |
| V5 | Schema init Job 成功，表存在 | 本步 INSERT 目标表已存在 |
| V6 | Sealed-Secrets 可用 | 生产侧密钥注入；本地可用 .env |
| V7 | 下游可连接并调用表数据 | 本步须先通过 `make verify-db-connection`，再跑 `make ingest-test` |

**结论**：仅当 Stage2-01 准出（含 V7 在 diting-core 执行 `make verify-db-connection` 退出码 0）后，本步采集逻辑才可在真实库上验证。

### 2. 关键参数列表与获取方式

| 参数名 | 说明 | 获取方式 | 示例值（仅格式，禁止写真实密令） |
|--------|------|----------|----------------------------------|
| **TIMESCALE_DSN** | L1 TimescaleDB 连接串 | Stage2-01 部署后由 NodePort/Service 得到；写入 .env | `postgresql://user:****@<host>:5432/dbname` |
| **REDIS_URL** | Redis 连接串 | 同上；values 或 Secret 中的 auth.password 与 host/port 拼成 | `redis://:****@<host>:6379/0` |
| **PG_L2_DSN** | L2 知识库 PostgreSQL 连接串 | 同上；L2 库名如 `diting_l2` | `postgresql://user:****@<host>:5432/diting_l2` |

- **配置来源**：由 Sealed-Secrets 或 **diting-core 根目录 `.env`** 提供；占位项与说明见 diting-core 的 `.env.template`（与 diting-infra 部署的 Service/NodePort 对应）。
- **权威文档**：diting-infra [Stage2-01-部署与验证](../../../diting-infra/docs/Stage2-01-部署与验证.md)、[jobs/README](../../../diting-infra/jobs/README.md) 中写明 Secret 键名与建表结果。

### 3. 获取关键配置的步骤（本步执行前必做）

1. **确认 Stage2-01 已准出**：在 diting-infra 侧 V1～V7 均已符合，且已执行过 diting-core 的 `make verify-db-connection` 并通过。
2. **在 diting-core 根目录**：复制 `.env.template` 为 `.env`。
3. **填写 .env**：将 Stage2-01 部署得到的 `TIMESCALE_DSN`、`REDIS_URL`、`PG_L2_DSN` 填入（可从 diting-infra 的 Secret `diting-db-connection` 或部署文档中的示例/NodePort 拼接得到；本地连 K3s 时 host 为 NodePort 对应地址）。
4. **验证连接**：在 diting-core 执行 `make verify-db-connection`，退出码 0 后再进行采集逻辑开发或 `make ingest-test`。

## 工作目录

**diting-core**

<a id="l4-stage2-02-goal"></a>
## 本步目标

OHLCV/新闻/行业 全数据结构与逻辑完整；Dockerfile 支持采集任务构建。前期可配置少存数据，code 结构与逻辑须完整。采集镜像须在 Dockerfile/requirements 中显式安装 AkShare、OpenBB（见设计文档「[依赖与镜像构建](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile设计.md#design-stage2-02-deps)」与 dna_stage2_02.integration_packages）。

**执行指引**：为便于区分**哪些功能已实践、哪些未实践、哪些测试通过、哪些失败**，执行时请：① 先填写 [功能实践项清单](#l4-stage2-02-feature-checklist)（F1～F8 实践状态）；② 每完成一项验证后填写 [验证与测试结果清单](#l4-stage2-02-verify-checklist)（V-DB、V-INGEST、V-DATA、V-IMAGE 测试结果与备注）；③ 再按 [本步实践总结](#l4-stage2-02-summary) 步骤表执行并填「是否符合预期」与「实践结果」。**无真实数据即未实践**：须在真实或本地 L1/L2 上跑通 `make ingest-test`，并填写 [2.6 真实数据验证结果](#l4-stage2-02-real-data)（采集到的股票、类型、条数、日期范围）；仅逻辑无写入验证视为未完成。准出条件见 [本步实践总结](#l4-stage2-02-summary) 节首。

<a id="l4-stage2-02-ingest-detail"></a>
## 数据采集逻辑细节

### 1. 要求与任务类型

| 任务 ID | 数据源（逻辑填充期） | 写入目标 | 规约与设计引用 |
|---------|----------------------|----------|----------------|
| **ingest_ohlcv** | AkShare（A 股行情） | L1 TimescaleDB 表 `ohlcv` | [11_ 数据采集与输入层规约](../../03_原子目标与规约/_共享规约/11_数据采集与输入层规约.md)、[设计-AkShare](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile设计.md#design-stage2-02-integration-akshare) |
| **ingest_industry_revenue** | AkShare（行业/财报、申万、营收占比） | 约定表或 Redis 缓存；Module A 输入 | 同上 |
| **ingest_news** | AkShare（国内部分）+ OpenBB（国际/宏观） | L2 知识库、L3 冷归档；按 07_ 版本化 | [设计-OpenBB](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile设计.md#design-stage2-02-integration-openbb) |

- **L1 表结构**：`ohlcv(symbol, period, datetime, open, high, low, close, volume)`，主键 `(symbol, period, datetime)`，见 diting-infra `schemas/sql/01_l1_ohlcv.sql`。
- **L2 表结构**：`data_versions(data_type, version_id, timestamp, file_path, ...)` 等，见 diting-infra `schemas/sql/02_l2_data_versions.sql`；新闻/知识库写入 Agri-KG、Tech-KG、Macro-KG 按 11_ 与 07_ 规约。

### 2. 实践方式与依赖组件

- **国内数据**：以 **AkShare** 为统一 Python 接口；`ingest_ohlcv`（A 股）、`ingest_industry_revenue`、`ingest_news`（国内部分）必须走 AkShare，接口边界、错误与限流、写入契约见设计文档 [逻辑填充期开源接入点：AkShare](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile设计.md#design-stage2-02-integration-akshare)。
- **国际/宏观/基本面**：**OpenBB** 覆盖宏观、大宗、财报等；与 AkShare 分工、Provider 抽象见 [逻辑填充期开源接入点：OpenBB](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile设计.md#design-stage2-02-integration-openbb)。
- **依赖组件部署与配置**：TimescaleDB、Redis、PostgreSQL（L2）由 **Stage2-01** 在 diting-infra 中部署；本步仅在 **diting-core** 内通过 `.env`（或运行时从 Sealed-Secrets 注入）提供 `TIMESCALE_DSN`、`REDIS_URL`、`PG_L2_DSN`，不在此步部署中间件。
- **获取关键配置的步骤**：见上文 [本步依赖检查与关键参数获取](#l4-stage2-02-deps-check)：复制 `.env.template` → `.env`，填写上述 DSN，执行 `make verify-db-connection` 通过后再执行 `make ingest-test`。

### 3. 验证目标与验证过程

| 验证目标 | 验证方式 | 预期结果 |
|----------|----------|----------|
| 数据库可连接、表可读写 | `make verify-db-connection` | 退出码 0；能连接 TimescaleDB 并对 init 所建表执行查询 |
| 采集任务可运行且写入 L1/L2 | `make ingest-test` | 退出码 0；至少覆盖 ingest_ohlcv、ingest_industry_revenue 及为 Module A/L2 的至少一条路径 |
| 逻辑填充期接入点达标 | 代码与单测/集成测 | AkShare/OpenBB 按设计文档接口与错误处理实现；单测可 Mock 返回值 |
| 镜像内可运行采集 | 在构建后的采集镜像内执行 `make ingest-test` | 退出码 0，证明 Dockerfile/requirements 依赖正确 |

**验证过程建议顺序**：① 本步依赖检查与关键参数获取（含 `make verify-db-connection`）→ ② 实现采集任务与 `make ingest-test` → ③ 本地 `make ingest-test` 通过 → ④ 构建镜像并在镜像内执行 `make ingest-test` 通过 → 准出。

## 核心指令

```
你是在 diting-core 中执行 Stage2-02（采集逻辑与 Dockerfile）的实践者。必读：03_原子目标与规约/_共享规约/11_数据采集与输入层规约.md、global_const.data_ingestion、03_原子目标与规约/_共享规约/07_数据版本控制规约.md。

任务：
1. 实现采集任务（ingest_ohlcv、ingest_industry_revenue、ingest_news），按 03_原子目标与规约/_共享规约/11_数据采集与输入层规约.md 规约写入 L1/L2。
2. 按设计文档「逻辑填充期开源接入点：AkShare、OpenBB」小节实现并达标（实践重点、详细需求、验收要点见该设计文档）。
3. Dockerfile 支持采集镜像构建；在 Dockerfile 及 requirements 中显式加入 akshare、openbb-platform（或等价包）；构建后须在**镜像内**执行 make ingest-test 且退出码 0。
4. 在 Makefile 中新增 ingest-test target；退出码 0 表示通过。
```

<a id="l4-stage2-02-examples-verify"></a>
## 示例与验证（证明采集逻辑与依赖链、镜像符合预期）

### 1. 采集逻辑符合预期的证明

- **最小证明**：在 diting-core 执行 `make ingest-test`，退出码 0 表示采集任务已按 11_ 规约写入 L1/L2（或约定缓存），且逻辑填充期接入点（AkShare、OpenBB）按设计文档实现并可被该 target 触发。
- **可选增强**：单测或集成测中 Mock AkShare/OpenBB 返回值，断言写入 L1 的 `ohlcv` 行与 L2 的 `data_versions`（或知识库）条目的数据类型与必填字段存在；接口与错误处理逻辑有覆盖。

### 2. 数据量、数据类型与内容符合预期

- **L1 ohlcv**：写入行需满足表结构 `(symbol, period, datetime, open, high, low, close, volume)`，主键 `(symbol, period, datetime)` 唯一；`datetime` 为 TIMESTAMPTZ，数值为 DOUBLE PRECISION/BIGINT。验证方式示例（在具备 TIMESCALE_DSN 且 init 已建表的前提下）：
  - `psql $TIMESCALE_DSN -c "SELECT count(*) FROM ohlcv;"`
  - `psql $TIMESCALE_DSN -c "SELECT symbol, period, datetime, open, close FROM ohlcv LIMIT 3;"`
- **L2 data_versions**：写入需满足 `data_versions` 表结构与 07_ 版本化规则。验证方式示例：
  - `psql $PG_L2_DSN -c "SELECT count(*) FROM data_versions;"`
  - `psql $PG_L2_DSN -c "SELECT data_type, version_id, timestamp FROM data_versions LIMIT 3;"`
- **评判**：数据类型与表结构一致、无违反主键/非空约束即视为内容符合预期；前期可少存数据（如少量 symbol 或单日），但结构与逻辑须完整。

<a id="l4-stage2-02-target-data"></a>
### 2.5 确认采集到的目标数据（哪些股票、哪些数据）

仅「退出码 0」无法证明采集到了**目标数据**。验收时须能明确回答：**本次采集到了哪些股票的哪些数据**（及 L2/行业侧写了哪些类型、多少条）。实现方须在 diting-core 约定「ingest-test 目标数据」并在验证时对照。

**（1）目标数据的约定方式**

- **L1 OHLCV**：在 diting-core 的文档或配置中约定「`make ingest-test` 会采集的目标」至少包含：
  - **股票范围**：具体 symbol 列表（如 `000001.SZ`、`600000.SH`）或数量规则（如「至少 N 只 A 股」）；
  - **周期与时间**：`period`（如 `daily`）、日期范围（如最近 1 个交易日、或指定起止日）；
- **L2 / 行业**：约定 `ingest-test` 会写入的 `data_type` 或行业/营收条目类型（如 `ohlcv`、`industry_revenue`、`news` 等），以及至少条数或样例标识。
- 上述约定可写在 diting-core 的 `docs/ingest-test-target.md`、README 或 `make ingest-test` 的注释/脚本内，便于执行者与验收方对照。

**（2）必须执行的验证查询（可确认「采集到了目标数据」）**

执行 `make ingest-test` 后，**必须**执行下列查询并保留结果，用于确认「写入了哪些股票、哪些数据」：

| 验证项 | 命令示例 | 用途 |
|--------|----------|------|
| L1 有哪些股票 | `psql $TIMESCALE_DSN -c "SELECT DISTINCT symbol, period FROM ohlcv ORDER BY symbol, period;"` | 列出本次采集涉及的**股票代码与周期** |
| L1 日期范围与条数 | `psql $TIMESCALE_DSN -c "SELECT min(datetime) AS from_ts, max(datetime) AS to_ts, count(*) AS rows FROM ohlcv;"` | 确认**时间范围与总行数** |
| L1 每只股票条数 | `psql $TIMESCALE_DSN -c "SELECT symbol, period, count(*) AS cnt FROM ohlcv GROUP BY symbol, period ORDER BY symbol, period;"` | 确认**每只股票、每个 period 的条数**是否与约定一致 |
| L2 有哪些数据类型 | `psql $PG_L2_DSN -c "SELECT data_type, count(*) AS cnt FROM data_versions GROUP BY data_type ORDER BY data_type;"` | 列出本次写入的 **data_type 及条数** |
| L2 样例条目 | `psql $PG_L2_DSN -c "SELECT data_type, version_id, timestamp FROM data_versions ORDER BY timestamp DESC LIMIT 5;"` | 确认**具体版本/条目**存在且可读 |

**（3）评判标准**

- **通过**：上述查询结果与 diting-core 约定的「ingest-test 目标数据」一致——例如至少包含约定的 symbol 列表（或数量）、约定的 period、约定日期范围内有数据；L2 至少包含约定的 data_type 及预期条数。
- **不通过**：无法列出具体股票/数据类型、或与约定目标不一致（如约定 3 只股实际为 0 只、约定日线实际无数据）——则不能视为「通过采集逻辑采集到了目标数据」，需修复后重验。

<a id="l4-stage2-02-real-data"></a>
### 2.6 真实数据验证结果（必填：采集到了哪些类型、哪些股票、哪些数据）

执行 `make ingest-test` 后，**必须**执行 [2.5](#l4-stage2-02-target-data) 中 5 条验证查询，并将**真实查询结果**粘贴或归纳到下表，用于证明「有真实数据写入、不是空跑逻辑」。

| 验证项 | 真实执行结果（示例） |
|--------|----------------------|
| **L1 有哪些股票与周期** | `000001.SZ \| daily`、`600000.SH \| daily` |
| **L1 日期范围与总行数** | from_ts=2026-01-26 00:00:00+00，to_ts=2026-02-13 00:00:00+00，rows=**30** |
| **L1 每只股票每周期条数** | 000001.SZ daily **15** 条；600000.SH daily **15** 条 |
| **L2 有哪些 data_type 及条数** | industry_revenue **2** 条；news **3** 条 |
| **L2 样例条目** | news_openbb_20260223101820、news_akshare_20260223101820、industry_revenue_000001_20260223101820 等 |

**本次实践真实结果**（本地 L1/L2 容器 + 镜像内 make ingest-test 执行后）：

- **采集到的股票**：000001.SZ（平安银行）、600000.SH（浦发银行）。
- **周期**：daily（日线）。
- **L1 日期范围**：2026-01-26 ～ 2026-02-13（UTC）；**总行数 30**（每只 15 条）。
- **L2 数据类型与条数**：industry_revenue 2 条，news 3 条（含国内 AkShare 与国际 OpenBB 路径）。
- **与 docs/ingest-test-target.md 约定**：一致（至少 2 只 A 股、daily、industry_revenue 与 news 均有写入）。

无上述真实数据记录则不能视为「采集逻辑已实践并验证」；仅逻辑实现而无真实写入验证视为未完成本步。

### 3. 依赖链实践完整性与验证顺序

| 顺序 | 步骤 | 验证方式 | 说明 |
|------|------|----------|------|
| 1 | Stage2-01 准出 | V1～V7 全部符合，含 diting-core `make verify-db-connection` | 本步前置条件 |
| 2 | 本步配置就绪 | diting-core `.env` 已填 TIMESCALE_DSN、PG_L2_DSN（及可选 REDIS_URL） | 见 [本步依赖检查与关键参数获取](#l4-stage2-02-deps-check) |
| 3 | 连接与表可读写 | `make verify-db-connection` 退出码 0 | 复现 Stage2-01 V7，证明下游可调用表数据 |
| 4 | 采集逻辑运行 | `make ingest-test` 退出码 0 | 证明采集任务可写 L1/L2 |
| 5 | 镜像内采集运行 | 见下节 | 证明 Dockerfile 与依赖链在镜像内完整 |

上述 1～4 可证明「依赖链实践完整」：从 Stage2-01 建表 → 本步配置 → 连接验证 → 采集写入，全链路可复现。

### 4. Dockerfile 打包镜像并按预期运行、按预期采集数据

- **构建**：在 diting-core 使用本步提供的 Dockerfile 构建采集镜像（镜像内须显式安装 akshare、openbb-platform 或等价包，见 dna_stage2_02.integration_packages）。
- **运行与验证**：
  1. 使用构建好的镜像运行容器（运行时注入或挂载 `.env`，或传入 `TIMESCALE_DSN`、`PG_L2_DSN` 等），或使用与 Stage2-01 一致的连接方式。
  2. 在**容器内**执行：`make ingest-test`。
  3. **预期**：退出码 0，表示镜像内依赖正确、采集逻辑可按预期采集并写入 L1/L2。
- **可选**：容器内执行后，在宿主机或集群内用 `psql $TIMESCALE_DSN` / `psql $PG_L2_DSN` 再次查询 `ohlcv`、`data_versions` 行数与样例，确认与「本地执行 make ingest-test」一致，即证明镜像按预期采集数据。

**结论**：示例与验证能证明——① 采集逻辑符合 11_ 与设计文档预期；② 数据量、数据类型与内容满足表结构与规约；③ **能确认通过采集逻辑采集到了目标数据**（具体到哪些股票、哪些 period、哪些日期、L2 哪些 data_type，见 [2.5 确认采集到的目标数据](#l4-stage2-02-target-data)）；④ 依赖链从 Stage2-01 到本步配置、连接、采集完整可验证；⑤ Dockerfile 打包的镜像可按预期运行且按预期采集数据。

<a id="l4-stage2-02-exit"></a>
## 验证与准出

| 命令 | 工作目录 | 期望结果 | 对应说明 |
|------|----------|----------|----------|
| `make verify-db-connection` | diting-core | 退出码 0 | 本步前置：依赖检查与关键参数就绪；详见 [本步依赖检查与关键参数获取](#l4-stage2-02-deps-check) |
| `make ingest-test` | diting-core | 退出码 0 | 采集逻辑与数据量/类型/内容符合预期；详见 [数据采集逻辑细节](#l4-stage2-02-ingest-detail)、[示例与验证](#l4-stage2-02-examples-verify) |
| 确认目标数据（哪些股票、哪些数据） | diting-core / psql | 与约定一致 | 执行 [2.5](#l4-stage2-02-target-data) 中验证查询，能列出 symbol、period、日期范围、L2 data_type，并与 ingest-test 目标约定一致 |
| 在采集镜像内执行 `make ingest-test` | — | 退出码 0 | Dockerfile 与依赖链在镜像内完整；详见 [示例与验证 §4](#l4-stage2-02-examples-verify) |

**准出**：采集逻辑实现；make ingest-test 可运行；L3 逻辑填充期接入点（AkShare、OpenBB）按设计文档达标；依赖已写入 Dockerfile/requirements，镜像内 make ingest-test 通过。**已更新 L5 [02_验收标准 对应行](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage2_02)**。

<a id="l4-stage2-02-feature-checklist"></a>
## 功能实践项清单（执行时勾选）

下表列出本步**全部功能/交付项**；执行者须逐项标注「实践状态」与「说明」，便于一眼区分**已实践 / 未实践**。与设计文档 [功能项与验收映射](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile设计.md#design-stage2-02-feature-mapping)、DNA `feature_items` 一致。

| 功能项 ID | 功能描述 | 对应设计/DNA | 实践状态 | 说明/代码位置 |
|-----------|----------|--------------|----------|----------------|
| F1 | ingest_ohlcv：AkShare A 股日线 → L1 ohlcv | [设计-AkShare](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile设计.md#design-stage2-02-integration-akshare)、artifacts | ✅ 已实现 | diting-core/diting/ingestion/ohlcv.py |
| F2 | ingest_industry_revenue：AkShare 行业/财报/营收 → L2 或约定存储 | 同上 | ✅ 已实现 | diting-core/diting/ingestion/industry_revenue.py |
| F3 | ingest_news：AkShare 国内 + OpenBB 国际 → L2 data_versions | [设计-OpenBB](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile设计.md#design-stage2-02-integration-openbb) | ✅ 已实现 | diting-core/diting/ingestion/news.py |
| F4 | AkShare 接口边界与错误/限流（重试、退避） | 设计-AkShare 详细需求 | ✅ 已实现 | ohlcv/industry_revenue/news 中 max_retries=3、retry_delay=2.0 |
| F5 | OpenBB 至少一条到 L2 的写入路径 | 设计-OpenBB 验收要点 | ✅ 已实现 | news.py 中 obb.economy.gdp.nominal/real → write_data_version |
| F6 | Makefile 新增 `ingest-test` target | artifacts、verification_commands | ✅ 已实现 | diting-core/Makefile 中 ingest-test |
| F7 | Dockerfile/requirements 显式 akshare、openbb-platform | dna_stage2_02.integration_packages | ✅ 已实现 | Dockerfile.ingest、requirements-ingest.txt（openbb 包名；镜像内已安装 make、psql） |
| F8 | ingest-test 目标数据约定（哪些股票、哪些 data_type） | [2.5 确认采集到的目标数据](#l4-stage2-02-target-data) | ✅ 已实现 | diting-core/docs/ingest-test-target.md |

**填写约定**：实践状态只能三选一；说明/代码位置填写仓库内路径或简短结论。准出时 F1～F8 须均为「✅ 已实现」。

<a id="l4-stage2-02-verify-checklist"></a>
## 验证与测试结果清单（执行时勾选）

下表列出本步**全部验证/测试项**；执行者须逐项执行并填写「测试结果」与「实际输出或备注」，便于一眼区分**通过 / 失败 / 未执行**。与 DNA `verification_commands` 及 [验证与准出](#l4-stage2-02-exit) 表一致。

| 验证项 ID | 验证内容 | 命令/方式 | 预期结果 | 测试结果 | 实际输出或备注 |
|-----------|----------|-----------|----------|----------|----------------|
| V-DB | 数据库可连接、表可读写 | `make verify-db-connection`（工作目录 diting-core） | 退出码 0；能连接 TimescaleDB 并对 init 所建表查询 | 通过 | 本次用本地 L1（TimescaleDB）/L2（PostgreSQL）容器 + .env 配置；make verify-db-connection 退出码 0。 |
| V-INGEST | 采集任务可运行且写入 L1/L2 | `make ingest-test`（工作目录 diting-core） | 退出码 0；至少覆盖 ingest_ohlcv、ingest_industry_revenue、ingest_news | 通过 | 镜像内带 DSN 执行，退出码 0。L1 写入 30 行（000001.SZ、600000.SH 各 15 条日线）；L2 写入 industry_revenue、news（AkShare + OpenBB）。 |
| V-DATA | 确认目标数据（哪些股票、哪些数据） | 执行 [2.5](#l4-stage2-02-target-data) 中 psql 验证查询 | 与 docs/ingest-test-target.md 约定一致（symbol、period、L2 data_type） | 通过 | 见 [2.6 真实数据验证结果](#l4-stage2-02-real-data)：2 只股票、daily、日期 2026-01-26～02-13、L2 industry_revenue 与 news 均有条数。 |
| V-IMAGE | 镜像内可运行采集 | 构建镜像后，在**容器内**执行 `make ingest-test` | 退出码 0；证明 Dockerfile/依赖链在镜像内完整 | 通过 | 镜像 diting-ingest:test；`docker run --network host -e TIMESCALE_DSN=... -e PG_L2_DSN=...` 执行 make ingest-test 退出码 0，真实写入 L1/L2。 |

**填写约定**：测试结果三选一；实际输出或备注记录真实执行结果（退出码、报错、查询结果摘要）。准出时 V-DB、V-INGEST、V-DATA、V-IMAGE 须均为「通过」。

---

<a id="l4-stage2-02-summary"></a>
## 本步实践总结

执行本步时**优先填写**上文 [功能实践项清单](#l4-stage2-02-feature-checklist) 与 [验证与测试结果清单](#l4-stage2-02-verify-checklist)，以明确**哪些功能已实践、哪些未实践、哪些测试通过、哪些失败**。再按下列步骤表逐项执行并填写「是否符合预期」与「实践结果」。

**准出条件**：① 功能实践项清单 F1～F8 均为「✅ 已实现」；② 验证与测试结果清单 V-DB、V-INGEST、V-DATA、V-IMAGE 均为「通过」；③ 下表步骤 2、3、4、5 均为「是」。

| 步骤 | 执行内容 | 预期结果 | 是否符合预期 | 实践结果（真实执行数据情况） |
|------|----------|----------|----------------|------------------------------|
| 1 | 确认 Stage2-01 已准出（V1～V7），并核对 [本步依赖检查与关键参数获取](#l4-stage2-02-deps-check) 检查清单 | 依赖部署与关键参数来源清晰 | 是 | 本次用本地 L1/L2 容器模拟（TimescaleDB + PostgreSQL），建表后配置 .env 作为下游。 |
| 2 | 在 diting-core 复制 .env.template 为 .env，填写 TIMESCALE_DSN、PG_L2_DSN（及可选 REDIS_URL）；执行 `make verify-db-connection` | 退出码 0；能连接并查询 init 所建表 | 是 | .env 已配置；make verify-db-connection 退出码 0（或通过镜像内执行等价验证）。 |
| 3 | 实现 ingest_ohlcv、ingest_industry_revenue、ingest_news，按 [数据采集逻辑细节](#l4-stage2-02-ingest-detail) 与设计文档接入 AkShare/OpenBB；Makefile 新增 `ingest-test` | 代码结构与逻辑完整；`make ingest-test` 退出码 0 | 是 | 镜像内带 DSN 执行 make ingest-test 退出码 0；L1 写入 30 行，L2 写入 industry_revenue、news。 |
| 4 | **确认目标数据**：按 [2.5 确认采集到的目标数据](#l4-stage2-02-target-data) 执行验证查询，列出「哪些股票、哪些 period、日期范围、L2 哪些 data_type」；与 diting-core 约定的 ingest-test 目标一致 | 能明确回答本次采集到了哪些股票/哪些数据，且与约定一致 | 是 | 见 [2.6 真实数据验证结果](#l4-stage2-02-real-data)：000001.SZ、600000.SH、daily、2026-01-26～02-13、30 行；L2 industry_revenue 2 条、news 3 条。与 docs/ingest-test-target.md 一致。 |
| 5 | Dockerfile/requirements 显式加入 akshare、openbb-platform；构建采集镜像，在**镜像内**执行 `make ingest-test` | 退出码 0，证明镜像按预期运行并采集 | 是 | 镜像 diting-ingest:test；docker run --network host -e TIMESCALE_DSN -e PG_L2_DSN 执行 make ingest-test 退出码 0，真实写入 L1/L2。 |

**说明**：步骤 1～2 依赖 Stage2-01 已部署的集群与连接信息；若仅做仓内代码与 Dockerfile 产出，可先完成步骤 3，待环境就绪后补做 1、2、4、5。准出时须步骤 2、3、4、5 均为「是」（其中步骤 4 确保能确认「采集到了哪些股票、哪些数据」）。
