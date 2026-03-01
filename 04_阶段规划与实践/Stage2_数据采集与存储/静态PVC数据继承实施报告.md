# 静态 PVC 数据继承实施报告

## 一、实施目标

实现混合存储策略：
- **需要数据继承的数据库**（TimescaleDB L1、PostgreSQL L2）：使用静态 PV/PVC
- **不需要继承的数据库**（Redis）：使用动态 PVC，Down 时自动删除

## 二、实施方案

### 2.1 架构设计

```
独立数据盘 (/mnt/titan-data)
├── postgres/
│   ├── timescaledb/          # 静态 PV 固定路径
│   └── postgresql-l2/        # 静态 PV 固定路径
└── k3s-storage/              # 动态 PVC 临时路径（Down 时删除）
    └── pvc-xxx-redis-...     # Redis 动态 PVC
```

### 2.2 核心配置文件

#### 静态 PV/PVC 配置

文件：`diting-infra/config/static-pvs-diting-prod.yaml`

```yaml
---
# TimescaleDB L1 静态 PV
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
  storageClassName: ""  # 静态 PV 不使用 StorageClass
  hostPath:
    path: /mnt/titan-data/postgres/timescaledb
    type: DirectoryOrCreate

---
# TimescaleDB L1 静态 PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-timescaledb-postgresql-0
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  storageClassName: ""
  volumeName: timescaledb-data-pv

# PostgreSQL L2 配置类似...
```

#### 部署配置

文件：`diting-infra/config/diting-prod.yaml`

```yaml
deploy_control:
  static_pvs_config: "config/static-pvs-diting-prod.yaml"
  
  # TimescaleDB/L1 存储（使用静态 PVC）
  timescaledb_storage:
    size: "50Gi"
    storage_class: ""
    use_static_pvc: true
    static_pvc_name: "data-timescaledb-postgresql-0"
  
  # PostgreSQL L2 存储（使用静态 PVC）
  postgres_l2_storage:
    size: "20Gi"
    storage_class: ""
    use_static_pvc: true
    static_pvc_name: "data-postgresql-l2-0"
  
  # Redis 存储（使用动态 PVC）
  redis_storage:
    size: "10Gi"
    storage_class: "local-path"
    use_static_pvc: false
```

### 2.3 管理脚本

#### 静态 PV/PVC 管理

文件：`diting-infra/scripts/manage-static-pvs.sh`

功能：
- `create <project> <env>` - 创建静态 PV/PVC
- `delete <project> <env>` - 删除静态 PVC（保留 PV 和数据）
- `cleanup <project> <env>` - 完全清理 PV/PVC 及数据

#### 动态 PVC 清理

文件：`diting-infra/scripts/cleanup-dynamic-pvcs.sh`

功能：在 `make down` 时删除动态 PVC（Redis），但保留静态 PVC

#### 数据库部署

文件：`diting-infra/scripts/deploy-databases-with-static-pvc.sh`

功能：
- TimescaleDB：使用 `existingClaim=data-timescaledb-postgresql-0`
- PostgreSQL L2：使用 `existingClaim=data-postgresql-l2-0`
- Redis：使用动态 PVC（`storageClass=local-path`）

### 2.4 Makefile 集成

```makefile
deploy-diting-prod: update-deploy-engine
	# ... (Terraform 部署) ...
	@CONFIG_ROOT="$(CONFIG_ROOT)" $(MAKE) -C $(DEPLOY_ENGINE_DIR) deploy $(PROD_DATA_ENV_PROJECT) $(PROD_DATA_ENV_ENV)
	@echo ""
	@echo "=========================================="
	@echo "  创建静态 PV/PVC（数据继承）"
	@echo "=========================================="
	@$(CURDIR)/scripts/manage-static-pvs.sh create $(PROD_DATA_ENV_PROJECT) $(PROD_DATA_ENV_ENV)
	# ... (后续步骤) ...

down-diting-prod:
	@echo ""
	@echo "=========================================="
	@echo "  清理动态 PVC（保留静态 PVC）"
	@echo "=========================================="
	@$(CURDIR)/scripts/cleanup-dynamic-pvcs.sh $(PROD_DATA_ENV_PROJECT) $(PROD_DATA_ENV_ENV)
	# ... (Terraform 销毁) ...
```

## 三、实施步骤

### 3.1 创建静态 PV/PVC

```bash
cd diting-infra
./scripts/manage-static-pvs.sh create diting prod
```

输出：
```
=== 创建静态 PV/PVC ===
persistentvolume/timescaledb-data-pv created
persistentvolumeclaim/data-timescaledb-postgresql-0 created
persistentvolume/postgresql-l2-data-pv created
persistentvolumeclaim/data-postgresql-l2-0 created
✅ 静态 PV/PVC 创建完成
```

### 3.2 修复目录权限

```bash
export KUBECONFIG="/Users/huishaoqi/.kube/config-diting-prod"
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl debug node/"$NODE_NAME" -it --image=busybox -- sh -c "
    mkdir -p /host/mnt/titan-data/postgres/timescaledb
    mkdir -p /host/mnt/titan-data/postgres/postgresql-l2
    chmod 777 /host/mnt/titan-data/postgres/timescaledb
    chmod 777 /host/mnt/titan-data/postgres/postgresql-l2
"
```

### 3.3 部署数据库

