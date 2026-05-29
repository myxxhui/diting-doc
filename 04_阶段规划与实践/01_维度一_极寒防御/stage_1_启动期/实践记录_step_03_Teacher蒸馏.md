# 实践记录 · 维度一·极寒防御 · 启动期 · step_03 · Teacher 蒸馏（阶段 A + B 编排）

> [!NOTE] **[TRACEBACK] 实践锚点**
> - **L3 step**: [step_03_Teacher蒸馏.md](../../../03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/steps/step_03_Teacher蒸馏.md)
> - **DNA**: [_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml)
> - **本阶段看板**: [README.md](./README.md)

---

## 一、范围说明

| 分段 | 含义 |
|---|---|
| **阶段 A** | 契约 + Mock + 小批量 `pytest`（**不单独宣称** 3500/2600 全量已达成） |
| **阶段 B 编排** | **可在本机执行**：三引擎蒸馏 → `auto_accept` → 导出 LLaMA-Factory JSON → `holdout_guard`；**全量 API 费用与时间**取决于本机环境与 Key；**Verified ≥2600** 仍须人工/策略补足（`auto_accept` 仅为辅助） |

**是否建议在本地做阶段 B？** **可以、且常见**：SQLite + 直连 Anthropic，或本机起 **super_evo** 再走维度五 HTTP。建议先 **`--smoke`** 再全量；笔记本直连 Anthropic 时设 **`CRYO_SKIP_D5=1`**，避免先打无效 D5 请求。

---

## 二、实际进展（阶段 A）

| L3 § / 项 | 状态 | 说明 |
|---|---|---|
| `teacher_distill` 表（扩展字段 + 唯一约束） | ✅ | `apps/cryo_guard/db/models.py`：`report_period`、`case_hash`、`parse_status`、`teacher_*` 等 |
| `distillation/` 包 | ✅ | `prompts.py`、`teacher_client.py`（`CRYO_GUARD_DISTILL_MOCK`、`CRYO_D5_DISTILL_URL`）、`distill_runner.py`（`--limit`/`--dry-run`）、`verifier.py`（`auto_accept_if_safe`）、`exporter.py` |
| `holdout_guard` JSON 数组训练文件 | ✅ | `training/scripts/holdout_guard.py`：`*.json` 可为 **JSON 数组**（与 exporter 一致），保留 **JSONL** |
| 单测 | ✅ | `tests/cryo_guard/test_distillation.py`（**10** 条）；全量 `tests/cryo_guard/` **21 passed** |
| 阶段 B 编排脚本 | ✅ | `training/scripts/run_cryo_phase_b.py`；`Makefile`：`cg-phase-b-help` / `cg-phase-b-preflight` |
| `CRYO_SKIP_D5` | ✅ | `teacher_client.py`：本机直连 Anthropic 时跳过维度五 HTTP |
| `distill_runner` + W&B | ✅ | `CRYO_GUARD_WANDB=1` 时在 `run()` 内 `init` / `log` / `finish` |

### 本地库迁移注意

若已有旧版 `data/cryo_guard.db` 仅含旧列 `teacher_distill`，**不会自动 ALTER**；开发环境可 **删库后** `python -m apps.cryo_guard.db.init_db` 或与阶段 B 一并做 Alembic。

---

### 阶段 B：本机一键编排（`diting-src` 根目录）

```bash
# 预检（只读 DB / Holdout 路径，不调 Teacher）
make cg-phase-b-preflight
# 或：PYTHONPATH=. python3 training/scripts/run_cryo_phase_b.py --preflight-only

# Mock + 每引擎最多 5 条（CRYO_DISTILL_SMOKE_LIMIT 可改）
PYTHONPATH=. python3 training/scripts/run_cryo_phase_b.py --mock --smoke --skip-guard

# 真实 Teacher（笔记本示例：跳过 D5，直连 Anthropic；产生费用）
export CRYO_SKIP_D5=1
export ANTHROPIC_API_KEY=...   # 或 .env
PYTHONPATH=. python3 training/scripts/run_cryo_phase_b.py --smoke   # 先试跑
# 全量（去掉 --smoke；确保财报/公告/关联交易候选池足够）
PYTHONPATH=. python3 training/scripts/run_cryo_phase_b.py --verify-holdout-manifest

# 训练过程 W&B（可选）
export CRYO_GUARD_WANDB=1
```

