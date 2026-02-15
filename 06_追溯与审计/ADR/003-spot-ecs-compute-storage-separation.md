# ADR-003: 采用 Spot ECS + 存算分离

## 状态
Accepted

## Context (背景)

需要降低基础设施成本，同时保证数据安全和高可用性。

**成本压力**：
- 包年包月 ECS 成本高（约 1000 元/月/实例）
- 需要多实例部署（扫描引擎、MoE 推理、执行网关）
- 总成本可能超过 5000 元/月

**数据安全要求**：
- 数据不能丢失（RPO ≈ 0）
- 支持竞价实例回收恢复（L2 故障）

## Decision (决策)

采用 **Spot ECS（竞价实例）+ 存算分离**架构：

1. **计算层**：Spot ECS（竞价实例）
   - 成本降低 70%（约 300 元/月/实例）
   - 支持 Metadata Service 2 分钟回收通知
   - 优雅关闭流程（kubectl drain → DB CHECKPOINT → wal-g push）

2. **存储层**：存算分离
   - **L1 Hot**：ESSD PL1（TimescaleDB，实时数据）
   - **L2 Warm**：PostgreSQL（业务数据）
   - **L3 Cold**：OSS（WAL 日志、快照归档）

3. **数据备份**：WAL-G + OSS
   - 实时 WAL 日志推送（RPO < 1 分钟）
   - 每小时数据库快照
   - 支持异地恢复（5 分钟内拉起新实例）

## Consequences (后果)

**[+] 正面影响**：
- 成本降低 70%（Spot 实例）
- 数据安全（存算分离，数据不丢失）
- 支持竞价实例回收恢复（L2 故障恢复，RTO < 5 分钟）
- 支持 Scale-to-Zero（成本治理）

**[-] 负面影响**：
- Spot 实例可能被回收（需要优雅关闭流程）
- 架构复杂度增加（存算分离、备份恢复）
- 需要监控 Metadata Service

**[!] 风险与注意事项**：
- Spot 实例回收频率：约每月 1-2 次
- 优雅关闭流程必须可靠（否则数据可能丢失）
- OSS 存储成本需要监控

## Alternatives Considered (考虑的替代方案)

1. **包年包月 ECS + 本地存储**：
   - 优点：稳定，简单
   - 缺点：成本高（约 5000 元/月），数据不安全（实例回收数据丢失）
   - 结论：❌ 不采用

2. **Spot ECS + 本地存储**：
   - 优点：成本低
   - 缺点：数据不安全（实例回收数据丢失）
   - 结论：❌ 不采用

3. **Spot ECS + 存算分离**：
   - 优点：成本低 + 数据安全 + 支持恢复
   - 缺点：架构复杂
   - 结论：✅ **采用**

## Compliance Check (合规检查)

- ✅ 符合成本治理要求（成本降低 70%）
- ✅ 符合数据安全要求（存算分离，RPO < 1 分钟）
- ✅ 符合业务连续性要求（RTO < 5 分钟）

## Traceability (追溯性)

- **L1 价值点**: [核心价值：成本控制](../01_顶层概念/02_战略目标与ROI.md)
- **L2 维度**: [成本治理维度](../02_战略维度/产品设计/07_成本治理维度.md)
- **L2 维度**: [数据架构与分层存储维度](../02_战略维度/产品设计/03_数据架构与分层存储维度.md)
- **L3 规约**: [运营治理与灾备规约](../03_原子目标与规约/10_运营治理与灾备规约.md)
- **相关 ADR**：ADR-001

## Implementation Notes (实施说明)

### Terraform 配置

```hcl
# modules/ecs_spot/main.tf
resource "alicloud_ecs_instance" "spot" {
  instance_charge_type = "PostPaid"
  spot_strategy        = "SpotWithPriceLimit"
  spot_price_limit     = var.spot_price_limit
  
  # 存算分离：不挂载数据盘
  # 数据存储在独立的 RDS/OSS
}
```

### 优雅关闭流程

```python
# diting-core/diting/dr/graceful_shutdown.py
class GracefulShutdown:
    def execute(self):
        # 1. kubectl drain
        self._drain_node()
        
        # 2. DB CHECKPOINT
        self._checkpoint_database()
        
        # 3. WAL-G push
        self._push_wal_logs()
        
        # 4. 脚本自杀
        self._self_terminate()
```

### 异地恢复流程

```hcl
# terraform/modules/spot_recovery/main.tf
resource "alicloud_ecs_instance" "recovery" {
  # 从 OSS 快照恢复
  image_id = var.snapshot_id
  
  # 异地部署
  availability_zone = var.recovery_zone
}
```

## Review History (审查历史)

- 2026-02-11: 初始创建
- 2026-02-11: 状态变更（Accepted）
