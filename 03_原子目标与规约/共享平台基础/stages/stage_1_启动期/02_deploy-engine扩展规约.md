# P-new-02 · deploy-engine 扩展规约（设计 · 实现在外仓 · v2）

> **本文档定位**：**设计规约 · 非实施 step**。给 deploy-engine 平级独立仓库提需求清单：支持 4 chart × 3 stack 矩阵 + 三档释放纪律 + GPU 镜像 + nodeSelector 注入。**实现地点**：`../deploy-engine/`（与 diting-infra 平级独立仓库 · 改完 push GitHub · diting-infra 跑 `make update-deploy-engine` 同步子模块）。
>
> **核心约束（必读 · 来自 .cursorrules §十一）**：
> - **禁止在 `diting-infra/deploy-engine/` 子模块内做任何写操作**（含编辑文件 · git add · commit · push · stash）。
> - **唯一允许的更新方式**：①在 deploy-engine **独立仓库**内编辑 → `git add/commit/push`；②在 diting-infra 中 `make update-deploy-engine`。

> [!NOTE] **[TRACEBACK]**
> - **P 轨入口**：[README](../../README.md)
> - **拓扑设计**：[01_平台拓扑设计](./01_平台拓扑设计.md)
> - **DNA 步骤定义**：[`shared/dna_shared_platform_baseline.yaml#steps[p_step_02_design]`](../../../_System_DNA/shared/dna_shared_platform_baseline.yaml)
> - **deploy-engine 子模块约定**：`.cursorrules` §十一「deploy-engine 子模块约定」
> - **L4 实践记录**：[实践记录_step_02_deploy_engine扩展](../../../../04_阶段规划与实践/共享平台基础/stage_1_启动期/实践记录_step_02_deploy_engine扩展.md)

---

## §1 设计目标

| # | 目标 | 影响范围 |
|---|------|---------|
| 1 | **多 stack ECS 模块**：用 `for_each = var.stacks` 取代 `count = 0/1`，按 `stack_id` 分组创建/销毁 | `deploy/terraform/alicloud/ecs/main.tf` |
| 2 | **GPU 镜像支持**：当 `stacks[].image_family == "ubuntu_22_04_gpu"` → 自动选 `^ubuntu_22_04_x64_100G_with_gpu_driver_and_cuda_alibase` 最新版 | `ecs/main.tf` 内 `data alicloud_images` 增加分支 |
| 3 | **nodeSelector label 注入**：user-data 模板从 `stacks[].node_labels` 渲染 K3s `--node-label k=v` 参数 | `bootstrap/scripts/user-data.sh` + `k3s-init-full.sh` |
| 4 | **K3s role 区分**：`stacks[].k3s_role` = `server` 或 `agent`；server 跑 K3s master，agent join master | `bootstrap/scripts/k3s-init-full.sh` |
| 5 | **三档 destroy**：tier-1 `target='module.ecs["<id>"]'` / tier-2 销所有 ECS 但保留永驻 / tier-3 全销含数据 | `Makefile` + Go 编排层 `pkg/orchestrator/workflow.go` |
| 6 | **永驻资源 10 项绝对不动**：tier-1/tier-2 都不动 VPC/SG/路由/网关 + NAS/独立盘/OSS | terraform `module.vpc/security/nas/oss` 全部 `lifecycle { prevent_destroy = true }`（仅 tier-3 时由 Makefile `terraform state rm` 后再 destroy） |
| 7 | **chart 名 → stack_id 映射**：deploy.yaml 或 stacks[] 内含 `chart_name` 字段 | `pkg/config/deploy_control.go` |
| 8 | **data_disk 仅挂 attach_data_disk=true 的 stack**（即仅 base）| `ecs/main.tf` 的 `alicloud_disk_attachment` 加 `for_each` 过滤 |

---

## §2 Terraform 改造（在 deploy-engine 独立仓库内）

### 2.1 `deploy/terraform/alicloud/variables.tf` 新增

