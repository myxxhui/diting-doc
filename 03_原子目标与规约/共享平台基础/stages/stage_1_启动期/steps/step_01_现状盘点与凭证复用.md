# P-step_01 · 现状盘点与凭证复用（v2）

> **本步定位**：启动期前 30 min 类盘点 step。**不创建任何云资源**。核对现状 10 项永驻资源 ID + 凭证就绪 + 工具链就绪 + deploy-engine 子模块更新。**用户校正 v2**：之前 v1 的"DeployEngine 就绪与凭证"假设从零起，本 v2 修正为"复用现状 · 不重做"。

> [!NOTE] **[TRACEBACK]**
> - **P 轨入口**：[README](../../../README.md)
> - **拓扑设计 §7 现状资源 ID 清单**：[01_平台拓扑设计 §7](../01_平台拓扑设计.md#§7-现状资源-id-清单v2-复用而非重做)
> - **deploy-engine 子模块约定**：`.cursorrules` §十一「deploy-engine 子模块约定」
> - **DNA**：[`shared/dna_shared_platform_baseline.yaml#steps[p_step_01]`](../../../../_System_DNA/shared/dna_shared_platform_baseline.yaml)
> - **L4**：[实践记录_step_01_现状盘点与凭证](../../../../../04_阶段规划与实践/共享平台基础/stage_1_启动期/实践记录_step_01_现状盘点与凭证.md)

---

## §1 本步目标

<a id="l4-p-step_01-goal"></a>

| # | 目标 | 来源 |
|---|------|------|
| 1 | 核对现状 10 项**永驻资源** ID 与 `terraform-diting-prod.tfvars` 一致 | 拓扑设计 §7 |
| 2 | deploy-engine 子模块更新到独立仓最新（**必须** `make update-deploy-engine`） | `.cursorrules` §十一 |
| 3 | 凭证就绪：阿里云 AK/SK / TF_VAR_instance_password / ACR USER/PASSWORD / SSH 公钥 | — |
| 4 | 工具链就绪：terraform ≥1.5、helm ≥3.13、kubectl、yq、docker | DNA stack_versions |
| 5 | ACR docker login 通过 | — |

**预计耗时**：30 min。**成本**：¥0（不创建资源）。

---

## §2 前置条件

| # | 前置 | 检查命令 |
|---|------|---------|
| 1 | 本地已 git clone `diting-infra` 且其 `deploy-engine/` 为 git submodule | `ls diting-infra/deploy-engine/.git` |
| 2 | 本地已 git clone `deploy-engine` 平级独立仓库（与 diting-infra 平级）| `ls deploy-engine/Makefile` |
| 3 | 阿里云账号已开通 ECS / NAS / OSS / ACR 服务 | 控制台核对 |
| 4 | 当前开发本机出口 IP 已加入 `sg-j6cizfabvego0nem81c2` 安全组 6443 + 22 入站规则 | 控制台核对 |

---

## §3 工作目录

```bash
cd /Users/<user>/Desktop/workspace/diting-infra
# deploy-engine 写操作必须在平级独立仓库：
#   cd /Users/<user>/Desktop/workspace/deploy-engine  ← 仅此处可写
# 禁止：cd diting-infra/deploy-engine （子模块拷贝 · 任何写操作违规）
```

---

## §3.5 数据质量验收矩阵（凭证 / 工具链 / 现状清单）

| # | 检查项 | 验证方式 | 启动期标准 |
|---|--------|---------|-----------|
| C1 | 现状 VPC ID 匹配 | `grep vpc_existing_id config/terraform-diting-prod.tfvars` | `vpc-j6cuhmska9vfwqa6my16q` ✅ |
| C2 | 现状 VSwitch ID 匹配 | `grep vswitch_existing_id config/terraform-diting-prod.tfvars` | `vsw-j6ct3ymab1lxeqz38lbwi` ✅ |
| C3 | 现状安全组 ID 匹配 | `grep security_group_existing_id config/terraform-diting-prod.tfvars` | `sg-j6cizfabvego0nem81c2` ✅ |
| C4 | 现状 NAS 文件系统 ID 匹配 | `grep nas_existing_file_system_id config/terraform-diting-prod.tfvars` | `12db2e48f90` ✅ |
| C5 | 现状 NAS 挂载点域名匹配 | `grep nas_existing_mount_target_domain config/terraform-diting-prod.tfvars` | `12db2e48f90-hpy48.cn-hongkong.nas.aliyuncs.com` ✅ |
| C6 | 现状独立数据盘 ID 匹配 | `grep use_existing_data_disk_id config/terraform-diting-prod.tfvars` | `d-j6cc6ew2bqkfdlwaavit` ✅ |
| C7 | 现状 OSS bucket 匹配 | `grep oss_bucket_name config/terraform-diting-prod.tfvars` | `deploy-engine-k3s-storage` ✅ |
| C8 | 现状 ACR URL 匹配 | `grep -r 'crpi-7vifw4ok9jkcxr60' config/` | 1+ 命中 ✅ |
| C9 | .env 含必要凭证 | `[ -f .env ] && grep -cE '^(ALIYUN_AK\|ALIYUN_SK\|TF_VAR_instance_password\|ACR_USER\|ACR_PASSWORD)' .env` | 5 ✅ |
| C10 | .env 已 gitignore | `git check-ignore .env` 退码 0 | ✅ |
| T1 | terraform 版本 | `terraform version` | ≥1.5 ✅ |
| T2 | helm 版本 | `helm version --short` | ≥v3.13 ✅ |
| T3 | kubectl 版本 | `kubectl version --client` | ≥v1.28 ✅ |
| T4 | yq 版本 | `yq --version` | ≥v4 ✅ |
| T5 | docker 可用 | `docker info` | 退码 0 ✅ |
| D1 | deploy-engine 子模块为最新 main | `cd deploy-engine && git rev-parse HEAD` 与 `git ls-remote origin main` 一致 | ✅ |
| D2 | deploy-engine 平级独立仓库存在 | `ls ../deploy-engine/Makefile` | 存在 ✅ |
| L1 | ACR docker login 通过 | `docker login crpi-7vifw4ok9jkcxr60.cn-hongkong.personal.cr.aliyuncs.com` | Login Succeeded ✅ |

---

## §4 启动期数据量预期 / §4.1 用户凭证清单

| 凭证 | 来源 | 用途 |
|------|------|------|
| `ALIYUN_AK` / `ALIYUN_SK` | 阿里云 RAM 子账号 AccessKey | Terraform 调用阿里云 API |
| `TF_VAR_instance_password` | 用户自定义 ≥8 位 | ECS root 密码 |
| `ACR_USER` / `ACR_PASSWORD` | ACR 控制台 → 访问凭证 | docker login / kubectl secret |
| SSH 公钥（可选） | `~/.ssh/id_rsa.pub` | ECS SSH 排错 |
| 本机出口 IP | `curl ifconfig.me` | 安全组 6443/22 入站白名单 |

> 用户须提供：① `ALIYUN_AK/SK`（仅 RAM 子账号 + ECS/VPC/NAS/OSS 最小权限）；② `TF_VAR_instance_password`（≥8 位）；③ `ACR_USER/PASSWORD`（ACR 个人版账号密码）。
> 上述写入 `diting-infra/.env`（已在 `.gitignore`）。

---

## §5 启动期数据量预期

本步不涉及业务数据。仅核对 10 项永驻资源 ID 清单（见 §3.5 C1~C8 + 拓扑设计 §7）。

---

## §6 下一步

→ [P-new-02_deploy-engine 扩展规约](../02_deploy-engine扩展规约.md)：实现多 stack `for_each` + 三档 destroy（W1 · 0.5 day · 在 **deploy-engine 平级独立仓库** 修改）。

---

## §7 实施步骤（设计规划推演）

### 7.1 实现要点

| 实现要点 | 涉及位置 | 关键设计决策 | 验证标准 |
|---------|---------|-------------|---------|
| 现状盘点 | `config/terraform-diting-prod.tfvars` + `config/diting-prod.yaml` | 不重做 · 仅核对 | §3.5 C1~C8 全 ✅ |
| .env 创建与补全 | `diting-infra/.env`（gitignore）| 不入仓 | §3.5 C9~C10 ✅ |
| deploy-engine 子模块更新 | `git submodule update --init --remote deploy-engine` | submodule ref 跟 main | §3.5 D1 ✅ |
| 工具链检查 | `make help` 或单独 `which` | 缺则 brew install | §3.5 T1~T5 全 ✅ |
| ACR login | `docker login $ACR_REGISTRY -u $ACR_USER -p $ACR_PASSWORD` | 凭证可达 | §3.5 L1 ✅ |

### 7.2 Makefile 合约（diting-infra）

| target | 用途 | 入参 |
|--------|------|------|
| `update-deploy-engine` | 拉子模块最新（已有 · 沿用）| 无 |
| `platform-step01-check` | 一键跑 §3.5 全部 C/T/D/L 检查项 | 读 `.env` |

### 7.3 给后续执行模型的指引

- **禁止**：重新创建 VPC / NAS / 独立盘 / OSS（这些是永驻资源 · 现状已就绪）；
- **禁止**：在 `diting-infra/deploy-engine/` 子模块内做任何写操作（含编辑 · git add · commit · push · stash）；
- **若 C1~C8 任一不匹配**：先确认 tfvars 是否被改过（git log + git diff）→ 与团队同步现状是否真的变动 → 不要立即改 tfvars；
- **若 D1 子模块不是最新**：执行 `make update-deploy-engine`；若有 conflict，去 deploy-engine 平级独立仓库操作；
- **若 L1 ACR login 失败**：在 ACR 控制台 → 访问凭证 → 重新设置/查看，更新 `.env`。

---

## §8 本步在哪里跑

| 操作 | 位置 |
|------|------|
| 核对 tfvars / .env / make help | `diting-infra/`（本地）|
| `make update-deploy-engine` | `diting-infra/`（本地）|
| deploy-engine 写操作 | **`../deploy-engine/`** 平级独立仓库（本地 · 不在子模块内）|

---

## §9 准出（Exit Criteria）

- [ ] §3.5 C1~C10 全 ✅（现状 10 项 + .env + gitignore）
- [ ] §3.5 T1~T5 全 ✅（工具链）
- [ ] §3.5 D1~D2 全 ✅（deploy-engine 子模块 + 平级仓库）
- [ ] §3.5 L1 ✅（ACR login）
- [ ] 已更新 L5 02_验收标准 中 `l5-shared-platform-baseline-step01` 对应行
- [ ] L4 实践记录_step_01 回填完成

---

## §10 [Deploy] 部署节奏

| 阶段 | 部署内容 | 触发 |
|------|---------|------|
| W1 | 本步骤一次性完成 | 启动期前置 |
| 后续 | 凡 deploy-engine 主仓更新 → diting-infra `make update-deploy-engine` 同步 | 按需 |

---

## §11 依赖

- diting-infra 已 clone（含 deploy-engine submodule）
- deploy-engine 平级独立仓库已 clone
- 阿里云子账号 AK/SK + ACR 账密 + ECS 实例密码已备好

---

## §12 风险与降级

| 风险 | 概率 | 影响 | 降级 |
|------|------|------|------|
| 现状 ID 与 tfvars 不一致（被改过）| 低 | 高（后续 step 全错）| 先 git log 查改动 · 与团队对齐 · 不要擅改 |
| ACR 账密失效 | 中 | 中 | 控制台重置 · 更新 .env |
| 本机出口 IP 变化（未在白名单）| 中 | 低 | `curl ifconfig.me` 再加白名单 |
| deploy-engine 主仓 main 有破坏性变更 | 低 | 中 | 锁子模块到特定 commit（`git submodule set-branch`）|

---

## §13 修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-24 v1 | DeployEngine 就绪与凭证初版（假设从零起 · 含创建资源）|
| **2026-05-24 v2** | **重命名为「现状盘点与凭证复用」**：①假设**复用现状**（10 项永驻资源全部已就绪）②**不创建任何云资源**（成本 ¥0）③耗时压缩到 30 min ④下一步指向新增 02_deploy-engine 扩展规约 |
