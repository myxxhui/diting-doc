# 文档仓一致性检查脚本

本目录提供轻量自动化检查，支撑协议中的「责任与触发」与「一致性检查表」（参见 `00_系统规则_通用项目协议.md` §3.4、§7.5）。

**运行方式**：从文档仓根目录（`diting-doc/`）执行。

```bash
# 便利贴数量检查（超过 9 则非零退出）
./scripts/check_sticky_count.sh

# 战略追溯矩阵待填充项报告
./scripts/check_matrix_pending.sh

# 设计↔DNA↔实践 三方一致性检查（04_ 实践 ↔ 03_ 设计 ↔ _System_DNA 一一对应）
./scripts/check_design_dna_practice_consistency.sh

# 跨文档锚点可解析性校验（L4 l4-*-goal/exit、L5 l5-stage-* 显式锚点存在）
./scripts/check_anchor_resolvable.sh

# Stage1-04 L1 验证（密钥与配置模板）：从文档仓执行，INFRA_DIR 指向 diting-infra 根目录
INFRA_DIR=/path/to/diting-infra ./scripts/verify_stage1_04.sh
```

**建议频率**：熔断前（每周五或 Sprint 结束前）运行 `check_sticky_count.sh`；发布或重构前运行 `check_matrix_pending.sh`；L4/03_/DNA 结构变更后运行 `check_design_dna_practice_consistency.sh`；L4 锚点或 02_验收标准 变更后运行 `check_anchor_resolvable.sh`。**Stage1-04 准出**时运行 `verify_stage1_04.sh`（见 [04_密钥与配置模板就绪](../04_阶段规划与实践/Stage1_仓库与骨架/04_密钥与配置模板就绪.md)#验证与准出）。可接入 CI（如 GitHub Actions）在每次 PR 或定时任务中执行。

**L4 实践文档与核心指令**：L4 实践文档与核心指令须满足「**DNA 为核心实践目标**」与「**核心指令引用 AI 可读**」（见 00_系统规则 §8.4d、§12）。对应校验脚本为 [06_追溯与审计/03_审计与一致性报告/check_prompt_refs_ai_readable.sh](../06_追溯与审计/03_审计与一致性报告/check_prompt_refs_ai_readable.sh)：若步骤文档含「本步逻辑引用（AI 可读）」块，则校验其中 dna_file、design_doc 等路径存在。建议在 04_ 步骤文档或核心指令/引用块变更后运行该脚本。

**协议约定**：若项目提供本目录下的一致性检查脚本，其通过可作为 §7.5 一致性检查表的部分满足条件。
