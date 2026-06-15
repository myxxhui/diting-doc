# 31 · Spot 计费感知与巡检规约（ECS Spot Guard · Phase 1）

> **适用**：`diting-infra` · `make deploy diting prod` 双环境（新加坡 proxy + 香港 base）  
> **Phase**：1（仅 diting-infra 脚本 + generated tfvars，不改 deploy-engine 子模块）  
> **配置真相源**：[`diting-infra/config/spot-billing-prefs.yaml`](../../../diting-infra/config/spot-billing-prefs.yaml)

> [!NOTE] **[TRACEBACK] 战略追溯锚点**
> - **战略维度**：[共享平台基础](../../共享平台基础/README.md) · P 轨随用随起
> - **拓扑**：[01_平台拓扑设计 §5](../../共享平台基础/stages/stage_1_启动期/01_平台拓扑设计.md)
> - **DNA**：[`dna_shared_platform_baseline.yaml`](../../_System_DNA/shared/dna_shared_platform_baseline.yaml) · `cost_estimate_cny_per_month`
> - **L4 实践**：`diting-infra` Makefile · Spot Guard 目标

---

## §1 目标

| # | 目标 |
|---|------|
| 1 | **启动时**探测 Spot 库存，有货优先竞价，无货 fallback 按量 |
| 2 | **日常巡检**发现意外释放 / Spot 抢占 / 按量时 Spot 机会 |
| 3 | **切换须交互确认**（`require_confirm_on_switch: true`），cron 只写报告 |
| 4 | 一键 Make 切换计费或抢占后按量恢复 |

---

## §2 配置

### 2.1 `config/spot-billing-prefs.yaml`

| 键 | 说明 |
|----|------|
| `policy.default` | `spot_first`（base/proxy 均允许） |
| `policy.watch_interval_minutes` | **15**（cron 建议间隔） |
| `policy.require_confirm_on_switch` | **true**（必须 `INTERACTIVE=1`） |
| `stacks.proxy` | 新加坡 `ecs.e-c1m2.large` · `SpotAsPriceGo` · limit 0.08 |
| `stacks.base` | 香港 `ecs.u1-c1m4.large` · `SpotAsPriceGo` · limit 0.6 |

### 2.2 本地运行态（`.gitignore`）

| 文件 | 用途 |
|------|------|
| `config/.spot-billing-state.json` | **运行意图** + billing + 云上 ECS/EIP 快照 |
| `config/.spot-watch-last-report.json` | 最近一次巡检结论 |
| `config/.generated/` | 合并后的 tfvars |
| `config/.spot-active/` | deploy-engine 使用的活跃 CONFIG_ROOT |

### 2.3 运行意图（`operational_intent` · 预期 Up/Down）

**问题**：集群不是 7×24 运行；主动 `make down` 与 Spot 抢占都会让 ECS 消失，巡检须区分「预期关闭」与「非预期释放」。

**真相源**：`config/.spot-billing-state.json`（每 stack 一条，与 billing 同文件）

| 字段 | 说明 |
|------|------|
| `operational_intent` | `running` = 预期集群在跑 · `stopped` = 预期已关闭 |
| `intent_updated_at` / `intent_reason` | 最后一次意图变更 |
| `last_up_at` | `make deploy diting prod` 成功收尾时写入 |
| `last_down_at` / `last_down_reason` | `make down diting prod` 时写入（如 `user_intentional`） |
| `instance_id` / `eip_address` / `eip_allocation_id` | deploy 后从阿里云刷新快照 |

**自动维护**（无需手改 JSON）：

| 动作 | 脚本 |
|------|------|
| `make deploy diting prod` 成功 | `spot-intent-mark.sh up` → `running` + 刷新云快照 |
| `make down diting prod` 成功 | `spot-intent-mark.sh down` → `stopped` |
| 手动 | `make spot-intent-mark OP=status` |

**巡检判定矩阵**（本地 `cluster-spot-watch.sh` · 每 15 分钟 · **单一脚本**含 Spot 机会 + 意外释放）：

| 预期意图 | ECS | EIP | 行为 |
|----------|-----|-----|------|
| `stopped` | 无 | 无 | **不发告警**（主动关闭） |
| `stopped` | 无 | **有** | **`EIP_LINGERING` 邮件**（orphan EIP · 可能持续计费） |
| `running` | 有 | 有 | 正常；按量时检测 `SPOT_OPPORTUNITY` |
| `running` | **无** | **有** | **非预期释放 / 抢占** → 邮件告警 |
| `running` | 无 | 无 | **非预期**（预期 Up 但资源全没）→ 告警 |

`unknown`（旧 state 无 intent）：仅当 Terraform state 仍有 stack 时视为预期 Up（兼容迁移）。

---

## §3 Make 命令

| 命令 | 用途 |
|------|------|
| `make deploy diting prod` | 内嵌 `spot-prefer-on-deploy`（可用 `SKIP_SPOT_PREFER=1` 跳过） |
| `make spot-prefer-on-deploy` | 单独跑启动探测 |
| `make cluster-spot-watch CRON=1` | 定时巡检（**不交互** · **发邮件至 126 收件箱**） |
| `make cluster-spot-watch INTERACTIVE=1` | 交互巡检（可确认切换） |
| `make spot-billing-status` | 运行意图 + 计费 + 最近报告 |
| `make spot-intent-mark OP=status` | 仅查看 running/stopped |
| `make switch-stack-billing STACK=proxy\|base BILLING=spot\|ondemand INTERACTIVE=1` | 单 stack 切换 |
| `make redeploy-prod-ondemand-fallback` | 抢占恢复：强制按量 + 全量 deploy |
| `make redeploy-prod-spot-prefer` | 强制 Spot 优先 + 全量 deploy |

