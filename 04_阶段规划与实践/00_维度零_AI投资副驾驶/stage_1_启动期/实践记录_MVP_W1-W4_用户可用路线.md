# 实践记录 · MVP 启动期 · W1–W4 用户可用路线（合并早报）

> [!NOTE] **[TRACEBACK] 战略追溯锚点**
> - **顶层概念**: [06_投资哲学体系总纲](../../../01_顶层概念/06_投资哲学体系总纲.md)（基石 ② 认知套利 · ⑦ 持仓监控）
> - **战略维度**: [06_标的深度分析与阶段判定实践规划](../../../02_战略维度/06_跨维度协作/06_标的深度分析与阶段判定实践规划.md)
> - **跨维总规划（六维度日历）**: [14_六维度启动期统一节奏表](../../../03_原子目标与规约/_共享规约/14_六维度启动期统一节奏表.md)（**维间并行与 Mn 以本表为准**）
> - **本路线定位**: **用户「先能用上」的纵向切片**；不等六维全部 step 完成；与 14 表 **互补**（14=全仓地图，本文=MVP 交付序）
> - **L3 锚点**:
>   - W1 health：[D3 step_06 健康度](../../../03_原子目标与规约/03_维度三_持仓监控/stages/stage_1_启动期/steps/step_06_健康度计算与push_level.md) · [D3 step_01～07](../../../03_原子目标与规约/03_维度三_持仓监控/stages/stage_1_启动期/steps/README.md)
>   - W2 phase：[D3 step_09 市场阶段](../../../03_原子目标与规约/03_维度三_持仓监控/stages/stage_1_启动期/steps/step_09_市场阶段分类器MVP.md) · [DNA step09](../../../03_原子目标与规约/_System_DNA/03_holding_watch/dna_d3_stage1_step09_market_phase_classifier.yaml)
>   - 合并早报：[D0 step_07 日报推送](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_07_日报周报推送.md)
>   - 推送/告警：[D0 step_05 告警系统](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_05_告警系统.md)
> - **DNA**: [00_co_pilot/dna_stage_1](../../../03_原子目标与规约/_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml) · [03_holding_watch/dna_stage_1](../../../03_原子目标与规约/_System_DNA/03_holding_watch/dna_stage_1_启动期.yaml)
> - **代码真相源（L4 已落地部分）**: `diting-src/apps/copilot/services/reports/holdings_morning.py` · `diting-src/apps/state_watch/market_phase/`
> - **持仓 SoT**: `diting-src/data/config/my_holdings.yaml`（模板 `my_holdings.example.yaml`）

<a id="l4-mvp-w1w4-goal"></a>

## 一、本步目标（你要先用上什么）

| 原则 | 说明 |
|------|------|
| **每完成一个 MVP 就能用** | 不做「只打地基」；每步必须有邮件/告警/看板可感知产出 |
| **以持仓为中心** | 标的清单来自 `my_holdings.yaml`（`active=true`）；数量随你维护，非固定 8 只 |
| **与 14 表关系** | **执行本路线时**以本文 MVP 序为主；**维间资源/凭证/Mn** 仍查 [14 表](../../../03_原子目标与规约/_共享规约/14_六维度启动期统一节奏表.md) |

**用户已确认决策（2026-05-27 会话锁定）**：

| # | 决策 |
|---|------|
| 1 | 推送：**126 发件 → Gmail 收件**；飞书 W1 不用 |
| 2 | 日报时间：**每交易日 08:00** |
| 3 | 静默：**不静默**（高危/阶段切换随时推；可用 Gmail 过滤器加星） |
| 4 | 暂缓项 **不删**：**D1 极寒防御简版 3 引擎**（W3）、**D4 SP2 止盈简版**（W4） |
| 5 | 执行序调整：**先做 W2**，再合并 W1+W2 早报（代码已合并） |

---

## 二、6 个 MVP · 约 4.5 周（执行序）

