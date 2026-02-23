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

## 关键下游依赖（来自 Stage2-01）

本步依赖 [01_基础设施与依赖部署](01_基础设施与依赖部署.md#l4-stage2-01-goal) 产出的数据库与连接方式。Stage2-01 准出时已包含**下游如何添加数据库连接配置并调用表数据**的验证；本步须与下列约定一致，并可作为 Stage2-01 的「下游引用示例」验证执行方。

| 依赖项 | 说明 | 本步用法 |
|--------|------|----------|
| **数据库连接配置** | 由 Sealed-Secrets 或 .env 提供；占位项见 diting-core `.env.template`（如 `TIMESCALE_DSN`、`REDIS_URL`、`PG_L2_DSN`），与 diting-infra 部署的 Service/NodePort 对应 | 采集任务写入 L1 TimescaleDB、L2 知识库时使用上述 DSN；配置来源见 [01_基础设施与依赖部署#关键下游引用与验证要求](01_基础设施与依赖部署.md#l4-stage2-01-downstream) |
| **调用表数据** | Stage2-01 的 init Job 已建表；下游通过 DSN 连接并对约定表执行 INSERT/SELECT | 本步 `make ingest-test` 会写入 L1/L2 表；Stage2-01 准出验证含「在 diting-core 执行 make verify-db-connection 或等价」以确认可调用表数据 |
| **示例与验证** | Stage2-01 文档中「关键下游引用与验证要求」要求：在 diting-core 中提供最小验证（如 `make verify-db-connection`），连接 DB 并对 init 所建表执行 SELECT，退出码 0 | 本步实现时须提供该 make target 或等价脚本，供 Stage2-01 准出时执行；实现方式见 [01_基础设施与依赖设计](../../03_原子目标与规约/Stage2_数据采集与存储/01_基础设施与依赖设计.md#design-stage2-01-exit) 与 11_ 规约 |

**验证归属**：上述「下游添加连接配置并调用表数据」的**验证执行**归属 Stage2-01 的准出检查清单（V7）；本步实现须保证该验证可被 Stage2-01 执行者复现（即本仓具备 `make verify-db-connection` 或等价）。

## 工作目录

**diting-core**

<a id="l4-stage2-02-goal"></a>
## 本步目标

OHLCV/新闻/行业 全数据结构与逻辑完整；Dockerfile 支持采集任务构建。前期可配置少存数据，code 结构与逻辑须完整。采集镜像须在 Dockerfile/requirements 中显式安装 AkShare、OpenBB（见设计文档「[依赖与镜像构建](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile设计.md#design-stage2-02-deps)」与 dna_stage2_02.integration_packages）。

## 核心指令

```
你是在 diting-core 中执行 Stage2-02（采集逻辑与 Dockerfile）的实践者。必读：03_原子目标与规约/_共享规约/11_数据采集与输入层规约.md、global_const.data_ingestion、03_原子目标与规约/_共享规约/07_数据版本控制规约.md。

任务：
1. 实现采集任务（ingest_ohlcv、ingest_industry_revenue、ingest_news），按 03_原子目标与规约/_共享规约/11_数据采集与输入层规约.md 规约写入 L1/L2。
2. 按设计文档「逻辑填充期开源接入点：AkShare、OpenBB」小节实现并达标（实践重点、详细需求、验收要点见该设计文档）。
3. Dockerfile 支持采集镜像构建；在 Dockerfile 及 requirements 中显式加入 akshare、openbb-platform（或等价包）；构建后须在**镜像内**执行 make ingest-test 且退出码 0。
4. 在 Makefile 中新增 ingest-test target；退出码 0 表示通过。
```

<a id="l4-stage2-02-exit"></a>
## 验证与准出

| 命令 | 工作目录 | 期望结果 |
|------|----------|----------|
| `make ingest-test` | diting-core | 退出码 0 |
| 在采集镜像内执行 `make ingest-test` | — | 退出码 0 |

**准出**：采集逻辑实现；make ingest-test 可运行；L3 逻辑填充期接入点（AkShare、OpenBB）按设计文档达标；依赖已写入 Dockerfile/requirements，镜像内 make ingest-test 通过。**已更新 L5 [02_验收标准 对应行](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage2_02)**。
