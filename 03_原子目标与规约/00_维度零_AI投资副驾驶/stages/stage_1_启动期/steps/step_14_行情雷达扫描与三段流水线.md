# Step 14 · 行情雷达扫描与三段流水线地基（M8 · T0/T1/T2 + StageArtifact + 模式C）

> **波次定位**：D0 启动期**波次三**第 1 步。把 step_12 的「🔭行情雷达」从空态升级为**顶级模型深度思考的全方位评估**，并落下整个波次三共享的**三段流水线 + 两级 Artifact 审计 + 模型路由**地基。**前置**：step_12（Campaign 6 表 + 6 维档案，已生产 ✅）。**架构总纲**：[25_四区漏斗_三段流水线_架构脊柱](../../../../_共享规约/25_四区漏斗_三段流水线_架构脊柱_设计.md)。

## §1 一句话定位与本步交付物

**一句话**：实现**行情雷达 3 类输入**（A 热度行业扫描 / B 概念表达分析 / C 模糊标的深度分析）→ 经 **T0 采集 → T1 压缩 → T2 推理** 三段流水线产出**候选标的全方位评估**（生态位/价值链/龙头/壁垒/利润/阶段/利好爆发窗/风险），三段全落 `StageArtifact` 可审计；支持候选**一键晋级**到路线图/规划/关注。**先做模式C（复用最多），A/B 为扩展项。**

**交付物**（勾选 = 完成）：
- [ ] **A 地基三表**：`stage_artifacts / workspace_artifacts` + `model_profile`（配置驱动模型路由）+ 扩展 `campaigns.stage` / `campaign_symbols.analysis_snapshot`（见 [25_ §3.2](../../../../_共享规约/25_四区漏斗_三段流水线_架构脊柱_设计.md)）
- [ ] **B 雷达表**：`radar_scans / radar_candidates`
- [ ] **C 三段流水线骨架**：`modules/radar/pipeline.py`（T0 采集 → T1 压缩 → T2 推理，每段写 `StageArtifact`）+ `ContextMatrixBuilder`（喂 T2 前矩阵压缩）
- [ ] **D 模式C 标的深度分析**：`modules/radar/scanner.py` 模式C → 并行调 market_phase + ProfitCapturePlaybook + MonitorDictReader + 行情 → `RadarCandidate`；缺引擎 `pending`/`inferred`
- [ ] **E 晋级流转**：`POST /api/radar/candidates/{id}/promote`（→ Campaign，带 `analysis_snapshot`）/ `watchlist`
- [ ] **F 前端**：雷达 3 输入入口卡 + 进度态轮询 + 候选评估卡（标签 chip + 利好窗 + 证据链链接 + 3 动作按钮）+ 模型选择器
- [ ] **G 单测**：≥ 12（三段 artifact 落库 + 溯源 + 模式C 各维度 + pending 降级 + promote + advisory）
- [ ] **H Makefile**：`copilot-step14-prep/migrate/scan/test/all/status/clean`

> **永久红线**：候选/动作建议全 advisory；T1 未训好显式 `t1_fallback=rule/generic`，**禁伪造**龙头/壁垒结论。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **架构脊柱**：[25_四区漏斗_三段流水线_架构脊柱](../../../../_共享规约/25_四区漏斗_三段流水线_架构脊柱_设计.md)（§2 三段流水线 / §3 Artifact / §4 ModelProfile）
> - **本阶段总览**：[steps/README §一-2 波次三](./README.md)
> - **DNA 键**：[`dna_stage_1_启动期.yaml`](../../../../_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml) `deliverables.modules[M8] / funnel_pipeline_v3 / stage_artifact / model_profile`
> - **L4 实践记录**：[实践记录_step_14_行情雷达扫描与三段流水线](../../../../../04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/实践记录_step_14_行情雷达扫描与三段流水线.md)（执行时生成）
> - **上游 step**：← step_12（Campaign 6 表 + 6 维 `dossier`）
> - **下游 step**：→ step_15（候选→路线图时间线）/ step_16（候选→规划证伪）/ step_17（执行）
> - **跨维上游能力**：D2 `ProfitCapturePlaybook`/`EvidenceChainBuilder`/Lighthouse(`AIDispatcher`)；D3 `classify_symbol`(market_phase)/`MonitorDictReader`；行情 `MarketQuoteClient`/`fetch_bars_60d`

