# Step 16 · 规划中证伪与持续监控（M10 · 4 类证伪任务 + 认知快照 + 持续数据采集）

> **波次定位**：D0 启动期**波次三**第 3 步。「📝规划中」工作区 = 对行情雷达的全方位评估做**验证 / 补充 / 持续监控配置**。雷达是顶级模型「下结论」，规划区是「**对结论持续证伪与数据沉淀**」。**前置**：step_14（候选 `analysis_snapshot` + `workspace_artifacts`）、step_15（生命周期假设）、step_12（`monitor_subscriptions` 机制 ✅）。**架构总纲**：[25_ §1.2/§5](../../../../_共享规约/25_四区漏斗_三段流水线_架构脊柱_设计.md)。

## §1 一句话定位与本步交付物

**一句话**：规划区展示雷达**认知快照**（生态位/价值链/龙头/壁垒/利好/风险），并把其中的**关键论点拆成 4 类可证伪监控任务**——
**🧱 物理壁垒逻辑证伪**（P5 招标/P6 海关/P7 产能数据采集）、**🕸️ 生态位定位证伪**（产业链节点关系/份额）、**📈 订单/关键利好追踪证伪**（催化是否兑现）、**⚠️ 关键风险监控**（财务/极寒防御）；
每类设**定时数据采集 + verdict 判定**，为「是否晋级执行」积累证据。

**交付物**（勾选 = 完成）：
- [ ] **A 认知快照视图**：规划区档案卡读 `campaign_symbols.analysis_snapshot` + `workspace_artifacts`（雷达评估结果原样呈现 + 溯源链链接）
- [ ] **B 4 类证伪任务建模**：扩展 `monitor_subscriptions.falsify_type ∈ {moat,niche,catalyst,risk}` + `hypothesis`（待证伪论点文本）
- [ ] **C 证伪 verdict 引擎**：`modules/planning/falsify.py` → 拉数据源 → 判 `verdict ∈ {ok(成立),warn,alert(被证伪),pending}`（复用 `refresh_verdicts`）
- [ ] **D 一键建任务**：从认知快照某论点 `POST /api/campaigns/{id}/falsify`（论点 → 选源 → 频率 → 起监控）
- [ ] **E 证据累积**：每次判定写 `stage_artifacts(workspace=planning)` + 更新 `monitor_subscriptions.evidence_ref`；证伪历史可查
- [ ] **F 晋级就绪度**：聚合 4 类 verdict → `readiness`（论点成立率/被证伪数）→ advisory「是否可进入执行」（人工确认晋级）
- [ ] **G 前端**：认知快照区块 + 4 类证伪任务卡（hypothesis + verdict 灯 + 证据链 + 最近判定时间）+「设监控」表单 +「晋级执行」确认按钮
- [ ] **H 单测**：≥ 12（4 类 verdict、被证伪 alert、pending 不伪造、就绪度聚合、晋级人工确认、证据落库）

> **永久红线**：证伪 verdict 缺源 → `pending`，**禁默认 ok**；晋级执行需 `human_confirmation_required`。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **架构脊柱**：[25_ §1.2 规划区职责 / §5 安全扫描 / §2 三段（planning 区 T0+T1 证伪）](../../../../_共享规约/25_四区漏斗_三段流水线_架构脊柱_设计.md)
> - **本阶段总览**：[steps/README §一-2 波次三](./README.md)
> - **DNA 键**：[`dna_stage_1_启动期.yaml`](../../../../_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml) `deliverables.modules[M10] / falsify_tasks`
> - **L4 实践记录**：[实践记录_step_16_规划中证伪与持续监控](../../../../../04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/实践记录_step_16_规划中证伪与持续监控.md)（执行时生成）
> - **上游 step**：← step_14（`analysis_snapshot`）/ step_15（生命周期假设）/ step_12（`monitor_subscriptions` 三支柱 ✅）
> - **下游 step**：→ step_17（就绪→执行）
> - **跨维上游**：D3 P5/P6/P7 + `MonitorDictReader`（moat 物理证伪）；D2 Architect 产业链（niche）+ Sniffer（catalyst）；D1 `FinancialFraudEngine`+health（risk）
> - **复用规约**：[20_监控字典规约](../../../../_共享规约/20_监控字典规约.md)（指标字典）· [22_事实交叉验证与防幻觉](../../../../_共享规约/22_事实交叉验证与防幻觉规约.md)（证伪独立源）

