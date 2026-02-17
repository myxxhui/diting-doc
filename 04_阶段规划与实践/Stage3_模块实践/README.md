# Stage3 模块实践

> [!NOTE] **[TRACEBACK] 阶段实践锚点**
> - **原子规约**: [_共享规约/09_核心模块架构规约](../../03_原子目标与规约/_共享规约/09_核心模块架构规约.md)
> - **设计**: 03_原子目标与规约/Stage3_模块实践/
> - **DNA**: _System_DNA/core_modules/、global_const.deployable_units

## 定位与目标

按 **Module A/B/C/D/E/F** 拆分为 6 份独立实践文档 + 07_全链路验证，每份强制 **四项 100% 验证**：接口、结构、逻辑功能（配置驱动+真实数据）、代码测试。建立 **单模块 → 联动 → 全链路** 递进验证体系。实盘多服务部署时，**可部署单元**为：Module A、Module B、Module C、**热路径 D+E+F**（同进程同镜像）；每单元具备 实现 → Dockerfile → 本地测试 → 镜像 → 部署 → 连调 链，见 `global_const.deployable_units` 与 `dna_dev_workflow.deployable_units`。

## 可部署单元与步骤索引

| 可部署单元 | 步骤文档 | 设计 | DNA |
|------------|----------|------|-----|
| Module A | [01_ModuleA](./01_ModuleA.md) | 09_ Module A、可部署单元清单 | deployable_units.module_a、dna_module_a.yaml |
| Module B | [02_ModuleB](./02_ModuleB.md) | 09_ Module B | deployable_units.module_b、dna_module_b.yaml |
| Module C | [03_ModuleC](./03_ModuleC.md) | 09_ Module C | deployable_units.module_c、dna_module_c.yaml |
| 热路径 D+E+F | [04_ModuleD](./04_ModuleD.md)、[05_ModuleE](./05_ModuleE.md)、[06_ModuleF](./06_ModuleF.md) | 09_ 可部署单元与热路径 | deployable_units.hot_path_def、dna_module_d/e/f.yaml |
| 全链路 | [07_全链路验证](./07_全链路验证.md) | - | make test |

**热路径**：04_～06_ 为 D、E、F 的实现步骤；交付物合并为**同一镜像**（diting-hot-path），构建/部署/连调按 `deployable_units.hot_path_def` 执行。

## 步骤列表

| 步骤 | 文档 | 对应 DNA |
|------|------|----------|
| 1 | [01_ModuleA](./01_ModuleA.md) | core_modules/dna_module_a.yaml |
| 2 | [02_ModuleB](./02_ModuleB.md) | core_modules/dna_module_b.yaml |
| 3 | [03_ModuleC](./03_ModuleC.md) | core_modules/dna_module_c.yaml |
| 4 | [04_ModuleD](./04_ModuleD.md) | core_modules/dna_module_d.yaml |
| 5 | [05_ModuleE](./05_ModuleE.md) | core_modules/dna_module_e.yaml |
| 6 | [06_ModuleF](./06_ModuleF.md) | core_modules/dna_module_f.yaml |
| 7 | [07_全链路验证](./07_全链路验证.md) | make test |

### 本阶段步骤索引

| 步骤 | 标题 | 链接（本步目标） |
|------|------|------------------|
| 01 | ModuleA | [01_ModuleA](01_ModuleA.md#l4-stage3-01-goal) |
| 02 | ModuleB | [02_ModuleB](02_ModuleB.md#l4-stage3-02-goal) |
| 03 | ModuleC | [03_ModuleC](03_ModuleC.md#l4-stage3-03-goal) |
| 04 | ModuleD | [04_ModuleD](04_ModuleD.md#l4-stage3-04-goal) |
| 05 | ModuleE | [05_ModuleE](05_ModuleE.md#l4-stage3-05-goal) |
| 06 | ModuleF | [06_ModuleF](06_ModuleF.md#l4-stage3-06-goal) |
| 07 | 全链路验证 | [07_全链路验证](07_全链路验证.md#l4-stage3-07-goal) |

## 开发期连调

本地运行一个或多个模块（如仅 Module A），连接**远程 K3s** 的 DB/Redis/其它已部署服务，使用**线上或类生产数据**联调；准入与验证见各步骤文档或 [03_ 工作流详细规划](../../03_原子目标与规约/开发与交付/03_项目全功能开发测试实践工作流详细规划.md)。

## 依赖

- **准入**：Stage2 准出（数据采集与 L1/L2 可用）