## §3 数据采集对象 / 落库映射

| 业务对象 | ORM 表/字段 | 数据源（T0/T1/T2） | 缺失语义 |
|---|---|---|---|
| 三段产物 | `stage_artifacts.{stage,model_id,payload_json,input_refs}` | T0 代码 / T1 LoRA / T2 Opus | 每段必落，缺则该段 status=skipped |
| 区间精简集 | `workspace_artifacts.{key_facts,verdict,upstream_refs}` | 本区 T2_verdict 对外视图 | — |
| 扫描会话 | `radar_scans.{input_type,query_text,status}` | 用户输入 | — |
| 候选评估 | `radar_candidates.{niche_text,is_leader,moat_level,profit_quality,market_phase,catalyst_window,risk_summary,confidence}` | 模式C 各引擎 | 缺引擎 → 字段 `pending`/`inferred`，**非 null 伪造** |

### §3.1 模式C 三段映射（标的深度分析 · 自给式 Opus 深度研报）

> **重构（2026-05-31 · 方案A 自给式）**：原设计 Mode C 各维度（生态位/壁垒/阶段等）依赖上游 D2/D3 引擎（deep_strike/state_watch），但生产全空 + T2 默认关导致所有维度 pending 空壳。**现重构为自给式**：T0 **直采 akshare** 真实数据（行情 K 线、个股资料、财务摘要、估值分位、同业）→ T1 压缩 → T2 **必开 Opus** 输出固定 9 维结构化 JSON（`niche/value_chain/is_leader/moat/profit_quality/market_phase/catalyst_timeline/risk/valuation`，每维含 `verdict+reasoning+evidence[]+confidence`，外加 `overall{conclusion,action_advisory,confidence}`），**成本显示**（`cost_yuan_est/tokens_in/tokens_out/model`）。失败返回 `status=error`+detail，**守 no-mock（绝不伪 pending、不造假）**。

| 段 | 动作 | 数据源/复用 | 输出 |
|---|---|---|---|
| **T0** | akshare 直采：日 K 行情、个股资料(行业/市值/上市)、财务摘要(营收/净利/毛利率/ROE/负债率)、估值分位(PE-TTM 历史百分位) | `scanner.py`：`stock_zh_a_hist`/`stock_individual_info_em`/`stock_financial_abstract`/`stock_a_indicator_lg`；每源超时+异常→`status=error`(不伪 pending) | 原始多源真实数据 → `stage_artifacts(T0_raw)` |
| **T1** | 压缩为紧凑「事实矩阵」（行情/公司资料/财务/估值），缺源标 `unavailable` | `context_matrix.py`（纯规则 · `t1_fallback=rule`） | 喂 Opus 的事实矩阵 → `stage_artifacts(T1_distilled)` |
| **T2** | **必开 Opus**：读事实矩阵 → 9 维结构化深度推理；检测 mock 降级→显式 error；按真实 token 算成本 | `pipeline._run_t2` → `AIDispatcher.call(scene=radar_assess)` + `schema.parse_opus_verdict`/`estimate_cost_yuan` | 9 维 `deep_analysis`+成本 → `stage_artifacts(T2_verdict)` → `radar_candidates` + `workspace_artifacts` |

## §3.5 数据质量验收矩阵（M8 · 仅启动期负责）

> **自给式重构（2026-05-31）**：T0 不再依赖上游 D2/D3，改为 akshare 4 类真实源；9 维结论由 Opus 基于事实矩阵推理产出。任一 akshare 源不可达→该源 `status=error`，Opus 仍基于其余真实数据推理并在 reasoning 说明缺口、降低 confidence；Opus 整体不可达→候选 `t2_status=error`+detail（**绝不伪 pending、不造假**）。