```mermaid
flowchart LR
  W1[MVP-A health 日报]
  W2[MVP-B market_phase]
  W3[MVP-C thesis]
  W4[MVP-D 戴维斯对比]
  W5[MVP-E sell_signal]
  W6[MVP-F 加仓时机]
  W1 --> W2
  W2 --> W3
  W3 --> W4
  W4 --> W5
  W5 --> W6
```

> **当前落地状态（2026-05-28）**：W2 代码 + Makefile ✅ · W1+W2 **合并早报** ✅ · W1 探针/health 部分依赖 D3 step_01～06 已有实现 · W3～W6 文档/L3 已有、代码待按序推进。

| 周次（别名） | MVP | 完成后你能用上 | 主维度 | L3 step（权威） | Makefile（`diting-src`） | 状态 |
|-------------|-----|----------------|--------|-----------------|---------------------------|------|
| **W1** | **A · 持仓健康度** | health 四色；探针数据入库 | **D3** + **D0** | step_01～06；早报见 step_07 | `watch-step01-prep` … `watch-step06-calc-all`（见 D3 README） | 🔄 部分已绿 |
| **W2** | **B · 市场四档** | 每只 `concept/expectation/realization/exhaustion`；切换邮件 | **D3** + **D0** | [step_09](../../../03_原子目标与规约/03_维度三_持仓监控/stages/stage_1_启动期/steps/step_09_市场阶段分类器MVP.md) | `watch-step09-classify-all` · `watch-step09-distribution` | ✅ 代码已落地 |
| **W1+W2** | **合并早报** | **每天 08:00 一封**：health + phase 全持仓 | **D0** | step_07 + 本实践记录 | `copilot-morning-brief` · `copilot-morning-brief-fast` | ✅ 已落地 |
| **W3** | **C · thesis 卡** | 持仓详情：为什么持有、break_signals | **D2** + 共享 22 | step_05 · [22 fact_gate](../../../03_原子目标与规约/_共享规约/22_事实交叉验证与防幻觉规约.md) | `deep-step05-*`（待联调） | ⏳ |
| **W3** | **D1 简版（保留）** | 日报「暴雷扫描」段 | **D1** | cryo 三引擎简版 | `cryo-step04-*` 等 | ⏳ +2d |
| **W3 末** | **D · 戴维斯对比** | 两只标的对比（如新易盛 vs 中际） | **D2** + **D0** | step_11 · step_08 | `deep-step11-*`（待 Makefile 齐） | ⏳ |
| **W4** | **E · 卖出信号** | SP1/SP3 + **SP2 简版** 邮件 | **D4** + **D0** | step_01～05 | `exit-step03-*` 等 | ⏳ |
| **W4 末** | **F · 加仓时机** | phase 升档提醒 | **D3** + **D0** | step_09 数据 + D0 规则 | 合入早报/告警 | ⏳ |

---

## 三、推送系统（三档 · 已锁定）

| 档位 | 何时 | 通道 | 你会看到 |
|------|------|------|----------|
| 🟢 **日报** | 每交易日 **08:00** | 邮件（126→Gmail） | 全持仓：health 分布 + market_phase 分布 + 明细表 |
| 🟡 **操作建议** | 实时；同股同类型 **1h 限频** | 邮件 | 单股：phase 切换、health 大降、break_signal 等 |
| 🔴 **高危** | 实时；**不静默** | 邮件 | 单股：exhaustion、SP1、D1 暴雷等 |

**环境变量（`diting-src/.env`）**：

| 变量 | 当前约定值 |
|------|------------|
| `COPILOT_DAILY_REPORT_TIME` | `08:00` |
| `COPILOT_DAILY_REPORT_MODE` | `holdings_merged`（合并早报；`legacy` = 旧 SCS 日报） |
| `COPILOT_SMTP_*` | 126 SSL 465 → `huishaoqiwork@gmail.com` |
| `MORNING_BRIEF_REFRESH` | `1` = 早报前刷新探针+阶段（慢） |
| `MORNING_BRIEF_RUN_PROBES` | `1` / `0` 跳过探针 |
| `MORNING_BRIEF_RUN_PHASE` | `1` / `0` 跳过全量 phase 重算 |
| `MARKET_PHASE_SYMBOLS` | 可选，如 `601138,300502` 仅跑子集 |