## §3 数据采集对象 / 落库映射

| 业务对象 | ORM 表/字段 | 来源 | 缺失语义 |
|---|---|---|---|
| 认知快照 | `campaign_symbols.analysis_snapshot(JSON)` + `workspace_artifacts(雷达)` | step_14 晋级带入 | 无快照→提示先经雷达 |
| 4 类证伪任务 | `monitor_subscriptions.{falsify_type,hypothesis,indicator,source,frequency,verdict}` | 用户/快照拆解 | 缺源→pending |
| 判定证据 | `stage_artifacts(workspace=planning,stage)` + `evidence_ref` | 各数据源 | — |
| 晋级就绪度 | 聚合计算（不落表，API 实时） | 4 类 verdict | — |

### §3.1 4 类证伪任务数据源（核心）

| falsify_type | 待证伪论点示例 | 数据源（T0 采 + T1 判） | verdict 逻辑 |
|---|---|---|---|
| 🧱 `moat` 物理壁垒 | "其产能/份额壁垒真实存在" | P7 产能 / P5 招标 / P6 海关 + monitor:dict | 持续 hit→ok；hit 消失/反向→alert |
| 🕸️ `niche` 生态位 | "其处产业链卡脖子关键节点/龙头" | D2 Architect 产业链节点 + 份额数据 | 节点关系成立→ok；被替代→alert |
| 📈 `catalyst` 利好追踪 | "X 利好将在 Y 月兑现" | D2 Sniffer 三源 + 公告/订单 | 兑现→ok(realized)；落空/延期→warn/alert |
| ⚠️ `risk` 关键风险 | "无财务造假/重大风险" | `FinancialFraudEngine`(T1) + D1 极寒防御 + D3 health | 正常→ok；fraud/reject→alert |

> **证伪而非证实**：每条 = 一个可被推翻的假设（hypothesis）；用**独立源**交叉验证（对齐 22_ 规约）；缺源 `pending`，不默认成立。

## §3.5 数据质量验收矩阵（M10 · 仅启动期负责）

| # | 分析维度 | 必产字段 | 启动期覆盖 | 降级 |
|---|---|---|---|---|
| F1 | 认知快照可读 | analysis_snapshot 原样呈现 + 溯源链接 | ✅ | 无快照→提示 |
| F2 | 4 类任务齐 | 每档案可建 moat/niche/catalyst/risk | ✅ 机制 | 源缺→pending |
| F3 | moat 接物理探针 | ≥1 条接 P5/P6/P7 真实 hit | ⚠️ watchlist 已通优先 | 缺→pending |
| F4 | risk 接财务测谎 | ≥1 条接 `FinancialFraudEngine` | ✅ 现成 LoRA | 未 ingest→pending |
| F5 | verdict 真实 | 带 last_checked_at + source + evidence_ref | ✅ | — |
| F6 | 不伪造 | 缺源 pending，被证伪 alert，禁默认 ok | ✅ | — |
| F7 | 证据累积 | 每次判定落 stage_artifacts 可查历史 | ✅ | — |

> **准出**：F1/F2/F4/F5/F6/F7 必绿；F3 至少 1 条 watchlist 已通标的接真实 hit。

## §4 真实数据源与凭证清单

**§4.1**：moat = D3 P5/P6/P7 + monitor:dict（Redis）；niche = D2 Architect（Redis/库）；catalyst = D2 Sniffer；risk = FinancialFraudEngine(vLLM LoRA) + cryo stream + health。