| # | 数据/分析维度 | 必产字段 | 启动期覆盖 | 降级路径 |
|---|---|---|---|---|
| D1 | 行情（多周期涨跌/量比） | T0 `quote`(1d/5d/20d/60d/量比) | ✅ `stock_zh_a_hist` | 限流/超时→`quote.status=error`，矩阵标 unavailable |
| D2 | 公司资料 | T0 `profile`(行业/总市值/流通/上市) | ✅ `stock_individual_info_em` | 同上 |
| D3 | 财务摘要 | T0 `financials`(营收/净利/毛利率/ROE/负债率) | ✅ `stock_financial_abstract` | 同上 |
| D4 | 估值分位 | T0 `valuation`(PE-TTM + 历史百分位/PB) | ✅ `stock_a_indicator_lg` | 同上 |
| V1~V9 | Opus 9 维 verdict | `niche/value_chain/is_leader/moat/profit_quality/market_phase/catalyst_timeline/risk/valuation`，每维 `verdict+reasoning+evidence[]+confidence` | ✅ T2 必开 Opus | Opus 不可达→`t2_status=error`，候选列留空(不伪造) |
| C1 | 成本透出 | `summary_json.cost`+候选 `raw_json.cost`(model/tokens/¥) | ✅ `estimate_cost_yuan` | tokens=0 时 ¥0 |
| C2 | 三段审计 | 每候选 T0/T1/T2 三条 `stage_artifacts` + 溯源 | ✅ | T1 用 `t1_fallback` 显式标 |

> **准出**：D1~D4 至少 ≥2 类真实采到 + V1~V9 由 Opus 真实产出（`t2_status=ok`、9 维齐）+ C1 成本透出 + C2 三段审计齐。Opus 硬失败时前端显式红色"未就绪"横幅，**不以占位冒充**。

## §4 真实数据源与凭证清单

**§4.1 数据源（自给式）**：行情/资料/财务/估值 = **akshare 直采**（`stock_zh_a_hist`/`stock_individual_info_em`/`stock_financial_abstract`/`stock_a_indicator_lg`）；T2 = Anthropic Opus（`AIDispatcher` remote）。不依赖上游 D2/D3 引擎或 monitor:dict。

**§4.2 凭证**
| 凭证 | 用途 | 何时 | 写在 |
|---|---|---|---|
| `COPILOT_REDIS_URL` | monitor:dict / market_phase / cryo stream | 本步前 | `diting-src/.env` |
| `MY_HOLDINGS_YAML` | 候选默认源（可扫持仓外标的） | 本步前 | `diting-src/.env` |
| `ANTHROPIC_API_KEY` | T2 Opus 9 维深度研报（**模式C 必需**；缺→候选 t2_status=error 不伪造） | 本步前 | `diting-src/.env` → 生产经 `copilot-sync-ai-from-src-env.sh` 注入 pod secret |
| `RADAR_T2_ENABLED` | T2 总开关（模式C 设 **true**；关则前端显式提示未就绪） | 本步前 | `.env` / Chart `copilot.ai.radarT2Enabled` |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| `/planning?view=radar` 3 输入入口可见 | 200 + grep |
| 模式C 输入 1 标的 → 返回 9 维研报卡（Opus 真实 verdict，`t2_status=ok`，**无 pending**）+ 成本徽章 | curl + jq |
| 每候选 3 条 `stage_artifacts`(T0/T1/T2) + 溯源可查 | jq |
| 候选 promote → Campaign，`analysis_snapshot` 带入 | POST 201 + 查得 |
| no-auto-execute 审计 | rg = 0 |
| 单测 | ≥ 12 passed |

## §6 下一步（一行）

本步 ✅ → **step_15 滚动路线图双层锚定**：候选的 `catalyst_window` 入时间线编排 + 合理性评估；生命周期判定。触发：模式C 评估卡稳定产出 + 地基三表可审计。

## §7 实施规划

### §7.1 实现要点

