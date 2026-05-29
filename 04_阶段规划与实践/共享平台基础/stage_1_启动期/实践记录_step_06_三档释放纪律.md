# L4 · 共享平台基础 · 启动期 · 实践记录 step_06 Stack Down 与三档释放纪律（v2 · 核心）

> **状态**：⚠️ tier-1 准出（diting-stack 三档 ×3 + tier-3 安全闸 ✅；train/infer/tier-2/G/C 启动期 SKIP · 见 §三-2）

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[step_06_Stack_Down与三档释放纪律](../../../03_原子目标与规约/共享平台基础/stages/stage_1_启动期/steps/step_06_Stack_Down与三档释放纪律.md)
> - **DNA**：`dna_shared_platform_baseline.yaml#steps.p_step_06` + `lifecycle_tiers`
> - **L5**：[`02_验收标准.md#l5-shared-platform-baseline-step06`](../../../05_成功标识与验证/02_验收标准.md)
> - **上游**：P-step_03 persist 全绿（同会话复用 down-stack 证据）
> - **下游**：→ [实践记录_step_07_阶段验收](./实践记录_step_07_阶段验收.md)

## 一、本步骤目标

按 L3 设计完成三档释放纪律：①命令统一用 chart 名（`make down-stack <chart-name>`）；②**永驻 10 项任何 down 都不动**；③tier-3 FULL_DESTROY 二次确认（输入 `DESTROY-DATA`）；④Down 前 graceful；⑤Spot 抢占 2min 监听；⑥每次 Down 后 cost-snapshot 入本记录。

## 二、实际进展（W4 · 已核验 2026-05-25）

| tier | 命令 | 状态 | 验证 |
|------|------|------|------|
| **tier-1 · diting-stack** | `make down-stack diting-stack` | ✅ | persist ROUNDS=3 每轮 down 退码 0 · 日志 `/tmp/persist_w4_v3.log` |
| **tier-1 · 永驻反向验证** | terraform output / state list | ✅ | 3 轮后 `data_disk_id=d-j6ce444m0p0kf0jwxhcu` 不变 · VPC/SG/NAS/OSS 全在（§三-2 表）|
| **tier-1 · diting-training** | `make down-stack diting-training` | ⏭ SKIP | 启动期未部署 train stack · state 无 `stack["train"]` |
| **tier-1 · diting-vllm** | `make down-stack diting-vllm` | ⏭ SKIP | 启动期未部署 infer stack |
| **tier-2 platform-base down** | `make down-platform-base` | ⏭ SKIP | 同会话集群仍供 W4 消费 · tier-2 留 step_07/暂离时验 |
| **tier-3 无 FULL_DESTROY 拒绝** | `make down-all` | ✅ | 退码 1 · 提示需 `FULL_DESTROY=1` |
| **tier-3 输错确认拒绝** | `echo yes \| FULL_DESTROY=1 make down-all` | ✅ | 输出「已取消」· 退码 1 · 永驻资源未动 |
| **tier-3 正确确认（DR）** | `echo DESTROY-DATA \| make down-all FULL_DESTROY=1` | ⏭ SKIP | 启动期禁止真销 |
| **graceful G1~G3** | `platform-step06-*` | ⏭ SKIP | Makefile 尚无对应 target · pre-delete hook / Spot daemon 待 L4 补实现 |
| **cost-snapshot C1** | `platform-step06-cost-snapshot` | ⏭ SKIP | 脚本未落地 · persist 3 轮 ECS 按需约 ¥0.6/h × ~45min ≈ ¥0.5（估算）|

### 永驻 10 项 ID 对账（与 P-step_01 现状 · down 后仍一致）

