# L4 · 纵深进攻 · 03 V1 特征工程 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[纵深进攻/05_实施推演_设计.md#三v1完整能力](../../03_原子目标与规约/纵深进攻/05_实施推演_设计.md#三v1完整能力)
> - **DNA**：[`dna_deep_strike_v1_feature.yaml`](../../03_原子目标与规约/_System_DNA/deep_strike/dna_deep_strike_v1_feature.yaml)
> - **L5 准出**：[`02_验收标准.md#l5-pillar-deep-v1-feature`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-deep-v1-feature)

<a id="l4-deep-v1-feature-goal"></a>
## 一、本阶段目标
- **stage_id**: `deep_strike_v1_feature`
- **工作目录**: `diting-src/diting/deep_strike/feature_engine/`
- **依赖**: `deep_strike_v1_council`
- **里程碑**: 信号特征工程批 + 流双管道 + 嵌入向量索引 + 预期差量化

## 二、本步骤落实的 DNA 键
- `feature_engine_batch`：每日批跑 → Feature Store 写入
- `feature_engine_stream`：实时事件 → 流特征
- `embedding_index`：Milvus / pgvector
- `expectation_gap_quantifier`：与市场共识对比 + 动量折现

## 三、实施内容（5D）
1. 批管道（Spark/Ray）：行情衍生 / 事件聚合 / 行业 / 嵌入
2. 流管道（Flink/Faust）：实时事件触发
3. Feature Store（Feast 或自建）写入与读取
4. 嵌入向量索引（Milvus 起步）+ hybrid 检索
5. expectation_gap_quantifier 公式实现 + 动量衰减

## 四、可执行验证清单
| 命令 | 工作目录 | 期望 |
|------|---------|------|
| `make test-feature-engine` | diting-src | exit 0 |
| `make daily-batch-feature` | diting-src | 全市场跑成功；Feature Store 行数符合 |
| `make rag-latency-bench` | diting-src | P99 < 500ms |
| `make expectation-gap-bench` | diting-src | gap_score 对历史样本可计算 |

## 五、准出检查清单
- [ ] 每日批跑成功；Feature Store 写入
- [ ] RAG 检索 P99 < 500ms
- [ ] gap_score 可计算且与历史样本一致
- [ ] **已更新 [`02_验收标准.md#l5-pillar-deep-v1-feature`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-deep-v1-feature)**

<a id="l4-deep-v1-feature-exit"></a>
## 六、L5 准出锚点
`l5-pillar-deep-v1-feature`

## 七、本步骤失败时
- 批跑失败：保留上次成功 snapshot；议会消费旧特征 + degraded
- 同 [极寒防御/01_MVP §七](../极寒防御/01_MVP_本阶段实践与验证.md#七本步骤失败时)

## 八、上一步 / 下一步
- **上一步**：[02_V1_council](./02_V1_council_本阶段实践与验证.md)
- **下一步**：[04_V1_eval](./04_V1_eval_本阶段实践与验证.md)
