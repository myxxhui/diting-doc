# 35 · Tushare 数据源优先收敛规约（L3 · 跨模块主备矩阵）

> **一句话**：凡 Tushare Pro **能力可达**且字段语义可审计的结构化指标，**主源统一为 Tushare**；东财（East Money）直连仅保留 Tushare **无法 1:1 等价**的板块聚合、全 A 快照与 [21_] 行情兜底；巨潮/官方/腾讯等既有主源**不因本规约变更**。
>
> **文档定位**：本规约为 Copilot 执行区、行情雷达、五区漏斗的**数据源裁决层**；细化 [11_](./11_数据采集与输入层规约.md) 采集原则，与 [21_](./21_行情数据源降级与断路器规约.md)（行情）、[27_](./27_行情雷达全链路架构设计优化.md)（雷达 T0）、[28_](./28_执行中工作区_标的深度监控_T0-T2开发计划.md)（执行探针）**互补不重复**。

> [!NOTE] **[TRACEBACK] 战略追溯锚点**
> - **L1**：[06_投资哲学体系总纲](../../01_顶层概念/06_投资哲学体系总纲.md)（一手可验证 · 禁止臆造数值）
> - **L2**：[03_跨维度数据采集依赖总表](../../02_战略维度/06_跨维度协作/03_跨维度数据采集依赖总表.md)
> - **行情**：[21_ 多源降级](./21_行情数据源降级与断路器规约.md)
> - **雷达**：[27_ 十七项 T0](./27_行情雷达全链路架构设计优化.md)
> - **执行**：[28_ JL3/JL4 矩阵](./28_执行中工作区_标的深度监控_T0-T2开发计划.md)
> - **五区**：[32_ 漏斗总纲](./32_五区漏斗工作流与数据工程标准化规约.md) · [34_ 指标矩阵](./34_五区指标矩阵与T0-T2集成规约.md)
> - **凭证**：环境变量 **`TUSHARE_TOKEN`**（Pro Token；部分接口 ≥2000 积分）· 生产注入见 [28_ §9](./28_执行中工作区_标的深度监控_T0-T2开发计划.md)

---

## §1 裁决原则

| # | 原则 | 说明 |
|---|------|------|
| P1 | **结构化硬算 → Tushare 优先** | 财报科目、资金流向、两融、大宗、股东变动、宏观 CPI/PPI 等可写死公式的指标，主源 **Tushare Pro** |
| P2 | **禁止静默混源** | 同一 `metric_id` / 探针 key 在 Tushare 与东财/F10 同时有值且冲突 → **`error` + blocker**（继承 [28_ §2.9.1](./28_执行中工作区_标的深度监控_T0-T2开发计划.md)） |
| P3 | **东财保留白名单** | 仅 §3「不可替代清单」允许东财 datacenter / push2 直连；其余东财用法视为**待迁移技术债** |
| P4 | **公告/附注不归 Tushare** | 全文 PDF、附注 OCR、互动易 → **巨潮 / Playwright / PyMuPDF**；Tushare 仅作结构化交叉校验 |
| P5 | **行情 K 线不归 Tushare 主链** | 日/分钟 K 与实时价 → [21_] **腾讯 / 新浪** 主链；Tushare `daily`/`stk_mins` 仅作 PG 底库或备用 |
| P6 | **实现须对齐规约** | L4 / `diting-src` 采集器 `source` 字段须与本表一致；旧 `eastmoney:RPT_F10_*` 路径 **禁止**再作为 JL3 财务硬算准出源 |

---

## §2 Tushare 主源矩阵（能力可达 · 强制）

> **接口名为 Tushare Pro 约定**；实现时 `ts_code` 由 6 位 symbol 转换。季频探针共享 `cache_group` 见 [28_ §3.4](./28_执行中工作区_标的深度监控_T0-T2开发计划.md)。

### §2.1 执行区 · JL4（已与 [28_ §2.9] 对齐）

