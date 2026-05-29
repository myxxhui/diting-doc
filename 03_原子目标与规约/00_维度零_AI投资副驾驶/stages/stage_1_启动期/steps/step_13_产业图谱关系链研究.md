# Step 13 · M7 产业图谱关系链研究（Campaign Part A · 概念→实体演进 · 确认/推演两态）

> **波次定位**：D0 启动期**波次二**第 3 步。落地 step_12 中每个 Campaign 的 **Part A 产业知识关系图谱**（认知层）。**前置**：step_12（M6 Campaign + `campaign_symbols`）。

## §1 一句话定位与本步交付物

**一句话**：实现 **M7 产业图谱关系链研究** —— 为每个 Campaign 提供一张**专属产业知识关系图谱**：初始**只有行业上下游的"概念节点"**（无标的），随调研深入，**关键上游需有官方信息才标"✅已确认"，否则为"🔵推演位置"**；**只有真正选定标的（执行点）后，才把标的实体节点挂进图谱**。图谱用于探索持仓与关注主题的**产业生态、机会面、风险面、关键危险预防监控**。图谱与 step_12 计划面板**双向联动**（点节点高亮相关利好/动作/三支柱监控）。

**交付物**（勾选 = 完成）：
- [ ] **A**（数据模型 2 表）：`graph_nodes`（节点）+ `graph_edges`（关系边），均带 **`confirm_state ∈ {confirmed, inferred}`** + `evidence_ref`（见 §3.3）
- [ ] **B**（节点两层）：`node_type ∈ {concept(环节/行业概念), entity(标的实体)}`；新建 Campaign 默认只生成 concept 节点；`entity` 节点**仅当 step_12 选定标的时**添加并挂到对应 concept 环节
- [ ] **C**（确认度判定 `ConfirmService`）：有**关键官方信息源**（P5 招标公示 / P6 海关 / 官方公告年报 / 政策文件 / P7 产能）→ `confirmed`；仅研报/新闻/AI 推演 → `inferred`；**直接复用 D2 The Critic evidence 等级**（PHYSICAL/官方=confirmed，SOFT=inferred），不另造一套
- [ ] **D**（图谱构建器）：以某标的/主题为中心，从 `related_party_graph`（D1/D2 已建 340 节点）+ D2 The Architect 产业链 + monitor:dict 拉取上下游 → 建 concept 图；标的选定后 `attach_entity()`
- [ ] **E**（4 视图）：① 生态图谱（可交互，实线=confirmed/虚线=inferred，entity 高亮）② 机会面（沿产业链找雷达关联行情）③ 风险面（关联方穿透：实控人/明股实债/循环交易，来自 D1 关联交易引擎）④ 关键危险监控（把 D3 P5/P6/P7 + monitor:dict 挂到节点，节点变红即预警）
- [ ] **F**（下钻入口，非孤岛）：从 step_11 监管卡「🕸️看产业链」/ step_12 雷达卡 / 档案卡进入，**默认以该标的为中心**；URL `?center={symbol|campaign_id}`
- [ ] **G**（双向联动）：点图谱节点 ↔ 高亮 step_12 计划里相关利好/动作/三支柱（通过 `monitor_subscriptions.symbol/node_ref` 关联）
- [ ] **H**（可视化）：Cytoscape.js 或 vis-network（CDN）渲染；confirmed 实线实心、inferred 虚线空心；点击节点弹证据来源（evidence_ref）
- [ ] **I**（节点证据来源审计）：每个 `confirmed` 节点/边**必须有非空 `evidence_ref`**；`confirmed` 无证据 → 校验失败降级 `inferred`
- [ ] **J**（单测）：≥ 12（concept/entity 分层、confirm 判定、attach_entity、related_party 导入、风险面穿透、双向联动 ref）
- [ ] **K**（Makefile）：`copilot-step13-prep/migrate/build/up/test/all/status/clean`

