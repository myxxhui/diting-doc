# 维度三·持仓监控·启动期·可执行步骤索引

> [!NOTE] **本目录定位**
> 本目录是**给 Cursor / 开发者的"工作令"**,每个 step 文件 = 一个可独立执行的开发任务(含完整代码、命令、验证、L4 回写指令)。
> - 设计依据:见同级 [01_实践目标与策略](../01_实践目标与策略.md) ~ [05_验收标准](../05_验收标准与检查清单.md)
> - DNA 真相源:[_System_DNA/03_holding_watch/dna_stage_1_启动期.yaml](../../../../_System_DNA/03_holding_watch/dna_stage_1_启动期.yaml)
> - 完成回写路径:[04_阶段规划与实践/03_维度三_持仓监控/stage_1_启动期/](../../../../../04_阶段规划与实践/03_维度三_持仓监控/stage_1_启动期/)
> - 共享时序(场景 B 持仓体检):[_共享规约/13_六维度启动期集成与时序](../../../../_共享规约/13_六维度启动期集成与时序.md)
> - 共享节奏、硬里程碑（M3 health_change）与 Mock 退场闸：[14_六维度启动期统一节奏表](../../../../_共享规约/14_六维度启动期统一节奏表.md) **§九**

> **[上架与环境]** **ECS + K3s · Helm · ACR · diting-infra→deploy-engine**。[16](../../../../_共享规约/16_阿里云ECS_K3s_ACR_Helm部署与deploy-engine链路.md) · [L3§1必选](../../../../_共享规约/L3步骤文档_部署价值哲学_必选引用.md)

<a id="l3-step-l4-mapping-authority"></a>

### L3 ↔ L4 映射（权威）

- **唯一执行序**：**`#` 列 1→8**，即 **`step_01` … `step_08`**。
- **L4 实践记录文件名**：`实践记录_step_NN_*.md`，与本目录 **`step_NN_*.md`** 按下文 **「五、L4 实践记录预期清单」** **1:1**。
- **日历周次**：仅作产品对齐参照 — **不作为本目录执行序**；权威节拍与 step↔里程碑见 **14_（§三、§九）**。

## 〇、三线并行门禁

| 线 | 要求 |
|---|---|
| **用户价值** | 链 [15](../../../../_共享规约/15_前后端职责与产品价值优先级.md)；**health_change** → 副驾驶 4 色/告警触点 |
| **部署** | 探针/workload 镜像 **ACR**；升级走 **Helm**，入口 **diting-infra**；勿改 deploy-engine 子模块 |
| **哲学** | [06](../../../../01_顶层概念/06_投资哲学体系总纲.md)；[维度三边界](../01_实践目标与策略.md) |

---

## 一、执行顺序与依赖

| # | Step | 上游 | 关键产出 | 行数 | 文档状态 |
|---|---|---|---|---|---|
| 1 | [step_01_状态机与DB_schema](./step_01_状态机与DB_schema.md) | - | LangGraph 4 态+T1~T6 转移+SQLite 三表+SoT 注册 | 170 | ✅ L3 v2 |
| 2 | [step_02_财务与新闻探针](./step_02_财务与新闻探针.md) | step_01 | P1(24h 6 metric)+P2(1h 情感)+coverage 矩阵 | 159 | ✅ L3 v2 |
| 3 | [step_03_价格与事件探针](./step_03_价格与事件探针.md) | step_02 | P3(30min 6 metric)+P4(6h 5 metric)+交易时段 | 155 | ✅ L3 v2 |
| 4 | [step_04_探针调度器与SLI聚合](./step_04_探针调度器与SLI聚合.md) | step_03 | ProbeScheduler+NodeSLIValue+加权聚合纯函数 | 154 | ✅ L3 v2 |
| 5 | [step_05_叙事一致性NLI_LoRA](./step_05_叙事一致性NLI_LoRA.md) | step_04+D5 | narrative_nli_lora_v1 Acc≥0.85；degraded 不伪造 | 164 | ✅ L3 v2 |
| 6 | [step_06_健康度计算与push_level](./step_06_健康度计算与push_level.md) | step_05 | health=0.5sli+0.3 narrative+0.2 freshness；T1~T6 评估 | 157 | ✅ L3 v2 |
| 7 | [step_07_health_change事件流与10持仓测试](./step_07_health_change事件流与10持仓测试.md) | step_06 | Stream 发布器+P95<30s+e2e 准确率≥0.90+D0/D4 schema | 169 | ✅ L3 v2 |
| 8 | [step_08_阶段验收](./step_08_阶段验收.md) | step_07 | 6 大检查+L5 `l5-stage-d3s1`+state-watch v0.1.0 | 159 | ✅ L3 v2 |
| 9 | [step_09_市场阶段分类器MVP](./step_09_市场阶段分类器MVP.md) | step_03+step_07 | 4 档（concept/expectation/realization/exhaustion）+ 纯规则启动期 + 与 D2 timer/D4 SP6 联动 | 280 | ✅ L3 v1.0 |

