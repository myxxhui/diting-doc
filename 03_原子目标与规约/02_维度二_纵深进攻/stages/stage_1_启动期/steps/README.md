# 维度二·纵深进攻·启动期·可执行步骤索引

> [!NOTE] **本目录定位**
> 给 Cursor / 开发者的"工作令"，每个 step 文件 = 一个可独立执行的开发任务。
> - 设计依据：见同级 [01_~05_](../) 5 份设计文档
> - DNA 真相源：[../../../../_System_DNA/02_deep_strike/dna_stage_1_启动期.yaml](../../../../_System_DNA/02_deep_strike/dna_stage_1_启动期.yaml)
> - 完成回写路径：[04_阶段规划与实践/02_维度二_纵深进攻/stage_1_启动期/](../../../../../04_阶段规划与实践/02_维度二_纵深进攻/stage_1_启动期/)

> **[上架与环境]** **阿里云 ECS + K3s** · **Helm** · **ACR** · **`diting-infra`→`deploy-engine`**。必读：[16](../../../../_共享规约/16_阿里云ECS_K3s_ACR_Helm部署与deploy-engine链路.md) · [L3§1必选](../../../../_共享规约/L3步骤文档_部署价值哲学_必选引用.md)

<a id="l3-step-l4-mapping-authority"></a>

### L3 ↔ L4 映射（权威）

- **唯一执行序**：**`#` 列 1→10**，即 **`step_01` … `step_10`**（见下表）。
- **L4 实践记录文件名**：`实践记录_step_NN_*.md`，与本目录 **`step_NN_*.md`** 按下文 **「三、L4 实践记录预期清单」** **1:1**。
- **六维度日历节奏**：见 [14_六维度启动期统一节奏表](../../../../_共享规约/14_六维度启动期统一节奏表.md)（含 **§九**）— **本目录正文不承载日历周次**。

## 〇、三线并行门禁（每张 step 必选）

| 线 | 要求 |
|---|---|
| **用户价值** | 链 [15](../../../../_共享规约/15_前后端职责与产品价值优先级.md)；**禁止自动建仓**；thesis 经 D0 触点 |
| **部署** | 镜像/Chart 走 **diting-infra**；**勿改** `diting-infra/deploy-engine` 子模块工作树 |
| **哲学挂钩** | [06](../../../../../01_顶层概念/06_投资哲学体系总纲.md)；[维度二边界](../01_实践目标与策略.md) |

---

## 一、执行顺序与依赖

| # | Step | 上游 | 关键产出 | 行数 | 文档状态 |
|---|---|---|---|---|---|
| 1 | [step_01_环境与服务骨架](./step_01_环境与服务骨架.md) | - | apps/deep_strike + FastAPI + DB + 永久规则 | 186 | ✅ L3 v1.2 |
| 2 | [step_02_数据采集](./step_02_数据采集.md) | step_01 | SoT 驱动 akshare/巨潮 + §3.5 质量矩阵 | 208 | ✅ L3 v1.2 |
| 3 | [step_03_证据链构建器](./step_03_证据链构建器.md) | step_02 | EvidenceChainBuilder 4 段流水线 | 209 | ✅ L3 v2.1 |
| 4 | [step_04_利润截留扫描仪剧本](./step_04_利润截留扫描仪剧本.md) | step_03 | LangGraph + 5 Signal + `deep-step04-*` | 163 | ✅ L3 v2.1 |
| 5 | [step_05_thesis卡片生成器](./step_05_thesis卡片生成器.md) | step_04 | 5 必填 + no-stub + D0 schema | 143 | ✅ L3 v2.1 |
| 6 | [step_06_Thesis_LoRA训练](./step_06_Thesis_LoRA训练.md) | step_05 + D5 | thesis_lora_v1（≥100 cases）| 125 | ✅ L3 v2.1 |
| 7 | [step_07_置信度评分器](./step_07_置信度评分器.md) | step_06 | 三路 0.5/0.3/0.2 + 永久规则 | 144 | ✅ L3 v2 |
| 8 | [step_08_人工确认门禁与一致率](./step_08_人工确认门禁与一致率.md) | step_07 | HumanGate + 一致率 ≥80% + thrust 推送 | 168 | ✅ L3 v2 |
| 9 | [step_09_端到端联调](./step_09_端到端联调.md) | step_08 + D1/D0 | PassEvent 真流 + TEST_ONLY 仅 tests | 163 | ✅ L3 v2 |
| 10 | [step_10_阶段验收](./step_10_阶段验收.md) | step_09 | 8 大检查 + L5 `l5-stage-d2s1` | 171 | ✅ L3 v2 |
| 11 | [step_11_估值动态评估器](./step_11_估值动态评估器.md) | step_05 | 戴维斯 4 档（双击/单击/双杀/中性）+ pe_percentile 4 周期 + industry_median + 纯函数（不调 LLM） | 240 | ✅ L3 v1.0 |

