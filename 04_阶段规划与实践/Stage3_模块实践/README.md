# Stage3 模块实践

> [!NOTE] **[TRACEBACK] 阶段实践锚点**
> - **原子规约**: [_共享规约/09_核心模块架构规约](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md)
> - **设计**: 03_原子目标与规约/Stage3_模块实践/
> - **DNA**: _System_DNA/core_modules/、global_const.deployable_units

## 定位与目标

按**可部署单元**拆分为 5 步：**语义分类器**（Module A）、**量化扫描引擎**（Module B）、**MoE 议会**（Module C）、**热路径判官风控与执行**（D+E+F 同进程同镜像）、**全链路验证**。每步强制 **四项 100% 验证**：接口、结构、逻辑功能、代码测试。实盘可部署单元为：Module A、Module B、Module C、**热路径 D+E+F**（同进程同镜像），见 `global_const.deployable_units` 与 `dna_dev_workflow.deployable_units`。

## 可部署单元与步骤索引

| 可部署单元 | 步骤文档 | 设计 | DNA |
|------------|----------|------|-----|
| 语义分类器（Module A） | [01_语义分类器_实践](./01_语义分类器_实践.md) | 09_ Module A | deployable_units.module_a、dna_module_a.yaml |
| 量化扫描引擎（Module B） | [02_量化扫描引擎_实践](./02_量化扫描引擎_实践.md) | 09_ Module B | deployable_units.module_b、dna_module_b.yaml |
| MoE 议会（Module C） | [03_MoE议会_实践](./03_MoE议会_实践.md) | 09_ Module C | deployable_units.module_c、dna_module_c.yaml |
| 热路径 D+E+F | [04_热路径判官风控与执行_实践](./04_热路径判官风控与执行_实践.md) | 09_ 可部署单元与热路径 | deployable_units.hot_path_def、dna_module_d/e/f.yaml |
| 全链路验证 | [05_全链路验证_实践](./05_全链路验证_实践.md) | - | make test |

**热路径**：判官（D）+ 风控（E）+ 执行（F）在一个实践步骤内完成，交付**同一镜像**（diting-hot-path），构建/部署/连调按 `deployable_units.hot_path_def` 执行。

## 步骤列表

| 步骤 | 文档 | 对应 DNA |
|------|------|----------|
| 1 | [01_语义分类器_实践](./01_语义分类器_实践.md) | core_modules/dna_module_a.yaml |
| 2 | [02_量化扫描引擎_实践](./02_量化扫描引擎_实践.md) | core_modules/dna_module_b.yaml |
| 3 | [03_MoE议会_实践](./03_MoE议会_实践.md) | core_modules/dna_module_c.yaml |
| 4 | [04_热路径判官风控与执行_实践](./04_热路径判官风控与执行_实践.md) | 04_dna_热路径判官风控与执行.yaml、dna_module_d/e/f.yaml |
| 5 | [05_全链路验证_实践](./05_全链路验证_实践.md) | make test |

### 本阶段步骤索引

| 步骤 | 标题 | 链接（本步目标） |
|------|------|------------------|
| 01 | 语义分类器 | [01_语义分类器_实践](01_语义分类器_实践.md#l4-stage3-01-goal) |
| 02 | 量化扫描引擎 | [02_量化扫描引擎_实践](02_量化扫描引擎_实践.md#l4-stage3-02-goal) |
| 03 | MoE 议会 | [03_MoE议会_实践](03_MoE议会_实践.md#l4-stage3-03-goal) |
| 04 | 热路径判官风控与执行 | [04_热路径判官风控与执行_实践](04_热路径判官风控与执行_实践.md#l4-stage3-04-goal) |
| 05 | 全链路验证 | [05_全链路验证_实践](05_全链路验证_实践.md#l4-stage3-05-goal) |

## 开发期连调

本地运行一个或多个模块（如仅语义分类器），连接**远程 K3s** 的 DB/Redis/其它已部署服务，使用**线上或类生产数据**联调；准入与验证见各步骤文档或 [03_ 工作流详细规划](../../03_原子目标与规约/开发与交付/03_项目全功能开发测试实践工作流详细规划.md)。

## 依赖

- **准入**：Stage2 准出（数据采集与 L1/L2 可用）