**阶段切换告警**：`events:monitor:market_phase_change` → Copilot `AlertDispatcher`（需 Copilot 进程消费 Redis）。

---

## 四、维度分工（回答「是不是只有 D3+D0」）

| 维度 | 在本路线中的作用 |
|------|------------------|
| **D0 副驾驶** | 邮件、APScheduler 8:00、告警栏、对比页（W3 末） |
| **D3 持仓监控** | health 探针/SLI/评分（W1）；market_phase（W2） |
| **D2 纵深进攻** | thesis、戴维斯、弹性（W3～W3 末） |
| **D4 卖出决策** | SP1/SP2/SP3（W4） |
| **D1 极寒防御** | 简版 3 引擎暴雷扫描（W3，用户保留） |
| **共享** | `my_holdings.yaml`、fact_gate 22、14 表 |

---

<a id="l4-mvp-w1w4-commands"></a>

## 五、核心指令（按本文执行 · 工作目录 `diting-src`）

### 5.1 每日（开盘前）

```bash
cd diting-src

# 推荐：快速早报（用库内缓存 phase/health，约 1～3 分钟）
make copilot-morning-brief-fast

# 完整：先探针+全量 phase 再发报（10 只约 10～15 分钟）
make copilot-morning-brief
```

**期望**：Gmail 收到主题含 `[diting] 持仓早报` 的 HTML 邮件。

### 5.2 W2 阶段分类（按需 / 盘后）

```bash
make watch-step09-test          # 规则单测
make watch-step09-classify-all # 全 active 分类 + 写库
make watch-step09-distribution  # 四档分布
```

### 5.3 W1 探针与 health（合并早报依赖）

```bash
make watch-step04-prep
make watch-step04-once-all    # P1～P4 探针各 tick 一次
make watch-step04-aggregate   # SLI 聚合（若 Makefile 已接 step06 可再接 health 计算）
```

> D3 完整 health 公式见 L3 [step_06](../../../03_原子目标与规约/03_维度三_持仓监控/stages/stage_1_启动期/steps/step_06_健康度计算与push_level.md)。合并早报会从 `holdings_state` + `node_sli_values` 推算 health。

### 5.4 即时告警（可选常驻）

```bash
# Copilot 起服务后，AlertDispatcher 消费 Redis
PYTHONPATH=. python3 -m uvicorn apps.copilot.main:app --host 127.0.0.1 --port 8080
# 另终端：告警消费者（若项目已配置独立 consumer 模块则按其 README）
```

### 5.5 持仓清单维护（你来做）

编辑 `diting-src/data/config/my_holdings.yaml`：`active` / `role`（portfolio|watchlist）/ `quantity` / `cost_price`。

---

## 六、验证步骤与期望结果

| # | 命令 | 工作目录 | 期望 |
|---|------|----------|------|
| 1 | `make watch-step09-test` | `diting-src` | pytest ≥14 passed |
| 2 | `make copilot-morning-brief-fast` | `diting-src` | 日志 `holdings morning brief sent` · `email ok=True` |
| 3 | 查 Gmail | — | 收到合并早报 HTML |
| 4 | `make watch-step09-distribution` | `diting-src` | JSON 含 `concept/expectation/realization/exhaustion` 计数 |

**验证结果去向**：更新本节「七、实际进展」；审计细节写入 `06_追溯与审计/`（若本轮有偏离）。

---

<a id="l4-mvp-w1w4-progress"></a>

## 七、实际进展（当前最佳验证 · 2026-05-28）

