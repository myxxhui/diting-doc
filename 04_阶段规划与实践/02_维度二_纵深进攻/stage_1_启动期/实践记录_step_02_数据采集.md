# 实践记录 · 维度二·纵深进攻 · step_02 · 数据采集

> [!NOTE] **[TRACEBACK]**
> - **L3**: [step_02_数据采集.md](../../../03_原子目标与规约/02_维度二_纵深进攻/stages/stage_1_启动期/steps/step_02_数据采集.md)
> - **DNA**: [_System_DNA/02_deep_strike/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/02_deep_strike/dna_stage_1_启动期.yaml)
> - **看板**: [README.md](./README.md)

---

## 一、本步计划（来自 L3）

- 利润截留等相关原始数据采集脚本、入库与质检（详见 L3 §3）。

## 二、实际进展

| 项 | 状态 | 说明 |
|---|---|---|
| ORM 四表 | ✅ | `apps/deep_strike/db/models.py`：`FinancialReport`、`FinancialIndicator`、`Announcement`、`IndustryPeer`（`deep_strike.db` 与 cryo 库文件分离） |
| akshare / 巨潮源 | ✅ | `apps/deep_strike/data/sources/akshare_source.py`、`cninfo_source.py`；启动期业务路径应接真实数据源，tests 内 fixture 仅限单元测试 |
| normalizer / validator | ✅ | `apps/deep_strike/data/normalizer.py`、`validator.py` |
| CLI ingest | ⚠️ | `python3 -m apps.deep_strike.data.ingest 600519` 真流待复验；不得用 mock 业务数据作为准出证据 |
| 单测 | ✅ | `pytest tests/deep_strike/test_data_ingest.py`（6+ 用例，网络 mock） |
| 生产级联网全链路 | ⏳ | 依赖 eastmoney/cninfo 可达；未在本环境断言「已全量生产验证」 |

## 三、本会话已执行验证（工作目录 `diting-src`）

```bash
PYTHONPATH=. python3 -m pytest tests/deep_strike/test_data_ingest.py -v
```

## 四、依赖与阻塞

- 真数据依赖网络与 `akshare` / 巨潮接口可达；上游缺失时等待或在 `tests/` 内使用 fixture 单测，禁止把 mock 业务数据作为采集准出。

## 五、下一步

- 在类生产网络下跑通非 MOCK 的 `ingest`，并核对 L3 字段映射与 `stock_financial_report_sina` 等接口版本差异（若 akshare 变更则回写 `akshare_source.py`）。

---

## 六、2026-05-21 W1 复验与 L3 对齐

| 项 | 结果 | 证据 |
|---|---|---|
| 数据采集单测 | ✅ | W1 合并验证包含 `tests/deep_strike/test_data_ingest.py`，整体 `76 passed, 4 skipped` |
| no-mock L4 修正 | ✅ | 本记录删除旧 mock 环境变量作为验收命令的口径；仅承认 tests fixture 单测 |
| 真实采集与质量矩阵 | ⚠️ | 未执行 `make deep-step02-all`；未跑 L3 §3.5 的 12 项质量检查，不宣称数据准出 |
| Makefile 一键合约 | ✅（2026-05-22 复验） | `deep-step02-*` / `deep-step02-all` 已落地；`make deep-step02-all` → 31 passed |

**结论（2026-05-21）**：W1 只确认单测基线。以下 **2026-05-22** 复验更新 Makefile 为 ✅；真采与 [L-α] 仍 ⚠️。

### 2026-05-22 W1 全量复验（§4 日历行 · 覆盖本步）

| 项 | 结果 | 证据（`diting-src`） |
|---|---|---|
| `make deep-step02-all` | ✅ | `31 passed`（含 `test_data_ingest` + `test_profit_capture` 等；复用 cryo 共表 collect 步骤） |
| `deep-step02-*` Makefile | ✅ | prep / collect / test / all / status |
| D1 共表依赖验证 | ✅ | financial_reports=136·announcements=730·related_party_graph=340 全部就绪 |
| [L-α] Sniffer / Architect / Opus 4.7 | ⚠️ | 需 `ANTHROPIC_API_KEY` + 联网源；W2+ 阻塞项 |
| W1 合并 pytest | ✅ | **291 passed, 3 skipped**（2026-05-22 全量） |

