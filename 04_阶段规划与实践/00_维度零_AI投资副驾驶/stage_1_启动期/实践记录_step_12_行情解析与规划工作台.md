# 实践记录 · step_12 · M6 行情解析与规划工作台

> [!NOTE] **[TRACEBACK]**
> - **L3**: [step_12_行情解析与规划工作台.md](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_12_行情解析与规划工作台.md)
> - **需求表**: [24_行情解析与规划工作台_需求实现表.md](../../../03_原子目标与规约/_共享规约/24_行情解析与规划工作台_需求实现表.md)
> - **DNA**: `M6` · `_System_DNA/00_co_pilot/dna_stage_1_启动期.yaml`

---

## 一、本步目标

必做 ①~④：4+1 导航 → Campaign 6 表 + 持仓入规划 → 6 维分析档案 → 三支柱监控；**Redis 未就绪则阻塞等待**（不降级跳过）。

---

## 二、实际进展

| 项 | 代码 | 本机 | 生产 K3s (`8.218.24.12:30080`) |
|---|---|:---:|:---:|
| ① UI 骨架 4+1 + `/planning` | ✅ | ✅ | ✅ |
| ② 6 表 + SoT→`campaign_symbols` | ✅ | ✅ | ✅ Pod bootstrap 导入 `601138` |
| ③ `dossier.py` 6 区块 API | ✅ | ✅ | ✅ 缺上游显式 `pending` |
| ④ 三支柱 `monitor_subscriptions` | ✅ | ✅ | ✅ 三支柱 API 齐 |
| `pytest test_planning.py` | ✅ 18 passed | ✅ | — |
| `make copilot-step12-tier2-verify` | — | — | ✅ |

### 生产部署链路（2026-05-29 已执行）

1. `make up-stack diting-stack` — 新 ECS `i-j6cax1jh34156ozk7so1` · EIP `8.218.24.12`（旧 `8.217.158.218` 已回收）
2. K3s 由 `kubeconfig-fetch` 远程触发 `k3s-init.sh`（guard 600s 内 6443 未就绪属正常，安装约 15min 内完成）
3. `make platform-step03-up` — platform-base + diting-stack + Timescale/PG-L2/Redis
4. ACR 推 `diting-copilot:latest`（digest `sha256:17c5c578…`）→ `kubectl rollout restart`
5. `make copilot-step12-tier2-verify` → **✅ tier-2 生产验收通过（①~④ HTTP）**

### 关键实现

- `apps/copilot/modules/planning/{service,dossier,monitor,schema}.py`
- `apps/copilot/services/redis_wait.py` — `wait_for_sync_redis()` 最长 120s（K8s bootstrap 180s）
- `scripts/copilot_k8s_bootstrap.py` — holdings + **等待 Redis** + Campaign 导入
- `diting-infra/Makefile` — `copilot-step12-deploy`

---

## 三、本机验证（2026-05-29）

```bash
cd diting-src
make copilot-step12-all
# → 18 passed · campaign_symbols=4（my_holdings.yaml portfolio）
```

---

## 四、生产验证（2026-05-29 · 已核验）

```bash
export KUBECONFIG=$HOME/.kube/config-diting-prod
cd diting-src && make copilot-step12-tier2-verify
# → ✅ tier-2 生产验收通过（①~④ HTTP）

curl -s http://8.218.24.12:30080/api/campaigns | jq '.[0].symbols[0].symbol'
# → "601138"

kubectl logs -n platform deploy/diting-copilot | grep -E 'Redis 就绪|Campaign 导入'
# → Redis 就绪 · campaign_id=1 · imported_count=1
```

**启动期 tier-2 说明**：档案 ②~⑤ 多数字段为 `pending`（D2/D3 上游未全量部署），符合 no-mock 规约；tier-2 准出以 HTTP 骨架 + 三支柱 API 齐 + bootstrap 导入为准。

---

## 五、修订记录

| 日期 | 说明 |
|---|---|
| 2026-05-29 | **生产 K3s ①~④ 验收通过**：新 EIP `8.218.24.12` · `copilot-step12-tier2-verify` ✅ |
| 2026-05-29 | 首版：本机 ①~④ 完成；生产列 ⏳；L4 与 24 表状态同步 |