**共计**：11 份 step，**~1,920 行**（L3 实施规划体；旧版 ~9,305 行嵌入代码已剥离）。

---

## 二、关键决策与契约

| # | 关键约定 |
|---|---|
| 全局 | service_name = `deep-strike`；包路径 `apps/deep_strike/`；端口 8082 |
| **永久规则三重强制** | ① 包顶部横幅 ② `_promote_to_confirmed` 唯一确认入口 ③ 验收 `assert_no_bypass` |
| schema 双侧 | 生产侧 ≥ 50 字（消费侧维度零 ≥ 20 字），始终保证下游通过 |
| 训练 | base_model: Qwen2.5-7B；lora_rank=16；alpha=32；epochs=3；lr=2e-4 |
| 数据 | thesis ≥ 100 + risk ≥ 100；seeds（25+）+ Teacher 改写 |
| **no-mock** | 生产/Makefile 禁止 stub/mock；tests/ 内 TEST_ONLY fixture 合法 |
| Makefile | 前缀 `deep-stepNN-*`；配置驱动 `my_holdings.yaml` |
| 跨维度 | 与维度零 schema 字段级对齐（11 必填 + 2 可选 + action 枚举） |

---

## 三、L4 实践记录预期清单

| step | L4 实践记录文件名 |
|---|---|
| step_01 | `实践记录_step_01_环境与服务骨架.md` |
| step_02 | `实践记录_step_02_数据采集.md` |
| step_03 | `实践记录_step_03_证据链构建器.md` |
| step_04 | `实践记录_step_04_利润截留扫描仪剧本.md` |
| step_05 | `实践记录_step_05_thesis卡片生成器.md` |
| step_06 | `实践记录_step_06_Thesis_LoRA训练.md` |
| step_07 | `实践记录_step_07_置信度评分器.md` |
| step_08 | `实践记录_step_08_人工确认门禁与一致率.md` |
| step_09 | `实践记录_step_09_端到端联调.md` |
| step_10 | `实践记录_step_10_阶段验收.md` + `阶段总结_stage_1_启动期.md` |
| step_11 | `实践记录_step_11_估值动态评估器.md` |

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-20 | **全量 L3 v1.2 重写**：去嵌入代码；§3.5 质量矩阵；`deep-stepNN-*` Makefile 合约；no-mock；行数 ~1,680 |
| 2026-05-16 | 全部 10 个 step 文档生成完成，共 9,305 行 |
| 2026-05-17 | **索引去周次化**；L3↔L4 权威映射；跨维节拍见 **14_ §九** |
| 2026-05-27 | **本轮关键重构 §4.5**：新增 step_11 估值动态评估器（戴维斯 4 档 + 纯函数，不调 LLM）；与 D2 step_05 thesis 卡 schema 升级 + 共享规约 22 fact_gate + D3 step_09 market_phase 分类器协同；总数 10→11 |