> **永久规则**：图谱为研究/监控视图，**不含**任何下单/执行动作；危险监控仅警示。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[../04_前端开发与用户体验.md](../04_前端开发与用户体验.md) §2.1（🕸️产业图谱）、[../01_实践目标与策略.md](../01_实践目标与策略.md)
> - **DNA**：[`dna_stage_1_启动期.yaml`](../../../../_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml) **M7 产业图谱关系链研究**
> - **上游数据**：`related_party_graph`（D1 `build_related_party_graph.py` 340 节点）· D2 The Architect 产业链 + Critic evidence 等级（[D2 step_02/03](../../../../02_维度二_纵深进攻/stages/stage_1_启动期/steps/step_03_证据链构建器.md)）· D3 P5/P6/P7 + `monitor:{symbol}:dict`（[D3 step_03](../../../../03_维度三_持仓监控/stages/stage_1_启动期/steps/step_03_价格与事件探针.md)）· D1 关联交易引擎（[D1 step_06](../../../../01_维度一_极寒防御/stages/stage_1_启动期/steps/step_06_关联交易引擎LoRA.md)）
> - **复用已建**：step_12 `campaign_symbols / monitor_subscriptions`（联动）；step_11 监管卡（下钻入口）
> - **共享规约**：[20_监控字典规约](../../../../_共享规约/20_监控字典规约.md)（节点挂载监控指标）· [18_动态采集流水线](../../../../_共享规约/18_动态采集流水线规约.md)
> - **L4**：[实践记录_step_13_产业图谱关系链研究](../../../../../04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/实践记录_step_13_产业图谱关系链研究.md)（执行时生成）

## §3 数据采集对象 / 落库映射

### §3.1 节点两层 + 确认度两态（核心模型）

| 概念 | 取值 | 含义 | 视觉 |
|---|---|---|---|
| `node_type` | `concept` | 行业上下游环节/概念（默认，建 Campaign 即有） | 普通节点 |
| `node_type` | `entity` | 标的实体（**选定执行点后才加**，挂到 concept 环节） | 高亮节点 |
| `confirm_state` | `confirmed` | 有关键官方信息源支撑 | 实线/实心 |
| `confirm_state` | `inferred` | 仅 AI 逻辑推演，无官方证实 | 虚线/空心 |

### §3.2 确认度 ← 官方信息源（复用 D2 Critic evidence 等级）

| 官方源 | 后端对应 | 用于确认 |
|---|---|---|
| 政府招投标公示(ccgp) | D3 P5 招标探针 | 上下游真实供货关系 |
| 海关 HS Code 进出口 | D3 P6 海关探针 | 产业链贸易流向 |
| 官方公告/年报披露 | D1/D2 公告采集 | 供应商/客户/产能 |
| 政策文件 | D2 Sniffer 政策源 | 行业地位/受益环节 |
| 产能利用率(统计局) | D3 P7 产能探针 | 物理产能逻辑 |

> **判定规则**：节点/边 `evidence_ref` 命中上述任一**官方/物理源**（= D2 Critic `PHYSICAL` 等级）→ `confirmed`；仅研报/新闻（`SOFT`）或纯 AI 推演 → `inferred`。**禁止**把 SOFT 证据标为 confirmed。

### §3.3 数据模型（2 表 · SQLite）

| 表 | 关键列 |
|---|---|
| `graph_nodes` | id, campaign_id FK, node_key(唯一·环节名或 symbol), node_type{concept,entity}, label, symbol(entity 时填), confirm_state{confirmed,inferred}, evidence_ref(JSON·官方源链接/explain), monitor_ref(关联 monitor_subscriptions), health{ok,warn,alert,unknown}, created_at |
| `graph_edges` | id, campaign_id FK, src_node FK, dst_node FK, relation{upstream,downstream,supply,related_party,same_theme}, confirm_state{confirmed,inferred}, evidence_ref(JSON), created_at |

### §3.4 图谱演进（状态机）

```
建 Campaign → 纯概念图（concept 节点，多为 inferred）
  → 补官方信息（P5/P6/公告）→ 关键上游 confirm_state: inferred→confirmed
  → step_12 选定标的 → attach_entity()：entity 节点挂到对应 concept 环节
  → 三支柱监控挂节点 → health 随 verdict 变化（ok→warn→alert）
```

## §3.5 数据质量验收矩阵（M7）

### §3.5.1 模型正确性
| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| G1 | 节点两层 | concept 默认；entity 仅选定后加 | ✅ |
| G2 | 确认/推演两态 | 每节点/边有 confirm_state | ✅ |
| G3 | confirmed 必有证据 | `confirmed` 且 `evidence_ref` 空 → 降级 inferred | ✅ |
| G4 | 复用 Critic 等级 | PHYSICAL→confirmed，SOFT→inferred；不另造 | ✅ |
| G5 | attach_entity | 选定标的后 entity 节点正确挂环节 | ✅ |

