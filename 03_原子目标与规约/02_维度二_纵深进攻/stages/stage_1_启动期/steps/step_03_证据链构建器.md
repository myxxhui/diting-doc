# Step 03 · 证据链构建器（四段流水线 · 结构化 Evidence[]）

## §1 一句话定位与本步交付物

**一句话**：把 step_02 的财报指标 + 公告全文加工成**结构化证据链**（财务 / 公告 / 行业 / 产业链四类），每 active 标的每次扫描产出 ≥3 条可引用 evidence（含 type / source / content / date / url / source_id），落 `evidence_records` 供 step_04/05/07 消费；**同时**（Lighthouse-Alpha 扩展）实现 **The Critic 物理证伪门禁**——对 step_02 嗅探候选簇（`sniffer_clusters`）执行"物理底线优先于财务证据"判定，产出 `physical_gate: true/false` 字段（type=`physical_gate` 第五类 evidence），凡 `physical_gate=false` 的候选直接拦截，不进入 step_04 The Mapper。

**交付物**（勾选 = 完成）：
- [ ] **A**（`EvidenceChainBuilder` 四段流水线）：`fetch_financial` → `fetch_announcements` → `enrich_industry` → `assemble_chain`
- [ ] **B**（证据 schema）：Pydantic `Evidence`（type / source / content / date / url / confidence / source_id）
- [ ] **C**（落库）：`evidence_records` 表；每 symbol 每 `scan_id` ≥3 条；幂等 `(symbol, scan_id, evidence_idx)`
- [ ] **D**（可追溯）：100% `source_id` 可 JOIN 回 `financial_indicators` 或 `announcements`
- [ ] **E**（质量脚本）：`training/scripts/validate_evidence_chain_quality.py` 对照 §3.5 全项
- [ ] **F**（单测）：`pytest tests/deep_strike/test_evidence_chain.py -v` ≥ 6 passed
- [ ] **G**（Makefile）：`make deep-step03-all` 端到端通过

> **本步阻塞 step_04/05**：无证据链则 thesis 卡片 `evidence_chain` 必填项无法达标；**禁止** LLM 编造无 `source_id` 的证据。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L2 哲学**：[02_维度二_纵深进攻 · 04_实践策略规划](../../../../../02_战略维度/02_维度二_纵深进攻/04_实践策略规划.md)（能力圈 · 纵深）
> - **本阶段总览**：[stage_1_启动期/README](../README.md)
> - **L3 数据**：[../03_数据采集与预处理.md](../03_数据采集与预处理.md) §三 证据链类型与字段
> - **L3 技术**：[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md) §三 证据链模块
> - **DNA 键**：`_System_DNA/02_deep_strike/dna_stage_1_启动期.yaml` → `deliverables.thesis_card_required_elements[1]` evidence_chain min_count=3
> - **L4 实践记录**：[实践记录_step_03_证据链构建器.md](../../../../../04_阶段规划与实践/02_维度二_纵深进攻/stage_1_启动期/实践记录_step_03_证据链构建器.md)
> - **上游 step**：← step_02（`financial_indicators` / `announcements` / `industry_peers`）
> - **下游 step**：→ step_04（剧本可挂 evidence）、step_05（thesis 5 必填）、step_07（相似度叙述素材）

## §3 数据采集对象 / 落库映射

**本步不采外部数据**——加工 step_02 已落库数据 → 生成 `evidence_records`。

| 输入表 | 输出 | 转换规则 |
|---|---|---|
| `financial_indicators` 最新 N 期 | type=`financial` | 模板叙述含毛利率 / 营收增速 / 周转环比等**数字锚点** |
| `announcements` 全文 | type=`announcement` | Top-K 按日期；content 截断 ≤500 字 + **url 必填** |
| `industry_peers` + 指标分位 | type=`industry` | 同业 ≥3 家则写分位叙述；不足则**跳过**（不伪造）|
| 产业链（启动期）| type=`supply_chain` | **无真实数据则不产出**；本步可 0 条 |
| **[L-α] 嗅探候选簇**（`sniffer_clusters`）+ `sniffer_raw_text` 原文 | type=`physical_gate` | The Critic 大模型判定：①是否存在可观测物理底线（招标/产能/海外路线图）；②业绩弹性的可达性（与营收基数对比）；输出 `{physical_gate: bool, falsified_reason: str, capacity_elasticity_ok: bool, source_clusters: [...]}` |

