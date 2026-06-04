# Step 17 · 执行中仓位指导（M11 · 持仓×实时价×仓位 advisory + 安全扫描门控）

> **波次定位**：D0 启动期**波次三**第 4 步（漏斗末端）。「🚀执行中」工作区 = 调研规划充分、人工确认晋级后，对**已建仓标的**做持仓与实时价监控，给出**建仓/加仓/浮盈减仓/浮亏处理**的 advisory 操作建议。**前置**：step_16（就绪度达标晋级）、step_11（持仓监管卡 ✅）、`holdings_sot`（持仓 SoT ✅）。**架构总纲**：[25_ §1.2/§5](../../../../_共享规约/25_四区漏斗_三段流水线_架构脊柱_设计.md)。

## §1 一句话定位与本步交付物

**一句话**：执行区扫描**市场实时价格波动 × 我的持仓**（成本价/持股数/当前仓位%/浮盈亏%），结合规划区证伪结论 + 路线图建仓窗 + 阶段，给出**仓位指导 advisory**（建仓/加仓/浮盈减仓/浮亏减仓/持有/清仓提示）；**盘后定时安全扫描**（财务测谎）流入风险，**fraud 时压制加仓建议**。**全 advisory，绝不下单。**

**交付物**（勾选 = 完成）：
- [ ] **A 执行档案**：执行中 Campaign 标的卡读 `holdings_sot`（成本/持股/仓位%）+ `MarketQuoteClient`（实时价）→ 浮盈亏% 实时算（T0）
- [ ] **B 仓位指导引擎（T0 规则 + 证据）**：`modules/execution/advisor.py` → `advice_action`（建仓/加仓/减仓/持有/清仓提示，全 advisory）+ rationale（引规划证伪 + 阶段 + 建仓窗）
- [ ] **C 执行建议落库**：`execution_advices` 表（current_price/cost_price/position_pct/unrealized_pnl_pct/advice_action/rationale/as_of）
- [ ] **D 盘后安全扫描门控**：定时 `FinancialFraudEngine.analyze`（T1）→ risk verdict；fraud/reject → **压制加仓建议**（标红 advisory）
- [ ] **E 一波完成归档**：标的了结 → Campaign 归档；若 `long_multiwave` 回流路线图「下一波待规划」（漏斗闭环，见 step_15）
- [ ] **F 前端**：执行档案卡（持仓×实时价×浮盈亏 + 阶段 chip）+ advisory 建议条（动作标签 + 理由 + 证据链）+ 安全扫描状态 + 归档/回流按钮
- [ ] **G 单测**：≥ 12（浮盈亏算、各 advice 分支、fraud 压制加仓、no-auto-execute schema、归档回流、缺实时价降级）
- [ ] **H Makefile**：`copilot-step17-prep/migrate/advise/safety-scan/test/all/status/clean`

> **永久红线（no-auto-execute）**：`execute_mode='advisory'` + `human_confirmation_required=1`；schema **禁** `buy/qmt/auto_trade/order_id/webhook_target`；模板**禁**下单/一键/立即按钮。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **架构脊柱**：[25_ §1.2 执行区职责 / §5 安全扫描门控 / §8 no-auto-execute](../../../../_共享规约/25_四区漏斗_三段流水线_架构脊柱_设计.md)
> - **执行中工作区（独立功能 · 可选参考）**：[28_ 执行中专属 T0-T2 监控开发计划](../../../../_共享规约/28_工业富联执行中专属T0-T2监控开发计划.md)（以执行区为主文档 · 香港 ECS · 601138 首版 profile · **不绑定本 step 准出**）
> - **本阶段总览**：[steps/README §一-2 波次三](./README.md)
> - **DNA 键**：[`dna_stage_1_启动期.yaml`](../../../../_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml) `deliverables.modules[M11] / execution_advisory`
> - **L4 实践记录**：[实践记录_step_17_执行中仓位指导](../../../../../04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/实践记录_step_17_执行中仓位指导.md)（执行时生成）
> - **上游 step**：← step_16（就绪度晋级）/ step_11（持仓监管卡 ✅）/ step_15（建仓窗 + 归档回流）
> - **下游 step**：→ step_15（long_multiwave 回流路线图）
> - **跨维上游**：行情 `MarketQuoteClient`（实时价 ✅）；`holdings_sot`（持仓 SoT ✅）；D1 `FinancialFraudEngine`（安全扫描 T1）；D2 Timer（阶段）；D4 卖出（sell_signal 提示）

