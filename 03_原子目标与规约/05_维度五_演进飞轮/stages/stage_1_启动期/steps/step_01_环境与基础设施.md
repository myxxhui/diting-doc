# Step 01 · super-evo 服务骨架 + MinIO + DVC + WandB 基础设施（v3 中间道细化版）

## §1 一句话定位与本步交付物

**一句话**：在 `diting-src/apps/super_evo/` 上搭起 **super-evo** 服务骨架（FastAPI port **8090**，9 子包）+ **MinIO 单机 docker**（蒸馏 JSONL / 模型权重 / Holdout 三 bucket prefix）+ **DVC 初始化**（`training/.dvc/`，remote 指向 MinIO）+ **WandB project `diting-super-evo`**（实验追踪，offline 模式可降级）；为 step_02~10 的 C1 Teacher 蒸馏、C2 Label Studio、C3 LLaMA-Factory 训练流水线、C4 双盲 Kappa、Holdout CI Block、灰度发布、`lora_updated` 事件流提供"地基"；**同时**（Lighthouse-Alpha 扩展）作为 **ETL LLM Engine 数据清洗中心**的统一环境入口——**复用同一 GPU 节点 + vLLM 推理栈**，部署 **Qwen-14B vLLM 服务**（端口 **8091**）+ **Kafka topic `sniffer_raw_text` 消费骨架** + **ClickHouse / ES 存储客户端**，消费 D2 嗅探层原文 → 大模型抽取结构化实体（标的/金额/HS Code/事件链）→ 落 ClickHouse + ES 供 D2 The Critic/Mapper/Scorer 与 D3 物理量探针消费。

**交付物**（勾选 = 完成）：

- [ ] **A**（包骨架）：`apps/super_evo/{teacher,labeling,training,deployment,versioning,events,storage,quality,api}/` 9 子包；`tests/super_evo/`
- [ ] **B**（FastAPI 服务）：`python3 -m uvicorn apps.super_evo.main:app --host 127.0.0.1 --port 8090`；`/health` 返回 200，体内含 4 组件状态（`minio / dvc / wandb / redis`）每项 `{ok, version?, reason?}`
- [ ] **C**（MinIO 单机）：docker 起 `minio/minio:RELEASE.2024-*`，端口 9000（API）+ 9001（Console），`super-evo` bucket 已建，三 prefix：`super-evo/distill/`、`super-evo/models/`、`super-evo/holdout/`
- [ ] **D**（DVC 初始化）：在 `diting-src/training/` 跑 `dvc init`；`.dvc/config` 含 `[core]` + `[remote "minio"]` 指向 `s3://super-evo/dvc/`（用 MinIO 当 S3 兼容存储）；`.dvc/.gitignore` 已生成
- [ ] **E**（WandB）：`WANDB_API_KEY` 配置；本机 `wandb login` 通过；test run 创建 `diting-super-evo/_health-check`，metric `up=1`；**降级**：无 API key → `SUPER_EVO_WANDB_MODE=offline` 走本地缓存
- [ ] **F**（Settings 配置层）：`apps/super_evo/config.py::SuperEvoSettings`（pydantic-settings v2，前缀 `SUPER_EVO_`），覆盖 MinIO/DVC/WandB/Redis/Anthropic 占位/Holdout 路径
- [ ] **G**（MinIO client wrapper）：`apps/super_evo/storage/minio_client.py`，暴露 `get_client() / ensure_bucket() / put_jsonl() / get_jsonl_iter() / put_artifact() / list_under()`；启动期幂等 `ensure_bucket(super-evo, prefixes=["distill/","models/","holdout/"])`
- [ ] **H**（单测）：`tests/super_evo/` 含 `test_health.py / test_settings.py / test_minio_client.py`，至少 **≥ 6 用例**，目标启动期 ≥ 12
- [ ] **I**（Makefile 合约）：`evo-step01-prep/bucket/dvc-init/wandb-check/health/test/all/status/clean`
- [ ] **[L-α] J**（GPU 节点就绪）：本机 GPU（≥ 1 张 A10/A100/RTX 4090）或阿里云 ECS GPU 实例（gn7i / gn6i）；`nvidia-smi` 可执行；`SUPER_EVO_GPU_AVAILABLE=true` 写入 `.env`；无 GPU 时本步 ETL Engine 部分**整体暂缓**（不阻塞 step_02~10 主线）
- [ ] **[L-α] K**（Qwen-14B vLLM 部署）：docker 起 `vllm/vllm-openai:latest`，模型 `Qwen/Qwen-14B-Chat`（或 `Qwen2-14B-Instruct`），端口 **8091**，`/health` 200；MinIO 同 bucket 下新增 prefix `super-evo/etl_models/` 缓存模型权重
- [ ] **[L-α] L**（Kafka topic 创建）：本机 Kafka 单 broker（docker `confluentinc/cp-kafka`）或复用 D2 嗅探层 Kafka 集群；topic `sniffer_raw_text`（分区 ≥ 3）+ `sniffer_extracted`（输出）+ DLQ `sniffer_extracted_dlq` 各建好；Consumer group `etl_llm_engine` 注册
- [ ] **[L-α] M**（ClickHouse + ES 客户端骨架）：`apps/super_evo/etl/{clickhouse_client,es_client}.py`；ClickHouse 表 `tender_extracted / event_chain_extracted / overseas_mapping_extracted` 三 schema 建好；ES index `sniffer_full_text_*` 按月切；客户端 wrapper 含 retry + DLQ
- [ ] **[L-α] N**（ETL FastAPI 路由占位）：在 super-evo 同进程内挂载 `/api/etl/*`（健康检查 / Kafka lag 查询 / 抽取重试 API），不另起服务；实际抽取逻辑在 step_02_C1_Teacher 后扩展（轻量演进，见 step_02 §未来扩展段）

