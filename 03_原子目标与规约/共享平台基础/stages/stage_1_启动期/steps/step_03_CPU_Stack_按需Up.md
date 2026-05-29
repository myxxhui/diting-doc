# P-step_03 · CPU stack 首次 Up · platform-base + diting-stack（v2）

> **本步定位**：启动期首次 Up CPU 节点 + 装集群级基础设施 chart + 装业务 chart。**v2 修订**：从 v1 "Spot ECS Up + 数据盘继承" + "CPU Stack 中间件" **两步合并为一步**（4 chart 设计下 platform-base 与 diting-stack 同时装更顺）。

> [!NOTE] **[TRACEBACK]**
> - **P 轨入口**：[README](../../../README.md)
> - **拓扑设计**：[01_平台拓扑设计](../01_平台拓扑设计.md)
> - **前置 step**：[step_01 现状盘点](./step_01_现状盘点与凭证复用.md) + [02 deploy-engine 扩展规约](../02_deploy-engine扩展规约.md)
> - **DNA**：[`shared/dna_shared_platform_baseline.yaml#steps[p_step_03]`](../../../../_System_DNA/shared/dna_shared_platform_baseline.yaml)
> - **L4**：[实践记录_step_03_CPU_Stack_按需Up](../../../../../04_阶段规划与实践/共享平台基础/stage_1_启动期/实践记录_step_03_CPU_Stack_按需Up.md)
> - **现有 chart**：`diting-infra/charts/diting-stack/`（沿用 · 加 platform namespace）

---

## §1 本步目标

<a id="l4-p-step_03-goal"></a>

| # | 目标 |
|---|------|
| 1 | `make up-stack diting-stack` 起 base ECS（CPU Spot · K3s server · 挂独立数据盘 · label=base）|
| 2 | 创建 `charts/diting-platform-base/` chart（namespace platform/train/infer + ACR pull secret + nvidia-device-plugin + runtimeClass + storageclass-nas）|
| 3 | `helm install diting-platform-base` 完成集群级基础设施 |
| 4 | `helm install diting-stack -n platform` 完成业务（TimescaleDB / PG-L2 / module_a / ingest · 沿用现有 chart 加 nodeSelector）|
| 5 | 三轮数据继承验证（down-stack → up-stack → 数据无丢失）|
| 6 | 业务 D1 step_02 真采集可入 TimescaleDB |

**预计耗时**：首次 ~60 min（含 K3s 启动 + chart install + 验证）；后续 `up-stack` ~10 min。**成本**：~¥0.6（1 小时）。

---

## §2 前置条件

| # | 前置 | 检查 |
|---|------|------|
| 1 | P-step_01 准出全 ✅ | 现状 10 项 ID 核对 + .env 就绪 |
| 2 | P-new-02 deploy-engine 扩展已实现并合入主仓 | `make help | grep up-stack` 有命中 |
| 3 | ACR 镜像已构建 + push（diting-ingest / diting-module-a / 等业务镜像） | `docker pull <ACR_URL>/diting-ingest:latest` 通 |

---

## §3 工作目录

```bash
cd /Users/<user>/Desktop/workspace/diting-infra
```

deploy-engine 写操作仍在平级独立仓库（不在本步内做 · P-new-02 已完成）。

---

## §3.5 数据质量验收矩阵（首次 Up + 中间件 + 数据继承）

