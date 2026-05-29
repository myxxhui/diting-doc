# L4 · 共享平台基础 · 启动期 · 实践记录 step_03 CPU Stack 按需 Up · platform-base + diting-stack（v2）

> **状态**：✅ tier-1 准出（smoke 19/19 · B1 已验 · **D1~D3 三轮 persist 全绿** · 见 §三-2）

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[step_03_CPU_Stack_按需Up](../../../03_原子目标与规约/共享平台基础/stages/stage_1_启动期/steps/step_03_CPU_Stack_按需Up.md)
> - **DNA**：`dna_shared_platform_baseline.yaml#steps.p_step_03`
> - **L5**：[`02_验收标准.md#l5-shared-platform-baseline-step03`](../../../05_成功标识与验证/02_验收标准.md)
> - **上游**：← [实践记录_step_02_deploy_engine扩展](./实践记录_step_02_deploy_engine扩展.md) ✅
> - **下游**：→ W4 业务 step_04（消 `BLOCKED(platform_not_ready)`）

## 一、本步骤目标

`make platform-step03-up` 起 base ECS + 装 platform-base + diting-stack @ **platform** ns + TimescaleDB/PG-L2；`make platform-step03-smoke` 验 §3.5；三轮 down/up 数据继承；D1 真采集入 K3s TimescaleDB。

## 二、实际进展（W4 · 已核验 2026-05-25）

| 项 | 状态 | 证据 |
|----|------|------|
| **make platform-step03-up** | ✅ | 同会话执行 · diting-stack @ **platform** ns |
| **make platform-step03-smoke** | ✅ | **FAIL=0**（H1~H6/P1~P4/S1~S6/D4/B2 共 19 项）|
| H4 node label=base | ✅ | `kubectl get nodes -L stack.diting/node` |
| S4 schema-init | ✅ | `job/diting-schema-init-6 Complete` |
| S5 module_a | ✅ | `diting-semantic-classifier-a` **1/1 Running** |
| S6 NodePort psql | ✅ | `47.243.248.139:30001` · `\dt` 含 ohlcv |
| **B1 D1 真采集入库** | ✅ | `SELECT count(*) FROM ohlcv` → **388322** 行 |
| **D1~D3 三轮继承** | ✅ | **2026-05-25** `ROUNDS=3 make platform-step03-test-persist` · 日志 `/tmp/persist_w4_v3.log` · 3 轮 marker 均 1×10s 命中 · `data_disk_id=d-j6ce444m0p0kf0jwxhcu` 三轮不变 |
| **A3 L5 子锚点** | ✅ | `l5-shared-platform-baseline-step03` → ✅（persist 绿后同步）|
| **会话资源策略** | ✅ | 同会话 A1→A2→A3/A4 **共享 ECS/K3s**，persist 完成前 **不** tier-1 down（见系统规则 §7.2 第 15 条）|

### 环境快照

| 键 | 值 |
|---|---|
| PUBLIC_IP | 8.217.179.252（第 3 轮 redeploy 后 · 见 `prod.conn`）|
| data_disk_id | d-j6ce444m0p0kf0jwxhcu |
| KUBECONFIG | ~/.kube/config-diting-prod |
| stack namespace | **platform** |
| NodePort L1/L2 | 30001 / 30002 |

## 三、验证命令

**工作目录**：`diting-infra`

```bash
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"   # macOS libpq
export KUBECONFIG="$HOME/.kube/config-diting-prod"

make platform-step03-up
make platform-step03-smoke          # 期望 FAIL=0
make platform-step03-test-persist ROUNDS=3   # D1~D3 · 每轮 ~20min
```

**B1 库内证据**（diting-core 连 prod.conn）：

```bash
psql "$TIMESCALE_DSN" -c "SELECT count(*) FROM ohlcv;"
# → 388322
```

**2026-05-25 smoke 摘要**：platform/train/infer ns + acr-titan ✅ · SC **titan-nas** ✅ · TimescaleDB/PG-L2/module_a Running ✅

### 三-2、W4 A2 · 三轮 persist 会话（2026-05-25 · ✅ 完成）

**根因修复**（v2 失败）：`platform-step03-deploy-stack.sh` 传绝对路径导致 `prod-write-conn.sh` 写 `PUBLIC_IP=<EIP>` → psql 超时；已修 `prod-write-conn.sh` + `_get_ip` 回退 Terraform。

```bash
cd /Users/huishaoqi/Desktop/workspace/diting-infra
ROUNDS=3 make platform-step03-test-persist
# 日志：/tmp/persist_w4_v3.log
# 终态：✅ [test-data-persistence] 3 轮全部通过
```

| 轮次 | INSERT | down-stack | redeploy | DB 连接 | SELECT marker | data_disk_id |
|------|--------|------------|----------|---------|---------------|--------------|
| 1/3 | ✅ | ✅ | ✅ | 1×10s ✅ | D1 1×10s ✅ | `d-j6ce444m0p0kf0jwxhcu` ✅ |
| 2/3 | ✅ | ✅ | ✅ | 1×10s ✅ | D2 1×10s ✅ | 不变 ✅ |
| 3/3 | ✅ | ✅ | ✅ | 1×10s ✅ | D3 1×10s ✅ | 不变 ✅ |

**资源批处理**：同会话 A1→A2→A3/A4 共享 ECS/K3s；persist 全绿前未 tier-1 down（系统规则 §7.2 第 15 条）。

## 四、DECISION_PENDING 与 SKIP_REASON

| 项 | 类型 | 说明 |
|----|------|------|
| Redis NodePort 30379 | SKIP_REASON | `deploy_control.enable_redis=false` · 启动期 D5 本机 docker 够用 |
| ingest-test 本次 akshare 断连 | SKIP_REASON | 库内已有 38 万+ ohlcv 行 · B1 以查库为准 |

## 五、准出复核

- [x] §3.5 H1~H6, P1~P4, S1~S6, D4, B1~B2（smoke + 查库）
- [x] D1~D3 三轮继承（`platform-step03-test-persist ROUNDS=3` 全绿 · `/tmp/persist_w4_v3.log`）
- [x] L5 `l5-shared-platform-baseline-step03` → ✅

## 六、修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-24 | 占位创建（v2）|
| **2026-05-25** | **W4 准出回填**：platform ns 迁移 · Makefile `platform-step03-*` · smoke 19/19 · B1 ohlcv=388322 · 三轮继承待完 |
| **2026-05-25** | **A3 收口**：L5 子锚点 step03 ⚠️；§三-2 persist 会话进度；会话资源批处理规则对齐 |
| **2026-05-25** | **A2 完成**：修复 prod.conn EIP 占位 · persist v3 三轮全绿 · L5 step03 → ✅ |
