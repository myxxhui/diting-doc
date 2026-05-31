# 实践记录 · step_14 · M8 行情雷达扫描与三段流水线

> [!NOTE] **[TRACEBACK]**
> - **L3**: [step_14_行情雷达扫描与三段流水线.md](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_14_行情雷达扫描与三段流水线.md)
> - **架构脊柱**: [25_四区漏斗_三段流水线_架构脊柱_设计.md](../../../03_原子目标与规约/_共享规约/25_四区漏斗_三段流水线_架构脊柱_设计.md)
> - **需求表**: [24_行情解析与规划工作台_需求实现表.md](../../../03_原子目标与规约/_共享规约/24_行情解析与规划工作台_需求实现表.md) §9.2 ⑦
> - **DNA**: `M8` · `_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml`

---

## 一、本步目标

⑦ 雷达 + 三段流水线地基：模式 C 标的深度扫描（T0→T1→T2）、`stage_artifacts`/`workspace_artifacts`/`model_profile` 落库、候选 promote 至 Campaign；启动期 `RADAR_T2_ENABLED=false`，缺上游显式 `pending`。

---

## 二、实际进展

| 项 | 代码 | 本机 | 生产 K3s (`47.243.64.137:30080`) |
|---|---|:---:|:---:|
| 地基五表 + Campaign 扩展 | ✅ | ✅ | ✅ Pod 启动 migrate |
| 模式 C T0→T1→T2 流水线 | ✅ | ✅ | ✅ scan_id=2 · 3 段 artifact |
| promote → Campaign | ✅ | ✅ | ✅ campaign_id + analysis_snapshot |
| 雷达 Tab UI + API | ✅ | ✅ | ✅ POST `/api/radar/scans` |
| `pytest test_radar.py` | ✅ 12 passed | ✅ | — |
| `make copilot-step14-tier2-verify` | — | — | ✅ |

### 生产部署链路（2026-05-30 已执行）

1. `make up-stack diting-stack` — 新 ECS `i-j6c8sz54lyng1nuzdm0q` · EIP **`47.243.64.137`**
2. K3s 由 `kubeconfig-fetch` 远程 `k3s-init.sh`（guard 6443 超时后 init 约 1min 内就绪）
3. `make platform-step03-up`（重试脚本）— platform-base + diting-stack + Timescale/PG-L2/Redis + schema-init
4. ACR 推 `diting-copilot:latest`（digest `sha256:6ba834f5…`）→ `make copilot-step14-deploy`
5. `make copilot-step14-tier2-verify` → **✅ step_12 基线 + step_14 ⑦ 雷达验收通过**

### 关键实现

- `apps/copilot/modules/radar/{scanner,context_matrix,pipeline,model_router,service}.py`
- `apps/copilot/db/migrate_step14.py` · 表 `radar_scans`/`radar_candidates`/`stage_artifacts`/`workspace_artifacts`/`model_profile`
- `scripts/copilot_step14_{scan,status,tier2_verify}.py`
- `diting-infra/Makefile` — `copilot-step14-deploy`

---

## 三、本机验证（2026-05-30）

```bash
cd diting-src
make copilot-step14-all
# → migrate OK · scan_id=1 symbol=601138 · 12 passed
# → radar_scans=1 candidates=1 stage_artifacts=3 workspace_artifacts=1
```

---

## 四、生产验证（2026-05-30 · 已核验）

```bash
export KUBECONFIG=$HOME/.kube/config-diting-prod
cd diting-infra && make copilot-step14-deploy
# → ✅ step_14 tier-2 生产验收通过（⑦ 雷达 + 三段 artifact + promote）

curl -s http://47.243.64.137:30080/health
# → HTTP 200

curl -s -X POST http://47.243.64.137:30080/api/radar/scans \
  -d 'input_type=symbol&query_text=601138'
# → scan_id=2 status=done candidate_count=1 confidence=0.55
# → market_phase/profit_quality 等多字段 pending（上游 D2/D3 未全量 · 符合 no-mock）
```

**启动期 tier-2 说明**：T2 默认关（`rule:t2_skipped`）；phase/profit 等依赖上游引擎，缺数据为 `pending`/`discard`，不以 mock 填充；tier-2 准出以 HTTP 扫描 + 3 段 artifact 落库 + promote 闭环为准。

---

## 五、修订记录

| 日期 | 说明 |
|---|---|
| 2026-05-30 | **生产 K3s ⑦ 验收通过**：EIP `47.243.64.137` · `copilot-step14-tier2-verify` ✅ · 24 表 ⑦ 行 ✅ |