| # | 检查项 | 验证方式 | 启动期标准 |
|---|--------|---------|-----------|
| **ECS / K3s** | | | |
| H1 | base ECS 起 · Spot 中标 | `terraform output instance_ids` 含 1 个 | ✅ |
| H2 | ECS 实例 Ready · SSH 通 | `ssh root@<EIP> uptime` | ✅ |
| H3 | K3s server 起 | `kubectl get nodes` 含 1 个 Ready | ✅ |
| H4 | K3s label=base 已注入 | `kubectl get nodes -L stack.diting/node | grep base` | ✅ |
| H5 | 独立数据盘已挂载到 `/mnt/data` | `ssh root@<EIP> 'df -h | grep /mnt/data'` | ✅ |
| H6 | NAS 已挂载到 `/mnt/nas` | `ssh root@<EIP> 'df -h | grep /mnt/nas'` | ✅ |
| **platform-base chart** | | | |
| P1 | 3 namespace 已创建（platform/train/infer）| `kubectl get ns | grep -E '(platform|train|infer)'` | 3 行 ✅ |
| P2 | ACR pull secret 已复制到 3 ns | `for ns in platform train infer; do kubectl get secret acr-titan -n $ns; done` | 3 行 ✅ |
| P3 | nvidia-device-plugin DaemonSet 已部署 | `kubectl get ds -n kube-system | grep nvidia` | 0 实例（GPU 节点未起）✅ |
| P4 | StorageClass nas 已创建 | `kubectl get sc | grep nas` | ✅ |
| **diting-stack chart** | | | |
| S1 | helm release diting-stack 在 platform ns | `helm list -n platform | grep diting-stack` | ✅ |
| S2 | TimescaleDB Pod Running · PVC Bound | `kubectl get pod,pvc -n platform | grep timescaledb` | ✅ |
| S3 | Postgres-L2 Pod Running · PVC Bound | `kubectl get pod,pvc -n platform | grep postgresql-l2` | ✅ |
| S4 | schema-init Job Complete | `kubectl get job -n platform | grep schema-init.*Complete` | ✅ |
| S5 | module_a Pod Running | `kubectl get pod -n platform | grep module_a.*Running` | ✅ |
| S6 | NodePort 30001/30002 可连（本机）| `psql -h <EIP> -p 30001 -U postgres -c '\dt'` | 列表 ✅ |
| **数据继承（核心 · 三轮）** | | | |
| D1 | 第 1 轮 down-stack diting-stack → up-stack → 数据无丢失 | down 前 INSERT 测试数据 · up 后 SELECT 验证 | ✅ |
| D2 | 第 2 轮 down-stack → up-stack → 数据无丢失 | 同上 | ✅ |
| D3 | 第 3 轮 down-stack → up-stack → 数据无丢失 | 同上 | ✅ |
| D4 | 独立数据盘 ID 保持 `d-j6cc6ew2bqkfdlwaavit` 不变 | `terraform state show alicloud_disk.prod_data` | ✅ |
| **业务联动** | | | |
| B1 | D1 step_02 真采集可入库（跨仓同会话） | `cd ../diting-src && make ingest-test` + 验 TimescaleDB 行数 | ≥1 行 ✅ |
| B2 | NAS 跨 namespace 可挂（platform → 后续 train/infer 共享） | `kubectl run -n platform --rm -it test --image=busybox -- ls /mnt/nas` | 通 ✅ |

---

## §4 启动期数据量预期

- TimescaleDB 启动期容量：~50GB（D1 全 A 8 持仓的 OHLCV + 财报）
- Postgres-L2 启动期容量：~20GB（业务事件 + ThesisCard）
- NAS 启动期容量：~10GB（启动期无 LoRA · 留空给 step_04）

## §4.1 用户须提供的凭证

| 凭证 | 何时用 |
|------|-------|
| `.env` 中 `TF_VAR_instance_password` | up-stack 起 ECS 时 |
| 阿里云控制台 → 安全组 6443/22 入站白名单 = 当前出口 IP | 起后 kubectl 连 |

---

## §5 启动期数据量预期（重复 §4 · 保留模板节）

见 §4。

---

## §6 下一步

→ 启动期常态：base stack 按需起停（每次起 ~10 min · 数据继承）
→ W4+ 触发：[step_04 GPU 训练组按需 Up](./step_04_GPU训练组按需Up.md)
→ W5+ 触发：[step_05 GPU 推理组按需 Up](./step_05_GPU推理组按需Up.md)
→ 任意时刻：[step_06 三档释放纪律](./step_06_Stack_Down与三档释放纪律.md)

---

## §7 实施步骤（设计规划推演）

### 7.1 实现要点

| 实现要点 | 涉及位置 | 关键设计决策 | 验证标准 |
|---------|---------|-------------|---------|
| 起 base ECS（首次或重启）| `make up-stack diting-stack` → terraform apply -target=`alicloud_instance.stack["base"]` | 复用 VPC/SG/NAS/数据盘 · 仅新建 ECS | §3.5 H1~H6 全 ✅ |
| 新建 `charts/diting-platform-base/` chart | `diting-infra/charts/diting-platform-base/templates/`（含 namespace + ACR secret + device-plugin + storageclass）| 一次装 · uninstall 时清 3 ns | §3.5 P1~P4 ✅ |
| 安装 platform-base | `helm install diting-platform-base charts/diting-platform-base` | 不指定 -n（cluster-scoped）| P1~P4 ✅ |
| 安装 diting-stack（沿用现有）| `helm install diting-stack charts/diting-stack -n platform --create-namespace=false` | platform ns 由 platform-base 已建 · 加 nodeSelector=base | S1~S6 ✅ |
| 三轮数据继承验证 | 脚本 `scripts/test-data-persistence.sh ROUNDS=3` | 每轮：INSERT marker → down-stack → up-stack → SELECT marker | D1~D3 ✅ |
| 业务联动 | `cd ../diting-src && make ingest-test` | 真 ingest 入库 | B1~B2 ✅ |

