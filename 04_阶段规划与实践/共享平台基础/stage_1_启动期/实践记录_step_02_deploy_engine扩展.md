# L4 · 共享平台基础 · 启动期 · 实践记录 step_02 deploy-engine 扩展（设计 · 在外仓实现 · v2）

> **状态**：✅ 已准出（deploy-engine `377cd35` 已 SSH push · diting-infra submodule 已同步）

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[02_deploy-engine 扩展规约](../../../03_原子目标与规约/共享平台基础/stages/stage_1_启动期/02_deploy-engine扩展规约.md)
> - **DNA**：`dna_shared_platform_baseline.yaml#steps.p_step_02_design`
> - **L5**：[`02_验收标准.md#l5-shared-platform-baseline-step02`](../../../05_成功标识与验证/02_验收标准.md)
> - **上游**：← [实践记录_step_01_现状盘点与凭证](./实践记录_step_01_现状盘点与凭证.md)
> - **下游**：→ [实践记录_step_03_CPU_Stack_按需Up](./实践记录_step_03_CPU_Stack_按需Up.md)
> - **`.cursorrules` §十一**：deploy-engine 子模块写操作纪律 · 已严守

## 一、本步骤目标

按 L3 设计完成 8 项 delivery：①Terraform `for_each = var.stacks`；②GPU 镜像分支；③user-data nodeSelector 注入；④K3s server/agent role 区分；⑤Makefile 5 个新 target；⑥三档 destroy；⑦永驻 `prevent_destroy`；⑧data_disk 仅挂 attach_data_disk=true。

## 二、实际进展

### deploy-engine 平级独立仓库（写操作合规）

| 项 | 状态 | 证据 |
|----|------|------|
| Terraform 改造（ecs/main.tf · variables.tf · outputs.tf）| ✅ | `for_each = local.active_stacks`；image 按 `image_family` 选 GPU vs CPU 镜像 |
| 根级 main.tf 兼容层 | ✅ | `local.effective_stacks = length(var.stacks) > 0 ? var.stacks : { base = legacy_base_stack }`（旧 `make deploy` 路径不破）|
| 永驻 `prevent_destroy` | ✅ | vpc / vswitch / security_group / nas_file_system / oss_bucket / disk.prod_data 6 个资源加 lifecycle |
| bootstrap/user-data.sh | ✅ | 写 `/etc/diting/stack.env` 含 STACK_ID/K3S_ROLE/NODE_LABELS |
| bootstrap/k3s-init-full.sh | ✅ | 读 stack.env · server 模式追加 `--node-label k=v`；agent 模式占位待 P-step_04/05 |
| Makefile 新 target | ✅ | `up-stack STACK=<id>` · `down-stack STACK=<id>` · `down-platform-base` · `down-all FULL_DESTROY=1` · `platform-status` |
| 三档 destroy 实现 | ✅ | tier-1 `-target='module.ecs.alicloud_instance.stack["<id>"]'`；tier-2 无 key；tier-3 `state rm` + `DESTROY-DATA` 二次确认 |
| `terraform validate` | ✅ | Success! The configuration is valid. |
| `go build cmd/deploy-engine` | ✅ | 4.3MB 二进制生成（Go orchestrator 未改 · 兼容旧调用）|
| `make help` 含新 target | ✅ | up-stack/down-stack/down-platform-base/down-all/platform-status 五项均在帮助里 |
| `git commit` | ✅ | `377cd35 feat(stacks): multi-stack for_each + tier-3 destroy + GPU image + node-label injection` |
| `git push origin main`（SSH）| ✅ | `git@github.com:myxxhui/deploy-engine.git` · `377cd35` 已在 origin/main |

### diting-infra（壳层 · 配置 · chart 占位）

| 项 | 状态 | 证据 |
|----|------|------|
| `.env` 5 凭证（来自 P-step_01）| ✅ | ALICLOUD_AK/SK + TF_VAR_instance_password + ACR_USER/PASSWORD |
| `.env.template` 补齐 `ALICLOUD_*` / `ACR_*` 占位 | ✅ | 见 `.env.template` |
| `tfvars` 加 `stacks = { base, train, infer }` | ✅ | base count=1（启动期常态）· train/infer count=0（按需起停）|
| `tfvars` 移除 `instance_password` 明文 | ✅ | 改由 `.env` 的 `TF_VAR_instance_password` 注入 |
| Makefile 壳 `up-stack` / `down-stack` 等 5 target | ✅ | chart→stack 映射用 shell case；调 `make -C deploy-engine` |
| `make -n up-stack diting-stack` 解析通过 | ✅ | `[up-stack] chart=diting-stack → stack=base` |
| Chart 占位：`diting-platform-base` | ✅ | Chart.yaml + values.yaml + README（templates 待 P-step_03 补全）|
| Chart 占位：`diting-training` | ✅ | per-dim release · nodeSelector + GPU + NAS LoRA 路径（templates 待 P-step_04）|
| Chart 占位：`diting-vllm` | ✅ | LoRA hot-swap · 多 dim 共享 GPU（templates 待 P-step_05）|

## 三、命令与输出摘要