## §3 数据采集对象 / 落库映射

| 业务对象 | ORM 表/字段 | 来源 | 缺失语义 |
|---|---|---|---|
| 持仓 | `holdings_sot`（成本/持股/仓位%） | `MY_HOLDINGS_YAML` SoT ✅ | 未持仓→建仓建议态 |
| 实时价 | `MarketQuoteClient.get_quote` | 腾讯/新浪/东财 → akshare | 限流→stale 标注 + 用收盘 |
| 浮盈亏 | T0 算 `(price-cost)/cost` | 上两者 | 缺成本→pending |
| 执行建议 | `execution_advices.*` | advisor 引擎 | — |
| 安全扫描 | `monitor_subscriptions(falsify_type='safety')` + `FinancialFraudEngine` | T1 LoRA | 未就绪→pending（不压制） |

### §3.1 仓位指导规则（T0 规则 + 规划证据 · advisory）

| 场景 | 触发（示例规则） | advice_action（advisory） | 证据来源 |
|---|---|---|---|
| 建仓 | 未持仓 + 就绪度达标 + 在建仓窗 + 阶段=潜伏/主升初 | "建议分批建仓至目标仓位 X%" | step_16 就绪度 + step_15 建仓窗 |
| 加仓 | 已持仓 + 浮盈 + 证伪持续 ok + 阶段未到撤退 + **无 fraud** | "可考虑加仓（注意单一仓位上限）" | 证伪 verdict + 阶段 |
| 浮盈减仓 | 浮盈 ≥ 阈值 + 阶段=兑现/退潮 或 利好已 realized | "建议浮盈分批减仓锁定" | Timer + catalyst realized |
| 浮亏处理 | 浮亏 ≥ 阈值 + 证伪被推翻(alert) 或 逻辑破坏 | "逻辑被证伪/破坏，建议评估止损" | 证伪 alert + sell_signal |
| 持有 | 假设成立 + 阶段持续 + 无信号 | "维持持仓，继续监控" | — |
| 清仓提示 | 重大风险/fraud/逻辑全破坏 | "重大风险，建议评估清仓" | fraud + cryo reject |

> 全部 **advisory 标签 + 理由 + 证据链**，不含任何下单语义；阈值（浮盈/浮亏/单一仓位上限）配置驱动。

### §3.2 安全扫描门控（§5 落点）

```
盘后定时 → FinancialFraudEngine.analyze(symbol)  [T1 LoRA]
  → verdict ∈ {normal, fraud}
  → fraud/reject  ⇒  压制本标的"加仓/建仓"建议（改标红 advisory「风险未排除，暂缓加仓」）
  → 写 stage_artifacts(workspace=executing) 审计
```

## §3.5 数据质量验收矩阵（M11 · 仅启动期负责）

| # | 分析维度 | 必产字段 | 启动期覆盖 | 降级 |
|---|---|---|---|---|
| X1 | 持仓真实 | 成本/持股/仓位% ← holdings_sot | ✅ | 未持仓→建仓态 |
| X2 | 实时价 | current_price（实时或 stale 标注） | ✅ MarketQuote | 限流→收盘+stale |
| X3 | 浮盈亏 | unrealized_pnl_pct 真实算 | ✅ T0 | 缺成本→pending |
| X4 | 建议带证据 | advice_action + rationale + 证据链 | ✅ | — |
| X5 | 安全扫描门控 | fraud → 压制加仓 | ✅ FinancialFraudEngine | 未就绪→pending（不压制不伪造放行） |
| X6 | no-auto-execute | schema/模板无下单语义 | ✅ | — |
| X7 | 归档回流 | 了结归档；long→回流 next_wave | ✅ | — |

> **准出**：X1~X7 全绿（X5 LoRA 未就绪可 pending 但须显式）。

## §4 真实数据源与凭证清单

**§4.1**：实时价 = MarketQuote(腾讯/新浪/东财) → akshare 降级；持仓 = holdings_sot；安全扫描 = FinancialFraudEngine(vLLM LoRA)。

