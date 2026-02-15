# 文档仓一致性检查脚本

本目录提供轻量自动化检查，支撑协议中的「责任与触发」与「一致性检查表」（参见 `00_系统规则_通用项目协议.md` §3.4、§7.5）。

**运行方式**：从文档仓根目录（`diting-doc/`）执行。

```bash
# 便利贴数量检查（超过 9 则非零退出）
./scripts/check_sticky_count.sh

# 战略追溯矩阵待填充项报告
./scripts/check_matrix_pending.sh
```

**建议频率**：熔断前（每周五或 Sprint 结束前）运行 `check_sticky_count.sh`；发布或重构前运行 `check_matrix_pending.sh`。可接入 CI（如 GitHub Actions）在每次 PR 或定时任务中执行。

**协议约定**：若项目提供本目录下的一致性检查脚本，其通过可作为 §7.5 一致性检查表的部分满足条件。
