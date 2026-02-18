# Stage2-02 采集逻辑与 Dockerfile

> [!NOTE] **[TRACEBACK] 步骤锚点**
> - **原子规约**: [_共享规约/11_数据采集与输入层规约](../../03_原子目标与规约/_共享规约/11_数据采集与输入层规约.md)
> - **DNA stage_id**: `stage2_02`
> - **本步设计文档**: [02_采集逻辑与Dockerfile设计](../../03_原子目标与规约/Stage2_数据采集与存储/02_采集逻辑与Dockerfile设计.md#design-stage2-02-exit)
> - **本步 DNA 文件**: [dna_stage2_02.yaml](../../03_原子目标与规约/_System_DNA/Stage2_数据采集与存储/dna_stage2_02.yaml)

<a id="l4-step-nav"></a>
## 步骤导航
- **上一步**：[01_基础设施与依赖部署](01_基础设施与依赖部署.md#l4-stage2-01-goal)
- **下一步**：[03_本地测试与K3s连调](03_本地测试与K3s连调.md#l4-stage2-03-goal)

## 工作目录

**diting-core**

<a id="l4-stage2-02-goal"></a>
## 本步目标

OHLCV/新闻/行业 全数据结构与逻辑完整；Dockerfile 支持采集任务构建。前期可配置少存数据，code 结构与逻辑须完整。

## 核心指令

```
你是在 diting-core 中执行 Stage2-02（采集逻辑与 Dockerfile）的实践者。必读：03_原子目标与规约/_共享规约/11_数据采集与输入层规约.md、global_const.data_ingestion、03_原子目标与规约/_共享规约/07_数据版本控制规约.md。

任务：
1. 实现采集任务（ingest_ohlcv、ingest_industry_revenue、ingest_news），按 03_原子目标与规约/_共享规约/11_数据采集与输入层规约.md 规约写入 L1/L2。
2. Dockerfile 支持采集镜像构建。
3. 在 Makefile 中新增 ingest-test target；退出码 0 表示通过。
```

<a id="l4-stage2-02-exit"></a>
## 验证与准出

| 命令 | 工作目录 | 期望结果 |
|------|----------|----------|
| `make ingest-test` | diting-core | 退出码 0 |

**准出**：采集逻辑实现；make ingest-test 可运行。**已更新 L5 [02_验收标准 对应行](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage2_02)**。
