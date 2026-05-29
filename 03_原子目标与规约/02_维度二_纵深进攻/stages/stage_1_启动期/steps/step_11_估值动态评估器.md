# Step 11 · 估值动态评估器（Valuation Dynamics Evaluator · 戴维斯双击/双杀判定）

## §1 一句话定位与本步交付物

**一句话**：基于纯写死财务公式 + 时序数据库滚动分位，计算每只 active 标的的 `current_pe / forward_pe / peg / pe_percentile_30d/90d/180d/3y` 与同行业中位数对比，输出 `valuation_dynamics` 子结构（嵌入 thesis 卡 + 推 D3 健康度公式新维度），判定「戴维斯双击 / 单击 / 双杀 / 中性」4 档，**不调任何大模型 / 不训 LoRA**——避免历史对话「动态 P/E 反推便宜」的循环论证陷阱。

**交付物**（勾选 = 完成）：

- [ ] **A**（`ValuationDynamics` schema）：Pydantic v2；含 `current_pe / forward_pe / peg / pe_percentile_*` 4 周期 + `industry_median_pe` + `davis_phase` 4 档枚举
- [ ] **B**（`pe_calculator.py`）：纯函数。`current_pe = price / ttm_eps`；`forward_pe = price / consensus_eps_next_y`；`peg = forward_pe / eps_growth_rate_pct`
- [ ] **C**（`pe_percentile.py`）：从 TimescaleDB 拉历史 P/E → 算 30d/90d/180d/3y 分位数（numpy.percentile，纯函数）
- [ ] **D**（`industry_median.py`）：按申万二级行业聚合中位 P/E（akshare 财务接口拉同行业 P/E → 中位数）
- [ ] **E**（`davis_classifier.py`）：4 档判定规则表（见 §3.5.4）
- [ ] **F**（API）：`POST /api/valuation/evaluate/{symbol}` 返完整 ValuationDynamics
- [ ] **G**（与 D2 step_05 thesis 卡集成）：thesis 卡 `valuation_dynamics` 字段在 `valuation_anchor` 旁并列存储
- [ ] **H**（与 D3 step_06 健康度集成）：新增 `valuation_health_score`（与 davis_phase 映射 0~100），作为可选 4 维加权进 health
- [ ] **I**（fact_gate 接入）：P/E 历史分位数据点写入前走 [共享规约 22](../../../../_共享规约/22_事实交叉验证与防幻觉规约.md) `fact_gate.verify`，防止过期数据误用

