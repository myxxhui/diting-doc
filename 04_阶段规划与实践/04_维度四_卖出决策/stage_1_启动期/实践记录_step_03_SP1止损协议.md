# 实践记录 · 维度四·卖出决策 · 启动期 · step_03 · SP1 止损协议

> [!NOTE] **[TRACEBACK] 实践锚点**
> - **L3 step**: [step_03_SP1止损协议.md](../../../03_原子目标与规约/04_维度四_卖出决策/stages/stage_1_启动期/steps/step_03_SP1止损协议.md)
> - **DNA**: [_System_DNA/04_exit_engine/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/04_exit_engine/dna_stage_1_启动期.yaml)
> - **本阶段看板**: [README.md](./README.md)

---

## 一、本步计划（来自 L3）

- 目标：`StopLossProtocol` 完整实现（阈值 -15%、P1、buffer=0、全卖、不可撤销）、`ExitAuditORM` + `AuditLogger` + `evaluate_and_audit`、`POST /api/protocols/{name}/evaluate/{position_id}`、`scripts/evaluate_all_holdings.py`、`pytest tests/exit_engine/test_stop_loss.py`（≥12 条）及 `init_db` 含 `exit_audit_logs`。

---

## 二、实际进展（W3 · Composer · 已核验）

| L3 准出项 | 状态 | 说明 |
|---|---|---|
| `exit_protocols.yaml` + `protocol_config.py` | ✅ | SP1 阈值 -0.15、priority=1、advice 模板可配置 |
| `scripts/exit_step03_run.py` | ✅ | preview / evaluate-one / threshold-test / status |
| `GET /api/protocols/SP1/preview` | ✅ | protocol_router 已注册 |
| Makefile `exit-step03-*` | ✅ | 8 target 齐 |
| **`make exit-step03-all`** | ✅ | preview + 4 portfolio evaluate + threshold 边界 + **18 pytest passed** |

### 同会话验证（`diting-src`）

```bash
make exit-step03-all
# ✅ SP1 preview + evaluate + threshold + pytest
```

portfolio 4 只（601138/601088/300866/601899）evaluate-one 均 `success=true`，当前均未触发 SP1（`return_pct=null` 缺现价时跳过触发判定）。

---

## 三、测试运行

```bash
cd diting-src && make exit-step03-all
```

- `test_stop_loss.py` + `test_base_protocol.py`：**18 passed**
- threshold-test：-14% 不触发 / -15% 触发 / 缺 cost 跳过 ✅

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-17 | 初稿：SP1 + 审计 + 路由 + 脚本 + 单测 |
| 2026-05-23 | **W3 Composer**：yaml 驱动 SP1 + `exit_step03_run.py` + Makefile `exit-step03-*`；`make exit-step03-all` 同会话通过 |