```bash
./scripts/deploy-databases-with-static-pvc.sh diting prod
```

## 四、验证结果

### 4.1 PV 路径验证 ✅

```bash
$ kubectl describe pv timescaledb-data-pv | grep -A 5 "Source:"
Source:
    Type:          HostPath (bare host directory volume)
    Path:          /mnt/titan-data/postgres/timescaledb
    HostPathType:  DirectoryOrCreate
```

### 4.2 PVC 绑定验证 ✅

```bash
$ kubectl get pvc -n default
NAME                            STATUS   VOLUME                  STORAGECLASS
data-timescaledb-postgresql-0   Bound    timescaledb-data-pv     
data-postgresql-l2-0            Bound    postgresql-l2-data-pv   
redis-data-redis-master-0       Bound    pvc-d400c74f-...        local-path
```

**关键点**：
- TimescaleDB 和 PostgreSQL L2 使用**静态 PV**（无 StorageClass）
- Redis 使用**动态 PVC**（StorageClass=local-path）

### 4.3 数据写入验证 ✅

```python
# 创建测试表并插入数据
CREATE TABLE test_static_pvc (
    id SERIAL PRIMARY KEY,
    message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO test_static_pvc (message) 
VALUES ('Static PVC test - created at ' || NOW());
```

输出：
```
✅ 测试数据已插入（使用静态 PVC）:
  ID: 1, Message: Static PVC test - created at 2026-03-01 17:16:09.258369+00
```

### 4.4 数据继承验证（待执行）

执行步骤：
1. 插入测试数据（已完成）
2. `make down diting prod` - 回收 ECS，保留数据盘和静态 PVC
3. `make deploy diting prod` - 重新部署，挂载同一数据盘
4. 验证数据是否存在

## 五、关键优势

### 5.1 静态 PV vs 动态 PV

| 特性 | 静态 PV | 动态 PV |
|------|---------|---------|
| **路径** | 固定（如 `/mnt/titan-data/postgres/timescaledb`） | 动态生成（如 `/mnt/titan-data/k3s-storage/pvc-xxx`） |
| **PV 名称** | 固定（如 `timescaledb-data-pv`） | 动态生成（如 `pvc-67255bab-...`） |
| **数据继承** | ✅ 自动继承（路径固定） | ❌ 无法继承（每次新路径） |
| **回收策略** | Retain（保留数据） | Delete（删除数据） |
| **适用场景** | 需要数据持久化的数据库 | 临时数据、缓存 |

### 5.2 混合存储策略的优势

1. **数据安全**：关键数据（TimescaleDB、PostgreSQL L2）使用静态 PV，确保数据继承
2. **资源优化**：临时数据（Redis）使用动态 PVC，Down 时自动清理
3. **成本控制**：避免为临时数据保留不必要的存储
4. **运维简化**：自动化脚本管理 PV/PVC 生命周期

## 六、Down 时的行为

### 6.1 静态 PVC（TimescaleDB、PostgreSQL L2）

```bash
make down diting prod
```

行为：
- ✅ PVC 保留（不删除）
- ✅ PV 保留（Retain 策略）
- ✅ 数据保留在 `/mnt/titan-data/postgres/`
- ✅ 下次 Up 时自动重新绑定

### 6.2 动态 PVC（Redis）

```bash
./scripts/cleanup-dynamic-pvcs.sh diting prod
```

行为：
- ✅ 删除 Redis PVC
- ✅ 删除对应的 PV（Delete 策略）
- ✅ 释放存储空间
- ✅ 下次 Up 时重新创建

## 七、故障排查

### 7.1 权限问题

**症状**：Pod CrashLoopBackOff，日志显示 `Permission denied`

**解决**：
```bash
kubectl debug node/<node-name> -it --image=busybox -- sh -c "
    chmod 777 /host/mnt/titan-data/postgres/timescaledb
    chmod 777 /host/mnt/titan-data/postgres/postgresql-l2
"
```

### 7.2 PV 状态 Released

**症状**：PV 状态为 Released，无法绑定新的 PVC

**原因**：PVC 被删除后，PV 保留了旧的 claimRef

**解决**：
```bash
kubectl patch pv timescaledb-data-pv -p '{"spec":{"claimRef":null}}'
kubectl patch pv postgresql-l2-data-pv -p '{"spec":{"claimRef":null}}'
```

## 八、下一步行动

### 8.1 完成数据继承验证

1. 执行 `make down diting prod`
2. 执行 `make deploy diting prod`
3. 验证 `test_static_pvc` 表数据是否存在

### 8.2 集成到 deploy-engine

将静态 PV/PVC 的创建集成到 deploy-engine 的部署流程中，实现完全自动化。

### 8.3 文档更新

更新以下文档：
- `06_生产级数据要求_设计.md` - 添加静态 PVC 说明
- `06_生产级数据要求_实践.md` - 更新实践步骤
- `02_基础设施与部署规约.md` - 添加存储策略说明

## 九、参考文档

- [Kubernetes PV/PVC 文档](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [StorageClass 配置与数据继承验证](./StorageClass配置与数据继承验证.md)
- [06_生产级数据要求_设计](../../03_原子目标与规约/Stage2_数据采集与存储/06_生产级数据要求_设计.md)
- [06_生产级数据要求_实践](./06_生产级数据要求_实践.md)
