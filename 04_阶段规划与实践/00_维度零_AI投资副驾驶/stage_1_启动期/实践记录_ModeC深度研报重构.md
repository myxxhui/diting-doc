# 实践记录 · Mode C 深度研报重构（方案A · 自给式 Opus）

> [!NOTE] **[TRACEBACK] 追溯锚点**
> - **架构脊柱 L3**：[25_四区漏斗_三段流水线_架构脊柱_设计 §2.2](../../../03_原子目标与规约/_共享规约/25_四区漏斗_三段流水线_架构脊柱_设计.md)（Mode C 自给式落地）
> - **Step L3**：[step_14 行情雷达扫描与三段流水线 §3.1](../../../03_原子目标与规约/00_维度零_AI投资副驾驶/stages/stage_1_启动期/steps/step_14_行情雷达扫描与三段流水线.md)（模式 C 三段映射 · 自给式 Opus 深度研报）
> - **需求主表**：[24_行情解析与规划工作台_需求实现表 §9.4](../../../03_原子目标与规约/_共享规约/24_行情解析与规划工作台_需求实现表.md)（Mode C 重构说明）
> - **工作目录**：`diting-src`

---

## 一、背景：为什么要重构 Mode C

step_14~17 完成后，雷达模式 C（标的深度分析）在生产环境全部维度呈 pending 空壳状态，根因诊断：

|| 症状 | 根因 |
||---|---|
|| 生态位/龙头/壁垒/利润质量/阶段/利好窗/风险 全部 pending | 依赖上游 D2 deep_strike（Lighthouse Sniffer/Critic/Architect）、D3 state_watch（market_phase/MonitorDictReader）、D1 cryo_guard（decision_gate） |
|| 上游引擎在生产全空 | deep_strike 需预先 ingest；state_watch monitor:dict 需按标的填充；cryo_guard gate 未实现 |
|| T2 默认关 | `RADAR_T2_ENABLED=false` 控成本，但 T2 关时 Mode C 无法完成深度推理 |

**用户决策**：方案A · 自给式——Mode C 不再依赖上游引擎，改为 **T0 直采 akshare 真实数据** + T1 压缩事实矩阵 + **T2 必开 Opus** 输出固定 9 维结构化 JSON（每维含 `verdict+reasoning+evidence[]+confidence`），**成本显示**，失败返回 `status=error`+detail，**守 no-mock（绝不伪 pending、不造假）**。

---

## 二、实际进展（待回填）

### 2.1 数据模型与三段流水线（Mode C 自给式）

**T0 真实采集（直采 akshare）**：
- 行情 K 线（`stock_zh_a_hist`·腾讯/新浪/akshare 降级）
- 个股资料（`stock_individual_info_em`·行业/市值/上市日期）
- 财务摘要（`stock_financial_abstract`·营收/净利/毛利率/ROE/资产负债率）
- 估值分位（`stock_a_indicator_lg`·PE/PB 历史序列→`pe_percentile`）
- 同业（best-effort，缺则 null）
- **接口不可达时**：返回 `status=error`+detail，该维度 `error`，Opus 仍基于其余真实数据推理

**T1 矩阵压缩**：
- 把 T0 raw 压成紧凑**事实矩阵**（关键财务指标+行情+估值分位+同业对比），省 token
- `ContextMatrixBuilder`（启动期纯规则，`t1_fallback=rule`）

**T2 必开 Opus**：
- 读事实矩阵 → **固定 9 维结构化 JSON**：
  - `niche`（生态位）
  - `value_chain`（价值链）
  - `is_leader`（是否龙头）
  - `moat`（壁垒）
  - `profit_quality`（利润质量）
  - `market_phase`（市场阶段：concept 概念/expectation 预期/realization 兑现/exhaustion 退潮）
  - `catalyst_timeline`（利好时间线）
  - `risk`（风险）
  - `valuation`（估值 · 含戴维斯双击判定）
- 每维含：`verdict+reasoning+evidence[]+confidence`
- 外加 `overall{conclusion, action_advisory, confidence}`
- `AIDispatcher.call(scene=radar_assess, model="claude-opus-4-6")` · **强制** `RADAR_T2_ENABLED=true`
- **成本显示**：`cost_yuan_est/tokens_in/tokens_out/model`

### 2.2 落库（复用现有表，无新表）

- 9 维 verdict 填 `radar_candidates` 列（`niche_text/value_chain_pos/is_leader/moat_level/profit_quality/market_phase/catalyst_window/risk_summary/valuation_verdict`）
- 完整 9 维 JSON 存 `raw_json.analysis_snapshot.deep_analysis`
- 成本入 `scan.summary_json`（`cost_yuan_est/tokens_in/tokens_out/model`）

### 2.3 前端（从 chip 行改为人类可读研报卡）

**原设计**：候选评估卡显示为 chip 行（如 `niche: pending | moat: pending | ...`）+ JSON 链接

**重构后**：
- **9 维研报卡**：每维一个区块，含 verdict 徽章（如 `✅ 强`/`⚠️ 中`/`❌ 弱`/`⏳ error`）+ 推理段落 + 证据列表 + 置信度条（0-1 可视化）
- **成本徽章**：显示本次扫描成本（如 `¥0.8 · 15k in / 3k out · claude-opus-4-6`）
- **三段溯源折叠区**：点击展开，显示 T0 raw → T1 distilled → T2 verdict 三段 `stage_artifacts` 链接（可跳转查看每段 payload_json）

