# 实践记录 · 维度三·持仓监控 · 启动期 · step_04 · ProbeScheduler + SLI 聚合

> [!NOTE] **[TRACEBACK] 实践锚点**
> - **L3 step**: [step_04_探针调度器与SLI聚合.md](../../../03_原子目标与规约/03_维度三_持仓监控/stages/stage_1_启动期/steps/step_04_探针调度器与SLI聚合.md)
> - **本阶段看板**: [README.md](./README.md)

---

## 一、实际进展（W4 tier-1 · 已核验）

| L3 准出项 | 状态 | 说明 |
|---|---|---|
| **`make watch-step04-all`** | ✅ | **2026-05-25** 同会话复验退码 0 |
| P1~P4 once-all | ✅ | `node_sli_values` 30 行；10 active SoT 标的 |
| SLI aggregate | ✅ | 10 标的各 sli_score=100.0（3 探针/标的）|
| pytest scheduler + aggregator | ✅ | **17 passed** |
| `probes/scheduler.py` | ✅ | 四类 job；交易时段跳过 price；`session_ctx`；`NodeSLIValue` upsert |
| `probes/heartbeat.py` | ✅ | Redis KV `state_watch:probe:heartbeat:*` |
| `health/sli_aggregator.py` | ✅ | `_score_one` / `aggregate` |
| `db/models.py` `NodeSLIValue` | ✅ | 唯一索引 `(holding_id, metric)` |
| `db/session.py` `session_ctx` | ✅ | 异步上下文管理 |
| `api/routes/probes.py` | ✅ | trigger / status / heartbeat/all |
| `main.py` | ✅ | 注册 `probes_router` |
| `tests/.../test_sli_aggregator.py` | ✅ | 12 条 |
| `tests/.../test_scheduler.py` | ✅ | 交易时段 + 4 job |
| 全量 `tests/state_watch/` | ✅ | **57 passed**（本会话） |

## 二、验证（W4 · 一键合约）

**工作目录**：`diting-src`

```bash
cd diting-src && make watch-step04-all
```

**2026-05-25 输出摘要**：

| target | 结果 |
|---|---|
| `watch-step04-migrate` | `migrate: ok` |
| `watch-step04-prep` | yaml_ok=true, nodes_total=10, node_sli_values_rows=30 |
| `watch-step04-once-all` | delta=0（已有 SLI 样本）|
| `watch-step04-aggregate` | 10 active × sli_score=100.0 |
| `watch-step04-test` | **17 passed** |

**BLOCKED**：无（tier-1 + tier-2 调度心跳/SLI 样本均达）

## 三、备注

- CLI：`python3 -m apps.state_watch.probes.scheduler --once` / `--start`。
- `scheduler_skeleton.py` 保留兼容 step_03 手工验证，正式调度以 `probes.scheduler` 为准。

## 四、下一步

- step_05 及后续健康度计算 / 状态迁移（见 L3 阶段规划）。

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-17 | 初稿：step_04 落地 + pytest 全绿 |
| 2026-05-25 | **W4 tier-1 复验**：`make watch-step04-all` 绿 · 10 active SLI 聚合 |