**结论**：§4 W1 行 D2 `step_02` Makefile 合约 ✅；共表数据依赖已就绪 ✅；[L-α] 真流为 W2+ 阻塞项 ⚠️。

---

## 七、2026-05-23 [L-α] Opus 4.7 真流与 AIDispatcher 补充

| 项 | 结果 | 证据（`diting-src`） |
|---|---|---|
| `ANTHROPIC_API_KEY` 写入 `.env` | ✅ | key 已配置；`cg-phase-b-preflight` 显示 `ANTHROPIC_API_KEY=set` |
| AnthropicTeacherClient 默认 model | ✅ | 修复为读 `ANTHROPIC_MODEL` env（默认 `claude-opus-4-6`）；不再硬编码旧 slug |
| DNA Y01 `api_model_id` 同步 | ✅ | `dna_deep_strike_theme_sniffer.yaml` slug 从 `claude-opus-4-20250514` → `claude-opus-4-6` |
| D1 Teacher 冒烟（三引擎） | ✅ | `--smoke` 三引擎各 3 条，9 次 Anthropic API 调用，全部 `parse=ok` |
| `AIDispatcher` 骨架 | ✅ | `apps/common/ai_dispatcher.py`；5 场景路由（scorer/critic/architect/timer→remote; etl→local）；预算守门；无 key 自动降级 mock |
| `AIDispatcher` 单测 | ✅ | `tests/common/test_ai_dispatcher.py`：**14 passed**（含 `test_call_remote_real` 真实调用 Opus 通过） |
| Sniffer / Architect / Critic 业务逻辑 | ⏳ | W2 实现五场景业务代码；骨架已就绪 |
| Kafka `sniffer_raw_text` / Redis `monitor:*` | ⏳ | W2+ |

**结论（[L-α] 分阶段）**：
- **已完成**：key 配置 ✅ · model slug 修复 ✅ · Teacher 冒烟真调用 ✅ · AIDispatcher 骨架 + 14 测试 ✅
- **W2 待做**：五场景业务代码（Sniffer/Architect/Critic/Scorer/Timer）→ L-α 真流正式上线

---

## 七、W2 补充（Lighthouse 五场景 + FastAPI + monitor_dict）

| 项 | 状态 | 证据 |
|---|---|---|
| Lighthouse 五场景代码 | ✅ | `apps/deep_strike/lighthouse/`（sniffer/architect/critic/scorer/timer/orchestrator） |
| 单测 | ✅ | `make deep-step02-lighthouse-test` → **19 passed** |
| monitor_dict writer/reader | ✅ | `monitor_dict_writer.py` + `monitor_dict_reader.py` + `test_monitor_dict.py` **3 passed** |
| FastAPI 路由 | ✅ | `routes_lighthouse.py` 挂载至 `deep_strike/main.py`（/api/lighthouse/*） |
| Opus 远程联调 | ✅ | `make deep-step02-lighthouse-opus-smoke` 5 场景全通过（同会话历史复验） |
| 架构 Review | ✅ | [Lighthouse架构Review_W2_Opus.md](./Lighthouse架构Review_W2_Opus.md) |
| **未做（W3+）** | ⏳ | Playwright 物理 Sniffer · 四表 ingest · The Mapper · Redis 生产写入联调 |

```bash
cd diting-src
make deep-step02-lighthouse-all   # prep + 19p + monitor 3p
# 可选：make deep-step02-lighthouse-opus-smoke
```

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-23 | **W2 Lighthouse 准出**：五场景代码 + FastAPI + monitor_dict writer/reader + 22 passed；Opus smoke 5/5 ✅ |
| 2026-05-22 | §4 W1 全量复验：`make deep-step02-all` → 31 passed；[L-α] 真流未验 |