**§4.2 凭证**
| 凭证 | 用途 | 写在 |
|---|---|---|
| `COPILOT_REDIS_URL` | 4 源读取 | `.env` |
| `VLLM_BASE_URL` / fraud LoRA | risk 财务测谎(T1) | `.env`（未就绪→pending） |
| 无新增密钥 | — | — |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 规划档案卡展示认知快照 + 溯源链接 | 200 + grep |
| 4 类证伪任务各建 ≥1（可 pending） | 查 monitor_subscriptions falsify_type |
| moat ≥1 接真实 P5/P6/P7 hit | jq verdict≠pending |
| risk ≥1 接 FinancialFraudEngine 真实判定 | jq |
| 构造被证伪场景 → verdict=alert（非默认 ok） | jq |
| 晋级就绪度 advisory + 人工确认晋级 | POST + human_confirmation |
| 单测 | ≥ 12 passed |

## §6 下一步（一行）

本步 ✅ → **step_17 执行中仓位指导**：就绪度达标且人工确认 → Campaign `stage=executing`，进入持仓×价格×仓位指导。触发：4 类证伪任务可持续判定 + 就绪度聚合可用。

## §7 实施规划

### §7.1 实现要点

| 实现要点 | 涉及代码位置 | 关键设计决策 | 验证标准 |
|---|---|---|---|
| A 认知快照 | `modules/planning/dossier.py` + 模板 | 读 analysis_snapshot + workspace_artifacts；溯源链链接到 stage_artifacts | F1 |
| B 证伪建模 | `db/models.py` 扩 `monitor_subscriptions` | 加 `falsify_type`,`hypothesis`；复用现有订阅表 | `.schema` 反映 |
| C verdict 引擎 | `modules/planning/falsify.py`（扩 `monitor.refresh_verdicts`） | 4 类各自数据源拉取 + 判定；缺源 pending；被推翻 alert | F2~F6 单测 |
| C2 risk 财务测谎 | 调 `FinancialFraudEngine.analyze` | T1 LoRA；未就绪→pending（不伪造 ok） | F4 单测 |
| D 一键建任务 | `routers/planning_routes.py` | 从快照论点→hypothesis→订阅 | POST + 查得 |
| E 证据累积 | `falsify.py` 写 `stage_artifacts(workspace=planning)` | 每判定一条；evidence_ref 更新 | F7 单测 |
| F 就绪度 | `service.py` `compute_readiness` | 论点成立率/被证伪数 → advisory；晋级 human_confirmation | F 单测 |
| G 前端 | `templates/planning/` planning partial | 快照区 + 4 类证伪卡(verdict 灯) + 设监控表单 + 晋级确认 | curl + 截图 |
| H 单测 | `tests/copilot/test_falsify.py` | 4 类/alert/pending/就绪度/晋级/证据 | `pytest -q` ≥ 12 |

### §7.2 Makefile 合约

| target | 用途 | 入参 | 验证 |
|---|---|---|---|
| `copilot-step16-prep` | 起 redis + 校验 step_14 快照 | `COPILOT_REDIS_URL` | 退出码 0 |
| `copilot-step16-migrate` | 扩 monitor_subscriptions 列 | — | `.schema` 反映 |
| `copilot-step16-falsify` | demo：建 4 类任务 + 跑判定 | `VLLM_BASE_URL` | verdict 落库 |
| `copilot-step16-test` | 单测 | — | ≥ 12 passed |
| `copilot-step16-all` | 端到端 | 合并 | 全退出码 0 |
| `copilot-step16-status` | 4 类任务数 + verdict 分布 + 就绪度 | — | 快照 |
| `copilot-step16-clean` | 删 demo 任务 | — | 已删 |

### §7.3 给后续执行模型的指引

