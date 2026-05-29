# Step 02 · C1 Teacher LLM 蒸馏器（Claude-3.5-Sonnet / DeepSeek-R1 / GPT-4o → JSONL）★M1（v3 中间道细化版）

## §1 一句话定位与本步交付物

**一句话**：实现 **C1 Teacher Distiller** —— 用 **Claude-3.5-Sonnet（首选）/ DeepSeek-R1 / GPT-4o** 作 Teacher，按 **3 个维度（D1 cryo_guard / D2 deep_strike / D3 holding_watch）** 的 prompt 模板生成结构化训练数据（alpaca JSONL：`instruction / input / output / metadata`），落 **MinIO `super-evo/distill/{dim}/v{YYYYMMDD}.jsonl`** + **DVC 版本化**；启动期 **≥ 500 条/天**（3 dim 各 ≥ 100）；schema 校验 ≥ 98%；为 step_03 标注 + step_04 训练备齐原料。**本步即为 ★M1**（Teacher 蒸馏可用）；D1 step_03 通过调用本步的 `/api/distill/*` HTTP 接口启动。

**交付物**（勾选 = 完成）：

- [ ] **A**（`TeacherClient` 抽象基类 + 3 个适配器）：`apps/super_evo/teacher/{base,anthropic_client,openai_client,deepseek_client}.py`；Anthropic SDK / OpenAI SDK / DeepSeek API 各一；`tenacity` 重试（指数退避 5 次）；token 计数 + cost 估算
- [ ] **B**（`Distiller` 编排）：`apps/super_evo/teacher/distiller.py`，含 `distill_one(dim, seed)` / `distill_batch(dim, n, concurrency=5)` async；并发用 `asyncio.Semaphore`；速率限制按 provider 文档
- [ ] **C**（Prompt 模板 yaml）：`training/configs/teacher_prompts/{cryo_v1.yaml, thrust_v1.yaml, narrative_v1.yaml}`，每份含 system / instruction_template / few_shot_examples / output_schema / metadata（`prompt_template_id` 必含，便于版本回滚）
- [ ] **D**（JSONL writer + dedup）：`apps/super_evo/teacher/jsonl_writer.py`；按日切文件 `super-evo/distill/{dim}/v{YYYYMMDD}.jsonl`；以 `md5(instruction+input)` 去重；同日重跑 **append + dedup**
- [ ] **E**（DVC pipeline）：`training/dvc.yaml` 含 `distill-cryo / distill-thrust / distill-narrative` 3 stage；每 stage `outs: [super-evo/distill/{dim}/]`；`make evo-step02-dvc-push` 一键 add + push
- [ ] **F**（吞吐 / 成本 API）：`POST /api/distill/{dim}/run`（body: `{n, seed_source}`）+ `GET /api/distill/stats?dim=&date=` + `GET /api/distill/recent?dim=&limit=10`
- [ ] **G**（ORM `distill_runs`）：`db/models.py` 加表 `distill_runs(id, dim, run_id UNIQUE, n, success, fail, latency_ms_p95, cost_usd, prompt_template_id, started_at, finished_at)`；alembic migration
- [ ] **H**（JSONL schema 校验）：`apps/super_evo/quality/jsonl_validator.py`，使用 `jsonschema` 模块，模板见 §7.2.1；校验通过率 ≥ 98%；失败条进 `dlq/distill/{dim}/{YYYYMMDD}.jsonl`
- [ ] **I**（吞吐看板）：WandB project `diting-super-evo` 每 batch log `{dim, n_success, n_fail, p95_latency_ms, cost_usd}`
- [ ] **J**（单测）：`tests/super_evo/test_distiller.py / test_jsonl_validator.py / test_teacher_clients.py`，**≥ 10 用例**
- [ ] **K**（Makefile 合约）：`evo-step02-prep/distill-once/distill-day/dvc-push/stats/test/all/status/clean`

> **永久规则**：**禁止**伪造 Teacher 输出 —— 无 API key 时**显式失败**（不写假数据进 JSONL，不写假数据进 MinIO）；`tests/` 内可用 mock 客户端做单测（合法），但**禁止** mock 客户端进入 `apps/` 业务路径。`rg "TeacherClient.*fake\|mock_distill\|stub_response" apps/super_evo/` 必须为 0。

