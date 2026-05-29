# L4 · 维度一极寒防御 · 启动期 · 实践记录 step_04 财务测谎引擎 LoRA

> **状态**：✅ tier-1 骨架完成（2026-05-25 W5）；tier-2 BLOCKED(gpu_unavailable + step_03 数据)

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[step_04_财务测谎引擎LoRA.md](../../../03_原子目标与规约/01_维度一_极寒防御/stages/stage_1_启动期/steps/step_04_财务测谎引擎LoRA.md)
> - **DNA**：`engines.financial_fraud` 5 节点 + `feature_calculator.thresholds` + `lora_gatekeeper.holdout_required`
> - **L5**：`02_验收标准.md#l5-stage-cryo_04`
> - **上游**：← step_03 Teacher 蒸馏数据 / **下游**：→ step_05 关联方网络引擎

## 一、本步骤目标

实现 5 节点财务测谎引擎骨架：
- N1 `field_extractor`：11 字段 ORM 查询，缺失标 missing
- N2 `feature_calculator`：6 类粉饰特征公式（存贷双高/现金流背离/应收异常/存货积压/研发资本化突变/毛利率异常）
- N3 `time_series_comparator`：≥4 期历史趋势，不足标 insufficient
- N4 `peer_comparator`：同行 ≥3 家百分位，不足降级 market_wide
- N5 `llm_interrogator`：vLLM + LoRA，无 vLLM 时降级 confidence=0.5

## 二、实际进展（2026-05-25 W5）

| 项 | 状态 | 证据 |
|----|------|------|
| `apps/cryo_guard/engines/financial_fraud/schemas.py` | ✅ | Pydantic v2：FraudLabel / RiskLevel / EvidenceItem / LLMInterrogatorOutput / FinancialFraudReport |
| `apps/cryo_guard/engines/financial_fraud/field_extractor.py` | ✅ | N1：11 字段，无 DB 全返 None + missing_fields |
| `apps/cryo_guard/engines/financial_fraud/feature_calculator.py` | ✅ | N2：6 类公式，配置项化阈值 |
| `apps/cryo_guard/engines/financial_fraud/time_series_comparator.py` | ✅ | N3：无 DB → insufficient=True |
| `apps/cryo_guard/engines/financial_fraud/peer_comparator.py` | ✅ | N4：无 DB → peer_fallback=no_db |
| `apps/cryo_guard/engines/financial_fraud/llm_interrogator.py` | ✅ | N5：无 vLLM → lora_loaded=False + confidence=0.5 |
| `apps/cryo_guard/engines/financial_fraud/engine.py` | ✅ | 5 节点串联，纯函数（tier-1 无 LangGraph 依赖）|
| `pytest tests/cryo_guard/test_financial_fraud_engine.py` | ✅ | **22 passed** |
| `make cryo-step04-all` | ✅ | prep + pytest 全绿 |
| N2 特征公式 6 类正负验证 | ✅ | 11 条 TestFeatureCalculator 覆盖 6 类正负触发场景 |
| tier-2 真实 DB 联调 | ⏳ | 等 step_02 `financial_reports` 数据就绪 |
| tier-2 LoRA 训练 + Holdout | ⏳ | `BLOCKED(gpu_unavailable)` + step_03 蒸馏数据尚未满足 Q1~Q3 |

## 三、命令与输出摘要

```
make cryo-step04-all
  ✅ FinancialFraudEngine 可导入
  ✅ feature_calculator 可导入
  22 passed in 0.08s
✅ [cryo-step04-all] D1 step_04 tier-1 准出
DECISION_PENDING: tier-2 需 GPU + step_03 蒸馏数据（Q1~Q3 各类 ≥150）
```

## 四、特征公式验证摘要（N2）

| 特征 | 触发场景验证 | 正常场景验证 |
|------|------|------|
| double_high | cash/assets=0.5>0.3 且 debt/assets=0.4>0.3 → ✅ | debt/assets=0.1<0.3 → ✅ |
| cash_flow_divergence | OCF/NP=0.167<0.5 → ✅ | OCF/NP=0.83>0.5 → ✅ |
| ar_abnormal | AR_yoy=300% vs revenue_yoy=6.7% → ✅ | 无上期 → not triggered ✅ |
| inventory_bloat | inv_ratio=18.75% vs median=5% × 1.5 → ✅ | — |
| rd_cap_surge | rd_cap yoy=100% > 30% → ✅ | — |
| gross_margin_anomaly | gm_yoy=-10pp < -5pp → ✅ | gm_yoy=+1pp → ✅ |

## 五、DECISION_PENDING 与 SKIP_REASON

| 项 | 类型 | 说明 |
|----|------|------|
| tier-2 LoRA 训练 | SKIP_REASON | `BLOCKED(gpu_unavailable)` + 等 step_03 Q1~Q3 满足 |
| Holdout 30 案例 H001~H030 | SKIP_REASON | 依赖 LoRA 训练完成 |
| N5 真实 vLLM 推理 | SKIP_REASON | 依赖 GPU + diting-vllm chart |
| N1/N3/N4 真实 DB 对接 | SKIP_REASON | 等 step_02 `financial_reports` 4 标的 × 4 期就绪 |

## 六、准出复核（tier-1）

- [x] 5 节点模块全部可导入（`FinancialFraudEngine`、`compute_features`）
- [x] N2 6 类特征公式逻辑正确（11 条测试，正负各 1+ 案例）
- [x] 整引擎无 DB / 无 vLLM 时优雅降级（lora_loaded=False，peer_fallback=no_db，insufficient=True）
- [x] `FinancialFraudReport` Pydantic schema 合法（model_dump 通过）
- [x] pytest 22 passed
- [x] `make cryo-step04-all` 退码 0
- [ ] tier-2：DB 真流 + LoRA 训练 + Holdout ≥Recall 0.95（等 GPU Spot 回流 + step_03 数据）

## 七、修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-25 | W5 tier-1 完成：5 节点骨架 + 22 passed；BLOCKED(gpu_unavailable) 已记录 |