### §3.5.2 数据来源真实
| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| D1 | related_party 导入 | 至少 1 Campaign 从 340 节点图拉真实关联方 | ✅ | 无则 concept 占位 |
| D2 | 风险面穿透 | 实控人/明股实债/循环交易标注（D1 引擎） | ⚠️ D1 引擎就绪程度 | 未就绪→标 pending |
| D3 | 危险监控挂节点 | P5/P6/P7 + monitor:dict 挂到节点 → health | ⚠️ | watchlist 已通优先 |

### §3.5.3 联动与可视化
| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| V1 | 下钻入口 | 从 step_11 监管卡 / step_12 卡可进，`?center=` 生效 | ✅ |
| V2 | 双向联动 | 点节点高亮 step_12 相关三支柱/利好 | ✅ |
| V3 | 视觉区分 | confirmed 实线 / inferred 虚线 | ✅ |

### §3.5.4 no-trade
| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| E1 | 无下单/执行 | `rg "立即\|一键\|下单\|place_order" templates/graph/` = 0 | ✅ |

> 共 **12 项**。逐项验证见 §9。

## §4 凭证清单

| 凭证 / 资源 | 用途 | 启动期 |
|---|---|---|
| `COPILOT_REDIS_URL` | 读 monitor:dict | 必须 |
| `related_party_graph` 数据可达 | 风险面/关联方 | 必须（D1 已建） |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| `/graph?center={symbol}` 渲染图谱（concept + 至少 1 entity） | 200 |
| 至少 1 节点 confirmed（有 evidence_ref 官方源）+ 1 节点 inferred | jq |
| 风险面渲染关联方（或 pending 占位） | 200 |
| 危险监控节点接 ≥1 物理探针 hit | jq health≠unknown |
| 双向联动：点节点高亮 step_12 三支柱 | 手测/集成测 |
| 单测 | ≥ 12 passed |

## §6 下一步

本步 ✅ → **波次二（M5/M6/M7）三大工作台联调**：在 step_09 全链路联调基础上，新增「监管卡 → 图谱下钻 → 计划联动」端到端场景，回写阶段验收（step_10 增补项）。

## §7 实施规划

### §7.1 实现要点
| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| 2 表 ORM + migrate | `db/models.py`（追加） | §3.3 | `.tables` 含 graph_nodes/edges |
| `GraphService` | `modules/graph/service.py` | build_concept / attach_entity / center 查询 | G1/G5 |
| `ConfirmService` | `modules/graph/confirm.py` | evidence_ref→confirm_state（复用 Critic 等级） | G3/G4 |
| related_party 导入 | `modules/graph/importer.py` | 从 340 节点图拉子图 | D1 |
| 风险面穿透 | `risk.py` | D1 关联交易引擎结果标注 | D2 |
| 节点挂监控 | `monitor_ref` 关联 step_12 | P5/P6/P7→health | D3/V2 |
| 可视化 + 路由 | `routers/graph_routes.py` + `templates/graph/` | Cytoscape/vis CDN | V1/V3 |

### §7.2 Makefile 合约
| target | 验证 |
|---|---|
| `copilot-step13-prep` | 起 redis + 校验 step_12 campaign_symbols 存在 |
| `copilot-step13-migrate` | 建 2 表 |
| `copilot-step13-build` | 为 demo Campaign 建概念图 + attach 1 entity |
| `copilot-step13-up` | uvicorn `/graph?center=...` 200 |
| `copilot-step13-test` | pytest ≥ 12 |
| `copilot-step13-all` | 端到端 |
| `copilot-step13-status` | 节点数 + confirmed/inferred 分布 + entity 数 |
| `copilot-step13-clean` | 删 demo 图谱 |

### §7.3 给后续执行模型的指引
1. **概念图先行**：`build_concept(campaign)` 只建 concept 节点，多数 inferred；不等标的。
2. **确认靠官方证据**：`ConfirmService` 必须把 evidence_ref 映射到官方源类别；无官方源不得标 confirmed（复用 D2 Critic PHYSICAL/SOFT 等级，禁止另造判据）。
3. **entity 后挂**：step_12 选定标的事件 → `attach_entity(campaign, symbol, concept_node)`。
4. **联动靠 ref**：节点 `monitor_ref` 指向 step_12 `monitor_subscriptions.id`，前端据此双向高亮。
5. **L4 回写**：demo 图谱节点 JSON（含 confirm_state 分布）、related_party 子图导入计数、危险监控节点 health、双向联动截图/集成测、≥12 pytest。
6. **审计**：
   ```bash
   rg -i "立即|一键|下单|place_order" apps/copilot/templates/graph/   # 0
   # confirmed 必有证据：
   sqlite3 data/copilot.db "SELECT COUNT(*) FROM graph_nodes WHERE confirm_state='confirmed' AND (evidence_ref IS NULL OR evidence_ref='')"   # 期望 0
   ```

