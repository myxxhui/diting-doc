# Stage3 模块实践

> [!NOTE] **[TRACEBACK] 阶段实践锚点**
> - **原子规约**: [_共享规约/09_核心模块架构规约](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md)
> - **设计**: 03_原子目标与规约/Stage3_模块实践/
> - **DNA**: _System_DNA/core_modules/、global_const.deployable_units

## 定位与目标

按**可部署单元**拆分为 **6 步**：**语义分类器**（Module A）、**B 模块策略设计/实践/验证/优化**（策略层）、**量化扫描引擎**（Module B 执行层）、**MoE 议会**（Module C）、**热路径判官风控与执行**（D+E+F 同进程同镜像）、**全链路验证**。每步强制 **四项 100% 验证**（或步骤约定占位）：接口、结构、逻辑功能、代码测试。实盘可部署单元为：Module A、Module B、Module C、**热路径 D+E+F**（同进程同镜像），见 `global_const.deployable_units` 与 `dna_dev_workflow.deployable_units`。

## 可部署单元与步骤索引

| 可部署单元 | 步骤文档 | 设计 | DNA |
|------------|----------|------|-----|
| 语义分类器（Module A） | [01_A轨_语义分类器_实践](01_A轨_语义分类器_实践.md) | 09_ Module A | deployable_units.module_a、dna_module_a.yaml |
| B 模块策略（策略层） | [02_A轨_B模块策略_实践](02_A轨_B模块策略_实践.md) | 02_A轨_B模块策略_设计 | 02_dna_B模块策略.yaml |
| 量化扫描引擎（Module B） | [03_A轨_量化扫描引擎_实践](03_A轨_量化扫描引擎_实践.md) | 09_ Module B、02_B模块策略_策略实现规约 | deployable_units.module_b、dna_module_b.yaml、03_dna_量化扫描引擎.yaml |
| MoE 议会（Module C） | [04_A轨_MoE议会_实践](04_A轨_MoE议会_实践.md) | 09_ Module C | deployable_units.module_c、dna_module_c.yaml |
| 热路径 D+E+F | [05_A轨_热路径判官风控与执行_实践](05_A轨_热路径判官风控与执行_实践.md) | 09_ 可部署单元与热路径 | deployable_units.hot_path_def、dna_module_d/e/f.yaml |
| 全链路验证 | [06_A轨_全链路验证_实践](06_A轨_全链路验证_实践.md) | - | make test |
| **B 轨** 语义与候选 | [01_B轨_语义与候选_实践](01_B轨_语义与候选_实践.md) | 03_/B轨/01_B轨系统设计、02_B轨数据与存储 | dna_b_track.yaml |

**热路径**：判官（D）+ 风控（E）+ 执行（F）在一个实践步骤内完成，交付**同一镜像**（diting-hot-path），构建/部署/连调按 `deployable_units.hot_path_def` 执行。

## 步骤列表

| 步骤 | 轨 | 文档 | 对应 DNA |
|------|-----|------|----------|
| 1 | A | [01_A轨_语义分类器_实践](01_A轨_语义分类器_实践.md) | core_modules/dna_module_a.yaml |
| 2 | A | [02_A轨_B模块策略_实践](02_A轨_B模块策略_实践.md) | 02_dna_B模块策略.yaml |
| 3 | A | [03_A轨_量化扫描引擎_实践](03_A轨_量化扫描引擎_实践.md) | core_modules/dna_module_b.yaml、03_dna_量化扫描引擎.yaml |
| 4 | A | [04_A轨_MoE议会_实践](04_A轨_MoE议会_实践.md) | core_modules/dna_module_c.yaml |
| 5 | A | [05_A轨_热路径判官风控与执行_实践](05_A轨_热路径判官风控与执行_实践.md) | 05_dna_热路径判官风控与执行.yaml、dna_module_d/e/f.yaml |
| 6 | A | [06_A轨_全链路验证_实践](06_A轨_全链路验证_实践.md) | make test |
| 01 | B | [01_B轨_语义与候选_实践](01_B轨_语义与候选_实践.md) | _System_DNA/B轨/dna_b_track.yaml |

### 本阶段步骤索引

| 步骤 | 轨 | 标题 | 链接（本步目标） |
|------|-----|------|------------------|
| 01 | A | 语义分类器 | [01_A轨_语义分类器_实践](01_A轨_语义分类器_实践.md#l4-stage3-01-goal) |
| 02 | A | B模块策略设计/实践/验证/优化 | [02_A轨_B模块策略_实践](02_A轨_B模块策略_实践.md#l4-stage3-02-goal) |
| 03 | A | 量化扫描引擎 | [03_A轨_量化扫描引擎_实践](03_A轨_量化扫描引擎_实践.md#l4-stage3-03-goal) |
| 04 | A | MoE 议会 | [04_A轨_MoE议会_实践](04_A轨_MoE议会_实践.md#l4-stage3-04-goal) |
| 05 | A | 热路径判官风控与执行 | [05_A轨_热路径判官风控与执行_实践](05_A轨_热路径判官风控与执行_实践.md#l4-stage3-05-goal) |
| 06 | A | 全链路验证 | [06_A轨_全链路验证_实践](06_A轨_全链路验证_实践.md#l4-stage3-06-goal) |
| 01 | B | 语义与候选 | [01_B轨_语义与候选_实践](01_B轨_语义与候选_实践.md#l4-stage3-b01-goal) |

## 开发期连调

本地运行一个或多个模块（如仅语义分类器），连接**远程 K3s** 的 DB/Redis/其它已部署服务，使用**线上或类生产数据**联调；准入与验证见各步骤文档或 [03_ 工作流详细规划](../../03_原子目标与规约/开发与交付/03_项目全功能开发测试实践工作流详细规划.md)。

## 依赖

- **准入**：Stage2 准出（数据采集与 L1/L2 可用）
