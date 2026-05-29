# Step 05 · Holdout 评测器 + CI Block（LoRA 守门）

## §1 一句话定位与本步交付物

**一句话**：实现 **HoldoutEvaluator**——对 step_04 新训 LoRA 在**永久锁库**的 Holdout 集（D1 50 案例已就绪、D2/D3 启动期 TBD）上评测 recall/precision/f1，与上一版本对比；**任一指标退化 >5% 触发 CI Block**（GitHub Actions 失败 + ADR）；通过的 adapter 才能进入 step_07 灰度。

**交付物**（勾选 = 完成）：
- [ ] **A**（`HoldoutEvaluator`）：按 dim 加载 holdout jsonl；批推理（vLLM）；统计 recall/precision/f1
- [ ] **B**（对比器）：与 `lora_versions` 中前一 prod 版本比；任一指标 -5% 触发 Block
- [ ] **C**（结果落库）：`holdout_evaluations(lora_version_id, dim, metrics, baseline_metrics, delta, blocked, decided_at)`
- [ ] **D**（API）：`POST /api/holdout/evaluate/{lora_version_id}`；`GET /api/holdout/{dim}/baseline`
- [ ] **E**（CI 集成）：GitHub Actions workflow `.github/workflows/holdout-gate.yml` 调评测 API；blocked=true → exit 1
- [ ] **F**（永久锁库）：Holdout jsonl 路径 read-only；CI 校验"不被混入训练集"
- [ ] **G**（Makefile）：`make evo-step05-all`

> **永久规则**：Holdout **永久锁库**，禁止用于训练；CI 守门不可绕过；blocked 的 adapter **不得**进 step_07。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../04_模型训练与部署.md](../04_模型训练与部署.md) §五 评测、[../05_验收标准与检查清单.md](../05_验收标准与检查清单.md)
> - **DNA**：`lora_gatekeeper`（holdout_required + regression_block 5%）、`holdout_management.policy: 永久锁库`
> - **L4**：[实践记录_step_05_Holdout评测器与CI_Block.md](../../../../../04_阶段规划与实践/05_维度五_演进飞轮/stage_1_启动期/实践记录_step_05_Holdout评测器与CI_Block.md)
> - **D1 Holdout**：50 案例（来自 D1 step_09 Holdout 准备）
> - **上游**：step_04；**下游**：step_07 灰度

## §3 数据采集对象 / 落库映射

| 输入 | 输出 |
|---|---|
| Holdout jsonl（per dim） | metrics（recall/precision/f1 + per-class）|
| 当前 prod baseline metrics | delta JSON |
| 每次评测 | `holdout_evaluations` 一行 + WandB 可选 |
| Block 决策 | `blocked=true` 阻断 step_07 |

## §3.5 数据质量验收矩阵（Holdout 守门 · 仅启动期）

### §3.5.1 Holdout 集治理

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| H1 | **永久锁库路径** | MinIO `super-evo/holdout/{dim}/`；read-only IAM policy | ✅ | 误写→自动拒 |
| H2 | **leak check** | training/scripts/verify_dataset.py 检查与 holdout 无重叠 | ✅ pre-train hook | leak→step_04 fail |
| H3 | **D1 案例数** | =50（DNA cases_per_dimension.cryo_guard）| ✅ | — |
| H4 | **D2/D3 案例数** | DNA TBD；启动期至少 30 | ⚠️ | <30 标 partial |
| H5 | **版本固定** | holdout 通过 DVC tag 锁定；不可改 | ✅ | — |

### §3.5.2 评测正确性

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **每 case 推理** | vLLM 调 candidate adapter；记录原始输出 | ✅ | LoRA 加载失败→fail |
| E2 | **指标 3 项** | recall / precision / f1（per-class + macro）| ✅ | — |
| E3 | **可复现** | 同 seed 重跑指标相同 ±1e-4 | ✅ | — |
| E4 | **baseline 对比** | 读 `lora_versions.status=prod` 最近一版 metrics | ✅ | 首次无 baseline→Pass + 标 first_run |

### §3.5.3 CI Block 逻辑

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| C1 | **退化 5% 触发 Block** | recall/precision/f1 任一 `(new-old)/old < -0.05` → blocked=true | ✅ | 阈值 yaml 可调 |
| C2 | **CI 集成** | GH Actions 必跑；exit 1 阻断合并 | ✅ | — |
| C3 | **可旁路 ≠ 自动** | 仅架构师 ADR 后可 override（手动 manual_gate）| ✅ | — |
| C4 | **审计** | holdout_evaluations.blocked + delta + decided_by | ✅ | — |

### §3.5.4 no-mock

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| N1 | **真 vLLM 推理** | CI 用真 vLLM 或硬阻塞 | ⚠️ GPU CI runner | 缺 GPU→标 BLOCKED 不出 PASS |
| N2 | **不伪造 baseline** | baseline 必须来自真 lora_versions | ✅ | — |

> 共 **15 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| Holdout MinIO read-only key | 评测 |
| vLLM 服务 | 推理 |
| `WANDB_API_KEY` | 记录 |
| GH Actions runner（GPU）| CI |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 至少 1 维 Holdout 评测完成 | ✅ |
| CI Block 工作 | 模拟退化 → exit 1 |
| 永久锁库 | leak check 0 命中 |