| 落库 | ORM 字段 | 说明 |
|---|---|---|
| `evidence_records` | symbol, scan_id, evidence_idx, type, source, content, date, url, source_id, confidence | `source_id` = 源表主键或复合键字符串 |

**零值语义**：无法 JOIN 源表 → **拒绝入库**；content <50 字 → 拒绝。

## §3.5 数据质量验收矩阵（按 step_04/05/07 反推 · 仅启动期）

> **本步范围**：证据链是 thesis「可辩护性」的根基——不是凑够 3 条标题，而是每条都能被人类复核回 SQLite 真值。

### §3.5.1 thesis 卡片 evidence_chain（step_05 消费）

| # | 分析维度 | 必产字段 / 衍生 | 启动期覆盖状态 | 启动期降级路径 |
|---|---|---|---|---|
| T1 | **条数门槛** | 每 active 标的每次 `build` ≥3 条 | ⚠️ 实测 | <3 **不准出**该次 build |
| T2 | **类型覆盖** | financial + announcement 各 ≥1（有源数据时）| ⚠️ | 缺 industry 允许；缺 announcement 全文则不准出 |
| T3 | **content 可辩护** | 中文 ≥50 字/条；含 ≥1 个可核对数字或日期 | ✅ 规则模板强制 | 过短拒绝入库 |
| T4 | **url 锚定** | announcement 类 `url` 非空率 100% | ✅ | 空 url 不入库 |
| T5 | **source_id 可追溯** | 100% 可 JOIN 源表 | ✅ | JOIN 失败拒绝 |

### §3.5.2 利润截留剧本附证（step_04 可选消费）

| # | 分析维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| P1 | **财务证据含 5 信号相关字段** | financial 证据文本提及毛利率 / 成本增速 / 周转 | ⚠️ 模板覆盖 | 缺字段则剧本仅算信号不挂该条 evidence |
| P2 | **scan_id 关联** | 与 step_04 `scan_logs.scan_id` 可对齐 | ✅ | — |

### §3.5.3 工程与幂等

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| E1 | **幂等 upsert** | 同 `(symbol, scan_id)` 重跑条数不变 | ✅ | — |
| E2 | **禁止 LLM 编造**（持仓侧）| 启动期**纯规则**模板；无 source_id 拒绝 | ✅ | step_06 后 LoRA 润色仍须保留 source_id |
| E3 | **构建耗时** | 单 symbol <30s（无 LLM）| ✅ | — |

### §3.5.4 [Lighthouse-Alpha] The Critic 物理证伪门禁

| # | 分析维度 | 必产字段 | 启动期 | 降级 |
|---|---|---|---|---|
| LC1 | **physical_gate 字段** | 每条 `sniffer_cluster` 产出一条 type=physical_gate 的 evidence；`physical_gate ∈ {true, false}` 必填 | ✅ | LLM 调用失败 → `physical_gate=null` + 该候选标 `pending_critic` 不进 Mapper |
| LC2 | **可观测物理底线** | The Critic prompt 强约束："必须援引可点击 url 的真实物理证据（招标/产能/出货/路线图）" | ✅ 单测覆盖 | 无物理证据 → `physical_gate=false` + `falsified_reason='no_observable_baseline'` |
| LC3 | **业绩弹性可达性** | `capacity_elasticity_ok` 字段：候选订单/产能 vs 标的近 12 月营收基数；< 5% → 标 `low_elasticity` | ✅ 与共享规约 19 异构 AI 调度对齐（小模型先算比值，LLM 仅给定性判定）| 数据缺失 → 标 `pending_elasticity` |
| LC4 | **可追溯 source_clusters** | physical_gate evidence.source_id 格式 `cluster:{cluster_id}`；JOIN `sniffer_clusters.cluster_id` 100% 成功 | ✅ | JOIN 失败拒绝入库 |
| LC5 | **人工抽样一致率** | 启动期人工抽 10 条 The Critic 输出，与人类判定一致率 ≥ 80% | ⚠️ | < 80% → 改 prompt 重训 ≤ 2 次；仍不达标暂停 The Critic |
| LC6 | **门禁透传到 step_04** | physical_gate=false 的 cluster 不进入 step_04 The Mapper；step_04 输入须先 `WHERE evidence.physical_gate = true` | ✅ | — |

