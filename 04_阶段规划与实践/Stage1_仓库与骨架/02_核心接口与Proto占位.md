# Stage1-02 核心接口与 Proto 占位

> [!NOTE] **[TRACEBACK] 步骤锚点**
> - **原子规约**: [_共享规约/04_全链路通信协议矩阵](../../03_原子目标与规约/_共享规约/04_全链路通信协议矩阵.md)、[_共享规约/05_接口抽象层规约](../../03_原子目标与规约/_共享规约/05_接口抽象层规约.md)
> - **DNA stage_id**: `stage1_02`
> - **本步设计文档**: [02_核心接口与Proto设计](../../03_原子目标与规约/Stage1_仓库与骨架/02_核心接口与Proto设计.md#design-stage1-02-exit)
> - **本步 DNA 文件**: [dna_stage1_02.yaml](../../03_原子目标与规约/_System_DNA/Stage1_仓库与骨架/dna_stage1_02.yaml)

<a id="l4-step-nav"></a>
## 步骤导航
- **上一步**：[01_三位一体仓库初始化](01_三位一体仓库初始化.md#l4-stage1-01-goal)
- **下一步**：[03_基础设施ECS与K3s就绪](03_基础设施ECS与K3s就绪.md#l4-stage1-03-goal)

<a id="l4-stage1-02-goal"></a>
## 本步目标
核心接口与 Proto 占位；make test 通过。

## 工作目录

**diting-core** 根目录

## 本步骤落实的 DNA 键

`dna_dev_workflow.workflow_stages[stage1_02]`、`global_const.trinity_repos.repo_i`

## 核心指令

```
你是在 diting-core 中执行 Stage1-02（核心接口与 Proto 占位）的开发者。必读：dna_dev_workflow.workflow_stages[stage1_02]、04_全链路通信协议矩阵、05_接口抽象层规约。

任务：
1. 按 repo_i.directories 建立目录：diting/abstraction/、drivers/、moe/、risk/、strategy/、tests/、design/。
2. 定义核心接口（Protocol/抽象类），与 04_ 协议矩阵、05_ 接口抽象层对齐。
3. Proto 占位：brain/expert.proto、verdict.proto、execution/order.proto、classifier/classifier_output.proto、quant/quant_signal.proto。
4. 为关键接口编写占位实现或 Mock，使「导入 + 最小调用」可运行；make test 可运行。
```

<a id="l4-stage1-02-exit"></a>
## 验证与准出

| 命令 | 工作目录 | 期望结果 |
|------|----------|----------|
| `make test` | diting-core | 退出码 0；单测全绿 |

**准出**：核心接口存在且本地单测通过；**已更新 L5 [02_验收标准 对应行](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage1_02)**。
