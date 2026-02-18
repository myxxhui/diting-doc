# Phase1 · 按模块实践 · 02 · Module B 量化扫描引擎

> [!NOTE] **[TRACEBACK] 战略追溯锚点**
> - **顶层概念**: [一句话定义与核心价值](../../01_顶层概念/01_一句话定义与核心价值.md)
> - **战略维度**: [01_产品设计维度](../../02_战略维度/产品设计/01_产品设计维度.md)
> - **原子能力**: [09_核心模块架构规约](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md)（Module B）、[QuantSignal Proto](../../03_原子目标与规约/_Design_Artifacts/protocols/quant/quant_signal.proto)
> - **阶段**: [Phase1_按模块实践](README.md)

**本步设计文档**：[02_ModuleB设计](../../03_原子目标与规约/Stage3_模块实践/02_ModuleB设计.md#design-stage3-02-exit)  
**本步 DNA 文件**：[03_原子目标与规约/_System_DNA/Stage3_模块实践/dna_stage3_02.yaml](../../03_原子目标与规约/_System_DNA/Stage3_模块实践/dna_stage3_02.yaml)

<a id="l4-step-nav"></a>
## 步骤导航
- **上一步**：[01_ModuleA](01_ModuleA.md#l4-stage3-01-goal)
- **下一步**：[03_ModuleC](03_ModuleC.md#l4-stage3-03-goal)

<a id="l4-stage3-02-goal"></a>
## 步骤目标

实现 Module B 量化扫描引擎，满足 09_ 规约的三大策略池、technical_score > 70、sector_strength > 1.1；完成 **四项 100% 验证**。

## 本步骤落实的 DNA 键

- `core_modules/dna_module_b.yaml`：`module_b_quant_engine.strategy_pools`、`scanner.technical_score_threshold`、`scanner.sector_strength_threshold`

## 实现部分

**工作目录**：`diting-core`

1. 建立 `diting/scanner` 或 `diting/strategy` 包，实现 `QuantScanner`
2. 接口：输入标的池、OHLCV；输出 `QuantSignal` 列表（technical_score、strategy_source、sector_strength）
3. 三大策略池（Trend/Reversion/Breakout）阈值与条件写 **YAML 配置**
4. 使用 L1 OHLCV 真实数据（s0_data 准出后）

## 验证部分

### 四项 100%

| 维度 | 验收标准 | 验证方法 |
|------|----------|----------|
| **接口 100%** | 输出符合 QuantSignal.proto；可被 D/C 消费 | Proto 契约单测 |
| **结构 100%** | 目录、配置与 DNA 一致 | 目录存在、config 可加载 |
| **逻辑功能 100%** | 策略池与阈值由 YAML 驱动；真实数据扫描 | 配置变更验证、真实市场扫描结果 |
| **代码测试 100%** | 单测覆盖三策略池、过滤逻辑 | `make test` 覆盖率达标 |

### 三层验证

- **单模块**：全市场或子集真实数据扫描，输出 technical_score > 70 的候选
- **联动**：B 输出作为 D 输入，A+B 联调
- **全链路**：参与 A→F 全链路验证

## 核心指令（The Prompt）

```
你是在 diting-core 中实现 Module B 量化扫描引擎的开发者。必读：03_原子目标与规约/_共享规约/09_核心模块架构规约.md（Module B 小节）、03_原子目标与规约/_System_DNA/core_modules/dna_module_b.yaml、QuantSignal.proto。

任务：1. 实现 QuantScanner，输出 QuantSignal；2. 策略池与阈值写 YAML；3. 单测覆盖 TREND/REVERSION/BREAKOUT；4. 用真实 OHLCV 验证（若 s0_data 已准出）。

工作目录：diting-core。约束：阈值不硬编码；代码含 [Ref: 02_ModuleB]。
```

## 验收与测试

- [ ] 接口 100%、结构 100%、逻辑功能 100%、代码测试 100%
- [ ] `make test` 通过；L5 [l5-mod-B](../../05_成功标识与验证/02_验收标准.md#l5-mod-B) 行已更新

<a id="l4-stage3-02-exit"></a>
## 本步骤准出（DoD）

- 代码提交；单测全绿；L5 [l5-mod-B](../../05_成功标识与验证/02_验收标准.md#l5-mod-B)、[l5-stage-stage3_02](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_02) 已更新

## 本步骤失败时

- 扫描超时 → 分批扫描或缩小 universe
- 真实数据不可用 → Mock 验证接口与结构
