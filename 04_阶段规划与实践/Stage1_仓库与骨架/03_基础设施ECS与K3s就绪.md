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

## 核心指令（动作唯一对齐本小节）

**工作目录**：diting-infra 根目录。以下动作为本步骤唯一对齐目标，diting-infra 的 Makefile/README 与本小节一致。

### 首次引入 deploy-engine（仅当尚未添加为 submodule 时执行）

- 若 diting-infra 下已存在 **deploy-engine 目录且不是 Git 仓库**（例如 Stage1-01 的占位目录），执行 `git submodule add` 会报错：`fatal: 'deploy-engine' already exists and is not a valid git repo`。
- **动作**：先删除该目录，再添加 submodule；其他仓勿臆造路径或命令。
  1. 在 diting-infra 根目录执行：`rm -rf deploy-engine`
  2. 执行：`git submodule add <deploy-engine-repo-url> deploy-engine`（将 `<deploy-engine-repo-url>` 替换为项目约定的仓库地址，如 `https://github.com/myxxhui/deploy-engine.git`）
  3. 提交 `.gitmodules` 与 `deploy-engine` 的 submodule 记录。
- 若 deploy-engine 已是 submodule，**跳过本段**，直接做「每次执行」动作。

### 按 deploy-engine 实践文档完成使用配置（必做，否则 Up 报错无预期配置）

**目标**：diting-infra 作为「通用项目引用 deploy-engine」时，配置全部放在业务仓，不修改 deploy-engine 仓库内任何文件。详见 **deploy-engine 仓库内** `docs/VERIFICATION.md` 第二节「二、通用项目引用 deploy-engine 实现部署」；在已克隆 diting-infra 且含有 deploy-engine 子模块时，该文件路径为 `deploy-engine/docs/VERIFICATION.md`（相对于 diting-infra 根目录）。

**约定**：deploy-engine 以**扁平 config 目录**读取配置（无更深层级）。diting-infra 的 **CONFIG_ROOT** = `config`（与根目录 Makefile 一致），三份**正式配置文件**直接放在 `config/` 下（勿直接使用 .example；从 deploy-engine 的 `config/examples/` 复制到 `config/` 并重命名）。

| 用途 | 文件名（config/ 下） | 来源（复制并重命名） |
|------|----------------------|------------------------|
| 部署配置 | `deploy.yaml` | `deploy-engine/config/examples/deploy.yaml.example` → `config/deploy.yaml` |
| Terraform 变量 | `terraform-diting-dev.tfvars` | `deploy-engine/config/examples/terraform-dev.tfvars.example` → `config/terraform-diting-dev.tfvars` |
| 环境 YAML | `diting-dev.yaml` | `deploy-engine/config/examples/default-dev.yaml.example` → `config/diting-dev.yaml` |

**操作示例**（在 diting-infra 根目录执行）：

```bash
cp deploy-engine/config/examples/deploy.yaml.example config/deploy.yaml
cp deploy-engine/config/examples/terraform-dev.tfvars.example config/terraform-diting-dev.tfvars
cp deploy-engine/config/examples/default-dev.yaml.example config/diting-dev.yaml
# 编辑 config/terraform-diting-dev.tfvars（region、instance_type 等）与 config/diting-dev.yaml（global.project_name、k3s.apiServer.domain）
```

若此前已使用 `config/environments/dev/`，请将上述三份文件移至 `config/` 并令 Makefile 的 CONFIG_ROOT 指向 `config`。

**敏感项**：`terraform-diting-dev.tfvars` 中的 **instance_password** 至少 8 位；建议使用环境变量 **TF_VAR_instance_password** 注入（执行 `make deploy-dev` 前 `export TF_VAR_instance_password="..."`），勿将真实密码提交到 Git。若不想将真实密码提交到 Git，可仅保留 tfvars 占位或将 `config/terraform-diting-dev.tfvars` 加入 `.gitignore`，统一使用 `export TF_VAR_instance_password` 注入。

**未完成时的表现**：若未按上表放置三份配置文件或未设置 instance_password，执行 `make deploy-dev` 会报错，例如「tfvars 不存在」或「instance_password 未设置」，导致 Up 无法通过；完成本段配置后，Up 仅受 Terraform/云凭证/网络等运行时条件约束。

### 每次执行本步骤时的动作顺序

每次执行 Stage1-03 时，**必须先更新 deploy-engine 代码，再执行后续任务**；命令与 diting-infra 根目录 Makefile 对齐。