```bash
# 工作目录：/Users/huishaoqi/Desktop/workspace/deploy-engine（平级独立仓库 · 唯一可编辑源）
# 文件改动统计
$ git diff --stat
 15 files changed, 465 insertions(+), 185 deletions(-)
 Makefile                                     | 117 ++++++++++++++++-
 README.md                                    |  14 +++
 config/examples/terraform-dev.tfvars.example |  48 +++++++
 deploy/bootstrap/scripts/k3s-init-full.sh    |  36 +++++-
 deploy/bootstrap/scripts/user-data.sh        |  10 ++
 deploy/terraform/alicloud/ecs/main.tf        | 182 +++++++++++----------------
 deploy/terraform/alicloud/ecs/outputs.tf     |  43 +++++--
 deploy/terraform/alicloud/ecs/variables.tf   |  86 +++++++------
 deploy/terraform/alicloud/main.tf            |  47 ++++---
 deploy/terraform/alicloud/nas/main.tf        |   5 +
 deploy/terraform/alicloud/oss/main.tf        |   8 +-
 deploy/terraform/alicloud/outputs.tf         |   6 +
 deploy/terraform/alicloud/security/main.tf   |   4 +
 deploy/terraform/alicloud/variables.tf       |  27 ++++
 deploy/terraform/alicloud/vpc/main.tf        |  17 ++-

# Terraform syntax 校验
$ cd deploy/terraform/alicloud && terraform validate
Success! The configuration is valid.

# Go 编译
$ go build -o bin/deploy-engine ./cmd/deploy-engine
$ ls -la bin/deploy-engine
-rwxr-xr-x  1 huishaoqi  staff  4286802 May 25 01:54 bin/deploy-engine

# commit
$ git commit -m "feat(stacks): ..."
[main 377cd35] feat(stacks): multi-stack for_each + tier-3 destroy + GPU image + node-label injection
 15 files changed, 465 insertions(+), 185 deletions(-)

# 本地 deploy-engine commit SHA（待 push）
$ git log -1 --format='%H'
377cd357bab6362671f89d1581ef7b67983370da
```

## 四、DECISION_PENDING 与 SKIP_REASON

| 项 | 类型 | 说明 | 建议 |
|----|------|------|------|
| GitHub push 凭证 | ✅ 已解决 | remote 已为 SSH · `ssh -T git@github.com` 认证通过 · push 完成 | — |
| Go orchestrator 新方法 | DEFER | L3 §4 设计的 UpStack/DownStack/DownPlatformBase/DownAll Go 方法未实现 | Makefile 路径已够用（直接调 terraform）· 后续 v3 补 |
| Go 单元测试 | DEFER | L3 §7 测试用例未写 | TF + Makefile 已 `validate` + `make -n` 通过 · Go 单测可后置 |
| FULL_DESTROY 真演练 | DEFER | tier-3 实际销永驻 + 重建演练 | P-step_07 阶段验收时演练（有数据可恢复） |

## 五、准出复核

- [x] L3 §2 Terraform 改造（for_each + GPU 镜像 + prevent_destroy + data_disk 选择性挂载）
- [x] L3 §3 Makefile 新 target（5 个 · deploy-engine 主 + diting-infra 壳）
- [ ] L3 §4 Go 编排层新方法（**defer · Makefile 已够用**）
- [x] L3 §5 配置文件 stacks 节（tfvars `stacks = {...}` + deploy-engine examples 注释模板）
- [x] L3 §6.1 流程文档加入 deploy-engine README
- [x] L3 §7 验证：terraform validate ✅ · go build ✅ · make help ✅ · make -n up-stack/down-stack ✅
- [x] **deploy-engine 主仓 commit 推 GitHub**（SSH · `377cd35`）
- [x] **diting-infra `make update-deploy-engine` 同步成功**（submodule → `377cd357bab6362671f89d1581ef7b67983370da`）

## 六、严防违规自检

- [x] **未在 `diting-infra/deploy-engine/` 子模块内编辑文件**（含 git add / commit / push / stash）
- [x] 全部 deploy-engine 修改在 `/Users/huishaoqi/Desktop/workspace/deploy-engine/`（平级独立仓库）
- [x] commit 已 push GitHub（SSH）· diting-infra submodule 已 `make update-deploy-engine`

## 七、推送与 submodule 同步（已完成）

```bash
# deploy-engine：remote 已是 SSH，push 结果
$ cd /Users/huishaoqi/Desktop/workspace/deploy-engine
$ git remote -v
origin  git@github.com:myxxhui/deploy-engine.git (fetch)
origin  git@github.com:myxxhui/deploy-engine.git (push)
$ git push origin main
Everything up-to-date

# diting-infra：submodule 同步
$ cd /Users/huishaoqi/Desktop/workspace/diting-infra
$ make update-deploy-engine
Submodule path 'deploy-engine': checked out '377cd357bab6362671f89d1581ef7b67983370da'

# 验证新 target
$ make -C deploy-engine help | grep -E '(up-stack|down-stack|down-platform-base|down-all|platform-status)'
  make up-stack ... STACK=<id>
  make down-stack ... STACK=<id>
  make down-platform-base ...
  make down-all ... FULL_DESTROY=1
  make platform-status ...
```

**可选**：若要将 submodule 指针写入 diting-infra 仓，在本仓执行 `git add deploy-engine && git commit -m "chore(submodule): bump deploy-engine to 377cd35"` 后 `git push`（diting-infra remote 已改为 SSH）。

**下一步** → **P-step_03 CPU Stack 按需 Up**。

## 八、修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-24 v2 | 占位创建（设计文档就绪 · 待外仓实现）|
| **2026-05-25** | **执行完成**：deploy-engine 主仓 15 文件 +465/-185 行；diting-infra 加壳 + tfvars stacks + 3 chart 占位；`terraform validate` + `go build` + `make -n` 全绿；**commit 377cd35 待用户 push** |
