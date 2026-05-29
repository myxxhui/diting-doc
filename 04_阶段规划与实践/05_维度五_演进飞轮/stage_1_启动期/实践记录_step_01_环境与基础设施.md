# 实践记录 · 维度五·演进飞轮 · step_01 · 环境与基础设施

> [!NOTE] **[TRACEBACK] 实践锚点**
> - **L3 阶段设计**: [step_01_环境与基础设施.md](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_01_环境与基础设施.md)
> - **DNA**: [_System_DNA/05_super_evo/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/05_super_evo/dna_stage_1_启动期.yaml)
> - **本阶段看板**: [README.md](./README.md)

---

## 一、本步计划（来自 L3）

### 来自 L3 stage 设计

- 引用：`03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_01_环境与基础设施.md`（§2 准出、§3 实施）
- DNA：`03_原子目标与规约/_System_DNA/05_super_evo/dna_stage_1_启动期.yaml`（`service_name` / `tech_stack` / `work_dir`）

### 本步目标（可验证子目标）

- [x] `apps/super_evo/` 骨架 + FastAPI `/health`（redis / minio / dvc / wandb 四组件）
- [x] `pyproject.toml` 补齐 super-evo 依赖；`deploy/docker-compose/super-evo-infra.yml` 拉起 MinIO + Redis
- [x] `training/` 下 `dvc init --no-scm` + MinIO S3 remote；`super-evo` bucket 已创建
- [x] `pytest tests/super_evo/` 全绿；本地 `uvicorn` + `curl /health` 验证 `status: ok`

---

## 二、实际进展

| §3 子步骤 | 状态 | 说明 |
|---|---|---|
| 3.1 目录骨架 | ✅ | `apps/super_evo/` 9 子包 + `training/`、`deploy/`、`tests/super_evo/` |
| 3.2 依赖 | ✅ | 见「偏离与决策」：Python 3.9 下版本收敛 |
| 3.3 config.py | ✅ | `SuperEvoSettings` + `pydantic-settings` |
| 3.4 minio_client | ✅ | boto3 path-style，适配本机 MinIO |
| 3.5 dvc_manager | ✅ | `python -m dvc` 回退；`configure_remote` 可重复执行 |
| 3.6 wandb_tracker | ✅ | 无 `WANDB_API_KEY` 时 mode 降为 offline |
| 3.7 main.py | ✅ | lifespan 注入 redis/minio/dvc/wandb |
| 3.8 docker-compose | ✅ | `super-evo-minio` / `super-evo-redis` 已 Up |
| 3.9 MinIO + DVC 初始化 | ✅ | bucket + `training/.dvc` + remote `minio` |
| 3.10 .env / template | ✅ | `.env.template` 追加 super-evo 段；由模板生成 `.env`（仓库不提交 `.env`） |
| 3.11–3.12 测试 | ✅ | 7 passed |
| 3.13 uvicorn + curl | ✅ | `status: ok`，四组件均 ok |
| 3.14 pytest | ✅ | 同 3.11–3.12 |
| 3.15 Makefile | ✅ | `super-evo-infra-up/down`、`super-evo-dev`、`super-evo-test` |
| 3.16 git commit | ⚠️ | **未执行**：按工作区约定待你显式要求后再提交 |

### 关键代码变更

- 工作目录：`diting-src`（新增 `apps/super_evo/`、`tests/super_evo/`、`deploy/docker-compose/super-evo-infra.yml`、`training/.dvc` 等）
- Commit hash: （待提交后回填）

---

## 三、测试运行

### 命令

```bash
cd diting-src
docker compose -f deploy/docker-compose/super-evo-infra.yml up -d
python3 -m pip install -e .
PYTHONPATH=. python3 -m pytest tests/super_evo/test_health.py tests/super_evo/test_storage.py -v
PYTHONPATH=. python3 -m uvicorn apps.super_evo.main:app --port 8090
curl -s http://127.0.0.1:8090/health | python3 -m json.tool
make super-evo-test
```

### 输出（/health 摘要）

```json
{
    "status": "ok",
    "service": "super-evo",
    "components": {
        "redis": { "ok": true },
        "minio": { "ok": true, "bucket": "super-evo", "endpoint": "http://localhost:9000" },
        "dvc": { "ok": true, "repo": "training", "remotes": ["minio\ts3://super-evo/dvc-store"] },
        "wandb": { "ok": true, "project": "diting-super-evo", "mode": "offline", "key_set": false }
    },
    "output_stream": "events:flywheel:lora_updated"
}
```

### pytest

```
tests/super_evo/test_health.py::test_root_returns_service_name PASSED
tests/super_evo/test_health.py::test_health_returns_components PASSED
tests/super_evo/test_health.py::test_health_status_field_is_ok_or_degraded PASSED
tests/super_evo/test_storage.py::test_minio_upload_download_bytes PASSED
tests/super_evo/test_storage.py::test_minio_list_keys PASSED
tests/super_evo/test_storage.py::test_minio_upload_fileobj PASSED
tests/super_evo/test_storage.py::test_dvc_health_reports_initialized PASSED
============================== 7 passed in 5.92s ===============================
```

