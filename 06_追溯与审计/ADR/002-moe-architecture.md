# ADR-002: 采用 MoE (混合专家) 架构

## 状态
Accepted

## Context (背景)

需要同时满足"不可能三角"的三个约束：
- **认知边界**：胜率 ≥ 80%
- **复利增长**：年化复利 ≥ 30%
- **生存底线**：回撤 < 12%

单一模型无法同时满足这些目标：
- 通用 LLM：胜率不足（约 65%）
- 纯量化策略：胜率不稳定，无法解释

## Decision (决策)

采用 **Neuro-Symbolic MoE（神经符号混合专家）架构**：

1. **Router**：根据 Domain Tag 和 Market Regime 动态选择专家
2. **垂类专家**：
   - Agri-Agent：农业领域（季节性、期货升贴水）
   - Tech-Agent：硬科技领域（研发投入、大基金动向）
   - Geo-Agent：宏观领域（大宗商品、汇率）
3. **强制交集**：Quant Signal ∩ Expert Opinion = 有效信号
4. **白盒化**：每个专家必须输出 reasoning_summary（可解释逻辑）

## Consequences (后果)

**[+] 正面影响**：
- 垂类专家胜率比通用 LLM 高 15% 以上（达到 ≥ 80%）
- 支持"认知边界"要求（只做能解释的交易）
- 支持"复利增长"要求（多策略池并发挖掘）
- 支持"生存底线"要求（专家一票否决机制）

**[-] 负面影响**：
- 架构复杂度增加（Router + 多个专家）
- 需要维护多个专家模型
- Token 成本增加（多个专家推理）

**[!] 风险与注意事项**：
- Router 选择错误可能导致信号丢失
- 专家模型需要持续训练和优化
- LLM API 限流可能影响推理速度

## Alternatives Considered (考虑的替代方案)

1. **单一通用 LLM**：
   - 优点：架构简单
   - 缺点：胜率不足（约 65%），无法满足 80% 要求
   - 结论：❌ 不采用

2. **纯量化策略**：
   - 优点：速度快，成本低
   - 缺点：胜率不稳定，无法解释，无法满足"认知边界"
   - 结论：❌ 不采用

3. **MoE 架构**：
   - 优点：平衡胜率和收益，支持可解释性
   - 缺点：架构复杂
   - 结论：✅ **采用**

## Compliance Check (合规检查)

- ✅ 符合"认知边界"要求（可解释性）
- ✅ 符合"复利增长"要求（多策略池）
- ✅ 符合"生存底线"要求（专家一票否决）

## Traceability (追溯性)

- **L1 价值点**: [核心价值：不可能三角](../01_顶层概念/01_一句话定义与核心价值.md)
- **L2 维度**: [技术栈与架构维度](../02_战略维度/产品设计/02_技术栈与架构维度.md)
- **L3 规约**: [核心公式与MoE架构规约](../03_原子目标与规约/_共享规约/01_核心公式与MoE架构规约.md)
- **L3 规约**: [核心模块架构规约](../03_原子目标与规约/_共享规约/09_核心模块架构规约.md)
- **相关 ADR**：ADR-001

## Implementation Notes (实施说明)

### Router 实现

```python
# diting-core/diting/moe/router.py
class MoERouter:
    """MoE 路由器：根据 Domain Tag 分发到对应专家"""
    
    def route(self, symbol: str, domain_tags: List[DomainTag], quant_signal: QuantSignal):
        # 根据 Tag 选择专家
        if DomainTag.AGRI in domain_tags:
            return self.agri_agent.analyze(symbol, quant_signal)
        elif DomainTag.TECH in domain_tags:
            return self.tech_agent.analyze(symbol, quant_signal)
        # ...
```

### 专家实现

```python
# diting-core/diting/moe/specialists/agri_agent.py
class AgriAgent:
    """农业专家：关注季节性、期货升贴水"""
    
    def analyze(self, symbol: str, quant_signal: QuantSignal) -> ExpertOpinion:
        # 1. 获取期货数据
        futures_data = self._get_futures_data("大豆")
        
        # 2. 检查期货升贴水
        is_contango = futures_data['spot_price'] > futures_data['futures_price']
        
        # 3. 生成专家意见（必须包含 reasoning_summary）
        return ExpertOpinion(
            is_supported=True,
            confidence=0.8,
            reasoning_summary="拉尼娜现象导致大豆减产预期强烈，且期货升水"
        )
```

### 验收标准

- 垂类专家胜率 ≥ 80%
- 专家胜率比通用 LLM 高 ≥ 15%
- 每个专家意见必须包含 reasoning_summary

## Review History (审查历史)

- 2026-02-11: 初始创建
- 2026-02-11: 状态变更（Accepted）