| 实现要点 | 涉及代码位置 | 关键设计决策 | 验证标准 |
|---|---|---|---|
| A 地基三表 + Campaign.stage | `apps/copilot/db/models.py` | `stage_artifacts`/`workspace_artifacts`/`model_profile` 见 25_ §3.2；input_refs/upstream_refs JSON 存 id 列表 | `.tables` 含 3 表；溯源字段可查 |
| B 雷达表 | 同上 | `radar_scans`/`radar_candidates` | `.tables` 含 2 表 |
| C 三段流水线骨架 | `modules/radar/pipeline.py` | `run_stage(T0/T1/T2)` 统一写 artifact + 计 latency/token；幂等按 input_refs hash 缓存 T2 | 单测：三段落库 + hash 命中复用 |
| C2 矩阵压缩 | `modules/radar/context_matrix.py` | 抽 anomaly/hit/delta；启动期纯规则（`t1_fallback=rule`） | 单测：输出仅关键单元 |
| D 模式C T0 采集 | `modules/radar/scanner.py` | 并行 gather 4 类 akshare 源；每源超时+异常→`status=error`+detail（**禁伪 pending**） | D1~D4 单测 |
| D2 T2 Opus + schema | `modules/radar/pipeline.py` + `schema.py` | 必开 Opus 出 9 维 JSON；检测 mock 降级→error；按真实 token 算成本 | mock Opus 单测：9 维齐 + 成本>0 + error 路径 |
| E 模型路由 | `modules/radar/model_router.py` | 读 `model_profile`，经 `AIDispatcher.call(scene=radar_assess)`；`RADAR_T2_ENABLED` 关→候选 t2_status=disabled（前端显式提示） | 单测：override + fallback 标注 |
| F promote | `routers/planning_routes.py` + `service.py` | 候选→CampaignSymbol，拷 `analysis_snapshot`；建/挂 Campaign 设 `stage` | POST 201 + snapshot 查得 |
| G 前端 | `templates/planning/workbench.html` + radar partial | 3 输入入口 + HTMX 轮询 `/api/radar/scans/{id}` + 评估卡 chip + 模型选择器 | curl + 截图 |
| H 单测 | `tests/copilot/test_radar.py` | 三段/溯源/模式C/pending/promote/advisory | `pytest -q` ≥ 12 |

### §7.2 Makefile 合约

| target | 用途 | 入参（环境变量） | 验证标准 |
|---|---|---|---|
| `copilot-step14-prep` | 起 redis + 校验 step_12 6 表 | `COPILOT_REDIS_URL` | 退出码 0 |
| `copilot-step14-migrate` | 建地基+雷达 5 表 + 扩展列 | — | `.tables` 反映 |
| `copilot-step14-scan` | 跑一次模式C（默认持仓首只） | `RADAR_SYMBOL`,`RADAR_T2_ENABLED` | 候选 + 3 artifact 落库 |
| `copilot-step14-test` | 单测 | — | ≥ 12 passed |
| `copilot-step14-all` | 端到端 | 合并 | 全退出码 0 |
| `copilot-step14-status` | 扫描数 + 候选数 + Q1~Q9 覆盖率 + artifact 段分布 | — | 打印快照 |
| `copilot-step14-clean` | 删 demo 扫描痕迹 | — | 已删 |

> 配置驱动：扫描标的/T2 开关只改环境变量，禁 hardcode。

### §7.3 给后续执行模型的指引

1. **先落地基三表 + Campaign.stage**（P0），再做模式C；A/B 模式为扩展项（见 25_ §7 P2/P3）。
2. **T2 默认关**（`RADAR_T2_ENABLED=false`）先把 T0/T1 + 落库 + 溯源跑通，避免一上来烧 Opus；开 T2 前确认预算（25_ §6.1 DECISION_PENDING）。
3. **缺引擎一律 pending/inferred**，T1 未训用 `t1_fallback=rule` 显式标注（守 no-mock）。
4. **每段必写 `stage_artifacts`**，T2 决断必带 `input_refs` 指向 T1（审计链不可断）。
5. **L4 回写**：1 个模式C 候选 JSON + 3 段 artifact + 溯源、Q1~Q9 覆盖、promote 后 snapshot、advisory rg 0、≥12 pytest。
6. **审计**：`rg -i "buy|qmt|auto_trade|order_id|webhook_target|立即|一键|下单" apps/copilot/modules/radar/ apps/copilot/templates/planning/` = 0。

## §8 部署节奏

| 项 | 本 step |
|---|---|
| 部署面 | 本机 uvicorn + redis；随 D0 整体上 K3s |
| Chart | 不改（新增表 + 路由 + ConfigMap `RADAR_T2_ENABLED`） |
| 必须层级 | **本机开发**（K3s 随 D0） |

## §9 准出标准

