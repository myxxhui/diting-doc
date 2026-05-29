# P-step_07 · 阶段验收 · 平台快照与生命周期对账（v2）

> **本步定位**：启动期 P 轨**收口必经** step。一键导出**平台快照 MD**到 06_/03_/审计 · 完成 L5 主表 + 7 step 子锚点全 ✅ · 7 L4 实践记录回填 · 月度成本对账 · 中央索引表加 P 轨 7 行 · 可选 DR 演练。**v2 修订**：4 chart × 3 stack 矩阵快照 + 永驻 10 项资源对账 + 三档释放命令历史。

> [!NOTE] **[TRACEBACK]**
> - **P 轨入口**：[README](../../../README.md)
> - **前置 step**：[step_01](./step_01_现状盘点与凭证复用.md) + [02_设计](../02_deploy-engine扩展规约.md) + [step_03](./step_03_CPU_Stack_按需Up.md) + [step_04](./step_04_GPU训练组按需Up.md) + [step_05](./step_05_GPU推理组按需Up.md) + [step_06](./step_06_Stack_Down与三档释放纪律.md) 全部 ✅
> - **DNA**：[`shared/dna_shared_platform_baseline.yaml#steps[p_step_07]`](../../../../_System_DNA/shared/dna_shared_platform_baseline.yaml)
> - **L5**：[02_验收标准 #l5-shared-platform-baseline](../../../../../05_成功标识与验证/02_验收标准.md)
> - **L4**：[实践记录_step_07_阶段验收](../../../../../04_阶段规划与实践/共享平台基础/stage_1_启动期/实践记录_step_07_阶段验收.md)

---

## §1 本步目标

<a id="l4-p-step_07-goal"></a>

| # | 目标 |
|---|------|
| 1 | 一键导出**平台快照 MD** 到 `diting-doc/06_追溯与审计/03_审计与一致性报告/平台快照_启动期_YYYYMMDD.md` |
| 2 | 4 chart 版本 + helm release 状态全 ✅ |
| 3 | 3 stack ECS 起停历史 + 月度成本对账（实际 vs 预算 ¥140-310）|
| 4 | 永驻 10 项资源现状对账（与 P-step_01 现状一致 · 验证任何 down 不动）|
| 5 | L5 主表 + 7 step 子锚点全 ✅ |
| 6 | 7 L4 实践记录回填完成 |
| 7 | 中央索引表加入 P 轨 7 行 |
| 8 | 「下次 Up 闭环」DR 演练（可选 · 模拟 make down-all 后从 P-step_01 重建）|

---

## §2 前置条件

| # | 前置 | 检查 |
|---|------|------|
| 1 | P-step_01~06 全部 ✅ | 7 L4 实践记录已生成 |
| 2 | 至少跑过一次完整链路（up-stack diting-stack → up-stack diting-training → up-stack diting-vllm → down 全部）| L4 含 cost-snapshot |
| 3 | 月度成本累计可拉取（阿里云费用账单 API 或控制台导出）| `aliyun bss QueryAccountBalance` |

---

## §3 工作目录

```bash
cd /Users/<user>/Desktop/workspace/diting-infra
```

---

## §3.5 数据质量验收矩阵（快照 + 对账）

| # | 检查项 | 验证方式 | 启动期标准 |
|---|--------|---------|-----------|
| **平台快照 MD** | | | |
| F1 | 快照 MD 已生成 | `ls diting-doc/06_追溯与审计/03_审计与一致性报告/平台快照_启动期_*.md` | ≥1 文件 ✅ |
| F2 | 快照含 4 chart 版本表 | `grep -E '(diting-platform-base|diting-stack|diting-training|diting-vllm)' <快照>` | 4 行 ✅ |
| F3 | 快照含 3 stack 起停历史 | `grep -E '(base|train|infer)' <快照>` | ≥3 行 ✅ |
| F4 | 快照含永驻 10 项现状对账 | grep 🟢 行 | ≥10 行 ✅ |
| F5 | 快照含月度成本对账 | grep `成本对账` 或 `actual_cny` | ✅ |
| F6 | 快照含三档释放命令历史 | grep `(down-stack|down-platform-base|down-all)` | ✅ |
| **L5 一致性** | | | |
| L1 | L5 主表 `l5-shared-platform-baseline` 状态 ✅ | `grep -A 1 'l5-shared-platform-baseline\b' diting-doc/05_成功标识与验证/02_验收标准.md` | 状态 ✅ |
| L2 | L5 7 step 子锚点全 ✅ | `for n in 01 02 03 04 05 06 07; do grep "l5-shared-platform-baseline-step$n" .../02_验收标准.md; done` | 7 行全 ✅ |
| **L4 实践记录** | | | |
| L4-1 | 7 L4 实践记录文件存在 | `ls 04_阶段规划与实践/共享平台基础/stage_1_启动期/实践记录_step_*.md` | 7 文件 ✅ |
| L4-2 | 每份 L4 实践记录含「二、实际进展」「准出验证」段 | grep '二、实际进展' + '准出验证' | 14 命中 ✅ |
| **中央索引表** | | | |
| I1 | 03_README 的 P 轨索引表 7 行 | `grep -A 10 'P 轨' 03_原子目标与规约/README.md` | 含 7 step 行 ✅ |
| I2 | 06_/02_战略追溯矩阵 加 P 轨行 | grep 同上 | ✅ |
| **永驻资源对账** | | | |
| P1 | VPC ID 与 P-step_01 现状一致 | `terraform output vpc_id` | `vpc-j6cuhmska9vfwqa6my16q` ✅ |
| P2 | NAS ID 与现状一致 | `terraform output nas_id` | `12db2e48f90` ✅ |
| P3 | 独立数据盘 ID 与现状一致 | `terraform output data_disk_id` | `d-j6cc6ew2bqkfdlwaavit` ✅ |
| P4 | 安全组 ID 与现状一致 | `terraform output security_group_id` | `sg-j6cizfabvego0nem81c2` ✅ |
| P5 | OSS bucket 与现状一致 | `terraform output oss_bucket_name` | `deploy-engine-k3s-storage` ✅ |
| **成本对账** | | | |
| C1 | 月度实际成本 ≤ 预算 130% | 阿里云账单 API or 手工 | 实际 ≤ ¥310 × 1.3 = ¥403 ✅ |
| C2 | 各 stack 跑时统计 | base 跑时 + train 跑时 + infer 跑时 | ✅ |
| **DR 演练（可选）** | | | |
| D1 | DR 演练完成（make down-all → 从 P-step_01 重建 → 数据恢复）| 演练日志 | ⚠️ 可选 |

---

## §6 下一步

→ 启动期收口 · 进入扩展期 stage_2 第一步：`../../stages/stage_2_扩展期/`（启动期不展开）
→ 触发条件见 DNA `stage_2_trigger`

---

## §7 实施步骤（设计规划推演）

### 7.1 实现要点

| 实现要点 | 涉及位置 | 关键设计决策 | 验证标准 |
|---------|---------|-------------|---------|
| 平台快照模板 | `diting-infra/scripts/templates/platform_snapshot.md.jinja` | 4 chart × 3 stack × 永驻 10 项 × 成本对账 | F1~F6 ✅ |
| 快照生成脚本 | `diting-infra/scripts/generate_platform_snapshot.py` | 读 terraform output + helm list + 阿里云 API + L4 记录 → 渲染 jinja | F1~F6 ✅ |
| L5 状态更新 | `diting-doc/05_成功标识与验证/02_验收标准.md` | 7 step 子锚点状态列 ❌→✅ | L1~L2 ✅ |
| L4 实践记录补全 | `04_/共享平台基础/stage_1_启动期/实践记录_step_*.md` | 含「二、实际进展」「准出验证」 | L4-1~L4-2 ✅ |
| 中央索引表更新 | `diting-doc/03_原子目标与规约/README.md` + `06_/02_战略追溯矩阵.md` | 加 P 轨 7 行 | I1~I2 ✅ |
| 成本对账 | `diting-infra/scripts/cost_reconcile.py` | 阿里云 bss API or 控制台导出 csv | C1~C2 ✅ |

### 7.2 Makefile 合约（diting-infra）

| target | 行为 |
|--------|------|
| `make platform-snapshot` | 一键生成快照 MD（含 helm list + terraform output + 阿里云账单 + L4 累计 cost-snapshot）|
| `make platform-cost-reconcile MONTH=YYYY-MM` | 月度成本对账输出 |
| `make platform-step07-status` | 列出 §3.5 全部 F/L/I/P/C 项状态 |
| `make platform-dr-drill`（可选）| DR 演练 · 从 down-all 状态重建（极少跑）|

### 7.3 给后续执行模型的指引

- **必须**先做 P-step_01~06 全部 ✅ 才能跑本步；
- 快照 MD 文件名 `平台快照_启动期_YYYYMMDD.md` 用当天日期；
- 永驻资源对账若有任何 ID 不匹配 P-step_01：**警报**（说明 P-step_06 三档释放纪律可能被破坏 · 立即查原因）；
- 成本对账超 130%：分析超支项（GPU 跑太久？base 24/7？）· 调整 stack runtime_lifecycle；
- L4 实践记录补全可参考 `.cursorrules` §8.4g（默认表达已核验准出）；
- DR 演练**可选**（启动期通常 SKIP · 完善期前必跑一次）。

---

## §8 本步在哪里跑

| 操作 | 位置 |
|------|------|
| make platform-snapshot / cost-reconcile / status | `diting-infra/`（本地）|
| 快照 MD 落 | `diting-doc/06_追溯与审计/03_审计与一致性报告/`（本仓）|
| L5 状态更新 | `diting-doc/05_成功标识与验证/02_验收标准.md`（本仓）|

---

## §9 准出（Exit Criteria）

- [ ] §3.5 F1~F6 全 ✅（平台快照 MD 完整）
- [ ] §3.5 L1~L2 全 ✅（L5 8 锚点）
- [ ] §3.5 L4-1~L4-2 全 ✅（7 L4 实践记录）
- [ ] §3.5 I1~I2 全 ✅（中央索引表）
- [ ] §3.5 P1~P5 全 ✅（永驻 10 项对账）
- [ ] §3.5 C1~C2 全 ✅（成本对账）
- [ ] §3.5 D1 ⚠️ 可选

---

## §10 [Deploy] 部署节奏

| 阶段 | 部署内容 | 触发 |
|------|---------|------|
| 启动期收口 | 一次性跑 platform-snapshot + L5 更新 + 中央索引 + L4 回填 | P-step_01~06 全 ✅ |
| 后续每 Sprint | 增量更新快照（每月一次 cost-reconcile）| 持续 |

---

## §11 依赖

- P-step_01~06 全 ✅
- L5 02_验收标准.md 已有 `l5-shared-platform-baseline-step*` 8 锚点（在前序重构时已加）
- 04_/共享平台基础/stage_1_启动期/ 实践记录目录已建

---

## §12 风险与降级

| 风险 | 概率 | 影响 | 降级 |
|------|------|------|------|
| 阿里云账单 API 拉不到 | 低 | 中 | 控制台导出 csv 手工对账 |
| 永驻 ID 与 P-step_01 现状不一致 | 低 | 高（说明 down 纪律被破坏）| 立即查 terraform plan/state · 找谁破坏的 |
| 成本超支 200%+ | 中 | 中 | 立即停 GPU stack + 调整 spot_price_limit |
| DR 演练失败（重建后数据不通）| 中 | 高 | 启动期不强制 DR · 完善期前必演练 |

---

## §13 修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-24 v1 | 阶段验收 · 平台快照初版（CPU 24/7 假设）|
| **2026-05-24 v2** | **重写**：①快照模板加 4 chart × 3 stack × 永驻 10 项②命令统一用 chart 名③加成本对账 ¥140-310 月预算④加永驻资源对账（P-step_01 一致性验证）⑤加 §3.5 F/L/I/P/C/D 18 项矩阵 |
