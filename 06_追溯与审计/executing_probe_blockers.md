# 执行区 T0 探针阻塞报告（完善期 · 严格准出 · 无 ok 顶替）

> **规则**：[28_ §9](../03_原子目标与规约/_共享规约/28_工业富联执行中专属T0-T2监控开发计划.md) · **ok = 规划源落地且验收字段齐全**；未实现 / 代理 / 无命中 / 快照 / 占位 → **`missing` + `[A|B|C|D]` blocker**。

**最后更新**：2026-06-05（**严格准出代码** · 废除「25/25 假绿」）  
**样板标的**：601138  
**代码**：`diting-src/apps/copilot/modules/executing/t0_collectors.py`（`EXECUTING_T0_STRICT` 内嵌于逻辑，无 env 开关）

---

## 汇总（诚实口径）

| 指标 | 数值 | 说明 |
|------|------|------|
| 探针总数 | 25 | 28_ §3 |
| **真 ok** | **以 Pod `collect-once` 为准** | 部署后执行：`python -m apps.copilot.jobs.executing_t0 collect-once --symbol 601138` |
| **missing** | 25 − ok_count | `--status` → `missing_count` / `stale_probes` |
| 曾误报 | ~~25/25~~ | 已撤销：代理源、词表无命中、PVC 快照、financial_abstract 裸表等 **不再标 ok** |

**完善期准出**：**未达成**（须 25/25 **真 ok** 或每项 blocker 闭环 DECISION_PENDING）。

---

## 已废除的「暗度陈仓」做法（2026-06-05）

| 违规做法 | 现行为 |
|----------|--------|
| 词表扫过无命中仍 `ok`（`no_keyword_match_verified`） | **`missing` [D]** |
| 未实现项用快讯/akshare 替代（nvda/tsmc/smci/鸿海 HK） | **`missing` [A]** |
| PVC 快照当次采集 `ok` | **禁止**；仅 live 成功可 ok |
| `financial_abstract` 整表 dump | **missing [C]**（毛利率/周转/合同负债/关联交易未解析） |
| 仅标题「减持」无占总股本% | **missing [A]** |
| 10 日波动冒充 β | **missing [A]** |
| 仅 USD/CNY 现货无 30 日序列 | **missing [C]** |
| ETF 仅有份额无 `share_change` | **missing [C]** |

---

## 仍可能为真 ok 的项（须逐次 Pod 核验）

规划源与实现对齐、且当次接口返回验收字段时方可绿：

| 探针 | 规划源（28_ §3） | 当前实现条件 |
|------|------------------|--------------|
| `cloud_capex_consensus` | SEC EDGAR | 四云商 CapEx JSON 成功 |
| `cpi_ppi_spread` | 宏观 CPI/PPI | 东财表非空 |
| `copper_cost_pressure` | 沪铜 30 日 | 期货序列 ≥30 日 |
| `mgmt_and_core_team` | 巨潮董监高 | 全扫后 **events 列表**（含 `[]` 合法负结果） |
| `gb200_iteration_node` | 公告关键词 | **≥1 条命中**（无命中 = missing） |
| `qmt_atr_trailing` | K 线 ATR | 腾讯 K + 数值 |
| `volume_price_div` | K 线量比 | 同上 |
| `turnover_acceleration` | 量比 3/60 | 同上 |
| `margin_short_skew` | 两融 | 上交所/深交所表命中日 |
| `block_trade_discount` | 大宗 | 601138 折价行 |
| `level2_super_order` | 东财超大单 5 日 | push2his 或 fund_flow **当次**成功 |

其余 14 项默认 **未实现 [A]** 或 **渠道/字段 [B/C]**，见 `collect-once` 输出 blocker 全文。

---

## 验证命令（Pod 内）

```bash
python -m apps.copilot.jobs.executing_t0 collect-once --symbol 601138
python -m apps.copilot.jobs.executing_t0 --status
```

**期望**：`ok_count` ≪ 25 为正常；**禁止**再追求「数字好看」。

---

## 修订记录

| 日期 | 变更 |
|------|------|
| 2026-06-05 | **严格准出**：废除代理/无命中/快照 ok；blockers 文档重写 |
| 2026-06-05 | 曾误记 25/25 全绿（已作废，见 git/部署记录） |
