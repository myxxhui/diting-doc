# L4 · 状态机监控 · 05 V2 模板灰度 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[状态机监控/05_实施推演_设计.md#四v2生产稳态](../../03_原子目标与规约/状态机监控/05_实施推演_设计.md#四v2生产稳态)
> - **DNA**：[`dna_state_watch_v2.yaml`](../../03_原子目标与规约/_System_DNA/state_watch/dna_state_watch_v2.yaml)
> - **L5 准出**：[`02_验收标准.md#l5-pillar-watch-v2-template`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-watch-v2-template)

<a id="l4-watch-v2-template-goal"></a>
## 一、本阶段目标
- **stage_id**: `state_watch_v2_template`
- **工作目录**: `diting-src/diting/state_watch/`
- **依赖**: `state_watch_v1_budget`
- **里程碑**: 模板版本灰度 + 实例升级 + 自定义探针（沙箱）+ 跨用户聚合 + 模板市场

## 二、本步骤落实的 DNA 键
- `template_canary_rollout`：模板版本 staging/canary/prod
- `instance_upgrade`：用户主动升级实例
- `custom_probe_in_sandbox`：用户脚本沙箱
- `cross_user_aggregation`：差分隐私聚合
- `template_marketplace`：模板分享 + 评分

## 三、实施内容（5D）
1. 模板灰度（与 super_evo `version_manager` 集成）
2. 实例升级流程（diff 展示 + 用户确认 + 历史保留）
3. 自定义探针 Sandbox（gVisor / Wasm）+ 资源 quota
4. 跨用户聚合视图（差分隐私）
5. 模板市场前端 + 评分 / 收藏

## 四、可执行验证清单
| 命令 | 工作目录 | 期望 |
|------|---------|------|
| `make sandbox-escape-tests-state-watch` | diting-src | exit 0 |
| `make template-canary-rollout-drill` | diting-src | 灰度推进 / 回滚演练通过 |
| `make instance-upgrade-bench` | diting-src | 旧实例可平滑升级 |
| `make cross-user-aggregation-privacy-test` | diting-src | 差分隐私指标达标 |

## 五、准出检查清单
- [ ] 模板灰度可推进与回滚
- [ ] 自定义探针沙箱无逃逸
- [ ] 跨用户聚合差分隐私达标
- [ ] **已更新 [`02_验收标准.md#l5-pillar-watch-v2-template`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-watch-v2-template)**

<a id="l4-watch-v2-template-exit"></a>
## 六、L5 准出锚点
`l5-pillar-watch-v2-template`

## 七、本步骤失败时
- Sandbox 异常 → 立即下线该探针 + 触发 critical RiskEvent
- 同 [极寒防御/01_MVP §七](../极寒防御/01_MVP_本阶段实践与验证.md#七本步骤失败时)

## 八、上一步 / 下一步
- **上一步**：[04_V1_budget](./04_V1_budget_本阶段实践与验证.md)
- **下一步**：本模块完结
