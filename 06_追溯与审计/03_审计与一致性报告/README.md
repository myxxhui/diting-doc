# L6 · 审计与一致性报告

> [!NOTE] **[TRACEBACK] 追溯审计锚点**
> - **顶层概念**: [一句话定义与核心价值](../../01_顶层概念/01_一句话定义与核心价值.md)
> - **本文档**: L6 层级，存放审计报告与增量便利贴

## 目录说明

- **审计报告**：定期生成的一致性检查报告
- **_增量便利贴/**：临时小改动的记录，需定期合并

## 增量便利贴使用说明

### 何时使用

- 小改动（加字段、改阈值）不宜直接改长篇设计文档时
- 需要快速记录临时需求时

### 使用流程

1. 在 `_增量便利贴/` 目录下新建文件（如 `20260212_增加字段.txt`）
2. 写下口语化需求
3. 使用 Prompt：`@便利贴文件 按需求更新代码/文档，注释中标注 [Ref: 便利贴_文件名]`
4. **熔断机制**：文件数 ≥10 或每周五/Sprint 结束前，必须合并并清空

### 便利贴格式

```
需求描述：[简要描述]
影响范围：[L1/L2/L3/L4/L5/L6]
优先级：[高/中/低]
创建时间：YYYY-MM-DD
```

## DNA–04_ Stage–L5 一致性校验

DNA、04_ 阶段目录（Stage1～5）、L5 验收标准三者变更时，可按下述清单或脚本快速发现漏改或断链。**执行时机**：人工定期执行或 CI 集成；与当前 Stage1～5（stage1_01～stage5_04）一致时均应通过。

### 人工校验清单

| 序号 | 检查项 | 操作方式 |
|------|--------|----------|
| 1 | DNA 中每个 `workflow_stages[].stage_id` 在 [04_阶段规划与实践](../../04_阶段规划与实践/) 下存在对应 Stage 目录（即 `l4_stage_dir` 同名目录） | 打开 [dna_dev_workflow.yaml](../../03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml)，逐条 `l4_stage_dir` 在 04_ 下列出目录（Stage1_仓库与骨架、Stage2_数据采集与存储 等），逐一确认存在 |
| 2 | 每个 `stage_id` 在 [05_成功标识与验证/02_验收标准.md](../../05_成功标识与验证/02_验收标准.md) 的 workflow_stages 表中有对应行 | 打开 02_验收标准.md，在「DNA stage_id」列中确认 stage1_01～stage5_04 各有一行 |
| 3 | 各 Stage 下步骤文档（01_～0N_）均含「可执行验证清单」与「本步骤失败时」 | 逐阶段打开步骤文档，全文检索「可执行验证清单」「本步骤失败时」 |
| 4 | （可选）每个 01_ 中「可执行验证清单」下至少有一条可执行项 | 目视或脚本检查 01_ 中该小节非空 |
| 5 | 各 Stage README「本阶段关联的 Phase 步骤」已回填或显式标注「本阶段无 Phase」 | 逐阶段打开 README，确认该小节为具体 Phase 链接或写明「本阶段无 Phase」/占位说明，审计或发布前无未替换占位 |
| 6 | L4 阶段文档（04_ 各 Stage 下 01_/README）发生结构性或 DNA 键引用变更后，当次或下次审计须复核与 L4 相关项 | 当步骤文档或 README 结构、DNA 键引用变更时，在审计清单中勾选「已按 [01_L3_DNA_变更对L4影响表](../01_L3_DNA_变更对L4影响表.md) 复核受影响阶段」 |
| 7 | **逻辑密集的 Phase 步骤文档**（见 [04_ README](../../04_阶段规划与实践/README.md) 或各 Phase README「本 Phase 步骤–5D 强度」表）是否包含「本步骤最小上下文」或「5D 执行顺序」、「本步骤失败时」、「本步骤准出」；**占位步骤**是否包含「占位边界」 | 逐条打开逻辑密集/占位步骤文档（如 Phase1 02_/03_、Phase2 01_、Phase3 02_ 等），全文检索上述小节标题，缺则补或标注待补 |
| 8 | （可选）各 Stage README「本阶段关联的 Phase 步骤」与对应 Phase 步骤文档内的「Phase–Stage 接口」是否一致 | 对照 Stage README 中列出的 Phase 步骤，打开各步骤文档「Phase–Stage 接口」小节，确认「本步产出被哪一 Stage 使用」「本步依赖哪一 Stage 准出」与 README 一致 |
| 9 | **所有 04_ 实践文档**（含 Stage 01_、Phase0 01_、各 Phase 的 01_～04_）是否含「**核心指令（The Prompt）**」块或明确引用完整版（如 00_5D）；是否含「**验证步骤**」与「**验证结果预期**」（或验收与测试/可执行验证清单 + 期望结果表） | 逐条打开上述文档，全文检索「核心指令」或「The Prompt」或「见 00_5D」；检索「验证步骤」或「可执行验证清单」；检索「验证结果预期」或表格「期望结果」列；缺则补或标注待补（见 [04_ README 实践文档统一必备结构](../../04_阶段规划与实践/README.md)） |
| 10 | **所有 04_ 实践文档**是否含**可复制测试命令**（bash/code 块）或可执行验证清单中至少一条可执行项 | Phase 步骤在「验收与测试」下确认存在可复制命令块；Stage 01_ / Phase0 01_ 在「可执行验证清单」或「验证步骤」下确认至少一条可执行项（见清单 3、4） |
| 11 | **L5 功能验收表**各行与 Phase 步骤 DoD 中引用的模块/行一致；L5 表增删行时须同步检查各步骤 DoD 表述 | 打开 [05_成功标识与验证/02_验收标准.md](../../05_成功标识与验证/02_验收标准.md) 功能验收表（锚点列 `l5-func-01`～`l5-func-10`），对照各 Phase 步骤「本步骤准出（DoD）」中的「已更新 L5…」表述，确认指向的锚点或「能力规约」与表一致；若 L5 表曾增删行，须逐步骤复核 DoD |
| 12 | **L4 与 DNA 一致**：各 Stage 01_「本步骤落实的 DNA 键」是否包含该 stage 的 `work_dir`、`verification_commands`、`l5_stage_anchor`（或等效表述） | 打开各 Stage 01_，在「本步骤落实的 _System_DNA 键」表中确认有 work_dir、verification_commands、l5_stage_anchor 的引用 |
| 13 | **可执行验证清单与 DNA 一致**：各 Stage 01_ 可执行验证清单中的命令是否与 [dna_dev_workflow.yaml](../../03_原子目标与规约/_System_DNA/dna_dev_workflow.yaml) 该 stage 的 `verification_commands` 一致或为其子集 | 对照 DNA 中该 stage 的 verification_commands[].cmd 与 01_ 中「可执行验证清单」或「验证步骤」下的命令，不一致时以 DNA 为准更新 01_ |
| 14 | **L5 workflow_stages 表与 DNA 一致**：L5 02_ 中 workflow_stages 表每行锚点（l5-stage-s0_pre 等）与 DNA 的 `l5_stage_anchor` 一致；表行集与 DNA stage_id 一一对应 | 运行 [check_l5_dna_consistency.sh](check_l5_dna_consistency.sh) 或人工对照 DNA workflow_stages[].l5_stage_anchor 与 L5 02_ 锚点列 |
| 15 | **L5 功能验收表与 DNA 一致**：功能验收表锚点（l5-func-01～10）与 [global_const product_scope.phases[].steps[].l5_anchor](../../03_原子目标与规约/_System_DNA/global_const.yaml) 一致 | 运行 [check_l5_dna_consistency.sh](check_l5_dna_consistency.sh) 或人工对照 DNA phases[].steps[].l5_anchor 与 L5 02_ 功能验收表 |
| 16 | **设计–DNA–实践 1:1:1**：每个 workflow_stages 条目的 design_doc、dna_file、04_ 步骤文件（l4_stage_dir + l4_step_doc）均存在 | 运行 [check_111_design_dna_practice.sh](check_111_design_dna_practice.sh) |

### 脚本校验（可选）

**脚本覆盖项**：下表项可由脚本自动判定；**仍须人工项**为其余序号（含 1～8、11 及 L2–L3–DNA 清单等），需人工打开文档逐项核对。

| 脚本 | 对应人工项 | 说明 |
|------|------------|------|
| [check_dna_00_l5.sh](check_dna_00_l5.sh) | 清单 1、2、3 | DNA–04_ Stage 目录、L5 stage_id 行、各 Stage 步骤文档可执行验证清单与本步骤失败时 |
| [check_phase_steps_prompt.sh](check_phase_steps_prompt.sh) | 清单 9、10 | 所有 04_ 实践文档（含 Stage 01_、Phase0 01_、Phase 步骤）是否含「核心指令」/The Prompt/00_5D；是否含可复制命令块（\`\`\`bash 等）或可执行项 |
| [check_l5_dna_consistency.sh](check_l5_dna_consistency.sh) | 清单 14、15 | L5 02_ workflow_stages 锚点与 DNA l5_stage_anchor 一致；L5 功能验收表锚点与 DNA product_scope.phases[].steps[].l5_anchor 一致 |
| [check_111_design_dna_practice.sh](check_111_design_dna_practice.sh) | **1:1:1 设计–DNA–实践** | 每个 workflow_stages 条目的 design_doc、dna_file、04_ 步骤文件（l4_stage_dir + l4_step_doc）是否存在 |

可执行脚本从**文档仓根目录**运行：

```bash
# 在 diting-doc 根目录下执行（不传参则自动识别文档仓根）
./06_追溯与审计/03_审计与一致性报告/check_dna_00_l5.sh
./06_追溯与审计/03_审计与一致性报告/check_phase_steps_prompt.sh
./06_追溯与审计/03_审计与一致性报告/check_l5_dna_consistency.sh
# 或指定文档仓根
./06_追溯与审计/03_审计与一致性报告/check_dna_00_l5.sh /path/to/diting-doc
./06_追溯与审计/03_审计与一致性报告/check_phase_steps_prompt.sh /path/to/diting-doc
./06_追溯与审计/03_审计与一致性报告/check_l5_dna_consistency.sh /path/to/diting-doc
./06_追溯与审计/03_审计与一致性报告/check_111_design_dna_practice.sh
./06_追溯与审计/03_审计与一致性报告/check_111_design_dna_practice.sh /path/to/diting-doc
```

脚本输出为逐项 PASS/FAIL 列表；全部 PASS 时退出码 0，否则非 0。

## L2–L3–DNA 一致性校验

L2 战略维度、L3 规约、DNA 子树三者变更时，可按下述清单检查漏改或断链。**权威表**：[00_L2_L3_DNA_映射](../00_L2_L3_DNA_映射.md)。

### 人工校验清单

| 序号 | 检查项 | 操作方式 |
|------|--------|----------|
| 1 | 每个 L2 维度（产品设计 01～08、开发与交付 01）在 [00_L2_L3_DNA_映射](../00_L2_L3_DNA_映射.md) 中有对应行 | 打开映射表，确认 9 个维度各有一行，且主责 L3、DNA 根节点/文件已填写 |
| 2 | 每个维度的主责 L3 文档存在，且其 TRACEBACK 中含该 L2 维度的链接 | 按映射表「主责 L3 规约」列打开文档，检查文首 TRACEBACK 是否有「战略维度：…」并指向对应 L2 文档 |
| 3 | 映射表中列出的 DNA 根节点在 `global_const.yaml` 或对应 `dna_*.yaml` 中存在 | 打开 [03_原子目标与规约/_System_DNA/global_const.yaml](../../03_原子目标与规约/_System_DNA/global_const.yaml)，确认 product_scope、cost_governance、data_architecture 等根节点存在；dna_dev_workflow 为独立文件 |
| 4 | （可选）`global_const.strategic_dimensions` 中每条 dimension 的 `primary_l3_docs` 与映射表一致 | 对比 YAML 中 strategic_dimensions 与 00_L2_L3_DNA_映射 表的主责 L3 列 |

### 脚本校验（可选）

若将映射表维护为机器可读格式（如 YAML 或表格可解析），可编写脚本：读取 L2 维度列表 → 校验映射表中有对应行 → 校验主责 L3 文件存在 → 校验 DNA 根节点在 global_const 或 dna_*.yaml 中存在；输出 PASS/FAIL 列表。

## DNA 节点落地状态

对 [global_const.yaml](../../03_原子目标与规约/_System_DNA/global_const.yaml) 中 `strategic_dimensions` 所列的各 `dna_nodes` 进行盘点：若节点下包含可执行键（路径、阈值、开关、保留期等）则视为已落地；若仅有注释或关键键为 null 则标注「部分待落地」，供后续迭代补键。

| DNA 根节点/文件 | 落地状态 | 备注 |
|-----------------|----------|------|
| product_scope | 已落地 | phases、priority_rules、l1_mapping_ref 等可执行键已填 |
| cost_governance | 部分待落地 | max_token_per_decision、roi_fuse_threshold、cold_archive.retention_days 为 null，待项目设定 |
| data_architecture | 部分待落地 | data_firewall.great_expectations_rules_path 为 null，待项目设定 |
| core_formula, constraints, tech_stack, trinity_repos, abstraction_layer, protocols, dynamic_config, data_version_control, heartbeat_protocol, core_modules, production_requirements, governance_and_dr, architecture_consensus, traceability_and_audit, success_markers | 已落地 | 均有可执行键或子节点 |
| dna_dev_workflow.yaml | 已落地 | workflow_stages、module_to_stages 完整 |

**维护**：L3 或 DNA 变更后，由当次执行方或审计时更新上表，避免给人「已完全对齐」的错觉。

## 审计报告

审计报告应定期生成，检查：
- 层级一致性
- 追溯链路完整性
- 便利贴合并情况
- 文档更新情况

### 2026-02-14 L3/DNA 推翻与 L4 全流程闭环 — 一致性检查表

| 检查项 | 状态 | 说明 |
|--------|------|------|
| 01_～06_ 目录层级正确 | ✅ | 文档仓层级未改变，Stage0_pre、Phase0_Infra 已归位 |
| DNA workflow_stages 与 L5 表 stage_id 一一对应 | ✅ | s0_pre～s4 共 7 个 stage，L5 02_验收标准 表已含 s0_pre 行及「与 DNA 强一致」约定 |
| 04_ 推荐顺序表与 DNA 一致 | ✅ | 04_阶段规划与实践/README 与 dna_dev_workflow 执行顺序一致，Stage1～5 线性执行 |
| Stage0 准入引用 Stage0_pre | ✅ | Stage0_骨架期 README 与 01_ 前置条件均含「若尚未具备，请先执行 Stage0_pre 或 Phase0_Infra 的 01_」 |
| 协议 §8.4a 含建仓阶段例外 | ✅ | 00_系统规则、.cursorrules 均已增加建仓阶段工作目录/可执行验证例外 |
| L6 与 ADR 含 s0_pre/Phase0-Infra 映射 | ✅ | 02_战略追溯矩阵 可交付性行含 Stage0_pre；ADR 追溯前有 Phase–Stage 约定（Phase0-Infra ↔ Stage0_pre/s0_pre） |
| 回退策略可引用 | ✅ | 03_项目全功能开发测试实践工作流详细规划「八、失败与回退策略」已增加回退检查点定义，各 01_「本步骤失败时」可引用 |