### 3.1 本机 crontab（15 分钟 · **唯一主路径**）

**一个脚本** `cluster-spot-watch.sh` 同时负责：① 预期 vs 实际（ECS/EIP）② 按量时 Spot 机会 ③ 126 邮件。

```cron
*/15 * * * * cd /path/to/diting-infra && make cluster-spot-watch CRON=1 >> logs/spot-watch.log 2>&1
```

竞价实例被抢占 → 整集群可能瞬间不可用 → **必须本机 cron**（集群内 CronJob 此时无法执行）。

### 3.2 集群内 CronJob（可选 · 默认 **关闭**）

`stack.spotGuardCron.enabled: false`。若将来仅需「集群 Up 时补充 Spot 机会检测」可改为 `true`；**不能替代**本机 cron。

| 场景 | 本机 `cluster-spot-watch` | 集群 CronJob |
|------|---------------------------|--------------|
| 预期 running · 抢占/EIP  orphaned | ✅ 告警 | 集群已垮 · ❌ |
| 预期 stopped · ECS/EIP 均无 | ✅ 静默 | ✅ 静默 |
| 按量 · Spot 有货 | ✅ | ✅（集群 Up 时） |

交互切换须人工：

```bash
make cluster-spot-watch INTERACTIVE=1
```

### 3.3 邮件报告（126 SMTP）

| 项 | 值 |
|----|-----|
| SMTP | 与 Copilot 告警同源 · `diting-src/.env` → `COPILOT_SMTP_*` |
| 发件 | `huishaoqi@126.com`（`COPILOT_SMTP_FROM`） |
| 收件 | `config/spot-billing-prefs.yaml` → `watch_email.to`（默认 **huishaoqi@126.com**） |
| 触发 | **`CRON=1`** 时自动发信；`HEALTHY` 也发（确认 cron 存活） |
| 手动测 | `make cluster-spot-watch CRON=1` 或 `SPOT_WATCH_EMAIL=1 make cluster-spot-watch` |

---

## §4 巡检结论码

| 结论 | 含义 | 建议动作 |
|------|------|----------|
| `HEALTHY` | 预期与云状态一致（含预期 stopped 不发告警） | 无 |
| `PREEMPTED_LIKELY` | 应在线但无实例，且上次 Spot、Spot 仍无货 | `make redeploy-prod-ondemand-fallback` |
| `UNEXPECTED_RELEASE` | 应在线但无实例（非抢占典型） | `make deploy diting prod` |
| `SPOT_OPPORTUNITY` | 当前按量且 Spot 有货 | `make switch-stack-billing ... INTERACTIVE=1` |
| `EIP_LINGERING` | 预期已 down · ECS 无 · **EIP 仍挂着** | 控制台释放 EIP 或复核 down |

---

## §5 脚本清单

| 脚本 | 职责 |
|------|------|
| `scripts/lib/spot-billing-lib.sh` | 库存探测、tfvars 合并、state JSON |
| `scripts/spot-prefer-on-deploy.sh` | 启动链入口 |
| `scripts/cluster-spot-watch.sh` | **本地唯一巡检**（意图 vs ECS/EIP · Spot 机会 · 邮件） |
| `scripts/spot-intent-mark.sh` | deploy/down 时写 running/stopped |
| `scripts/spot-watch-send-email.py` | 本机 CRON 邮件报告（126 SMTP） |
| `scripts/spot-guard-sync-k8s-secret.sh` | 同步 `diting-spot-guard` Secret（AK/SK + 代理密码） |
| `diting-src/apps/copilot/jobs/spot_guard_watch.py` | **集群内** CronJob 巡检 + 发信 |
| `scripts/spot-switch-stack-billing.sh` | 单 stack 切换 |

GPU 训练 Spot 重试仍用 [`retry-up-stack-training.sh`](../../../diting-infra/scripts/retry-up-stack-training.sh)（独立流程）。

---

## §6 风险

- **Spot 回收**：香港 base 跑 K3s+DB，回收后须 `redeploy-prod-ondemand-fallback` 或 `deploy diting prod`。
- **切换 = 新 ECS**：EIP 可能变更；proxy 自动 `sync-anthropic-proxy-to-copilot`。
- **Phase 2（可选）**：deploy-engine 独立仓库支持 `-var-file` overlay，减少 tfvars 全量 merge。

---

## 修订记录

| 日期 | 说明 |
|------|------|
| 2026-06-12 | Phase 1 落地：spot_first · cron 15min · 必须 INTERACTIVE 切换 |
| 2026-06-12 | CRON 邮件报告 · 126 收件 · `spot-watch-send-email.py` |
| 2026-06-12 | **K3s CronJob** 集群内 15min 巡检 · `spot_guard_watch.py` · 本机 cron 作全灭兜底 |
| 2026-06-12 | **运行意图** `operational_intent` · 单一本机 cron · 区分主动 down 与意外释放 |
