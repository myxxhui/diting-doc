# Step 04 · M2 推荐池 + thesis 卡（5 必填）+ 3 操作按钮 + PDF 导出

## §1 一句话定位与本步交付物

**一句话**：实现 **M2 推荐池**——订阅 `events:thrust:thesis_proposed`（D2）→ 渲染**推荐池页**（按 confidence 排序）+ **thesis 卡详情页**（**5 必填**：thesis / catalyst / valuation / risk / exit_condition）+ **3 操作按钮**（"加入观察"/"标记为已研究"/"不感兴趣"，**均不下单**）+ PDF 导出（WeasyPrint）。

**交付物**（勾选 = 完成）：
- [ ] **A**（`ThesisConsumer`）：组 `dim_zero_thesis`；写 `thesis_pool(thesis_id, symbol, confidence, status, payload, received_at)`
- [ ] **B**（推荐池路由）：`GET /thesis-pool`；按 confidence 降序；过滤 status
- [ ] **C**（thesis 卡详情）：`GET /thesis/{thesis_id}`；5 必填字段渲染；缺字段标"未提供"
- [ ] **D**（3 操作按钮）：`POST /thesis/{id}/action`（watch/researched/dismiss）→ 写 `thesis_actions`；UI 仅状态变更
- [ ] **E**（PDF 导出）：`GET /thesis/{id}/pdf`；WeasyPrint 渲染；含 5 必填 + 当时 confidence
- [ ] **F**（D2 未就绪降级）：池为空→展示"待 D2 推送"，**不**假数据
- [ ] **G**（单测）：≥12 含 consumer/action/5 必填校验/PDF
- [ ] **H**（Makefile）：`make copilot-step04-all`

> **永久规则**：3 个按钮**不**对接任何券商 API；"加入观察"仅本地标注。

## §2 TRACEBACK 锚点

> [!NOTE] **[TRACEBACK]**
> - **L3**：[../01_实践目标与策略.md](../01_实践目标与策略.md) M2、[../02_技术方案与代码架构.md](../02_技术方案与代码架构.md)
> - **DNA**：`modules[1] M2`（推荐池/5 必填/3 按钮/PDF）
> - **D2 上游**：[02_维度二_纵深进攻 step_09](../../../02_维度二_纵深进攻/stages/stage_1_启动期/steps/step_09_端到端联调.md)
> - **L4**：[实践记录_step_04_推荐池模块.md](../../../../../04_阶段规划与实践/00_维度零_AI投资副驾驶/stage_1_启动期/实践记录_step_04_推荐池模块.md)
> - **上游**：step_01/02；D2 step_09；**下游**：step_05 告警引用推荐 + step_06 价值账本对账

## §3 数据采集对象 / 落库映射

| 输入 | 落库 |
|---|---|
| `events:thrust:thesis_proposed` | `event_logs` + `thesis_pool` |
| 用户操作 | `thesis_actions(thesis_id, action, ts)` |
| PDF | 临时生成不持久；导出日志写 `pdf_exports` 可选 |

## §3.5 数据质量验收矩阵（M2 · 仅启动期）

### §3.5.1 5 必填严格

| # | 字段 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| F1 | **thesis** | 投资逻辑 1~3 段 | ✅ | 空→标"未提供"+告警 |
| F2 | **catalyst** | 短中长 ≥1 项 | ✅ | — |
| F3 | **valuation** | 多视角 ≥1 + 锚点价 | ✅ | — |
| F4 | **risk** | ≥3 项与对应触发器 | ✅ | — |
| F5 | **exit_condition** | 止损/止盈/Thesis 失效 ≥1 项 | ✅ | — |
| F6 | **校验** | Pydantic v2 强制 5 字段非空字符串 | ✅ | 不可入推荐池 |

### §3.5.2 推荐池与操作

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| P1 | **confidence 排序** | desc | ✅ | — |
| P2 | **status filter** | new/watch/researched/dismissed | ✅ | — |
| P3 | **3 操作语义** | watch=本地观察；researched=已读；dismiss=隐藏 | ✅ | — |
| P4 | **不下单** | UI/路由/code grep 无券商 API 调用 | ✅ | — |
| P5 | **审计** | 每次 action 写 thesis_actions | ✅ | — |

### §3.5.3 PDF 与一致性