```hcl
variable "stacks" {
  description = "多 stack 定义（按 stack_id 分组创建 ECS + EIP + 系统盘）"
  type = map(object({
    instance_type             = string
    spot_strategy             = string
    spot_price_limit          = number
    image_family              = string             # ubuntu_22_04 | ubuntu_22_04_gpu
    system_disk_gb            = number
    system_disk_category      = string
    attach_data_disk          = bool               # 仅 base = true
    k3s_role                  = string             # server | agent
    node_labels               = map(string)        # K3s --node-label
    enable_eip                = bool               # base 必 true · train/infer 可选
    count                     = number             # 通常 0 或 1
  }))
  default = {}
}
```

### 2.2 `deploy/terraform/alicloud/ecs/main.tf` 改造

```hcl
# 原 count = var.enable_spot ? 1 : 0 → for_each 按 stack_id
locals {
  active_stacks = { for k, s in var.stacks : k => s if s.count > 0 }
}

data "alicloud_images" "by_family" {
  for_each      = local.active_stacks
  owners        = "system"
  status        = "Available"
  most_recent   = true
  instance_type = each.value.instance_type
  name_regex = (
    each.value.image_family == "ubuntu_22_04_gpu"
      ? "^ubuntu_22_04_x64_100G_with_gpu_driver_and_cuda_alibase"
      : "^ubuntu_22_04_x64"
  )
}

resource "alicloud_instance" "stack" {
  for_each = local.active_stacks

  instance_name     = "${var.project_name}-${each.key}-${var.env_id}"
  instance_type     = each.value.instance_type
  image_id          = data.alicloud_images.by_family[each.key].images[0].id
  spot_strategy     = each.value.spot_strategy
  spot_price_limit  = each.value.spot_price_limit
  security_groups   = [var.security_group_id]
  vswitch_id        = var.vswitch_id
  password          = var.instance_password
  system_disk_category = each.value.system_disk_category
  system_disk_size     = each.value.system_disk_gb
  role_name            = var.ram_role_name != "" ? var.ram_role_name : null

  user_data = base64encode(templatefile(
    "${path.root}/../../bootstrap/scripts/user-data.sh",
    merge(var.user_data_vars, {
      stack_id    = each.key
      k3s_role    = each.value.k3s_role
      node_labels = join(",", [for k, v in each.value.node_labels : "${k}=${v}"])
      public_ip   = each.value.enable_eip ? try(alicloud_eip_address.stack[each.key].ip_address, "") : ""
    })
  ))

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-${each.key}-${var.env_id}"
    StackId = each.key
  })
}

resource "alicloud_eip_address" "stack" {
  for_each             = { for k, s in local.active_stacks : k => s if s.enable_eip }
  bandwidth            = var.eip_bandwidth
  internet_charge_type = "PayByTraffic"
  payment_type         = "PostPaid"
  lifecycle { ignore_changes = [payment_type] }
}

resource "alicloud_eip_association" "stack" {
  for_each      = { for k, s in local.active_stacks : k => s if s.enable_eip }
  allocation_id = alicloud_eip_address.stack[each.key].id
  instance_id   = alicloud_instance.stack[each.key].id
}

# 数据盘仅挂 attach_data_disk=true（即 base）
resource "alicloud_disk_attachment" "stack" {
  for_each    = { for k, s in local.active_stacks : k => s if s.attach_data_disk && var.data_disk_id != "" }
  instance_id = alicloud_instance.stack[each.key].id
  disk_id     = var.data_disk_id
}
```

### 2.3 永驻资源加 `prevent_destroy`（防误删）

```hcl
# deploy/terraform/alicloud/main.tf
module "vpc" {
  source = "./vpc"
  # ... 现有参数
}

# 在 vpc/main.tf 内对核心资源加 lifecycle
resource "alicloud_vpc" "main" {
  count = local.use_existing_vpc ? 0 : 1
  # ...
  lifecycle { prevent_destroy = true }  # 默认禁止销毁 · tier-3 由 Makefile state rm 后再销
}

# 同理：alicloud_vswitch, alicloud_security_group, alicloud_nas_*, alicloud_oss_bucket, alicloud_disk.prod_data
```

### 2.4 `bootstrap/scripts/user-data.sh` 模板变量

