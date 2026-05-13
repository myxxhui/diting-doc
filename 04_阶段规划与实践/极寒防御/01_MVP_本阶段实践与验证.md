# L4 · 极寒防御 · 01 MVP 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[极寒防御/05_实施推演_设计.md#二mvp最小可用产品](../../03_原子目标与规约/极寒防御/05_实施推演_设计.md#二mvp最小可用产品)
> - **DNA**：[`_System_DNA/cryo_guard/dna_cryo_guard_mvp.yaml`](../../03_原子目标与规约/_System_DNA/cryo_guard/dna_cryo_guard_mvp.yaml)
> - **L5 准出**：[`05_成功标识与验证/02_验收标准.md#l5-pillar-cryo-mvp`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-cryo-mvp)

<a id="l4-cryo-mvp-goal"></a>
## 一、本阶段目标
- **stage_id**: `cryo_guard_mvp`
- **工作目录**: `diting-src/diting/cryo_guard/`
- **依赖**: `shared_platform_baseline`
- **里程碑**: 风险事件总线 + 决策门禁器（schema/evidence 两层）+ 审计日志（无链式 hash）+ 风险熔断面板 MVP

## 二、本步骤落实的 DNA 键

| DNA 键 | 用途 |
|--------|------|
| `dna_cryo_guard_mvp.proto_v1_minimal` | RiskEvent / GateRequest / GateDecision / AuditEntry 必备字段 |
| `dna_cryo_guard_mvp.db_tables` | risk_events / gate_decisions / audit_logs |
| `dna_cryo_guard_mvp.decision_gate_layers` | 仅 schema + evidence，且 `require_evidence_ref=true` |
| `dna_cryo_guard_mvp.risk_event_bus.realtime_push=websocket` | 前端 WS 订阅 |
| `dna_cryo_guard_mvp.audit_log.chain_hash=false` | MVP 关闭；V1 开启 |

## 三、实施内容（5D）

| # | 步骤 | 5D 角色 | 工作目录 |
|---|------|---------|---------|
| 1 | 编写 Proto v1 + 生成代码 | Design + Decompose | `diting-src/design/protocols/cryo_guard/` |
| 2 | 写测试用例（Table-Driven） | Drive | `diting-src/tests/cryo_guard/` |
| 3 | 数据库迁移脚本 + 运行 | Decompose | `diting-src/diting/cryo_guard/migrations/` |
| 4 | risk_event_bus（HTTP + Kafka + WS） | Decompose | `diting-src/diting/cryo_guard/risk_event_bus/` |
| 5 | decision_gate（schema + evidence 层） | Decompose | `diting-src/diting/cryo_guard/decision_gate/` |
| 6 | audit_log_service（无链式 hash） | Decompose | `diting-src/diting/cryo_guard/audit_log/` |
| 7 | 与前端风险熔断面板 MVP 联调 | Defense | `diting-src/web/apps/console/app/(risk)/` |
| 8 | Code Review + 红线检查 | Defense | 全部 |

## 四、可执行验证清单

| 命令 | 工作目录 | 期望 | 对应 DNA 键 |
|------|---------|------|-------------|
| `make test-cryo-guard-mvp` | diting-src | exit 0；覆盖率 ≥ 70% | `verification_commands[0]` |
| `make smoke-cryo-guard-mvp` | diting-src | RiskEvent 写入与读取通过；缺 evidence 的 GateRequest 被 reject；AuditEntry 已生成 | `verification_commands[1]` |
| `pytest tests/cryo_guard/ -v` | diting-src | 全通过 | `decision_gate_layers` |

## 五、准出检查清单

- [ ] 任意模块的 RiskEvent < 2s 在前端可见
- [ ] 缺 evidence_ref 的 GateRequest 被 reject 且生成 AuditEntry
- [ ] 单元 + 集成测试覆盖率 ≥ 70%
- [ ] Session transcript 与 Audit 关联可被回放
- [ ] **已更新 [`05_成功标识与验证/02_验收标准.md#l5-pillar-cryo-mvp`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-cryo-mvp)**

<a id="l4-cryo-mvp-exit"></a>
## 六、L5 准出锚点
`l5-pillar-cryo-mvp`

## 七、本步骤失败时
- **回退目标**：上一稳定 Helm Release + Git tag
- **重试上限**：同一问题修复重试 ≤ 2 次
- **超出后**：`helm rollback`；登记 06_/审计；架构师审批
- 详见 [系统规则 §7.2 / §九](../../00_系统规则_通用项目协议.md#九违规与修复)

## 八、上一步 / 下一步
- **上一步**：[共享平台基础/01](../共享平台基础/01_本阶段实践与验证.md)
- **下一步**：[02_V1_本阶段实践与验证.md](./02_V1_本阶段实践与验证.md)
