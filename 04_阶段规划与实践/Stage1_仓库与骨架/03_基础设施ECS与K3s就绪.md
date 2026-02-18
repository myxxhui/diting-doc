# Stage1-03 基础设施 ECS 与 K3s 就绪

> [!NOTE] **[TRACEBACK] 步骤锚点**
> - **原子规约**: [_共享规约/02_三位一体仓库规约](../../03_原子目标与规约/_共享规约/02_三位一体仓库规约.md)、[02_基础设施与部署规约](../../03_原子目标与规约/开发与交付/02_基础设施与部署规约.md)
> - **DNA stage_id**: `stage1_03`
> - **本步设计文档**: [03_基础设施ECS与K3s设计](../../03_原子目标与规约/Stage1_仓库与骨架/03_基础设施ECS与K3s设计.md#design-stage1-03-exit)
> - **本步 DNA 文件**: [dna_stage1_03.yaml](../../03_原子目标与规约/_System_DNA/Stage1_仓库与骨架/dna_stage1_03.yaml)

<a id="l4-step-nav"></a>
## 步骤导航
- **上一步**：[02_核心接口与Proto占位](02_核心接口与Proto占位.md#l4-stage1-02-goal)
- **下一步**：[04_密钥与配置模板就绪](04_密钥与配置模板就绪.md#l4-stage1-04-goal)

## 工作目录

**diting-infra** 根目录

<a id="l4-stage1-03-goal"></a>
## 本步骤目标

deploy-engine 通过 Git 引用就绪；单一 YAML 部署配置就绪；执行 Up 产出 ECS+K3s；验证通过后**无论成败均执行 Down 回收**资源（含竞价 ECS）。

## 本步骤落实的 _System_DNA 键

| DNA 键 | 用途 |
|--------|------|
| `dna_dev_workflow.workflow_stages[stage1_03]` | delivery_scope、exit_criteria、work_dir、verification_commands、l5_stage_anchor |
| `global_const.trinity_repos.repo_a` | config 结构、deploy-engine 引用约定 |

## 核心指令

```
你是在 diting-infra 中执行 Stage1-03（基础设施 ECS 与 K3s 就绪）的实践者。必读：03_原子目标与规约/_共享规约/02_三位一体仓库规约.md、03_原子目标与规约/开发与交付/02_基础设施与部署规约.md。

任务：
1. 确认 deploy-engine 以 Git submodule 或等价方式存在于 diting-infra，且调用约定（工作目录、config 路径）已满足。
2. 确认 config/environments/dev/deploy.yaml（或约定路径）存在且符合 DeploymentConfig 结构。
3. 按约定执行 deploy-engine Up（或 make deploy-dev 等），产出 ECS+K3s 集群；验证 KubeConfig 可用、kubectl get nodes 成功。
4. 验证完成后，无论通过与否，执行 deploy-engine Down（或 make down），回收部署与基础资源（含竞价实例 ECS）。
```

<a id="l4-stage1-03-exit"></a>
## 验证与准出

| 检查 | 工作目录 | 期望结果 |
|------|----------|----------|
| deploy-engine 可调用、config 路径正确 | diting-infra | Up 命令可执行 |
| Up 后 KUBECONFIG 指向产出、kubectl get nodes | diting-infra | 退出码 0，节点列表可见 |
| **准出前执行 Down** | diting-infra | Down 成功，资源已释放 |

**准出**：Up 成功且验证通过；**已执行 Down 回收**；**已更新 L5 [02_验收标准 对应行](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage1_03)**。

## 本步骤失败时

- **回退目标**：执行 Down 回收后，回退到上一阶段最后一步（Stage1-02 准出）。
- **重试**：建议重试上限 3 次；仍失败则执行 Down 后按回退目标处理。
- **临时跳过**：须架构师或项目负责人审批；具体回退操作见 [03_ 工作流详细规划 八、失败与回退策略](../../03_原子目标与规约/开发与交付/03_项目全功能开发测试实践工作流详细规划.md)。