```bash
cd diting-src
# 1) 建表
make copilot-step14-migrate
sqlite3 data/copilot.db ".tables" | grep -E "stage_artifacts|workspace_artifacts|model_profile|radar_scans|radar_candidates"
# 2) 模式C 扫描（T2 默认关）
RADAR_SYMBOL=601138 make copilot-step14-scan
curl -s "http://127.0.0.1:8080/api/radar/scans/1" | jq '.candidates[0] | {symbol,market_phase,profit_quality,is_leader,niche_text,confidence}'
# 3) 三段 artifact + 溯源
curl -s "http://127.0.0.1:8080/api/radar/candidates/1/artifacts" | jq 'group_by(.stage)|map({stage:.[0].stage,n:length})'
# 4) promote 带 snapshot
curl -s -XPOST "http://127.0.0.1:8080/api/radar/candidates/1/promote" -d '{"new_theme":"雷达晋级测试"}' | jq '.campaign_id'
# 5) no-auto-execute
rg -i "buy|qmt|auto_trade|order_id|webhook_target|立即|一键|下单" apps/copilot/modules/radar/ apps/copilot/templates/planning/   # 0
# 6) 单测
pytest tests/copilot/test_radar.py -q   # ≥ 12 passed
pytest tests/copilot/ -q                # 不退化
make copilot-step14-all && make copilot-step14-status
```

### §9.1 准出确认
- [ ] §3.5 Q1~Q9（必绿项全绿；pending/inferred 显式）
- [ ] §9 命令本机跑通
- [ ] L4 `实践记录_step_14_*.md` 回写
- [ ] 通知 step_15 owner：候选 `catalyst_window` 可入时间线

## §10 [Deploy]

ConfigMap 增 `RADAR_T2_ENABLED`（默认 false）、`RADAR_SCAN_TIMEOUT_SEC`。引用 [16_ECS+K3s+ACR](../../../../_共享规约/16_阿里云ECS_K3s_ACR_Helm部署与deploy-engine链路.md)；deploy-engine 改动走独立仓库流程。

## §11 依赖与被依赖

- **上游**：step_12（6 表+dossier ✅）；D3 market_phase（✅）；D2 ProfitCapture（需 ingest）；行情 MarketQuote（✅）
- **下游**：step_15/16/17 消费 `radar_candidates` + `workspace_artifacts`
- **不能 mock**：Q4/Q5/Q6/Q7 上游未就绪 → pending/inferred，禁伪造；T1 未训用 fallback 标注

## §12 风险与回退

| 触发 | 应对 | 重试 |
|---|---|---|
| T2 Opus 成本/未配 key | `RADAR_T2_ENABLED=false`，仅出 T0/T1 评估（降级但可用） | — |
| deep_strike 未 ingest | profit_quality pending，先靠行情+阶段 | — |
| 龙头/壁垒无引擎 | inferred 代理 + 显式标注，列待建 | — |
| 同问题 > 2 次 | §8.4f：先交付「模式C + 地基三表 + promote」最小闭环，A/B 迭代 | — |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-30 | 初版（波次三 M8）：行情雷达 3 模式（A 热度/B 概念/C 标的·先做C）+ T0/T1/T2 三段流水线骨架 + StageArtifact/WorkspaceArtifact 两级落库审计 + ModelProfile 路由 + ContextMatrixBuilder + 候选 promote 晋级；地基三表 + 雷达两表 + Campaign.stage；Q1~Q9 质量矩阵（缺引擎 pending/inferred 禁伪造）；T2 默认关控成本；no-auto-execute/no-mock 红线 |
| 2026-05-31 | **模式C 自给式 Opus 深度研报重构（取消占位符）**：根因 = 原 T0 依赖上游 D2/D3 引擎在生产全空 + T2 默认关 + pod 未注入 ANTHROPIC_API_KEY → 全维 pending 空壳。重构：T0 改 **akshare 直采**(行情/资料/财务/估值，新增 `schema.py` 冻结 9 维契约)；T1 压缩事实矩阵；T2 **必开 Opus** 输出 9 维结构化 JSON（mock 降级→显式 error 守 no-mock）+ 真实 token 成本；前端 `_render_scan_html` 改人类可读 9 维研报卡 + 成本徽章 + 三段溯源；§3.1/§3.5 表更新为 D1~D4+V1~V9+C1~C2；Chart secret 注入 AI env + `copilot-sync-ai-from-src-env.sh` + `make copilot-modec-deploy`。test_radar 17 项 + 全套 162 passed。L4 见 实践记录_ModeC深度研报重构.md |