### 结果

- 通过测试：**7/7**
- 失败测试：无

---

## 四、偏离与决策

| 偏离 | 原因 | 决策 | 决策人 |
|---|---|---|---|
| L3 §3.2 与 L3 §2 依赖表述 | 当前默认解释器为 **Python 3.9.6**；`dvc>=3.50` + `dvc[s3]` 在 pip 解析器上极慢且易触发 aiobotocore/boto3 与 **pathspec 1.x** 冲突 | `pyproject.toml` 采用：`dvc>=3.48,<3.49`、`dvc-s3>=3.0,<3.1`、`boto3/botocore>=1.34,<1.35`、`pathspec>=0.11,<0.12`；与 L3 示例数值略有收敛，语义一致 | AI 执行回填 |
| WandB `wandb login` | 本地未配置有效 `WANDB_API_KEY` | 按 L3 §6 回退：`WandbTracker` 自动 **offline**；`/health` 仍返回 `wandb.ok: true`；上线前再执行 `wandb login` 或写入 key | AI 执行回填 |

---

## 五、问题与风险

| 问题 | 影响 | 应对 | 负责人 |
|---|---|---|---|
| `dvc` 可执行文件不在 PATH（user site-packages） | 裸 `dvc` 命令失败 | `DVCManager` 优先 `shutil.which("dvc")`，否则 **`python3 -m dvc`** | 已落在代码 |
| 与本机 **6379** 上其他 Redis 冲突 | super-evo 连不上 Redis → `/health` degraded | 调整 `SUPER_EVO_REDIS_URL` 或停掉占用端口的实例 | 部署时关注 |

---

## 六、下一步

- [ ] [step_02_C1_Teacher蒸馏器](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_02_C1_Teacher蒸馏器.md)
- [ ] 在 `diting-src` 执行 L3 §3.16 所述 `git add` / `commit` / `push`（需你本地确认分支与密钥不入库）

---

## 七、2026-05-21 W1 复验与 L3 v3 对齐（更新）

| 项 | 结果 | 证据 |
|---|---|---|
| W1 最小 pytest | ✅ | W1 合并验证整体 `76 passed, 4 skipped` |
| Makefile 已落地 target | ✅ | `make super-evo-test`：`29 passed, 4 skipped` |
| L3 v3 新 target 合约 | ✅ | W1 缺口修复：`evo-step01-infra-up/down/init/test/all/status`（6 个）+ `evo-step02-test/smoke/all`（3 个）全部落地 |
| MinIO 真连通 | ✅ | W1 缺口修复：`docker compose -f deploy/docker-compose/super-evo-infra.yml up -d` 成功；Python boto3 smoke test 通过（见 §八） |
| `make evo-step01-test` | ✅ | `7 passed`（含 `test_minio_upload_download_bytes` / `test_minio_list_keys` / `test_minio_upload_fileobj` 真实连通用例） |
| `make evo-step02-all` | ✅ | `14 passed`（Teacher 蒸馏器；infra 已就绪） |

**结论**：W1 MinIO 真连通验证通过；`evo-step01-*` / `evo-step02-*` Makefile 合约落地；D5 step01 准出条件（基础设施 + storage 单测）已满足。

### 2026-05-22 W1 全量复验（§4 日历行 · 覆盖本步）

| 项 | 结果 | 证据（`diting-src`） |
|---|---|---|
| `make evo-step01-all` | ✅ | `7 passed`（health + storage · MinIO 真连通） |
| [L-α] AIDispatcher / ETL / Kafka | ⚠️ | L3 step_01 已 merge_inplace 规划；本步代码以 MinIO/Redis/health 为准，ETL vLLM:8091 与 Kafka 消费骨架待后续 step 落地 |
| W1 八步合并 pytest | ✅ | 与 D1/D2/D3/D4 W1 步合并：`176 passed`（2026-05-22） |

**结论**：§4 W1 行 D5 `step_01` 本机准出 ✅；[L-α] 专项基础设施项保持 ⚠️ 待代码实现，不阻塞 W1 骨架验收。

---

## 八、MinIO 真连通 smoke test（2026-05-21）

**命令**：`docker compose -f deploy/docker-compose/super-evo-infra.yml up -d && python3 smoke`

**输出**：

```
health: {"ok": true, "bucket": "super-evo-smoke", "endpoint": "http://localhost:9000"}
upload OK -> s3://super-evo-smoke/smoke/test_20260521.txt
download OK -> diting-minio-smoke-2026-05-21
list OK -> ['smoke/test_20260521.txt']

✅ MinIO read/write smoke test 通过
```

**结论**：MinIO `localhost:9000` 连通；bucket 自动创建；write→read→list 全链路验证通过。

---

## 八、引用

- L3 设计：[step_01_环境与基础设施.md](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_01_环境与基础设施.md)
- DNA：[dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/05_super_evo/dna_stage_1_启动期.yaml)
- 代码 PR：（待创建）