| 探针 key | Tushare 接口 | 关键字段 | 备注 |
|----------|-------------|----------|------|
| `smart_money_flow` | `moneyflow` + `daily_basic` | `buy_elg_amount`/`sell_elg_amount` · `free_share` | ≥2000 积分 |
| `level2_super_order` | `moneyflow` | `buy_elg_amount`/`sell_elg_amount` | 120 日分位 |
| `margin_short_skew` | `margin_detail` + `daily_basic` | 融资余额 / 流通市值 | T+1 |
| `turnover_acceleration` | `daily_basic` | `turnover_rate_f` · `volume_ratio` | 盘后 |
| `block_trade_discount` | `block_trade` | 折价 · 成交额 | 事件稀疏 |
| `retail_concentration` | `moneyflow` | 中小单净买 / 总成交 | 与 #3 同窗 |
| `insider_sell_actual`（结构化支） | `stk_holdertrade` | `change_vol` · 减持% | 与巨潮 DeepSeek 交叉 |
| `tech_beta_correlation` | `daily` + `index_daily` | `pct_chg` 同窗 | 板块指数对齐 |
| `etf_redemption_impact` | `fund_share` + `fund_portfolio` | 份额变动 · 穿透权重 | T+1 |

### §2.2 执行区 · JL3 财务/运营硬算（本规约收敛重点）

| 探针 key（示例） | Tushare 接口 | 字段映射 | 废弃源（禁止准出） |
|------------------|-------------|----------|-------------------|
| `fii_gross_margin` 等 `*_gross_margin` | `fina_indicator` | `grossprofit_margin` | ~~`eastmoney:RPT_F10_FINANCE_MAINFINADATA`~~ |
| `fii_contract_liab` 等 `*_contract_liab` | `balancesheet` | `contract_liab` · QoQ 硬算 | ~~东财 F10~~ |
| `fii_inventory_turnover` 等 `*_inventory_turn` | `fina_indicator` | `inv_turn` | ~~东财 F10~~ |
| `fii_ar_turnover` 等 `*_inter_receivable` | `fina_indicator` | `ar_turn` | ~~东财 F10~~ |
| `fii_cfo_health` 等 `*_cfo_health` | `cashflow` + `fina_indicator` | `n_cashflow_act` / `netprofit_margin` | ~~东财 F10~~ |
| `nev_net_margin` 等净利率 | `fina_indicator` | `netprofit_margin` | ~~东财 F10~~ |
| `env_goodwill_imp` | `balancesheet` | `goodwill` / 净资产 | ~~东财 F10~~ |

**`batch_id` / `cache_group` 约定**：同季同标的多字段 → `tushare_fina_indicator_q` · `tushare_balance_q` · `tushare_cashflow_q`（见 `probe_registry`）。

### §2.3 执行区 · JL1 宏观硬算

| 探针 key | Tushare 接口 | 字段 | 废弃源 |
|----------|-------------|------|--------|
| `cpi_ppi_spread` | `cn_cpi` + `cn_ppi` | 全国 CPI YoY · PPI YoY · 剪刀差 | ~~东财 datacenter 宏观~~ |

> 美国 CPI/PPI 扩展期仍走 **BLS / FRED** 或专用 API；不在 Tushare 启动期范围。

### §2.4 执行区 · 治理/筹码（Tushare 可达部分）

| 场景 | Tushare 接口 | 说明 |
|------|-------------|------|
| 大股东增减持结构化 | `stk_holdertrade` | 与巨潮全文交叉（[28_ §2.9.1]） |
| 质押比例 | `pledge_stat` | 取代东财 `RPT_CSDC_LIST` |
| 股东户数 / 筹码集中 | `stk_holdernumber` | 取代 AkShare 股东户数（`retail_concentration` 相关） |
| 限售解禁 | `share_float` | 与 [27_ T0-16] 对齐 |

### §2.5 行情雷达 · 域 2～5（Tushare 主源化）

