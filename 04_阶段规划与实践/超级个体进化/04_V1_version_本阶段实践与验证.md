# L4 · 超级个体进化 · 04 V1 版本治理与灰度 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[超级个体进化/05_实施推演_设计.md#三v1完整能力](../../03_原子目标与规约/超级个体进化/05_实施推演_设计.md#三v1完整能力)
> - **DNA**：[`dna_super_evo_v1_version.yaml`](../../03_原子目标与规约/_System_DNA/super_evo/dna_super_evo_v1_version.yaml)
> - **L5 准出**：[`02_验收标准.md#l5-pillar-evo-v1-version`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-evo-v1-version)

<a id="l4-evo-v1-version-goal"></a>
## 一、本阶段目标
- **stage_id**: `super_evo_v1_version`
- **工作目录**: `diting-src/diting/super_evo/version/`
- **依赖**: `super_evo_mvp`, `super_evo_v1_eval`
- **里程碑**: model_versions 表 + 自动灰度策略 + 一键回滚

## 二、本步骤落实的 DNA 键
- `model_versions_governance`：版本元数据 + lineage
- `auto_canary_strategy`：评测达标 → 自动灰度推进
- `one_click_rollback`：一键回滚到上一稳定版本

## 三、实施内容（5D）
1. model_versions 表 + version_manager API
2. auto_canary 策略（评测达标 → progressive rollout）
3. rollback API（管理台 + CLI）
4. lineage 可视化（数据集 / 训练参数 / 评测报告）

## 四、可执行验证清单
| 命令 | 工作目录 | 期望 |
|------|---------|------|
| `make test-version-manager` | diting-src | exit 0 |
| `make canary-rollout-drill` | diting-src | 灰度推进 ≤ 5min；自动暂停指标恶化 |
| `make rollback-drill` | diting-src | 1 步回滚到上一版本；P95 < 30s |

## 五、准出检查清单
- [ ] 自动灰度达标推进
- [ ] 回滚 P95 < 30s
- [ ] lineage 可视化
- [ ] **已更新 [`02_验收标准.md#l5-pillar-evo-v1-version`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-evo-v1-version)**

<a id="l4-evo-v1-version-exit"></a>
## 六、L5 准出锚点
`l5-pillar-evo-v1-version`

## 七、本步骤失败时
- 灰度指标恶化 → 自动暂停 + 通知 + 触发 RiskEvent
- 同 [极寒防御/01_MVP §七](../极寒防御/01_MVP_本阶段实践与验证.md#七本步骤失败时)

## 八、上一步 / 下一步
- **上一步**：[03_V1_retro](./03_V1_retro_本阶段实践与验证.md)
- **下一步**：[05_V2_online](./05_V2_online_本阶段实践与验证.md)