**§4.2 凭证**
| 凭证 | 用途 | 写在 |
|---|---|---|
| `MY_HOLDINGS_YAML` | 持仓 SoT | `.env` ✅ |
| `COPILOT_REDIS_URL` | 阶段/sell_signal/cryo | `.env` |
| `VLLM_BASE_URL` / fraud LoRA | 盘后安全扫描(T1) | `.env`（未就绪→pending） |
| `EXEC_PNL_TAKE_PROFIT_PCT` / `EXEC_PNL_STOP_PCT` / `EXEC_MAX_SINGLE_POS_PCT` | 仓位阈值 | `.env`/ConfigMap |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| 执行档案卡显示持仓×实时价×浮盈亏 | 200 + grep |
| 给出 ≥1 条 advisory 建议（带理由+证据链） | jq advice_action+rationale |
| 浮盈/浮亏阈值触发对应建议分支 | jq（构造场景） |
| 盘后安全扫描 fraud → 加仓建议被压制（标红） | jq |
| no-auto-execute 审计 | rg = 0 |
| 了结归档；long_multiwave 回流路线图 | jq next_wave |
| 单测 | ≥ 12 passed |

## §6 下一步（一行）

本步 ✅ → **波次三收口**：四区漏斗端到端贯通（雷达→路线图→规划→执行→滚动回流）。触发：执行建议 advisory 稳定 + 安全门控生效 + 归档回流闭环可演示。

## §7 实施规划

### §7.1 实现要点

| 实现要点 | 涉及代码位置 | 关键设计决策 | 验证标准 |
|---|---|---|---|
| A 执行档案 | `modules/execution/dossier.py` + 模板 | 合 holdings_sot + MarketQuote；T0 算浮盈亏；实时价 stale 标注 | X1~X3 |
| B 仓位引擎 | `modules/execution/advisor.py` | §3.1 规则表；纯函数 T0 + 引规划/阶段证据；全 advisory；阈值配置驱动 | X4 单测 |
| C 建议落库 | `db/models.py` `execution_advices` | as_of 快照；可查历史 | `.tables` 反映 |
| D 安全门控 | `advisor.py` 调 `FinancialFraudEngine` | §3.2 fraud→压制加仓；写 stage_artifacts(executing) | X5 单测 |
| E 归档回流 | `service.py` archive | 了结归档；long_multiwave 回 step_15 next_wave | X7 单测 |
| F 前端 | `templates/planning/` execution partial | 档案卡 + advisory 建议条 + 安全状态 + 归档/回流按钮（无下单） | curl + 截图 |
| G 单测 | `tests/copilot/test_execution.py` | 浮盈亏/分支/fraud 压制/schema/归档/stale | `pytest -q` ≥ 12 |

### §7.2 Makefile 合约

| target | 用途 | 入参 | 验证 |
|---|---|---|---|
| `copilot-step17-prep` | 校验 holdings_sot + step_16 就绪 | `MY_HOLDINGS_YAML` | 退出码 0 |
| `copilot-step17-migrate` | 建 execution_advices 表 | — | `.tables` 反映 |
| `copilot-step17-advise` | demo：持仓首只 → advisory 建议 | `EXEC_*` 阈值 | 建议落库 |
| `copilot-step17-safety-scan` | demo：盘后安全扫描 + 门控 | `VLLM_BASE_URL` | fraud 压制证据 |
| `copilot-step17-test` | 单测 | — | ≥ 12 passed |
| `copilot-step17-all` | 端到端 | 合并 | 全退出码 0 |
| `copilot-step17-status` | 执行 Campaign 数 + 建议分布 + 安全 verdict | — | 快照 |
| `copilot-step17-clean` | 删 demo | — | 已删 |

### §7.3 给后续执行模型的指引