---

## 三、验证结果（待用户回填）

### 3.1 本机验收

> **待回填**：由主代理（用户）落地后执行以下验证，并在此处填写验证输出。

**验证步骤**（供参考）：
```bash
cd diting-src
# 1) 建表（若已建则跳过）
make copilot-step14-migrate
# 2) Mode C 扫描（T2 必开，输入 1 标的）
RADAR_SYMBOL=601138 RADAR_T2_ENABLED=true make copilot-step14-scan
# 3) 检查候选 9 维
curl -s "http://127.0.0.1:8080/api/radar/scans/1" | jq '.candidates[0] | {symbol, niche_text, is_leader, moat_level, profit_quality, market_phase, catalyst_window, risk_summary, valuation_verdict, confidence}'
# 4) 检查成本
curl -s "http://127.0.0.1:8080/api/radar/scans/1" | jq '.summary_json.cost_yuan_est'
# 5) 三段 artifact + 溯源
curl -s "http://127.0.0.1:8080/api/radar/candidates/1/artifacts" | jq 'group_by(.stage)|map({stage:.[0].stage, n:length, model:.[0].model_id})'
# 6) no-auto-execute
rg -i "buy|qmt|auto_trade|order_id|webhook_target|立即|一键|下单" apps/copilot/modules/radar/ apps/copilot/templates/planning/   # 应为 0
```

### 3.2 生产 K3s 验收（2026-05-31 实测）

**部署链路全绿**：重拉 Spot ECS（HK `cn-hongkong-b`，复用数据盘 `d-j6ce444m0p0kf0jwxhcu`）→ `platform-step03-up`（timescaledb/pg-l2/redis/schema-init/module_a/copilot 全部 deployed）→ Mode C 镜像构建推 ACR（含 akshare 1.18.64 + anthropic 0.105.2）→ AI-sync 注入 `ANTHROPIC_API_KEY`+`RADAR_T2_ENABLED=true` → revision 4 deployed、copilot rollout 完成、pod env 核验到位。

**部署期修复（真实 bug）**：`copilot-sync-ai-from-src-env.sh` 仅传 copilot 子集 values，helm 重渲染把 `diting-db-connection` 的 DSN 退回 `default` 命名空间 → schema-init 连不上 → helm `--wait` 超时。修复：脚本补 `ingest/module_a.timescaleHost/postgresL2Host` + `storage.*.pvc.namespace` 的 platform-ns 覆盖（对齐 platform-step03）。

**601138 真扫被网络地域墙阻塞（待解）**——逐项 pod 内实测：

| 链路 | 实测 | 根因 |
|---|---|---|
| T2 → `api.anthropic.com` | `403 forbidden: Request not allowed` | Anthropic 地域封锁 HK/大陆 IP |
| T0 → akshare(东财 push2) | `ConnectionError: RemoteDisconnected` | 东财对海外(HK)出口拒连/不稳 |

核心矛盾：akshare 要大陆友好 IP、Anthropic 要非大陆 IP，HK 节点两者皆不满足。**no-mock 策略正确生效**：T2 失败 → `t2_status=error` + 前端红条，绝不伪造。

**一键代理修复已就绪**：`diting-stack` chart `copilot/secret.yaml` 新增条件 `HTTPS_PROXY/HTTP_PROXY/NO_PROXY`（`envFrom` 自动注入 pod）；`copilot-sync-ai-from-src-env.sh` 从 `diting-src/.env` 读 `HTTPS_PROXY` 注入；`.env`/`.env.template` 加注释占位。**下次**：填 `HTTPS_PROXY`（需同时可达东财与 Anthropic）→ `make up-stack diting-stack && make platform-step03-up && make copilot-modec-deploy` 一键真扫。

**资源**：验收完用户选择关停止血 → `make down-stack diting-stack`（4 项 destroyed，数据盘与永驻 10 项保留，费用停）。

---

## 四、no-mock & no-auto-execute 红线审计

- **no-mock**：akshare 接口失败返回 `status=error`+detail（该维度 error），Opus 仍基于其余真实数据推理；**绝不伪造 pending 或用随机值冒充真实数据**。
- **no-auto-execute**：候选评估与晋级操作全 `human_confirmation_required=True`、`execute_mode=advisory`，须人工确认按钮触发；无 `buy/qmt/auto_trade/order_id/webhook_target/立即/一键/下单` 等禁止词。

---

## 五、一致性检查表

- [x] 引用具体 L3（step_14 §3.1 + 25_架构脊柱 §2.2）
- [x] 工作目录标注 `diting-src`
- [x] 端到端 Mode C 自给式设计已同步至 L3 step_14 §3.1 与 25_架构脊柱 §2.2
- [ ] 本机验收完成（待用户回填）
- [x] 生产部署链路全绿（ECS/平台栈/镜像/AI-env 注入/rollout，2026-05-31）
- [ ] 生产 601138 真扫 `t2_status=ok`（**阻塞**：东财+Anthropic 双双被 HK 地域墙挡；待用户提供全局出口代理 `HTTPS_PROXY` 后一键重扫）
- [x] 关键重构已按 §4.5 同步 step_14、25_架构脊柱、24_需求实现表
- [x] no-mock & no-auto-execute 红线明确