1. **复用 step_12 `monitor.refresh_verdicts`**：本步是其「证伪化」扩展（加 falsify_type/hypothesis + 4 源），勿另起炉灶。
2. **缺源 pending、被推翻 alert**：F6 红线，禁默认 ok（守 no-mock + 22_ 防幻觉）。
3. **risk 优先接 `FinancialFraudEngine`**（现成 LoRA T1），是 §5 安全扫描在规划区的落点。
4. **证据落 `stage_artifacts(workspace=planning)`**：每次判定一条，支撑就绪度与审计。
5. **晋级人工确认**：就绪度只给 advisory，晋级需用户点确认（no-auto-execute）。
6. **L4 回写**：4 类任务 JSON、moat 真实 hit、risk 真实测谎、被证伪 alert demo、就绪度、≥12 pytest。
7. **审计**：`rg -i "buy|qmt|auto_trade|order_id|立即|一键|下单" apps/copilot/modules/planning/` = 0。

## §8 部署节奏

| 项 | 本 step |
|---|---|
| 部署面 | 本机 uvicorn + redis（+ vLLM 可选） |
| Chart | 不改（扩列 + 路由） |
| 必须层级 | 本机开发 |

## §9 准出标准

```bash
cd diting-src
make copilot-step16-migrate
sqlite3 data/copilot.db ".schema monitor_subscriptions" | grep -E "falsify_type|hypothesis"
make copilot-step16-falsify
curl -s "http://127.0.0.1:8080/api/campaigns/1/falsify" | jq 'group_by(.falsify_type)|map({type:.[0].falsify_type,verdicts:[.[].verdict]})'
# moat 真实 hit / risk 真实测谎 / 被证伪 alert
curl -s "http://127.0.0.1:8080/api/campaigns/1/falsify" | jq '[.[]|select(.falsify_type=="moat" and .verdict!="pending")]|length'
curl -s "http://127.0.0.1:8080/api/campaigns/1/readiness" | jq '{ok_rate,falsified,advice}'
# no-auto-execute
rg -i "buy|qmt|auto_trade|order_id|立即|一键|下单" apps/copilot/modules/planning/   # 0
pytest tests/copilot/test_falsify.py -q   # ≥ 12
pytest tests/copilot/ -q
make copilot-step16-all && make copilot-step16-status
```

### §9.1 准出确认
- [ ] §3.5 F1~F7（必绿全绿；F3 ≥1 真实 hit）
- [ ] §9 本机跑通
- [ ] L4 `实践记录_step_16_*.md` 回写
- [ ] 通知 step_17 owner：就绪度达标 Campaign 可晋级执行

## §10 [Deploy]

ConfigMap 增 `FALSIFY_DEFAULT_FREQ`（默认判定频率）、`READINESS_OK_RATE_THRESHOLD`（晋级建议阈值）。

## §11 依赖与被依赖

- **上游**：step_14 快照 + step_12 monitor 机制 ✅；D3 P5/P6/P7（moat）；D1 FinancialFraudEngine（risk）
- **下游**：step_17 读就绪度晋级
- **不能 mock**：4 类 verdict 缺源 pending，禁默认 ok；risk 用真实 LoRA 判定

## §12 风险与回退

| 触发 | 应对 | 重试 |
|---|---|---|
| niche/catalyst 上游未就绪 | 对应任务 pending；moat+risk 先跑 | — |
| vLLM fraud LoRA 未起 | risk 接 health 代理 + 标 pending | — |
| 同问题 > 2 次 | §8.4f：先交付 moat+risk 两类证伪最小闭环，niche/catalyst 迭代 | — |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-30 | 初版（波次三 M10）：规划区 = 雷达评估的验证/补充/持续监控——认知快照原样呈现 + 溯源链 + 4 类可证伪监控任务（🧱物理壁垒 P5/P6/P7 / 🕸️生态位定位 / 📈订单利好追踪 / ⚠️关键风险 FinancialFraudEngine）+ 证伪 verdict 引擎（缺源 pending/被推翻 alert，禁默认 ok）+ 证据累积 stage_artifacts + 晋级就绪度 advisory（人工确认）；扩展 monitor_subscriptions(falsify_type/hypothesis)；F1~F7 质量矩阵；no-mock/防幻觉/no-auto-execute 红线 |
