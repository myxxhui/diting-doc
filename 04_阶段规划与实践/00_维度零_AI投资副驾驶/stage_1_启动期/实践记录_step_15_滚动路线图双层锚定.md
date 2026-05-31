# 实践记录 · step_15 · M9 滚动路线图双层锚定

> [!NOTE] **[TRACEBACK]**
> - **L3**: [step_15_滚动路线图双层锚定.md](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_15_滚动路线图双层锚定.md)
> - **架构脊柱**: [25_四区漏斗_三段流水线_架构脊柱_设计.md](../../../03_原子目标与规约/_共享规约/25_四区漏斗_三段流水线_架构脊柱_设计.md)
> - **需求表**: [24_行情解析与规划工作台_需求实现表.md](../../../03_原子目标与规约/_共享规约/24_行情解析与规划工作台_需求实现表.md) §9.2 ⑧
> - **DNA**: `M9` · `_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml`

---

## 一、本步目标

⑧ 滚动路线图双层锚定：维度一 T0 时间线编排 + 4 类合理性 flag；维度二 lifecycle 代理判定（全 `inferred`）+ long/mid 自动 regime 巡检；归档滚动闭环。

---

## 二、实际进展

| 项 | 代码 | 本机 | 生产 K3s (`47.243.64.137:30080`) |
|---|---|:---:|:---:|
| timeline 扩展列 + regime_assessments | ✅ | ✅ | ✅ Pod migrate |
| T0 合理性 4 flag 引擎 | ✅ | ✅ | ✅ window_overlap |
| POST/GET `/api/campaigns/{id}/timeline` | ✅ | ✅ | ✅ |
| regime assess + regime 巡检订阅 | ✅ | ✅ | ✅ confirm=inferred |
| 归档滚动 `POST .../archive` | ✅ | ✅ | — |
| 路线图 Tab UI | ✅ | ✅ | ✅ |
| `pytest test_roadmap.py` | ✅ 11 passed | ✅ | — |
| `make copilot-step15-tier2-verify` | — | — | ✅ |

### 生产部署（2026-05-31）

1. 复用 ECS `47.243.64.137` · K3s platform 栈
2. `make copilot-step15-deploy` → ACR digest `sha256:dfb5ab2e…` → rollout
3. tier-2：step_12/14 基线 + step_15 时间线重叠 flag + regime inferred ✅

### 关键实现

- `apps/copilot/modules/roadmap/{feasibility,regime,service,calendar}.py`
- `regime_assessments` 表 · `campaign_timeline` 扩展 · `monitor_subscriptions.falsify_type`
- `scripts/copilot_step15_{timeline,regime,status,tier2_verify}.py`

---

## 三、本机验证（2026-05-31）

```bash
cd diting-src && make copilot-step15-all
# → 11 passed · flag_distribution window_overlap/capital_collision
```

---

## 四、生产验证（2026-05-31 · 已核验）

```bash
cd diting-infra && make copilot-step15-deploy
# → ✅ step_15 tier-2（⑧ 时间线 + 合理性 + regime inferred）
```

---

## 五、修订记录

| 日期 | 说明 |
|---|---|
| 2026-05-31 | 本机 + 生产 K3s ⑧ 验收通过 · 24 表 ⑧ 行 ✅ |
