# L3/DNA 变更 → L4 影响表

> 当某 L3 文档或某 DNA 子树发生变更时，本表列出需**复核或再生成**的 L4 阶段/步骤。L4 步骤文档中「本步骤落实的 _System_DNA 键」所涉键或主责 L3 变更时，须按本表执行复核。参见 [00_系统规则 §8.4a DNA/L3 变更时复核](../00_系统规则_通用项目协议.md)。

## 约定

- **复核**：检查对应 00_ 阶段目录下 `01_本阶段实践与验证.md` 及 README 的实施内容、验证清单、DNA 键引用是否仍与 L3/DNA 一致；必要时重跑该阶段或更新 01_。
- **可选**：DNA 关键节点可增加 `used_by_l4_stages: [s0_pre, s0, ...]` 便于脚本自动推导影响范围。

## L3 文档变更 → 需复核的 L4 阶段

| L3 规约文档 | 需复核的 L4 阶段（04_ Stage1～5） | 说明 |
|-------------|--------------------------------------|------|
| [01_开发生命周期与实践流程规约](../03_原子目标与规约/开发与交付/01_开发生命周期与实践流程规约.md) | 全部 Stage（s0_pre～s4） | 阶段顺序、准入准出、工作目录、失败回退均引用本规约 |
| [02_基础设施与部署规约](../03_原子目标与规约/开发与交付/02_基础设施与部署规约.md) | Stage3_K3s测试开发期、Stage4_与流水线衔接 | 编排、Secret、deploy-engine、环境与发布 |
| [03_项目全功能开发测试实践工作流详细规划](../03_原子目标与规约/开发与交付/03_项目全功能开发测试实践工作流详细规划.md) | 全部 Stage | 5D 总览、工作目录总表、失败与回退策略被各 01_ 引用 |
| [02_三位一体仓库规约](../03_原子目标与规约/_共享规约/02_三位一体仓库规约.md) | Stage0_pre_仓库与L3就绪、Stage0_骨架期、Stage3、Stage4 | 仓库结构、secrets、diting-infra |
| [01_需求与产品范围](../03_原子目标与规约/产品设计/01_需求与产品范围.md) | Stage1_逻辑填充期及关联 Phase 步骤 | delivery_scope、Phase 任务拆分 |
| [08_心跳协议与健康检查规约](../03_原子目标与规约/_共享规约/08_心跳协议与健康检查规约.md) | Stage3_K3s测试开发期 | 可观测性、健康检查 |
| [09_核心模块架构规约](../03_原子目标与规约/_共享规约/09_核心模块架构规约.md) | [Stage1_仓库与骨架](../04_阶段规划与实践/Stage1_仓库与骨架/README.md#本阶段步骤索引)、[Stage3_模块实践](../04_阶段规划与实践/Stage3_模块实践/README.md#本阶段步骤索引) 01_～06_（若涉及模块部署） | 模块与生产要求 |
| [10_运营治理与灾备规约](../03_原子目标与规约/_共享规约/10_运营治理与灾备规约.md) | Stage4_与流水线衔接、Stage3（若涉及合规/密钥） | 准出后运维、Level 2/3、合规与灾备 |
| [11_数据采集与输入层规约](../03_原子目标与规约/_共享规约/11_数据采集与输入层规约.md) | Stage0_数据采集、Phase1_按模块实践 01_～06_（真实数据验证） | 数据源、L1/L2 写入与消费 |

## DNA 子树/文件变更 → 需复核的 L4 阶段

| DNA 子树/文件 | 需复核的 L4 阶段 | 说明 |
|---------------|------------------|------|
| `dna_dev_workflow.yaml`（workflow_stages, module_to_stages） | 全部 Stage | 阶段定义、delivery_scope、exit_criteria、artifacts 直引 |
| `global_const.trinity_repos` | Stage0_pre、Stage0、Stage3、Stage4 | 仓库路径、repo_a/secrets |
| `global_const.production_requirements`（observability, deployment） | Stage3、Stage4 | 可观测性、部署要求 |
| `global_const.cost_governance` | Stage1（选型）、Stage3（部署资源） | 成本敏感步骤须引用 |
| `_System_DNA/core_modules/`（dna_module_a～f.yaml） | Phase1_按模块实践 01_～06_ | 每模块 L4 步骤引用对应 dna_module_*.yaml |
| `global_const.data_ingestion` | Stage0_数据采集、Phase1_按模块实践 | 数据采集与真实数据验证 |
| 其他 global_const 根节点（core_formula, data_architecture 等） | 引用该键的 Stage 01_ | 按各 01_「本步骤落实的 _System_DNA 键」逐项对照 |

## 下一步

- L3 或 DNA 变更后，执行方按本表复核对应 L4 阶段，并更新 01_/README 或重跑验证。
- 协议 §4.1：L3 变更 → 同步 L4 阶段、L5 验收项；本表为「同步 L4」的具体索引。
