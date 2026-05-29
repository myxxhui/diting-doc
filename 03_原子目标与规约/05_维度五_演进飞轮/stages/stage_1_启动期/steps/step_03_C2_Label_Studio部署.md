# Step 03 · C2 Label Studio 部署（蒸馏数据人工 verified + 双盲样本 ≥10%）（v3 中间道细化版）

## §1 一句话定位与本步交付物

**一句话**：部署 **Label Studio 1.10+** 单实例（docker-compose 起，挂载 MinIO 为 S3 存储后端，PostgreSQL 持久化）；配置 **3 个维度的标注模板**（D1 财务测谎 二分类 / D2 thesis 质量 五段评分 / D3 NLI 三类蕴含）；自动导入 step_02 产出 JSONL → 按 dim 建 Project → 每个 task 注入 input + Teacher output；**10% 双盲分配**（同一 task 派给 2 名标注员，为 step_06 Kappa 校准准备）；标注完成走 webhook → 写 `labelings` 表 + 同步到 MinIO `super-evo/verified/{dim}/v{YYYYMMDD}.jsonl`；step_04 训练**仅消费 verified=true** 的样本。

**交付物**（勾选 = 完成）：

- [ ] **A**（Label Studio 部署）：`deploy/docker-compose/label-studio.yml`，含 LS 1.10+ + PG 15；持久卷 `./data/label-studio/`；admin 账号 `admin@diting / super-evo-token-dev`（启动期默认值，**线上换强密码**）；UI 端口 8082
- [ ] **B**（3 维标注模板）：`training/configs/label_studio_templates/{cryo_v1.xml, thrust_v1.xml, narrative_v1.xml}`，含双盲 hidden 字段 `is_blind_sample`；含 `reject_reason` 枚举 7 项
- [ ] **C**（导入器）：`scripts/ls_import.py --dim {cryo_guard|deep_strike|holding_watch} --date YYYYMMDD --blind-ratio 0.1`：从 MinIO 拉 `distill/{dim}/v{date}.jsonl` → md5 dedup（避免与既有 task 冲突）→ Label Studio SDK 建 Project（如已存在则 reuse）→ 上传 task（10% 标 `is_blind_sample=true` 并复制一份分给第二名标注员）
- [ ] **D**（webhook）：`POST /api/labeling/ls_webhook`；HMAC 签名校验（`SUPER_EVO_LS_WEBHOOK_SECRET`）；解析 LS 完成事件 → 写 `labelings`（task_id / dim / instruction_hash / annotation / verified / reject_reason / annotator_email / completed_at）+ 触发 MinIO sync
- [ ] **E**（导出器）：`scripts/ls_export.py --project-id N --dim X --date YYYYMMDD`：从 `labelings` 表过滤 `verified=true AND dim=X AND completed_at >= start_of_day(date)` → 输出 `super-evo/verified/{dim}/v{YYYYMMDD}.jsonl`；自动 `dvc add + dvc push`
- [ ] **F**（标注进度 API）：`GET /api/labeling/progress?dim=` 返回 `{total, in_progress, verified, rejected, blind_dual_labeled, blind_pending}`
- [ ] **G**（ORM `labelings` 表 + alembic）：见 §3.3 schema
- [ ] **H**（双盲分配机制）：导入器在 `import_tasks()` 中按 `random.sample(tasks, int(len(tasks)*blind_ratio))` 选出 N 条 → 每条复制一份（task_id 加后缀 `-b`）分给指定的第二位标注员；启动期默认两位标注员邮箱由 `.env` 配置
- [ ] **I**（单测）：`tests/super_evo/test_ls_import.py / test_ls_webhook.py / test_ls_export.py`，**≥ 8 用例**（webhook 签名/import dedup/export verified-only/blind 分配比例）
- [ ] **J**（Makefile 合约）：`evo-step03-prep/import-cryo/import-thrust/import-narrative/export/progress/test/all/status/clean`

