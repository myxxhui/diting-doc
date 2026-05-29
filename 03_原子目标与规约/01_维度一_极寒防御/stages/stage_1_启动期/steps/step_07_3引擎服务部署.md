# Step 07 · 3 引擎服务部署（vLLM multi-lora + FastAPI 路由 + LangGraph）

## §1 一句话定位与本步交付物

**一句话**：把 step_04/05/06 训出来的 3 个 LoRA + 3 个 LangGraph 引擎装进 vLLM multi-lora 热加载 + FastAPI 三路由 + K3s Deployment，让 step_08 decision_gate 能通过 HTTP 调用 3 个引擎拿到统一的 `EngineOutput` 结构。

**交付物**（勾选 = 完成）：
- [ ] **A**（vLLM multi-lora 启动）：`scripts/start_vllm.sh` 一键启动；`curl http://vllm-svc:8000/v1/models` 含 base model + `financial_fraud_lora_v1 / shareholder_lora_v1 / related_party_lora_v1` 共 4 条
- [ ] **B**（per-request LoRA 客户端）：`apps/cryo_guard/llm/vllm_client.py` 支持单次请求指定 `lora_name`，并发请求不污染全局状态
- [ ] **C**（3 FastAPI 路由）：`POST /api/engines/financial_fraud/check` / `/shareholder_integrity/check` / `/related_party/check` 均返回 `EngineOutput`，缺字段 422
- [ ] **D**（LangGraph 编排）：每路由调用 step_04/05/06 的 engine.run()；同 `request_id` 重入幂等（Redis 缓存 5 min）
- [ ] **E**（K3s 部署）：`cryo-guard / vllm` 两 Deployment + 两 Service，含 readinessProbe / livenessProbe；`kubectl apply -f deploy/k3s/` 后两 Pod Running 1/1
- [ ] **F**（健康检查聚合）：`/health` 返 `engines` 段含 3 个引擎 `lora_loaded=True`
- [ ] **G**（端到端集成测试）：`scripts/e2e_verify_step07.sh` 跑 1 个真实标的过 3 路由 → 3 个 EngineOutput 全返
- [ ] **H**（压测）：`hey -n 30 -c 3 -m POST` P95 < 5 s（GPU 单卡）
- [ ] **I**（单测）：`pytest tests/cryo_guard/test_api_engines.py -v` ≥ 7 passed
- [ ] **J**（Makefile 一键复现）：`make cryo-step07-all` 端到端通过

