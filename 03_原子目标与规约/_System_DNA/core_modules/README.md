# 核心模块 DNA（按模块独立文件）

本目录存放 Module A-F 的独立 DNA 文件，与 [09_核心模块架构规约](../../_共享规约/09_核心模块架构规约.md) 一一对应。L4 步骤应引用对应 `dna_module_*.yaml`。

| 文件 | 对应模块 |
|------|----------|
| dna_module_a.yaml | Module A 语义分类器 |
| dna_module_b.yaml | Module B 量化扫描引擎 |
| dna_module_c.yaml | Module C MoE 议会 |
| dna_module_d.yaml | Module D 判官 |
| dna_module_e.yaml | Module E 风控盾 |
| dna_module_f.yaml | Module F 执行网关 |

production_requirements（容错、性能、可观测性等）为跨模块共用，保留在 `global_const.yaml` 中。

**可部署单元**：实盘多服务部署时，可部署单元定义见 `global_const.deployable_units`；热路径 D+E+F 为单一可部署单元（同进程、同镜像）。各单元之 verification_commands、work_dir、l5_anchor 与 L4 步骤文档 1:1 对齐，见 `dna_dev_workflow.yaml` 之 workflow_stages 与 deployable_units。
