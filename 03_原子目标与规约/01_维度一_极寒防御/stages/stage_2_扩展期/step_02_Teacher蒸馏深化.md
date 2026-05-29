# Step 02 · Teacher 蒸馏深化（扩展期 · 3500 case 基线）

> **本步定位**：D1 三引擎 LoRA 训练数据从启动期 65 case 试跑，扩到**扩展期 3500 case 基线**（财务 1800 + 股东 1000 + 关联 700）。承接 step_01 扩展期数据（17 表 / 31 项矩阵），承接启动期 step_03 §6.5 长期推演的「扩展期」列。

## §1 一句话定位与本步交付物

**做完本步**：D1 三引擎获得 3500 条高质量 Verified case；架构师抽审率 ≥ 10%；Q1~Q9 矩阵全 ⚠️ 及以上；三引擎 LoRA 可在 P=0.85 上训练。

## §2 TRACEBACK

> [!NOTE]
> - **上游 step**：← [step_01_数据深度扩展](step_01_数据深度扩展.md)（17 表 / 31 项矩阵）
> - **启动期 step_03 §6.5 引用**：[`stage_1_启动期/steps/step_03_Teacher蒸馏.md#65-长期推演65--3500-case-路径--三档质量矩阵--给后续模型的工作指引`](../stage_1_启动期/steps/step_03_Teacher蒸馏.md)
> - **DNA 键**：`_System_DNA/01_cryo_guard/dna_stage_2_扩展期.yaml#teacher_distill`（Phase 2 待创建）
> - **触发条件**：step_01 全部 ✅ + 31 项矩阵全过 + 用户已配 `ANTHROPIC_API_KEY`（Sonnet 主蒸 + Opus 抽校）

## §3 数据采集对象（扩展期蒸馏增强）

| 业务对象 | 表 | 来源 | 新增字段 |
|---|---|---|---|
| `teacher_distill` 表（扩展期升级）| `teacher_distill_v2` | 同启动期 + 新字段 | + `case_difficulty`（简单/中等/难）+ `is_adversarial`（对抗样本）+ `critic_score`（Critic 引擎评分）+ `commit_chain_hash`（证据链 hash）|

## §3.5 数据质量矩阵（Q1~Q9 扩展期门槛）

承接启动期 step_03 §6.5.2 表的「扩展期」列：

| # | 维度 | 启动期 → 扩展期门槛 |
|---|---|---|
| Q1 | 证据链可追溯 | 90% → **100%** |
| Q3 | 标签分布平衡 | 6 类各 ≥ 10 → **12 类各 ≥ 100** |
| Q4 | 跨年对照 | 可选 → **≥ 50%** |
| Q5 | 跨标的对照 | 可选 → **≥ 30%** |
| Q6 | 难度分层 | 不分层 → **三档各 ≥ 30%** |
| Q7 | 对抗样本占比 | 0% → **≥ 10%** |
| Q8 | reasoning 字段 token | ≥ 100 → **≥ 300（CoT）** |
| Q9 | Critic 评分 | 手工标 → **LoRA 自动 + 架构师 10%** |

## §4 真实数据源与凭证

- `ANTHROPIC_API_KEY`：Sonnet 4.5/3.5（主蒸 · ~$0.022/case × 3500 ≈ $77）+ Opus 4.7（抽校 20% × ~$0.1/case × 700 ≈ $70）
- 启动期已配；扩展期无新凭证

## §5 扩展期目标

| 引擎 | case 数 | 平均 token | 单 case 成本 | 引擎成本 |
|---|---|---|---|---|
| 财务测谎（step_04）| 1800 | 3000 in / 1200 out | $0.022 | ~$40 |
| 大股东诚信（step_05）| 1000 | 2500 in / 1000 out | $0.018 | ~$18 |
| 关联交易（step_06）| 700 | 3500 in / 1500 out | $0.027 | ~$19 |
| **合计** | **3500** | — | — | **~$77 主蒸 + $70 Opus 抽校 = $150** |

