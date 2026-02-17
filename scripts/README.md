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
```

**建议频率**：熔断前（每周五或 Sprint 结束前）运行 `check_sticky_count.sh`；发布或重构前运行 `check_matrix_pending.sh`；L4/03_/DNA 结构变更后运行 `check_design_dna_practice_consistency.sh`；L4 锚点或 02_验收标准 变更后运行 `check_anchor_resolvable.sh`。可接入 CI（如 GitHub Actions）在每次 PR 或定时任务中执行。

**协议约定**：若项目提供本目录下的一致性检查脚本，其通过可作为 §7.5 一致性检查表的部分满足条件。
