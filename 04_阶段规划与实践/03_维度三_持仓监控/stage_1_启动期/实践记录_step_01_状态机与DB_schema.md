# 实践记录 · 维度三·持仓监控 · step_01 · 状态机与 DB schema

> [!NOTE] **[TRACEBACK]**
> - **L3**: [step_01_状态机与DB_schema.md](../../../03_原子目标与规约/03_维度三_持仓监控/stages/stage_1_启动期/steps/step_01_状态机与DB_schema.md)
> - **DNA**: [_System_DNA/03_holding_watch/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/03_holding_watch/dna_stage_1_启动期.yaml)
> - **看板**: [README.md](./README.md)

---

## 一、本步计划

- LangGraph 单节点评估图 + T1～T6 规则；三表 ORM；FastAPI `/health`、`/api/state-machine/register` 等。

## 二、实际进展

| 项 | 状态 | 说明 |
|---|---|---|
| `apps/state_watch/` | ✅ | `config` / `main` / `db` / `state_machine` / `api/routes` |
| Redis | ⚠️ | 默认 `redis://localhost:6379/3`（与 cryo/deep_strike/exit 分库） |
| pytest | ✅ | `tests/state_watch/test_state_machine.py` + `test_db_schema.py` 共 **17 passed** |

## 三、测试运行

```bash
cd diting-src
PYTHONPATH=. python3 -m pytest tests/state_watch -v
# 17 passed
```

## 四、偏离与决策

- L3 `main.health` 原样例未测 DB：本实现增加 `ping_db()`，无 DB 时 `status` 为 `degraded`。
- 路由顺序：`/list/active`、`/by-symbol/{symbol}` 置于 `/{node_id}` 之前，避免 `list` 被误匹配。

## 五、下一步

- [step_02_财务与新闻探针](../../../03_原子目标与规约/03_维度三_持仓监控/stages/stage_1_启动期/steps/step_02_财务与新闻探针.md)

---

## 六、2026-05-21 W1 复验与 L3 对齐

| 项 | 结果 | 证据 |
|---|---|---|
| 状态机与 DB schema 单测 | ✅ | W1 合并验证包含 `tests/state_watch/test_state_machine.py` + `tests/state_watch/test_db_schema.py`，整体 `76 passed, 4 skipped` |
| L3 目标测试数 | ⚠️ | L3 写合计 `≥18`；当前记录为 17 passed，本轮沿用既有测试，未新增第 18 项 |
| Makefile 一键合约 | ✅（2026-05-22 复验） | `watch-step01-prep/test/all/status` 已落地 |

**结论（2026-05-21）**：17 passed。以下 **2026-05-22** 复验：57 passed + Makefile ✅。

### 2026-05-22 W1 全量复验（§4 日历行 · 覆盖本步）

| 项 | 结果 | 证据（`diting-src`） |
|---|---|---|
| `make watch-step01-all` | ✅ | async DB init + `57 passed`（`tests/state_watch` 全套，含探针/调度等后续 step 单测） |
| `watch-step01-*` Makefile | ✅ | 本轮补齐 prep / test / all / status（4 个 target） |
| L3 目标 `≥18` 用例 | ✅ | 57 passed ≥ 18 |
| W1 八步合并 pytest | ✅ | `176 passed`（2026-05-22） |

**结论**：§4 W1 行 D3 **仅 step_01**（日历行无 step_02）本机准出 ✅。

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-22 | §4 W1 复验：`watch-step01-all` 落地并通过；57 passed |