## §6 下一步

- **触发条件**：3500 case 全部 Verified + Q1~Q9 全过 → 进入 [`stage_3_完善期/step_02_Teacher精炼.md`](../stage_3_完善期/step_02_Teacher精炼.md)（10000+ case + 多模型投票，Phase 2 新建）

## §7 实施规划

### §7.1 实现要点

| 要点 | 涉及代码 | 关键决策 | 验证 |
|---|---|---|---|
| A Prompt 模板 v2 | `apps/super_evo/teacher/prompts/v2/*.txt` | Few-shot + CoT + 角色扮演（"你是 SEC 资深审计师"）| 每个引擎 1 个模板 |
| B Sonnet 主蒸客户端 | `AnthropicTeacherClient` 扩 | model='claude-sonnet-4-x' | 3500 case 端到端 |
| C Opus 抽校客户端 | 同上 model='claude-opus-4-x' | 抽 20% × 3 引擎 | 不一致率 < 10% |
| D Critic 引擎评分 | 新增 `critic_lora_score.py` | 启动期 LoRA 预训 → 给 case 打分 0~1 | 评分 ≥ 0.6 入训 |
| E 难度课程 + 对抗样本 | 新增 `curriculum_builder.py` + `adversarial_generator.py` | LightGBM 自动判难度；LLM 生对抗 | Q6 三档 ≥ 30%；Q7 ≥ 10% |
| F 跨年/跨标的关联 | 新增 `case_cross_year_join.py` | 同标的多年 + 同行业横切 | Q4 ≥ 50%；Q5 ≥ 30% |

### §7.2 Makefile 合约

| target | 用途 | 验证 |
|---|---|---|
| `make cryo-stage2-distill-prep` | Prompt v2 + Critic LoRA 就绪 | 退出码 0 |
| `make cryo-stage2-distill-run` | 3500 case Sonnet 主蒸 | 3500 行入 `teacher_distill_v2` |
| `make cryo-stage2-distill-audit` | Opus 抽校 20% | 不一致率 < 10% |
| `make cryo-stage2-distill-quality` | Q1~Q9 矩阵 | 全过 |

### §7.3 给后续执行模型的指引

承接启动期 step_03 §6.5.5 的 7 条禁止 + 4 条必做约束；额外约束：
- **禁止用 Opus 主蒸**（成本 5x）：仅做抽校 20%；
- **禁止跳过 Critic 评分**：评分 < 0.6 case 退回重蒸；
- **禁止跨阶段共用 case**：启动期 65 case 不入 stage_2 训练，仅做对照。

## §8 部署节奏

| 阶段 | 形态 | 是否必须 |
|---|---|---|
| 本机开发 | 蒸馏脚本本机起 | 必须 |
| Dev K3s | Critic LoRA serving 起 K3s | Critic 评分阶段必须 |

## §9 准出标准

- [ ] 3500 case Verified
- [ ] Q1~Q9 全 ⚠️ 及以上
- [ ] Opus 抽校 20% 不一致率 < 10%
- [ ] 架构师 10% 抽审通过
- [ ] L4 实践记录回写

## §10 [Deploy] · §11 依赖 · §12 风险

- Deploy：Critic LoRA serving 部署见部署仓 Phase 2 新增
- 上游：← step_01 31 项矩阵；← 启动期 step_04~06 LoRA 已 P=0.6
- 下游：→ stage_2 step_03~05（三引擎 LoRA 升级训练 P=0.85）
- 风险：Anthropic 限流 → Bedrock cross-region；Critic 评分 SoT 漂移 → 锁定模型版本

## §13 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-23 | **v1.0 初版**：承接启动期 step_03 §6.5 表的扩展期列，3500 case 基线；与 step_01 形成扩展期数据 + 蒸馏闭环 |