> **本步是 step_08 的硬阻塞**：decision_gate 通过 HTTP 调用 3 个引擎路由聚合结果；本步不通则 step_08 起不来。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2 哲学**：[01_维度一_极寒防御 · 04_防御实践策略规划](../../../../../02_战略维度/01_维度一_极寒防御/04_防御实践策略规划.md)
> - **本阶段总览**：[stage_1_启动期/README](../README.md)
> - **L3 技术架构**：[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §四 API 设计、§五 部署架构（K3s + vLLM）
> - **L3 模型训练**：[../04_模型训练与部署.md](../04_模型训练与部署.md) §6.2 vLLM 部署命令、§6.4 K8s 部署 yaml
> - **L3 验收**：[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md) §3.1/3.2 服务可用性、§五 性能验收
> - **DNA 键**：`_System_DNA/01_cryo_guard/dna_stage_1_启动期.yaml` → `deliverables.engines`、`service_name=cryo-guard`、`verification_commands`
> - **共享规约**：[L3 步骤·部署价值哲学·必选引用](../../../../_共享规约/L3步骤文档_部署价值哲学_必选引用.md) · [16 · ECS+K3s+ACR+Helm+deploy-engine 链路](../../../../_共享规约/16_阿里云ECS_K3s_ACR_Helm部署与deploy-engine链路.md) · [13_六维度启动期集成与时序](../../../../_共享规约/13_六维度启动期集成与时序.md) §六 维度一对外契约
> - **L4 实践记录**：[实践记录_step_07_3引擎服务部署.md](../../../../../04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_07_3引擎服务部署.md)
> - **上游 step**：← step_04（financial_fraud_lora_v1）、step_05（shareholder_lora_v1）、step_06（related_party_lora_v1）
> - **下游 step**：→ step_08（decision_gate HTTP 调本步 3 路由）、step_09（综合 Holdout 评测调本步 3 路由）

## §3 数据采集对象 / 落库映射

**本步不采集数据**——仅消费 3 个 LoRA + 3 个 engine 包，对外暴露 HTTP API。

| 数据流向 | 来源 / 落库 | 用途 |
|---|---|---|
| 3 LoRA adapter | step_04/05/06 `output/*_lora_v1/` | vLLM PVC 挂载到 `/loras/{financial_fraud,shareholder,related_party}/` |
| 3 engine 包 | step_04/05/06 `apps/cryo_guard/engines/` | FastAPI 路由 import + LangGraph 调用 |
| 请求幂等缓存 | Redis db=1（与 D0 共用实例不同 db） | `request_id` → EngineOutput 缓存 5 min |
| 请求审计日志 | `apps/cryo_guard/api/middlewares/audit.py` → SQLite `audit_log` | 请求 / 响应 / 耗时落库（供 step_08 decision_gate 复用） |

## §3.5 数据质量验收矩阵（按 step_08/09 需求反推 · 仅启动期负责）

> **本步范围**：vLLM 多 LoRA 加载 + 3 路由响应 + LangGraph 编排 + K3s 部署四个环节。每行 ✅ 或 ⚠️。**不**列扩展期内容（如 HPA / 多副本）。

### §3.5.1 vLLM multi-lora 加载质量

| # | 维度 | 必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| V1 | **3 LoRA 全部 loaded** | `/v1/models` 返回 4 条（base + 3 LoRA），各 LoRA `status=loaded` | ⚠️ 启动期 24GB 显存边界；OOM 时切串行加载 | OOM → 降为单 LoRA 模式，按需切换 + 标 `lora_mode=serial` |
| V2 | **per-request LoRA 切换** | 同进程并发 3 请求各指定不同 `lora_name`，结果不串扰 | ✅ vLLM ≥ 0.4 原生支持 | 失败时检查 vLLM 版本 |
| V3 | **首次冷加载延迟** | 单 LoRA 冷加载 < 30 s | ✅ rank=16 adapter ~60MB | OOM 后再加载会超时 → 重启 Pod |
| V4 | **LoRA 名与训练产物一致** | 名字严格 = `financial_fraud_lora_v1 / shareholder_lora_v1 / related_party_lora_v1` | ✅ 启动脚本枚举 + 校验 | 名字不匹配 → 启动失败 + 中文日志说明 |

### §3.5.2 3 FastAPI 路由质量

| # | 路由 | 必产字段（EngineOutput）| 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| R1 | **`POST /api/engines/financial_fraud/check`** | `request_id / engine_name / label / confidence / risk_level / category / evidence[] / reason_zh / latency_ms / lora_loaded` | ✅ Pydantic v2 强校验 | 缺字段 422 |
| R2 | **`POST /api/engines/shareholder_integrity/check`** | 同上 + `retrieved_announcements[]`（RAG 来源） | ✅ | 同 |
| R3 | **`POST /api/engines/related_party/check`** | 同上 + `cypher_paths[]`（图路径） | ✅ | 同 |
| R4 | **请求体统一 schema** | 三路由均接 `{request_id, symbol, report_period?, extra?}`；symbol 校验合法 A 股代码 | ✅ Pydantic | symbol 非法 422 |
| R5 | **同 request_id 幂等** | 同 `request_id` 5 min 内重复请求 → Redis 命中返同一 EngineOutput | ✅ middleware 实现 | Redis 不可用降级"每次重算 + 标 `idempotent_cache=miss`" |

### §3.5.3 LangGraph 编排质量

| # | 维度 | 必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| L1 | **engine.run() 返 Prediction** | 与 step_04/05/06 schemas.py 完全一致 | ✅ 直接 import 子包 | schema 漂移 → CI 失败 |
| L2 | **节点失败可恢复** | 单节点抛异常 → LangGraph 捕获 → 返回 EngineOutput 标 `partial=True + failed_node=<name>` | ⚠️ 启动期最小实现 | 完全失败仍返 EngineOutput 但 confidence=0 |
| L3 | **超时熔断** | 单 engine 总超时 30 s；超时返 timeout EngineOutput | ⚠️ 启动期 30 s 含 RAG + 图查询 | 超时频发 → 改 60 s + ADR |

### §3.5.4 K3s 部署质量

| # | 维度 | 必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| K1 | **cryo-guard Deployment** | replicas=1，resource requests/limits 设置（cpu 1/2, mem 2Gi/4Gi）；readinessProbe = `/health`；livenessProbe = `/health` | ✅ K3s 单节点 | 资源不足按需调整 |
| K2 | **vllm Deployment** | replicas=1，GPU 节点亲和；`--enable-lora --max-loras 4`；PVC 挂载 `/loras/` 三子目录 | ⚠️ GPU 不可用降级 stub | step_01 已有 stub 路径，本步继承 |
| K3 | **2 Service 内通信** | `cryo-guard-svc:8081`、`vllm-svc:8000` ClusterIP；NodePort 30081 暴露 cryo-guard 测试用 | ✅ | — |
| K4 | **健康检查聚合** | `/health` engines 段含 3 LoRA loaded 状态 + dependencies 段含 vllm/milvus/neo4j/redis | ✅ step_01 已建框架，本步补 engines | 某项失败标 `status=degraded` |

> 共 **16 项启动期质量要求**（V1~V4 vLLM / R1~R5 路由 / L1~L3 LangGraph / K1~K4 K3s）。矩阵中**无 ❌**。

### §3.5.5 质量门槛（合并到 §9.2）

矩阵每行须满足之一：
- **✅ 覆盖**：本步已实现且抽样验证通过；
- **⚠️ 启动期降级**：明确降级路径 + 在该降级下 step_08 仍能调用本步 3 路由。

**禁止**：①LoRA 未加载用 base model 假装 EngineOutput；②K3s yaml 写死镜像 tag 不走 ConfigMap；③健康检查永远返 ok 不真实聚合。

## §4 真实数据源与凭证清单

### §4.1 资源

| 资源 | 来源 | 备注 |
|---|---|---|
| 3 LoRA adapter | step_04/05/06 产出 | 通过 dvc pull 或 PVC 挂载 |
| vLLM image | `vllm/vllm-openai:latest` | step_01 已就绪 |
| Qwen2.5-7B-Instruct 基模 | step_01 下载 + PVC 挂载 | ~14GB |
| Redis | step_01 已起（D0 共用） | db=1 |

### §4.2 用户须提供的凭证

| 凭证 | 用途 | 何时需要 | 写在哪里 |
|---|---|---|---|
| `KUBECONFIG` | K3s apply 权限 | 部署前 | 默认 `~/.kube/config` |
| `IMAGE_REGISTRY`（启动期可空） | 镜像仓库；启动期本地 build + `k3s ctr import` 可不用 | 部署前 | `.env` |

> **本步无新增模型 / 数据凭证**（vLLM / Milvus / Neo4j 在前置 step 已配）。

## §5 启动期目标

### §5.1 关键设计

| 项 | 取值 | 理由 |
|---|---|---|
| vLLM 启动参数 | `--model /models/Qwen2.5-7B-Instruct --enable-lora --max-loras 4 --max-cpu-loras 4` | 4090 24GB 可同时 hot 3 LoRA + base |
| per-request LoRA | 调用 vLLM `/v1/chat/completions` 时传 `model=<lora_name>` | 不修改 client 全局态 |
| FastAPI 路由前缀 | `/api/engines/{financial_fraud,shareholder_integrity,related_party}` | step_08 decision_gate 按约定调用 |
| 请求幂等 | Redis db=1 `cryo:idem:{request_id}` 5 min | step_08 重放安全 |
| LangGraph 超时 | 30 s | 含 RAG + 图查询 |
| 健康检查 | `/health` 聚合 engines + dependencies；启动期单实例 | step_01 已建框架 |
| K3s 资源 | cpu 1/2，mem 2Gi/4Gi，单实例 | 启动期单 ECS |

### §5.2 性能门槛

| 指标 | 启动期门槛 | 说明 |
|---|---|---|
| 单引擎请求 P50 | < 3 s | GPU 单卡 |
| 单引擎请求 P95 | < 5 s | 同 |
| 3 引擎串行总耗时 | < 12 s | step_08 decision_gate 上限 |
| QPS（3 并发） | ≥ 0.5 | `hey -n 30 -c 3` |
| LoRA 冷加载 | < 30 s | 首次 |

### §5.3 可接受退化

- 24GB 显存不足同时挂 3 LoRA → 切串行加载（`--max-loras 1` + 切换时 unload）；
- K3s 起不来 → 切 `docker compose up`（仍提供同 3 路由）；
- vLLM crash → cryo-guard 健康检查标 degraded，路由返 503，不假装 200。

## §6 下一步（一行触发条件）

- **触发条件**：本步全部 ✅ + 3 路由真实标的可调通 → step_08（decision_gate）可开工。
- **下一阶段方向**：扩展期接 HPA + 多副本 + GPU 节点池；Chart 化；详见 `stages/stage_2_扩展期/`。

## §7 实施规划（L3 设计 · 给后续执行模型的工作指引）

> **L3 定位**：本节是**设计规划 + 实现要点 + 验证标准**——**不嵌入完整 K8s yaml / Python 路由代码 / vLLM 启动脚本**。具体落地由 L4 实践记录 / 后续执行模型按本节规划自行完成。

### §7.1 实现要点（按交付物拆分）

| 实现要点 | 涉及代码位置 | 关键设计决策 | 验证标准 |
|---|---|---|---|
| **A vLLM 启动脚本** | `scripts/start_vllm.sh` + `deploy/k3s/vllm-deployment.yaml` | 启动参数：`--enable-lora --max-loras 4 --max-cpu-loras 4 --max-model-len 4096`；PVC 挂载 `/loras/` 三子目录；GPU 节点亲和 | `curl :8000/v1/models` 返 4 条 |
| **B per-request LoRA 客户端** | `apps/cryo_guard/llm/vllm_client.py` | 单例 `httpx.AsyncClient`；`async chat_completion(messages, lora_name)` 在请求体里指定 `model=lora_name`；并发安全（不持有全局 lora 状态） | 并发测试 3 不同 lora_name 不串扰 |
| **C EngineOutput schema** | `apps/cryo_guard/api/schemas.py` | Pydantic v2：`request_id / engine_name / label / confidence / risk_level / category / evidence[] / reason_zh / latency_ms / lora_loaded / partial / failed_node`；三引擎扩展字段（retrieved_announcements / cypher_paths）作可选 | 三路由响应通过 schema |
| **D 三引擎路由** | `apps/cryo_guard/api/routes/engines.py` | 三路由薄封装：①Pydantic 校验入参；②调 step_04/05/06 的 `engine.run(symbol, period)`；③包装为 EngineOutput；④走幂等 middleware；超时控制 30 s | 三路由各返 EngineOutput |
| **E 幂等 middleware** | `apps/cryo_guard/api/middlewares/idempotency.py` | 入参含 request_id → Redis `cryo:idem:{request_id}` 查；命中返缓存；未命中执行后写入 TTL=5 min；Redis 不可用降级直通 + header 标 `X-Idempotent: miss` | 单测同 request_id 二次调 Redis 命中 |
| **F 审计 middleware** | `apps/cryo_guard/api/middlewares/audit.py` | 每请求落 `audit_log` 表：request_id / route / payload_hash / response_hash / latency_ms / status_code | step_08 可查 audit_log 复用 |
| **G LangGraph 节点失败处理** | 在每个 engine.py 的 LangGraph 内加 try/except + state 标 `failed_node` | 单节点失败 → 返 EngineOutput partial=True；不让整个请求挂掉 | 单测主动让 1 节点抛 → EngineOutput 返 partial |
| **H FastAPI 主程序注册** | `apps/cryo_guard/api/main.py` | 注册三路由 + 两 middleware + 启动时 vLLM 健康检查；`/health` 聚合 engines（3 LoRA loaded 状态）+ dependencies | `/health` 含 4 段 |
| **I cryo-guard Deployment** | `deploy/k3s/cryo-guard-deployment.yaml` | image 本地 build + `k3s ctr import`；env 从 ConfigMap + Secret；replicas=1；探针 `/health` initialDelay=20 s | `kubectl get pods` Running 1/1 |
| **J 2 Service** | `deploy/k3s/{cryo-guard-svc,vllm-svc}.yaml` | ClusterIP `:8081/:8000`；cryo-guard 加 NodePort 30081 供本机调测 | `kubectl get svc` 2 条 |
| **K e2e 验证脚本** | `scripts/e2e_verify_step07.sh` | 取 1 个 active 标的 → 调 3 路由 → 三 EngineOutput 全返且 confidence > 0 | 退出码 0 |
| **L 压测脚本** | `scripts/load_test_step07.sh` | `hey -n 30 -c 3 -m POST -T 'application/json' -d @payload.json` 跑三路由 | P95 < 5 s |
| **M 单测** | `tests/cryo_guard/test_api_engines.py` | 覆盖：①三路由 Pydantic 校验；②mock engine.run() 返 EngineOutput；③mock Redis 验幂等；④节点失败 partial；⑤超时 503 | `pytest -v` ≥ 7 passed |

### §7.2 Makefile 一键复现合约（L3 约定 · L4 实现）

**设计目的**：3 LoRA 就绪后跑 `make cryo-step07-all` 完成"vLLM 起 + cryo-guard build + apply → 路由可调 → 压测 → 单测"全套。

**target 合约表**：

| target | 用途 | 入参（环境变量 · 均有默认） | 验证标准 |
|---|---|---|---|
| `make cryo-step07-prep` | LoRA 自检（3 adapter 存在）+ Redis/Milvus/Neo4j 就绪 | `KUBECONFIG` | 3 LoRA 文件 + 4 依赖 OK |
| `make cryo-step07-build` | docker build cryo-guard 镜像 + `k3s ctr import` | `IMAGE_TAG=step07-$(git rev-parse --short HEAD)` | 镜像在 k3s ctr 可见 |
| `make cryo-step07-vllm-up` | apply vllm-deployment.yaml + 等就绪 | — | `curl :8000/v1/models` 4 条 |
| `make cryo-step07-apply` | apply cryo-guard-deployment.yaml + 2 Service | — | `kubectl get pods` 2 Running |
| `make cryo-step07-health` | 全栈健康检查 `/health` | — | engines.lora_loaded 全 true |
| `make cryo-step07-e2e` | e2e 三路由验证 1 真标的 | `TEST_SYMBOL` | 退出码 0；3 EngineOutput |
| `make cryo-step07-load` | 压测 P95 | `LOAD_N=30 LOAD_C=3` | P95 < 5 s |
| `make cryo-step07-test` | 单测 | — | `pytest -v` ≥ 7 passed |
| `make cryo-step07-all` | **端到端一键** | 同上合并 | 全部退出码 0；冷启动 ≤ 15 min |
| `make cryo-step07-status` | 进度快照（只读） | — | 打印 LoRA loaded / Pod 状态 / 最近压测指标 |
| `make cryo-step07-down` | 删 cryo-guard + vllm Deployment（保留 LoRA PVC）| — | Pod 全 Terminating |
| `make cryo-step07-clean` | 清镜像 + audit_log | — | 已清；**不**删 LoRA / 基模 |

**合约要求**：
1. **入参环境变量化**；镜像 tag 从 git short hash 自动生成；
2. **target 是薄包装**：apply 用 `kubectl apply -f`；build 用 docker buildx；
3. **可重入幂等**：`apply` 走 declarative，重跑不破坏；二次 `all` 跳过 build（hash 未变）；
4. **降级显式**：vLLM OOM 时启动脚本输出"已降级为 max_loras=1 + 串行切换"中文日志；
5. **失败可观察**：每个 target 中文 3 行摘要 + Pod 关键 logs 摘要。

### §7.3 给后续执行模型的指引

L4 / 执行模型按以下顺序：

1. **核对前置**：step_04/05/06 三 LoRA 全部 passed + `output/*_lora_v1/adapter_model.safetensors` 就绪；step_01 K3s + Redis OK；
2. **逐项落地 A~M**：建议顺序 C→B→D→E→F→G→H→A→I→J→K→L→M（schema/client 先于路由先于部署）；
3. **集成 Makefile**：按 §7.2 实现 12 个 target；
4. **冷启动顺序**：先 `vllm-up`（占 GPU），再 `apply`（cryo-guard 依赖 vllm）；
5. **e2e + 压测必跑**：仅 health 检查不能算准出；
6. **§9 准出 + L4 回写**：vLLM LoRA 加载耗时、P50/P95、并发上限、commit hash；
7. **遇问题**：vLLM OOM → 切串行；K3s CrashLoop → docker compose 备选；超时 → 排查具体节点 + 延长到 60 s + ADR；同问题 ≥ 2 次失败 § 8.4f 回收。

> **L3 责任边界**：本节给规划 + 实现要点 + 验证标准；**不**给完整 K8s yaml 字段值 / Python 路由实现 / vLLM 启动 bash；具体落地交给 L4 实践记录 / 后续执行模型。

## §8 部署节奏（本步在哪里跑）

| 阶段 | 形态 | 是否本步必须 | 说明 |
|---|---|---|---|
| **本机开发** | `uvicorn apps.cryo_guard.api.main:app` + `pytest` | **必须** | 三路由 / middleware / schema / 单测在本机完成（tier-1）|
| **P轨 中间件（tier-1 可用 / ★M3+）** | P-step_03 `diting-stack` 已 Up；DB NodePort 30001、Redis NodePort 30379 | 推荐 | platform ns 中间件：`redis-svc.platform:6379`；`timescaledb-svc.platform:5432`；本机服务直连 NodePort 可 tier-1 使用 |
| **P轨 GPU 推理（tier-2 / ★M2 锁死）** | P-step_05 `make up-stack diting-vllm`；vLLM 在 `infer` ns（`vllm-infer-svc.infer:8000`）| **M2 必须** | 须先完成 P-step_05；3 LoRA 从 NAS PVC 热加载；推理服务运行时 cryo-guard 路由连接 infer ns vLLM；完成后 `make down-stack diting-vllm`（保留 NAS）|
| **cryo-guard K3s（tier-2 / ★M3+）** | `make cryo-step07-apply`（`kubectl apply -f deploy/k3s/`）| 服务上线必须 | 启动期裸 yaml 在 `diting-src/deploy/k3s/`；扩展期迁 `diting-infra/charts/cryo-guard/` |
| **本机 docker-compose** | 当 K3s 起不来时切 compose | 否（备选）| 提供同三路由 + vllm 容器 |
| **ACR + 生产 K3s** | 扩展期 Helm Chart + 多副本 | 否 | 启动期裸 yaml 足够 |

**本步默认运行形态**：
- **tier-1**：本机 uvicorn + 本机 / NodePort vLLM（已有 P-step_05 或本机 GPU）+ `make cryo-step07-test`；
- **tier-2 / ★M2**：P-step_05 vllm infer Up + `make cryo-step07-apply` + e2e 真标的通过。

## §9 准出标准（同会话可执行清单 · 质量优于数量）

### §9.1 服务可用性
- [ ] `curl http://vllm-svc:8000/v1/models` 返 4 条（base + 3 LoRA），各 LoRA `status=loaded`
- [ ] `curl http://cryo-guard-svc:8081/health` 200，engines 段 3 LoRA loaded
- [ ] 3 路由 POST 真实标的均返 EngineOutput

### §9.2 数据质量门槛（§3.5 矩阵 16 项）
- [ ] **vLLM 4 项（V1~V4）**：3 LoRA loaded + per-request 切换 + 冷加载 < 30 s + 名字一致
- [ ] **路由 5 项（R1~R5）**：3 schema 通过 + 入参校验 + 同 request_id 幂等
- [ ] **LangGraph 3 项（L1~L3）**：engine.run 返 Prediction + 节点失败 partial + 超时 30 s
- [ ] **K3s 4 项（K1~K4）**：2 Deployment Running + 2 Service + 健康聚合

### §9.3 工程交付
- [ ] `pytest tests/cryo_guard/test_api_engines.py -v` ≥ 7 passed
- [ ] `scripts/e2e_verify_step07.sh` 退出码 0；3 EngineOutput 全返
- [ ] `scripts/load_test_step07.sh` P95 < 5 s

### §9.4 一键复现
- [ ] **Makefile 合约**（§7.2）：12 个 target 已实现且通过；`make cryo-step07-all` 端到端 ≤ 15 min
- [ ] **可重入验证**：连跑两次 `make cryo-step07-all`，第二次跳过 build（hash 未变）+ apply 幂等 ≤ 3 min
- [ ] L4 实践记录 `04_阶段规划与实践/01_维度一_极寒防御/stage_1_启动期/实践记录_step_07_3引擎服务部署.md` 已按 §8.4g 更新"二、实际进展"（含 vLLM 启动参数、LoRA 加载耗时、P50/P95、并发上限、commit hash）
- [ ] commit：`feat(cryo-guard): step_07 vLLM multi-lora + 3 engine routes + K3s deploy + Makefile [Ref: 03_/01_维度一/.../step_07]`
- [ ] **同会话验证**：上述命令在当次会话执行并输出摘要

## §10 [Deploy] 段

**本步必涉镜像 / K8s yaml**。遵循 [L3 步骤·部署价值哲学·必选引用](../../../../_共享规约/L3步骤文档_部署价值哲学_必选引用.md) 与 [16 · ECS+K3s+ACR+Helm 链路](../../../../_共享规约/16_阿里云ECS_K3s_ACR_Helm部署与deploy-engine链路.md)：

| 内容 | 位置 | 启动期边界 |
|---|---|---|
| 镜像 `cryo-guard` build | `diting-src/deploy/docker/Dockerfile` | 本机 build → `k3s ctr images import`；扩展期才推 ACR |
| **cryo-guard K3s yaml（tier-1 开发用）** | `diting-src/deploy/k3s/`：`cryo-guard-deployment / cryo-guard-service / configmap-cryo-guard / secret-cryo-guard` | 启动期裸 yaml 足够；扩展期迁入 `diting-infra/charts/cryo-guard/` |
| **vLLM（tier-2 · P轨）** | `diting-infra/charts/diting-vllm/` by P-step_05 | `make up-stack diting-vllm` 起 infer ECS + Service；本步 **不**再维护 `deploy/k3s/vllm-deployment.yaml`——以 P-step_05 chart 为准 |
| **cryo-guard Helm Chart（扩展期）** | `diting-infra/charts/cryo-guard/` | 本步**不**做；启动期裸 yaml 够用 |

> **vLLM 部署路径修正（P 轨 v2 四层 chart 对齐）**：
> - 启动期 `deploy/k3s/vllm-*.yaml` 为**开发占位 yaml**，仅在 P-step_05 不可用时备用；
> - **tier-2 正式路径**：`diting-infra/charts/diting-vllm/` by P-step_05，namespace=`infer`，Service=`vllm-infer-svc.infer:8000`；
> - cryo-guard 路由中 `VLLM_URL` 在 tier-2 指向 `http://vllm-infer-svc.infer:8000`；
> - 变更 vLLM 启动参数须在 **deploy-engine 独立仓库**修改后 `make update-deploy-engine`，**禁止**在 `diting-infra/deploy-engine/` 子模块内写操作。

**deploy-engine 自检**（强制）：本步若改 `diting-infra/deploy-engine/`，须在与 diting-infra 平级的独立 `deploy-engine/` 仓库内修改、push，再 `make update-deploy-engine`。**禁止**在 diting-infra 子模块拷贝内做任何写操作（含 stash）。

## §11 依赖与被依赖

**上游**：
- `step_04/05/06`：3 LoRA + 3 engine 包；
- `step_01`：K3s + Redis + vLLM stub 框架；
- 用户提供：`KUBECONFIG`。

**下游**：
- `step_08` decision_gate：通过 HTTP 调本步 3 路由聚合结果；
- `step_09` 综合 Holdout：50 案例 × 3 路由跑评测；
- `step_10` 阶段验收：复用本步 API 跑 e2e demo。

**严禁伪造**（no-mock-policy）：vLLM LoRA 未真加载不允许路由返"loaded=true"；K3s 未真起不允许声称部署完成。

## §12 风险与回退

| 触发条件 | 动作 |
|---|---|
| vLLM 24GB 显存 OOM（同时加 3 LoRA）| 切 `--max-loras 1` + 串行加载策略；标 `lora_mode=serial`；step_08 调用时知晓本服务串行限制 |
| LoRA 加载失败 | 检查 PVC 挂载 + adapter_model.safetensors 文件完整性；重新 dvc pull |
| K3s Pod CrashLoop | 查 `kubectl logs` + `kubectl describe`；切 `docker compose up` 备选；问题修后回 K3s |
| 路由 P95 > 5 s | 看具体节点耗时（field_extractor / RAG / 图查询）；调 LangGraph 并行度；降级返 timeout EngineOutput |
| 健康检查 5 min 内反复 flaky | initialDelay 调到 30 s；降级把对应依赖标 degraded 而非 down |
| 同问题修复重试 ≥ 2 次仍失败 | § 8.4f 回收 |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-25 | **P 轨基建对齐（关键回写）**：§8 将 `Dev K3s` 行拆为 `P轨中间件 diting-stack`、`P轨 GPU 推理 diting-vllm（P-step_05）`、`cryo-guard K3s tier-1 apply` 三行，补 tier-1/tier-2 默认形态说明；§10 [Deploy] 新增 `vLLM 部署路径修正` blockquote（P-step_05 chart 为 tier-2 正式路径，启动期裸 yaml 为开发占位；deploy-engine 自检）|
| 2026-05-20 | **v2 按新 L3 启动期 step 模板（v1.2）重写**（关键重构，与 `00_系统规则` §4.5 同步）：①删除全部嵌入完整 K8s yaml / Python 路由 / vLLM 启动 bash 代码（原文 812 行 → 现 ~310 行）；②新增 §3.5 数据质量验收矩阵 16 项（V1~V4 vLLM + R1~R5 路由 + L1~L3 LangGraph + K1~K4 K3s）；③§7 改为"实施规划"三段式（§7.1 实现要点 13 项 + §7.2 Makefile 合约 12 个 target + §7.3 给后续执行模型指引）；④§5 性能门槛表只保留指标不嵌脚本；⑤§9 准出加 Makefile 合约 + 可重入验证；⑥§10 [Deploy] 段含 deploy-engine 自检约束；⑦明确 L3 责任边界 |
| 2026-05-16 | 初版（含完整 yaml + Python routes + start_vllm.sh + 压测脚本），812 行 |
