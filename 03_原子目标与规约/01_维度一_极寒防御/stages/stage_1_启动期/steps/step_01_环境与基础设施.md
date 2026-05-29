# Step 01 · 环境与基础设施（K3s + vLLM + Milvus + Neo4j + cryo-guard 骨架）

## §1 一句话定位与本步交付物

**一句话**：搭起 cryo-guard 模块跑起来所需的全部基础设施 + 服务骨架，让 step_02~10 都有"地基"可踩。

**交付物**（勾选 = 完成）：
- [ ] **A**（项目骨架）：`apps/cryo_guard/` 目录结构齐全（含 `api/`、`db/`、`engines/{financial_fraud,shareholder_integrity,related_party}/`、`decision_gate/`、`llm/`、`rag/`、`graph/`）；`pyproject.toml` 依赖齐
- [ ] **B**（FastAPI 骨架）：`uvicorn apps.cryo_guard.api.main:app --port 8081` 可起；`/health` 返回 `status=ok` 含 `engines/dependencies/upstream_streams` 三段；`/api/decision-gate/health` 返回 `status=initializing`
- [ ] **C**（K3s 集群）：单节点 K3s 起 + `kubectl get nodes` Ready
- [ ] **D**（vLLM + Qwen2.5-7B）：GPU 可用时 `--enable-lora`；不可用时 stub 模式（HTTP 200 + 假响应，**非阻塞**）
- [ ] **E**（Milvus Standalone）：19530 端口可访问，可创建 collection
- [ ] **F**（Neo4j Community）：7687 端口可访问，默认账号 `neo4j/diting123`
- [ ] **G**（Redis）：6379（与 D0 共用 1 个实例）
- [ ] **H**（单测）：`pytest tests/cryo_guard/test_health.py -v` 全绿