```bash
# 渲染时 templatefile 注入：${stack_id} ${k3s_role} ${node_labels}
STACK_ID="${stack_id}"
K3S_ROLE="${k3s_role}"
NODE_LABELS="${node_labels}"   # 形如 stack.diting/node=train,nvidia.com/gpu=present

# K3s 启动参数（在 k3s-init-full.sh 里）：
if [ "$K3S_ROLE" = "server" ]; then
  K3S_ARGS="server --write-kubeconfig-mode 644"
else
  K3S_ARGS="agent --server https://${K3S_MASTER_URL}:6443 --token ${K3S_TOKEN}"
fi

# 注入 node-label
for label in $(echo "$NODE_LABELS" | tr ',' ' '); do
  K3S_ARGS="$K3S_ARGS --node-label $label"
done
```

---

## §3 Makefile 改造（diting-infra · 不在 deploy-engine 内）

> **注意**：本节描述的 Makefile target 在 **`diting-infra/Makefile`** 添加（外层壳），实际逻辑调用 `deploy-engine` 的 `make` 或直接 `terraform apply/destroy`。

### 3.1 新 target 清单

| target | 调用 | 说明 |
|--------|------|------|
| `make up-stack <chart-name>` | 内部映射 chart → stack_id → terraform apply -target | 起对应 stack ECS + EIP + 系统盘 |
| `make down-stack <chart-name>` | helm uninstall + terraform destroy -target | 销对应 stack ECS · 保留永驻 |
| `make up-platform-base` | helm install diting-platform-base | 集群级一次装（需 base ECS 已起）|
| `make down-platform-base` | helm uninstall + terraform destroy 所有 module.ecs/eip | 销所有 ECS + 集群级 K8s · 保留 VPC/NAS/盘 |
| `make down-all FULL_DESTROY=1` | 二次确认 + state rm prevent_destroy + terraform destroy 全部 | 销 VPC + 数据 + 全部（仅永久退出）|
| `make platform-status` | terraform output + kubectl get nodes + helm list | 状态总览 |

### 3.2 chart → stack 映射逻辑

```makefile
# diting-infra/Makefile 内的映射函数
define chart_to_stack
$(if $(filter $1,diting-stack),base,\
$(if $(filter $1,diting-training),train,\
$(if $(filter $1,diting-vllm),infer,\
$(error 未知 chart: $1 · 支持: diting-stack/diting-training/diting-vllm))))
endef

up-stack:
	$(eval _STACK := $(call chart_to_stack,$(word 2,$(MAKECMDGOALS))))
	@cd $(DEPLOY_ENGINE_DIR) && \
	  terraform apply -target='alicloud_instance.stack["$(_STACK)"]' \
	                  -target='alicloud_eip_address.stack["$(_STACK)"]' \
	                  -auto-approve \
	                  -var-file="$(CONFIG_ROOT)/terraform-diting-prod.tfvars"

down-stack:
	$(eval _STACK := $(call chart_to_stack,$(word 2,$(MAKECMDGOALS))))
	$(eval _RELEASE := $(if $(filter $(word 2,$(MAKECMDGOALS)),diting-training),\
	  diting-train-cryo diting-train-thrust diting-train-narrative,\
	  $(word 2,$(MAKECMDGOALS))))
	$(eval _NS := $(call chart_to_ns,$(word 2,$(MAKECMDGOALS))))
	@for r in $(_RELEASE); do helm uninstall $$r -n $(_NS) 2>/dev/null || true; done
	@cd $(DEPLOY_ENGINE_DIR) && \
	  terraform destroy -target='alicloud_instance.stack["$(_STACK)"]' \
	                    -target='alicloud_eip_address.stack["$(_STACK)"]' \
	                    -auto-approve \
	                    -var-file="$(CONFIG_ROOT)/terraform-diting-prod.tfvars"
```

### 3.3 三档 destroy 实现要点

**tier-1（单 chart）**：
- 仅 `-target='alicloud_instance.stack["<stack_id>"]'` + `alicloud_eip_address.stack["<stack_id>"]'`
- **永驻资源不动**：VPC / SG / NAS / OSS / data_disk 不在 target 列表

