# Phase1 · 按模块实践 · 01 · Module A 语义分类器

> [!NOTE] **[TRACEBACK] 战略追溯锚点**
> - **顶层概念**: [一句话定义与核心价值](../../01_顶层概念/01_一句话定义与核心价值.md)
> - **战略维度**: [01_产品设计维度](../../02_战略维度/产品设计/01_产品设计维度.md)
> - **原子能力**: [09_核心模块架构规约](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md)（Module A）、[ClassifierOutput Proto](../../03_原子目标与规约/_Design_Artifacts/protocols/classifier/classifier_output.proto)
> - **阶段**: [Phase1_按模块实践](README.md)

**本步设计文档**：[01_ModuleA设计](../../03_原子目标与规约/Stage3_模块实践/01_ModuleA设计.md#design-stage3-01-exit)  
**本步 DNA 文件**：[03_原子目标与规约/_System_DNA/Stage3_模块实践/dna_stage3_01.yaml](../../03_原子目标与规约/_System_DNA/Stage3_模块实践/dna_stage3_01.yaml)

<a id="l4-step-nav"></a>
## 步骤导航
- **上一步**：[05_采集模块部署与验收](../Stage2_数据采集与存储/05_采集模块部署与验收.md#l4-stage2-05-goal)
- **下一步**：[02_ModuleB](02_ModuleB.md#l4-stage3-02-goal)

<a id="l4-stage3-01-goal"></a>
## 步骤目标

实现 Module A 语义分类器，满足 09_ 规约的输入/输出与分类规则；完成 **四项 100% 验证**（接口、结构、逻辑功能、代码测试）。

## 本步骤落实的 DNA 键

- `core_modules/dna_module_a.yaml`：`module_a_semantic_classifier.purpose`、`input`、`output`、`classification_rules`

## 实现部分

**工作目录**：`diting-core`

1. 建立 `diting/classifier` 包，实现 `SemanticClassifier`
2. 接口：输入标的代码、申万行业、营收占比；输出 `ClassifierOutput`（Domain Tag 列表 + 置信度）
3. 分类规则写入 **YAML 配置**（不硬编码），路径如 `config/classifier_rules.yaml`
4. 从 L1/L2 或 MarketDataFeed 读取真实行业/营收数据（s0_data 准出后）

## 验证部分

### 四项 100%

| 维度 | 验收标准 | 验证方法 |
|------|----------|----------|
| **接口 100%** | 输出符合 ClassifierOutput.proto；可被 B/D 消费 | Proto 生成代码、接口契约单测 |
| **结构 100%** | 目录、配置路径与 DNA 一致 | 目录存在性、config 可加载 |
| **逻辑功能 100%** | 规则由 YAML 驱动；用真实市场数据跑通 | 配置变更验证、真实标的分类结果 |
| **代码测试 100%** | 单测覆盖分类规则、边界、UNKNOWN 路径 | `make test` 或 `pytest` 覆盖率 ≥ 约定 |

### 三层验证

- **单模块**：用真实标的（如 000998.SZ、中芯国际、紫金矿业）验证分类结果
- **联动**：A 输出作为 B/D 输入，接口对接验证
- **全链路**：Module F 完成后参与 A→F 全链路验证

## 核心指令（The Prompt）

```
你是在 diting-core 中实现 Module A 语义分类器的开发者。必读：03_原子目标与规约/_共享规约/09_核心模块架构规约.md（Module A 小节）、03_原子目标与规约/_System_DNA/core_modules/dna_module_a.yaml、ClassifierOutput.proto。

任务：1. 实现 SemanticClassifier，输出符合 ClassifierOutput；2. 分类规则写 config/classifier_rules.yaml；3. 单测覆盖 AGRI/TECH/GEO/UNKNOWN；4. 用真实标的验证（若 s0_data 已准出）。

工作目录：diting-core。约束：规则不硬编码；代码含 [Ref: 01_ModuleA]。
输出：变更列表、关键接口、单测命令与通过摘要。
```

## 验收与测试

- [ ] 接口 100%：ClassifierOutput 契约满足
- [ ] 结构 100%：diting/classifier、config 存在
- [ ] 逻辑功能 100%：YAML 驱动 + 真实数据验证
- [ ] 代码测试 100%：`make test` 通过、覆盖率达标

**可执行验证**（工作目录：`diting-core`）：
```bash
make test
# 或：pytest diting/classifier -v --cov=diting.classifier
```

<a id="l4-stage3-01-exit"></a>
## 本步骤准出（DoD）

- 代码已提交；单测全绿；L5 功能验收表 [l5-mod-A](../../05_成功标识与验证/02_验收标准.md#l5-mod-A) 行与 [l5-stage-stage3_01](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage3_01) 已更新

## 本步骤失败时

- 单测不通过 → 核对 09_ 分类规则与 Proto
- 真实数据不可用 → 先用 Mock 验证接口与结构，标注待 s0_data 准出后补验
