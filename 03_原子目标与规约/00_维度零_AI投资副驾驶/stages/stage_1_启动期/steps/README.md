# 维度零·启动期·可执行步骤索引

> [!NOTE] **本目录定位**
> 本目录是**给 Cursor / 开发者的"工作令"**，每个 step 文件 = 一个可独立执行的开发任务（含完整代码、命令、验证、L4 回写指令）。
> - 设计依据：见同级 [01_实践目标与策略](../01_实践目标与策略.md) ~ [05_验收标准](../05_验收标准与检查清单.md)
> - DNA 真相源：[_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml](../../../../_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml)
> - 完成回写路径：[04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/](../../../../../04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/)

> **[上架与环境]** 目标运行时 **阿里云 ECS + K3s**；交付 **Helm Chart**；镜像 **阿里云 ACR**；编排入口 **`diting-infra` → `deploy-engine`**（独立仓库开发与推送，`make update-deploy-engine` 更新指针）。必读：[16 · 阿里云 ECS+K3s+Helm+ACR](../../../../_共享规约/16_阿里云ECS_K3s_ACR_Helm部署与deploy-engine链路.md) · [L3 steps §1 必读块](../../../../_共享规约/L3步骤文档_部署价值哲学_必选引用.md)

<a id="l3-step-l4-mapping-authority"></a>

### L3 ↔ L4 映射（权威）

