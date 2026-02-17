# L3 · Stage2-02 采集逻辑与 Dockerfile 设计

> [!NOTE] **[TRACEBACK] 原子规约锚点**
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

<a id="design-stage2-02-exit"></a>
## 准出

采集逻辑实现；Dockerfile 可构建采集镜像；make ingest-test 或等价命令可运行。
