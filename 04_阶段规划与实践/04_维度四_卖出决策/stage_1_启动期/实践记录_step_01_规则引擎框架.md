# 实践记录 · 维度四·卖出决策 · step_01 · 规则引擎框架

> [!NOTE] **[TRACEBACK]**
> - **L3**: [step_01_规则引擎框架.md](../../../03_原子目标与规约/04_维度四_卖出决策/stages/stage_1_启动期/steps/step_01_规则引擎框架.md)
> - **DNA**: [_System_DNA/04_exit_engine/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/04_exit_engine/dna_stage_1_启动期.yaml)
> - **看板**: [README.md](./README.md)

---

## 一、本步计划

- `exit-engine` FastAPI；`BaseProtocol` + SP1～SP4 占位；`SellSignal` / `SellSignalEvent`；同步 SQLite `holdings` 初始化。

## 二、实际进展

| 项 | 状态 | 说明 |
|---|---|---|
| `apps/exit_engine/` | ✅ | `config` / `main` / `protocols` / `models` / `db` |
| 默认监听端口 | ⚠️ | 代码默认 **8092**（`EXIT_PORT`），避免与 **super_evo** 占用 **8090**；`/health` JSON 含 `listen_port` |
| Redis | ⚠️ | 默认 `redis://localhost:6379/2` |
| pytest | ✅ | `tests/exit_engine/test_health.py` + `test_base_protocol.py` **7 passed** |

## 三、测试运行

```bash
cd diting-src
PYTHONPATH=. python3 -m apps.exit_engine.db.init_db
PYTHONPATH=. python3 -m pytest tests/exit_engine -v
# 7 passed
```

## 四、偏离与决策

- Python **3.9** 无 `dataclass(slots=True)`：Position / Portfolio / SellSignal 等已改为普通 `@dataclass`。
- L3 示例 `8090`：与当前仓库 super_evo 冲突，默认改为 **8092** 并在 `EXIT_PORT` 可覆盖。

## 五、下一步

- [step_02_持仓数据接入与行情](../../../03_原子目标与规约/04_维度四_卖出决策/stages/stage_1_启动期/steps/step_02_持仓数据接入与行情.md)

---

## 六、2026-05-21 W1 复验与 L3 对齐

| 项 | 结果 | 证据 |
|---|---|---|
| exit_engine health / base_protocol 单测 | ✅ | W1 合并验证包含 `tests/exit_engine/test_health.py` + `tests/exit_engine/test_base_protocol.py`，整体 `76 passed, 4 skipped` |
| L3 目标测试数 | ⚠️ | L3 写 `pytest ≥10`；当前 W1 范围只复验 health + base_protocol，共 7 项，未覆盖后续 SP1/SP2 等测试 |
| Makefile 一键合约 | ✅（2026-05-22 复验） | `exit-step01-prep/test/all/status` 已落地 |
| 永久规则 | ✅ | 本步仍保持 no-auto-execute：仅生成卖出信号，不自动交易 |

**结论（2026-05-21）**：7 passed。以下 **2026-05-22** 复验：63 passed + Makefile ✅。

### 2026-05-22 W1 全量复验（§4 日历行 · 覆盖本步）

| 项 | 结果 | 证据（`diting-src`） |
|---|---|---|
| `make exit-step01-all` | ✅ | DB init（holdings / exit_audit_logs / pending_signals）+ `63 passed` |
| `exit-step01-*` Makefile | ✅ | 本轮补齐 prep / test / all / status（4 个 target） |
| 永久 no-auto-execute | ✅ | 框架层无下单字段；与 [L-α] SP5 契约一致（advisory only） |
| W1 八步合并 pytest | ✅ | `176 passed`（2026-05-22） |

**结论**：§4 W1 行 D4 **仅 step_01** 本机准出 ✅；L3「≥10」用例已满足（63 passed 含后续 SP 协议单测）。

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-22 | §4 W1 复验：`exit-step01-all` 落地并通过；63 passed |