## §6 下一步

本步 ✅ → step_06 双盲 Kappa 校准（C4）。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A HoldoutEvaluator** | `quality/holdout_evaluator.py` | dim → load jsonl → vLLM 推理 → metrics | 单测 mock |
| **B baseline reader** | 同模块 | 读 prod 标记最新版 | 单测 |
| **C 对比 + Block** | `quality/regression_gate.py` | 阈值 yaml；blocked flag | 单测 |
| **D `holdout_evaluations` ORM** | `db/models.py` + alembic | §3 字段 | migration |
| **E API routes** | `api/routes/holdout.py` | evaluate + baseline | 200 |
| **F CI workflow** | `.github/workflows/holdout-gate.yml` | 调 API；exit 由 blocked | dry-run |
| **G leak check job** | CI step + scripts | grep symbol/hash 重叠 | 0 命中 |
| **H 单测** | `test_holdout_evaluator.py`、`test_regression_gate.py` | ≥10 | pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `evo-step05-prep` | holdout 在；vLLM 路径在；GPU ok |
| `evo-step05-evaluate-cryo` | D1 50 案例评测 |
| `evo-step05-evaluate-thrust` | D2 |
| `evo-step05-evaluate-narrative` | D3 |
| `evo-step05-leak-check` | 与 verified 训练集 0 重叠 |
| `evo-step05-regression-sim` | 模拟一次退化 → blocked=true |
| `evo-step05-test` | pytest ≥10 |
| `evo-step05-all` | 端到端 |
| `evo-step05-status` | 最近 N 次评测 + delta |

### §7.3 指引

先 leak_check→evaluator→regression_gate→API→CI；CI runner 缺 GPU 时**不**虚假 PASS（标 BLOCKED）。

## §8 部署节奏（P 轨 · 真实基建对齐）

| 阶段 | 形态 | 是否本步必须 | 说明 |
|---|---|---|---|
| **tier-1 · 本机** | `python quality/holdout_evaluator.py` + `pytest` + GH Actions workflow dry-run | **必须** | 评测逻辑 + 单测 + CI workflow 在本机 / CI 完成；vLLM 可用本机端口或 mock（单测）|
| **tier-2 · P轨推理（★M2 锁死）** | P-step_05 `make up-stack diting-vllm` 起 infer ECS；评测脚本连接 `vllm-infer-svc.infer:8000` | **M2 必须** | 须先完成 **P-step_05**（`diting-infra/charts/diting-vllm/`）；真 vLLM 推理；评测完成后 `make down-stack diting-vllm` 回收 GPU ECS（NAS LoRA 保留）|

**M2 链（锁死）**：P-step_04 → D5 step_04 训练 ✅ → **P-step_05** `make up-stack diting-vllm` → **D5 step_05 Holdout** → `make down-stack diting-vllm`。

**缺 GPU**：`evo-step05-evaluate-*` 需连接真 vLLM；CI runner 缺 GPU 时标 `BLOCKED(gpu_unavailable)`，**不**出 PASS。**禁止**用 mock vLLM 响应伪造 Holdout 通过。

**扩展期**：独立 evaluator Pod + GPU 专属节点；多维并行评测。

## §9 准出标准

- [ ] §3.5 15 项；至少 1 维 evaluator 跑通 + Block 模拟测通
- [ ] leak check 0 命中；GH Actions workflow 在
- [ ] `make evo-step05-all`；L4 回写（metrics、baseline、delta、blocked）

## §10 [Deploy]

GH Actions workflow + ConfigMap `REGRESSION_THRESHOLD=0.05`。

**P 轨 chart 对齐（tier-2）**：
- vLLM 推理服务由 **P-step_05** `diting-infra/charts/diting-vllm/` 管理（namespace=`infer`，Service=`vllm-infer-svc.infer:8000`）；
- `VLLM_URL` 环境变量在 tier-2 时指向 infer ns（或通过 NodePort 暴露，端口由 chart values 决定）；
- `REGRESSION_THRESHOLD=0.05` 写入 ConfigMap，由 `diting-vllm` chart 或 `diting-stack` ConfigMap 渲染；
- 本步**不**产出业务镜像，无需改 deploy-engine；评测完成后执行 `make down-stack diting-vllm` 回收 infer ECS。

## §11 依赖

step_04；vLLM；Holdout MinIO；CI。

**严禁**：bypass CI 直接发布；改 holdout 文件；伪造 baseline。

## §12 风险

| 触发 | 动作 |
|---|---|
| baseline 缺失 | 标 first_run + 人审通过 |
| 退化频繁 | 回查 step_02 蒸馏质量 / step_03 标注 |
| 阈值争议 | 改 yaml + ADR |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-25 | **P 轨基建对齐（回写）**：§8 改为 tier-1/tier-2 双路径表（tier-2 = P-step_05 `diting-vllm` chart；M2 链锁死）；§10 补 vLLM chart 对齐说明与 VLLM_URL 绑定 |
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 1215 行嵌入 Python/yaml；§3.5 15 项；leak check；no-bypass；`evo-step05-*`；1215→~240 行 |
| 2026-05-16 | 初版 1215 行 |