> 共 **10 项原有 + 6 项 Lighthouse-Alpha = 16 项**。矩阵中**无 ❌**。
> [Lighthouse-Alpha] 对齐 L1 哲学基石⑥「物理证伪 ≥ 财务证伪」与 DNA 键 `_System_DNA/02_deep_strike/theme_sniffer.yaml::critic.physical_gate_required`（待 D03 设计文档新增）。

### §3.5.4 质量门槛（合并到 §9.2）

矩阵每行须 ✅ 或 ⚠️ 有明确降级路径。**禁止**：无 source_id 的 evidence；用假 supply_chain 充数。

## §4 真实数据源与凭证清单

### §4.1 资源

| 资源 | 来源 |
|---|---|
| step_02 业务表 | 硬前置 |
| `MY_HOLDINGS_YAML` | 标的范围 |

### §4.2 用户须提供

| 凭证 | 用途 | 何时 | 位置 |
|---|---|---|---|
| step_02 已准出 | 数据齐 | **本步前** | L4 实践记录 |
| `MY_HOLDINGS_YAML` | active 标的 | 同 | `.env` |

> **本步无** Teacher / GPU 凭证。

## §5 启动期目标

### §5.1 数据范围

- **标的**：SoT `active=true`
- **每标的**：每次 build ≥3 条 evidence；financial+announcement 各 ≥1（有数据时）

### §5.2 数据量门槛（必要不充分）

| 指标 | 最小值 | 验证 |
|---|---|---|
| evidence 总行数 | active 数 × 3 | `SELECT symbol, COUNT(*) ... GROUP BY symbol` |
| §3.5 矩阵 | 全 ✅/⚠️ | `validate_evidence_chain_quality.py` 退出码 0 |

### §5.3 可接受退化

- peers <3 → 跳过 industry 证据；
- 公告仅标题 → 不计入 E2 全文率，且该条不入 evidence；
- 产业链无数据 → supply_chain 0 条（合规）。

## §6 下一步（一行触发条件）

- **触发条件**：本步 ✅ + §3.5 矩阵绿 → step_04 利润截留剧本可算 5 信号并引用 evidence。
- **扩展期**：产业链 API + LLM 摘要证据；见 `stage_2_扩展期/`。

## §7 实施规划（L3 设计 · 给后续执行模型的工作指引）

> **L3 定位**：设计规划 + 实现要点 + 验证标准；**不嵌入**完整 Python 类代码。

### §7.1 实现要点

| 实现要点 | 涉及代码位置 | 关键设计决策 | 验证标准 |
|---|---|---|---|
| **A Evidence schema** | `engines/evidence/schemas.py` | type enum: financial/announcement/industry/supply_chain；content min_length=50；url Optional 但 announcement 必填 | pydantic 单测边界 |
| **B 段1 财务证据** | `engines/evidence/financial_segment.py` | 读最新 1~2 期 indicators；模板："Q{period} 毛利率 {gm:.1%}，环比 {qoq:+.1%}；营收同比 {rev_yoy:+.1%}"；source_id=`fi:{symbol}:{period}` | 单测 1 symbol |
| **C 段2 公告证据** | `announcement_segment.py` | Top3 按 ann_date；content[:500]；url 原样；source_id=`ann:{id}` | 单测 3 条 |
| **D 段3 行业证据** | `industry_segment.py` | peers≥3 写分位；否则返回 [] | mock 5 peers |
| **E 段4 组装** | `evidence_chain_builder.py` | `build(symbol, scan_id) -> list[Evidence]`；顺序 financial→announcement→industry | e2e ≥3 条 |
| **F 持久化** | `evidence_repository.py` | upsert by (symbol, scan_id, evidence_idx) | 重跑幂等 |
| **G 质量脚本** | `validate_evidence_chain_quality.py` | 扫 §3.5 16 项（含 §3.5.4 6 项 Lighthouse-Alpha）+ SQL JOIN 抽样 | 退出码 0 |
| **H 单测** | `tests/deep_strike/test_evidence_chain.py` + `test_the_critic.py` | ≥6：schema/各段/组装/幂等/JOIN；+ ≥4：The Critic 物理证伪正反例 / null 兜底 / 人工抽样 mock | pytest 全绿 |
| **[L-α] I The Critic 段** | `engines/evidence/the_critic.py` | 异构 AI 调度（共享规约 19）：小模型先算 capacity_elasticity 数值；**Claude Opus 4.7** 仅做定性 physical_gate 判定 + 援引证据 url；prompt 强约束"必须含可点击 url" | 单测 mock LLM 5 例：3 正例 physical_gate=true / 2 反例 false |
| **[L-α] J Critic 输出 schema** | `engines/evidence/schemas.py` | 扩 Evidence enum 加 `physical_gate`；新增字段 `physical_gate: Optional[bool]` / `falsified_reason: Optional[str]` / `capacity_elasticity_ok: Optional[bool]` / `source_clusters: list[str]` | pydantic 单测 |
| **[L-α] K Critic 门禁注入 step_04** | `evidence_repository.py::get_for_mapper` | SQL 过滤 `WHERE type='physical_gate' AND physical_gate=true`；其他 evidence 一并返回 | 单测 fixture: 3 候选 2 true 1 false → Mapper 仅收 2 |

