# L2 战略维度 ↔ 主责 L3 规约 ↔ DNA 子树 映射表

> 本表为 L2/L3/DNA 三者对应关系的**唯一总表**。L2 维度变更时，须先更新主责 L3 文档，再同步对应 DNA 子树，最后检查 L4 引用。详见 [03_原子目标与规约/README 变更传播规则](../03_原子目标与规约/README.md)。

## 约定

- **主责 L3 规约**：每个 L2 维度有且仅有 1 份「主责」L3 文档；变更时优先更新该文档。
- **DNA 根**：每个 L2 维度在 DNA 中有至少 1 个根级子树或独立文件作为该维度的配置真相源（`global_const.yaml` 根节点或 `dna_*.yaml`）。
- **09_通俗易懂的逻辑链路图**：沟通用图表，不占主责 L3；与 L2/L3 一致，冲突时以 L3 为准。

## 映射表

| L2 维度 | 主责 L3 规约 | 辅 L3 规约（可选） | DNA 子树/文件 |
|---------|--------------|--------------------|----------------|
| [01_产品设计维度](../02_战略维度/产品设计/01_产品设计维度.md) | [01_需求与产品范围](../03_原子目标与规约/产品设计/01_需求与产品范围.md) | — | `product_scope` / `roadmap`（见 global_const） |
| [02_技术栈与架构维度](../02_战略维度/产品设计/02_技术栈与架构维度.md) | [01_核心公式与MoE架构规约](../03_原子目标与规约/01_核心公式与MoE架构规约.md) | 02_三位一体、09_核心模块架构规约 | `core_formula`, `constraints`, `tech_stack`, `trinity_repos`, `core_modules`, `abstraction_layer` |
| [03_数据架构与分层存储维度](../02_战略维度/产品设计/03_数据架构与分层存储维度.md) | [07_数据版本控制规约](../03_原子目标与规约/07_数据版本控制规约.md) | 05_接口抽象层、09_核心模块、10_运营治理与灾备 | `data_version_control`, `data_architecture`（见 global_const） |
| [04_生产保障与可观测性维度](../02_战略维度/产品设计/04_生产保障与可观测性维度.md) | [08_心跳协议与健康检查规约](../03_原子目标与规约/08_心跳协议与健康检查规约.md) | 09_核心模块、10_运营治理与灾备、03_架构设计共识 | `heartbeat_protocol`, `production_requirements.observability`, `production_requirements.deployment`（该维度无单一 DNA 根，以列举为准） |
| [05_安全与机密治理维度](../02_战略维度/产品设计/05_安全与机密治理维度.md) | [10_运营治理与灾备规约](../03_原子目标与规约/10_运营治理与灾备规约.md) | 02_三位一体、03_架构设计共识、开发与交付/02_基础设施与部署 | `governance_and_dr.compliance`, `trinity_repos.repo_a.secrets`, `success_markers.security_acceptance`, `traceability_and_audit.audit_logging` |
| [06_研产同构维度](../02_战略维度/产品设计/06_研产同构维度.md) | [05_接口抽象层规约](../03_原子目标与规约/05_接口抽象层规约.md) | 02_三位一体、03_架构设计共识、07_数据版本控制、09_核心模块 | `abstraction_layer`, `architecture_consensus.gitflow`, `data_version_control` |
| [07_成本治理维度](../02_战略维度/产品设计/07_成本治理维度.md) | [10_运营治理与灾备规约](../03_原子目标与规约/10_运营治理与灾备规约.md) | 06_动态配置、09_核心模块 | `cost_governance`（见 global_const） |
| [08_经纪商解耦与冗余维度](../02_战略维度/产品设计/08_经纪商解耦与冗余维度.md) | [05_接口抽象层规约](../03_原子目标与规约/05_接口抽象层规约.md) | 09_核心模块、10_运营治理与灾备 | `abstraction_layer.broker_driver`, `core_modules`（Module F）, `governance_and_dr.compliance.allowed_channels` |
| [01_开发与交付流程维度](../02_战略维度/开发与交付/01_开发与交付流程维度.md) | [01_开发生命周期与实践流程规约](../03_原子目标与规约/开发与交付/01_开发生命周期与实践流程规约.md) | 02_基础设施与部署、03_项目全功能开发测试实践工作流详细规划 | `_System_DNA/dna_dev_workflow.yaml`（`workflow_stages`, `module_to_stages`） |

## 说明

- **product_scope / roadmap**：产品设计维度 DNA 根，在 global_const 中补全后本表无需改列名。
- **data_architecture**：数据架构维度专用 DNA 根，在 global_const 中新增后与 data_version_control 并列引用。
- **cost_governance**：成本治理维度专用 DNA 根，在 global_const 中新增。
- **04_生产保障与可观测性**：当前无单一 DNA 根，以多节点列举为准；可选后续新增 `production_assurance` 聚合子树。

## L3/DNA 变更对 L4 的影响

当 L3 规约或 DNA 子树变更时，需复核的 L4 阶段见 [01_L3_DNA_变更对L4影响表](01_L3_DNA_变更对L4影响表.md)。各 01_ 中「本步骤依赖的 DNA 键或主责 L3 发生变更时，须复核本步骤」见协议 §8.4a。

## 下一步

- 03_README、02_战略维度/README 在显著位置链接至本表。
- 各 L2 维度文档「下一步」改为精确主责 L3 链接 + 本映射表链接。