**共计**：9 份 step，**~1,567 行**（L3 实施规划体；旧版 ~7,332 行嵌入代码已剥离）。

**Makefile 前缀**：`watch-stepNN-*`（配置驱动：改 `my_holdings.yaml` 即可端到端复跑）。

**no-mock**：生产/Makefile 默认路径禁止 stub；`tests/` 内 TEST_ONLY fixture 合法。

---

## 二、Cursor 使用方式

### 方式一:单步执行
1. 打开下一个 `实施状态=⏳` 的 step 文件 → Cursor 阅读
2. 让 Cursor 按照 step 文件中"§3 详细实施步骤"在 `diting-src` 下执行
3. 完成后 Cursor 自动按 step 文件 §4 在 L4 对应路径写实践记录
4. 标记本表"实施状态"为 ✅,进入下一步

### 方式二:批量串行
- 一句指令:"按 `steps/README.md` 顺序,从 step_01 开始执行,每完成一步先在 L4 写记录后再开始下一步"

### 方式三:分块并行(注意依赖)
- step_01 → step_02 → step_03 必须串行(BaseProbe / 模型 / 适配器 累积)
- step_04 必须等 step_03 完(scheduler 注册需要 4 类探针类)
- step_05 与 step_04 可半并行(数据/训练在另一台 GPU 机器同时进行)
- step_06 必须等 step_04 + step_05(用 SLI 聚合器 + NLI 客户端)
- step_07 必须等 step_06(orchestrator 升级)
- step_08 必须等 step_01-07 全部就绪

---

## 三、各 step 关键决策与契约(实施时遵守)

| # | 关键约定 |
|---|---|
| step_01 | 包路径:`apps/state_watch/`(不是根级 `state_watch/`,与 D0 `apps/copilot/` 对齐) |
| step_01 | 端口:`8003`(state-watch 服务);DB:`sqlite+aiosqlite:///./data/state_watch.db` |
| step_01 | 6 条转移规则强约束:T1 持仓 > 6 月 + thesis 仍成立、T2 GROWING<60、T3 STABLE<60 或 contradiction、T4 narrative_invalid_count≥3、T5 WARNING>75 持续 7d、T6 WARNING<30 或失效 |
| step_02 | 数据源：AKShare/RSS/巨潮；冷门标的新闻<3 条只标 coverage 降级，**不**写 stub 入库 |
| step_03 | RSI/drawdown/vol_ratio 纯函数实现,边界 100/0 已兜底；非交易时段标 closed_market |
| step_04 | APScheduler `_is_trading_hours` 用 UTC+8 偏移近似,扩展期切 pytz |
| step_04 | NodeSLIValue 表:`(holding_id, metric)` 唯一索引,upsert 写入 |
| step_05 | LoRA rank=16, alpha=32;3 epoch;cutoff_len=2048;train ≥ 100,holdout=30 |
| step_05 | 无 GPU 时 SKIP 训练 + 评测,但仍须完成数据 + 客户端 + stub + 测试 |
| step_06 | 权重 α=0.5/β=0.3/γ=0.2 在 calculator 构造期校验 sum==1.0 |
| step_06 | push_level 边界:80/60/30 严格大于等于;0-29 → 3 红色 |
| step_07 | Stream key:`events:monitor:health_change`;消费组 `dim_zero / dim_four` |
| step_07 | thesis_status="invalid" 触发条件:new_state==exit OR (contradiction && invalid_count≥3) |
| step_07 | 真 Redis 与 fakeredis：tests/ 可 fakeredis；**生产/`make all` 禁止伪造事件** |
| step_08 | H6 NLI 在无 GPU 时合理 SKIP 不阻塞;6 大类其他必须 PASS |

