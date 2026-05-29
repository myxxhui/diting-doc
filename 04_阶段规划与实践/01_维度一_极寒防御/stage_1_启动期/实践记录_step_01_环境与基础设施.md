# 实践记录 · 维度一·极寒防御 · stage_1_启动期 · step_01 · 环境与基础设施

> [!NOTE] **[TRACEBACK] 实践锚点**
> - **L3 阶段设计**: [../../../03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/steps/step_01_环境与基础设施.md](../../../03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/steps/step_01_环境与基础设施.md)
> - **DNA**: [_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml)
> - **本阶段看板**: [README.md](./README.md)

---

## 一、本步计划（来自 L3）

### 来自 L3 stage 设计
- 引用：`03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/steps/step_01_环境与基础设施.md`
- 引用 DNA：`_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml`（`tech_stack`、`service_name`、`dependencies.upstream` 等）

### 本步目标（可验证子目标）
- [x] 建立 `apps/cryo_guard/` 骨架与占位子包（api/db/decision_gate/engines/llm/rag/graph）
- [x] FastAPI 入口、`/health`（engines + dependencies + upstream_streams）、`/api/decision-gate/health`（initializing）
- [x] SQLite 模型与 `init_db`；`deploy/k3s` 清单（Milvus / Neo4j / vLLM / vLLM-stub）；Makefile `cg-*`
- [x] `pytest tests/cryo_guard/test_health.py` 通过

---

## 二、实际进展

| 项 | 状态 | 说明 |
|---|---|---|
| §3.1 目录骨架 | ✅ | `apps/cryo_guard` 下 40 个 `.py`；`deploy/k3s`、`data/{milvus neo4j minio}`、`training/configs` 已建 |
| §3.2 依赖 | ✅ | 在保留仓库 `requires-python >=3.9` 前提下合并新增：`pymilvus`、`neo4j`、`langgraph`、`langchain-core`、`alembic`、`numpy`；未整包替换文档中的 hatch/py311 模板 |
| §3.3～3.5 配置/API | ✅ | vLLM 探活 URL 使用去掉 `/v1` 后缀的 root + `/health`（避免对 `rstrip('/v1')` 的错误字符集剥离） |
| §3.4 数据库 | ✅ | `sqlite3 data/cryo_guard.db ".tables"` 见五表 |
| §3.6 测试 | ✅ | 3 passed |
| §3.7～3.10 K3s 组件 | ⚠️ | 本机当前 `kubectl` 无法连集群（localhost:8080 refused），未在本环境验证 Pod Running；清单已落库 `diting-src/deploy/k3s/*.yaml` |

### 关键代码变更
- 工作目录：`diting-src` — 新增 `apps/cryo_guard/**`、`tests/cryo_guard/test_health.py`、`deploy/k3s/{milvus,neo4j,vllm,vllm-stub}.yaml`，更新 `pyproject.toml`、`Makefile`
- Commit hash: （未代提交；见用户 Git 规则）

---

## 三、测试运行

### 命令
```bash
cd diting-src
PYTHONPATH=. python3 -m apps.cryo_guard.db.init_db
PYTHONPATH=. python3 -m pytest tests/cryo_guard/test_health.py -v
```

### 输出（摘要）
```
[cryo-guard] tables created.
announcements         financial_reports     teacher_distill
cryo_guard_audit_log  holdout_cases
...
tests/cryo_guard/test_health.py::test_root PASSED
tests/cryo_guard/test_health.py::test_health_returns_ok PASSED
tests/cryo_guard/test_health.py::test_decision_gate_health_initializing PASSED
============================== 3 passed in 12.47s ==============================
```

### 结果
- 通过测试：3/3

---

## 四、偏离与决策

| 偏离 | 原因 | 决策 | 决策人 |
|---|---|---|---|
| L3 文档示例 `pyproject` 要求 Python ≥3.11 + hatch | 与现有 `diting-src` 可复现环境（3.9 + setuptools）不一致 | 仅追加本步所需依赖，不升仓内全局 `requires-python` | 实践执行 |
| 模型注解 `str \| None` | SQLAlchemy 在 3.9 下解析 `Mapped[str \| None]` 失败 | 改为 `Mapped[Optional[str]]` 等 | 实践执行 |
| K3s / Milvus / Neo4j / vLLM 运行态 | 本环境无可用集群上下文 | 交付 YAML + Makefile；在 GPU/ECS 节点按 L3 §3.7～3.10 复验 | 待验收方 |

---

## 五、问题与风险

| 问题 | 影响 | 应对 | 负责人 |
|---|---|---|---|
| 集群与端口转发未在本机验证 | §2 准出中 kubectl/端口项在此环境为「未核验」 | 上架节点执行 `make cg-deploy-infra` 或按 L3 手工 apply + port-forward | 部署侧 |
| `cg-test` 含 `--cov` | 与全仓 `tests/` 大规模跑测需区分 | 本步以 `tests/cryo_guard/test_health.py` 为准；全量回归另列 | 开发侧 |

---

## 六、下一步

- [ ] [step_02_数据采集与50案例Holdout](../../../03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/steps/step_02_数据采集与50案例Holdout.md)
- [ ] 在目标 K3s 节点完成 Milvus(19530) / Neo4j(7687) / vLLM(8000) 或 stub 的 Running 复验，并回填本记录 §3.7～3.10

---

## 七、2026-05-21 W1 复验与 L3 v2 对齐

| 项 | 结果 | 证据 |
|---|---|---|
| DB 初始化 | ✅ | `make cg-init-db`：`[cryo-guard] tables created.` |
| cryo_guard 测试集 | ✅ | `make cg-test`：`34 passed` |
| W1 合并最小验证 | ✅ | 合并运行 W1 相关测试文件：整体 `76 passed, 4 skipped` |
| L3 新 target 合约 | ⚠️ | L3 要求 `cryo-step01-*` / `cryo-step01-all`；当前 Makefile 已有 `cg-init-db` / `cg-test`，尚未实现完整 `cryo-step01-*` 一键合约 |
| K3s / Milvus / Neo4j / vLLM | ⚠️ | 本轮仍未获得可用集群上下文；仅确认本机 DB + API 单测，不宣称 Pod Running |

**结论**：W1 本机骨架与测试准出已复验；集群态与新版 Makefile 一键合约未完成，保持为部署侧阻塞项。

### 2026-05-22 W1 全量复验（§4 日历行 · 覆盖本步）

| 项 | 结果 | 证据（`diting-src`） |
|---|---|---|
| `make cryo-step01-all` | ✅ | `34 passed`（含 `--cov=apps/cryo_guard`） |
| `cryo-step01-*` Makefile 合约 | ✅ | prep / test / all / status 已落地 |
| K3s / Milvus / Neo4j / vLLM | ⚠️ | 本环境仍无可用集群；不宣称 Pod Running |
| W1 八步合并 pytest | ✅ | 合并验证 `176 passed`（2026-05-22） |

**结论**：§4 W1 行 D1 `step_01` 本机准出 ✅；集群态仍为部署侧阻塞。

---

## 八、引用

- L3 设计：[step_01_环境与基础设施.md](../../../03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/steps/step_01_环境与基础设施.md)
- DNA：[dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml)
- 共享规约：[13_六维度启动期集成与时序.md](../../../03_原子目标与规约/_共享规约/13_六维度启动期集成与时序.md) · [14_六维度启动期统一节奏表.md](../../../03_原子目标与规约/_共享规约/14_六维度启动期统一节奏表.md)

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-17 | 按 L3 step_01 落地代码骨架、`deploy/k3s`、`pytest` 与 L4 回填（集群态本地未验） |
