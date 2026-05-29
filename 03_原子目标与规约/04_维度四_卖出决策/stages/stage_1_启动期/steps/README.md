# 维度四·卖出决策·启动期·可执行步骤索引

> [!NOTE] **本目录定位**
> 给 Cursor / 开发者的"工作令"，每个 step 文件 = 一个可独立执行的开发任务。
> - 设计依据：见同级 [01_~05_](../) 5 份设计文档
> - DNA 真相源：[../../../../_System_DNA/04_exit_engine/dna_stage_1_启动期.yaml](../../../../_System_DNA/04_exit_engine/dna_stage_1_启动期.yaml)
> - 完成回写路径：[04_阶段规划与实践/04_维度四_卖出决策/stage_1_启动期/](../../../../../04_阶段规划与实践/04_维度四_卖出决策/stage_1_启动期/)

> **[上架与环境]** ECS+K3s · Helm · ACR · **`diting-infra`→`deploy-engine`**。[16](../../../../_共享规约/16_阿里云ECS_K3s_ACR_Helm部署与deploy-engine链路.md) · [L3§1](../../../../_共享规约/L3步骤文档_部署价值哲学_必选引用.md)

<a id="l3-step-l4-mapping-authority"></a>

### L3 ↔ L4 映射（权威）

- **唯一执行序**：**`#` 列 1→8**，即 **`step_01` … `step_08`**。
- **L4 实践记录文件名**：`实践记录_step_NN_*.md`，与本目录 **`step_NN_*.md`** 按下文 **「三、L4 实践记录预期清单」** **1:1**。
- **日历 / 跨维节拍**：见 [14_](../../../../_共享规约/14_六维度启动期统一节奏表.md)（含 **§九**）；**本目录不以周次为执行序**。

## 〇、三线并行门禁

| 线 | 要求 |
|---|---|
| **用户价值** | [15](../../../../_共享规约/15_前后端职责与产品价值优先级.md)；sell_signal→副驾驶红色告警触点 |
| **部署** | 规则引擎镜像与 values 由 Chart 注入；**diting-infra** 入口 |
| **哲学** | 纪律卖出、缓冲期不写死 Makefile；链 [06](../../../../01_顶层概念/06_投资哲学体系总纲.md)·[边界](../01_实践目标与策略.md) |

---

## 一、执行顺序与依赖

| # | Step | 上游 | 关键产出 | 行数 | 实施状态 |
|---|---|---|---|---|---|
| 1 | [step_01_规则引擎框架](./step_01_规则引擎框架.md) | - | apps/exit_engine + BaseProtocol + 持仓 schema | 150 | ✅ L3 v2 |
| 2 | [step_02_持仓数据接入与行情](./step_02_持仓数据接入与行情.md) | step_01 | akshare 行情 + 30 分钟刷新 + 10 笔 fixture | 149 | ✅ L3 v2 |
| 3 | [step_03_SP1止损协议](./step_03_SP1止损协议.md) | step_02 | SP1（priority=1，threshold=-0.15）+ 立即触发 | 146 | ✅ L3 v2 |
| 4 | [step_04_SP2止盈协议](./step_04_SP2止盈协议.md) | step_03 | SP2（priority=2，buffer=3 天）+ BufferManager 持久化 | 148 | ✅ L3 v2 |
| 5 | [step_05_SP3_Thesis失效协议](./step_05_SP3_Thesis失效协议.md) | step_04 + D3 step_07 | SP3 订阅 health_change + evidence_ref + no-auto | 157 | ✅ L3 v2 |
| 6 | [step_06_SP4再平衡协议](./step_06_SP4再平衡协议.md) | step_05 | SP4（priority=3，buffer=7 天）+ 部分卖出 + 反向取消 | 172 | ✅ L3 v2 |
| 7 | [step_07_冲突处理与回测](./step_07_冲突处理与回测.md) | step_06 | ConflictResolver 7 场景 + 100 笔回测 ≥0.95 + sell_signal publisher | 185 | ✅ L3 v2 |
| 8 | [step_08_阶段验收](./step_08_阶段验收.md) | step_07 | 6 大检查 + assert_no_auto_order + L5 `l5-stage-d4s1` | 174 | ✅ L3 v2 |

**共计**：8 份 step，**~1,281 行**（L3 实施规划体；旧版 ~8,128 行嵌入代码已剥离）。

**Makefile 前缀**：`exit-stepNN-*`（配置驱动）。

**no-mock & no-auto-order**：生产/Makefile 默认路径禁止 mock 事件与自动下单；`tests/` 内 TEST_ONLY fixture（含 100 笔回测 csv）合法。

---

## 二、关键决策与契约

| # | 关键约定 |
|---|---|
| 全局 | service_name = `exit-engine`；包路径 `apps/exit_engine/`；端口 8083 |
| 4 协议 | SP1 止损（-15%/p=1/buf=0）/ SP2 止盈（+30%/p=2/buf=3d）/ SP3 thesis（p=1/buf=0）/ SP4 再平衡（25%/p=3/buf=7d）|
| 冲突 | 按 (priority, protocol_name) 升序选最高；SP1 < SP3（字典序） |
| 缓冲期 | SQLite `pending_signals` 持久化（防重启丢失）+ 反向条件取消 |
| 事件 | events:exit:sell_signal 含 6 必选 + 7 扩展字段（sell_ratio/buffer_end_at 等） |
| 离线 | akshare 不可用时 `MockQuoteFetcher` 从 fixture JSON 读价 |
| 审计 | 冲突场景写 N+1 条审计（N 子 + 1 主 conflict_resolved） |

---

## 三、L4 实践记录预期清单

| step | L4 实践记录文件名 |
|---|---|
| step_01 | `实践记录_step_01_规则引擎框架.md` |
| step_02 | `实践记录_step_02_持仓数据接入与行情.md` |
| step_03 | `实践记录_step_03_SP1止损协议.md` |
| step_04 | `实践记录_step_04_SP2止盈协议.md` |
| step_05 | `实践记录_step_05_SP3_Thesis失效协议.md` |
| step_06 | `实践记录_step_06_SP4再平衡协议.md` |
| step_07 | `实践记录_step_07_冲突处理与回测.md` |
| step_08 | `实践记录_step_08_阶段验收.md` + `阶段总结_stage_1_启动期.md` |

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **全量 L3 v1.2 重写**：去嵌入代码；§3.5 质量矩阵；`exit-stepNN-*` Makefile 合约；no-mock & no-auto-order；行数 ~1,281 |
| 2026-05-16 | 全部 8 个 step 文档生成完成，共 8,128 行 |
| 2026-05-17 | **索引去周次化**；**14_ §九** 承载跨维映射与 Mock 退场闸；L3↔L4 权威说明 |