| T0 ID | 指标 | 主源（本规约） | 备用 | 东财 |
|:---:|---|---|---|---|
| **4** | 基础档案 | **`stock_basic`** | akshare | — |
| **5** | 主营结构穿透 | **`fina_mainbz`** | akshare · 巨潮 PDF | ~~F10 MAINOP 直连~~ |
| **8** | 250 日 OHLCV | [21_] **腾讯 fqkline** | akshare | — |
| **9** | 陆股通 30 日 | **`moneyflow_hsgt`** / `hk_hold` | akshare | — |
| **10** | 融资融券 30 日 | **`margin_detail`** | akshare | — |
| **11** | 龙虎榜 10 日 | **`top_list`** | akshare | — |
| **14** | 财务排雷切片 | **`fina_indicator`** + **`balancesheet`** | akshare | — |
| **15** | 大股东质押 | **`pledge_stat`** | akshare | ~~RPT_CSDC_LIST~~ |
| **16** | 限售解禁 | **`share_float`** | akshare | — |

---

## §3 东财不可替代清单（禁止改为 Tushare 主源）

| 场景 | 东财用法 | 不可替代原因 | 权威规约 |
|------|----------|-------------|----------|
| 雷达 T0-2 | 板块近 **3 日**涨跌幅 `stat=3/f127` | Tushare 无等价板块预聚合字段 | [27_ §2.2](./27_行情雷达全链路架构设计优化.md) |
| 雷达 T0-3 | 板块 **5 日**主力净流入 | 同上；备用列为「—」 | [27_ §2.2] |
| 雷达 T0-2/3 板块匹配 | push2 **`f100` 行业** 或 **`stock_basic.industry` 映射表** | 板块 clist 聚合仍须东财；**单标的行业标签**可用 Tushare | [27_ §2.2 脚注] |
| 雷达 T0-1（现实现） | push2delay **全 A clist** 快照 | Tushare 无一次扫全市场涨跌比接口；规约主源 QMT/akshare | [27_ §2.2.1] |
| 实时报价 P3 | `push2.eastmoney.com/ulist.np` | [21_] 降级链第三源 | [21_ §3] |
| 15min K（#16） | push2his 15m（**腾讯 mkline 优先**） | Tushare `stk_mins` 积分/频次不适合盘中 */15 Cron 主链 | [28_ §2.9] · [21_] |
| 公告全文 | — | **巨潮 cninfo**；东财仅元数据 | D1 step_02 · no-mock |

---

## §4 迁移与验收

### §4.1 L4 实现检查（`diting-src`）

| 检查项 | 期望 |
|--------|------|
| JL3 财务 KPI collector | `source` 含 `Tushare` + 接口名；**无** `eastmoney:RPT_F10_FINANCE_MAINFINADATA` 准出 |
| `cpi_ppi_spread` | `cn_cpi` / `cn_ppi`；**无**东财 macro datacenter |
| 质押 | `pledge_stat`；**无** `RPT_CSDC_LIST` 作为唯一源 |
| 主营构成 | `fina_mainbz` 优先；东财 MAINOP 仅作冲突交叉 |

### §4.2 准出 blocker 语义

| 类型 | 条件 |
|------|------|
| `[A]` | `TUSHARE_TOKEN` 未配置或积分不足 |
| `[C]` | 准出源仍为废弃东财 F10 路径 · **源错位** |
| 冲突 | Tushare 与东财同窗字段差 > 规约阈值 → `error`（禁止静默取东财） |

### §4.3 一致性联动

本规约变更时须自检：

- [ ] [27_](./27_行情雷达全链路架构设计优化.md) 域 2～5 主备列与本表 §2.5 一致
- [ ] [28_](./28_执行中工作区_标的深度监控_T0-T2开发计划.md) JL3 矩阵「T0 文档血缘 / 数据源」列无「财报/东财 F10」歧义
- [ ] [03_跨维度数据采集依赖总表](../../02_战略维度/06_跨维度协作/03_跨维度数据采集依赖总表.md) P0 行主源 Tushare 居前
- [ ] `probe_registry/*.yaml` 的 `t0_source_id` 与本表一致

---

## §5 修订记录

| 日期 | 触发原因 | 涉及小节 |
|------|----------|----------|
| 2026-06-17 | 用户确认：Tushare 能力可达项统一规约为 Tushare 主源；东财收敛为 §3 白名单 | 全文；联动 27_/28_/32_/L2 依赖表 |
