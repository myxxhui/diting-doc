# ADR-004: 采用 Human-in-the-Loop (买入确认/止损自动) 模式

## 状态
Accepted

## Context (背景)

金融交易系统需要合规性保障，同时需要快速响应止损信号。

**合规性要求**：
- 程序化交易需要人工审批
- 严禁全自动交易（存在合规风险）

**业务要求**：
- 止损需要快速响应（< 500ms）
- 买入/止盈可以接受一定延迟（人工确认）

## Decision (决策)

采用 **Human-in-the-Loop 模式**：

1. **买入**：
   - 流程：推送至手机 → 人工确认 → 机器拆单执行
   - 审批要求：必须人工确认
   - 超时时间：5 分钟

2. **止盈**：
   - 流程：推送至手机 → 人工确认 → 机器执行
   - 审批要求：必须人工确认
   - 超时时间：5 分钟

3. **止损**：
   - 流程：机器自动执行（无需审批）
   - 审批要求：AUTO_EXECUTED（最高权限）
   - 执行时间：< 500ms

## Consequences (后果)

**[+] 正面影响**：
- 符合合规性要求（人工审批）
- 止损快速响应（< 500ms）
- 降低误操作风险（人工确认）
- 支持合规性审计（所有操作可追溯）

**[-] 负面影响**：
- 买入/止盈需要人工确认（可能延迟 1-5 分钟）
- 需要维护通知系统（手机推送）
- 人工确认可能错过最佳时机

**[!] 风险与注意事项**：
- 止损必须自动执行（不能等待人工确认）
- 通知系统必须可靠（否则订单无法执行）
- 人工确认超时后的处理策略（拒绝/自动执行）

## Alternatives Considered (考虑的替代方案)

1. **全自动交易**：
   - 优点：快速，无需人工干预
   - 缺点：合规风险高，可能违反监管规定
   - 结论：❌ 不采用

2. **全人工交易**：
   - 优点：完全合规
   - 缺点：效率低，止损响应慢（无法满足 < 500ms）
   - 结论：❌ 不采用

3. **Human-in-the-Loop**：
   - 优点：平衡合规和效率
   - 缺点：买入/止盈有延迟
   - 结论：✅ **采用**

## Compliance Check (合规检查)

- ✅ 符合程序化交易报备要求（人工审批）
- ✅ 符合交易行为合规性要求（可追溯）
- ✅ 符合监管要求（止损自动执行是行业标准）

## Traceability (追溯性)

- **L1 价值点**: [核心价值：合规性](../01_顶层概念/01_一句话定义与核心价值.md)
- **L2 维度**: [安全与机密治理维度](../02_战略维度/产品设计/05_安全与机密治理维度.md)
- **L3 规约**: [核心模块架构规约](../03_原子目标与规约/09_核心模块架构规约.md)
- **L3 规约**: [运营治理与灾备规约](../03_原子目标与规约/10_运营治理与灾备规约.md)
- **相关 ADR**：ADR-001, ADR-002

## Implementation Notes (实施说明)

### 执行网关实现

```python
# diting-core/diting/execution/gateway.py
class ExecutionGateway:
    async def execute_order(self, order: TradeOrder):
        if order.audit_status == AuditStatus.AUTO_EXECUTED:
            # 止损：自动执行
            await self._auto_execute(order)
        elif order.audit_status == AuditStatus.PENDING_APPROVAL:
            # 买入/止盈：等待人工确认
            await self._wait_for_approval(order)
```

### 通知系统

```python
# diting-core/diting/execution/notification.py
class NotificationService:
    async def send_approval_request(self, order: TradeOrder):
        """发送审批请求到手机"""
        await push_notification(
            title="交易确认",
            message=f"{order.symbol} {order.type} {order.quantity}股",
            order_id=order.order_id,
            timeout=300  # 5 分钟超时
        )
```

### 验收标准

- 止损执行耗时 < 500ms
- 买入/止盈人工确认率 ≥ 95%
- 通知系统可用性 ≥ 99.9%

## Review History (审查历史)

- 2026-02-11: 初始创建
- 2026-02-11: 状态变更（Accepted）