## §8 部署节奏

| 项 | 本 step |
|---|---|
| 部署面 | 本机 uvicorn + redis |
| Chart | 不改（新增表 + 路由 + 前端 CDN 图库） |
| 上 K3s | 随 D0 整体 |

## §9 准出标准

```bash
# 1) 建表
make copilot-step13-migrate
sqlite3 data/copilot.db ".tables" | grep -E "graph_nodes|graph_edges"

# 2) 建概念图 + attach entity
make copilot-step13-build
curl -s "http://127.0.0.1:8080/api/graph?center=601138" | jq '{nodes:(.nodes|length), entities:[.nodes[]|select(.node_type=="entity")]|length}'

# 3) 确认/推演分布
curl -s "http://127.0.0.1:8080/api/graph?center=601138" | jq '[.nodes[].confirm_state]|group_by(.)|map({state:.[0],n:length})'
# 期望同时含 confirmed 与 inferred

# 4) confirmed 必有证据
sqlite3 data/copilot.db "SELECT COUNT(*) FROM graph_nodes WHERE confirm_state='confirmed' AND (evidence_ref IS NULL OR evidence_ref='')"   # 0

# 5) 危险监控节点 health
curl -s "http://127.0.0.1:8080/api/graph?center=601138" | jq '[.nodes[]|select(.monitor_ref!=null)|.health]|unique'

# 6) 下钻入口
curl -s "http://127.0.0.1:8080/graph?center=601138" | grep -o "产业图谱"

# 7) no-trade 审计
rg -i "立即|一键|下单|place_order" apps/copilot/templates/graph/   # 0

# 8) 单测
pytest tests/copilot/test_graph.py -v   # ≥ 12 passed
pytest tests/copilot/ -q                # 全量不退化

# 9) Makefile
make copilot-step13-all && make copilot-step13-status
```

### §9.1 准出确认
- [ ] §3.5 12 项全绿
- [ ] §9 命令本机跑通
- [ ] L4 `实践记录_step_13_产业图谱关系链研究.md` 已回写
- [ ] 波次二（M5/M6/M7）三工作台下钻/联动闭环可演示

## §10 [Deploy]

ConfigMap 增 `COPILOT_GRAPH_LIB`（cytoscape|vis）。前端图库走 CDN，不入镜像。

## §11 依赖与禁忌

| 类型 | 依赖 | 就绪 | 缺失处理 |
|---|---|---|---|
| 硬上游 | step_12 campaign_symbols/monitor_subscriptions | ✅ | 回前置 |
| 数据 | related_party_graph（340 节点） | ✅ D1 已建 | 无则 concept 占位 |
| 软上游 | D1 关联交易引擎（风险面穿透）+ D2 Architect 产业链 | 部分 | 未就绪→pending 占位 |

**严禁**：把 SOFT 证据标 confirmed；confirmed 无 evidence_ref；图谱含下单/执行动作；伪造关联方关系。

## §12 风险与回退

| 触发 | 应对 | 重试 |
|---|---|---|
| related_party 子图过大 | 按中心标的 N 跳裁剪（启动期默认 2 跳） | — |
| D1 关联交易引擎未就绪 | 风险面标 pending；先做 concept + 物理监控面 | — |
| 可视化库渲染慢 | 节点 > 200 分页/聚合 | — |
| 同问题 > 2 次 | §8.4f：先交付「concept 图 + 确认/推演 + 物理监控挂载」，风险穿透迭代 | — |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-29 | 初版（波次二 M7）：Campaign Part A 产业知识图谱；node_type(concept/entity) 两层 + confirm_state(confirmed/inferred) 两态（复用 D2 Critic PHYSICAL/SOFT 等级）；概念→实体演进；4 视图（生态/机会/风险/危险监控）；与 step_12 双向联动；2 表 schema |
