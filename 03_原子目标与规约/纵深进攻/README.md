# L3 · 纵深进攻（Deep-Strike）

> [!NOTE] **[TRACEBACK] 原子规约锚点**
> - **顶层概念**：[项目定义与核心价值](../../01_顶层概念/01_项目定义与核心价值.md)
> - **战略主轴**：[L2 · 双目标与战略维度关系 §纵深进攻](../../02_战略维度/00_双目标与战略维度关系.md)
> - **同层总纲**：[四大模块抽象总纲 §3.2 纵深进攻](../00_四大模块抽象总纲.md#32-纵深进攻deep-strike)
> - **DNA 计划路径**：`_System_DNA/deep_strike/`、`global_const.deep_strike`（第 2 批补完）
> - **L4 计划目录**：`04_阶段规划与实践/纵深进攻/`（第 3 批补完）

## 一句话定位

**项目的 Alpha 引擎——把高维碎片信息压缩为有解释、有证据、有失败兜底的研究结论。**

## 核心交付物

- 研究卡片（结论 + 证据链 + 适用周期）
- 研究候选清单（优先级 / 置信度 / 状态机模板建议）
- 议会会议记录（多 Agent 投票、分歧与共识）
- 预期差度量值

## 后端服务子模块（计划，第 2 批展开）

| 子模块 | 英文键 | 主责 |
|--------|--------|------|
| 内容理解服务 | `content_comprehension_service` | 实体抽取、事件抽取、主营对齐、产业链关联 |
| 信号特征工程 | `signal_feature_engine` | 数值 / 语义 / 嵌入 / 图特征，含批 + 流 |
| 研究议会服务 | `research_council_service` | MoE / Agent / Tool Calling 编排，多视角推理 |
| 议程编排器 | `agenda_orchestrator` | 每日 / 每周 / 触发式议程，议会议题排程 |
| 预期差量化器 | `expectation_gap_quantifier` | 与市场共识的差异度量、动量折现 |
| 研究候选注册表 | `candidate_registry` | 候选生命周期管理与去重 |

## 前端接入

- 投研对话台
- 研究候选广场
- 研究卡片详情页（证据链可视化）

## 第 2 批将补完的文档

- `01_目标与边界_设计.md`
- `02_后端服务子模块_设计.md`
- `03_接口契约_设计.md`：Research Protocol（含 ResearchCard、Candidate、CouncilSession Proto）
- `04_数据契约_设计.md`：研究卡片表、候选表、议会会议记录表、嵌入与图特征存储
- `05_实施推演_设计.md`：MVP → V1（多 Agent 协作）→ V2（自适应议程与预期差）

## 旧 ABCDEF 映射

- 旧 Module A（内容理解与标的画像）整体收敛
- 旧 Module B（特征 / 信号 / 候选引擎）整体收敛
- 旧 Module C（研究议会与 Agent 编排）整体收敛
- 旧 B 轨 / C 轨 / Segment 右脑等命名完全废弃，能力点并入

## 一致性检查表（本目录第 2 批完成时勾选）

- [ ] 六个子模块设计稿到位
- [ ] 与共享规约 04（Research Protocol）/ 05（Inference Gateway / Research Workflow Port）/ 11（数据采集）对齐
- [ ] DNA `deep_strike` 子树已建
- [ ] L4 实践目录骨架已建
- [ ] L5 验收行 `l5-pillar-deep-*` 已建