> **永久规则**：未经人工 verified 的数据**不得**用于训练 —— step_04 LLaMA-Factory 训练数据加载器必须只读 `verified/*.jsonl`（grep `distill/.*\.jsonl` 在 `training/configs/llama_factory/` 配置中 = 0）；admin 撤销 verified 时**双向同步**（labelings + MinIO 删该行）。

> **双盲 ≥ 10%** 是 step_06 Kappa 校准的硬依赖：blind_ratio < 0.1 时 step_06 无法计算 Kappa。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[../01_实践目标与策略.md](../01_实践目标与策略.md) C2、[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §四
> - **DNA**：[`_System_DNA/05_super_evo/dna_stage_1_启动期.yaml`](../../../../_System_DNA/05_super_evo/dna_stage_1_启动期.yaml) `components[1].C2`（version 1.10+，用途 verified + Kappa 准备）
> - **共享规约**：[14_六维度启动期统一节奏表](../../../../_共享规约/14_六维度启动期统一节奏表.md) §2 凭证清单第 2/3 条（LS_* / 2 名标注员）
> - **L4**：[实践记录_step_03_C2_Label_Studio部署](../../../../../04_阶段规划与实践/05_维度五_演进飞轮/stage_1_启动期/实践记录_step_03_C2_Label_Studio部署.md)
> - **上游 step**：step_02（C1 Teacher 蒸馏 ★M1，产出 distill JSONL）
> - **下游 step**：step_04（C3 LLaMA-Factory 训练 ★M2，仅消费 verified）/ step_06（C4 双盲 Kappa 校准 ≥ 0.80）

## §3 数据采集对象与落库映射

### §3.1 流水线（distill → tasks → verified）

| 阶段 | 数据 | 位置 | 操作 |
|---|---|---|---|
| 1 蒸馏产出 | `super-evo/distill/{dim}/v{date}.jsonl` | MinIO | step_02 产出 |
| 2 导入 LS | LS Project tasks（每 dim 1 个 Project） | LS PG + S3 引用 | `ls_import.py` |
| 3 标注 | annotator 在 UI 中标注 | LS PG | 标注员 |
| 4 webhook | LS 推送完成事件 | super-evo `/api/labeling/ls_webhook` | LS → super-evo |
| 5 落库 | `labelings(verified=true/false, reject_reason, annotator)` | SQLite | super-evo |
| 6 导出 | `super-evo/verified/{dim}/v{date}.jsonl` | MinIO | `ls_export.py` |
| 7 DVC | `verified/{dim}/` 版本化 | DVC + MinIO | `dvc push` |

### §3.2 双盲样本机制

| 项 | 详情 |
|---|---|
| **触发** | 导入器按 `blind_ratio=0.1`（10%）随机选 task |
| **复制** | 同 task 创建两份：原 task_id（分给 annotator A）+ task_id+`-b`（分给 annotator B） |
| **隐藏字段** | `is_blind_sample: true`、`blind_pair_id`（指向另一份）|
| **annotator 不可见** | LS 模板 hide 该字段 |
| **完成后** | 两份独立标注 → step_06 Kappa 校准计算 |

### §3.3 ORM `labelings` 表

| 列 | 类型 | 约束 | 用途 |
|---|---|---|---|
| id | INTEGER | PK | — |
| task_id | VARCHAR(64) | NOT NULL | LS task id（含 `-b` 后缀区分双盲）|
| project_id | INTEGER | NOT NULL | LS project id |
| dim | VARCHAR(32) | NOT NULL | cryo_guard/deep_strike/holding_watch |
| instruction_hash | VARCHAR(32) | NOT NULL | md5(instruction+input)，与 step_02 distill_runs.input_hash 对齐 |
| verified | BOOLEAN | NOT NULL DEFAULT false | true=通过 / false=拒绝 |
| reject_reason | VARCHAR(64) | NULL | 枚举：`output_wrong / output_partial / instruction_unclear / input_corrupted / format_invalid / safety_violation / other` |
| annotation_payload | TEXT (JSON) | NOT NULL | LS 完整 result（含修正后的 output）|
| annotator_email | VARCHAR(128) | NOT NULL | 标注员标识 |
| is_blind_sample | BOOLEAN | NOT NULL DEFAULT false | 双盲样本标记 |
| blind_pair_id | VARCHAR(64) | NULL | 双盲配对的另一份 task_id |
| completed_at | DATETIME | NOT NULL | LS 完成时间 |
| received_at | DATETIME | NOT NULL DEFAULT NOW | webhook 接收时间 |
| INDEX(dim, verified, completed_at) | | `ix_dim_verified_time` | export 查询 |

## §3.5 数据质量验收矩阵

### §3.5.1 模板与覆盖

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| T1 | **3 维模板都到位** | cryo/thrust/narrative xml 与 D1/D2/D3 训练目标对齐 | ✅ 评审 | 缺 1 维不上线 |
| T2 | **导入幂等** | 同 instruction_hash 不重复上 task | ✅ md5 索引 | — |
| T3 | **任务量** | 每 dim 启动期 ≥ 100 待标 | ✅（依赖 step_02 ≥ 100/dim/day）| < 100 → 增蒸馏量 |
| T4 | **reject_reason 枚举完整** | 7 项可选 + "other" 必填补描述 | ✅ schema | — |
| T5 | **模板含双盲 hidden 字段** | xml 内 `is_blind_sample` + `blind_pair_id` 隐藏 | ✅ | — |

### §3.5.2 标注质量

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| Q1 | **verified 比例** | 启动期 ≥ 80% 蒸馏样本人工通过 | ⚠️ 待标完 | < 80% → 改 step_02 prompt |
| Q2 | **annotator 留痕** | webhook payload 含 annotator_email | ✅ | — |
| Q3 | **拒绝原因必填** | reject 时 reject_reason ≠ null | ✅ schema | — |
| Q4 | **双盲样本占比** | 每 dim ≥ 10% 任务双标 | ✅ 导入器分配 | < 10% → 导入器报错 |
| Q5 | **annotator 至少 2 名** | env 配置 `LS_ANNOTATOR_EMAILS` ≥ 2 邮箱 | ✅ | < 2 → step_06 Kappa 无法跑 |
| Q6 | **拒绝样本不进 verified** | export 只 filter `verified=true` | ✅ SQL | — |

### §3.5.3 同步与回滚

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| S1 | **MinIO 同步路径** | `verified/{dim}/v{YYYYMMDD}.jsonl` | ✅ | — |
| S2 | **DVC 版本** | verified jsonl 也走 DVC | ✅ | — |
| S3 | **admin 撤销回滚** | UI 撤销 → webhook 推 update 事件 → labelings.verified=false + MinIO 删该行 | ✅ | — |
| S4 | **webhook 签名校验** | HMAC-SHA256 + `SUPER_EVO_LS_WEBHOOK_SECRET` | ✅ | — |
| S5 | **重复 webhook 幂等** | 同 task_id + completed_at 重复推不重复落库 | ✅ unique key | — |

**共 16 项**。逐项验证命令见 §9。

## §4 凭证清单与环境模板

### §4.1 凭证

| 凭证 | 用途 | 默认值（启动期 dev）| 写在哪 | 是否必填 |
|---|---|---|---|---|
| `SUPER_EVO_LS_API_URL` | LS API endpoint | `http://127.0.0.1:8082` | `.env` | 必填 |
| `SUPER_EVO_LS_API_TOKEN` | LS API token（admin 账号生成）| `super-evo-token-dev` | `.env` | 必填 |
| `SUPER_EVO_LS_WEBHOOK_SECRET` | webhook HMAC 签名密钥 | `super-evo-ls-webhook-dev`（线上换强）| `.env` | 必填 |
| `SUPER_EVO_LS_ADMIN_EMAIL` | LS admin 邮箱 | `admin@diting` | `.env` | 必填 |
| `SUPER_EVO_LS_ADMIN_PASSWORD` | admin 密码 | `super-evo-admin-pass`（线上换强）| `.env` | 必填 |
| `SUPER_EVO_LS_ANNOTATOR_EMAILS` | 标注员邮箱列表（逗号分隔，≥ 2）| `ann1@diting,ann2@diting` | `.env` | **必填 ≥ 2** |
| `SUPER_EVO_LS_BLIND_RATIO` | 双盲比例 | `0.10` | `.env` | 可不填 |

> 启动期 dev 默认值可直接用本机；**线上**必须换强密码 + Annotator 实名邮箱。

### §4.2 `.env.template` 增补

```text
# ============ Label Studio (D5 step_03) ============
SUPER_EVO_LS_API_URL=http://127.0.0.1:8082
SUPER_EVO_LS_API_TOKEN=super-evo-token-dev
SUPER_EVO_LS_WEBHOOK_SECRET=super-evo-ls-webhook-dev
SUPER_EVO_LS_ADMIN_EMAIL=admin@diting
SUPER_EVO_LS_ADMIN_PASSWORD=super-evo-admin-pass
SUPER_EVO_LS_ANNOTATOR_EMAILS=ann1@diting,ann2@diting
SUPER_EVO_LS_BLIND_RATIO=0.10
```

## §5 启动期目标

| 指标 | 启动期门槛 | 测量 |
|---|---|---|
| LS UI 8082 可达 | 200 | `curl -sI :8082` |
| 3 个 Project 创建 | 各 1 | LS SDK `Project.list()` |
| 每 dim ≥ 100 task 导入 | 100 | LS SDK `tasks.list(project=...).count` |
| 双盲比例 | ≥ 10% | `SELECT COUNT(*) FROM labelings WHERE is_blind_sample=true` / total |
| verified 比例（标完后）| ≥ 80% | SQL |
| 每 dim verified 样本 | ≥ 80 | SQL |
| webhook 签名校验单测 | 100% pass | pytest |
| 单测 | ≥ 8 passed | pytest |

## §6 下一步

本步 ✅ → **step_04 LLaMA-Factory 训练流水线（★M2）**：从 `super-evo/verified/{dim}/v*.jsonl` 起训 LoRA + Holdout 守门。

## §7 实施规划（中间道）

### §7.1 实现要点

| # | 要点 | 位置 | 输入 | 核心逻辑 | 关键输出 | 错误处理 | 验证 |
|---|---|---|---|---|---|---|---|
| 1 | **LS docker-compose** | `deploy/docker-compose/label-studio.yml` | env | LS 1.10+ image；PG 15；持久卷 `./data/label-studio/`；env：`DATABASE_URL` + `STORAGE_*`（S3 兼容 MinIO）；端口 8082 | LS UI ok | LS migration 失败 → 删卷重起 | `curl -sI :8082` 200 |
| 2 | **3 维 XML 模板** | `training/configs/label_studio_templates/{cryo_v1,thrust_v1,narrative_v1}.xml` | — | 见 §7.2.2~7.2.4 | 3 xml | — | 模板可在 LS UI Project 设置加载 |
| 3 | **ls_import.py** | `scripts/ls_import.py` | dim + date + blind_ratio | ① 从 MinIO 拉 distill jsonl；② md5 dedup vs `labelings` 已 verified；③ LS SDK 建/找 Project；④ 上传 tasks；⑤ 双盲：sample 10% + 复制 task；⑥ 分派给 2 名标注员 | tasks_count | 重复 task 跳过；blind_ratio < 0.1 raise | `test_import_dedup_idempotent / test_import_blind_ratio` |
| 4 | **webhook 路由** | `api/routes/labeling.py::POST /api/labeling/ls_webhook` | LS POST body + `X-Label-Studio-Signature` | HMAC-SHA256 校验 → 解 `result.value` → 解 `verified/reject_reason/annotation_payload` → upsert `labelings` | 200 ok | 签名 fail → 403；解析 fail → 400 | `test_webhook_signature / test_webhook_idempotent` |
| 5 | **labelings ORM** | `apps/super_evo/db/models.py` | — | 见 §3.3 | 1 表 + index | — | alembic upgrade |
| 6 | **ls_export.py** | `scripts/ls_export.py` | dim + date | SQL filter `verified=true AND dim=X AND date(completed_at)=date` → 拼 jsonl → MinIO put → `dvc add + push` | export count | 0 行不 push（warn）| `test_export_only_verified` |
| 7 | **progress API** | `api/routes/labeling.py::GET /api/labeling/progress` | dim query | SQL: total / in_progress / verified / rejected / blind | JSON | — | `test_progress_counts` |
| 8 | **双盲分配** | `scripts/ls_import.py::_assign_blind_pairs` | tasks list | random.sample(N×ratio) 选；每条 copy + task_id 加 `-b` 后缀；分派给 emails[0] / emails[1] | 双倍 tasks | `len(emails) < 2` raise | `test_blind_assignment_count` |
| 9 | **admin 撤销回滚** | webhook update 事件分支 | LS update payload | 解 `action="updated"` + 新 `verified=false` → labelings.verified=false + 触发 MinIO sync 删该行 | 1 行更新 + 1 行删 | — | `test_revoke_propagates_minio` |
| 10 | **单测** | `tests/super_evo/test_ls_*` | conftest | ≥ 8 用例 | pytest | — | — |
| 11 | **Makefile** | `diting-src/Makefile` | env | 9 target | `.PHONY` | — | `make -n evo-step03-all` |

### §7.2 关键代码 / 配置片段

#### 7.2.1 docker-compose 关键片段（启动期 dev）

```yaml
services:
  label-studio-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: labelstudio
      POSTGRES_PASSWORD: labelstudio
      POSTGRES_DB: labelstudio
    volumes: ["./data/label-studio-db:/var/lib/postgresql/data"]

  label-studio:
    image: heartexlabs/label-studio:1.10.1
    depends_on: [label-studio-db]
    ports: ["8082:8080"]
    environment:
      DATABASE_URL: postgres://labelstudio:labelstudio@label-studio-db:5432/labelstudio
      LABEL_STUDIO_USERNAME: ${SUPER_EVO_LS_ADMIN_EMAIL}
      LABEL_STUDIO_PASSWORD: ${SUPER_EVO_LS_ADMIN_PASSWORD}
      LABEL_STUDIO_USER_TOKEN: ${SUPER_EVO_LS_API_TOKEN}
      LABEL_STUDIO_DISABLE_SIGNUP_WITHOUT_LINK: "true"
    volumes: ["./data/label-studio:/label-studio/data"]
```

#### 7.2.2 cryo_v1.xml（D1 财务测谎 二分类 + reject_reason）

```xml
<View>
  <Header value="阅读 input（财务/公告片段）+ Teacher output，判断 output 是否准确"/>
  <Text name="input" value="$input"/>
  <Text name="teacher_output" value="$output"/>
  <Choices name="verified" toName="teacher_output" required="true">
    <Choice value="accept" alias="true"/>
    <Choice value="reject" alias="false"/>
  </Choices>
  <Choices name="reject_reason" toName="teacher_output" visibleWhen="choice-selected" whenTagName="verified" whenChoiceValue="reject" required="true">
    <Choice value="output_wrong"/><Choice value="output_partial"/>
    <Choice value="instruction_unclear"/><Choice value="input_corrupted"/>
    <Choice value="format_invalid"/><Choice value="safety_violation"/><Choice value="other"/>
  </Choices>
  <TextArea name="annotation_note" toName="teacher_output" placeholder="补充说明（必填若 reason=other）"/>
  <!-- 隐藏字段 -->
  <View visibleWhen="never">
    <Text name="is_blind_sample" value="$is_blind_sample"/>
    <Text name="blind_pair_id" value="$blind_pair_id"/>
  </View>
</View>
```

#### 7.2.3 thrust_v1.xml（D2 thesis 五段评分骨架）

D2 thesis 5 段评分（thesis / catalyst / valuation / risk / exit）；每段 Rating 1~5；总分 ≥ 18 视为 verified；评分模板含 5 个 `<Rating>` 控件 + 1 个 `<Choices>` accept/reject + reject_reason 同 cryo_v1。

#### 7.2.4 narrative_v1.xml（D3 NLI 三类蕴含）

D3 NLI 三类（entailment / neutral / contradiction）；模板含 `<Choices name="nli_label">` 三选一 + reject_reason 同上；启动期对 verified/rejected 与 cryo 同语义对齐。

#### 7.2.5 webhook 签名校验（核心算法 ~12 行）

```python
import hmac, hashlib
from fastapi import Request, HTTPException

def verify_ls_signature(req_body: bytes, signature: str, secret: str) -> bool:
    """LS webhook 签名格式：sha256=<hex>"""
    if not signature or not signature.startswith("sha256="):
        return False
    expected = "sha256=" + hmac.new(secret.encode(), req_body,
                                    hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature)

@router.post("/api/labeling/ls_webhook")
async def ls_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    body = await request.body()
    if not verify_ls_signature(body, request.headers.get("X-Label-Studio-Signature",""),
                                settings.ls_webhook_secret):
        raise HTTPException(403, "invalid signature")
    payload = json.loads(body)
    # ... upsert labelings ...
    return {"ok": True}
```

#### 7.2.6 双盲分配（核心算法 ~14 行）

```python
def assign_blind_pairs(tasks: list[dict], blind_ratio: float,
                       emails: list[str]) -> list[dict]:
    """Sample blind_ratio of tasks; duplicate each into pair (a,b) → 2 annotators."""
    if len(emails) < 2:
        raise ValueError("need ≥ 2 annotator emails for blind pairing")
    n_blind = max(1, int(len(tasks) * blind_ratio))
    blind_indices = random.sample(range(len(tasks)), n_blind)
    out = []
    for idx, t in enumerate(tasks):
        if idx in blind_indices:
            a = {**t, "is_blind_sample": True, "blind_pair_id": t["data"]["id"] + "-b",
                 "_assignee": emails[0]}
            b = {**t, "data": {**t["data"], "id": t["data"]["id"] + "-b"},
                 "is_blind_sample": True, "blind_pair_id": t["data"]["id"],
                 "_assignee": emails[1]}
            out.extend([a, b])
        else:
            out.append({**t, "_assignee": random.choice(emails)})
    return out
```

#### 7.2.7 export 关键 SQL

```python
async def export_verified(dim: str, date: str, db: AsyncSession) -> list[dict]:
    from datetime import datetime
    d0 = datetime.strptime(date, "%Y%m%d")
    d1 = d0 + timedelta(days=1)
    rows = (await db.execute(text("""
        SELECT annotation_payload, instruction_hash
          FROM labelings
         WHERE dim = :dim AND verified = TRUE
           AND completed_at >= :d0 AND completed_at < :d1
    """), {"dim": dim, "d0": d0, "d1": d1})).all()
    # 一条 verified 的 labelings.annotation_payload 已是完整 JSONL 行（标注员修正后）
    return [json.loads(r.annotation_payload) for r in rows]
```

### §7.3 Makefile 合约

| target | 用途 | 入参 | 验证 |
|---|---|---|---|
| `evo-step03-prep` | docker-compose 起 LS + PG；建 3 个 Project；注入 admin token | `SUPER_EVO_LS_*` | `LS up, 3 projects ✅` |
| `evo-step03-import-cryo` | 拉 step_02 当日 cryo_guard distill → 导入 + 10% 双盲 | `--date=$(date -u +%Y%m%d)` | `cryo: imported N, blind M ✅` |
| `evo-step03-import-thrust` | 同上 D2 | — | 同上 |
| `evo-step03-import-narrative` | 同上 D3 | — | 同上 |
| `evo-step03-export` | 3 dim 各 export verified jsonl → MinIO → DVC push | `--date` | `exported: cryo=80 thrust=N narrative=N ✅` |
| `evo-step03-progress` | API GET /api/labeling/progress 3 次 | — | 表格 |
| `evo-step03-test` | `pytest tests/super_evo/test_ls_*.py -v` | — | `≥ 8 passed ✅` |
| `evo-step03-all` | prep → import-3dim → progress → export → test | — | 5 段全绿 |
| `evo-step03-status` | LS Project/task/verified count 三段表 | — | 表格 |
| `evo-step03-clean` | `FORCE=1` 删当日 verified jsonl 与 labelings 当日行；不删 LS | `FORCE` | `cleaned ✅` |

**合约要求**：
1. 配置驱动：blind_ratio / annotator emails 全 env；
2. 可重入：import 第二次同日同 dim 跑只补增量（dedup by instruction_hash）；
3. 失败可观察：每 target 3 行中文摘要。

### §7.4 给后续执行模型的指引

1. **顺序刚性**：docker-compose 起（7.2.1）→ 3 xml 模板（7.2.2~7.2.4）→ labelings ORM + alembic → ls_import.py 含双盲分配（7.2.6）→ webhook 签名 + 路由（7.2.5）→ ls_export.py（7.2.7）→ progress API → 单测 → Makefile；
2. **不嵌入完整模块代码**：§7.2 给关键算法 10~15 行/片段；xml 模板 D2/D3 详细字段由 L4 实践记录回写；
3. **L4 回写**：3 dim Project id / 实际 blind_ratio / 每 dim 任务数 / 标注员 2 邮箱掩码 / 实际 verified 比例；
4. **永久规则审计**：
   ```bash
   rg "verified.*false|distill/.*\.jsonl" training/configs/llama_factory/    # step_04 配置应 0 命中
   ```
   step_04 配置文件**只能**写 `verified/*.jsonl`，**禁止**直接读 `distill/*.jsonl`。

## §8 部署节奏

本机 docker-compose；扩展期独立 LS Pod 上 dev K3s（多标注员 SSO 接入）。

## §9 准出标准

### §9.1 数据量

| 项 | 启动期门槛 |
|---|---|
| 3 个 Project | 各 1 |
| 每 dim 任务 | ≥ 100 |
| 每 dim 双盲任务 | ≥ 10 |
| 每 dim verified 任务（标完后）| ≥ 80 |
| verified jsonl 每 dim 行数 | = labelings verified count |

### §9.2 数据质量（§3.5 16 项全绿）

```bash
# 1) LS 起
make evo-step03-prep
curl -sI http://127.0.0.1:8082    # 期望 200

# 2) 3 个 Project
python -c "
from label_studio_sdk import Client
c = Client(url='$SUPER_EVO_LS_API_URL', api_key='$SUPER_EVO_LS_API_TOKEN')
print('projects:', [p.title for p in c.list_projects()])
"    # 期望 3 个

# 3) 导入 + 双盲
make evo-step03-import-cryo
make evo-step03-import-thrust
make evo-step03-import-narrative
# 期望每 dim ≥ 100 tasks，blind ≥ 10

# 4) 双盲比例
sqlite3 data/super_evo.db "SELECT dim, COUNT(*) blind FROM labelings WHERE is_blind_sample=true GROUP BY dim"
# 期望每 dim ≥ 10

# 5) webhook 签名校验
pytest tests/super_evo/test_ls_webhook.py::test_webhook_signature -v

# 6) progress API
curl -s "http://127.0.0.1:8090/api/labeling/progress?dim=cryo_guard" | jq
# 期望含 total/in_progress/verified/rejected/blind_dual_labeled/blind_pending

# 7) export（须先有 verified 数据）
make evo-step03-export
mc cat local/super-evo/verified/cryo_guard/v$(date -u +%Y%m%d).jsonl | wc -l    # ≥ 80

# 8) DVC
dvc status -r minio    # 期望 up to date

# 9) 单测
pytest tests/super_evo/test_ls_*.py -q    # 期望 ≥ 8 passed

# 10) 永久规则
rg "verified.*false|distill/.*\.jsonl" training/configs/llama_factory/    # 期望 0
```

### §9.3 准出确认

- [ ] §9.2 全部 10 条命令本机跑通 ✅
- [ ] §3.5 16 项全绿
- [ ] L4 回写：3 Project id / 实际 blind_ratio / 标注员邮箱掩码 / verified 比例
- [ ] 通知 step_04 owner（C3 LLaMA-Factory）可启动；通知 step_06 owner（C4 双盲 Kappa）blind 样本已 ≥ 10%

## §10 [Deploy]

启动期 docker-compose；扩展期 K3s `label-studio-deployment.yaml` + ConfigMap webhook URL = super-evo `/api/labeling/ls_webhook`。

## §11 依赖与禁忌

| 类型 | 依赖项 | 当前 | 缺失时 |
|---|---|---|---|
| 硬上游 | step_01 + step_02（MinIO + 当日 distill jsonl ≥ 100/dim）| ✅ | 回 step_02 |
| 硬上游 | ≥ 2 名标注员邮箱（双盲需要）| 用户提供 | 阻塞 |
| 软上游 | LS 1.10+ image 可拉 | dockerhub | 切国内镜像源 |

**严禁**：
- step_04 训练数据加载器 import `distill/*.jsonl`（必须 `verified/*.jsonl`）；
- webhook 不校验签名（必须 HMAC）；
- 双盲 ratio < 0.1（step_06 Kappa 跑不起来）；
- 标注员 < 2 名（双盲不成立）；
- admin 撤销 verified 时仅改 DB 不同步 MinIO（数据不一致）。

## §12 风险与回退

| 触发 | 影响 | 应对 | 重试 |
|---|---|---|---|
| LS docker 启动慢 / migration fail | UI 不可达 | 删卷重起；锁定 image tag `1.10.1` | 2 次 |
| 标注员积压 | verified 比例 < 80% | 缩当批 batch；加人；ADR | — |
| 双盲比例 < 10% | step_06 阻塞 | 导入器报错；增 ratio 到 0.15 | 1 次 |
| webhook 签名 fail | 403 | 校 `SUPER_EVO_LS_WEBHOOK_SECRET` 与 LS 配置一致；查 LS Project Settings | 2 次 |
| LS Project 重复 | 导入器混淆 | import 前 `Project.list()` find by title；reuse | — |
| 同问题 > 2 次 | 阻塞 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v3 中间道细化**：保留 v1.2 三件套；新增 §3.1 7 阶段流水线、§3.2 双盲机制详表、§3.3 labelings ORM 含 blind_pair_id 与 reject_reason 7 枚举、§4.1/4.2 凭证（≥ 2 标注员邮箱）、§7.2.1~7.2.7 关键片段（docker-compose / cryo_v1 xml / webhook 签名 / 双盲分配算法 / export SQL）；§3.5 从 10 项扩到 16 项；§9 从 2 行扩到 10 条逐项命令；151→~600 行 |
| 2026-05-20 | v2 按 L3 v1.2 重写：删 894 行嵌入 yaml/Python；§3.5 10 项；双盲 + Kappa 铺垫；`evo-step03-*`；894→~190 行 |
| 2026-05-16 | 初版 894 行 |