> **本步是 step_02~10 的硬阻塞**：基础设施未就绪所有训练 / 服务 / 评测都无法跑。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2 哲学**：[01_维度一_极寒防御 · 04_防御实践策略规划](../../../../../02_战略维度/01_维度一_极寒防御/04_防御实践策略规划.md)
> - **本阶段总览**：[stage_1_启动期/README](../README.md)
> - **L3 技术方案**：[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §1.1 技术栈矩阵、§1.2 硬件要求、§二 代码仓库结构、§5.1 K3s 部署图
> - **L3 模型训练**：[../04_模型训练与部署.md](../04_模型训练与部署.md) §6.2 vLLM 部署命令
> - **L3 数据采集**：[../03_数据采集与预处理.md](../03_数据采集与预处理.md) §8.1 存储架构（MinIO/SQLite/Milvus/Neo4j）
> - **DNA 键**：`_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml` → `tech_stack`、`hardware_requirements`、`work_dir`、`service_name`、`dependencies.upstream`
> - **共享规约**：[L3 步骤·部署价值哲学·必选引用](../../../../_共享规约/L3步骤文档_部署价值哲学_必选引用.md) · [16 · ECS+K3s+ACR+Helm+deploy-engine 链路](../../../../_共享规约/16_阿里云ECS_K3s_ACR_Helm部署与deploy-engine链路.md)
> - **L4 实践记录**：[实践记录_step_01_环境与基础设施.md](../../../../../04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_01_环境与基础设施.md)
> - **上游 step**：← 无（本 step 是 D1 启动期入口）
> - **下游 step**：→ step_02（采集脚本依赖 SQLite ORM）、step_03~06（训练流水线依赖 GPU + ORM 表）、step_07~10（服务依赖 K3s + vLLM）

## §3 数据采集对象 / 落库映射

**本步不涉及数据采集**——仅建 ORM 表结构、空 SQLite 文件、空 Milvus collection、空 Neo4j 图。

### §3.1 资源/表/Collection 详表

| 落库对象 | 位置 | 本步状态 | 下游写入 |
|---|---|---|---|
| `financial_reports` | SQLite `data/cryo_guard.db` | **空表建好** | step_02 |
| `announcements` | 同 | **空表建好** | step_02 |
| `related_party_raw` | 同 | **空表建好** | step_02 |
| `related_party_graph`（v2.3 新增）| 同 | **空表建好** | step_02 |
| `failed_ocr_pages` | 同 | **空表建好** | step_02 |
| `audit_log`（decision_gate 用） | 同 | **空表建好** | step_08 |
| Milvus `shareholder_announcements` collection | Milvus | **空 collection 建好**（dim=1024 HNSW + IP metric） | step_05 RAG |
| Neo4j 股权图 constraints | Neo4j | **建 constraint**：`(:Person)-[:CONTROLS]->(:Company)` + 唯一约束 `Person.name UNIQUE` / `Company.symbol UNIQUE` | step_06 |
| MinIO bucket `cryo-guard`（可选）| MinIO（D5 已起）| **空 bucket 建好**：prefix `cryo-guard/raw_pdfs/` / `cryo-guard/lora/` | step_02 PDF / step_04 LoRA |

### §3.2 6 张 SQLite 表 schema 简表（启动期）

| 表 | 关键列 | 约束 / 索引 |
|---|---|---|
| `financial_reports` | id PK / symbol VARCHAR(16) / report_year INT / report_type ENUM(annual/semi/q1/q3) / industry VARCHAR(64) / revenue/net_profit/cash/short_debt/long_debt/rd_expense/rd_capitalized NUMERIC(18,2) / raw_eastmoney TEXT(JSON) / created_at | `UNIQUE(symbol, report_year, report_type)`、`INDEX(industry)` |
| `announcements` | id PK / symbol / ann_date DATE / ann_type VARCHAR(32)（7 类）/ title VARCHAR(256) / url VARCHAR(512) / content TEXT / raw_json TEXT | `UNIQUE(symbol, ann_date, title)`、`INDEX(ann_type)` |
| `related_party_raw` | id PK / symbol / report_year / party_name VARCHAR(128) / relationship VARCHAR(128) / transaction_type VARCHAR(64) / pricing_method VARCHAR(64) / amount NUMERIC(18,2) NULL / raw_text TEXT / pdf_page_no INT | `INDEX(symbol, report_year)`、`INDEX(party_name)` |
| `related_party_graph` | id PK / symbol / party_name / parent_party VARCHAR(128) NULL / controller VARCHAR(128) NULL / source_pdf_page INT | `UNIQUE(symbol, party_name)` |
| `failed_ocr_pages` | id PK / symbol / report_year / page_no / pdf_path / error_reason TEXT | `INDEX(symbol, report_year)` |
| `audit_log`（decision_gate）| id PK / event_type VARCHAR(64) / event_id UNIQUE / prev_hash / hash / payload TEXT / created_at | step_08 哈希链审计；本步只建表 |

## §3.5 数据质量验收矩阵（工程基座 · 16 项）

本步无业务采集；矩阵以"5 服务可用 + ORM 完整 + 健康检查正确"为主。

### §3.5.1 服务可用

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| I1 | **FastAPI 起** | `:8081/health` 200 | ✅ | — |
| I2 | **vLLM Pod** | `:8000/v1/models` 返 base model（GPU 可用）；或返 stub | ✅ / ⚠️ stub | GPU 不可用 → stub（阻塞 step_04 训练）|
| I3 | **Milvus** | `:19530` 可连；pymilvus `connect()` 成功 | ✅ | docker compose 兜底 |
| I4 | **Neo4j** | `:7687` 可连；`cypher-shell "RETURN 1"` 返 1 | ✅ | 同上 |
| I5 | **Redis 共用 D0** | `redis-cli -n 1 PING` PONG | ✅ | — |

### §3.5.2 ORM & migration

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| I6 | **6 张表全建** | `.tables` 含 6 表名（含 `related_party_graph` + `audit_log`）| ✅ |
| I7 | **alembic 可重入** | upgrade 第二次 noop | ✅ |
| I8 | **FK / UNIQUE 完整** | `.schema announcements` 含 `UNIQUE(symbol,ann_date,title)` | ✅ |
| I9 | **Milvus collection 建** | dim=1024 HNSW IP metric；空 | ✅ |
| I10 | **Neo4j constraint 建** | `Person.name UNIQUE` / `Company.symbol UNIQUE` | ✅ |

### §3.5.3 工程配置 & no-mock

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| I11 | **`/health` 三段结构** | engines（3 stub）+ dependencies（4 项）+ upstream_streams（7 项） | ✅ |
| I12 | **`/api/decision-gate/health` initializing** | step_08 实启用前 status=initializing | ✅ |
| I13 | **GPU 降级显式** | `nvidia-smi` 失败时 `/health.engines.*.gpu="unavailable, stub mode"` | ✅ |
| I14 | **配置环境化** | NEO4J_PASSWORD / HF_TOKEN 不写死 | ✅ |
| I15 | **deploy-engine 自检** | 若改 `diting-infra/deploy-engine/` → 平级 `deploy-engine/` 仓库 push 再 `make update-deploy-engine` | ✅ §10 |
| I16 | **业务路径无 mock** | `rg "fake_lora\|stub_engine\|mock_decision" apps/cryo_guard/` = 0 | ✅ |

## §4 真实数据源与凭证清单

### §4.1 资源来源

| 资源 | 来源 | 备注 |
|---|---|---|
| Qwen2.5-7B-Instruct | Hugging Face | 首次下载 ~14GB，存到 `models/Qwen2.5-7B-Instruct/` |
| bge-m3 嵌入模型 | Hugging Face | RAG 检索用，~2GB，存到 `models/bge-m3/` |
| K3s | rancher/k3s 官方安装脚本 | `curl -sfL https://get.k3s.io \| sh -s -` |
| Milvus Standalone | `milvusdb/milvus:v2.4.x` | docker 起 + 19530 暴露 |
| Neo4j Community | `neo4j:5-community` | docker 起 + 7687 暴露 |

### §4.2 用户须提供的凭证

| 凭证 | 用途 | 何时需要 | 写在哪里 |
|---|---|---|---|
| `HF_TOKEN` | 从 HuggingFace 下载 Qwen2.5-7B 与 bge-m3 | 本步执行前 | `diting-src/.env` |
| `NEO4J_PASSWORD` | Neo4j 登录（默认 `diting123` 可改） | 本步执行前 | `diting-src/.env` |
| `WANDB_API_KEY` | step_04~06 训练监控 | step_04 执行前（本步可暂留） | `diting-src/.env` |

> **本步无需** Teacher LLM key（step_03 才用）；无需采集相关凭证（step_02 才用）。

## §5 启动期目标

### §5.1 资源范围
- **硬件**：单节点 RTX 4090（24GB 显存）一台；CUDA ≥ 12.1；Docker + containerd 可用。
- **服务实例**：单实例（无副本、无 HPA），仅本机或单台 ECS。
- **数据**：本步**不落业务数据**；只建空表 / 空 collection / 空图。

### §5.2 数据量预期（最低门槛 · 必要不充分）

| 指标 | 启动期最小值 | 验证命令 |
|---|---|---|
| ORM 表已建 | 5 张（`financial_reports / announcements / related_party_raw / failed_ocr_pages / 占位 audit_log`）| `sqlite3 data/cryo_guard.db ".tables"` |
| K3s Pod Running | cryo-guard + vllm + milvus + neo4j 4 个 | `kubectl get pods -n diting` |
| 健康检查响应 | 8081/health 200 + 8081/api/decision-gate/health 200 | `curl localhost:8081/health` |

### §5.3 可接受退化
- GPU 不可用 → vLLM 降级为 stub 模式（HTTP 200 + 假 response），**非阻塞** step_02~03（只阻塞 step_04 训练）；
- Milvus / Neo4j 起不来 → 仅本机 SQLite 仍允许 step_02 跑（step_05/06 才强制依赖）；
- Helm Chart 未准备 → 启动期 step_01 仅"docker compose + K3s yaml" 两种形态即可，Chart 在 step_07 补。

## §6 下一步（一行触发条件）

- **触发条件**：本步全部 ✅ → step_02 可开工（落 SQLite 业务表数据）。
- **下一阶段方向**：扩展期改为多副本、HPA、独立 GPU 节点池；详见 `stages/stage_2_扩展期/`。

## §7 实施规划（L3 设计 · 给后续执行模型的工作指引）

> **L3 定位**：本节是**设计规划 + 实现要点 + 验证标准**——靠谱地描述"做什么 / 如何执行"，**不嵌入完整 Dockerfile / Helm values / Makefile 实现代码**。具体命令、镜像 tag、yaml 字段填充由 L4 实践记录 / 后续执行模型按本节规划自行落地。

### §7.1 实现要点（按交付物拆分 · L4 / 后续模型按此逐项落地）

| 实现要点 | 涉及代码位置 | 关键设计决策 | 验证标准 |
|---|---|---|---|
| **A 项目骨架与依赖** | `diting-src/apps/cryo_guard/`、`pyproject.toml`、`tests/cryo_guard/` | 包结构：`api/{routes,middlewares}`、`db/{models,session,migrations}`、`engines/{financial_fraud,shareholder_integrity,related_party}/`、`decision_gate/{gate,audit_log,streams}`、`llm/{vllm_client,lora_manager}`、`rag/{embedder,milvus_store,retriever}`、`graph/neo4j_client.py`、`utils/`；依赖：fastapi / uvicorn / sqlalchemy / aiosqlite / alembic / redis / openai / pymilvus / neo4j / langgraph / pydantic-settings | `find apps/cryo_guard -name "*.py" \| wc -l` ≥ 25；`uv pip install -e .` 成功 |
| **B FastAPI 健康检查骨架** | `apps/cryo_guard/api/main.py`、`api/routes/health.py`、`api/routes/decision_gate.py`（占位）| `/health` 聚合 3 段：`engines`（3 个引擎 stub 状态）+ `dependencies`（vllm/milvus/neo4j/redis 健康）+ `upstream_streams`（7 个上游 stream 名称 + Redis 连通性）；`/api/decision-gate/health` 返 `status=initializing`（引擎未训练）| `curl localhost:8081/health` JSON 含 3 段；`curl localhost:8081/api/decision-gate/health` JSON status=initializing |
| **C 配置中心（pydantic-settings）** | `apps/cryo_guard/config.py` | 单例 `Settings`，按命名空间分组：`database / vllm / milvus / neo4j / redis / upstream_streams`；从 `.env` 自动加载；端口默认 8081；与 D0 共用 Redis 6379 | `from apps.cryo_guard.config import settings; print(settings.dict())` 输出可读 |
| **D ORM 与初始 migration** | `apps/cryo_guard/db/{models.py,session.py,init_db.py}`、`alembic/` | 5 张表初版（含 step_02 用到的 4 张 + audit_log 占位）；async engine + 同步 fallback；alembic autogenerate 一次 | `alembic upgrade head` 后 `.tables` 含 5 张 |
| **E K3s 单节点集群 + namespace** | 安装脚本（不写入仓 · 用文档指引）+ `deploy/k3s/namespace.yaml` | 单节点 K3s（traefik 启用）；namespace `diting`；本机或 ECS 单台 | `kubectl get nodes` 1 Ready；`kubectl get ns diting` 存在 |
| **F vLLM Pod / Service** | `deploy/k3s/vllm-deployment.yaml`、`deploy/k3s/vllm-service.yaml` | image `vllm/vllm-openai:latest`；启动参数：`--model /models/Qwen2.5-7B-Instruct --enable-lora --max-loras 4 --max-cpu-loras 4`；GPU 不可用时 image 改为 stub（FastAPI 假实现）；Service ClusterIP 8000 | `kubectl get pods -l app=vllm` Running；`curl vllm-svc:8000/v1/models` 返回 base model |
| **G Milvus Standalone Pod / Service** | `deploy/k3s/milvus-deployment.yaml`、`deploy/k3s/milvus-service.yaml` | image `milvusdb/milvus:v2.4.x`；持久卷 `/var/lib/milvus`；19530 ClusterIP | `kubectl get pods -l app=milvus` Running；`from pymilvus import connections; connections.connect()` 成功 |
| **H Neo4j Pod / Service** | `deploy/k3s/neo4j-deployment.yaml`、`deploy/k3s/neo4j-service.yaml` | image `neo4j:5-community`；持久卷 `/data`；7687 ClusterIP；初始密码从 Secret 读 | `kubectl get pods -l app=neo4j` Running；`cypher-shell -u neo4j -p $NEO4J_PASSWORD "RETURN 1;"` 返回 1 |
| **I Redis 复用 D0 实例** | `apps/cryo_guard/config.py` 配置 `redis_url=redis://redis-svc.diting:6379` | 与 D0 共用一个 Redis（节省资源）；只用不同 db index（D1 用 `db=1`，D0 用 `db=0`）| `redis-cli -n 1 PING` PONG |
| **J cryo-guard Deployment / Service** | `deploy/k3s/cryo-guard-deployment.yaml`、`deploy/k3s/cryo-guard-service.yaml` | image 从 ACR pull（本步可先 docker build + import 到 K3s 本地）；env 全部从 ConfigMap + Secret；readinessProbe = `/health`；livenessProbe = `/health` | `kubectl get pods -l app=cryo-guard` Running 1/1；外部 `curl <node-ip>:30081/health` 200 |
| **K 单元测试** | `tests/cryo_guard/test_health.py` | 测试用 httpx + fastapi TestClient：mock vllm/milvus/neo4j 客户端，验证 `/health` 三段结构、状态聚合逻辑、降级路径返回正确 stub 标记 | `pytest tests/cryo_guard/test_health.py -v` ≥ 6 passed |

### §7.2 Makefile 一键复现合约（L3 约定 · L4 / `diting-src/Makefile` 实现）

**设计目的**：架构师**改 `.env`** 或 K3s 资源（GPU 节点 IP / Milvus 持久卷 size 等）后跑**一条命令** `make cryo-step01-all` 完成"骨架建仓 → 镜像 build → K3s apply → 健康检查 → 单测"全套。

**target 合约表**（L3 此处只定义合约 · 实现交 L4 / `diting-src/Makefile`）：

| target | 用途（一句话） | 入参（环境变量 · 均有默认） | 验证标准 |
|---|---|---|---|
| `make cryo-step01-skeleton` | 创建项目目录骨架 + `pyproject.toml` + 空 `__init__.py` | — | `find apps/cryo_guard -name "*.py" \| wc -l` ≥ 25 |
| `make cryo-step01-deps` | `uv pip install -e .` + 验证关键 import | `PYTHON_VERSION` | `python -c "import fastapi, vllm, pymilvus, neo4j"` 成功 |
| `make cryo-step01-db-init` | alembic upgrade + 创建 5 张表 | `DATABASE_URL` | `sqlite3 data/cryo_guard.db ".tables"` 5 张 |
| `make cryo-step01-k3s-up` | K3s 单节点 + namespace + 4 个 deployment apply | `KUBECONFIG / NEO4J_PASSWORD / HF_TOKEN` | 4 个 Pod 全 Running |
| `make cryo-step01-health` | 全栈健康检查（vllm/milvus/neo4j/redis/cryo-guard）| — | 5 个 endpoint 200 |
| `make cryo-step01-test` | 单测 | — | `pytest tests/cryo_guard/test_health.py -v` ≥ 6 passed |
| `make cryo-step01-all` | **端到端一键**（含上述 6 步顺序串联） | 同上合并 | 全部退出码 0；冷启动 ≤ 25 min（首次拉镜像 + 下 Qwen） |
| `make cryo-step01-status` | 数据量进度快照（只读） | — | 打印 5 张表存在性 + 4 Pod 状态 + 5 endpoint 健康 |
| `make cryo-step01-down` | 关掉 K3s 资源（保留持久卷） | — | `kubectl get pods -n diting` 全 Terminating |
| `make cryo-step01-clean` | 清掉镜像 / 持久卷 / SQLite | — | 全清；**不**清 `models/` 下载的 Qwen / bge-m3（避免重下） |

**合约要求**（L4 实现时必须遵守）：
1. **入参全部环境变量化**：`.env` 优先，命令行覆盖；
2. **target 是薄包装**：K3s 资源用 `kubectl apply -f deploy/k3s/`；构建用 docker buildx；不在 Makefile 写业务逻辑；
3. **可重入幂等**：重跑 `cryo-step01-all` 不破坏已有 Pod / 表（用 `kubectl apply` 而非 create；alembic upgrade head 而非 revert）；
4. **GPU 降级显式**：检测到 `nvidia-smi` 失败时自动切 stub vLLM 镜像，日志中文写明"已降级为 stub 模式（step_04 训练阻塞）"；
5. **失败可观察**：每个 target 输出"做了什么 / 期望什么 / 实际什么"3 行中文摘要。

### §7.3 关键配置片段（中间道 · 非完整代码）

#### 7.3.1 `/health` 响应 JSON 示例（三段结构）

```json
{
  "service": "cryo-guard", "status": "ok",
  "engines": {
    "financial_fraud":      {"loaded": false, "stub": true, "reason": "no LoRA yet (step_04)"},
    "shareholder_integrity":{"loaded": false, "stub": true, "reason": "no LoRA yet (step_05)"},
    "related_party":        {"loaded": false, "stub": true, "reason": "no LoRA yet (step_06)"}
  },
  "dependencies": {
    "vllm":  {"ok": true, "gpu": "RTX 4090", "model": "Qwen2.5-7B-Instruct"},
    "milvus":{"ok": true, "collections": ["shareholder_announcements"]},
    "neo4j": {"ok": true, "version": "5.x", "constraints": 2},
    "redis": {"ok": true, "db": 1}
  },
  "upstream_streams": {
    "events:monitor:health_change":   {"ok": true, "length": 0, "reason": "stream not found (mock mode)"},
    "events:thrust:thesis_proposed":  {"ok": true, "length": 0},
    "events:flywheel:lora_updated":   {"ok": true, "length": 0},
    "events:exit:sell_signal":        {"ok": true, "length": 0},
    "events:cryo_guard:pass":         {"ok": true, "length": 0, "self_produced": true},
    "events:cryo_guard:reject":       {"ok": true, "length": 0, "self_produced": true},
    "events:cryo_guard:degrade":      {"ok": true, "length": 0, "self_produced": true}
  }
}
```

#### 7.3.2 vLLM K3s deployment 关键字段（指引而非全文）

```yaml
spec:
  containers:
    - name: vllm
      image: vllm/vllm-openai:v0.6.x
      args:
        - "--model=/models/Qwen2.5-7B-Instruct"
        - "--enable-lora"
        - "--max-loras=4"
        - "--max-cpu-loras=4"
        - "--port=8000"
      resources:
        limits: { nvidia.com/gpu: 1 }
      env:
        - name: HF_HOME
          value: /models
      volumeMounts:
        - { name: models, mountPath: /models }
```

GPU 不可用时 `image` 改为 `diting/cryo-vllm-stub:dev`（一个 FastAPI 假实现，`/v1/models` 返 base、`/v1/completions` 返 stub）。

#### 7.3.3 ORM 6 表 alembic migration 入口（核心算法 ~12 行）

```python
def upgrade():
    op.create_table("financial_reports",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("symbol", sa.String(16), nullable=False),
        sa.Column("report_year", sa.Integer, nullable=False),
        sa.Column("report_type", sa.String(16), nullable=False),
        sa.Column("industry", sa.String(64)),
        sa.Column("revenue", sa.Numeric(18, 2)),
        # ... 其它列见 §3.2 ...
        sa.UniqueConstraint("symbol","report_year","report_type", name="uq_fin_rep"),
        sa.Index("ix_fin_industry","industry"),
    )
    # ... announcements / related_party_raw / related_party_graph
    # ... failed_ocr_pages / audit_log ...
```

#### 7.3.4 健康检查聚合算法（核心 ~15 行）

```python
async def health() -> dict:
    results = await asyncio.gather(
        check_vllm(), check_milvus(), check_neo4j(), check_redis(),
        return_exceptions=True,
    )
    deps = {k: ({"ok": False, "reason": str(v)} if isinstance(v, Exception) else v)
            for k, v in zip(["vllm","milvus","neo4j","redis"], results)}
    streams = await check_upstream_streams(settings.upstream_streams)
    engines = {name: {"loaded": False, "stub": True, "reason": f"no LoRA yet (step_{4+i})"}
               for i, name in enumerate(["financial_fraud","shareholder_integrity","related_party"])}
    status = "ok" if deps["vllm"]["ok"] or deps.get("vllm",{}).get("stub") else "degraded"
    return {"service": "cryo-guard", "status": status,
            "engines": engines, "dependencies": deps, "upstream_streams": streams}
```

### §7.4 给后续执行模型的指引

L4 / 执行模型在本步落地时**按以下顺序**，**不偏离 §7.1 + §7.2**：

1. **核对前置**：`.env` 含 `HF_TOKEN / NEO4J_PASSWORD`；Docker + nvidia-smi 可用；
2. **逐项落地 A~K**：每项产出独立可跑；
3. **集成 Makefile**：10 target，过 `make cryo-step01-all`；
4. **§9 准出清单逐项打勾** + 同会话证据；
5. **回写 L4**：GPU 是否降级、首次镜像下载耗时、commit hash、`/health` 完整 JSON；
6. **永久规则审计**：`rg "fake_lora|stub_engine|mock_decision" apps/cryo_guard/` = 0；
7. **遇问题**：先 Verify First（`kubectl describe pod / kubectl logs`）再改；同问题 ≥ 2 次失败按 §8.4f。

> **L3 责任边界**：本节给规划 + 实现要点 + 验证标准 + 关键片段；**不**给完整 Dockerfile / Helm Chart / K8s yaml 字段；具体落地交 L4。

## §8 部署节奏（本步在哪里跑）

| 阶段 | 形态 | 是否本步必须 | 说明 |
|---|---|---|---|
| **本机开发** | `python -m apps.cryo_guard.api.main` + `pytest` | **必须** | 项目骨架、ORM、FastAPI、单测在本机完成 |
| **本机 docker-compose** | （可选） `docker compose -f deploy/docker-compose/cryo-guard.yml up` | 否（备选） | 当 K3s 起不来时用 compose 兜底 |
| **Dev K3s（本地单节点 K3s）** | `kubectl apply -f deploy/k3s/` | **必须** | 启动期目标运行时（ECS 单台 + K3s 单节点） |
| **ACR + 生产 K3s** | （扩展期）`make publish-cryo-guard` → `helm upgrade` | 否 | 启动期仅本机 + Dev K3s 即可；扩展期接 ACR + deploy-engine |

**本步默认运行形态**：本机开发 + Dev K3s（单节点）。镜像本地 build + `k3s ctr images import` 导入（避免依赖 ACR）。

## §9 准出标准（同会话可执行清单）

### §9.1 项目骨架与依赖
- [ ] `find apps/cryo_guard -name "*.py" \| wc -l` ≥ 25
- [ ] `python -c "import fastapi, vllm, pymilvus, neo4j, langgraph"` 成功（GPU 不可用时允许 `vllm` 缺，但日志说明）

### §9.2 ORM 与数据库
- [ ] `sqlite3 data/cryo_guard.db ".tables"` 含 `financial_reports / announcements / related_party_raw / failed_ocr_pages / audit_log` 5 张
- [ ] `alembic current` 输出最新 revision id

### §9.3 K3s 与服务
- [ ] `kubectl get nodes` Ready
- [ ] `kubectl -n diting get pods` 含 `cryo-guard / vllm / milvus / neo4j` 4 个 Running（Redis 与 D0 共用，名为 `redis`）
- [ ] `curl <node-ip>:30081/health` 200，JSON 含 `engines / dependencies / upstream_streams` 三段
- [ ] `curl <node-ip>:30081/api/decision-gate/health` 返 `status=initializing`

### §9.4 工程交付 + 一键复现
- [ ] **Makefile 合约落地**（§7.2）：10 个 target 全部已实现，`make cryo-step01-all` 端到端通过；冷启动 ≤ 25 min
- [ ] **可重入验证**：连跑两次 `make cryo-step01-all`，第二次 ≤ 3 min（仅健康检查 + 单测，不重拉镜像、不重 apply）
- [ ] `pytest tests/cryo_guard/test_health.py -v` ≥ 6 passed
- [ ] L4 实践记录 `04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_01_环境与基础设施.md` 已按 §8.4g 更新"二、实际进展"为已核验准出（含 GPU 是否降级、镜像 size、Pod logs 摘要）
- [ ] commit：`feat(cryo-guard): step_01 基础设施 + 服务骨架 + Makefile 一键复现 [Ref: 03_/01_维度一/.../step_01]`
- [ ] **同会话验证**：上述命令在当次会话执行并输出摘要（按 `00_系统规则` §7.2 第 10/11 条）

## §10 [Deploy] 段

**本步必涉镜像 / Chart / K8s yaml**。遵循 [L3 步骤·部署价值哲学·必选引用](../../../../_共享规约/L3步骤文档_部署价值哲学_必选引用.md) 与 [16 · ECS+K3s+ACR+Helm 链路](../../../../_共享规约/16_阿里云ECS_K3s_ACR_Helm部署与deploy-engine链路.md)：

| 内容 | 位置 | 启动期边界 |
|---|---|---|
| 镜像（`cryo-guard`）build | `diting-src/deploy/docker/Dockerfile` | 本机 build → `k3s ctr images import`；扩展期再推 ACR |
| K3s yaml | `diting-src/deploy/k3s/` 5 份 deployment + 5 份 service + 1 份 namespace + 1 份 configmap + 1 份 secret | 启动期足够；扩展期改 Helm Chart |
| Helm Chart | （扩展期才建）`diting-infra/charts/cryo-guard/` | 本步**不**做；启动期用裸 yaml |

**deploy-engine 自检**（强制）：本步若改 `diting-infra/deploy-engine/`，**必须**在与 diting-infra 平级的独立 `deploy-engine/` 仓库内修改、commit、push，再在 diting-infra 执行 `make update-deploy-engine`。**禁止**在 diting-infra 子模块拷贝内做任何写操作（含 stash）。

## §11 依赖与被依赖

**上游**：
- 无（本 step 是 D1 启动期入口）；
- 但**需要用户准备**：① 一台单 RTX 4090 24GB 的 ECS 或本机 ② Docker + nvidia-container-toolkit ③ HF_TOKEN ④ NEO4J_PASSWORD。

**下游**（本步产出被消费）：
- `step_02` 数据采集：依赖 SQLite ORM 表已建；
- `step_03` Teacher 蒸馏：依赖 `apps/cryo_guard/distillation/` 包结构；
- `step_04~06` LoRA 训练：依赖 vLLM Pod + GPU；
- `step_07~10` 服务部署 / 评测 / 验收：依赖 K3s 集群 + 所有依赖服务可达。

**严禁伪造**（no-mock-policy）：vLLM GPU 不可用时**允许 stub**（明确标注 stub_mode），**不允许**伪造 Milvus / Neo4j 响应；这两者必须实际起来或本步不算准出。

## §12 风险与回退

| 触发条件 | 动作 |
|---|---|
| GPU 节点不可用 | vLLM 降级为 stub（HTTP 200 + 假 response），日志中文写明；step_04 训练阻塞但 step_02/03 可继续 |
| Milvus / Neo4j 镜像拉取失败 | 切国内镜像源（阿里云镜像 / 网易镜像）；超时 ≥ 2 次仍失败 → ADR 走架构师裁决 |
| K3s traefik 端口冲突 | 改 NodePort 区间或禁用 traefik；本步**不**强制走 traefik |
| `pyproject.toml` 依赖冲突 | 先排出冲突包（pip-tools / uv compile）；超时 ≥ 2 次失败 → 回收并明确未达项 |
| 同一问题修复重试 ≥ 2 次仍失败 | 按 `00_系统规则` §8.4f 回收：在 L4 实践记录"问题与风险"中说明 + 提 ADR |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v3 中间道细化**：保留 v1.2/v2.3 三件套；新增 §3.1 9 项资源详表（含 MinIO bucket）、§3.2 6 张 SQLite 表 schema 简表（含 `related_party_graph` / `audit_log`）；§3.5 从"不适用"细化为 16 项工程基座质量；§7.3 新增 4 个关键片段（`/health` JSON 三段示例 / vLLM K3s deployment 关键字段 / alembic migration 入口 / 健康检查聚合算法）；229→~470 行 |
| 2026-05-20 | **v2 按新 L3 启动期 step 模板（v1.2）重写**（关键重构，与 `00_系统规则` §4.5 同步）：①删除全部完整 Dockerfile / K8s yaml 嵌入代码；②§7 改为"实施规划"三段式（§7.1 实现要点 11 项 + §7.2 Makefile 合约 10 个 target + §7.3 给后续执行模型指引）；③§3 / §3.5 标明"本步不涉及数据采集"；④§9 准出加 Makefile 合约落地 + 可重入验证；⑤§10 [Deploy] 加 deploy-engine 自检约束。从 1057 行 → ~210 行 |
| 2026-05-16 | 初版（含完整 Dockerfile / K8s yaml / Python 代码块），1057 行 |