| 项 | 状态 | 证据摘要 |
|----|------|----------|
| W2 step_09 规则引擎 | ✅ | `tests/state_watch/test_market_phase_classifier.py` 14 passed；`make watch-step09-test` |
| W2 全量分类 | 🔄 | 10 只外网慢；`MARKET_PHASE_SYMBOLS=601138,300502` 2 只 e2e 成功（约 154s） |
| W1+W2 合并早报 | ✅ | `holdings_morning.py` + `COPILOT_DAILY_REPORT_MODE=holdings_merged`；`copilot-morning-brief-fast` → **email ok=True** |
| 8:00 cron | ✅ 配置 | `COPILOT_DAILY_REPORT_TIME=08:00`；需 Copilot 主进程 + APScheduler 运行 |
| L4 本文档 | ✅ | 首次入库 |

---

## 八、暂缓清单（启动期不做 · 用户已确认）

| # | 项 | 原因 |
|---|-----|------|
| 1 | D2 step_04 利润截留扫描仪 | 启动期人工选股够用 |
| 2 | D2 Thesis LoRA / HumanGate | 样本不足 |
| 3 | 主动嗅探 The Sniffer | 标的已选定 |
| 4 | D3 narrative LoRA | GPU+数据；degraded 即可 |
| 5 | D4 SP4 再平衡 | 手动调仓 |
| 6 | D5 演进飞轮全量 | 需 30+ 决策样本 |

---

## 九、准出检查清单（本路线阶段门）

- [ ] `my_holdings.yaml` 已填真实持仓且 **禁止提交 git**
- [ ] `make copilot-morning-brief-fast` 连续 3 个交易日 email ok
- [ ] `make watch-step09-classify-all` 对全 active 有当日 `market_phase_records`（或文档记录 `SKIP_REASON`）
- [ ] 合并早报 HTML 同时含 **health 分布** 与 **phase 分布**
- [ ] 阶段切换时（若开 Redis consumer）收到 **单股邮件**
- [ ] W3 起：thesis 卡 7 只 portfolio+关注 各至少 1 份 `confirmed`（见 §十）

---

## 十、W3 待办 · thesis 反向补全（协作模式）

| 步 | 谁 | 动作 |
|----|-----|------|
| 1 | AI | 按 [D2 step_05 §3.5.6](../../../03_原子目标与规约/02_维度二_纵深进攻/stages/stage_1_启动期/steps/step_05_thesis卡片生成器.md) 起草每 active 标的 thesis |
| 2 | 你 | 每只补 1～2 句产业链判断（15～20 分钟/只） |
| 3 | AI | fact_gate 验证后写库 |
| 4 | D0 | 持仓详情页展示 + break_signal 邮件 |

---

## 十一、本步骤失败时

| 现象 | 分析 | 修复 | 重试 |
|------|------|------|------|
| 早报未收到 | SMTP/授权码/垃圾箱 | 查 `COPILOT_SMTP_*`；跑 §六-2 | 同命令重试 ≤3 次 |
| phase 全 concept | 阈值严/行情缺 | 调 `data/config/market_phase_rules.yaml`；先 `watch-step03-price-once` | 再 `watch-step09-classify-all` |
| classify-all 超时 | 外网+10 只串行 | `MARKET_PHASE_SYMBOLS` 子集；`MORNING_BRIEF_RUN_PHASE=0` | 分批跑 |

仍失败 → 在「七、实际进展」标 `BLOCKED` 并链 [14 表 §9.1.1](../../../03_原子目标与规约/_共享规约/14_六维度启动期统一节奏表.md)。

---

## 十二、下一步（MVP 完成后）

1. **W3**：thesis + D1 简版 → 见上 §十  
2. **W4**：`exit-step03/05` + SP2 → 红色卖出建议邮件  
3. **扩展期**：LoRA 版 phase、D4 SP6 正式 exhaustion 协议 — 见 [step_09 §6](../../../03_原子目标与规约/03_维度三_持仓监控/stages/stage_1_启动期/steps/step_09_市场阶段分类器MVP.md)

---

## 修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-28 | 初版：自 2026-05-27 会话固化 MVP A～F、三档推送、W2 优先、W1+W2 合并早报代码锚点、Makefile 合约、与 14 表关系说明 |
