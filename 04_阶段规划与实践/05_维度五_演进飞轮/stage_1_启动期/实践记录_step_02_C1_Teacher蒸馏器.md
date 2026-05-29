# 实践记录 · 维度五·演进飞轮 · step_02 · C1 Teacher 蒸馏器

> [!NOTE] **[TRACEBACK] 实践锚点**
> - **L3 步骤**：[step_02_C1_Teacher蒸馏器.md](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_02_C1_Teacher蒸馏器.md)
> - **DNA**：[_System_DNA/05_super_evo/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/05_super_evo/dna_stage_1_启动期.yaml)（`deliverables.components[C1]`）
> - **硬节点 M1**：[14_六维度启动期统一节奏表 §三](../../../03_原子目标与规约/_共享规约/14_六维度启动期统一节奏表.md)

---

## 一、本步计划（来自 L3）

- 落地 `TeacherDistiller`：Claude API（可 dry_run）、令牌桶限流、指数退避重试、JSONL、MinIO `distilled/{task_type}/{date}/{batch}.jsonl`
- 暴露 `/api/distill/health|single|batch`
- 准出：`pytest tests/super_evo/test_teacher_distiller.py` ≥10 用例；吞吐契约在 dry_run 下以批量与时延自检

---

## 二、实际进展

| §3 子步骤 | 状态 | 说明 |
|---|---|---|
| 3.1 schemas | ✅ | `teacher/schemas.py` |
| 3.2 prompts | ✅ | `base` / `financial_fraud` / `shareholder` / `related_party` + `REGISTRY` |
| 3.3 rate_limiter | ✅ | `TokenBucket` + `RateLimiter` |
| 3.4 anthropic_client | ✅ | `AsyncRetrying` + dry_run + 可重试异常 |
| 3.5 distiller | ✅ | `distill_one` / `distill_batch` + MinIO 上传 |
| 3.6 api/routes/distill | ✅ | FastAPI router |
| 3.7 main 挂载 | ✅ | `include_router` |
| 3.8 pytest | ✅ | **14 passed**（含 MinIO key 格式用例） |
| 3.9 pytest-asyncio | ✅ | 已由仓库 `pyproject.toml` 配置 |
| 3.10 手工 curl | ✅ | `/api/distill/health` 返回 `dry_run: true`（无 ANTHROPIC_API_KEY） |
| 3.11 Makefile | ✅ | `test-teacher-distill` · `distill-demo` |
| 3.12 git commit | ⚠️ | 待你显式要求后再提交 |

### 补充用例（相对 L3 原文）

- `test_rate_limiter_enforces_pause_beyond_burst`：突发用尽后的匀速等待
- `test_distill_batch_five_within_sixty_seconds`：60 秒内 ≥5 条（dry_run）
- `test_distill_batch_minio_key_format`：MinIO URI 含 `distilled/financial_fraud/` 且以 `.jsonl` 结尾

---

## 三、测试运行

### 命令

```bash
cd diting-src
docker compose -f deploy/docker-compose/super-evo-infra.yml up -d
PYTHONPATH=. python3 -m pytest tests/super_evo/test_teacher_distiller.py -v
PYTHONPATH=. python3 -m uvicorn apps.super_evo.main:app --port 8090
curl -s http://127.0.0.1:8090/api/distill/health | python3 -m json.tool
docker compose -f deploy/docker-compose/super-evo-infra.yml down
```

### `/api/distill/health`（摘录）

```json
{
    "ok": true,
    "teacher_model": "claude-3-5-sonnet-latest",
    "dry_run": true
}
```

### pytest（摘录）

```
tests/super_evo/test_teacher_distiller.py::... 14 passed in ~18s
```

---

## 四、偏离与决策

| 偏离 | 原因 | 决策 |
|---|---|---|
| 未配置 `ANTHROPIC_API_KEY` | 本地联调不触发计费 | `dry_run=True`；Teacher 返回确定性 JSON；**生产前须配置 key** |
| L3 §3.9 要求写 `asyncio_mode` | 仓库已存在 `pytest-asyncio` 与 `[tool.pytest.ini_options]` | **不重复追加**，沿用现配置 |
| M1 在 14_ 表内状态 | 表格无独立「验证」列 | 在 **[14 §三](...14_六维度启动期统一节奏表.md)** 增加 **里程碑验证回填** 段落链至本文档 |