### §7.2 Makefile 一键复现合约

| target | 用途 | 入参 | 验证标准 |
|---|---|---|---|
| `make deep-step03-prep` | 确认 step_02 quality 已过 | — | `deep-step02-quality-check` 退出码 0 |
| `make deep-step03-build` | 全 active build | `MY_HOLDINGS_YAML` | 每 symbol ≥3 条 |
| `make deep-step03-quality-check` | §3.5 矩阵 | — | 退出码 0 |
| `make deep-step03-test` | pytest | — | ≥6 passed |
| `make deep-step03-all` | 端到端 | 合并 | 全 0 |
| `make deep-step03-status` | 快照 | — | 每 symbol evidence 数 + 类型分布 |
| `make deep-step03-clean` | 清 evidence_records | `FORCE=1` | 已清 |

**合约要求**：改 `my_holdings.yaml` 增标的 → 重跑 `build` 仅增量；失败中文 3 行摘要。

### §7.3 关键代码片段（中间道）

#### 7.3.1 Evidence Pydantic schema（核心 ~12 行）

```python
class Evidence(BaseModel):
    type: Literal["financial","announcement","industry","supply_chain"]
    source: str                                # 'akshare' / 'cninfo' / 'derived'
    content: str = Field(min_length=50, max_length=500)
    date: date
    url: Optional[HttpUrl] = None              # announcement 强校验在 validator
    source_id: str                             # fi:600519:2024Q3 / ann:1234567
    confidence: float = Field(ge=0.0, le=1.0, default=1.0)

    @model_validator(mode="after")
    def url_required_for_announcement(self):
        if self.type == "announcement" and self.url is None:
            raise ValueError("announcement evidence requires url")
        return self
```

#### 7.3.2 段1 财务证据模板（核心 ~10 行 · 数字锚点强制）

```python
def render_financial_evidence(ind: FinancialIndicator) -> Evidence:
    period = ind.report_period
    parts = [f"{period} 毛利率 {ind.gross_margin:.1%}"]
    if ind.gross_margin_qoq is not None:
        parts.append(f"环比 {ind.gross_margin_qoq:+.1%}")
    if ind.revenue_growth_yoy is not None:
        parts.append(f"营收同比 {ind.revenue_growth_yoy:+.1%}")
    if ind.receivable_turnover_qoq is not None:
        parts.append(f"应收周转环比 {ind.receivable_turnover_qoq:+.1%}")
    content = "，".join(parts) + "。"
    return Evidence(type="financial", source="akshare", content=content,
                    date=parse_period_date(period),
                    source_id=f"fi:{ind.symbol}:{period}")
```

#### 7.3.3 EvidenceChainBuilder 四段组装（核心 ~15 行）

```python
class EvidenceChainBuilder:
    def __init__(self, repo: EvidenceRepository):
        self.repo = repo

    async def build(self, symbol: str, scan_id: str) -> list[Evidence]:
        chain: list[Evidence] = []
        # 段1 财务（≥1）
        ind = await self.repo.get_latest_indicators(symbol, n=2)
        chain.extend([render_financial_evidence(i) for i in ind])
        # 段2 公告（Top3）
        anns = await self.repo.get_top_announcements(symbol, k=3)
        chain.extend([render_announcement_evidence(a) for a in anns])
        # 段3 行业（peers≥3 才产）
        peers = await self.repo.get_peers(symbol)
        if len(peers) >= 3:
            chain.append(render_industry_evidence(symbol, peers))
        # 段4 产业链（启动期无源 → 跳过）
        for idx, ev in enumerate(chain):
            await self.repo.upsert(symbol, scan_id, idx, ev)
        return chain
```

#### 7.3.4 source_id 反向 JOIN 抽样脚本（核心 ~10 行）