| 资源 | P-step_01 基线 | 2026-05-25 down×3 后 | 一致 |
|------|----------------|----------------------|------|
| VPC | vpc-j6cuhmska9vfwqa6my16q | vpc-j6cuhmska9vfwqa6my16q | ✅ |
| VSwitch | vsw-j6ct3ymab1lxeqz38lbwi | vsw-j6ct3ymab1lxeqz38lbwi | ✅ |
| 安全组 | sg-j6cizfabvego0nem81c2 | sg-j6cizfabvego0nem81c2 | ✅ |
| NAS | 12db2e48f90 | 12db2e48f90-hpy48.cn-hongkong.nas.aliyuncs.com | ✅ |
| 独立数据盘 | d-j6cc6ew2bqkfdlwaavit（初盘）| **d-j6ce444m0p0kf0jwxhcu**（persist 继承盘 · 仍为 `alicloud_disk.prod_data[0]`）| ✅ 类型一致 |
| OSS | deploy-engine-k3s-storage | deploy-engine-k3s-storage | ✅ |

## 三、验证命令

**工作目录**：`diting-infra`

```bash
# tier-3 安全闸（不销资源）
make down-all                                    # 期望退码 1
echo yes | FULL_DESTROY=1 make down-all          # 期望「已取消」· 退码 1

# 永驻资源 + 当前 stack
cd deploy-engine/deploy/terraform/alicloud
terraform output vpc_id data_disk_id security_group_id oss_bucket_name
terraform state list | grep -E 'prod_data|stack\["base"\]'

# 平台快照
make platform-status
```

**deploy-engine help**（三档命令可见）：

```text
make down-stack <project> <env> STACK=<id>
make down-platform-base <project> <env>
make down-all <project> <env> FULL_DESTROY=1
```

### 三-2、W4 B1 · tier-1 证据链（persist ×3 + 本步 T3 闸）

**来源 A — P-step_03 persist**（`/tmp/persist_w4_v3.log`）：

| 轮次 | down-stack | base ECS 销 | redeploy | data_disk_id |
|------|------------|-------------|----------|--------------|
| 1/3 | ✅ | ✅ | ✅ | d-j6ce444m0p0kf0jwxhcu 不变 |
| 2/3 | ✅ | ✅ | ✅ | 不变 |
| 3/3 | ✅ | ✅ | ✅ | 不变 |

**来源 B — 本步 tier-3 安全闸**（2026-05-25 同会话 · 集群仍 Running @ 8.217.179.252）：

- T3-1：`make down-all` → `错误: tier-3 完全销毁需 FULL_DESTROY=1` · exit 1 ✅
- T3-3：`echo yes | FULL_DESTROY=1 make down-all` → `已取消` · exit 1 ✅ · terraform state 永驻行仍在

## 四、DECISION_PENDING 与 SKIP_REASON

| 项 | 类型 | 说明 |
|----|------|------|
| tier-3 FULL_DESTROY 真销 | SKIP_REASON | 启动期 DR 不做 · T3-4 跳过 |
| train/infer tier-1 down | SKIP_REASON | W4 未 Up GPU stack · T1-6~T1-9 待 step_04/05 后补 |
| tier-2 platform-base down | SKIP_REASON | 同会话共享 ECS · 暂离场景再验 T2-1~T2-4 |
| graceful G1~G3 | SKIP_REASON | `platform-step06-graceful-test` / Spot daemon 未入 Makefile |
| cost-snapshot C1 | SKIP_REASON | `scripts/cost-snapshot.sh` 未落地 · 粗算见 §二 |

## 五、准出复核

- [x] §3.5 T1-1~T1-4（diting-stack · persist ×3）
- [ ] T1-6~T1-9（train/infer · 待 GPU stack 部署后）
- [ ] T2-1~T2-4（tier-2 · 暂离时验）
- [x] T3-1~T3-3（二次确认安全闸）
- [ ] T3-4 SKIP（DR）
- [ ] G1~G3 SKIP（脚本待补）
- [ ] C1 SKIP（cost-snapshot 待补）
- [x] 三档命令 deploy-engine `make help` 可见
- [x] down 后永驻 ID 与 P-step_01 同 VPC/SG/NAS/OSS 族
- [x] L5 `l5-shared-platform-baseline-step06` → ⚠️ tier-1 部分

## 六、修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-24 | 占位创建（v2 三档释放纪律）|
| **2026-05-25** | **W4 B1 tier-1 回填**：persist ×3 down-stack 证据 + T3 安全闸 + 永驻 10 项对账 · train/infer/tier-2/G/C 标 SKIP |
