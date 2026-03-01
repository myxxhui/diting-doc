# StorageClass 配置与数据继承验证报告

## 一、任务目标

配置 StorageClass 使用独立数据盘作为后端存储，并更新 Helm values 以使用新的存储配置，实现数据在 Down+Up 后的继承。

## 二、实施步骤

### 2.1 创建 data-disk-local StorageClass

创建了使用独立数据盘路径（`/mnt/titan-data/k3s-storage`）的 StorageClass：

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: data-disk-local
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Retain
parameters:
  nodePath: /mnt/titan-data/k3s-storage
```

### 2.2 更新 local-path provisioner 配置

更新了 `local-path-config` ConfigMap，添加了 `/mnt/titan-data/k3s-storage` 路径：

```json
{
  "nodePathMap":[
  {
    "node":"DEFAULT_PATH_FOR_NON_LISTED_NODES",
    "paths":["/var/lib/rancher/k3s/storage","/mnt/titan-data/k3s-storage"]
  }
  ]
}
```

### 2.3 更新 diting-prod.yaml 配置

修改了 `/Users/huishaoqi/Desktop/workspace/diting-infra/config/diting-prod.yaml`，将所有数据库的 `storage_class` 设置为 `data-disk-local`：

```yaml
deploy_control:
  timescaledb_storage:
    size: "50Gi"
    storage_class: "data-disk-local"
  postgres_l2_storage:
    size: "20Gi"
    storage_class: "data-disk-local"
  redis_storage:
    size: "10Gi"
    storage_class: "data-disk-local"
```

### 2.4 重新部署数据库

使用新的 StorageClass 重新部署了所有数据库组件（TimescaleDB、PostgreSQL L2、Redis）。

## 三、验证结果

### 3.1 PV 路径验证 ✅

成功验证 PV 使用了独立数据盘路径：

```bash
$ kubectl describe pv pvc-67255bab-fea1-402a-b06d-25794089917d
Source:
    Type:          HostPath (bare host directory volume)
    Path:          /mnt/titan-data/k3s-storage/pvc-67255bab-fea1-402a-b06d-25794089917d_default_data-timescaledb-postgresql-0
    HostPathType:  DirectoryOrCreate
```

### 3.2 数据写入验证 ✅

成功在 TimescaleDB 中创建测试表并插入数据：

```
✅ 测试数据已插入:
  ID: 1, Message: Data persistence test - created at 2026-03-01 16:49:58.165612+00, Created: 2026-03-01 16:49:58.165612+00:00
```

### 3.3 数据继承验证 ❌

执行 `make down diting prod` 和 `make deploy diting prod` 后，数据**未能继承**。

**原因分析**：

1. **独立数据盘已保留** ✅
   - `make down` 后，数据盘 `d-j6c4rf72n4bxwtodo515` 确实被保留
   - 数据目录 `/mnt/titan-data/k3s-storage/` 中的旧数据仍然存在

2. **PVC/PV 动态创建问题** ❌
   - 每次部署时，Helm 会创建新的 PVC
   - local-path provisioner 会为新 PVC 创建新的 PV，使用新的 UUID
   - 新 PV 指向新的目录路径（如 `pvc-7fc80895-...`），而不是旧的路径（`pvc-67255bab-...`）

3. **数据盘目录结构**：
   ```
   /mnt/titan-data/k3s-storage/
   ├── pvc-67255bab-fea1-402a-b06d-25794089917d_default_data-timescaledb-postgresql-0/  # 旧数据（有数据）
   ├── pvc-7fc80895-958b-4a0a-b251-b8940d0d7e4b_default_data-timescaledb-postgresql-0/  # 新数据（空）
   ├── pvc-056ecaaf-738c-414d-8512-63685ef8bdd2_default_data-postgresql-l2-0/           # 旧数据
   └── pvc-a21f369d-1b26-48c0-8243-0cf6ee5ddc0a_default_data-postgresql-l2-0/           # 新数据
   ```

## 四、问题根因

**核心问题**：使用动态 PVC/PV 时，每次重新部署都会创建新的 PV，无法自动关联到旧的数据目录。

**Kubernetes 的 PV/PVC 机制**：
- PVC 是对存储的声明（Claim）
- PV 是实际的存储资源
- 动态 provisioner 会为每个 PVC 创建新的 PV
- PV 的名称包含 UUID，每次创建都不同
- local-path provisioner 使用 PV 名称作为目录名

## 五、解决方案

要实现真正的数据继承，有以下几种方案：

### 方案 1：手动创建静态 PV（推荐）

在部署前手动创建 PV，指向固定的路径：

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: timescaledb-data-pv
spec:
  capacity:
    storage: 50Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: data-disk-local
  hostPath:
    path: /mnt/titan-data/postgres/timescaledb
    type: DirectoryOrCreate
```

然后在 Helm values 中引用这个 PV：

```yaml
primary:
  persistence:
    existingClaim: timescaledb-data-pvc
```

### 方案 2：使用 volumeClaimTemplates 的 volumeName

在 StatefulSet 的 volumeClaimTemplates 中指定 `volumeName`，但这需要修改 Helm chart。

### 方案 3：备份与恢复

在 `make down` 前备份数据，`make deploy` 后恢复：

```bash
# Down 前备份
kubectl exec timescaledb-postgresql-0 -- pg_dump -U postgres > backup.sql

# Up 后恢复
kubectl exec timescaledb-postgresql-0 -- psql -U postgres < backup.sql
```

### 方案 4：修改 deploy-engine 逻辑

在 `deploy-engine` 中添加逻辑：
1. Down 前记录 PV 名称和路径
2. Up 后检测旧数据目录
3. 创建 PV 时重用旧路径或迁移数据

## 六、当前状态

### 已完成 ✅

1. ✅ 创建了 `data-disk-local` StorageClass
2. ✅ 更新了 `local-path-config` 配置
3. ✅ 更新了 `diting-prod.yaml` 配置
4. ✅ 验证了 PV 使用独立数据盘路径
5. ✅ 验证了数据可以写入独立数据盘
6. ✅ 验证了独立数据盘在 Down 后被保留

### 未完成 ❌

1. ❌ 数据继承：Down+Up 后数据未能自动继承
2. ❌ 需要实施上述解决方案之一

## 七、配置持久化问题

**重要发现**：K3s 重新初始化后，以下配置会丢失：
- StorageClass `data-disk-local`
- ConfigMap `local-path-config` 的修改

**影响**：每次 `make deploy` 后需要重新：
1. 创建 `data-disk-local` StorageClass
2. 更新 `local-path-config` ConfigMap
3. 重启 `local-path-provisioner`

**建议**：将这些配置集成到 `deploy-engine` 的部署流程中，在 K3s 初始化后自动执行。

## 八、下一步行动

1. **短期**：选择并实施一个数据继承方案（推荐方案 1）
2. **中期**：将 StorageClass 和 ConfigMap 配置集成到 `deploy-engine`
3. **长期**：考虑使用专业的存储解决方案（如 Longhorn、Rook-Ceph）

## 九、参考文档

- Kubernetes PV/PVC 文档：https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- K3s local-path provisioner：https://github.com/rancher/local-path-provisioner
- diting-doc/03_原子目标与规约/_System_DNA/Stage2_数据采集与存储/06_dna_生产级数据要求.yaml
- diting-doc/04_阶段规划与实践/Stage2_数据采集与存储/06_生产级数据要求_实践.md