```sql
-- §3.5 T5 验证：source_id 100% 可追溯
SELECT e.symbol, e.evidence_idx, e.type, e.source_id,
       CASE
         WHEN e.type='financial' AND fi.id IS NULL THEN 'BROKEN'
         WHEN e.type='announcement' AND a.id IS NULL THEN 'BROKEN'
         ELSE 'ok'
       END AS join_status
FROM evidence_records e
LEFT JOIN financial_indicators fi
  ON e.type='financial' AND e.source_id =
     'fi:' || fi.symbol || ':' || fi.report_period
LEFT JOIN announcements a
  ON e.type='announcement' AND e.source_id =
     'ann:' || CAST(a.id AS TEXT)
WHERE e.scan_id = :scan_id;
-- 期望：所有行 join_status='ok'
```

### §7.4 给后续执行模型的指引

1. 必须先 `deep-step02-quality-check` 通过；
2. 顺序 A→H；每段独立单测后再组装；
3. **禁止** LLM 编造 evidence；缺产业链不填假 supply_chain；
4. §9 准出 + L4 含矩阵 10 行 + JOIN 抽样 5 条证据。

> **L3 责任边界**：不给完整 Python；交给 L4 / 后续模型。

## §8 部署节奏（本步在哪里跑）

| 阶段 | 形态 | 必须 | 说明 |
|---|---|---|---|
| **本机** | `python -m ... build` + pytest | **是** | 纯 CPU |
| **K3s** | — | 否 | — |

## §9 准出标准（同会话可执行清单 · 质量优于数量）

### §9.1 数据量
- [ ] 每 active symbol `COUNT(*) >= 3`

### §9.2 质量（§3.5 · 10 项）
- [ ] `validate_evidence_chain_quality.py` 退出码 0；10 行 ✅/⚠️

### §9.3 工程 + 一键复现
- [ ] `make deep-step03-all` 通过
- [ ] L4 实践记录含矩阵 + JOIN 证据
- [ ] commit：`feat(deep-strike): step_03 证据链四段流水线 + 质量矩阵 + Makefile [Ref: 03_/02_维度二/.../step_03]`
- [ ] **同会话验证**：命令输出摘要

## §10 [Deploy] 段

本步无镜像 / Chart。

## §11 依赖与被依赖

**上游**：step_02 持仓侧 ✅（financial_indicators / announcements / industry_peers）；**[L-α]** step_02 嗅探侧 ✅（sniffer_clusters 当日 ≥ 1 簇）+ The Critic 大模型 API key（**ANTHROPIC_API_KEY · Claude Opus 4.7**；可用共享规约 19 异构 AI 调度做小模型预处理省成本）。
**下游**：step_04 The Mapper（消费 physical_gate=true 候选）、step_05 thesis 卡片、step_07 The Scorer。
**严禁伪造**：无 source_id 的 evidence；假 supply_chain；**[L-α]** The Critic 在无可点击 url 物理证据时**禁止**返回 physical_gate=true。

## §12 风险与回退

| 触发 | 动作 |
|---|---|
| content 过短大面积 | 调模板补数字锚点 |
| source_id JOIN 失败 | 修 source_id 格式与 ORM 主键 |
| <3 条/标的 | 回 step_02 补公告/指标 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-21 | **v3.1 Lighthouse-Alpha 融合**：merge_inplace 融入 The Critic 物理证伪门禁——§1 一句话扩；§3 输入表加第 5 类 evidence；§3.5 新增 §3.5.4 矩阵 6 项（LC1~LC6）；§7.1 追加 I/J/K 三实现要点（The Critic 段 / schema 扩展 / 门禁注入）；§11 依赖加 The Critic 大模型 + 嗅探候选簇上游；对齐 L1 哲学基石⑥与 DNA `theme_sniffer.yaml::critic` |
| 2026-05-21 | **v3 中间道细化**：保留 v2.1 §3.5 10 项；§7.3 新增 4 个关键片段（Evidence Pydantic schema + url validator / 段1 财务证据模板 / EvidenceChainBuilder 四段组装 / source_id JOIN 抽样 SQL）；210→~390 行 |
| 2026-05-20 | **v2.1 深度补全**（用户要求推演深度不下降）：§3.5 扩为 10 项三分块；§7~§13 完整化；Makefile 7 target；去「略式」节；727→~300 行 |
| 2026-05-20 | v2：按 L3 v1.2 瘦身去嵌入代码 |
| 2026-05-16 | 初版 727 行含完整 Python |
