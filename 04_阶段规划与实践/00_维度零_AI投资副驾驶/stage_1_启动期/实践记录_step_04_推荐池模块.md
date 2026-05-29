# 实践记录 · 维度零·AI 投资副驾驶 · 启动期 · step_04 · M2 推荐池与 thesis 卡

> [!NOTE] **[TRACEBACK] 实践锚点**
> - **L3 step**: [step_04_推荐池模块.md](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_04_推荐池模块.md)
> - **DNA**: [_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml)（`deliverables.modules[1]` · M2）
> - **本阶段看板**: [README.md](./README.md)

---

## 一、本步计划（来自 L3）

- 引用：[step_04_推荐池模块.md](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_04_推荐池模块.md)
- 目标：M2 全栈（ORM / schema / handler / service / PDF / HTMX / 测试 / mock 注入）+ **§3.10 Linux 验证镜像**（`Dockerfile`、容器内 **0 skip** 全量 pytest）

---

## 二、实际进展

| §3.x / 项 | 状态 | 说明 |
|---|---|---|
| 3.1 依赖 | ✅ | `pyproject.toml`：`weasyprint>=62`、`pydantic>=2.6` |
| 3.2～3.9 | ✅ | 与上轮一致：M2 代码 + `test_recommendation.py` |
| **3.10 Docker** | ✅ | 仓根 `Dockerfile`（`python:3.11-slim-bookworm` + Pango/Cairo/GDK-Pixbuf + `fonts-noto-cjk`）+ `.dockerignore` |
| 3.11 commit/push | ⚠️ | 未执行（用户规则） |

### 偏离与决策

| 项 | 决策 |
|---|---|
| **PDF 权威验证** | **§3.10 镜像内** `pytest`：`57 passed`、`0 skipped`，`test_pdf_generation_returns_bytes` **PASSED** |
| **macOS 本机** | Apple `python3` 上 PDF 仍可能 **SKIP**（FFI 库命名差异）；**不阻断** step_04 产品准出，以 L3 §3.10 / 本记录 **§三-B** 为准 |

### 关键交付物（`diting-src`）

- `Dockerfile`、`.dockerignore`
- 其余路径同前：`apps/copilot/modules/recommendation/*`、`events/handlers/thesis_proposed.py`、`events/consumer.py`、`templates/recommendation/*`、`scripts/inject_mock_thesis.py`、`tests/copilot/test_recommendation.py` 等

---

## 三、测试运行

### 命令（本机，对照）

```bash
cd /Users/huishaoqi/Desktop/workspace/diting-src
python3 -m pip install -e .
python3 -m pytest tests/copilot/ -q
```

（本机可能出现 **`56 passed, 1 skipped`**，skip 为 PDF。）

### 三-B、Linux 镜像（**产品准出**，2026-05-17 本会话）

```bash
cd /Users/huishaoqi/Desktop/workspace/diting-src
docker build -t diting-copilot-verify:step04 .
docker run --rm diting-copilot-verify:step04 python -m pytest tests/copilot/ -q --tb=short
```

**输出摘录**：

```
.........................................................                [100%]
57 passed in 14.40s
```

---

### 三-2、复验.command（准出必跑）

```bash
cd /Users/huishaoqi/Desktop/workspace/diting-src
# 权威：Linux 镜像内全量 pytest，须 0 skipped
docker build -t diting-copilot-verify:step04 .
docker run --rm diting-copilot-verify:step04 python -m pytest tests/copilot/ -q --tb=short
# 可选：本机回归（允许 PDF skip）
python3 -m pip install -e . && python3 -m pytest tests/copilot/test_recommendation.py -v --tb=short
```

**期望信号**：镜像内 **`57 passed`**（或与当时 `tests/copilot/` 收集数一致）、**`0 skipped`**。

---

### 三-3、W4 tier-1 复验（2026-05-25 · `make copilot-step04-all`）

```bash
cd /Users/huishaoqi/Desktop/workspace/diting-src
make copilot-step04-all
```

**输出摘录**：

```
▶ [copilot-step04-prep] copilot 数据库 + events 消费者路由自检
  copilot DB 初始化 ✅
  handler: mapper_thesis ✅
  handler: thesis_proposed ✅
▶ [copilot-step04-consumer-check] 确认 consumer 订阅了 events:deep_strike:thesis_proposed
  consumer 已订阅 events:deep_strike:thesis_proposed ✅
▶ [copilot-step04-pool-status] thesis_cards 当前状态
  thesis_cards 总数=0（其中 mapper_candidate=0）
  events:deep_strike:thesis_proposed event_logs=0
  推荐池状态: 空池（BLOCKED-B 路径，等待 D2 thesis 真流）⚠️
▶ [copilot-step04-test] pytest copilot mapper_thesis handler
  2 passed, 71 deselected in 1.03s
✅ [copilot-step04-all] 准出：DB + consumer + pool_status
```

**结论**（对照 14 表 W4 tier-1 口径）：

| 验收项 | 期望 | 实际 | 状态 |
|---|---|---|---|
| copilot DB 初始化 | 无异常 | ✅ init OK | ✅ |
| consumer 订阅 `mapper_thesis` + `thesis_proposed` | 两条流均注册 | ✅ | ✅ |
| pool 状态（BLOCKED-B 合法） | 空池 + 提示 BLOCKED-B | 0 cards / BLOCKED-B ⚠️ | ✅ 合法 |
| pytest copilot 相关 | pass | 2 passed | ✅ |

**tier-1 准出**：工程链路通，pool 空属于 `BLOCKED(d2_thesis_stream)` 合法降级，等 D2 step_05 Mapper 上真流后自然填充。

---

## 四、问题与风险

| 问题 | 应对 |
|---|---|
| 本机 PDF skip | 以 **Docker §3.10** 为门禁；CI 应 `docker build && docker run pytest` |
| 镜像体积 / 构建时 | 已用 `.dockerignore` 缩小上下文；生产 Chart 镜像可再做多阶段剥离 |

---

## 五、下一步

- [ ] [step_05_告警系统](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_05_告警系统.md)

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-17 | M2 初版 + 本机 pytest 摘要 |
| 2026-05-17 | **§3.10**：`Dockerfile`/`.dockerignore`；`docker build` + 容器 `57 passed`；L3/L4/README 同步 |
| 2026-05-25 | **W4 tier-1 复验**：`make copilot-step04-all` 退码 0；consumer 两流已订阅；pool=0 标注 `BLOCKED(d2_thesis_stream)`（14 表 W4 合法路径）；新增 §三-3 |