> **本步阻塞** step_02~10；无上游硬依赖（除用户提供 MinIO 凭证 / WandB key 或 offline）；与 D0/D1/D2/D3/D4 解耦（不消费任何下游 stream）。
> **[L-α] 本步对 GPU 节点的依赖说明**：ETL Engine 部分须 GPU；GPU 不可用时仅 J~N 交付物暂缓，其余 A~I 仍正常完成；C1 Teacher 蒸馏（step_02）可在无 GPU 时走云端 API（Claude/GPT-4o），不受 GPU 影响。

> **永久规则（D5）**：训练好的 LoRA 权重**禁止**提交 Git；必须经 DVC + MinIO 版本化。`git status` 出现 `*.safetensors / *.bin / *.pt` 在 `training/` 下视为违规。
> **[L-α] 永久规则（ETL 侧）**：Qwen-14B 输出**禁止**绕过 jsonschema.validate 直接入 ClickHouse；DLQ 必须有审计 url + raw_text 留痕；**禁止**伪造抽取结果（无 raw_text 输入则无 extracted 输出）。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2 哲学**：[02_战略维度/05_维度五_演进飞轮/](../../../../../02_战略维度/05_维度五_演进飞轮/)
> - **L3 设计**：[../01_实践目标与策略.md](../01_实践目标与策略.md) §2.3、[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §一
> - **DNA**：[`_System_DNA/05_super_evo/dna_stage_1_启动期.yaml`](../../../../_System_DNA/05_super_evo/dna_stage_1_启动期.yaml) `tech_stack`、`service_name: super-evo`、`work_dir: diting-src`、`port: 8090`
> - **共享规约**：[16_ECS+K3s+ACR+Helm+deploy-engine](../../../../_共享规约/16_阿里云ECS_K3s_ACR_Helm部署与deploy-engine链路.md)、[L3_启动期step_重构模板](../../../../_共享规约/L3_启动期step_重构模板.md)
> - **L4**：[实践记录_step_01_环境与基础设施](../../../../../04_阶段规划与实践/05_维度五_演进飞轮/stage_1_启动期/实践记录_step_01_环境与基础设施.md)
> - **下游 step**：→ step_02（C1 Teacher 蒸馏 ★M1，使用 MinIO/DVC 存 JSONL）/ step_03（C2 Label Studio）/ step_04（C3 LLaMA-Factory，使用 MinIO 存 LoRA 权重）/ step_07（灰度发布，使用 lora_versions 表）/ step_08（`events:flywheel:lora_updated`，被 D1/D2/D3 消费）
> - **跨维度被消费**：D1 step_03（Teacher 蒸馏调用 super-evo `/api/distill/*`）/ D1 step_04~06、D2 step_06、D3 step_05 LoRA 训练入口

## §3 数据采集对象与落库映射

**本步不采集业务数据**——仅创建空 bucket / 空 DVC 仓 / 空 WandB project / 空 ORM 占位。

### §3.1 资源 / 表 / Bucket 详表

| 资源类型 | 名称 / 位置 | 本步状态 | 下游写入时机 |
|---|---|---|---|
| MinIO bucket | `super-evo` | **已建**（含 3 prefix）| step_02+ 写入 |
| MinIO prefix `super-evo/distill/` | 存蒸馏 JSONL（`d1_{lora_name}_{batch_id}.jsonl`）| 空 | step_02 |
| MinIO prefix `super-evo/models/` | 存 LoRA `.safetensors` 与 adapter 元数据 | 空 | step_04 |
| MinIO prefix `super-evo/holdout/` | Holdout 评测集（只读副本）| 空 | step_05 |
| DVC 仓 | `diting-src/training/.dvc/` | `init` 完成 | step_02+ `dvc add` |
| DVC remote `minio` | `s3://super-evo/dvc/`（endpoint http://127.0.0.1:9000）| 配置完成 | step_02+ `dvc push` |
| WandB project | `diting-super-evo` | 空 + 1 test run（`up=1`）| step_04+ 训练每轮 log |
| SQLite ORM 占位 | `data/super_evo.db` | **空文件占位**（不建表）| step_04 建 `lora_versions / training_jobs`，step_05 建 `holdout_evaluations`，step_06 建 `kappa_reports / annotator_trainings`，step_07 建 `release_pipelines`，step_08 不落库 |
| **[L-α] MinIO prefix `super-evo/etl_models/`** | 缓存 Qwen-14B 模型权重 + tokenizer | 空 | vLLM 启动时自动下载并缓存 |
| **[L-α] vLLM 推理服务** | Docker `vllm/vllm-openai:latest` + Qwen-14B 端口 8091 | **已起**（GPU 可用时）| step_02+ 调用 `/v1/chat/completions` |
| **[L-α] Kafka topic** | `sniffer_raw_text` / `sniffer_extracted` / `sniffer_extracted_dlq` | **已建**（≥ 3 分区）| D2 step_02 嗅探层 produce / ETL 消费 / 抽取后 produce |
| **[L-α] ClickHouse 表** | `tender_extracted / event_chain_extracted / overseas_mapping_extracted` | **建表完成**（空）| ETL 抽取后写入 |
| **[L-α] ES index** | `sniffer_full_text_{YYYYMM}` 按月切 + mapping | **当月 index 建好**（空）| ETL 写入 + D2 The Critic 全文检索 |

### §3.2 服务架构图（启动期）

```
┌─────────────── diting-src ───────────────┐
│  apps/super_evo/                          │
│    ├─ api/        (FastAPI routes)        │
│    ├─ teacher/    (step_02 C1)            │
│    ├─ labeling/   (step_03 C2)            │
│    ├─ training/   (step_04 C3 wrapper)    │
│    ├─ quality/    (step_05/06 Holdout/Kappa)
│    ├─ deployment/ (step_07 灰度)          │
│    ├─ events/     (step_08 lora_updated)  │
│    ├─ storage/    (MinIO/DVC client)      │
│    └─ versioning/ (LoRA semver)           │
└────────────┬──────────────────────────────┘
             │ uvicorn :8090
             ↓
   ┌─────────────────────────────┐
   │  Docker (本机 / docker-compose) │
   │  ├─ minio :9000/:9001        │
   │  └─ diting-redis :6379       │
   └─────────────────────────────┘
             │
             ↓
   wandb.ai (cloud) 或 offline 缓存
```

## §3.5 数据质量验收矩阵（本步：工程基座质量）

本步无业务数据采集；矩阵以"4 组件基座的可用性 + 配置正确性 + 幂等性"为主。

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| I1 | **MinIO 可达** | `mc alias set` 成功 + `mc ls super-evo` 列出 3 prefix | ✅ | 容器重启策略 `always` |
| I2 | **bucket 与 prefix 幂等** | `ensure_bucket()` 第二次跑不报错；prefix 仍存在 | ✅ | 用 head_bucket 预检 |
| I3 | **DVC remote 配置** | `dvc remote list` 含 `minio` 且 default；`dvc config` 含 endpoint | ✅ | — |
| I4 | **DVC push 通路** | `echo test > /tmp/x && dvc add /tmp/x && dvc push -r minio` 成功 | ✅ 启动期目标 | offline 模式：`dvc init --no-scm` 本地 cache |
| I5 | **WandB login** | `wandb login --verify` 通过；或 `mode=offline` 时 `wandb.init(mode="offline")` 成功 | ✅ | `SUPER_EVO_WANDB_MODE=offline` |
| I6 | **WandB test run** | run id 可读；`up=1` metric 已 log；可在 wandb.ai/local cache 查到 | ✅ | offline 时本地 `.wandb/` 含 run 目录 |
| I7 | **/health 4 组件结构** | `{minio, dvc, wandb, redis}` 每项 `{ok, version?, reason?}` | ✅ | — |
| I8 | **Settings 字段齐** | `SuperEvoSettings.dict()` 含 ≥ 12 关键字段（见 §4.2）| ✅ | 缺字段 ValidationError |
| I9 | **MinIO endpoint 可配** | `SUPER_EVO_MINIO_ENDPOINT` 环境变量切换不改代码 | ✅ | — |
| I10 | **DVC + MinIO endpoint 一致** | DVC config 的 `endpointurl` 与 settings 的 endpoint 同源 | ✅ | 单测 `test_dvc_endpoint_matches_settings` |
| I11 | **no-mock 资产** | 业务路径不出现 `mock_distill_*.jsonl`、`fake_lora_*.safetensors` | ✅ | — |
| I12 | **`.gitignore` 含 LoRA 大文件** | `*.safetensors / *.bin / *.pt` 在 `training/` 已被忽略 | ✅ | grep 验证 |
| I13 | **依赖锁版本** | `boto3>=1.34 / minio>=7.2 / dvc[s3]>=3 / wandb>=0.16 / fastapi>=0.110` 含下限 | ✅ | 锁不上写 ADR |
| I14 | **启动期 docker-compose 单文件** | `deploy/docker-compose/super-evo-dev.yml` 起 minio + redis 一键 | ✅ | — |

### §3.5.5 [Lighthouse-Alpha] ETL LLM Engine 环境就绪

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| EL1 | **GPU 节点** | `nvidia-smi` 可执行 + 显存 ≥ 24GB（Qwen-14B 量化后约 16GB）；`SUPER_EVO_GPU_AVAILABLE=true` 写入 .env | ⚠️ 用户需提供 | 无 GPU → 本节其余项**整体暂缓**；step_02 Teacher 走云端 API 继续 |
| EL2 | **vLLM 服务** | `curl :8091/health` 200；`/v1/models` 列出 `Qwen-14B-Chat`；首次启动模型下载 ≤ 30 分钟 | ✅（有 GPU）| 模型下载慢 → 用 MinIO 缓存预加载 |
| EL3 | **Kafka topic** | `sniffer_raw_text` / `sniffer_extracted` / DLQ 三 topic 存在；consumer group `etl_llm_engine` 注册 | ✅ | Kafka 不可用 → 启动期可临时用 Redis Stream 兜底（POC 不上生产）|
| EL4 | **ClickHouse 连通** | DSN 可连接 + 三张表 CREATE TABLE 成功 + 写入 1 行 sample → 读回一致 | ✅ | CH 不可用 → 启动期临时用 SQLite 模拟（生产必须 CH）|
| EL5 | **ES 连通** | ES `/_cluster/health` 200；index template 已 PUT；当月 index 已建 | ✅ | ES 不可用 → 启动期降级走 ClickHouse 全文索引（性能差但可用）|
| EL6 | **jsonschema 严格** | 抽取结果 schema 定义 `apps/super_evo/etl/schemas/{tender,event_chain,overseas}.json` 三份；写入前必须 validate | ✅ | 验证失败 → DLQ + 告警 |
| EL7 | **DLQ 审计** | `sniffer_extracted_dlq` 包含 raw_text + 失败原因 + Qwen 原始输出全文 | ✅ | — |
| EL8 | **配置全 env 化** | `SUPER_EVO_QWEN_ENDPOINT / KAFKA_BROKERS / CLICKHOUSE_DSN / ES_URL` env 化；切环境只改 .env | ✅ | 写死 → 单测拒绝 |
| EL9 | **成本可观察** | WandB log 每日 vLLM GPU-hour + token 处理量 + DLQ 率 | ✅ | — |

**共 14 项原有 + 9 项 Lighthouse-Alpha = 23 项**；启动期 14 项必须全绿；EL1~9 在 GPU 可用时必须全绿，GPU 不可用时本节准出可暂缓但 14 项基础项仍须 ✅。

## §4 凭证清单与环境模板

### §4.1 用户必须提供的凭证

| 凭证 / 环境变量 | 用途 | 默认值 | 写在哪 | 是否必填 |
|---|---|---|---|---|
| `SUPER_EVO_MINIO_ENDPOINT` | MinIO API endpoint | `http://127.0.0.1:9000` | `.env` | 必填 |
| `SUPER_EVO_MINIO_ACCESS_KEY` | MinIO access | `super-evo-admin` | `.env` | 必填 |
| `SUPER_EVO_MINIO_SECRET_KEY` | MinIO secret | `super-evo-pass-dev`（生产改）| `.env` | 必填 |
| `SUPER_EVO_MINIO_BUCKET` | bucket 名 | `super-evo` | `.env` | 可不填 |
| `SUPER_EVO_DVC_REMOTE_NAME` | DVC remote 名 | `minio` | `.env` | 可不填 |
| `WANDB_API_KEY` | WandB 云端追踪 | （空 → 启用 offline） | `.env` | 否（offline 可空）|
| `SUPER_EVO_WANDB_PROJECT` | WandB project 名 | `diting-super-evo` | `.env` | 可不填 |
| `SUPER_EVO_WANDB_MODE` | `online / offline` | `online`（缺 key 自动切 offline）| `.env` | 可不填 |
| `SUPER_EVO_REDIS_URL` | step_08 lora_updated 流 | `redis://127.0.0.1:6379/0` | `.env` | 必填 |
| `ANTHROPIC_API_KEY` 或 `OPENAI_API_KEY` 或 `DEEPSEEK_API_KEY` | Teacher（step_02 才用，本步留空也行） | — | `.env` | step_02 前提供 |
| **[L-α]** `SUPER_EVO_GPU_AVAILABLE` | GPU 节点可用标志 | `false` | `.env` | 无 GPU 时 false，ETL 暂缓 |
| **[L-α]** `SUPER_EVO_QWEN_ENDPOINT` | vLLM Qwen-14B 端点 | `http://127.0.0.1:8091` | `.env` | GPU 可用时必填 |
| **[L-α]** `SUPER_EVO_KAFKA_BROKERS` | Kafka brokers | `127.0.0.1:9092` | `.env` | 必填（GPU 可用时）|
| **[L-α]** `SUPER_EVO_CLICKHOUSE_DSN` | ClickHouse 连接 | `clickhouse://default:@127.0.0.1:9000/diting` | `.env` | 必填（GPU 可用时）|
| **[L-α]** `SUPER_EVO_ES_URL` | Elasticsearch | `http://127.0.0.1:9200` | `.env` | 必填（GPU 可用时）|

### §4.2 `.env.template` 增补片段

```text
# ============ super_evo (D5) ============
SUPER_EVO_MINIO_ENDPOINT=http://127.0.0.1:9000
SUPER_EVO_MINIO_ACCESS_KEY=super-evo-admin
SUPER_EVO_MINIO_SECRET_KEY=super-evo-pass-dev
SUPER_EVO_MINIO_BUCKET=super-evo
SUPER_EVO_DVC_REMOTE_NAME=minio
SUPER_EVO_DVC_REMOTE_URL=s3://super-evo/dvc/
SUPER_EVO_WANDB_PROJECT=diting-super-evo
SUPER_EVO_WANDB_MODE=online        # 或 offline
SUPER_EVO_REDIS_URL=redis://127.0.0.1:6379/0
WANDB_API_KEY=                      # 留空走 offline
ANTHROPIC_API_KEY=                  # step_02 前补
```

### §4.3 关键 Settings schema（pydantic-settings v2 风格）

```python
class SuperEvoSettings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_prefix="SUPER_EVO_", extra="ignore",
    )
    service_name: str = "super-evo"
    port: int = 8090

    # MinIO
    minio_endpoint: str = "http://127.0.0.1:9000"
    minio_access_key: str
    minio_secret_key: str
    minio_bucket: str = "super-evo"
    minio_prefix_distill: str = "distill/"
    minio_prefix_models: str = "models/"
    minio_prefix_holdout: str = "holdout/"

    # DVC
    dvc_remote_name: str = "minio"
    dvc_remote_url: str = "s3://super-evo/dvc/"

    # WandB
    wandb_project: str = "diting-super-evo"
    wandb_mode: str = "online"     # online | offline

    # Redis
    redis_url: str = "redis://127.0.0.1:6379/0"

    # Teacher (step_02+)
    anthropic_api_key: Optional[str] = None
    openai_api_key: Optional[str] = None
    deepseek_api_key: Optional[str] = None
```

## §5 启动期目标

| 指标 | 启动期门槛 | 测量 |
|---|---|---|
| `GET /health` 状态码 | 200 | `curl -sI :8090/health` |
| `/health` 4 组件结构 | 4 键全在；每项含 `ok/version/reason` | `jq '.minio,.dvc,.wandb,.redis'` |
| MinIO bucket | 1 存在 + 3 prefix | `mc ls super-evo` 输出 3 行 |
| DVC `dvc status` | clean 或 `up to date` | `dvc status -r minio` |
| WandB | login 通过（或 offline 缓存可用）+ 1 test run id | `wandb login --verify` 或 ls `.wandb/` |
| 单测 | ≥ 6 passed（目标 ≥ 12）| `pytest tests/super_evo/ -q` |
| 永久规则审计 | `git status` 不含 `training/**/*.safetensors\|*.bin\|*.pt` | git status grep |

## §6 下一步

本步 ✅ → **step_02 C1 Teacher 蒸馏器（★M1）**：实现 `/api/distill/*`，将各维度的输入（如 D1 财报疑点）→ Teacher LLM → 结构化 JSONL → MinIO + DVC 版本化。

## §7 实施规划（中间道：实现要点 + Makefile 合约 + 关键代码片段）

### §7.1 实现要点（位置 / 输入 / 核心逻辑 / 关键字段 / 错误处理 / 验证）

| # | 要点 | 位置 | 输入 | 核心逻辑 | 关键字段 / 输出 | 错误处理 | 验证标准 |
|---|---|---|---|---|---|---|---|
| 1 | **包骨架** | `apps/super_evo/` | — | 9 子包 + `__init__.py`；`tests/super_evo/` | 9 个包目录 | 缺包 CI fail | `find apps/super_evo -name __init__.py \| wc -l ≥ 9` |
| 2 | **依赖** | `diting-src/pyproject.toml` | step_01~02 基线 | 追加 `boto3>=1.34 / minio>=7.2 / dvc[s3]>=3 / wandb>=0.16 / openai>=1 / anthropic>=0.18`；`requires-python>=3.9` | 依赖锁版本 | `pip check` | `pip show boto3` |
| 3 | **SuperEvoSettings** | `apps/super_evo/config.py` | `.env` | pydantic-settings v2；见 §4.3 | 见 §4.3 | 缺 key ValidationError | `python -c "from apps.super_evo.config import settings; print(settings.dict())"` |
| 4 | **MinIO docker compose** | `deploy/docker-compose/super-evo-dev.yml` | env | minio:RELEASE.* + redis:7-alpine；持久卷 `./data/minio:/data` | 容器 `super-evo-minio`、`diting-redis` | endpoint 占用换端口 | `docker compose ps` 全 Up |
| 5 | **MinIO client wrapper** | `apps/super_evo/storage/minio_client.py` | settings | boto3 S3 兼容；`ensure_bucket(bucket, prefixes)` 幂等；`put_jsonl / get_jsonl_iter / put_artifact / list_under` | 6 公开方法 | 网络错重试 3 次；`NoSuchBucket` → create | `test_minio_client_ensure_idempotent` |
| 6 | **DVC init script** | `scripts/dvc_init.sh` | settings | `cd training && dvc init --no-scm 2>/dev/null \|\| true && dvc remote add -d minio $URL --force && dvc remote modify minio endpointurl $ENDPOINT && dvc remote modify minio access_key_id $AK && dvc remote modify minio secret_access_key $SK` | `.dvc/config` 含 `remote "minio"` | 已存在跳过 | `dvc remote list \| grep minio` |
| 7 | **WandB client wrapper** | `apps/super_evo/quality/wandb_client.py` | settings | `init_run(name, mode)`；`mode='offline'` 时 `os.environ["WANDB_MODE"]="offline"`；`log(metrics)`；`finish()` | 4 方法 | 无 key 自动 offline；log 异常打日志不中断 | `test_wandb_offline_works` |
| 8 | **FastAPI main + health** | `apps/super_evo/main.py` + `api/routes/health.py` | settings | lifespan: MinIO ensure_bucket / WandB 验证连通 / Redis ping；`/health` 并发探 4 组件 + 返回汇总 | 见 §7.2.4 JSON | gather(return_exceptions=True)；任何异常入 reason | `curl /health \| jq` |
| 9 | **`.gitignore` 增补** | `diting-src/.gitignore` | — | 追加 `training/**/*.safetensors`、`*.bin`、`*.pt`、`.dvc/cache/`、`wandb/`（offline 缓存）| 5 行 | — | `git check-ignore training/foo.safetensors` |
| 10 | **单测** | `tests/super_evo/test_*.py` | conftest | `test_settings.py / test_minio_client.py / test_wandb_client.py / test_health.py` | ≥ 6 用例 | — | `pytest -v` |
| 11 | **Makefile** | `diting-src/Makefile` | settings | 8 target | `.PHONY` | — | `make -n evo-step01-all` |
| **[L-α] 12** | **vLLM docker-compose 段** | `deploy/docker-compose/etl-llm-engine.yml`（或合并入 super-evo-dev.yml）| GPU runtime | `vllm/vllm-openai:latest` + Qwen-14B；`runtime: nvidia` + `deploy.resources.reservations.devices` | 容器 `etl-vllm` Up；`:8091/health` 200 | 显存不足 → 改 `--gpu-memory-utilization 0.85` | `curl :8091/v1/models` 含 Qwen |
| **[L-α] 13** | **Kafka docker-compose 段** | 同上 yml | env | `confluentinc/cp-kafka:7.5.x` 单 broker；KRaft 模式（无须 zookeeper）；自动建 3 topic | 3 topic 存在 | port 占用换端口 | `kafka-topics --list` 含 3 个 |
| **[L-α] 14** | **ClickHouse 客户端** | `apps/super_evo/etl/clickhouse_client.py` | settings | clickhouse-driver；retry 3 次；建三表 idempotent；sample insert/select | 1 行 roundtrip | DSN 错 → ConnectionError | `pytest test_clickhouse_client.py` |
| **[L-α] 15** | **ES 客户端** | `apps/super_evo/etl/es_client.py` | settings | elasticsearch-py 8.x；index template by month；retry | 当月 index 存在 | — | `pytest test_es_client.py` |
| **[L-α] 16** | **ETL FastAPI 路由占位** | `apps/super_evo/api/routes/etl.py` | settings | `/api/etl/health` + `/api/etl/kafka/lag` + `/api/etl/retry/{message_id}` 三占位接口；实际抽取逻辑在 step_02 演进段 | 200 + body | — | curl 三接口 |
| **[L-α] 17** | **Qwen-14B 抽取 prompt 模板（占位）** | `apps/super_evo/etl/prompts/{tender,event_chain,overseas}.yaml` | — | 三模板占位；step_02 完整化 | yaml 解析 OK | — | 加载测试 |

### §7.2 关键代码片段（中间道：仅嵌入关键算法，不放整模块骨架）

#### 7.2.1 MinIO `ensure_bucket` 幂等（核心算法 ~15 行）

```python
def ensure_bucket(client, bucket: str, prefixes: list[str]) -> None:
    """Idempotent: create bucket if not exists; ensure prefixes via 0-byte placeholders."""
    try:
        client.head_bucket(Bucket=bucket)
    except client.exceptions.ClientError as e:
        if e.response["Error"]["Code"] not in ("404", "NoSuchBucket"):
            raise
        client.create_bucket(Bucket=bucket)
    for p in prefixes:
        key = p if p.endswith("/") else p + "/"
        try:
            client.head_object(Bucket=bucket, Key=key + ".keep")
        except client.exceptions.ClientError:
            client.put_object(Bucket=bucket, Key=key + ".keep", Body=b"")
```

#### 7.2.2 WandB offline 自动降级（核心算法 ~12 行）

```python
def init_run(name: str, project: str, mode: str = "online") -> "wandb.Run":
    import os, wandb
    api_key = os.environ.get("WANDB_API_KEY")
    if mode == "online" and not api_key:
        log.warning("WANDB_API_KEY missing, fallback to offline")
        mode = "offline"
    os.environ["WANDB_MODE"] = mode
    run = wandb.init(project=project, name=name, mode=mode,
                     reinit=True, settings=wandb.Settings(start_method="thread"))
    return run
```

#### 7.2.3 DVC remote 配置（关键 shell 片段）

```bash
cd diting-src/training
dvc init --no-scm 2>/dev/null || true
dvc remote add -d "$DVC_REMOTE_NAME" "$DVC_REMOTE_URL" --force
dvc remote modify "$DVC_REMOTE_NAME" endpointurl "$MINIO_ENDPOINT"
dvc remote modify "$DVC_REMOTE_NAME" access_key_id "$MINIO_ACCESS_KEY"
dvc remote modify "$DVC_REMOTE_NAME" secret_access_key "$MINIO_SECRET_KEY"
dvc remote modify "$DVC_REMOTE_NAME" use_ssl false   # 本机 http
```

#### 7.2.4 `/health` 响应 JSON 示例（4 组件聚合）

```json
{
  "status": "ok",
  "service": "super-evo",
  "version": "0.1.0",
  "components": {
    "minio":  {"ok": true,  "version": "RELEASE.2024-05-..", "bucket": "super-evo",
               "prefixes": ["distill/","models/","holdout/"]},
    "dvc":    {"ok": true,  "version": "3.50.x", "remote": "minio",
               "endpointurl": "http://127.0.0.1:9000"},
    "wandb":  {"ok": true,  "mode": "online", "project": "diting-super-evo",
               "last_run_id": "abcd1234"},
    "redis":  {"ok": true,  "latency_ms": 1, "url": "redis://127.0.0.1:6379/0"}
  }
}
```

无 key 时 `wandb.mode="offline"`、`wandb.ok=true`；MinIO 起不来时 `components.minio.ok=false, reason="connection refused: ..."`，服务级 `status` 仍 `"ok"`（4 组件中**至少 MinIO 必须 ok**才视为本步准出）。

### §7.3 Makefile 合约（一键复现 · 配置驱动 · 可重入幂等）

| target | 用途 | 入参（env） | 验证标准（输出末段） |
|---|---|---|---|
| `evo-step01-prep` | docker compose 起 minio + redis；校验 `.env` 关键 key | `SUPER_EVO_MINIO_*`、`SUPER_EVO_REDIS_URL` | `minio up ✅ \| redis PONG ✅` |
| `evo-step01-bucket` | `ensure_bucket(super-evo, [distill/,models/,holdout/])` | `SUPER_EVO_MINIO_BUCKET` | `bucket=super-evo prefixes=3 ✅` |
| `evo-step01-dvc-init` | 跑 `scripts/dvc_init.sh` | `SUPER_EVO_DVC_REMOTE_*` | `dvc remote list \| grep minio ✅` |
| `evo-step01-wandb-check` | `wandb login --verify` 或 offline 自检 | `WANDB_API_KEY`、`SUPER_EVO_WANDB_MODE` | `mode=online \| login ok ✅`（或 `mode=offline ✅`）|
| `evo-step01-up` | 后台启 uvicorn :8090；写 pid | `COPILOT_PORT?=8090` 之外用 `SUPER_EVO_PORT?=8090` | `pid=N listening :8090 ✅` |
| `evo-step01-health` | `curl :8090/health \| jq` + 4 组件断言 | — | `4 components ok ✅` |
| `evo-step01-test` | `pytest tests/super_evo/ -q` | — | `≥ 6 passed ✅` |
| `evo-step01-all` | prep → bucket → dvc-init → wandb-check → up → health → test → down | — | 8 段全绿 |
| `evo-step01-status` | docker ps + bucket 列表 + dvc remote + wandb mode | — | 4 行表格 |
| `evo-step01-clean` | 停 docker（保留持久卷） | — | `containers stopped ✅` |
| **[L-α]** `evo-step01-etl-prep` | GPU 自检 + 拉 vLLM 镜像 + Kafka/ClickHouse/ES docker 起 | `SUPER_EVO_GPU_AVAILABLE` | `gpu=✅ vllm-img=✅ kafka=✅ ch=✅ es=✅` |
| **[L-α]** `evo-step01-etl-vllm-up` | 启 Qwen-14B vLLM 容器 + 健康检查 | `SUPER_EVO_QWEN_ENDPOINT` | `/health 200` 内 30s |
| **[L-α]** `evo-step01-etl-kafka-topics` | 创建 3 topic + consumer group | `KAFKA_BROKERS` | 3 topic 存在 |
| **[L-α]** `evo-step01-etl-ch-init` | 建 ClickHouse 三表 + sample insert/select | `CLICKHOUSE_DSN` | 1 行 roundtrip |
| **[L-α]** `evo-step01-etl-es-init` | PUT ES index template + 当月 index | `ES_URL` | template + index 存在 |
| **[L-α]** `evo-step01-etl-test` | pytest tests/super_evo/etl/ | — | ≥ 8 passed |
| **[L-α]** `evo-step01-etl-all` | etl-prep → vllm-up → kafka → ch → es → test | — | 6 段全绿（GPU 不可用时整体 skip）|
| **[L-α]** `evo-step01-etl-status` | vLLM GPU 占用 + Kafka lag + CH/ES 行数 | — | 4 行表格 |

**合约要求**：
1. 入参全部 env 化（端点、bucket 名、project 名等），Makefile 不写死；
2. **配置驱动**：把 `SUPER_EVO_MINIO_ENDPOINT` 改成 `http://127.0.0.1:9100` 或把 `WANDB_MODE` 改 offline，跑 `make evo-step01-all` 端到端通过；
3. **可重入幂等**：`evo-step01-all` 第二次跑跳过 docker run（用 `docker compose up -d`）、`ensure_bucket` 检 head_bucket 跳过、dvc init 已存在跳过；
4. **失败可观察**：每个 target 输出"做了什么 / 期望什么 / 实际什么"3 行中文摘要。

### §7.4 给后续执行模型的指引

1. **顺序刚性**：包骨架（7.2 节 1）→ 依赖装齐 → Settings（7.2.0）→ docker compose 起 minio+redis → MinIO client + ensure_bucket（7.2.1）→ DVC init + remote（7.2.3）→ WandB wrapper（7.2.2）→ FastAPI main + /health（7.2.4）→ tests → Makefile；
2. **不嵌入完整模块代码**：本文档 §7.2 是关键算法 10~15 行/片段；具体的完整路由 / docstring / 日志格式由 L4 实践记录回写；
3. **降级路径明示**：无 GPU 时本步**完全可跑**（无训练）；无 WandB key 时切 offline；MinIO endpoint 改端口时改 `.env` 即可，**不**改代码；
4. **L4 回写内容**：
   - MinIO 镜像 tag（`RELEASE.2024-*`）；
   - DVC 版本（`dvc --version`）；
   - WandB 模式（online / offline）+ test run id 或本地路径；
   - `/health` 完整 JSON（脱敏 key）；
   - 8 个 Makefile target 实际耗时；
5. **永久规则审计**：
   ```bash
   git check-ignore training/foo.safetensors training/foo.bin training/foo.pt
   git status training/ | grep -E "\.(safetensors|bin|pt)$" | wc -l    # 期望 0
   ```
6. **跨维度承接**：本步完成后通知 D1 step_03 owner 可启动 Teacher 蒸馏（D1 step_03 会调用 super-evo `/api/distill/*`，到 step_02 时实现）。

## §8 部署节奏

| 项 | 本 step |
|---|---|
| 部署面 | **本机** uvicorn + docker compose（MinIO + Redis）|
| Chart | **不改** |
| ACR | **不构建** |
| Helm release | **—** |
| 上 K3s 时机 | step_07 灰度发布时上 dev K3s；启动期仅本机 docker compose 即可 |

## §9 准出标准

### §9.1 数据量（本步：bucket/prefix/run）

| 项 | 启动期门槛 | 测量 |
|---|---|---|
| MinIO bucket | 1 | `mc ls / \| grep super-evo` |
| MinIO prefix | 3（`distill/ models/ holdout/`）| `mc ls super-evo` 含 3 行 + `.keep` 占位 |
| DVC remote | 1（`minio`，default）| `dvc remote list` |
| WandB run | ≥ 1（health-check run）| API 或 `.wandb/` |

### §9.2 工程质量（§3.5 14 项必须全绿）

```bash
# 1) 依赖与骨架
cd diting-src && pip install -e .
find apps/super_evo -name __init__.py | wc -l    # 期望 ≥ 9

# 2) docker compose 起
docker compose -f deploy/docker-compose/super-evo-dev.yml up -d
docker compose -f deploy/docker-compose/super-evo-dev.yml ps     # 期望全 Up

# 3) MinIO bucket + prefix
mc alias set local http://127.0.0.1:9000 $SUPER_EVO_MINIO_ACCESS_KEY $SUPER_EVO_MINIO_SECRET_KEY
mc ls local/super-evo    # 期望 3 行（distill/ models/ holdout/）

# 4) DVC
cd training && dvc remote list | grep minio       # 期望命中
echo "test" > /tmp/dvc_smoke && dvc add /tmp/dvc_smoke && dvc push -r minio

# 5) WandB
wandb login --verify || echo "offline mode"
python -c "from apps.super_evo.quality.wandb_client import init_run; r=init_run('health-check','diting-super-evo'); r.log({'up':1}); r.finish(); print(r.id)"

# 6) FastAPI + /health
python3 -m uvicorn apps.super_evo.main:app --port 8090 &
sleep 3
curl -s :8090/health | jq '.components | keys | length'    # 期望 4
curl -s :8090/health | jq '.components.minio.ok'           # 期望 true

# 7) 单测
pytest tests/super_evo/ -q    # 期望 ≥ 6 passed

# 8) 永久规则
git status training/ | grep -E "\.(safetensors|bin|pt)$" | wc -l    # 期望 0

# 9) Makefile 合约
make evo-step01-all
make evo-step01-status
```

### §9.3 准出确认

- [ ] §9.2 全部 9 条命令本机跑通 ✅
- [ ] §3.5 14 项全绿
- [ ] L4 实践记录 `实践记录_step_01_环境与基础设施.md` 已回写：组件版本快照（minio / dvc / wandb）、`/health` JSON、Makefile 实际耗时、WandB mode（online/offline）
- [ ] 通知 step_02 owner（C1 Teacher 蒸馏 ★M1）可启动

## §10 [Deploy]

启动期 ConfigMap / Helm Chart **不创建**；本步只在 `diting-src/.env` 写 dev 配置。`super-evo` Pod 在 **step_07 灰度发布** 时上 dev K3s（需先在 step_01~06 备好镜像）。

## §11 依赖与禁忌

| 类型 | 依赖项 | 当前就绪 | 缺失时处理 |
|---|---|---|---|
| 硬依赖 | Python 3.9+ | ✅ | 升级或 ADR |
| 硬依赖 | Docker Desktop / docker compose v2 | 用户本机 | 阻塞 |
| 软依赖 | WandB API key | 可空 → offline | offline 模式 |
| 软依赖 | Anthropic / OpenAI / DeepSeek key（任一）| step_02 前 | 本步留空 |
| **[L-α] 软依赖** | GPU 节点（≥ 24GB 显存）| 用户提供 | 无 → ETL 部分整体暂缓；step_02 Teacher 走云端 API |
| **[L-α] 软依赖** | Kafka / ClickHouse / ES（本机 docker 或外部集群）| 用户提供或 docker-compose 起 | 无 → ETL 暂缓，不阻塞 step_02~10 |

**严禁**：
- 训练 LoRA `.safetensors / .bin / .pt` 提交 Git（必须经 DVC + MinIO）；
- MinIO 密钥写死代码（必须 env 化）；
- 业务路径出现 `mock_distill_*.jsonl` 或 `fake_lora_*.safetensors`（违反 no-mock）；
- DVC remote 用 GitHub LFS 替代（本项目坚持 S3 兼容 MinIO 路线）；
- 在 K3s 启动期 deployment 直接拉本步的本机 docker image（启动期不上 K3s）；
- **[L-α]** Qwen-14B 抽取结果未经 jsonschema.validate 直接写 ClickHouse / ES；
- **[L-α]** 伪造 ETL 抽取结果入业务库（必须有真实 raw_text 输入）；
- **[L-α]** 用 OpenAI/Claude 等云端大模型替代 Qwen-14B 跑 ETL（成本爆炸 + 数据合规问题）。

## §12 风险与回退

| 触发 | 影响 | 应对 | 重试上限 |
|---|---|---|---|
| MinIO 9000 端口冲突 | 起不来 | 改 `SUPER_EVO_MINIO_ENDPOINT` 到 9100；同步改 docker compose 端口映射 | 2 次 |
| DVC init 报已存在 | 不影响功能 | `dvc init --no-scm 2>/dev/null \|\| true` 吞掉；视为正常 | — |
| WandB API 不可达 | online 失败 | 自动切 offline；log warning；写 ADR | 1 次（直接切）|
| boto3 / minio SDK 冲突 | import 失败 | 锁版本 `boto3>=1.34,<2`；`pip check` | 2 次 |
| `dvc push` 报 endpoint 错 | DVC ↔ MinIO 不通 | 确认 `endpointurl=http://127.0.0.1:9000`、`use_ssl=false` | 2 次 |
| `dvc add` 大文件慢 | 启动期 smoke 用 1KB 文件即可 | 用 `/tmp/dvc_smoke` 测；不在本步压性能 | — |
| 同问题修复 > 2 次 | 阻塞 | 按 .cursorrules §8.4f 回退：重建 venv / 删 `.dvc/` 重 init / 重起 MinIO 容器 | — |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v3.1 Lighthouse-Alpha 融合**：merge_inplace 融入 ETL LLM Engine 主体——§1 一句话扩 + 交付物 J~N（GPU/vLLM/Kafka/ClickHouse/ES/ETL FastAPI 占位）；§3.1 资源表追加 6 行（ETL 模型 prefix / vLLM 服务 / Kafka topic / ClickHouse 表 / ES index）；§3.5 新增 §3.5.5 矩阵 9 项（EL1~EL9）；§4.1 凭证表加 6 行（GPU + vLLM + Kafka + CH + ES env）；§7.1 追加 12~17 六实现要点（vLLM/Kafka docker / CH/ES 客户端 / ETL FastAPI 路由 / Prompt 模板占位）；§7.3 Makefile 加 8 个 etl target；§11 软依赖加 GPU/Kafka/CH/ES；§严禁加 ETL 三条；强化 GPU 不可用时整体暂缓不阻塞主线 |
| 2026-05-21 | **v3 中间道细化**：保留 v1.2 §3.5 矩阵 + Makefile 合约 + no-mock 三件套不动；新增 §3.1 资源详表、§3.2 服务架构图、§4.2/4.3 .env 与 Settings schema、§7.2.1~7.2.4 关键算法/响应 JSON 示例（4 个关键片段，每个 10~15 行）、§7.3 Makefile 合约扩到 10 个 target；§3.5 从"不适用"细化为 14 项工程质量；§9 从 2 行扩到 9 条逐项命令；127→~600 行 |
| 2026-05-20 | v2 按 L3 v1.2 重写：删 1007 行嵌入代码；§3.5 不适用；`evo-step01-*` 8 target；1007→~150 行 |
| 2026-05-16 | 初版 1007 行 |