| 顺序 | 动作 | 命令（在 diting-infra 根目录执行） | 说明 |
|------|------|-------------------------------------|------|
| 0 | 更新 deploy-engine 代码 | `make update-deploy-engine` 或 `git submodule update --init --remote deploy-engine` | 必做；失败则本步不继续 |
| 1 | 确认 deploy-engine 与 config | 确认 `deploy-engine/` 存在；且已按上文在 `config/` 下放置三份配置文件（deploy.yaml、terraform-diting-dev.tfvars、diting-dev.yaml） | 结构就绪，否则 Up 报错无预期配置 |
| 2 | Up（创建 ECS+K3s） | `make deploy-dev`（执行前需设置 `TF_VAR_instance_password` 或填写 tfvars 中的 instance_password；需 Terraform 与阿里云凭证） | 需 Terraform、云凭证与三份配置 |
| 3 | **执行成功后必做**：导出 KUBECONFIG 并验证 | 按终端输出的「使用方法」执行 `export KUBECONFIG=<提示中的路径>`（如 `export KUBECONFIG=~/.kube/config-diting-dev`），**确保当前终端**可连目标集群；然后执行 `kubectl get nodes` 验收集群，并检查 Chart 测试程序（如 deploy 中配置的 release）是否部署完成 | 未执行 export 则 kubectl 连不到目标集群；验收集群与部署完成后方可进入下一步 |
| 4 | Down（准出前必做） | `make down` | 无论 Up 成败均执行，回收资源 |

### 任务与规约引用

必读：03_原子目标与规约/_共享规约/02_三位一体仓库规约.md、03_原子目标与规约/开发与交付/02_基础设施与部署规约.md。diting-infra 的 Makefile 中 `CONFIG_ROOT` 指向扁平目录 `config`，project/env 与 deploy.yaml 中 `deployment_id` 一致（如 diting、dev）。

<a id="l4-stage1-03-exit"></a>
## 验证与准出

验证项与上文「核心指令（动作唯一对齐）」一致；命令以本实践文档为准，diting-infra 实现与之对齐。

| 检查 | 工作目录 | 命令/期望结果 |
|------|----------|----------------|
| **执行前**：deploy-engine 代码已更新 | diting-infra | `make update-deploy-engine` 或 `git submodule update --init --remote deploy-engine` 已执行且无报错 |
| 已按 deploy-engine 完成使用配置 | diting-infra | `config/` 下存在 deploy.yaml、terraform-diting-dev.tfvars、diting-dev.yaml（见上文「按 deploy-engine 完成使用配置」） |
| deploy-engine 可调用、config 路径正确 | diting-infra | `make deploy-dev` 可执行（CONFIG_ROOT 指向 config；已设置 TF_VAR_instance_password 或 tfvars 中 instance_password） |
| Up 后必做 export 并验证 | diting-infra | 按终端提示执行 `export KUBECONFIG=~/.kube/config-diting-dev`（或提示路径），当前终端执行 `kubectl get nodes` 退出码 0、节点可见；并确认 Chart 测试程序已部署完成 |
| **准出前执行 Down** | diting-infra | `make down` 成功，资源已释放 |

**准出**：Up 成功且验证通过；**已执行 Down 回收**；**已更新 L5 [02_验收标准 对应行](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage1_03)**。

### 准出后自检（执行方完成，无需读者再执行）

| 自检项 | 说明 |
|--------|------|
| Down 已结束 | 执行 `make down` 后确认终端出现 Terraform destroy 完成（或资源已释放），无报错。 |
| L5 与 06_ 已同步 | 已更新 [02_验收标准](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage1_03) 中 stage1_03 行及 [02_战略追溯矩阵](../../06_追溯与审计/02_战略追溯矩阵.md)「可交付性」行备注，标明本阶段已准出。 |
| 敏感信息（可选） | 若不想将真实密码提交到 Git，可仅保留 tfvars 中 `instance_password` 占位或将 `config/terraform-diting-dev.tfvars` 加入 `.gitignore`，统一使用 `export TF_VAR_instance_password="..."` 注入。 |

**本次实践已同步完成上述 L5 与 06_ 更新，无需再执行。**

## 本步骤失败时

- **回退目标**：执行 Down 回收后，回退到上一阶段最后一步（Stage1-02 准出）。
- **重试**：建议重试上限 3 次；仍失败则执行 Down 后按回退目标处理。
- **临时跳过**：须架构师或项目负责人审批；具体回退操作见 [03_ 工作流详细规划 八、失败与回退策略](../../03_原子目标与规约/开发与交付/03_项目全功能开发测试实践工作流详细规划.md)。
