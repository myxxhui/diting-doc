# 实践记录 · 维度二·纵深进攻 · 启动期 · step_04 · 利润截留扫描仪

> [!NOTE] **[TRACEBACK] 实践锚点**
> - **L3 step**: [step_04_利润截留扫描仪剧本.md](../../../03_原子目标与规约/02_维度二_纵深进攻/stages/stage_1_启动期/steps/step_04_利润截留扫描仪剧本.md)
> - **本阶段看板**: [README.md](./README.md)

---

## 一、实际进展（W4 tier-1 · 已核验 2026-05-25）

| L3 准出项 | 状态 | 说明 |
|---|---|---|
| **`make deep-step04-all`** | ✅ | 同会话复验退码 0 |
| scan-all | ✅ | 10 active · propose=0 watch=0 discard=10（tier-1 合法）|
| mapper-run | ✅ | total_events=0（无 critic-pass cluster · tier-1 合法）|
| quality-check | ✅ | Q1~Q4 绿 · Q5/Q6 ⚠️ 启动期可接受 |
| pytest | ✅ | **21 passed**（profit_capture + the_mapper）|
| `HoldingsSoT` import 修复 | ✅ | 改用 `load_holdings_sot()` |
| `profit_capture/signals/*` ×5 | ✅ | DNA 权重与条件一致 |
| `profit_capture/state.py` + `nodes.py` | ✅ | 异步 load / evidence；同步 score / classify |
| `profit_capture/playbook.py` | ✅ | LangGraph `StateGraph` + `set_entry_point` |
| `playbooks/registry.py` | ✅ | `profit_capture` 懒注册 |
| `api/routes.py` | ✅ | scan / batch-scan；替换 step_01 scaffold |
| `data/ingest.py` `run(..., mock=)` | ✅ | 测试与 CLI 显式 mock |
| `akshare_source` mock 最新季 | ✅ | i=7 行对齐 5 信号全命中（读库最新 `period_end`） |
| `tests/deep_strike/test_profit_capture.py` | ✅ | **11 passed** |
| `tests/deep_strike/test_health.py` | ✅ | 扫描路由改为断言三档决策 |
| commit / push | ⚠️ | 未执行 |

## 二、验证（W4 · 一键合约）

**工作目录**：`diting-src`

```bash
cd diting-src && make deep-step04-all
```

**2026-05-25 摘要**：scan_logs 63 条 · physical evidence 10 条 · mapper 0 行（无 physical_gate 簇 · 14 表「不算 tier-2 欠项」）

**BLOCKED**：无 tier-1 阻塞；tier-2「Mapper ≥1 事件」未达 · 可接受

## 三、说明

- 节点未使用 `loguru`（仓库未声明依赖），与 `EvidenceChainBuilder` 一致用标准库 `logging`（playbook 内）。
- `decision=propose` 仅表示进入推荐池，建仓须 step_08 人工确认（L3 永久规则）。

## 四、下一步

- step_05 及 P0 剧本扩展（见 L3）。

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-17 | 初稿：LangGraph profit_capture + mock 尾季 + 全量 deep_strike pytest |
| 2026-05-25 | **W4 tier-1**：`deep-step04-all` 绿 + holdings_sot 修复 + L4 回填 |