> **★M1 含义**：本步完成即为节奏表 §5 的 **M1 节点**（Teacher 蒸馏可用），是 D1 step_03 / D5 step_04 的入口；M1 卡 → M2 / M5 / M3 链条都将承压。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[../01_实践目标与策略.md](../01_实践目标与策略.md) C1、[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §三 Teacher
> - **DNA**：[`_System_DNA/05_super_evo/dna_stage_1_启动期.yaml`](../../../../_System_DNA/05_super_evo/dna_stage_1_启动期.yaml) `components[0].C1`（throughput ≥ 500/day；JSONL schema）
> - **共享规约**：[14_六维度启动期统一节奏表](../../../../_共享规约/14_六维度启动期统一节奏表.md) §8 no-mock + §5 M1 锚点
> - **L4**：[实践记录_step_02_C1_Teacher蒸馏器](../../../../../04_阶段规划与实践/05_维度五_演进飞轮/stage_1_启动期/实践记录_step_02_C1_Teacher蒸馏器.md) — 含 M1 ✅ 标记
> - **上游 step**：step_01（MinIO/DVC/WandB 基座）
> - **下游 step**：step_03（C2 Label Studio，标注本步产出 JSONL）/ step_04（C3 LLaMA-Factory，verified JSONL 训 LoRA）/ D1 step_03（cryo_guard Teacher 蒸馏，HTTP 调本步 `/api/distill/cryo_guard/run`）

## §3 数据采集对象与落库映射

### §3.1 输入 / 输出 / 落库（按 3 维度）

| 维度 | 输入（seed_source）| 调用 Teacher 模式 | 输出 JSONL 位置 | 启动期目标条数/天 |
|---|---|---|---|---|
| `cryo_guard` | D1 step_02 产出的 `announcements.content` + `related_party_raw.raw_text` + `financial_reports` 4 标的 × 4 类 | system + instruction "判断是否构成造假/掏空/关联交易/承诺违约" + few-shot 3 例 | `super-evo/distill/cryo_guard/v{YYYYMMDD}.jsonl` | ≥ 200 条 |
| `deep_strike` | D2 step_02 产出的同源（启动期共表）| system + instruction "构造五段证据链 thesis / catalyst / valuation / risk / exit" | `super-evo/distill/deep_strike/v{YYYYMMDD}.jsonl` | ≥ 150 条 |
| `holding_watch` | D3 step_02~03 产出的 P1/P2/P3/P4 探针快照 + 持仓 SoT | system + instruction "判断 narrative 与最新事件的一致性（NLI 蕴含/中立/矛盾）" | `super-evo/distill/holding_watch/v{YYYYMMDD}.jsonl` | ≥ 150 条 |

**累计启动期门槛**：3 dim 合计 ≥ 500 条/天（dim 内分布不可空）。

### §3.2 JSONL schema（4 顶级 · jsonschema 严格模式）

| 顶级字段 | 类型 | 必填 | 含义 |
|---|---|---|---|
| `instruction` | string | ✅ | 任务指令（中文，按 prompt template）|
| `input` | string | ✅ | 上下文输入（财报片段 / 公告 / 探针快照原文） |
| `output` | string | ✅ | Teacher 生成的结构化答案（含 `{"verdict": ..., "evidence": [...], "confidence": 0.XX}` JSON）|
| `metadata` | object | ✅ | 见下 |

**metadata 子字段**：

| 字段 | 类型 | 必填 | 含义 |
|---|---|---|---|
| `dim` | enum {cryo_guard, deep_strike, holding_watch} | ✅ | 维度 |
| `prompt_template_id` | string (`{dim}_v{N}`) | ✅ | 模板版本（如 `cryo_v1`）|
| `teacher_model` | string | ✅ | `claude-3-5-sonnet-20241022` / `gpt-4o-2024-08-06` / `deepseek-r1` |
| `created_at` | ISO ts | ✅ | UTC 时间戳 |
| `seed_id` | string | ⚠️ | 输入 seed 来源 ID（announcement_id / report_id / probe_snapshot_id）|
| `input_hash` | string (md5) | ✅ | 用于 dedup |
| `cost_usd` | float | ⚠️ | 本次调用估算成本 |
| `latency_ms` | int | ⚠️ | 本次调用耗时 |

### §3.3 ORM `distill_runs` 表

| 列 | 类型 | 约束 | 用途 |
|---|---|---|---|
| id | INTEGER | PK | — |
| run_id | VARCHAR(64) | NOT NULL UNIQUE（uuid）| 本次 batch 运行标识 |
| dim | VARCHAR(32) | NOT NULL | cryo_guard / deep_strike / holding_watch |
| n | INTEGER | NOT NULL | 本次 batch 目标条数 |
| success | INTEGER | NOT NULL | 成功生成数 |
| fail | INTEGER | NOT NULL | 失败数（含 schema 校验失败、API error）|
| latency_ms_p95 | INTEGER | NULL | 单条 p95 |
| cost_usd | NUMERIC(10,4) | NULL | 总成本 |
| prompt_template_id | VARCHAR(32) | NOT NULL | 模板版本 |
| teacher_model | VARCHAR(64) | NOT NULL | 模型名 |
| started_at / finished_at | DATETIME | — | — |
| INDEX(dim, started_at DESC) | | `ix_dim_time` | stats 查询 |

## §3.5 数据质量验收矩阵

### §3.5.1 schema 与内容

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| S1 | **JSONL 4 顶级齐** | instruction/input/output/metadata 必填 | ✅ jsonschema | 缺字段 → 丢弃 + dlq |
| S2 | **维度标签合法** | metadata.dim ∈ 3 枚举 | ✅ | 误标 → 丢弃 |
| S3 | **output 长度** | ≥ 50 字 / ≤ 3000 字 | ✅ | 极端长度标 outlier 但不丢 |
| S4 | **重复率** | 同 dim 同 input_hash 重复 ≤ 5% | ✅ md5 set | > 5% → 触发重采（增多样 seed）|
| S5 | **prompt_template_id 留痕** | 每条可回溯到模板版本 | ✅ | — |
| S6 | **output 含可解析 JSON** | output 字符串内可被 `json.loads` 出含 verdict/evidence/confidence | ✅ ≥ 95% | < 95% → 改 prompt 强约束 |
| S7 | **input_hash 唯一性** | md5(instruction + input) 同日内同 dim 唯一 | ✅ | dedup |

### §3.5.2 吞吐与成本

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| T1 | **日吞吐** | ≥ 500 条/天（3 dim 加总）；每 dim ≥ 100 | ⚠️ 依赖 API 额度 | < 500 → ADR + 调 §12 |
| T2 | **成功率** | ≥ 95% | ✅ tenacity 重试 5 次 | < 95% 写 `distill_runs.fail` 与日志 |
| T3 | **成本可观测** | distill_runs.cost_usd 累计；WandB log | ✅ | — |
| T4 | **并发** | 启动期 5~10 并发；遇 429 退避 | ✅ Semaphore + retry | — |
| T5 | **latency p95** | 单条 < 30s（含 prompt+生成 4000 token）| ✅ | > 30s 写 ADR |

### §3.5.3 工程 no-mock

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| E1 | **真 Teacher 调用** | 无 key → 显式 `raise EnvironmentError("ANTHROPIC_API_KEY missing")`；不写假数据 | ✅ runtime guard |
| E2 | **DVC 版本可回滚** | 每日 `dvc add ... && dvc push -r minio` | ✅ |
| E3 | **MinIO 路径规范** | `super-evo/distill/{dim}/v{YYYYMMDD}.jsonl` 严格 | ✅ |
| E4 | **重跑幂等** | 同日重跑 append 到当日文件 + dedup（input_hash 全局集合） | ✅ |
| E5 | **mock 边界** | `tests/` 可用 `FakeTeacherClient` 跑单测；**禁止**该类在 `apps/` 中 import | ✅ `rg "FakeTeacherClient" apps/` = 0 |
| E6 | **DLQ 处理** | schema fail 的条目进 `dlq/distill/{dim}/{YYYYMMDD}.jsonl`；不静默丢弃 | ✅ |

**共 18 项**。逐项验证命令见 §9。

## §4 凭证清单与环境模板

### §4.1 凭证

| 凭证 | 用途 | 何时必填 | 写在哪 |
|---|---|---|---|
| `ANTHROPIC_API_KEY`（首选）| Claude-3.5-Sonnet 调用 | 本步执行前 | `.env` |
| `OPENAI_API_KEY`（备选）| GPT-4o 调用 | 同上 | `.env` |
| `DEEPSEEK_API_KEY`（备选）| DeepSeek-R1 调用 | 同上 | `.env` |
| `SUPER_EVO_TEACHER_PROVIDER` | 选 `anthropic / openai / deepseek` | 默认 `anthropic` | `.env` |
| `SUPER_EVO_TEACHER_MODEL` | 具体型号 | 默认 `claude-3-5-sonnet-20241022` | `.env` |
| `SUPER_EVO_DISTILL_CONCURRENCY` | 并发数 | 默认 5 | `.env` |
| `SUPER_EVO_DISTILL_DAILY_TARGET` | 当日总目标 | 默认 500 | `.env` |
| MinIO/WandB | 沿用 step_01 | 已就绪 | — |

> **三选一即可**（启动期至少配 1 家）；若全空则本步显式失败（`Distiller.__init__` 抛 `EnvironmentError`）。

### §4.2 `.env.template` 增补

```text
SUPER_EVO_TEACHER_PROVIDER=anthropic    # anthropic | openai | deepseek
SUPER_EVO_TEACHER_MODEL=claude-3-5-sonnet-20241022
SUPER_EVO_DISTILL_CONCURRENCY=5
SUPER_EVO_DISTILL_DAILY_TARGET=500
SUPER_EVO_DISTILL_RETRY_MAX=5
SUPER_EVO_DISTILL_RETRY_BACKOFF=2.0     # 指数退避基数（秒）
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
DEEPSEEK_API_KEY=
```

## §5 启动期目标

| 指标 | 启动期门槛 | 测量 |
|---|---|---|
| 日吞吐 | ≥ 500 条/天，3 dim 各 ≥ 100 | `make evo-step02-stats` |
| schema 校验通过率 | ≥ 98% | jsonl_validator 统计 |
| 重复率 | ≤ 5% | md5 dedup |
| latency p95 | < 30s/条 | `distill_runs.latency_ms_p95` |
| 成本 | 启动期 ≤ ¥50/天（Anthropic 估算）| WandB log |
| 单测 | ≥ 10 passed | pytest |
| no-mock 审计 | `rg "FakeTeacher" apps/` = 0 | rg |

## §6 下一步

本步 ✅（即为 **★M1**）→ **step_03 C2 Label Studio**（人工 verify 本步产出 JSONL）+ **D1 step_03**（cryo_guard 调用 `/api/distill/cryo_guard/run`）。

## §7 实施规划（中间道）

### §7.1 实现要点

| # | 要点 | 位置 | 输入 | 核心逻辑 | 关键字段 / 输出 | 错误处理 | 验证 |
|---|---|---|---|---|---|---|---|
| 1 | **TeacherClient 基类** | `teacher/base.py` | settings | abstract `agenerate(prompt: str, max_tokens: int) -> dict`；含 `provider / model / estimate_cost(in, out)` | TeacherResponse dataclass | — | `test_teacher_clients_abstract` |
| 2 | **AnthropicClient** | `teacher/anthropic_client.py` | anthropic SDK | `messages.create`；解析 `content[0].text + usage.input_tokens/output_tokens`；cost=in*3$/1M + out*15$/1M | `agenerate()` 返 `{text, cost_usd, tokens, latency_ms}` | 429/5xx → tenacity 退避 5 次 | mock client 单测 |
| 3 | **DeepSeekClient / OpenAIClient** | `teacher/{deepseek,openai}_client.py` | 对应 SDK | OpenAI 兼容 API；同基类 | 同上 | 同上 | 同上 |
| 4 | **Prompt 模板加载** | `teacher/prompt_loader.py` | yaml 文件 | `load(dim) -> PromptTemplate`；含 `system / instruction_tpl / few_shot / output_schema` | 3 个 yaml | 缺 yaml raise | `test_prompt_loader_all_three_dims` |
| 5 | **Distiller** | `teacher/distiller.py` | dim + seeds + n | `distill_one(seed) -> dict`：拼 prompt → client.agenerate → 解析 output JSON → 组装 JSONL row；`distill_batch(dim, seeds, n)`：Semaphore(concurrency) + asyncio.gather | 单 dict / list[dict] | 单条失败入 dlq；整批 fail > 50% raise | `test_distiller_single / test_distiller_batch_concurrency` |
| 6 | **JsonlValidator** | `quality/jsonl_validator.py` | dict 列 | jsonschema 校验（schema 定义 §3.2）；返 `(ok_list, bad_list)` | 2 list | bad → dlq | `test_validator_schema` |
| 7 | **JsonlWriter + dedup** | `teacher/jsonl_writer.py` | (dim, rows) | 按日切文件名 `super-evo/distill/{dim}/v{YYYYMMDD}.jsonl`；以 md5(instruction+input) 维护全局集合（每次启动从 MinIO 加载当日已有 hash）；append-only | MinIO 对象更新 | hash 冲突 → 跳过 | `test_writer_idempotent_append` |
| 8 | **DVC pipeline yaml** | `training/dvc.yaml` | — | 3 stage：`distill-cryo / distill-thrust / distill-narrative`；`cmd: python -m apps.super_evo.teacher.distiller {dim}`；`outs: [super-evo/distill/{dim}/]` | dvc.yaml | `dvc repro distill-cryo` | `dvc repro --dry` |
| 9 | **API routes** | `api/routes/distill.py` | — | `POST /api/distill/{dim}/run` → 异步 BackgroundTask；返回 run_id；`GET /stats` → 聚合 distill_runs | 3 endpoint | 不存在 dim → 422 | `test_api_run_returns_run_id` |
| 10 | **ORM distill_runs + migration** | `db/models.py` + alembic | — | 见 §3.3 schema | 1 表 + index | — | `alembic upgrade head` |
| 11 | **WandB log** | `quality/wandb_client.py`（沿用 step_01） | batch 结果 | 每 batch `run.log({n_success, n_fail, p95, cost})` | — | offline 时本地 | — |
| 12 | **单测 ≥ 10** | `tests/super_evo/test_*.py` | conftest | client mock / validator / writer dedup / distiller batch / api / cost | 10+ 用例 | — | `pytest -q` |
| 13 | **Makefile** | `diting-src/Makefile` | env | 9 target | `.PHONY` | — | `make -n evo-step02-all` |

### §7.2 关键代码片段（中间道）

#### 7.2.1 JSONL schema 定义（jsonschema · §3.2 落地）

```python
DISTILL_JSONL_SCHEMA = {
    "type": "object",
    "required": ["instruction", "input", "output", "metadata"],
    "properties": {
        "instruction": {"type": "string", "minLength": 1},
        "input": {"type": "string"},
        "output": {"type": "string", "minLength": 50, "maxLength": 3000},
        "metadata": {
            "type": "object",
            "required": ["dim", "prompt_template_id", "teacher_model",
                         "created_at", "input_hash"],
            "properties": {
                "dim": {"enum": ["cryo_guard","deep_strike","holding_watch"]},
                "prompt_template_id": {"pattern": "^[a-z_]+_v\\d+$"},
                "teacher_model": {"type": "string", "minLength": 1},
                "created_at": {"type": "string", "format": "date-time"},
                "input_hash": {"type": "string", "pattern": "^[a-f0-9]{32}$"},
                "cost_usd": {"type": "number", "minimum": 0},
                "latency_ms": {"type": "integer", "minimum": 0},
            },
        },
    },
}
```

#### 7.2.2 TeacherClient with tenacity 重试（核心算法 ~18 行）

```python
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

class AnthropicClient(TeacherClient):
    @retry(
        stop=stop_after_attempt(5),
        wait=wait_exponential(multiplier=2, min=2, max=60),
        retry=retry_if_exception_type((RateLimitError, APIError, APITimeoutError)),
        reraise=True,
    )
    async def agenerate(self, prompt: str, max_tokens: int = 4000) -> TeacherResponse:
        t0 = time.perf_counter()
        resp = await self._client.messages.create(
            model=self.model, max_tokens=max_tokens,
            messages=[{"role": "user", "content": prompt}],
        )
        text = resp.content[0].text
        in_tok, out_tok = resp.usage.input_tokens, resp.usage.output_tokens
        cost = in_tok * 3.0 / 1e6 + out_tok * 15.0 / 1e6  # USD
        return TeacherResponse(
            text=text, cost_usd=cost, in_tokens=in_tok, out_tokens=out_tok,
            latency_ms=int((time.perf_counter() - t0) * 1000),
        )
```

#### 7.2.3 distill_one 关键算法（核心 ~20 行）

```python
async def distill_one(self, dim: str, seed: SeedInput) -> Optional[dict]:
    tpl = self.prompt_loader.load(dim)
    prompt = tpl.render(seed=seed)
    try:
        resp = await self.client.agenerate(prompt, max_tokens=4000)
    except Exception as e:
        log.warning("teacher call fail seed=%s err=%s", seed.id, e)
        return None
    row = {
        "instruction": tpl.instruction_tpl.format(**seed.fields),
        "input": seed.input_text,
        "output": resp.text,
        "metadata": {
            "dim": dim, "prompt_template_id": tpl.id,
            "teacher_model": self.client.model,
            "created_at": datetime.utcnow().isoformat(),
            "input_hash": hashlib.md5(
                (tpl.instruction_tpl + seed.input_text).encode("utf-8")
            ).hexdigest(),
            "cost_usd": resp.cost_usd, "latency_ms": resp.latency_ms,
            "seed_id": seed.id,
        },
    }
    return row
```

#### 7.2.4 JSONL append + dedup（核心 ~15 行）

```python
async def append_to_daily(self, dim: str, rows: list[dict]) -> int:
    """Append rows to MinIO 'super-evo/distill/{dim}/v{YYYYMMDD}.jsonl', dedup by input_hash."""
    today = datetime.utcnow().strftime("%Y%m%d")
    key = f"distill/{dim}/v{today}.jsonl"
    # 1) load existing hashes (read-modify-write tolerable for 1 file/day)
    existing_hashes = await self._load_existing_hashes(key)  # set[str]
    # 2) filter
    fresh = [r for r in rows if r["metadata"]["input_hash"] not in existing_hashes]
    if not fresh:
        return 0
    # 3) append-write back to MinIO (read full + concat + put)
    body = await self._read_or_empty(key)
    body += b"\n".join(json.dumps(r, ensure_ascii=False).encode() for r in fresh) + b"\n"
    await self.minio.put_object(Bucket=self.bucket, Key=key, Body=body)
    return len(fresh)
```

#### 7.2.5 `/api/distill/{dim}/run` API 契约

```http
POST /api/distill/cryo_guard/run
Content-Type: application/json

{ "n": 50, "seed_source": "d1_announcements_2024_q4", "concurrency": 5 }

→ 202 Accepted
{ "run_id": "abc123", "dim": "cryo_guard", "n": 50, "status": "running",
  "stats_url": "/api/distill/stats?dim=cryo_guard&run_id=abc123" }
```

`POST` 立即返回 `run_id` 不阻塞；BackgroundTask 完成后写入 `distill_runs`；查询用 `GET /api/distill/stats?dim=cryo_guard&date=20260520`。

#### 7.2.6 DVC pipeline 片段

```yaml
# training/dvc.yaml
stages:
  distill-cryo:
    cmd: python -m apps.super_evo.teacher.distiller --dim cryo_guard --n 200
    outs:
      - super-evo/distill/cryo_guard/   # MinIO 远端路径（via dvc remote）
    desc: "Daily distill batch for cryo_guard"
  distill-thrust:
    cmd: python -m apps.super_evo.teacher.distiller --dim deep_strike --n 150
    outs:
      - super-evo/distill/deep_strike/
  distill-narrative:
    cmd: python -m apps.super_evo.teacher.distiller --dim holding_watch --n 150
    outs:
      - super-evo/distill/holding_watch/
```

### §7.3 Makefile 合约

| target | 用途 | 入参（env） | 验证 |
|---|---|---|---|
| `evo-step02-prep` | 校验 Teacher key（≥ 1 家）+ MinIO ok + ORM 表 distill_runs | `SUPER_EVO_TEACHER_PROVIDER`、key | `key ok ✅ \| table created ✅` |
| `evo-step02-distill-once` | 单条蒸馏（dim=cryo_guard，n=1）+ schema 校验 + MinIO append | — | `1 row written, schema ok ✅` |
| `evo-step02-distill-day` | 3 dim 各跑目标条数；DVC add+push | `SUPER_EVO_DISTILL_DAILY_TARGET` | `cryo=200 thrust=150 narrative=150 ✅` |
| `evo-step02-dvc-push` | `dvc repro distill-* && dvc push -r minio` | — | `pushed N MB ✅` |
| `evo-step02-stats` | 查 distill_runs 当日聚合：吞吐 / 成本 / 重复率 | — | 表格输出（dim/success/cost/dedup_rate）|
| `evo-step02-test` | `pytest tests/super_evo/test_distiller* tests/super_evo/test_jsonl_validator.py` | — | `≥ 10 passed ✅` |
| `evo-step02-all` | prep → distill-once → distill-day → dvc-push → stats → test | — | 6 段全绿 |
| `evo-step02-status` | 当日 + 近 7 日吞吐 | — | 表格 |
| `evo-step02-clean` | `FORCE=1` 时清当日 jsonl 与 distill_runs 当日行 | `FORCE` | `cleaned ✅` |

**合约要求**：
1. 配置驱动：`SUPER_EVO_TEACHER_PROVIDER=deepseek` 切换不改 Makefile；
2. 可重入：`distill-day` 第二次跑同日仅补差（已有 hash 跳过）；
3. 失败可观察：每 target 3 行中文摘要（做了什么/期望/实际）；
4. `dvc-push` 与 `distill-day` 解耦（push 可单独跑）。

### §7.4 给后续执行模型的指引

1. **顺序刚性**：prompt 模板 3 份（先 cryo_v1） → AnthropicClient → JsonlValidator → JsonlWriter → Distiller → DVC pipeline → API → ORM → 单测 → Makefile；
2. **不嵌入完整模块代码**：§7.2 给关键算法 10~20 行/片段；具体 docstring / metric / 日志 / few-shot 例子由 L4 实践记录回写；
3. **L4 回写内容**：
   - 实际 provider / model 与 key 残留 4 位掩码；
   - 当日 3 dim 实际条数 + 成本 USD + p95 latency；
   - DVC push 后的 `dvc.lock` md5；
   - WandB run id；
4. **永久规则审计**：
   ```bash
   rg "FakeTeacherClient|mock_distill|stub_response" apps/super_evo/   # 0 命中
   ```
5. **M1 完成宣告**：本步准出后须在 14_节奏表 §9.2 把 M1 标 ✅ 并加 L4 链接。

## §8 部署节奏

本步**仅本机** uvicorn + docker compose（沿用 step_01 起的 minio + redis）；step_07 灰度时 super-evo Pod 进 dev K3s。

## §9 准出标准

### §9.1 数据量

| 项 | 启动期门槛 | 测量 |
|---|---|---|
| `super-evo/distill/cryo_guard/v{今天}.jsonl` 行数 | ≥ 200 | `mc cat ... \| wc -l` |
| `super-evo/distill/deep_strike/v{今天}.jsonl` | ≥ 150 | 同上 |
| `super-evo/distill/holding_watch/v{今天}.jsonl` | ≥ 150 | 同上 |
| `distill_runs` 当日 | ≥ 3 行（3 dim 各 1 batch）| sqlite count |

### §9.2 数据质量（§3.5 18 项必须全绿）

```bash
# 1) 准备 key
[ -n "$ANTHROPIC_API_KEY" ] || [ -n "$OPENAI_API_KEY" ] || [ -n "$DEEPSEEK_API_KEY" ] \
  || { echo "no teacher key"; exit 1; }

# 2) 单条 distill smoke
make evo-step02-distill-once
mc cat local/super-evo/distill/cryo_guard/v$(date -u +%Y%m%d).jsonl | head -1 | jq '.metadata'

# 3) 一天全量（启动期 500 条）
make evo-step02-distill-day
mc cat local/super-evo/distill/cryo_guard/v$(date -u +%Y%m%d).jsonl | wc -l    # ≥ 200

# 4) Schema 校验通过率
python -m apps.super_evo.quality.jsonl_validator \
  --bucket super-evo --prefix distill/ --date $(date -u +%Y%m%d)
# 期望 stdout: pass_rate=98.x%

# 5) 重复率
python -c "
import json, hashlib, collections
hashes = collections.Counter()
for fp in ['cryo_guard','deep_strike','holding_watch']:
    # ... 读 mc cat 输出
    pass
print('dup_rate=', sum(c-1 for c in hashes.values() if c > 1) / sum(hashes.values()))
"   # 期望 < 0.05

# 6) DVC push
make evo-step02-dvc-push
dvc status -r minio    # 期望 Pipelines are up to date

# 7) 单测
pytest tests/super_evo/test_distiller.py tests/super_evo/test_jsonl_validator.py -q
# 期望 ≥ 10 passed

# 8) 永久规则审计
rg "FakeTeacherClient|mock_distill|stub_response" apps/super_evo/    # 0

# 9) Makefile
make evo-step02-all
make evo-step02-stats
```

### §9.3 准出确认

- [ ] §9.2 全部 9 条命令本机跑通 ✅
- [ ] §3.5 18 项全绿
- [ ] L4 回写：实际 provider / 当日 3 dim 条数 / cost_usd / dvc.lock md5 / WandB run id
- [ ] **14_节奏表 §9.2 M1 标 ✅** + 链接 L4
- [ ] 通知 step_03 / D1 step_03 / D5 step_04 owner

## §10 [Deploy]

ConfigMap 增 `SUPER_EVO_TEACHER_PROVIDER`、`SUPER_EVO_TEACHER_MODEL`、`SUPER_EVO_DISTILL_DAILY_TARGET`；上 K3s 时 Anthropic key 走 Secret。

## §11 依赖与禁忌

| 类型 | 依赖项 | 当前 | 缺失时 |
|---|---|---|---|
| 硬上游 | step_01 完成（MinIO/DVC/WandB 基座）| ✅ | 回 step_01 |
| 硬上游 | ≥ 1 家 Teacher API key | 用户提供 | 阻塞（不写假数据）|
| 软上游 | D1/D2/D3 step_02 已有 seed 数据 | 启动期 D1 W1-W3 同步进行 | 启动期可用人工整理的少量 seed 起步，但**不**伪造业务数据 |
| 资源 | Anthropic 额度 ~$50/月覆盖 500 条/天 | 用户 | 切 DeepSeek 降本 |

**严禁**：
- 缺 key 时 falling back 到 hardcoded 字符串（必须 raise）；
- 把 `FakeTeacherClient` 写进 `apps/super_evo/teacher/` 业务路径；
- 同一 input_hash 多次写入 MinIO 同日文件（必须 dedup）；
- 把 LoRA `.safetensors` 提交 git（沿用 step_01 永久规则）。

### §11.4 [Lighthouse-Alpha] 未来扩展：ETL LLM Engine 输出回流为蒸馏样本

step_01 §3.1 已新建 ETL LLM Engine 基础设施（Qwen-14B vLLM + Kafka + ClickHouse + ES）；待 ETL Engine 正式运行后（GPU 节点就绪），其抽取的结构化样本（招标实体/事件链/海外科技映射）**可作为 C1 Teacher 蒸馏的扩充语料来源**——具体路径：

1. ETL 抽取结果（ClickHouse `tender_extracted / event_chain_extracted / overseas_mapping_extracted`）→ 作为 `seed_source` 候选喂给 C1 Distiller；
2. C1 Teacher 用 Claude / GPT-4o 对 ETL 结果做"高质量解读 → JSONL 训练样本"二次蒸馏；
3. 训练样本沉淀回 MinIO `super-evo/distill/{dim}/v{date}.jsonl`，进入正常 step_03~04 标注 + LoRA 训练流水线；
4. 形成"D2 嗅探原文 → ETL 结构化 → C1 二次蒸馏 → LoRA 训练 → 推理改进 → D2 嗅探更精准"的**数据自我进化闭环**——这也正是 D5 维度作为"演进飞轮"的根本定义。

**本 step 不实现此流程**（属于扩展期或完善期工作）；本节仅为前瞻提示，对应：
- DNA：`_System_DNA/05_super_evo/etl_llm_engine.yaml`（待新增）含 `feedback_to_teacher: enabled=true/false` 开关，启动期默认 false；
- L4 实践记录：本节信息**不**回填到当前 stage_1 实践记录，**待**触发 ETL 输出回流时由扩展期 step 文档承接。

## §12 风险与回退

| 触发 | 影响 | 应对 | 重试上限 |
|---|---|---|---|
| Anthropic 额度耗尽 | < 500 条/天 | 切 DeepSeek（成本 ~1/10）；ADR 写明 | — |
| 429 频发 | latency p95 > 30s | 降并发到 3；调 `SUPER_EVO_DISTILL_RETRY_BACKOFF=4.0` | 2 次 |
| schema 通过率 < 98% | 数据可用性 | 增 prompt 严格度（system message 显式要求 JSON 格式）；改 max_tokens；启用 JSON mode（OpenAI / DeepSeek 支持）| 3 次 |
| 重复率 > 5% | 训练数据多样性差 | 扩 seed 池（D1/D2/D3 多采集）；prompt 加 `temperature=0.7` | — |
| DVC push 慢 | 上传卡 | MinIO 本机即可 < 1s；远端时切 `dvc push --jobs 4` | — |
| 同问题 > 2 次 | 阻塞 | §8.4f 回退 |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v3.1 Lighthouse-Alpha 前瞻提示**：merge_inplace 在 §11 严禁段后追加 §11.4「未来扩展：ETL LLM Engine 输出回流为蒸馏样本」（1~2 段轻量描述，不实现）；说明 step_01 已新建的 ETL 基础设施（Qwen-14B/Kafka/CH/ES）输出将来如何回流为 C1 蒸馏样本，形成数据自我进化闭环；明确本步**不实现**该流程，由扩展期 step 承接 |
| 2026-05-21 | **v3 中间道细化**：保留 v1.2 §3.5/Makefile/no-mock 三件套；新增 §3.1 3 维度输入/输出/落库详表、§3.2 JSONL schema 详表（含 metadata 8 子字段）、§3.3 distill_runs ORM、§4.1/4.2 凭证三选一与 .env 模板、§7.2.1~7.2.6 关键代码片段（JSONL schema/tenacity 重试/distill_one/dedup/API 契约/dvc.yaml）；§3.5 从 13 项扩到 18 项；§9 从 2 行扩到 9 条逐项命令；157→~600 行；**标记 ★M1 节点完成宣告流程** |
| 2026-05-20 | v2 按 L3 v1.2 重写：删 1258 行嵌入 Python；§3.5 13 项；no-mock；1258→~150 行 |
| 2026-05-16 | 初版 1258 行 |