**tier-2（platform-base）**：
- `helm uninstall` 所有业务 release
- `helm uninstall diting-platform-base`
- `terraform destroy -target='alicloud_instance.stack' -target='alicloud_eip_address.stack'`（无具体 key · 销所有 stack）
- **永驻资源不动**

**tier-3（FULL_DESTROY · 极少用）**：

```bash
down-all:
  @if [ "$(FULL_DESTROY)" != "1" ]; then echo "请用 FULL_DESTROY=1 启用"; exit 1; fi
  @echo "⚠️  此操作将销毁: VPC + 安全组 + NAS + 独立数据盘 + OSS（数据不可恢复）"
  @read -p "请输入 DESTROY-DATA 以确认: " CONFIRM; \
  [ "$$CONFIRM" = "DESTROY-DATA" ] || { echo "已取消"; exit 1; }
  @# 移除 prevent_destroy lifecycle（用 state rm + 重新 apply 无 prevent_destroy 的版本）
  @cd $(DEPLOY_ENGINE_DIR) && \
    terraform state rm alicloud_vpc.main alicloud_nas_file_system.main alicloud_oss_bucket.main alicloud_disk.prod_data 2>/dev/null; \
    terraform destroy -auto-approve -var-file="..."
```

---

## §4 Go 编排层改造（pkg/orchestrator/workflow.go）

新增方法（不替换现有 `Up()` / `Down()` · 兼容旧调用）：

```go
type StackOptions struct {
  StackID string  // base | train | infer
  Action  string  // up | down
}

// UpStack 起单个 stack（仅 ECS + EIP + 系统盘 · 复用 VPC/NAS/数据盘）
func (e *Engine) UpStack(ctx context.Context, cfg *config.DeploymentConfig, opts StackOptions) (*state.State, error) {
  // 调 Provider.Apply with -target='alicloud_instance.stack["<id>"]' ...
}

// DownStack 销单个 stack（保留永驻资源）
func (e *Engine) DownStack(ctx context.Context, s *state.State, opts StackOptions) error {
  // 调 Provider.Destroy with -target='alicloud_instance.stack["<id>"]' ...
}

// DownPlatformBase 销集群级 K8s + 所有残留 ECS（保留 VPC + 数据）
func (e *Engine) DownPlatformBase(ctx context.Context, s *state.State) error {
  // 1. helm uninstall 业务 release
  // 2. helm uninstall diting-platform-base
  // 3. terraform destroy -target='alicloud_instance.stack' -target='alicloud_eip_address.stack'
}

// DownAll FULL_DESTROY 实现（含 prevent_destroy 移除）
func (e *Engine) DownAll(ctx context.Context, s *state.State, confirmString string) error {
  if confirmString != "DESTROY-DATA" { return errors.New("二次确认未输入 DESTROY-DATA") }
  // ...
}
```

---

## §5 配置文件改造（diting-infra/config/diting-prod.yaml）

新增 `stacks` 节：

```yaml
# diting-infra/config/diting-prod.yaml 新增
stacks:
  base:
    instance_type: ecs.u1-c1m4.xlarge
    spot_strategy: SpotAsPriceGo
    spot_price_limit: 0.6
    image_family: ubuntu_22_04
    system_disk_gb: 60
    system_disk_category: cloud_essd
    attach_data_disk: true
    k3s_role: server
    node_labels:
      stack.diting/node: base
    enable_eip: true
    count: 1
    chart_name: diting-stack

  train:
    instance_type: ecs.gn6i-c4g1.xlarge
    spot_strategy: SpotAsPriceGo
    spot_price_limit: 3.0
    image_family: ubuntu_22_04_gpu
    system_disk_gb: 100
    system_disk_category: cloud_essd
    attach_data_disk: false
    k3s_role: agent
    node_labels:
      stack.diting/node: train
      nvidia.com/gpu: present
    enable_eip: false  # 启动期可不挂 EIP · 通过 base 节点 SSH 跳板
    count: 0   # 启动期 0 · make up-stack diting-training 时改为 1
    chart_name: diting-training

  infer:
    instance_type: ecs.gn6i-c4g1.xlarge
    spot_strategy: SpotAsPriceGo
    spot_price_limit: 3.0
    image_family: ubuntu_22_04_gpu
    system_disk_gb: 100
    system_disk_category: cloud_essd
    attach_data_disk: false
    k3s_role: agent
    node_labels:
      stack.diting/node: infer
      nvidia.com/gpu: present
    enable_eip: false
    count: 0
    chart_name: diting-vllm
```