---

## 五、吞吐与 M1

- **dry_run** 下 `throughput_per_day` 会极高，**不作为真实 API 性能**；契约以：批量条数、`num_success`、JSONL 落盘、MinIO key 命名、`distill_batch` 并发=4、**60 秒内完成 ≥5 条** 自检为主。
- **M1（Teacher 蒸馏可用）**：本 step 代码 + 测试 + API 已通，视为 **M1 链路基线达成**（真 Teacher 需 key 后复验延迟与错误率）。

---

## 六、下一步

- [ ] [step_03_C2_Label_Studio部署](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_03_C2_Label_Studio部署.md)
- [ ] 配置生产 `ANTHROPIC_API_KEY` 后抽样跑通 `single`/`batch` 并记录延迟

---

## 七、W2 与节奏表

- **★M1 / W2 行** 整体验收录网：[14 · W2 行准出核验](../../../03_原子目标与规约/_共享规约/14_六维度启动期统一节奏表.md#w2-行准出核验)（本步为 D5 主责格）
- **W2 双模型拆分**：`TEACHER_MODEL=claude-sonnet-4-5` · `LIGHTHOUSE_REMOTE_MODEL=claude-opus-4-6`（`.env`）
- **W2 HTTP 真蒸馏**：`make evo-step02-http` → TestClient `/api/distill/health` + `/single` **200**，`teacher_model=claude-sonnet-4-5`，`dry_run=False`

```bash
cd diting-src
make evo-step02-all   # prep + 14p + dry_run + HTTP 冒烟
```

---

## 八、2026-05-21 W1 复验与 L3 v3 对齐（更新）

| 项 | 结果 | 证据 |
|---|---|---|
| Teacher 单测 | ✅ | `make test-teacher-distill`：`13 passed, 1 skipped` |
| `make evo-step02-all` | ✅ | W1 缺口修复：`evo-step02-test/smoke/all` 三个 target 落地；`make evo-step02-all` → MinIO infra 启动 + `14 passed` |
| W1 合并最小验证 | ✅ | 整体 `76 passed, 4 skipped` |
| dry_run 边界 | ✅ | 未配置真实 Teacher key 时仅使用 dry_run 单测，不伪造真实 LLM 输出 |
| MinIO 依赖 | ✅ | MinIO docker compose 已真实连通（见 step_01 实践记录 §八） |
| 真实 Teacher 凭证 | ⚠️ | `ANTHROPIC_API_KEY` 未配置；dry_run 基线通过，生产前须配置 key + 复验延迟/成本 |

**结论**：W1 Makefile 合约缺口已补齐；D5 step02 MinIO + Teacher 蒸馏器 dry_run 准出条件满足。真实 Teacher 凭证为后续生产准出的唯一阻塞项。

### 2026-05-22 W1 全量复验（§4 日历行 · 覆盖本步）

| 项 | 结果 | 证据（`diting-src`） |
|---|---|---|
| `make evo-step02-all` | ✅ | `14 passed`（Teacher 蒸馏器 · dry_run） |
| [L-α] ETL LLM Engine LoRA 流水线 | ⚠️ | L3 已规划 4 抽取器 + 灰度；本步 W1 仅验收 Teacher HTTP/单测，ETL 训练待 D5 step_01/02 代码扩展 |
| 真实 `ANTHROPIC_API_KEY` | ⚠️ | 未配置；不伪造 LLM 输出 |
| W1 八步合并 pytest | ✅ | 合并验证 `176 passed`（2026-05-22） |

**结论**：§4 W1 行 D5 `step_02` 本机准出 ✅（dry_run 基线）；★M1 链路基线维持；生产 Teacher + [L-α] ETL 为 W2+ 阻塞项。

---

## 九、引用

- L3：[step_02_C1_Teacher蒸馏器.md](../../../03_原子目标与规约/05_维度五_演进飞轮/stages/stage_1_启动期/steps/step_02_C1_Teacher蒸馏器.md)
- 节奏表：[14_六维度启动期统一节奏表.md](../../../03_原子目标与规约/_共享规约/14_六维度启动期统一节奏表.md)
