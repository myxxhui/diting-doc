# L4 · 共享平台基础 · 启动期 · 实践记录 step_01 现状盘点与凭证复用（v2）

> **状态**：✅ 已准出（2026-05-24 · 路径 A 选定 · 凭证已写入 `diting-infra/.env`）

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[step_01_现状盘点与凭证复用](../../../03_原子目标与规约/共享平台基础/stages/stage_1_启动期/steps/step_01_现状盘点与凭证复用.md)
> - **DNA**：`dna_shared_platform_baseline.yaml#steps.p_step_01`
> - **L5**：[`02_验收标准.md#l5-shared-platform-baseline-step01`](../../../05_成功标识与验证/02_验收标准.md)
> - **上游**：（无 · 启动期首 step）
> - **下游**：→ [实践记录_step_02_deploy_engine扩展](./实践记录_step_02_deploy_engine扩展.md)（**路径 A · 全量 new-02**）

## 一、本步骤目标

按 L3 设计 §1 核对现状 10 项永驻资源 ID + deploy-engine 子模块更新 + 凭证就绪 + 工具链就绪 + ACR login。**v2 修正**：复用现状（不创建任何云资源 · ¥0）· 30 min 完成。

## 二、实际进展

| 项 | 状态 | 证据 |
|----|------|------|
| 现状 10 项永驻资源 ID 核对（§3.5 C1~C8）| ✅ | tfvars 与拓扑设计 §7 一致（vpc-j6cuhmska9vfwqa6my16q / vsw-j6ct3ymab1lxeqz38lbwi / sg-j6cizfabvego0nem81c2 / NAS 12db2e48f90 / 盘 d-j6cc6ew2bqkfdlwaavit / OSS deploy-engine-k3s-storage / ACR crpi-7vifw4ok9jkcxr60…）|
| deploy-engine 子模块为最新 main（D1）| ✅ | 子模块与平级独立仓均为 `aeb29719` = `origin/main` |
| deploy-engine 平级独立仓库（D2）| ✅ | `../deploy-engine/Makefile` 存在 |
| .env 含 5 凭证（§3.5 C9）| ✅ | `grep -cE '^(ALIYUN_AK\|ALIYUN_SK\|TF_VAR_instance_password\|ACR_USER\|ACR_PASSWORD)=' .env` → **5** |
| .env 已 gitignore（C10）| ✅ | `.gitignore` 已增 `.env`；`git check-ignore .env` 退码 0 |
| 工具链就绪（§3.5 T1~T5）| ✅ | terraform **v1.5.7** · helm **v3.8.1** · kubectl **v1.20.4** · yq **v4.50.1** · docker OK |
| ACR docker login（§3.5 L1）| ✅ | `Login Succeeded`（registry 香港个人版）|
| 用户决策：路径 A | ✅ | 全量 P-new-02 deploy-engine 扩展（非路径 B 降级）|
| SSH 公钥 | ⏭ 跳过 | 用户确认用密码 SSH；get-kubeconfig 走 `TF_VAR_instance_password` |

## 三、命令与输出摘要

```text
# C1~C8：config/terraform-diting-prod.tfvars 与拓扑 §7 全匹配
# D1：deploy-engine 子模块 HEAD = origin/main = aeb29719
# C9/C10：diting-infra/.env 已创建（ALICLOUD_* + ALIYUN_* 别名 + TF_VAR + ACR_*）
# L1：docker login $ACR_REGISTRY → Login Succeeded
# 安全组本机 IP：prod tfvars ssh_allowed_cidr=0.0.0.0/0 + 复用 sg-j6cizfabvego0nem81c2 → 无需手动加 IP
# tfvars instance_password 明文已移除，改由 .env TF_VAR_instance_password 注入
```

## 四、DECISION_PENDING 与 SKIP_REASON

| 项 | 类型 | 说明 | 建议 |
|----|------|------|------|
| — | — | 本步无 DECISION_PENDING | — |
| SSH 公钥 | SKIP | 用户选用密码登录 | 排错时 `sshpass` + root 密码 |

## 五、准出复核

- [x] §3.5 C1~C10 全 ✅
- [x] §3.5 T1~T5 全 ✅
- [x] §3.5 D1~D2 全 ✅
- [x] §3.5 L1 ✅
- [ ] L5 `l5-shared-platform-baseline-step01`（待同步 02_验收标准 状态列）

## 六、修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-24 | 占位创建（v1 原名 DeployEngine 就绪）|
| 2026-05-24 v2 | 重命名 v2：现状盘点与凭证复用 |
| **2026-05-24** | **执行准出**：凭证入 `.env` · 工具链/ACR/现状 ID 全绿 · **路径 A** · 下游 P-new-02 |