> **配置驱动**：`make up-stack diting-training` 自动把 `stacks.train.count` 改为 1（或通过 TF_VAR 覆盖）。

---

## §6 工作流程（在 deploy-engine 独立仓库改 → 同步到 diting-infra）

### 6.1 正确流程（必读）

```bash
# Step 1: 在 deploy-engine 平级独立仓库内修改
cd /Users/<user>/Desktop/workspace/deploy-engine   # ← 平级独立仓库 · 唯一可编辑源
# 编辑 deploy/terraform/alicloud/ecs/main.tf
# 编辑 deploy/terraform/alicloud/variables.tf
# 编辑 bootstrap/scripts/user-data.sh
# 编辑 Makefile
# 编辑 pkg/orchestrator/workflow.go

# Step 2: 在独立仓库内 commit + push
git add deploy/ bootstrap/ Makefile pkg/
git commit -m "feat(stacks): for_each multi-stack + tier_3 destroy + GPU image + node-label injection"
git push origin main

# Step 3: 在 diting-infra 同步子模块
cd /Users/<user>/Desktop/workspace/diting-infra
make update-deploy-engine
git add deploy-engine    # 仅更新 submodule ref
git commit -m "chore(submodule): bump deploy-engine to <new-sha>"
```

### 6.2 禁止的操作（违规 · 见 .cursorrules §九）

```bash
# ❌ 禁止：在 diting-infra/deploy-engine/ 子模块内做任何写操作
cd diting-infra/deploy-engine
vim deploy/terraform/alicloud/ecs/main.tf   # ❌ 违规
git add . && git commit                     # ❌ 违规
git stash                                   # ❌ 违规（会污染子模块拷贝）
```

---

## §7 验证（集成测试 · 在 deploy-engine 独立仓库内跑）

```bash
cd ../deploy-engine

# 1. Terraform plan 校验（不真起）
terraform plan -var-file=config/examples/terraform-prod.tfvars.example \
               -target='alicloud_instance.stack["base"]'
terraform plan ... -target='alicloud_instance.stack["train"]'
terraform plan ... -target='alicloud_instance.stack["infer"]'

# 2. Go 单元测试
go test ./pkg/orchestrator/... -run TestUpStack
go test ./pkg/orchestrator/... -run TestDownStack
go test ./pkg/orchestrator/... -run TestDownAll_RequiresConfirmation

# 3. Makefile 检查
make help | grep -E '(up-stack|down-stack|down-platform-base|down-all)'

# 4. 在 diting-infra 验证 make help 也能看到
cd ../diting-infra
make update-deploy-engine
make help | grep -E '(up-stack|down-stack|down-platform-base|down-all)'
```

---

## §8 准出（Exit Criteria）

- [ ] §2 Terraform 改造完成（for_each stacks + GPU 镜像选择 + prevent_destroy）
- [ ] §3 Makefile 新 target（up-stack/down-stack/up-platform-base/down-platform-base/down-all）实现
- [ ] §4 Go 编排层新方法实现 + 单测通过
- [ ] §5 配置文件 stacks 节示例已加 config/examples/
- [ ] §6.1 流程文档已加入 deploy-engine README
- [ ] §7 验证全部通过
- [ ] deploy-engine 主仓 commit 已推 GitHub
- [ ] diting-infra `make update-deploy-engine` 成功同步且 `make help` 含新 target

---

## §9 修订记录

| 日期 | 变更 |
|------|------|
| **2026-05-24 v2** | 新增本规约（4 chart + 3 stack + 三档 destroy + GPU 镜像 + nodeSelector 注入 + 永驻 prevent_destroy + 在外仓改流程）|
