# 实践记录 · 维度四·卖出决策 · 启动期 · step_04 · SP2 止盈协议与缓冲期

> [!NOTE] **[TRACEBACK] 实践锚点**
> - **L3 step**: [step_04_SP2止盈协议.md](../../../03_原子目标与规约/04_维度四_卖出决策/stages/stage_1_启动期/steps/step_04_SP2止盈协议.md)
> - **DNA**: [_System_DNA/04_exit_engine/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/04_exit_engine/dna_stage_1_启动期.yaml)
> - **本阶段看板**: [README.md](./README.md)

---

## 一、本步计划（来自 L3）

- 目标：`TakeProfitProtocol`（阈值 +30%、P2、buffer=3 天、可撤销）、`PendingSignalORM` + `BufferManager`、`evaluate_with_buffer`、FastAPI `GET /api/buffer/pending` 与 `POST /api/buffer/{audit_id}/cancel`、APScheduler 1 分钟 `expire_due_signals`、单测 ≥18 项、端到端 `evaluate_all_holdings.py --protocol take_profit --mock-price`。

---

## 二、实际进展（W4 tier-1 · 已核验）

| L3 准出项 | 状态 | 说明 |
|---|---|---|
| **`make exit-step04-all`** | ✅ | **2026-05-25** 同会话复验退码 0 |
| 真 portfolio evaluate | ✅ | SoT 4 只 portfolio（601138/601088/300866/601899）；腾讯行情真拉取 |
| SP2 triggered | ✅ 合法 0 | 四标的均未达 +30% 阈值；`buffer_state=not_met`（tier-2 未触发合法）|
| pytest SP2 + streak | ✅ | **32 passed**（`test_take_profit` + `test_sp2_streak`）|
| `protocols/take_profit.py` | ✅ | `check`/`trigger`/`output_event`/`is_reverse_condition`；默认与 `settings` 对齐 |
| `models/buffer.py` + `services/buffer_manager.py` | ✅ | `enqueue`/`cancel`/`cancel_by_position`/`list_pending`/`expire_due`/`has_pending`；SQLAlchemy 2.x `select` |
| `services/protocol_runner.py` | ✅ | `evaluate_with_buffer`；缓冲成功仅记 `buffer_pending`，幂等时不重复审计 |
| `db/init_db.py` | ✅ | `create_all` 含 `pending_signals` |
| `routers/buffer_router.py` + `main.py` | ✅ | 注册 buffer 路由 |
| `services/quote_scheduler.py` | ✅ | `expire_due_signals_once` + `buffer_expire` 任务 |
| `routers/protocol_router.py` | ✅ | `take_profit` 走 `evaluate_with_buffer` |
| `scripts/evaluate_all_holdings.py` | ✅ | `take_profit` + `buffer_pending` / `buffer_already_pending` 标记 |
| `tests/exit_engine/test_take_profit.py` | ✅ | **22** 条（含 API、反向取消审计） |
| `tests/exit_engine/test_buffer_manager.py` | ✅ | **9** 条 |
| `tests/exit_engine/test_base_protocol.py` | ✅ | 占位 `NotImplemented` 仅 SP3/SP4 |
| 全量 `tests/exit_engine/` | ✅ | **63 passed**（本会话） |
| commit / push | ⚠️ | 未执行（按用户规则） |

### 关键代码变更（工作目录：`diting-src`）

- `apps/exit_engine/models/buffer.py`、`services/buffer_manager.py`
- `apps/exit_engine/protocols/take_profit.py`
- `apps/exit_engine/services/protocol_runner.py`、`services/quote_scheduler.py`
- `apps/exit_engine/routers/buffer_router.py`、`routers/protocol_router.py`、`main.py`、`db/init_db.py`
- `scripts/evaluate_all_holdings.py`
- `tests/exit_engine/test_take_profit.py`、`test_buffer_manager.py`、`test_base_protocol.py`

### 说明

- **Python 3.9**：`PendingSignal` 未使用 `dataclass(slots=True)`（避免 `TypeError` 与失败导入导致 metadata 重复注册）。
- **端到端触发笔数**：`quotes_mock.json` 下收益率 ≥30% 的标的为 **601318 / 000333 / 002594** 共 **3** 笔（300750 约 +27.78% 未触发，与 L3 文本中「triggered=False」一致；L3 提要「至少 4 笔」与同一文档收益率表不一致，以阈值 **0.30** 为准）。
- **buffer_days**：仍默认 **3** 天，与 `ExitEngineSettings.sp2_take_profit_buffer_days` 一致。

---

## 三、验证（W4 · 一键合约）

**工作目录**：`diting-src`

```bash
cd diting-src && make exit-step04-all
```

**2026-05-25 输出摘要**：

| target | 结果 |
|---|---|
| `exit-step04-preview` | threshold=0.3, buffer_days=3, sell_ratio=1.0 |
| `exit-step04-preview-distribution` | 4 portfolio → `not_met`（return_pct 最高 601138 +13.2%）|
| `exit-step04-buffer-progress` | `symbols_with_logs=0`（无 pending，合法）|
| `exit-step04-evaluate-one` | 4/4 success, `triggered=false` |
| `exit-step04-test` | **32 passed** |

**BLOCKED**：无（tier-1 全绿；tier-2「有 triggered 样本」未达，属 14 表「不算 tier-2 欠项」）

**历史烟测（2026-05-17 · mock-price）**：10 笔中 3 笔 buffer_pending — 保留作 buffer 逻辑参考，W4 准出以 SoT 真行情 evaluate 为准。

---

## 四、问题与风险

- **到期 firing**：`expire_due` 当前仅将状态置为 `fired`，未接 Redis Stream 发布；与 step_05+ 或集成任务衔接时再补 `events:exit:sell_signal` 写入与审计 `event_published`。

---

## 五、下一步

- [step_05_SP3_Thesis失效协议.md](../../../03_原子目标与规约/04_维度四_卖出决策/stages/stage_1_启动期/steps/step_05_SP3_Thesis失效协议.md)

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-17 | 初稿：SP2 + Buffer + 路由 + 调度 + 单测 63 全绿 + 端到端 3 笔入队 |
| 2026-05-25 | **W4 tier-1 复验**：`make exit-step04-all` 绿 · 真 portfolio 4 只 evaluate · triggered=0 合法 |