### 7.2 Makefile 合约（diting-infra）

| target | 用途 | 行为 |
|--------|------|------|
| `make up-stack diting-stack` | 起 base ECS | terraform apply -target=stack["base"] + 等待 K3s Ready |
| `make platform-step03-up` | 一键端到端：up-stack + helm install platform-base + helm install diting-stack | 调上述 + helm |
| `make platform-step03-test-persist ROUNDS=3` | 数据继承三轮验证 | 脚本 |
| `make platform-step03-smoke` | 一键跑 §3.5 全部 H/P/S/D/B 检查 | 调 kubectl/helm/psql 等 |
| `make down-stack diting-stack` | 销 base ECS（保留数据 + 永驻）| 见 step_06 |

### 7.3 给后续执行模型的指引

- **必须**先做 P-step_01（现状盘点）+ P-new-02（deploy-engine 扩展）；
- 起 base ECS 时**复用**现有 VPC `vpc-j6cuhmska9vfwqa6my16q` + NAS `12db2e48f90` + 独立数据盘 `d-j6cc6ew2bqkfdlwaavit`（terraform 已配 use_existing_*）；
- 装 `diting-platform-base` chart 时 **DaemonSet device-plugin 0 实例是正常的**（GPU 节点未起）· 等 P-step_04 起 train ECS 后才有 1 实例；
- 装 `diting-stack` chart 时务必 `--create-namespace=false`（namespace 由 platform-base 管 · 防双方都管 ns）；
- 数据继承三轮**必须**真做（不能跳过）· 是验证 ECS 重启数据不丢的核心证据；
- 若 §3.5 任意必 ✅ 项失败：先按本文档 §12 风险与降级排查 · 重试 ≤2 次 · 再 ≤2 次仍失败回收 + 标 L4 BLOCKED。

---

## §8 本步在哪里跑

| 操作 | 位置 |
|------|------|
| make up-stack / 三轮验证 / smoke | `diting-infra/`（本地 · 配 kubeconfig）|
| psql / 业务 ingest-test | 本机或集群内 |
| chart 编辑 | `diting-infra/charts/diting-platform-base/`（新建）+ `diting-infra/charts/diting-stack/`（沿用 · 加 nodeSelector）|

---

## §9 准出（Exit Criteria）

- [ ] §3.5 必 ✅ 项全绿（H1~H6, P1~P4, S1~S6, D1~D4, B1~B2 共 19 项）
- [ ] 业务 D1 step_02 真采集已入 TimescaleDB（B1）
- [ ] 三轮数据继承通过（D1~D3）
- [ ] 已更新 L5 02_验收标准 中 `l5-shared-platform-baseline-step03` 对应行
- [ ] L4 实践记录_step_03 回填完成

---

## §10 [Deploy] 部署节奏

| 阶段 | 部署内容 | 触发 |
|------|---------|------|
| 首次 W2 | 一键端到端 platform-step03-up（含三轮验证 ~60 min）| P-step_01/02 完成 |
| 后续按需 | up-stack diting-stack（~10 min · 数据继承）| 每次采集 / 业务执行 |

---

## §11 依赖

- P-step_01 ✅ + P-new-02 ✅
- 现有 6 类永驻资源（VPC/VSwitch/SG/NAS/独立盘/OSS）
- ACR 业务镜像已 push

---

## §12 风险与降级

| 风险 | 概率 | 影响 | 降级 |
|------|------|------|------|
| Spot 库存不足（base 起不来）| 低 | 高 | 换可用区（zone_gpu_fallback）· 再不行临时按量 ≤¥10/h |
| 独立数据盘挂载失败 | 中 | 高（数据访问不通）| 检查 attach_data_disk + delete_with_instance=false · 重启 ECS |
| K3s server 启动慢 | 中 | 中 | 检查 user-data.sh + journalctl -u k3s |
| ACR pull secret 失效 | 低 | 中（业务镜像拉不到）| 重新生成 .dockerconfigjson · helm upgrade platform-base |
| 数据继承轮次失败 | 低 | 高（核心 SLA）| 检查 PV/PVC reclaimPolicy=Retain + storageClass=local-path |
| D1 step_02 业务真采集失败 | 中 | 中 | 退到 mock（明示 BLOCKED）+ 标 L4 |

---

## §13 修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-24 v1 | step_02 Spot ECS Up + step_03 CPU Stack 中间件 两份独立 |
| **2026-05-24 v2** | **合并为本步**：①CPU 节点改"随用随起"②首次 Up 同时装 platform-base + diting-stack（4 chart 设计）③命令改 `make up-stack diting-stack`④加 §3.5 P1~P4 platform-base 检查项⑤强调三轮数据继承核心 SLA |
