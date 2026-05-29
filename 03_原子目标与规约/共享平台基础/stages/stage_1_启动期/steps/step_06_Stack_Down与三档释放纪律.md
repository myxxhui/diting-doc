# P-step_06 · Stack Down 与三档释放纪律（v2 · 核心纪律）

> **本步定位**：定义并落地 **三档资源释放纪律**——单 chart down（最常用）/ platform-base down（暂离）/ FULL_DESTROY（永久退出 · 极少用）。**v2 修订**：命令统一用 chart 名（更直观）+ **网络层（VPC/SG/路由/网关）与数据同级永驻**（用户校正：0 成本 · 重建贵）。
>
> **核心三条纪律**：
> 1. 任何 down 操作都**不动 10 项永驻资源**（VPC + SG + 路由 + 网关 + NAS + 独立数据盘 + OSS + ACR · 仅 FULL_DESTROY 二次确认可销）；
> 2. **down-stack <chart-name>** 是日常最常用；**down-platform-base** 月级；**FULL_DESTROY** 年级；
> 3. 所有 Down 前必须 **graceful**（drain Pod + DB CHECKPOINT + wal-push）· 不能 hard kill。

> [!NOTE] **[TRACEBACK]**
> - **P 轨入口**：[README §3 三档释放纪律](../../../README.md#§3-三档资源释放纪律v2-校正-核心纪律)
> - **拓扑设计 §7 现状资源 ID 清单 + 🟢 永驻标记**：[01_平台拓扑设计 §7](../01_平台拓扑设计.md#§7-现状资源-id-清单v2-复用而非重做)
> - **deploy-engine 扩展（三档 destroy 实现）**：[02_deploy-engine扩展规约 §3](../02_deploy-engine扩展规约.md#§3-makefile-改造diting-infra-·-不在-deploy-engine-内)
> - **DNA lifecycle_tiers**：[`shared/dna_shared_platform_baseline.yaml#lifecycle_tiers`](../../../../_System_DNA/shared/dna_shared_platform_baseline.yaml)
> - **L4**：[实践记录_step_06_三档释放纪律](../../../../../04_阶段规划与实践/共享平台基础/stage_1_启动期/实践记录_step_06_三档释放纪律.md)

---

## §1 本步目标

<a id="l4-p-step_06-goal"></a>

| # | 目标 |
|---|------|
| 1 | 三档释放命令全部按文档实现（make down-stack / down-platform-base / down-all）|
| 2 | 永驻资源 10 项任何 down 都不动（VPC/SG/路由/网关 + NAS/独立盘/OSS/ACR）|
| 3 | tier-3 FULL_DESTROY 二次确认（输入 `DESTROY-DATA` 字符串）生效 |
| 4 | Down 前 graceful：drain + DB CHECKPOINT + wal-push（base 节点）|
| 5 | Spot 抢占监听（metadata service 2 min 优雅关闭）|
| 6 | 每次 Down 后 cost-snapshot 入 L4 实践记录 |

---

## §2 三档释放矩阵（核心 · 必读）

| 资源类别 | tier-1 单 chart down | tier-2 platform-base down | tier-3 FULL_DESTROY=1 |
|---------|---------------------|--------------------------|----------------------|
| **K8s 业务资源（Deployment/Job/PVC/Service/Secret/ConfigMap）** | helm uninstall 仅清该 chart | helm uninstall 全清 | helm uninstall 全清 |
| **K8s namespace**（platform/train/infer）| **不动** | helm uninstall diting-platform-base 时清 | 清 |
| **集群级 K8s**（ACR pull secret / device-plugin / runtimeClass / storageclass）| **不动** | 跟 platform-base 清 | 清 |
| **对应 stack ECS + EIP + 系统盘** | **销** ✅ | 全销（base + train + infer 残留）| 全销 |
| 🟢 **VPC** | **不动** | **不动** | 销（极少用）|
| 🟢 **安全组** | **不动** | **不动** | 销 |
| 🟢 **路由表 / 网关** | **不动** | **不动** | 销 |
| 🟢 **NAS（含数据 LoRA + datasets）** | **不动** | **不动** | 销（**数据不可恢复警告**）|
| 🟢 **独立数据盘（postgres）** | **不动** | **不动** | 销（**数据不可恢复警告**）|
| 🟢 **OSS bucket（含 wal / backup）** | **不动** | **不动** | 销（**数据不可恢复警告**）|
| 🟢 **ACR 镜像仓库** | 不在 TF 管 | 不在 TF 管 | 不在 TF 管（控制台手销）|

**🟢 = 永驻资源（10 项）**。

---

## §3 工作目录

```bash
cd /Users/<user>/Desktop/workspace/diting-infra
```

---

## §3.5 数据质量验收矩阵（三档释放 · 验证不动永驻）

| # | 检查项 | 验证方式 | 启动期标准 |
|---|--------|---------|-----------|
| **tier-1 单 chart down** | | | |
| T1-1 | `make down-stack diting-stack` 退码 0 | exec | ✅ |
| T1-2 | base ECS 销 | `terraform state list | grep 'stack..base'` | 空 ✅ |
| T1-3 | 独立数据盘仍在 | `terraform state list | grep alicloud_disk.prod_data` | 1 行 ✅ |
| T1-4 | VPC + SG + NAS + OSS 全在 | `terraform output vpc_id nas_id oss_bucket_name security_group_id` | 全部非空 ✅ |
| T1-5 | train/infer 其他 stack 不受影响 | 如有 train ECS · `terraform state list | grep 'stack..train'` 仍在 | ✅ |
| **tier-1 down train** | | | |
| T1-6 | `make down-stack diting-training` 退码 0 | exec | ✅ |
| T1-7 | train ECS 销 · NAS LoRA 仍在 | terraform + `ls /mnt/nas/lora/` | ✅ |
| **tier-1 down vllm** | | | |
| T1-8 | `make down-stack diting-vllm` 退码 0 | exec | ✅ |
| T1-9 | infer ECS 销 · 永驻仍在 | terraform | ✅ |
| **tier-2 platform-base down** | | | |
| T2-1 | `make down-platform-base` 退码 0 | exec | ✅ |
| T2-2 | 所有 ECS 销（base + train + infer 残留）| `terraform state list | grep alicloud_instance` | 空 ✅ |
| T2-3 | 所有 namespace 清 | （若集群还在 · 此时已无 ECS · kubectl 不可用）| ⚠️ 跳过（集群无节点）|
| T2-4 | VPC + SG + 路由 + 网关 + NAS + 独立盘 + OSS 全在 | terraform output 全部非空 | ✅ |
| **tier-3 FULL_DESTROY** | | | |
| T3-1 | `make down-all` 无 FULL_DESTROY=1 时拒绝 | `make down-all` 应退码 1 + 提示 | ✅ |
| T3-2 | `make down-all FULL_DESTROY=1` 询问二次确认 | exec · 应阻塞等待输入 `DESTROY-DATA` | ✅ |
| T3-3 | 二次确认输错（如输入 `yes`）时退出且不破坏 | echo "yes" | make down-all FULL_DESTROY=1 | 退码 1 · 资源全在 ✅ |
| T3-4 | 二次确认输 `DESTROY-DATA` 后真销（**仅 DR 演练时跑 · 通常 SKIP**）| echo "DESTROY-DATA" | make down-all FULL_DESTROY=1 | 全销（数据丢失）⚠️ |
| **graceful + 抢占** | | | |
| G1 | down-stack 前 drain Pod | helm uninstall 前 `kubectl drain <node>` | 完成 ✅ |
| G2 | base stack down 前 DB CHECKPOINT | `kubectl exec pg-pod -- psql -c 'CHECKPOINT'` | ✅ |
| G3 | Spot 抢占监听 daemon（base 节点）| ECS metadata service `curl http://100.100.100.200/latest/meta-data/instance/spot/termination-time` | 2 min 前能收到信号 ✅ |
| **cost-snapshot** | | | |
| C1 | 每次 Down 后 cost-snapshot 入 L4 | `make platform-step06-cost-snapshot` 输出 | ✅ |

---

## §4 / §5 启动期数据量预期 / 凭证

无业务数据。仅 cost-snapshot 累积入 L4 实践记录。

---

## §6 下一步

→ 任意时刻被调用（每次 stack 跑完）
→ 启动期收口前：[P-step_07 阶段验收 · 平台快照](./step_07_阶段验收_平台快照.md)

---

## §7 实施步骤（设计规划推演）

### 7.1 实现要点（部分细节在 02_deploy-engine 扩展规约已写）

| 实现要点 | 涉及位置 | 关键设计决策 | 验证标准 |
|---------|---------|-------------|---------|
| Makefile chart→stack 映射函数 | `diting-infra/Makefile` 内 `define chart_to_stack` | diting-stack=base / diting-training=train / diting-vllm=infer | 见 02_§3.2 ✅ |
| tier-1 实现 | `make down-stack` target | helm uninstall + terraform destroy -target=stack["<id>"] | T1-1~T1-9 ✅ |
| tier-2 实现 | `make down-platform-base` target | helm uninstall 所有 + terraform destroy -target=stack（无具体 key 销所有）| T2-1~T2-4 ✅ |
| tier-3 实现 | `make down-all FULL_DESTROY=1` target | 二次确认 + terraform state rm prevent_destroy + terraform destroy | T3-1~T3-4 ✅ |
| graceful 钩子 | `scripts/graceful-shutdown.sh`（chart pre-delete hook）| drain + CHECKPOINT + wal-push | G1~G2 ✅ |
| Spot 抢占 daemon | base ECS user-data 内 `systemd` service `spot-preempt-watch.service` | metadata 2min 通知 → 触发 graceful | G3 ✅ |
| cost-snapshot | `scripts/cost-snapshot.sh` | 读 terraform output + 计算 ECS 跑时 × 单价 | C1 ✅ |

### 7.2 Makefile 合约（diting-infra）

| target | 行为 |
|--------|------|
| `make down-stack <chart-name>` | tier-1 单 chart down（最常用）|
| `make down-platform-base` | tier-2 platform-base down |
| `make down-all FULL_DESTROY=1` | tier-3 完全销毁 · 二次确认 |
| `make platform-step06-graceful-test` | 模拟 Spot 抢占触发 graceful · 验证 G1~G3 |
| `make platform-step06-cost-snapshot` | 当前轮成本输出 + 累计入 L4 |
| `make platform-step06-status` | 列出所有 ECS / EIP / 永驻资源状态 |

### 7.3 给后续执行模型的指引

- **日常 90% 用 tier-1**（每次跑完业务）· 命令最简单：`make down-stack diting-stack` 或 `diting-training` 或 `diting-vllm`；
- **tier-2 仅暂离时用**（节假日 / 长周末 · 不想再付任何 ECS 费）· 月级；
- **tier-3 几乎不用**（仅业务永久终止 · 年级）· **务必**先备份 NAS 数据 + OSS 数据到本地或外部存储再跑；
- **永驻资源 10 项 grep `🟢` 关键字**：本文档 §2 + README §3 + 拓扑设计 §7 三处都明确标注；
- **二次确认机制**：tier-3 的 `DESTROY-DATA` 字符串是 hard-coded 在 Makefile 内 · **不允许**修改弱化；
- **graceful 失败也要 down**：如 DB CHECKPOINT 失败（DB 已挂）· 仍要 down ECS（防 Spot 反复抢占）+ 标 L4 BLOCKED；
- **Spot 抢占 2min 通知**：是阿里云保证的（不是承诺 · 但通常）· daemon 必须实现 metadata polling。

---

## §8 本步在哪里跑

| 操作 | 位置 |
|------|------|
| make down-stack / down-platform-base / down-all | `diting-infra/`（本地）|
| chart pre-delete hook 脚本 | `diting-infra/charts/diting-{stack,training,vllm}/templates/_helpers.tpl`（已新增）|
| Spot 抢占 daemon | base ECS user-data（在 deploy-engine bootstrap/scripts/user-data.sh · 由 02_§2.4 实现）|

---

## §9 准出（Exit Criteria）

- [ ] §3.5 T1-1~T1-9 全 ✅（tier-1 三种 chart）
- [ ] §3.5 T2-1~T2-4 全 ✅（tier-2 不动永驻验证）
- [ ] §3.5 T3-1~T3-3 全 ✅（tier-3 二次确认机制 · T3-4 视实际需求跑或 SKIP）
- [ ] §3.5 G1~G3 全 ✅（graceful + Spot 抢占）
- [ ] §3.5 C1 ✅（cost-snapshot 入 L4）
- [ ] 已更新 L5 02_验收标准 中 `l5-shared-platform-baseline-step06` 对应行
- [ ] L4 实践记录_step_06 回填完成

---

## §10 [Deploy] 部署节奏

| 阶段 | 部署内容 | 触发 |
|------|---------|------|
| 任意 stack 跑完 | 自动或手动调 `make down-stack <chart>` | 每次（日常 90%）|
| 长暂离 | `make down-platform-base` | 月级 |
| 永久退出 | `make down-all FULL_DESTROY=1` + 二次确认 | 年级 |

---

## §11 依赖

- P-new-02 deploy-engine 扩展 ✅（三档 destroy 实现）
- P-step_03/04/05 都已部署过至少一次（有 stack ECS 可销）

---

## §12 风险与降级

| 风险 | 概率 | 影响 | 降级 |
|------|------|------|------|
| 误跑 FULL_DESTROY 未输二次确认 | 极低 | 灾难 | Makefile 强制 read -p · 输错退出 · prevent_destroy lifecycle |
| Spot 抢占 daemon 漏报 | 低 | 中（DB 来不及 CHECKPOINT）| postgres archive 模式 + 启动期接受 ≤30s 数据丢失 |
| down-stack 后忘了删 PV（Retain 策略孤儿）| 中 | 低 | `make platform-step06-cleanup-orphan-pv` 列出无主 PV |
| terraform state 损坏（state rm 错） | 低 | 高 | state 备份 + remote state（OSS）|
| 多人并发 down 冲突 | 低 | 中 | terraform state lock + Makefile 互斥 |

---

## §13 修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-24 v1 | "Stack Down 与 Spot 回收"分级 Down（6 级）|
| **2026-05-24 v2** | **重写为三档释放纪律**：①命令统一用 chart 名（`make down-stack <chart-name>`）②**网络层永驻**（VPC/SG/路由/网关与数据同级 · 用户校正）③10 项永驻资源 grep 🟢 标注④tier-3 二次确认输 `DESTROY-DATA` 字符串⑤加 §2 三档释放矩阵（与 README §3 / DNA lifecycle_tiers 三处一致）⑥加 §3.5 T1/T2/T3/G/C 19 项矩阵 |