---

## 四、模板与 DNA 引用

- **step 文件模板**:参考 [step_01](./step_01_状态机与DB_schema.md) 的标准 6 块结构(给 Cursor 的指令 / 上下文 / 准出 / 详细步骤 / L4 回写 / 失败回退 + 引用 + 修订记录)
- **L4 实践记录模板**:[../../../../../04_阶段规划与实践/_模板/](../../../../../04_阶段规划与实践/_模板/)
- **DNA 真相源**:`_System_DNA/03_holding_watch/dna_stage_1_启动期.yaml`
  - `deliverables.state_machine`:4 态 + 6 转移
  - `deliverables.sli_probes`:P1-P4 调度间隔
  - `deliverables.narrative_consistency`:LoRA 名称 / 准确率阈值
  - `deliverables.health_score`:范围 + push_level 映射
  - `quantitative_goals`:推送 < 30s / Accuracy ≥ 0.85 / 切换准确率 ≥ 0.90

---

## 五、L4 实践记录预期清单(执行时按此清单生成)

| step | L4 实践记录文件名 |
|---|---|
| step_01 | `实践记录_step_01_状态机与DB_schema.md` |
| step_02 | `实践记录_step_02_财务与新闻探针.md` |
| step_03 | `实践记录_step_03_价格与事件探针.md` |
| step_04 | `实践记录_step_04_探针调度器与SLI聚合.md` |
| step_05 | `实践记录_step_05_叙事一致性NLI_LoRA.md` |
| step_06 | `实践记录_step_06_健康度计算与push_level.md` |
| step_07 | `实践记录_step_07_health_change事件流与10持仓测试.md` |
| step_08 | `实践记录_step_08_阶段验收.md` + `阶段总结_stage_1_启动期.md` |
| step_09 | `实践记录_step_09_市场阶段分类器MVP.md` |

---

## 六、与其他维度的联动

| 维度 | 联动点 | step | 说明 |
|---|---|---|---|
| 维度零(D0) | `events:monitor:health_change` 消费 | step_07 | D0 step_03 EventConsumer 用 `dim_zero` 消费,push_level=2/3 触发告警 |
| 维度二(D2) | `events:thrust:thesis_proposed` 输入 | step_01 | 启动期可手工/mock 注册；**D2 thesis 真流就绪后**再接真实 thesis |
| 维度四(D4) | `thesis_status="invalid"` → SP3 触发 | step_07 | D4 用 `dim_four` 消费,符合条件触发 sell_signal |
| 维度五(D5) | LoRA 训练流水线(可选)| step_05 | 启动期可本地 LLaMA-Factory 跑通;扩展期接 D5 守门 |

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **全量 L3 v1.2 重写**：去嵌入代码；§3.5 质量矩阵；`watch-stepNN-*` Makefile 合约；no-mock；行数 ~1,287 |
| 2026-05-16 | 初版:8 份 step 索引,共 7,332 行可执行文档 |
| 2026-05-17 | **索引去周次化**；**14_ §九** 承载跨维映射与 Mock 退场闸；L3↔L4 权威说明 |
| 2026-05-27 | **本轮关键重构 §4.5**：新增 step_09 市场阶段分类器 MVP（4 档正交轴 concept/expectation/realization/exhaustion · 纯规则启动期 + LoRA 扩展期）；与 D2 step_05 thesis 4 新字段 + D2 step_11 估值动态 + D2 timer_signal + D4 SP6 候选事件协同；总数 8→9 |
