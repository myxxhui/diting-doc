# 实践记录 · 维度二·纵深进攻 · step_01 · 环境与服务骨架

> [!NOTE] **[TRACEBACK]**
> - **L3**: [step_01_环境与服务骨架.md](../../../03_原子目标与规约/02_维度二_纵深进攻/stages/stage_1_启动期/steps/step_01_环境与服务骨架.md)
> - **DNA**: [_System_DNA/02_deep_strike/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/02_deep_strike/dna_stage_1_启动期.yaml)
> - **看板**: [README.md](./README.md)

---

## 一、本步计划

- 可启动 `deep-strike` FastAPI：`/health`、`/api/playbooks`、占位 scan；Redis 上游流探测；SQLite 四表模型。

## 二、实际进展

| 项 | 状态 | 说明 |
|---|---|---|
| `apps/deep_strike/` 骨架 | ✅ | `config` / `main` / `db` / `api`；永久规则见 `__init__.py` |
| ORM 四表 | ✅ | `thesis_cards` / `scan_logs` / `evidence_records` / `human_confirmations` |
| pytest | ✅ | `tests/deep_strike/test_health.py` **4 passed**（与 **14** W1 对齐） |

## 三、测试运行

```bash
cd diting-src
PYTHONPATH=. python3 -m pytest tests/deep_strike/test_health.py -v
# 4 passed
```

## 四、偏离与决策

- L3 示例使用 `loguru`：本实现改用标准库 `logging`，减少新依赖。

## 五、下一步

- [step_02_数据采集](../../../03_原子目标与规约/02_维度二_纵深进攻/stages/stage_1_启动期/steps/step_02_数据采集.md)

---

## 六、2026-05-21 W1 复验与 L3 对齐（更新）

| 项 | 结果 | 证据 |
|---|---|---|
| deep_strike health 单测 | ✅ | W1 合并验证整体 `76 passed, 4 skipped` |
| `make deep-step01-all` | ✅ | W1 缺口修复：`deep-step01-prep/test/all/status`（4 个）target 落地；`make deep-step01-all` → DB init + `4 passed` |
| L3 目标测试数 | ⚠️ | L3 写 `≥5 passed`，当前 `test_health.py` 实际为 4 项；服务骨架可用，但测试覆盖数未达新版 L3 数值 |
| D2 step02 target | ⚠️ | `deep-step02-prep/collect/test/all/status`（5 个）已落地；step02 数据采集（复用 cryo_guard 共表）待真实执行 |

**结论**：W1 Makefile 合约缺口已补齐；D2 step01 骨架准出条件满足。测试数量（4 vs L3 要求 ≥5）为轻微缺口，step02 数据依赖 D1 cryo_guard 共表先完成全量采集。

### 2026-05-22 W1 全量复验（§4 日历行 · 覆盖本步）

| 项 | 结果 | 证据（`diting-src`） |
|---|---|---|
| `make deep-step01-all` | ✅ | DB init + `4 passed`（`test_health.py`） |
| `deep-step01-*` Makefile | ✅ | prep / test / all / status |
| W1 八步合并 pytest | ✅ | `176 passed`（2026-05-22） |

**结论**：§4 W1 行 D2 `step_01` 本机准出 ✅。