- **唯一执行序**：**`#` 列 1→10**，即 **`step_01` … `step_10`**（见下表）。
- **L4 实践记录文件名**：`实践记录_step_NN_*.md`，与 **`step_NN_*.md`** 按下文 **[五、L4 实践记录预期清单](#五l4-实践记录预期清单执行时按此清单生成)** **1:1**。
- **六维度日历节奏**：若需与产品计划对齐，见共享规约 [14_六维度启动期统一节奏表](../../../../_共享规约/14_六维度启动期统一节奏表.md) — **本目录正文不承载日历周次**，避免与 step 序号混读。
- **step ↔ 跨维里程碑（Mock 退场）**：见 [14_ §九点四](../../../../_共享规约/14_六维度启动期统一节奏表.md#14-mock-exit-gates)。

## 〇、三线并行门禁（每张 `step_*.md` 必须满足）

| 线 | 要求 |
|---|---|
| **用户价值** | §1 资源表须含 [15§二～§七](../../../../_共享规约/15_前后端职责与产品价值优先级.md) 中与本步对应的 **P0/首日/触点**表述或链接 |
| **部署进度** | 凡涉镜像/Chart/K8s：**§1 + `### [Deploy]`** 小节，工作目录优先考虑 **`diting-infra`**；**禁止**在 `diting-infra/deploy-engine` 子模块内改代码 |
| **哲学挂钩** | 不重复 L1 条文；须在 §1 或准出中加一句 **与本步相关的边界**链到 [06_投资哲学体系总纲](../../../../../01_顶层概念/06_投资哲学体系总纲.md) 或本维 [`01_实践目标与策略.md`](../01_实践目标与策略.md) §边界 |

---

<a id="redis-docker-lifecycle"></a>

## 〇-1、Redis Docker 起停规约（跨步统一）

**目的**：凡涉及 `redis-cli` / `XADD` / `EventConsumer` / `AlertDispatcher.consume_forever` / 注入脚本连接 `6379` 的验证，**优先用 Docker 拉起 Redis**，并在**该步验证结束后主动关闭并移除容器**，避免长期占用端口、避免把「真 Stream」推迟到仅 step_09 才第一次起容器。

### 启动（验证前）

```bash
# 若名称/端口冲突可先删旧容器
docker rm -f diting-redis 2>/dev/null || true
docker run -d --name diting-redis -p 6379:6379 redis:7-alpine
# 就绪（返回 PONG）
until docker exec diting-redis redis-cli ping 2>/dev/null | grep -q PONG; do sleep 0.5; done
```

与 `diting-src` 对齐：`COPILOT_REDIS_URL=redis://127.0.0.1:6379/0`（或 `.env` 中等价项）。

**6379 已被占用**：可改用 `-p 6380:6379`，并设置 `COPILOT_REDIS_URL=redis://127.0.0.1:6380/0`，且在本步 L4「偏离与决策」注明。

### 验证后关闭（必做）

```bash
docker stop diting-redis
docker rm diting-redis
```

> **纪律**：各 step 文档中凡出现「本小节手工/终端级 Redis 验证」，须同时写明上式或显式写「验证通过后执行停止+删除」；执行方**不得**在验证结束后长期保留名为 `diting-redis` 的容器（本地另有共享 Redis 契约的除外，须在 L4 说明）。

### 各 step 植入索引（须引用本节的「起 → 验 → 停」）

| Step | 植入位置（示例） |
|---|---|
| [step_01](./step_01_后端依赖与服务骨架.md) | §3.6 手工验 `/health`：起 → curl → **停** |
| [step_02](./step_02_Web骨架与SQLite.md) | §3.7：可选验 `/health` 真连时启停；仅 pytest 可不启容器 |
| [step_03](./step_03_持仓体检模块.md) | §3.7 联调：`inject` / consumer 前起，步骤末 **停** |
| [step_04](./step_04_推荐池模块.md) | §3.8：`inject_mock_thesis` 前起，末尾 **停** |
| [step_05](./step_05_告警系统.md) | §3.12、§3.13：起 → 冒烟 / XADD → **停** |
| [step_06](./step_06_价值账本.md) | §3.15：需起 `uvicorn` 全链时启停（与 Redis 相关时） |
| [step_07](./step_07_日报周报推送.md) | §3.13：`uvicorn` 前起，手工段结束 **停** |
| [step_08](./step_08_月报与熔断.md) | §3.11：若熔断/状态走**真实** Redis（非 fakeredis 单测）则启停 |
| [step_09](./step_09_全链路联调.md) | testcontainers **自动**回收；若用手工 `docker run redis`，场景结束须 **stop/rm** |

**与 step_09 关系**：step_09 仍为 **四场景串联 + integration-status** 的收紧口；前序各步按上表完成 Docker Redis 起停后，不免除 step_09 的最终联调验收。

---

## 一、执行顺序与依赖

| # | Step | 上游 | 关键产出 | 行数 | 文档状态 |
|---|---|---|---|---|---|
| 1 | [step_01_后端依赖与服务骨架](./step_01_后端依赖与服务骨架.md) | - | copilot FastAPI 骨架 + 5 stream /health 探测 + no-auto-order | 123 | ✅ L3 v2 |
| 2 | [step_02_Web骨架与SQLite](./step_02_Web骨架与SQLite.md) | step_01 | HTMX/Alpine/Jinja + 3 组 SQLite 表 + 首屏 Lighthouse≥90 | 164 | ✅ L3 v2 |
| 3 | [step_03_持仓体检模块](./step_03_持仓体检模块.md) | step_02 + D3 | M1 4 色卡片 + 4 态详情 + 30d 曲线 + health_change consumer | 156 | ✅ L3 v2 |
| 4 | [step_04_推荐池模块](./step_04_推荐池模块.md) | step_03 + D2 | M2 thesis 5 必填 + 3 操作（无下单）+ WeasyPrint PDF | 165 | ✅ L3 v2 |
| 5 | [step_05_告警系统](./step_05_告警系统.md) | step_04 + D1/D3/D4 | M3 4 红+2 橙 + 3 通道 + 红色 5min SLA ≥99.5% | 161 | ✅ L3 v2 |
| 6 | [step_06_价值账本](./step_06_价值账本.md) | step_05 | M4 SCS/EV/8 象限/避险价值 + 熔断（仅警示）+ no-auto-stop | 168 | ✅ L3 v2 |
| 7 | [step_07_日报周报推送](./step_07_日报周报推送.md) | step_06 | 日报 18:00 + 周报周日 20:00 + 中文卡片 + 3 通道复用 | 152 | ✅ L3 v2 |
| 8 | [step_08_月报与熔断](./step_08_月报与熔断.md) | step_07 | 月报 T+1 100% + 熔断流程（UI 警示+ack 不停服务） | 153 | ✅ L3 v2 |
| 9 | [step_09_全链路联调](./step_09_全链路联调.md) | step_08 + D1~D5 | 5 e2e 场景 + 6 stream schema 0 diff + 联调收紧口 | 161 | ✅ L3 v2 |
| 10 | [step_10_阶段验收](./step_10_阶段验收.md) | step_09 | 6+1 大检查 + assert_no_auto_order + L5 `l5-stage-d0s1` | 182 | ✅ L3 v2 |

**共计**：10 份 step，**~1,585 行**（L3 实施规划体；旧版 ~10,949 行嵌入代码已剥离）。

**Makefile 前缀**：`copilot-stepNN-*`（配置驱动）。

**no-auto-order & no-auto-stop**：D0 严守"观察者模式"——UI 无下单按钮、通道无下单链接、熔断仅警示；`tests/` 内 fakeredis 等仅限单测，业务/`make all` 路径用真 Redis。

**共计**：10 份 step，**10,662 行可执行文档**。

**状态图例**：
- 文档状态：✅ 已生成 ｜ ⏳ 待写
- 实施状态：⏳ 未开始 ｜ 🔄 进行中 ｜ ✅ 已完成 ｜ ⚠️ 偏离

---

## 二、Cursor 使用方式

### 方式一：单步执行
1. 打开下一个 `实施状态=⏳` 的 step 文件 → Cursor 阅读
2. 让 Cursor 按照 step 文件中"§3 详细实施步骤"在 `diting-src` 下执行
3. 完成后 Cursor 自动按 step 文件 §4 在 L4 对应路径写实践记录
4. 标记本表"实施状态"为 ✅，进入下一步

### 方式二：批量串行
- 一句指令："按 `steps/README.md` 顺序，从 step_01 开始执行，每完成一步先在 L4 写记录后再开始下一步"

### 方式三：分块并行（注意依赖）
- step_01 → step_02 → step_03 必须串行（前后端依赖）
- step_05 与 step_06 可半并行（前者上游 step_04，后者上游 step_05 但部分 SCS/EV 可并发）
- step_09 必须等所有 6 维度就绪

---

## 二-1、开发期宽松验证与 step_09 收紧口

<a id="l3-steps-loose-to-tight"></a>

> **单一收紧门禁**：[step_09 全链路联调](./step_09_全链路联调.md#l3-step09-tightening) **§1.1**（四场景串联 + Consumer 证据 + integration-status + mock 收口）。  
> **Redis**：凡涉及 Stream/注入/Consumer 的终端验证，各步须先按 [〇-1 · Redis Docker 起停规约](#redis-docker-lifecycle) **启动验证、验证后关闭**；**不**把「第一次起真 Redis」推迟到 step_09 才在本地起手。step_09 负责**全链收紧与场景审计**，不替代各步本地 Docker 纪律。  
> 下表汇总「前几步文档已写明可宽松」的项，避免误以为「某步永久不测」。

| 前序 step | 开发期常见宽松 | step_09 收紧要点 |
|---|---|---|
| step_01 | 无 Redis 时 `/health` Stream **mock**；有 Docker 时可真连 | 四场景下 Stream 观测与 integration-status 对齐 §1.1 |
| step_03 | mock `health_change`；Consumer 可仅单测 | **场景 B** + 各步已 Docker 起停前提下再串联证据 |
| step_04 | mock `thesis_proposed` | **场景 A** 或 `issues.md` |
| step_05 | 通道 **stub**；Redis 断线重试 | **场景 C** + `integration-status` + SLA 实测 |
| step_06 | WeasyPrint **HTML-only**；行情 **mock** | **场景 D**；PDF/数据按验收与 issues |
| step_07 | `is_demo`、历史不足 | step_09 对应 L4 对 SLA/演示数据范围给结论 |
| step_08 | （熔断策略以 step 为准） | 纳入场景与 admin 路由联调审查 |

---

## 三、各 step 关键决策与契约（实施时遵守）

| # | 关键约定 |
|---|---|
| step_01 | 包路径：`apps/copilot/`（不是根级 `copilot/`）|
| step_02 | 表名：`users / holdings / value_snapshots / event_logs`（启动期单用户 `user_id='default'`）|
| step_03 | EventConsumer 用 `copilot_group` + `xreadgroup` + `xack`，幂等按 `event_id`；**终端联调** Redis 启停见 [〇-1](#redis-docker-lifecycle) |
| step_04 | Pydantic v2 5 必填强校验；校验失败仅落 `event_logs` 不污染 `thesis_cards` |
| step_05 | AlertDispatcher 三通道全 stub 降级（凭据缺失不阻塞），SLA 时钟统一 UTC |
| step_06 | WeasyPrint 不可用时 HTML-only 降级；自我熔断 B+H 占比 ≥ 35% 触发 |
| step_07 | `is_demo` 标记：数据不足时报告生成但不计 SLA 失败 |
| step_08 | 熔断 24h 自动恢复 + 手工 `force_resume`，需 `x-admin-token` |
| step_09 | testcontainers Redis fixture，CI fallback 到 `REDIS_URL`；**并见** [step_09 §1.1](./step_09_全链路联调.md#l3-step09-tightening) **统一收紧前序 mock/stub** |
| step_10 | `scripts/validate_stage_1.sh` 6 大类自动化输出 JSON 报告 + 终端 ✅/❌ |

---

## 四、模板与 DNA 引用

- **step 文件模板**：参考 [step_01](./step_01_后端依赖与服务骨架.md) 的标准 6 块结构
- **L4 实践记录模板**：[../../../../../04_阶段规划与实践/_模板/](../../../../../04_阶段规划与实践/_模板/)
- **DNA**：每个 step 对应 `_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml` 中的 `deliverables.modules[X]`

---

<a id="五l4-实践记录预期清单执行时按此清单生成"></a>

## 五、L4 实践记录预期清单（执行时按此清单生成）

> **术语**：下表中的 **`实践记录_step_NN_*.md`** 即为各步骤的 **「实践结果文档」**（验证证据、偏离、复验命令的正文载体；L3 `step_*.md` 为设计与命令，不在 L3 内堆多轮终端全文）。**对应关系以 step 序号（NN）为唯一权威。**

| step | L4 实践记录文件名 |
|---|---|
| step_01 | `实践记录_step_01_后端依赖与服务骨架.md` |
| step_02 | `实践记录_step_02_Web骨架与SQLite.md` |
| step_03 | `实践记录_step_03_持仓体检模块.md` |
| step_04 | `实践记录_step_04_推荐池模块.md` |
| step_05 | `实践记录_step_05_告警系统.md` |
| step_06 | `实践记录_step_06_价值账本.md` |
| step_07 | `实践记录_step_07_日报周报推送.md` |
| step_08 | `实践记录_step_08_月报与熔断.md` |
| step_09 | `实践记录_step_09_全链路联调.md` |
| step_10 | `实践记录_step_10_阶段验收.md` + `阶段总结_stage_1_启动期.md` |

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-16 | 全部 10 个 step 文档生成完成，共 10,662 行 |
| 2026-05-17 | 新增 §二-1：前序宽松 → step_09 §1.1 收紧对照表；step_09 行链至 §1.1 |
| 2026-05-17 | step_05 实施状态 ✅（M3 落地 diting-src） |
| 2026-05-17 | **step_04 实施状态 ✅**（M2 落地 `diting-src`；**含 Dockerfile §3.10**；L4 `实践记录_step_04_推荐池模块.md`） |
| 2026-05-17 | 新增 **〇-1 Redis Docker 起停规约**（跨步）；二-1 与前序 step 表对齐「分段 Docker、step_09 串联收紧」；step_01/02/03/04/05/06/07/08/09 植入启停纪律 |
| 2026-05-17 | L4：`实践记录_step_02` / `实践记录_step_05` 按 step_02/step_05 **§2.5** 复验回写 |
| 2026-05-17 | step_02/step_05 文首增加 **L4 实践结果文档** 可点击入口；§五 注明 `实践记录_*.md` 即「实践结果文档」 |
| 2026-05-17 | **索引去周次化**：删除 W 跳号说明与日历周列表；**一、** 表仅保留 step 序号与依赖；**五、** 仅 `实践记录_step_NN_*` |
| 2026-05-17 | 历史上曾对齐 §8.4h 与「周次别名」说明；**即日起本维 steps 以 step_NN 为唯一叙事**，日历节奏见 14_ 共享规约 |
| 2026-05-17 | **step_08 实施状态 ✅**（月报 PDF 管线、`SelfCircuitBreaker`、`fakeredis` 单测、`copilot.monthly_report` 调度；L4 `实践记录_step_08_月报与熔断.md`） |