> **不需要 LoRA / 不调大模型**：完全是数值计算 + 历史分位比较 + 规则判定。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **上溯 L1**：[基石 ②·认知论套利的工程化 §2.3 估值不是单点](../../../../01_顶层概念/06_投资哲学体系总纲.md#基石-认知论套利的工程化) + [基石 ⑥·进攻哲学边界](../../../../01_顶层概念/06_投资哲学体系总纲.md#基石-进攻哲学边界维度二纵深进攻)
> - **上溯 L2**：[02_战略维度/平台与产品/11_标的深度分析与阶段判定实践规划](../../../../../02_战略维度/平台与产品/11_标的深度分析与阶段判定实践规划.md) §三戴维斯双击判定
> - **同模块**：[step_05 thesis 卡片生成器](./step_05_thesis卡片生成器.md) §3.5 / [step_08 业绩弹性闸门](../../../08_业绩弹性闸门_设计.md)
> - **DNA**：[`_System_DNA/02_deep_strike/dna_d2_stage1_step11_valuation_dynamics.yaml`](../../../../_System_DNA/02_deep_strike/dna_d2_stage1_step11_valuation_dynamics.yaml)
> - **共享规约**：[22_事实交叉验证与防幻觉规约](../../../../_共享规约/22_事实交叉验证与防幻觉规约.md) / [21_行情数据源降级与断路器规约](../../../../_共享规约/21_行情数据源降级与断路器规约.md)
> - **L4**：`04_阶段规划与实践/02_维度二_纵深进攻/stage_1_启动期/实践记录_step_11_估值动态评估器.md`（待创建）
> - **上游**：step_05（thesis 卡 schema 升级后含 valuation_dynamics 字段）
> - **下游**：D3 step_06 健康度计算（新增 valuation_health_score 维度）

## §3 数据采集对象 / 落库映射

| 输入 | 来源 | 输出 |
|---|---|---|
| `current_price` | akshare 实时行情 + 共享规约 21 行情断路器 | 计算输入 |
| `ttm_eps` | akshare `stock_financial_em` 或 `eps_ttm` 字段 | `current_pe` |
| `consensus_eps_next_y` | akshare `stock_yjbb_em` 或券商一致预测（启动期可接入 wind / 同花顺 API） | `forward_pe` |
| `eps_growth_rate_pct` | (consensus_eps_next_y - ttm_eps) / abs(ttm_eps) | `peg` |
| 历史 P/E 时序 | TimescaleDB `pe_history` 表（按日落库） | `pe_percentile_*` |
| 同行业 P/E 列表 | akshare 申万二级行业成分股 + 各成分 current_pe | `industry_median_pe` |

**落库表**：

```sql
CREATE TABLE valuation_dynamics (
  symbol VARCHAR(10) NOT NULL,
  evaluated_at TIMESTAMPTZ NOT NULL,
  current_pe NUMERIC(10,4),
  forward_pe NUMERIC(10,4),
  peg NUMERIC(10,4),
  pe_percentile_30d NUMERIC(5,4),     -- [0, 1]
  pe_percentile_90d NUMERIC(5,4),
  pe_percentile_180d NUMERIC(5,4),
  pe_percentile_3y NUMERIC(5,4),
  industry_median_pe NUMERIC(10,4),
  industry_pe_zscore NUMERIC(10,4),   -- (current_pe - industry_median) / industry_std
  davis_phase VARCHAR(20) NOT NULL,   -- davis_double_click / single_click_eps / double_kill / neutral
  valuation_health_score INTEGER,     -- [0, 100] 供 D3 健康度加权
  data_quality_tags TEXT[],           -- 如 ['forward_pe_consensus_stale', 'industry_median_low_sample']
  PRIMARY KEY (symbol, evaluated_at)
);

-- Timescale hypertable
SELECT create_hypertable('valuation_dynamics', 'evaluated_at');
```

## §3.5 数据质量验收矩阵（启动期）

### §3.5.1 财务公式正确性

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| F1 | **current_pe 公式** | `price / ttm_eps`；`ttm_eps <= 0` 时输出 null + tag `negative_eps` | ✅ 纯函数 | — |
| F2 | **forward_pe 公式** | `price / consensus_eps_next_y`；缺一致预测时输出 null + tag `consensus_unavailable` | ✅ | — |
| F3 | **peg 公式** | `forward_pe / eps_growth_rate_pct`；增长率 < 5% 时 peg 失真 → tag `low_growth_peg_unreliable` | ✅ | — |
| F4 | **历史分位准确** | numpy.percentile(history, q*100)；样本 < 30 时 tag `low_sample_percentile` | ✅ | <30 不计算 |
| F5 | **行业中位数** | 申万二级 ≥ 10 个成分；不足 10 个升级到一级 | ✅ | <5 拒绝 |

### §3.5.2 戴维斯 4 档判定规则（核心 · 启动期写死）

| # | davis_phase | 触发条件（AND 关系） | 业务含义 |
|---|---|---|---|
| D1 | `davis_double_click` | `pe_percentile_180d ≥ 0.8` AND `pe_trend_30d > 0` AND `eps_growth_rate_pct ≥ 5%`（戴维斯双击：EPS 涨 + P/E 拔升） | 业绩 + 估值共振，主升浪 |
| D2 | `single_click_eps` | `eps_growth_rate_pct ≥ 5%` AND `pe_percentile_180d ≤ 0.3`（EPS 涨但 P/E 在低位） | 业绩没被市场认可，估值修复机会 |
| D3 | `double_kill` | `eps_growth_rate_pct ≤ -5%` AND `pe_percentile_180d ≤ 0.3` AND `pe_trend_30d < 0`（EPS 跌 + P/E 跌） | 戴维斯双杀，进入冬天 |
| D4 | `neutral` | 不满足上述 3 个 | 中性 |

### §3.5.3 跨维度契约

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| C1 | **与 thesis 卡集成** | thesis 卡 `valuation_dynamics` 字段必须填，缺则置 null + tag | ✅ | — |
| C2 | **与 D3 健康度集成** | `valuation_health_score` 映射：double_click=90 / single_click=70 / neutral=50 / double_kill=20 | ✅ | D3 step_06 升级 health 公式可选 |
| C3 | **fact_gate 接入** | P/E 历史时序数据点写库前走 `fact_gate.verify`（来源 publisher / fetched_at / expires_at） | ✅ | — |

### §3.5.4 防错（启动期硬约束）

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **禁止反推「便宜」** | runtime guard：不允许业务代码用未验证的 `consensus_eps_next_y` 反推 forward_pe 后直接断言「估值便宜」；必须先 fact_gate.verify | ✅ | — |
| E2 | **历史样本期标注** | `pe_percentile_*` 必须带 `sample_start_date / sample_end_date / sample_count` 三元组 | ✅ | — |
| E3 | **同行业基准 as_of** | `industry_median_pe` 必须带 `as_of_date`，过期 7 天自动重算 | ✅ | — |
| E4 | **no auto-trade** | valuation_dynamics 不得嵌入 buy/qmt/auto_trade 字段 | ✅ | assert |

> 共 **5 + 4 + 3 + 4 = 16 项**。

## §4 凭证清单

| 凭证 | 用途 | 何时 |
|---|---|---|
| akshare 财务接口可用 | ttm_eps / consensus_eps_next_y | 必须 |
| TimescaleDB `pe_history` 表已建 | 历史分位 | 必须 |
| 共享规约 21 行情断路器已实现 | current_price 容错 | 必须 |
| 共享规约 22 fact_gate 已部署 | 数据点验证 | 必须 |
| （可选）wind/同花顺一致预测 API | 提高 forward_pe 准确性 | 启动期 akshare 替代亦可 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| active 标的覆盖率 | 100% 有 valuation_dynamics 行 |
| 戴维斯 4 档分类一致率（人工抽检 20 只） | ≥ 90% |
| `make deep-step11-all` 通过 | exit 0 |
| 与 thesis 卡集成 | 100% thesis 含 valuation_dynamics 字段 |

## §6 下一步

本步 ✅ → D3 step_06 健康度公式扩展（接入 valuation_health_score 作为可选 4 维加权）。

**扩展期**：接入券商一致预测 API（成本预算单独评估）+ 自动检测「估值修复」机会（D2 主动嗅探层 candidate registry 增加 single_click_eps 触发器）。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A ValuationDynamics schema** | `apps/deep_strike/valuation/schemas.py` | Pydantic v2；4 档枚举 | jsonschema |
| **B pe_calculator** | `apps/deep_strike/valuation/pe_calculator.py` | 3 个纯函数 + 边界处理 | 单测 ≥ 6（含负 EPS、零增长） |
| **C pe_percentile** | `apps/deep_strike/valuation/pe_percentile.py` | numpy.percentile + 4 周期 | 单测 ≥ 4 |
| **D industry_median** | `apps/deep_strike/valuation/industry_median.py` | 申万二级聚合 + 缓存 24h | 单测 ≥ 3 |
| **E davis_classifier** | `apps/deep_strike/valuation/davis_classifier.py` | 表驱动判定 | 单测 ≥ 4（4 档各 1 正例） |
| **F orchestrator** | `apps/deep_strike/valuation/orchestrator.py` | 编排 B+C+D+E → 写库 + 调 fact_gate | e2e 1 只 |
| **G API** | `apps/deep_strike/api/routes/valuation.py` | POST evaluate | 200 |
| **H 集成 thesis** | 改 `step_05 ThesisCardSchema` 增 `valuation_dynamics` 字段 | 已在 step_05 升级补丁中处理 | schema diff |
| **I 集成 D3 health** | D3 step_06 可选 4 维：sli/narrative/freshness/valuation；权重 yaml 默认 (0.4/0.25/0.15/0.2) | D3 升级单测 | |
| **J 单测** | `tests/deep_strike/test_valuation_*.py` ≥ 17 | — | pytest |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `deep-step11-prep` | TimescaleDB pe_history 表存在 + akshare 可达 |
| `deep-step11-backfill-pe-history` | 拉 active 标的近 3 年日频 P/E（一次性） |
| `deep-step11-evaluate-all` | 全 active 调 orchestrator |
| `deep-step11-davis-distribution` | 输出 4 档分布 |
| `deep-step11-quality-check` | 16 项矩阵 |
| `deep-step11-test` | pytest ≥ 17 |
| `deep-step11-all` | 端到端 |
| `deep-step11-status` | 当日覆盖率 / davis 分布 / 数据质量 tags |
| `deep-step11-clean` | dev only |

### §7.3 给后续执行模型的指引

- **不要调任何大模型**：戴维斯判定完全是数值规则，调 LLM 反而引入幻觉
- **forward_pe 启动期可接受用 akshare 替代 wind**：标 `data_quality_tags=['forward_pe_consensus_akshare_only']`，扩展期再升级
- **同行业中位数 ≥ 10 样本**：不足 10 时升级到申万一级；仍不足 → 拒绝判定 single_click_eps（行业基准不可信）
- **配置驱动**：增减 active 标的只改 `data/config/my_holdings.yaml`；不改代码
- **可重入幂等**：按 `(symbol, evaluated_at_date)` upsert

## §8 部署节奏

| 阶段 | 形态 | 是否本步必须 | 说明 |
|---|---|---|---|
| **tier-1 · 本机** | `uvicorn` port 8082 复用 + pytest | **必须** | 公式 + 分类逻辑本机完成 |
| **P 轨 DB（tier-1 可用）** | TimescaleDB NodePort 30001（与 step_05 同 DB） | 推荐 | `pe_history` + `valuation_dynamics` 两张 hypertable |
| **扩展期** | 接入券商一致预测 API（成本 ¥XX/月，DECISION_PENDING：选 wind 还是同花顺） | 否 | 启动期 akshare 替代 |

## §9 准出标准

- [ ] §3.5 16 项全过
- [ ] active 标的 100% 有 valuation_dynamics 行
- [ ] 人工抽检 20 只 davis 分类一致率 ≥ 90%
- [ ] `make deep-step11-all` exit 0
- [ ] L4 实践记录含 4 档分布 + 抽检结果 + commit；同会话验证
- [ ] thesis 卡 100% 含 valuation_dynamics 字段（与 step_05 schema 升级联动）

## §10 [Deploy]

启动期 tier-1（本机 + 连 P 轨 DB）。扩展期合并到 deep-strike Deployment。

## §11 依赖

step_05（thesis 卡 schema 升级）、共享规约 21（行情断路器）、共享规约 22（fact_gate）、TimescaleDB（pe_history hypertable）。

**严禁**：调大模型判戴维斯；用未验证 consensus_eps 反推「便宜」；valuation_dynamics 嵌入 buy/qmt 字段。

## §12 风险

| 触发 | 动作 |
|---|---|
| akshare consensus_eps 缺失率 > 30% | 标 `consensus_unavailable` 不阻塞；扩展期接 wind |
| 历史样本不足（新股 < 30 日） | tag `low_sample_percentile`，不输出 davis_phase |
| 同行业基准 < 5 样本 | 拒绝判定 single_click_eps；其余 3 档仍可判 |
| 同问题 ≥ 2 次（§8.4f） | 回收 / 退出 |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-27 | **初版 v1.0**（本轮关键重构 · §4.5 同步 .cursorrules）：从 Gemini 对话「动态 P/E 反推便宜」循环论证抽象出「估值动态评估器」；3 公式 + 4 周期分位 + 行业中位 + 4 档判定；纯写死纯函数，不调 LLM；与 D2 thesis 卡 / D3 健康度 / 共享规约 22 fact_gate 全集成 |
