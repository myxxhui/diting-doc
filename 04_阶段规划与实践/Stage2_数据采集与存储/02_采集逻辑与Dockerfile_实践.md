# Stage2-02 采集逻辑与 Dockerfile

> [!NOTE] **[TRACEBACK] 步骤锚点**
> - **原子规约**: [_共享规约/11_数据采集与输入层规约](../../03_原子目标与规约/_共享规约/11_数据采集与输入层规约.md)
> - **DNA stage_id**: `stage2_02`
> - **本步设计文档**: [02_采集逻辑与Dockerfile设计](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile_设计.md#design-stage2-02-exit)
> - **本步 DNA 文件**: [dna_stage2_02_采集逻辑与Dockerfile.yaml](../../03_原子目标与规约/_System_DNA/Stage2_数据采集与存储/dna_stage2_02_采集逻辑与Dockerfile.yaml)
> - **逻辑填充期接入点**：本步须按设计文档中「逻辑填充期开源接入点」小节实现并达标，见 [AkShare](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile_设计.md#design-stage2-02-integration-akshare)、[OpenBB](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile_设计.md#design-stage2-02-integration-openbb)。

<a id="l4-step-nav"></a>
## 步骤导航
- **上一步**：[01_基础设施与依赖_实践](01_基础设施与依赖_实践.md#l4-stage2-01-goal)
- **下一步**：[03_本地测试与K3s连调_实践](03_本地测试与K3s连调_实践.md#l4-stage2-03-goal)

> [!IMPORTANT] **实践测试方式约定**
> 本步以**本地 Docker Compose**为**主要（默认）**实践测试方式，可选 ECS+K3s；无云凭证或无需真实集群时**优先**使用本地 Compose 完成验收。见 [00_系统规则_通用项目协议](../../00_系统规则_通用项目协议.md)、[02_三位一体仓库规约](../../03_原子目标与规约/_共享规约/02_三位一体仓库规约.md)#本地开发与部署文件。

**上下游关系总览**：本步**消耗** Stage2-01 准出（数据库与连接配置、表已建、`make verify-db-connection` 可过）；**产出** 采集任务（ingest_ohlcv、ingest_industry_revenue、ingest_news）、Dockerfile 与 `make ingest-test`，供 Stage2-03（本地测试与 K3s 连调）、Stage2-04/05（镜像打包与采集模块部署）使用。

## 关键下游依赖（来自 Stage2-01）

本步依赖 [01_基础设施与依赖_实践](01_基础设施与依赖_实践.md#l4-stage2-01-goal) 产出的数据库与连接方式。Stage2-01 准出时已包含**下游如何添加数据库连接配置并调用表数据**的验证；本步须与下列约定一致，并可作为 Stage2-01 的「下游引用示例」验证执行方。

| 依赖项 | 说明 | 本步用法 |
|--------|------|----------|
| **数据库连接配置** | 由 Sealed-Secrets 或 .env 提供；占位项见 diting-core `.env.template`（如 `TIMESCALE_DSN`、`REDIS_URL`、`PG_L2_DSN`），与 diting-infra 部署的 Service/NodePort 对应 | 采集任务写入 L1 TimescaleDB、L2 知识库时使用上述 DSN；配置来源见 [01_基础设施与依赖实践#关键下游引用与验证要求](01_基础设施与依赖_实践.md#l4-stage2-01-downstream) |
| **调用表数据** | Stage2-01 的 init Job 已建表；下游通过 DSN 连接并对约定表执行 INSERT/SELECT | 本步 `make ingest-test` 会写入 L1/L2 表；Stage2-01 准出验证含「在 diting-core 执行 make verify-db-connection 或等价」以确认可调用表数据 |
| **示例与验证** | Stage2-01 文档中「关键下游引用与验证要求」要求：在 diting-core 中提供最小验证（如 `make verify-db-connection`），连接 DB 并对 init 所建表执行 SELECT，退出码 0 | 本步实现时须提供该 make target 或等价脚本，供 Stage2-01 准出时执行；实现方式见 [01_基础设施与依赖设计](../../03_原子目标与规约/Stage2_数据采集与存储/01_基础设施与依赖_设计.md#design-stage2-01-exit) 与 11_ 规约 |

**验证归属**：上述「下游添加连接配置并调用表数据」的**验证执行**归属 Stage2-01 的准出检查清单（V7）；本步实现须保证该验证可被 Stage2-01 执行者复现（即本仓具备 `make verify-db-connection` 或等价）。

<a id="l4-stage2-02-verify-routes"></a>
## 验证路线说明（必读）

本步支持两种验证路线，执行前须明确选用哪一种。

| 路线 | 说明 | 适用场景 |
|------|------|----------|
| **默认：Docker Compose** | 在 **diting-infra** 使用 `compose/docker-compose.ingest.yaml` 启动本地 L1/L2（`make local-deps-up` → `make local-deps-init`）；在 **diting-core** 配置 `.env` 指向 localhost:15432/15433 后执行 `make verify-db-connection` → `make ingest-test`。部署与编排归属 infra，core 仅连接与验证（见 [02_三位一体仓库规约](../../03_原子目标与规约/_共享规约/02_三位一体仓库规约.md)#本地开发与部署文件）。V-IMAGE 可用 `docker run -e TIMESCALE_DSN=... -e PG_L2_DSN=...` 连宿主机 `host.docker.internal` 的 L1/L2。 | 日常开发、CI、无云凭证或无需真实集群时；**推荐作为默认验收路径**。 |
| **可选：ECS + K3s** | 在 **diting-infra** 按 [4. 实测前自建依赖与测试后回收](#l4-stage2-02-deploy-deps-and-cleanup) 顺序 ①～⑦：先 `make deploy-dev` 起 ECS/K3s，再 Helm 部署 TimescaleDB/Redis/PostgreSQL、Secret、Schema Init Job；在 **diting-core** 用 K3s NodePort/节点 IP 填写 `.env`，执行步骤 2～5；最后在 diting-infra 执行回收。 | 需要验证与真实 K3s 集群、NodePort、Sealed-Secrets 等一致时；需 Terraform/云凭证。 |

**填写约定**：在 [验证项与结果清单](#l4-stage2-02-verify-checklist)、[本步实践总结](#l4-stage2-02-summary) 的备注或「是否符合预期」中注明本次采用的路线（如「默认 Docker Compose」或「可选 ECS+K3s」），便于追溯。**外网不可达时**：可设置 `DITING_INGEST_MOCK=1` 后执行 `make ingest-test`（及镜像内同命令），采集逻辑会写入 mock 数据至 L1/L2，仍可完成 V-INGEST、V-DATA、V-IMAGE 验证。

<a id="l4-stage2-02-deps-check"></a>
## 本步依赖检查与关键参数获取

执行本步前，须按所选验证路线准备环境，并完成下列检查与参数准备。

- **默认路线（Docker Compose）**：依赖 **diting-infra** 内 `compose/docker-compose.ingest.yaml` 与 `make local-deps-up`、`make local-deps-init`；无需 Stage2-01 在 K3s 的准出，但 L1/L2 表结构须与 Stage2-01 的 schema 一致（见 diting-infra `scripts/local/init_l1_ohlcv_local.sql`、`init_l2_data_versions_local.sql`）。**diting-core** 仅配置 `.env` 并执行 `make verify-db-connection`、`make ingest-test`。
- **可选路线（ECS + K3s）**：必须确认 **Stage2-01 已准出**（V1～V7），再在 diting-core 用 K3s 提供的 DSN 填写 `.env`。

### 1. 依赖部署步骤检查清单

本步依赖 [01_基础设施与依赖_实践](01_基础设施与依赖_实践.md#l4-stage2-01-exit) 的验证项 V1～V7 全部通过。执行本步前建议逐项核对：

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

<a id="l4-stage2-02-deploy-deps-and-cleanup"></a>
### 4. 实测前自建依赖与测试后回收（可选路线：ECS + K3s）

本小节为**可选路线（ECS + K3s）**所用。选用**默认路线（Docker Compose）**时无需执行本段 ①～⑦，直接在 diting-core 按 README「Stage2-02 本地实践」执行（在 diting-infra 完成 `make local-deps-up`、`make local-deps-init` 后，在 diting-core 配置 `.env` 并执行 `make verify-db-connection`、`make ingest-test`）即可。

**环境依赖**：**步骤 2～5 均依赖** L1/L2 可用（默认路线下由 **diting-infra** 的 `compose/docker-compose.ingest.yaml` 与 `make local-deps-up`、`make local-deps-init` 提供；可选路线下由 Stage2-01 在 K3s 部署）：步骤 2 需在 diting-core 连库执行 `make verify-db-connection`；步骤 3 需连库执行 `make ingest-test` 写入数据；步骤 4 需连库执行 5 条 psql 查询确认目标数据；步骤 5 需在镜像内执行 `make ingest-test`，容器同样要能连上 L1/L2。步骤 1 仅为确认上述依赖已就绪。

**若选用可选路线且无现成集群与连接信息，须先按下列顺序在 diting-infra 部署测试集群与中间件，再在 diting-core 执行本步验证。**（无脚本，全部手动手顺。）

**操作顺序（实测前自建依赖）**：

| 顺序 | 执行位置 | 执行内容 | 说明 |
|------|----------|----------|------|
| ① | **diting-infra** | 若无可用集群：执行 `make deploy-dev`，等待完成；根据 deploy-engine 输出设置 **KUBECONFIG** | 需 Terraform/云凭证；与 [01_基础设施与依赖_实践](01_基础设施与依赖_实践.md)、[03_基础设施ECS与K3s就绪](../../Stage1_仓库与骨架/03_基础设施ECS与K3s_实践.md) 一致 |
| ② | **diting-infra** | V1 校验：`test -d charts/dependencies/timescaledb && grep -E '^version:' charts/dependencies/timescaledb/Chart.yaml`（redis、postgresql 同理）；确认 charts/values/*.yaml 存在且镜像 tag 已固定 | 见 [01_基础设施与依赖实践 步骤 1](01_基础设施与依赖_实践.md#l4-stage2-01-summary) |
| ③ | **diting-infra** | 按 diting-infra [Stage2-01-部署与验证](../../../diting-infra/docs/Stage2-01-部署与验证.md) 部署中间件：`helm upgrade --install timescaledb ...`、`helm upgrade --install redis ...`、`helm upgrade --install postgresql-l2 ...`（-n default，密码与 values 按文档） | 对应 Pod 为 Running；NodePort 见 values（如 30432/30379/30433） |
| ④ | **diting-infra** | 创建 Secret **diting-db-connection**（键 TIMESCALE_DSN、PG_L2_DSN）；按 [jobs/README](../../../diting-infra/jobs/README.md) 创建 ConfigMap **diting-schema-init-sql** 并 `kubectl apply -f jobs/schema-init-job.yaml`；等待 Job **diting-schema-init** 完成 | 表 ohlcv、data_versions 存在；DSN 由 NodePort + 节点 IP 拼接 |
| ⑤ | **diting-core** | 复制 `.env.template` 为 `.env`，填入 TIMESCALE_DSN、PG_L2_DSN（及可选 REDIS_URL）；执行 `make verify-db-connection`，退出码 0 | 确认下游可连 L1/L2 |
| ⑥ | **diting-core** | 按本步 [本步实践总结](#l4-stage2-02-summary) 步骤表执行步骤 2～5（验证项 V-DB、V-INGEST、V-DATA、V-IMAGE），并在 [验证项与结果清单](#l4-stage2-02-verify-checklist)、[目标数据约定与真实结果](#l4-stage2-02-target-data) 填写结果 | 全部完成后再做 ⑦ |
| ⑦ | **diting-infra** | **回收**：执行 `make stage2-01-full-down`（或先 `make stage2-01-down` 再 `make down`） | **正常**：⑥ 全部完成后再执行；**异常**：若 ①～⑥ 中途失败或意外退出，也须执行本步，避免 ECS 残留与计费 |

**权威引用**：①～④ 与 [01_基础设施与依赖_实践](01_基础设施与依赖_实践.md#l4-stage2-01-summary)、diting-infra [Stage2-01-部署与验证](../../../diting-infra/docs/Stage2-01-部署与验证.md) 一致；回收与 [清除验证环境（必做)](../../../diting-infra/docs/Stage2-01-部署与验证.md) 一致。

## 工作目录

**diting-core**

<a id="l4-stage2-02-goal"></a>
## 本步目标

OHLCV/新闻/行业 全数据结构与逻辑完整；Dockerfile 支持采集任务构建。前期可配置少存数据，code 结构与逻辑须完整。采集镜像须在 Dockerfile/requirements 中显式安装 AkShare、OpenBB（见设计文档「[依赖与镜像构建](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile_设计.md#design-stage2-02-deps)」与 dna_stage2_02.integration_packages）。**本步须提供一键构建本阶段所涉全部镜像的能力**：Makefile 提供单一 target（如 `make build-images`），一次执行即可构建本阶段全部镜像（当前为采集镜像 Dockerfile.ingest），便于 CI 与本地复现。

**执行指引**（三者关系）：
- **功能实践项清单**（F1～F9）= 本步交付项；执行时勾选「已实现 / 未实现」及代码位置。
- **验证项与结果清单**（V-DB / V-INGEST / V-DATA / V-IMAGE / V-BUILD-ALL）= 本步**唯一**测试结果填写处；按 [本步实践总结](#l4-stage2-02-summary) 步骤表顺序执行，每完成一步即在验证清单填写对应行，**不必在步骤表重复填写结果**。
- **本步实践总结步骤表** = 推荐执行顺序；步骤 2～6 分别对应 V-DB、V-INGEST、V-DATA、V-IMAGE、V-BUILD-ALL。

**无真实数据即未实践**：须在真实或本地 L1/L2 上跑通 `make ingest-test`，并在 [目标数据约定与真实结果](#l4-stage2-02-target-data) 中填写真实数据验证结果。准出条件见 [验证项与结果清单](#l4-stage2-02-verify-checklist) 与 [本步实践总结](#l4-stage2-02-summary)。

<a id="l4-stage2-02-ingest-detail"></a>
## 数据采集逻辑细节

### 1. 要求与任务类型

| 任务 ID | 数据源（逻辑填充期） | 写入目标 | 规约与设计引用 |
|---------|----------------------|----------|----------------|
| **ingest_ohlcv** | AkShare（A 股行情） | L1 TimescaleDB 表 `ohlcv` | [11_ 数据采集与输入层规约](../../03_原子目标与规约/_共享规约/11_数据采集与输入层规约.md)、[设计-AkShare](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile_设计.md#design-stage2-02-integration-akshare) |
| **ingest_industry_revenue** | AkShare（行业/财报、申万、营收占比） | 约定表或 Redis 缓存；Module A 输入 | 同上 |
| **ingest_news** | AkShare（国内部分）+ OpenBB（国际/宏观） | L2 知识库、L3 冷归档；按 07_ 版本化 | [设计-OpenBB](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile_设计.md#design-stage2-02-integration-openbb) |

- **L1 表结构**：`ohlcv(symbol, period, datetime, open, high, low, close, volume)`，主键 `(symbol, period, datetime)`，见 diting-infra `schemas/sql/01_l1_ohlcv.sql`。
- **L2 表结构**：`data_versions(data_type, version_id, timestamp, file_path, ...)` 等，见 diting-infra `schemas/sql/02_l2_data_versions.sql`；新闻/知识库写入 Agri-KG、Tech-KG、Macro-KG 按 11_ 与 07_ 规约。

### 2. 实践方式与依赖组件

- **国内数据**：以 **AkShare** 为统一 Python 接口；`ingest_ohlcv`（A 股）、`ingest_industry_revenue`、`ingest_news`（国内部分）必须走 AkShare，接口边界、错误与限流、写入契约见设计文档 [逻辑填充期开源接入点：AkShare](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile_设计.md#design-stage2-02-integration-akshare)。
- **国际/宏观/基本面**：**OpenBB** 覆盖宏观、大宗、财报等；与 AkShare 分工、Provider 抽象见 [逻辑填充期开源接入点：OpenBB](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile_设计.md#design-stage2-02-integration-openbb)。

**说明**：AkShare、OpenBB 的**接口实现**（调用方式、错误与限流、写入 L1/L2 的契约）按上述设计文档「逻辑填充期开源接入点」实现，**不按**下述「依赖组件」；「依赖组件」仅指本步所依赖的**存储与中间件**（由 Stage2-01 部署），接口实现无需依其部署方式。

- **依赖组件部署与配置**：TimescaleDB、Redis、PostgreSQL（L2）由 **Stage2-01** 在 diting-infra 中部署；本步仅在 **diting-core** 内通过 `.env`（或运行时从 Sealed-Secrets 注入）提供 `TIMESCALE_DSN`、`REDIS_URL`、`PG_L2_DSN`，不在此步部署中间件。
- **获取关键配置的步骤**：见上文 [本步依赖检查与关键参数获取](#l4-stage2-02-deps-check)：复制 `.env.template` → `.env`，填写上述 DSN，执行 `make verify-db-connection` 通过后再执行 `make ingest-test`。
- **验证项与执行顺序**：本步全部验证项（命令、期望结果、结果填写）见 [验证项与结果清单](#l4-stage2-02-verify-checklist)；推荐执行顺序见 [本步实践总结](#l4-stage2-02-summary) 步骤表。

### 3. 与系统数据需求（含双轨）的对应

按 [11_ 数据采集与输入层规约](../../03_原子目标与规约/_共享规约/11_数据采集与输入层规约.md) 与 [03_双轨制与VC-Agent](../../01_顶层概念/03_双轨制与VC-Agent.md)，本步 F1～F8 覆盖系统（含 A/B 双轨）所需数据采集能力：

| 系统需求 | 本步对应 | 说明 |
|----------|----------|------|
| **A 轨**：OHLCV 供 Module B 扫描、技术面信号 | F1 `ingest_ohlcv` | 写入 L1 ohlcv；03 步 MarketDataFeed 读 L1 |
| **双轨共用**：申万行业、营收占比供 Module A 打 Tag | F2 `ingest_industry_revenue` | 行业/财报/营收 → 约定表或 Redis；Module A 输入 |
| **B 轨**：基本面（财报、营收增速、研发占比）供 VC-Agent、逻辑证伪 | F2（AkShare 财报/营收）+ F5（OpenBB 宏观/基本面） | 11_ 与 L1 约定 VC-Agent 接入基本面；F2 含「财报、营收」，OpenBB 路径含营收增速、研发占比等 |
| **双轨共用**：新闻/知识库供 Module C 专家与 B 轨推理 | F3、F5 `ingest_news` | 国内 AkShare、国际 OpenBB → L2 data_versions / 知识库 |
| **数据量与范围** | F8、`docs/ingest-test-target.md` | 逻辑填充期与约定一致即可；生产扩展时须满足全市场扫描所需标的与历史深度（见 [Stage2 README#数据采集规划与实践步骤对照](README.md#stage2-data-plan-vs-steps)） |

**结论**：完成本步 F1～F8 并通过 V-DB/V-INGEST/V-DATA/V-IMAGE，即可保证采集层产出满足系统与双轨目标判断所需数据类型；数据量在逻辑填充期以 ingest-test-target 为准，生产扩展时在目标约定或 L5 中明确标的数/历史深度。

## 核心指令

```
你是在 diting-core 中执行 Stage2-02（采集逻辑与 Dockerfile）的实践者。必读：03_原子目标与规约/_共享规约/11_数据采集与输入层规约.md、global_const.data_ingestion、03_原子目标与规约/_共享规约/07_数据版本控制规约.md。

任务：
1. 实现采集任务（ingest_ohlcv、ingest_industry_revenue、ingest_news），按 03_原子目标与规约/_共享规约/11_数据采集与输入层规约.md 规约写入 L1/L2。
2. 按设计文档「逻辑填充期开源接入点：AkShare、OpenBB」小节实现并达标（实践重点、详细需求、验收要点见该设计文档）。
3. Dockerfile 支持采集镜像构建；在 Dockerfile 及 requirements 中显式加入 akshare、openbb-platform（或等价包）；构建后须在**镜像内**执行 make ingest-test 且退出码 0。
4. 在 Makefile 中新增 ingest-test target；退出码 0 表示通过。
5. 在 Makefile 中新增一键构建所有镜像的 target（如 `make build-images`）；一次执行构建本阶段所涉全部镜像（当前为采集镜像），退出码 0 表示全部构建成功。
```

<a id="l4-stage2-02-verify-checklist"></a>
<a id="l4-stage2-02-exit"></a>
<a id="l4-stage2-02-examples-verify"></a>
## 验证项与结果清单（本步唯一测试结果填写处）

下表为本步**全部验证项**：命令、工作目录、期望结果与**结果填写**合一。执行顺序按 [本步实践总结](#l4-stage2-02-summary) 步骤表；每完成一步即在对应行填写「测试结果」与「实际输出或备注」，**不必在步骤表重复填写**。与 DNA `verification_commands`、设计文档验收一致。

| 验证项 ID | 验证内容 | 命令/方式 | 工作目录 | 期望结果 | 测试结果 | 实际输出或备注 |
|-----------|----------|-----------|----------|----------|----------|----------------|
| V-DB | 数据库可连接、表可读写 | `make verify-db-connection` | diting-core | 退出码 0；能连接 L1/L2 并对 init 所建表查询 | 通过 | 默认路线：L1/L2 由 diting-infra compose 提供，core 仅连与验证 |
| V-INGEST | 采集任务可运行且写入 L1/L2 | `make ingest-test` | diting-core | 退出码 0；至少覆盖 ingest_ohlcv、ingest_industry_revenue、ingest_news | 通过 | 默认路线；本次环境外网不可达，使用 DITING_INGEST_MOCK=1 在容器内执行，30 rows L1 + industry_revenue/news L2 |
| V-DATA | 确认目标数据（哪些股票、哪些数据） | 执行 [目标数据约定与真实结果](#l4-stage2-02-target-data) 中 5 条 psql 验证查询 | diting-core / psql | 与 docs/ingest-test-target.md 约定一致（symbol、period、L2 data_type） | 通过 | 本次为 mock 数据：000001.SZ/600000.SH daily、30 行；L2 industry_revenue 1、news 2；见下方 5 条原始输出 |
| V-IMAGE | 镜像内可运行采集 | 构建镜像后，在**容器内**执行 `make ingest-test` | — | 退出码 0；证明 Dockerfile/依赖链在镜像内完整 | 通过 | 默认路线：docker run --network host -e TIMESCALE_DSN=... -e PG_L2_DSN=... [-e DITING_INGEST_MOCK=1] diting-ingest:test make ingest-test 退出码 0 |
| V-BUILD-ALL | 一键构建所有镜像 | `make build-images`（或项目约定名） | diting-core | 退出码 0；本阶段所涉全部镜像（当前为采集镜像）均成功构建；可辅以 `docker images` 或 Make 内自检 | 通过 | diting-ingest:test 构建成功；build-images OK |

**准出**：① F1～F9 均为「✅ 已实现」；② 上表五行测试结果均为「通过」；③ [目标数据约定与真实结果](#l4-stage2-02-target-data) 中真实数据表已填写。满足后更新 L5 [02_验收标准 对应行](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage2_02)。

**说明**：采集逻辑与表结构符合 11_、设计文档；依赖链顺序见本步实践总结步骤表；Dockerfile 构建与镜像内验证见 V-IMAGE。可选单测/集成测 Mock AkShare/OpenBB 覆盖接口与错误处理。

<a id="l4-stage2-02-target-data"></a>
<a id="l4-stage2-02-real-data"></a>
## 目标数据约定与真实结果

仅「退出码 0」无法证明采集到了**目标数据**。须在 diting-core 约定「ingest-test 目标数据」（如 `docs/ingest-test-target.md`），执行 `make ingest-test` 后做下列验证并**在本节下表填写真实结果**。

**约定内容**：L1 至少约定 symbol 列表（或数量）、period（如 daily）、日期范围；L2 至少约定 data_type（如 industry_revenue、news）及预期条数。

**必做 5 条验证查询**（执行后保留结果并填入下表）：

| 查询用途 | 命令示例 |
|----------|----------|
| L1 有哪些股票与周期 | `psql $TIMESCALE_DSN -c "SELECT DISTINCT symbol, period FROM ohlcv ORDER BY symbol, period;"` |
| L1 日期范围与总行数 | `psql $TIMESCALE_DSN -c "SELECT min(datetime) AS from_ts, max(datetime) AS to_ts, count(*) AS rows FROM ohlcv;"` |
| L1 每只股票每周期条数 | `psql $TIMESCALE_DSN -c "SELECT symbol, period, count(*) AS cnt FROM ohlcv GROUP BY symbol, period ORDER BY symbol, period;"` |
| L2 有哪些 data_type 及条数 | `psql $PG_L2_DSN -c "SELECT data_type, count(*) AS cnt FROM data_versions GROUP BY data_type ORDER BY data_type;"` |
| L2 样例条目 | `psql $PG_L2_DSN -c "SELECT data_type, version_id, timestamp FROM data_versions ORDER BY timestamp DESC LIMIT 5;"` |

**关于 L2 的 timestamp**：`data_versions.timestamp` 表示**该版本记录的写入时间**（即执行 `make ingest-test` 的时刻），不是新闻/财报等源数据的发布日期。每次重新执行 `make ingest-test` 会写入新版本，时间戳为当次运行时间；文档下表与下方「5 条原始输出」为**某次实践运行的快照**，读者若自行再跑一遍会得到新的时间戳。

**评判**：查询结果与约定一致（symbol、period、日期范围、L2 data_type 及条数）为通过；否则需修复后重验。无真实数据记录视为未完成本步。

**真实数据验证结果（必填）**：

| 验证项 | 真实执行结果 |
|--------|----------------|
| L1 有哪些股票与周期 | 000001.SZ daily、600000.SH daily |
| L1 日期范围与总行数 | from_ts=2026-01-26 00:00:00+00 to_ts=2026-02-13 00:00:00+00 rows=30 |
| L1 每只股票每周期条数 | 000001.SZ daily 15 条；600000.SH daily 15 条 |
| L2 有哪些 data_type 及条数 | industry_revenue 1 条；news 2 条 |
| L2 样例条目 | news news_openbb_20260223205006 2026-02-23 20:50:06；news news_akshare_20260223205006 2026-02-23 20:50:06；industry_revenue industry_revenue_000001_20260223205006 2026-02-23 20:50:06 |

**5 条验证查询的原始输出（执行结果）**  

以下为按上述 5 条命令执行后的**完整终端输出**，便于核对实际落库数据。L2 中的 `timestamp` 为**当次 make ingest-test 的写入时间**，非源数据发布日期；表中时间为**该次实践运行时刻**的快照，重新执行实践会得到新的时间戳。（本次实践采用**默认路线 Docker Compose**，执行时间 2026-02-23。）

（1）L1 有哪些股票与周期

```
 000001.SZ | daily
 600000.SH | daily
```

（2）L1 日期范围与总行数

```
 2026-01-26 00:00:00+00 | 2026-02-13 00:00:00+00 |   30
```

（3）L1 每只股票每周期条数

```
 000001.SZ | daily  |  15
 600000.SH | daily  |  15
```

（4）L2 有哪些 data_type 及条数

```
 industry_revenue |   1
 news             |   2
```

（5）L2 样例条目

```
 news             | news_openbb_20260223205006             | 2026-02-23 20:50:06.265787
 news             | news_akshare_20260223205006            | 2026-02-23 20:50:06.265787
 industry_revenue | industry_revenue_000001_20260223205006 | 2026-02-23 20:50:06.236795
```

<a id="l4-stage2-02-feature-checklist"></a>
## 功能实践项清单（执行时勾选）

下表列出本步**全部功能/交付项**；执行者须逐项标注「实践状态」与「说明」，便于区分**已实践 / 未实践**。与设计文档 [功能项与验收映射](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile_设计.md#design-stage2-02-feature-mapping)、DNA `feature_items` 一致。

| 功能项 ID | 功能描述 | 对应设计/DNA | 实践状态 | 说明/代码位置 |
|-----------|----------|--------------|----------|----------------|
| F1 | ingest_ohlcv：AkShare A 股日线 → L1 ohlcv | [设计-AkShare](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile_设计.md#design-stage2-02-integration-akshare)、artifacts | ✅ 已实现 | diting-core/diting/ingestion/ohlcv.py |
| F2 | ingest_industry_revenue：AkShare 行业/财报/营收 → L2 或约定存储 | 同上 | ✅ 已实现 | diting-core/diting/ingestion/industry_revenue.py |
| F3 | ingest_news：AkShare 国内 + OpenBB 国际 → L2 data_versions | [设计-OpenBB](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile_设计.md#design-stage2-02-integration-openbb) | ✅ 已实现 | diting-core/diting/ingestion/news.py |
| F4 | AkShare 接口边界与错误/限流（重试、退避） | 设计-AkShare 详细需求 | ✅ 已实现 | ohlcv/industry_revenue/news 中 max_retries=3、retry_delay=2.0 |
| F5 | OpenBB 至少一条到 L2 的写入路径 | 设计-OpenBB 验收要点 | ✅ 已实现 | news.py 中 obb.economy.gdp.nominal/real → write_data_version |
| F6 | Makefile 新增 `ingest-test` target | artifacts、verification_commands | ✅ 已实现 | diting-core/Makefile 中 ingest-test |
| F7 | Dockerfile/requirements 显式 akshare、openbb-platform | dna_stage2_02.integration_packages | ✅ 已实现 | Dockerfile.ingest、requirements-ingest.txt（openbb 包名；镜像内已安装 make、psql） |
| F8 | ingest-test 目标数据约定（哪些股票、哪些 data_type） | [目标数据约定与真实结果](#l4-stage2-02-target-data) | ✅ 已实现 | diting-core/docs/ingest-test-target.md |
| F9 | 一键构建所有镜像：Makefile 提供单一 target（如 `make build-images`），一次构建本阶段所涉全部镜像 | [设计-依赖与镜像构建](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile_设计.md#design-stage2-02-deps) | ✅ 已实现 | diting-core/Makefile 中 build-images |

**填写约定**：实践状态三选一；说明/代码位置填仓库路径或简短结论。准出时 F1～F9 须均为「✅ 已实现」。

---

<a id="l4-stage2-02-summary"></a>
## 本步实践总结

按下列步骤表顺序执行；**步骤 2～5 分别对应验证项 V-DB、V-INGEST、V-DATA、V-IMAGE**。每完成一步请在 [验证项与结果清单](#l4-stage2-02-verify-checklist) 填写对应行，**本表只填「是否符合预期」**，不必重复填写实践结果。

**准出条件**：见 [验证项与结果清单](#l4-stage2-02-verify-checklist) 节末（F1～F8 已实现、四验证项通过、目标数据真实结果已填）。

| 步骤 | 执行内容 | 预期结果 | 对应验证项 | 是否符合预期 |
|------|----------|----------|------------|----------------|
| 1 | 确认 Stage2-01 已准出（V1～V7），或**默认路线**下已在 diting-infra 执行 `make local-deps-up`、`make local-deps-init`，并核对 [本步依赖检查与关键参数获取](#l4-stage2-02-deps-check) | 依赖与关键参数来源清晰 | — | 是（**默认路线**：diting-infra compose 提供 L1/L2） |
| 2 | 在 diting-core 复制 .env.template 为 .env，填写 TIMESCALE_DSN、PG_L2_DSN（及可选 REDIS_URL）；执行 `make verify-db-connection` | 退出码 0；能连接并查询 init 所建表 | V-DB | 是 |
| 3 | 实现 ingest_ohlcv、ingest_industry_revenue、ingest_news，按 [数据采集逻辑细节](#l4-stage2-02-ingest-detail) 与设计文档接入 AkShare/OpenBB；Makefile 新增 `ingest-test`；执行 `make ingest-test` | 退出码 0；采集写入 L1/L2 | V-INGEST | 是 |
| 4 | 按 [目标数据约定与真实结果](#l4-stage2-02-target-data) 执行 5 条 psql 查询，并填写该节「真实数据验证结果」表 | 能列出 symbol、period、日期范围、L2 data_type，与约定一致 | V-DATA | 是 |
| 5 | Dockerfile/requirements 显式加入 akshare、openbb-platform；构建采集镜像，在**镜像内**执行 `make ingest-test` | 退出码 0；镜像内依赖与采集正常 | V-IMAGE | 是 |
| 6 | 在 Makefile 中新增一键构建 target（如 `make build-images`）；在 diting-core 执行该命令 | 退出码 0；本阶段所涉全部镜像（当前为采集镜像）均成功构建；可辅以 `docker images` 或 Make 内自检 | V-BUILD-ALL | 是 |

**说明**：步骤 2～6 均依赖 L1/L2 可用（步骤 6 仅依赖 Docker 与 Makefile，无需 L1/L2 运行）。**默认路线**：在 **diting-infra** 执行 `make local-deps-up`、`make local-deps-init` 后，在 **diting-core** 配置 `.env` 并执行步骤 2～6（编排与建表归属 infra，见 [02_三位一体仓库规约](../../03_原子目标与规约/_共享规约/02_三位一体仓库规约.md)）。**可选路线**为 ECS + K3s，须先按 [4. 实测前自建依赖与测试后回收](#l4-stage2-02-deploy-deps-and-cleanup) ①～⑦ 部署；**回收**：默认路线在 diting-infra 执行 `make local-deps-down`；可选路线等所有步骤验证完成后再在 diting-infra 执行 `make stage2-01-full-down`；若中途失败或意外退出，也须执行回收以免 ECS 残留。
