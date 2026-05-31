# 实践记录 · step_16 · M10 规划中证伪与持续监控

> [!NOTE] **[TRACEBACK]**
> - **L3**: [step_16_规划中证伪与持续监控.md](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_16_规划中证伪与持续监控.md)
> - **架构脊柱**: [25_四区漏斗_三段流水线_架构脊柱_设计.md](../../../03_原子目标与规约/_共享规约/25_四区漏斗_三段流水线_架构脊柱_设计.md) §1.2 规划区
> - **需求表**: [24_行情解析与规划工作台_需求实现表.md](../../../03_原子目标与规约/_共享规约/24_行情解析与规划工作台_需求实现表.md) §9.2 ⑨
> - **DNA**: `M10` · `_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml`

---

## 一、本步目标

⑨ 规划区对雷达认知快照做持续证伪：4 类监控任务（moat/niche/catalyst/risk）+ verdict 引擎（缺源 pending / 被推翻 alert）+ `stage_artifacts(workspace=planning)` 证据累积 + 就绪度 advisory + 人工确认晋级执行。

---

## 二、实际进展

| 项 | 代码 | 本机 | 生产 K3s (`47.243.64.137:30080`) |
|---|---|:---:|:---:|
| `modules/planning/falsify.py` 4 类 verdict | ✅ | ✅ | ✅ |
| 认知快照 API + dossier 扩展 | ✅ | ✅ | ✅ |
| POST/GET `/api/campaigns/{id}/falsify` | ✅ | ✅ | ✅ |
| GET `/readiness` · POST `/promote-executing`（人工闸） | ✅ | ✅ | ✅ 无 confirm→400 |
| 规划 Tab 证伪面板 UI | ✅ | ✅ | ✅ |
| `pytest test_falsify.py` | ✅ 16 passed | ✅ | — |
| `make copilot-step16-tier2-verify` | — | — | ✅ |

### 生产部署（2026-05-31）

1. 复用 ECS `47.243.64.137` · K3s platform 栈
2. `make copilot-step16-deploy` → ACR digest `sha256:32236222…` → rollout
3. tier-2：step_12/14/15 基线 + step_16 4 类证伪 + readiness + human_confirmation 闸 ✅

### 关键实现

- `apps/copilot/modules/planning/falsify.py` · `monitor.refresh_verdicts` 分流 4 类证伪
- `apps/copilot/modules/planning/service.promote_campaign_to_executing`
- `scripts/copilot_step16_{falsify,status,tier2_verify}.py`
- 雷达 promote / 持仓导入时 `ensure_default_falsify_tasks`

---

## 三、本机验证（2026-05-31）

```bash
cd diting-src && make copilot-step16-all
# → 16 passed · falsify_subscriptions=4 · planning_artifacts≥1
```

---

## 四、生产验证（2026-05-31 · 已核验）

```bash
cd diting-infra && make copilot-step16-deploy
# → ✅ step_16 tier-2（⑨ 证伪 + 就绪度 + 人工确认闸）
```

---

## 五、修订记录

| 日期 | 说明 |
|---|---|
| 2026-05-31 | 本机 + 生产 K3s ⑨ 验收通过 · 24 表 ⑨ 行 ✅ |