1. **复用 step_11 持仓监管卡 + holdings_sot + MarketQuoteClient**，本步加「仓位指导 advisory 引擎 + 安全门控」，勿重写持仓读取。
2. **仓位引擎纯 T0 规则 + 引证据**（规划证伪/阶段/建仓窗），不调 T2；阈值全配置驱动。
3. **fraud 压制加仓是硬门控**（X5），LoRA 未就绪则 pending（**不伪造放行**也**不伪造拦截**）。
4. **no-auto-execute 是最强红线**：schema/模板/路由全程审计 rg=0；建议只到「文字 + 理由 + 证据」。
5. **归档回流闭环**：了结 long_multiwave 标的回 step_15 路线图，形成完整漏斗滚动。
6. **L4 回写**：持仓×实时价×浮盈亏 JSON、各 advice 分支、fraud 压制 demo、归档回流、advisory rg 0、≥12 pytest。
7. **审计**：`rg -i "buy|qmt|auto_trade|order_id|webhook_target|立即|一键|下单" apps/copilot/modules/execution/ apps/copilot/templates/planning/` = 0。
8. **执行中工作区（28_）**：若做 601138 深度体检，以 [28_](../../../../_共享规约/28_工业富联执行中专属T0-T2监控开发计划.md) 为准（`modules/executing/` · 香港 Pod · 前端持仓 CRUD）；本 step 的 `advisor.py` 仅可复用，**不得**用本 step 裁剪 28_ 功能范围。

## §8 部署节奏

| 项 | 本 step |
|---|---|
| 部署面 | 本机 uvicorn + redis（+ vLLM 可选） |
| Chart | 不改（新表 + 路由 + ConfigMap 阈值）；盘后安全扫描随 APScheduler |
| 必须层级 | 本机开发 |

## §9 准出标准

```bash
cd diting-src
make copilot-step17-migrate
sqlite3 data/copilot.db ".tables" | grep execution_advices
make copilot-step17-advise
curl -s "http://127.0.0.1:8080/api/campaigns/1/execution" | jq '.[0] | {symbol,current_price,cost_price,position_pct,unrealized_pnl_pct,advice_action,rationale}'
# 安全门控：fraud 压制加仓
make copilot-step17-safety-scan
curl -s "http://127.0.0.1:8080/api/campaigns/1/execution" | jq '[.[]|select(.advice_action|test("暂缓加仓|风险未排除"))]'
# no-auto-execute
rg -i "buy|qmt|auto_trade|order_id|webhook_target|立即|一键|下单" apps/copilot/modules/execution/ apps/copilot/templates/planning/   # 0
pytest tests/copilot/test_execution.py -q   # ≥ 12
pytest tests/copilot/ -q
make copilot-step17-all && make copilot-step17-status
```

### §9.1 准出确认
- [ ] §3.5 X1~X7 全绿（X5 LoRA 未就绪显式 pending）
- [ ] §9 本机跑通
- [ ] L4 `实践记录_step_17_*.md` 回写
- [ ] 通知波次三收口：四区漏斗端到端贯通可演示

## §10 [Deploy]

ConfigMap 增 `EXEC_PNL_TAKE_PROFIT_PCT`/`EXEC_PNL_STOP_PCT`/`EXEC_MAX_SINGLE_POS_PCT`/`EXEC_SAFETY_SCAN_CRON`。

## §11 依赖与被依赖

- **上游**：step_16 就绪度晋级；step_11 持仓卡 + holdings_sot ✅；MarketQuoteClient ✅；D1 FinancialFraudEngine
- **下游**：step_15（long_multiwave 回流）
- **不能 mock**：浮盈亏用真实持仓+实时价；安全扫描用真实 LoRA；缺则 pending/stale，禁伪造

## §12 风险与回退

| 触发 | 应对 | 重试 |
|---|---|---|
| 实时行情限流 | 收盘价 + stale 标注，建议仍出但注明 | — |
| fraud LoRA 未起 | 安全扫描 pending（不压制不放行，UI 提示待扫描） | — |
| 同问题 > 2 次 | §8.4f：先交付「持仓×实时价×浮盈亏 + advisory 建议」最小闭环，安全门控迭代 | — |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-06-04 | 链入 [28_ 执行中工作区开发计划](../../../../_共享规约/28_工业富联执行中专属T0-T2监控开发计划.md)（独立功能文档 · 香港 ECS · 与 M11 可选参考） |
| 2026-05-30 | 初版（波次三 M11 · 漏斗末端）：执行区持仓×实时价×仓位 → advisory 仓位指导引擎（建仓/加仓/浮盈减仓/浮亏处理/持有/清仓提示 6 场景规则 + 引规划证伪/阶段/建仓窗证据）+ 盘后安全扫描门控（FinancialFraudEngine fraud→压制加仓）+ 一波完成归档 + long_multiwave 回流路线图闭环；execution_advices 表；X1~X7 质量矩阵；no-auto-execute 最强红线（schema/模板/路由 rg=0） |
