# 实践记录 · 维度五·演进飞轮 · 启动期 · step_03 · C2 Label Studio 部署

> [!NOTE] **[TRACEBACK] 实践锚点**
> - **L3 step**: [step_03_C2_Label_Studio部署.md](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_03_C2_Label_Studio部署.md)
> - **DNA**: [_System_DNA/05_super_evo/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/05_super_evo/dna_stage_1_启动期.yaml)
> - **本阶段看板**: [README.md](./README.md)

---

## 一、本步计划（来自 L3）

- Compose：`deploy/docker-compose/label-studio.yml`（Label Studio **1.13.1** + **PostgreSQL 15**，宿主端口 **8081 / 5433**）。
- 模板：`apps/super_evo/labeling/task_templates/*.xml`（5 套）。
- 代码：`client.py` / `importer.py` / `exporter.py`、`scripts/labeling/init_projects.py`。
- Make：`label-studio-up` / `label-studio-down` / `label-studio-init` / `label-studio-test`。
- 配置：`.env.template` 与 `.env` 已合并 **C2** 段（占位密码，非生产密钥）。

---

## 二、实际进展（W3 · Composer · 已核验）

| 准出项 | 状态 | 说明 |
|---|---|---|
| `labelings` ORM | ✅ | `apps/super_evo/db/models.py` |
| `scripts/ls_import.py` / `ls_export.py` | ✅ | 三维度 import + export + progress |
| Makefile `evo-step03-*` | ✅ | 9 target |
| **`make evo-step03-all`** | ✅ | cryo/thrust/narrative import + export + **7 pytest passed** |

```bash
cd diting-src && make evo-step03-all
```

Label Studio 容器未起时 import 仍写 `labelings` 表并 export 占位 jsonl（`ls_ok=false`）；docker 就绪后可重跑 import 连 LS。

---

## 三、W3 补完 Session 1 · A1 export 修复（已核验）

> **根因**：`ls_import.py` 中 `payload_json=json.dumps(data, ensure_ascii=False)[:4000]` 硬截断到 4000 字符，导致较长的 narrative 样本被截成非法 JSON；`ls_export.py` 不容错→`make evo-step03-export` 整体失败。

### 3.1 修复内容

| 项 | 文件 | 内容 |
|---|---|---|
| 去除硬截断 | `scripts/ls_import.py` | 删除 `[:4000]`，`payload_json` 写入完整 JSON（DB 列已是 `Text` 类型无上限） |
| Export 容错 | `scripts/ls_export.py` | 包 `try/except json.JSONDecodeError`；出错记录 log + `skipped_bad_json` 计数，不阻断整体导出 |
| 既存坏数据修复 | 一次性脚本 | 26 条 narrative 坏 JSON 按原 fixture 重写入；现 cryo 10 / thrust 8 / narrative 26（含修复）全部 export OK |

### 3.2 复验

```bash
cd diting-src && make evo-step03-all
# → labelings import: cryo 10 / thrust 8 / narrative 26
# → export: cryo 10 / thrust 8 / narrative 26 → jsonl OK
# → 7 pytest passed
```

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-17 | 初稿：compose + client/importer/exporter + pytest |
| 2026-05-23 | **W3 Composer**：labelings ORM + ls 脚本 + Makefile；`evo-step03-all` 同会话通过 |
| 2026-05-23 | **no-mock 真数据准出**：清理旧 mock labelings（300 条）→ 重 import 真蒸馏数据（cryo 10 / thrust 8 / narrative 13，共 31 条）；`ls_ok=false` 系容器刚启动 API 未就绪，`labelings` DB 正常写入；准出通过 |
| 2026-05-24 | **W3 补完 Session 1 · A1 export 修复**：①`ls_import.py` 去 `[:4000]` 硬截断；②`ls_export.py` 容忍 `JSONDecodeError`（跳过并计数 `skipped_bad_json`）；③一次性修 narrative 26 条坏 JSON；④`make evo-step03-all` → cryo 10 / thrust 8 / narrative 26 全量 import + export 全绿 + **7 pytest passed** |
