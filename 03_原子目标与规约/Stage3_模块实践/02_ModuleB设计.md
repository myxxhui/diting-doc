# L3 · Stage3-02 Module B 设计

> [!NOTE] **[TRACEBACK] 原子规约锚点**
> - **战略维度**: [技术栈与架构维度](../../02_战略维度/产品设计/02_技术栈与架构维度.md)
> - **原子规约**: [_共享规约/09_核心模块架构规约](../_共享规约/09_核心模块架构规约.md)
> - **DNA**: [dna_stage3_02.yaml](../_System_DNA/Stage3_模块实践/dna_stage3_02.yaml)、[dna_module_b.yaml](../_System_DNA/core_modules/dna_module_b.yaml)
> - **L4 实践**: [04_阶段规划与实践/Stage3_模块实践/02_ModuleB](../../04_阶段规划与实践/Stage3_模块实践/02_ModuleB.md#l4-stage3-02-exit)
> - **L5 锚点**: [02_验收标准#l5-stage-stage3_02](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_02)

<a id="design-stage3-02-goal"></a>
## 本步目标

实现 Module B 量化扫描引擎（左脑）：策略池（趋势/反转/突破）、板块强弱、向量化扫描；产出技术分数与机会丰度，供 Module C/D 消费。

<a id="design-stage3-02-points"></a>
## 设计要点

- **策略池**：趋势（均线/MACD）、反转（RSI/Bollinger）、突破（高点/成交量）；各池 score_range [0,100]
- **Scanner**：universe_size、technical_score_threshold、sector_strength_threshold（见 core_modules/dna_module_b）
- **输入**：市场数据 OHLCV、Module A 的 Domain Tag
- **输出**：量化信号、技术分数、板块强度

<a id="design-stage3-02-dna-keys"></a>
## 本步落实的 _System_DNA 键

- `core_modules/dna_module_b.yaml`（strategy_pools、scanner）

<a id="design-stage3-02-exit"></a>
## 准出

Module B 四项 100%；单测与联动验证通过；L5 [l5-stage-stage3_02](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_02) 可更新。