| # | 维度 | 必产 | 启动期 | 降级 |
|---|---|---|---|---|
| D1 | **PDF 渲染** | WeasyPrint 生成 ≤2s 完成 | ✅ | 慢→后台任务（扩展期）|
| D2 | **PDF 含 5 必填** | 同 UI；含 confidence/exit/risk | ✅ | — |
| D3 | **离线可读** | A4 + 中文字体 | ✅ | — |

### §3.5.4 no-mock

| # | 维度 | 必产 | 启动期 |
|---|---|---|---|
| N1 | **D2 未就绪 UI 文案** | 池空显式标 | ✅ |
| N2 | **不伪造 confidence** | 仅来自 D2 payload | ✅ |
| N3 | **action 不触发下单** | grep broker SDK = 0 | ✅ |

> 共 **15 项**。

## §4 凭证清单

| 凭证 | 用途 |
|---|---|
| `REDIS_URL` | consumer |
| D2 step_09 真流可用 | 主路径 |
| WeasyPrint 中文字体 | PDF 渲染 |

## §5 启动期目标

| 指标 | 门槛 |
|---|---|
| D2 真流 thesis 入池 | ≥1 真实 thesis |
| 5 必填校验通过率 | 100%（不通过不入池）|
| PDF 渲染 | ≤2s |
| 单测 | ≥12 |

## §6 下一步

本步 ✅ → step_05 M3 告警系统。

## §7 实施规划

### §7.1 实现要点

| 要点 | 位置 | 决策 | 验证 |
|---|---|---|---|
| **A ThesisConsumer** | `events/thesis_consumer.py` | XREADGROUP；5 必填校验 | mock test |
| **B `thesis_pool` ORM + `thesis_actions`** | `models/thesis.py` + alembic | §3 字段 | migration |
| **C 推荐池路由 + 模板** | `api/routes/m2.py` + `templates/thesis_pool.html` | desc 排序 + filter | 200 |
| **D 详情页** | `templates/thesis_detail.html` | 5 必填字段渲染 | 视觉 |
| **E 3 按钮 + action API** | `api/routes/m2.py` | watch/researched/dismiss | 单测 |
| **F PDF** | `services/pdf_exporter.py` | WeasyPrint + Jinja PDF template | 渲染 |
| **G 单测** | `test_thesis_consumer.py`、`test_m2_routes.py`、`test_pdf.py` | ≥12 | pytest |
| **H no-broker grep** | `scripts/assert_no_broker_sdk.sh` | grep `tushare-trade`、`xt`、`broker` 等 | 0 命中 |

### §7.2 Makefile

| target | 验证 |
|---|---|
| `copilot-step04-prep` | D2 stream 存在或 BLOCKED |
| `copilot-step04-consumer-up` | 起 consumer +5s |
| `copilot-step04-validate-5fields` | 测试样例 + 缺字段 → 不入池 |
| `copilot-step04-pdf-once` | 1 thesis 导 PDF |
| `copilot-step04-action-test` | 3 按钮路径走 |
| `copilot-step04-nobroker-check` | 0 命中 |
| `copilot-step04-test` | pytest ≥12 |
| `copilot-step04-all` | 端到端 |
| `copilot-step04-status` | 池数 + 4 status 分布 |

### §7.3 指引

先 5 必填 Pydantic→consumer→ORM→UI→action→PDF→nobroker；D2 未就绪 BLOCKED 但保留 UI"待推荐"提示。

## §8 部署节奏

本机；扩展期 PDF 后台 task queue。

## §9 准出标准

- [ ] §3.5 15 项；至少 1 真实 thesis 入池 + PDF 导出
- [ ] D2 真流路径或 BLOCKED + TEST_ONLY 已过
- [ ] `make copilot-step04-all`；L4 回写（thesis 数、5 必填通过率、PDF 路径）

## §10 [Deploy]

ConfigMap 增 `THESIS_PDF_FONT_PATH=...`。

## §11 依赖

step_01/02；D2 step_09；WeasyPrint。

**严禁**：3 按钮触发外部 API；放宽 5 必填；假数据入池。

## §12 风险

| 触发 | 动作 |
|---|---|
| 5 必填经常缺字段 | 提示用户/D2 回查 |
| PDF 慢 | 缓存 + 异步 |
| D2 长断 | UI 文案；轮询保活 |
| 同问题 ≥2 次 | §8.4f |

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **v2 按 L3 v1.2 重写**：删 1125 行嵌入 HTML/Python；§3.5 15 项；5 必填严格；no-broker；`copilot-step04-*`；1125→~220 行 |
| 2026-05-16 | 初版 1125 行 |