全量准出后：**SQLite 计数**、人工/抽检 Verified、`dvc add`/`dvc push`（见 `training/.dvc/config`）、更新本节 **数字** 与 **14** W3 行 D1 格。

---

## 三、验证命令（工作目录：`diting-src`）

```bash
PYTHONPATH=. python3 -m pytest tests/cryo_guard/test_distillation.py -v --tb=short
PYTHONPATH=. python3 -m pytest tests/cryo_guard/ -q
```

### Mock 跑 1 条（示例）

```bash
export CRYO_GUARD_DISTILL_MOCK=1
python3 -m apps.cryo_guard.distillation.distill_runner --engine financial_fraud --limit 1
python3 -m apps.cryo_guard.distillation.verifier --engine financial_fraud
python3 -m apps.cryo_guard.distillation.exporter --engine financial_fraud
```

---

## 四、本会话测试输出摘要

- `tests/cryo_guard/test_distillation.py`：**10 passed**（含 `run_cryo_phase_b.py --help`）
- `tests/cryo_guard/`：**21 passed**

---

## 五、阶段 B 实际准出（2026-05-23 no-mock 真实执行）

### 执行摘要

| 项 | 数值 | 命令 |
|---|---|---|
| **DB 总行数** | **121 条**（fraud 51 / shareholder 16 / related_party 54） | `make cryo-step03-status` |
| **verified 导出** | **37 条**（fraud 12 / shareholder 10 / related_party 15） | `make cryo-step03-export` |
| **Teacher 模型** | `claude-sonnet-4-5`（Smoke 5 条/引擎）+ `claude-opus-4-6`（先前 9 条） | `.env TEACHER_MODEL` |
| **candidate 候选池** | annual财报=56 / 公告=2363 / 关联交易=48813 | `make cryo-step03-prep` |
| **LLaMA-Factory JSON** | fraud_train 10 / shareholder_train 8 / related_party_train 13 | `ls training/data/llama_factory/` |
| **no-mock 守卫** | `CRYO_GUARD_DISTILL_MOCK` 业务路径已 hard fail | `apps/common/no_mock_policy.py` |

### 准出核验证据

```
# DB 计数（2026-05-23 23:39 实测）
  financial_fraud: 51 条 | shareholder_integrity: 16 条 | related_party: 54 条
  总计：121 条

# verified export（非 mock Teacher）
  financial_fraud.json: 12 条（train 10 / val 1 / test 1）
  shareholder.json: 10 条（train 8 / val 1 / test 1）
  related_party.json: 15 条（train 13 / val 1 / test 1）

# pytest（21 passed）
  make cryo-step03-test → 21 passed
```

> **注**：启动期候选池约 67 条（财报标的 × 年份），已耗尽启动期可蒸馏数据。扩展期目标 3500 条在 `stage_2/step_01` 扩数据后方可达成；当前 37 条 verified 可解锁 M1 Teacher 入口。

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-17 | 阶段 A：distillation 包 + 表扩展 + holdout_guard 数组 + pytest |
| 2026-05-17 | 阶段 B 编排：`run_cryo_phase_b.py`、`CRYO_SKIP_D5`、`wandb` 在 `run()` 内闭环；Makefile；单测 +1 |
| 2026-05-23 | 阶段 B 真实执行：no-mock 清理 → step_02 补采 10 只 + 质量矩阵 21 项通过 → Sonnet smoke 3×5 条 → 全量 distill（fraud 43/shareholder 8/related_party 46）→ export 37 条 verified JSON → evo-step03 clean + import（labelings 31 条）→ 准出通过 |
