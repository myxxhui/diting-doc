# L3 · Stage1-03 基础设施 ECS 与 K3s 设计

> [!NOTE] **[TRACEBACK] 原子规约锚点**
> - **战略维度**: [开发与交付流程维度](../../02_战略维度/开发与交付/01_开发与交付流程维度.md)、[数据架构与分层存储维度](../../02_战略维度/产品设计/03_数据架构与分层存储维度.md)
> - **原子规约**: [_共享规约/02_三位一体仓库规约](../_共享规约/02_三位一体仓库规约.md)、[开发与交付/02_基础设施与部署规约](../开发与交付/02_基础设施与部署规约.md)
> - **DNA**: [_System_DNA/Stage1_仓库与骨架/dna_stage1_03.yaml](../_System_DNA/Stage1_仓库与骨架/dna_stage1_03.yaml)
> - **L4 实践**: [04_阶段规划与实践/Stage1_仓库与骨架/03_基础设施ECS与K3s就绪](../../04_阶段规划与实践/Stage1_仓库与骨架/03_基础设施ECS与K3s就绪.md#l4-stage1-03-exit)
> - **L5 锚点**: [02_验收标准#l5-stage-stage1_03](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage1_03)

<a id="design-stage1-03-goal"></a>
## 本步目标

基础设施（ECS + K3s）就绪；diting-infra 通过 Git 引用 deploy-engine，单一 YAML 配置就绪；执行 deploy-engine Up 产出集群；验证后**无论成败均回收资源**（含竞价 ECS）。

<a id="design-stage1-03-points"></a>
## 设计要点

- **deploy-engine 引用**：diting-infra 以 Git submodule 或等价方式引用 deploy-engine；调用约定见 02_基础设施与部署规约。
- **配置**：diting-infra 维护单一 YAML（如 `config/environments/dev/deploy.yaml`），结构符合 DeploymentConfig。
- **Up 产出**：执行 deploy-engine Up 后，ECS + K3s 集群可用；KubeConfig 可写至约定路径；`kubectl get nodes` 可成功。
- **验证后回收**：本步骤执行「创建 → 验证」后，**必须执行 deploy-engine Down**，释放部署与基础资源（含竞价实例 ECS）；验证通过与否均须回收。

<a id="design-stage1-03-exit"></a>
## 准出

deploy-engine Up 成功、KubeConfig 可用、验证项通过；**准出前已执行 Down 回收**，资源已释放。
