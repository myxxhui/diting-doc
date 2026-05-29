# 5 维度与 L3 / L4 / L5 / DNA 的衔接

> [!NOTE] **[TRACEBACK]**
> - **同层引用**: [01_5维度协作关系图](./01_5维度协作关系图.md)
> - **L3 总纲**: [03_原子目标与规约/00_六大模块抽象总纲](../../03_原子目标与规约/00_六大模块抽象总纲.md)

## 一、5 维度 ↔ L3 模块对照

| 维度 | L3 模块 | 关系 |
|---|---|---|
| 维度一·极寒防御 | `cryo_guard` | 1:1 对应 |
| 维度二·纵深进攻 | `deep_strike` | 1:1 对应 |
| 维度三·持仓监控 | `state_watch`（监控部分） | 维度三 + 维度四 = 1 个 L3 模块 |
| 维度四·卖出决策 | `state_watch`（决策部分） | 维度三 + 维度四 = 1 个 L3 模块 |
| 维度五·演进飞轮 | `super_evo` | 1:1 对应 |

> **关键说明**：维度三 + 维度四 = `state_watch` 单一 L3 模块。L3 仍是 4 大模块结构（不增加 L3 模块数量），但产品设计视角从中拆出"持仓监控"和"卖出决策"两个独立的产品子能力。

## 二、5 维度 ↔ _System_DNA 文件对照

| 维度 | _System_DNA 路径 | 内容 |
|---|---|---|
| 维度一 | `_System_DNA/cryo_guard/engines/*.yaml` | 10 引擎的 SLI、阈值、决策规则 |
| 维度二 | `_System_DNA/deep_strike/playbooks/*.yaml` | 10 剧本的 Agent 编排、prompt 模板、能力圈白名单 |
| 维度三 | `_System_DNA/state_watch/observer/*.yaml` | 8 引擎的 SLI 探针调度、加权策略 |
| 维度四 | `_System_DNA/state_watch/exit_engine/*.yaml` | 7 引擎的 R1/R2/R3 矩阵阈值、确认门禁 |
| 维度五 | `_System_DNA/super_evo/components/*.yaml` | 13 MLOps 组件的训练超参、Holdout 守门规则 |

## 三、5 维度 ↔ L4 阶段实践对照

| L4 阶段 | 涉及维度 | 关键交付 |
|---|---|---|
| Stage1·仓库与骨架 | 维度五（DVC + 数据湖） | 三仓骨架 + 配置 + 密钥 |
| Stage2·数据采集与存储 | 维度一、二、三的 P0 数据采集 | P0 10 类数据可被消费 |
| Stage3·模块实践 | 维度一、二、三、五的 P0 引擎/组件 | 10 个 P0 引擎/组件全部跑通 |
| Stage4·MoE 与执行网关 | 维度二、三、四（部分） | 议会模式 + 卖出决策 |
| Stage5·优化与扩展 | 全部维度（P1/P2） | 全维度运行 + 数字分身 |

## 四、5 维度 ↔ L5 验收对照

| 维度 | L5 验收行 ID 前缀 | 主要验收指标 |
|---|---|---|
| 维度一 | `l5-cryo-*` | Holdout Recall ≥ 0.95、Precision ≥ 0.70 |
| 维度二 | `l5-strike-*` | Holdout Recall ≥ 0.70、thesis 通过率 ≥ 0.70 |
| 维度三 | `l5-watch-*` | NLI F1 ≥ 0.80、被打脸召回率 ≥ 0.85 |
| 维度四 | `l5-exit-*` | 建议命中率 ≥ 0.65、R1 escalate 召回率 ≥ 0.90 |
| 维度五 | `l5-evo-*` | Holdout 守门覆盖率 100%、DVC 可追溯率 100% |

## 五、与 L4 工作目录约定

| 维度 | 主要工作目录 |
|---|---|
| 维度一/二/三/四的 AI 引擎 | `diting-src/`（代码仓） |
| 维度五的 MLOps 组件 | `diting-infra/`（部署仓） + `diting-src/training/` |
| 数据湖与 DVC | `diting-data/`（数据仓） |
| 文档 | `diting-doc/`（文档仓） |

## 六、追溯规则

每一个引擎/组件文档（`engines/0X_*.md` 或 `components/0X_*.md`）的 §八 必须包含：

```markdown
## 八、L3/L4/L5/DNA 映射
- L3 子模块: `xxxx_service`
- L4 阶段实践: 04_阶段规划与实践/StageY_*/
- L5 验收行 ID: l5-cryo-fraud-detector / l5-strike-profit-retention / ...
- DNA 配置键: _System_DNA/cryo_guard/engines/fraud_detector.yaml
```

这是 5 维度可追溯到 L3/L4/L5/DNA 的强制约定。
