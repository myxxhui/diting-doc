# L4 · 纵深进攻 · 05 V2 Tool Runtime 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[纵深进攻/05_实施推演_设计.md#四v2生产稳态](../../03_原子目标与规约/纵深进攻/05_实施推演_设计.md#四v2生产稳态)
> - **DNA**：[`dna_deep_strike_v2.yaml`](../../03_原子目标与规约/_System_DNA/deep_strike/dna_deep_strike_v2.yaml)
> - **L5 准出**：[`02_验收标准.md#l5-pillar-deep-v2-runtime`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-deep-v2-runtime)

<a id="l4-deep-v2-runtime-goal"></a>
## 一、本阶段目标
- **stage_id**: `deep_strike_v2_runtime`
- **工作目录**: `diting-src/diting/deep_strike/`
- **依赖**: `deep_strike_v1_council`, `deep_strike_v1_feature`
- **里程碑**: browser/computer-use Tool Runtime + 自适应议程 + 跨议题学习 + 多模态证据

## 二、本步骤落实的 DNA 键
- `tool_runtime_browser_and_cu`：经 [Runtime Sandbox Port](../../03_原子目标与规约/_共享规约/05_接口抽象层规约.md)
- `adaptive_agenda`：根据评测反馈调整议题优先级 / 频率
- `cross_topic_learning`：议会跨议题"记住"与"对比"
- `multimodal_evidence`：表格 / 图像 / 视频片段嵌入

## 三、实施内容（5D）
1. Runtime Sandbox（gVisor / Firecracker）+ 资源 quota
2. browser/computer-use Tool 适配层 + 录制
3. 自适应议程算法（多臂老虎机式）
4. 跨议题记忆库（基于 super_evo 知识库子集）
5. 多模态嵌入（图像 / PDF 表格）

## 四、可执行验证清单
| 命令 | 工作目录 | 期望 |
|------|---------|------|
| `make sandbox-escape-tests` | diting-src | exit 0；无逃逸 |
| `make adaptive-agenda-bench` | diting-src | 高活跃议题排程提前；指标可衡量 |
| `make multimodal-rag-bench` | diting-src | 含图证据可被议会引用 |

## 五、准出检查清单
- [ ] Tool Runtime 沙箱安全（无逃逸）
- [ ] 自适应议程指标可衡量
- [ ] 多模态证据议会可消费
- [ ] **已更新 [`02_验收标准.md#l5-pillar-deep-v2-runtime`](../../05_成功标识与验证/02_验收标准.md#l5-pillar-deep-v2-runtime)**

<a id="l4-deep-v2-runtime-exit"></a>
## 六、L5 准出锚点
`l5-pillar-deep-v2-runtime`

## 七、本步骤失败时
- Sandbox 异常 → 立即下线该 tool；触发 critical RiskEvent
- 同 [极寒防御/01_MVP §七](../极寒防御/01_MVP_本阶段实践与验证.md#七本步骤失败时)

## 八、上一步 / 下一步
- **上一步**：[04_V1_eval](./04_V1_eval_本阶段实践与验证.md)
- **下一步**：本模块完结
