# 实践记录 · 维度二·纵深进攻 · 启动期 · step_03 · 证据链构建器

> [!NOTE] **[TRACEBACK] 实践锚点**
> - **L3 step**: [step_03_证据链构建器.md](../../../03_原子目标与规约/02_维度二_纵深进攻/stages/stage_1_启动期/steps/step_03_证据链构建器.md)
> - **DNA**: [_System_DNA/02_deep_strike/dna_stage_1_启动期.yaml](../../../03_原子目标与规约/_System_DNA/02_deep_strike/dna_stage_1_启动期.yaml)
> - **本阶段看板**: [README.md](./README.md)

---

## 一、本步计划（来自 L3）

- 四段流水线：采集（读库）→ 财务/剪刀差等指标证据 → 时序对比 → 同业对比（依赖 `peer_metric_snapshot.gross_margin`）→ 公告证据；去重后 `EvidenceChain` 至少 3 条，不足时数据稀疏兜底；落库 `EvidenceRecord`；单测仅允许使用 `tests/` fixture + 临时库，不作为业务流准出。

---

## 二、实际进展（W3 · Composer · 已核验）

| § / 项 | 状态 | 说明 |
|---|---|---|
| `EvidenceChainBuilder` + scan_id/source_id | ✅ | 禁止 padding；`<3` 条 raise；幂等 upsert |
| `scripts/deep_step03_sync_cryo.py` | ✅ | cryo 公告 + 财报 → deep_strike；portfolio 补 state_watch 财务摘要 |
| `scripts/deep_step03_build.py` | ✅ | 全 active build + status |
| `validate_evidence_chain_quality.py` | ✅ | 启动期质量矩阵 |
| Makefile `deep-step03-*` | ✅ | 8 target |
| **`make deep-step03-all`** | ✅ | **10/10** build + quality + **9 pytest passed** |

```bash
cd diting-src && make deep-step03-all
```

---

## 三、W3 补完 Session 2 · Lighthouse-Alpha 接入（已核验）

> **口径**：W3 启动期 tier-2 闭环（见 14 节奏表 §4 末「W3 启动期 tier-1 / tier-2 口径」）。

### 3.1 A2：D2 Critic 接入 `EvidenceChainBuilder.build()`

| 项 | 状态 | 说明 |
|---|---|---|
| `build()` 新增 `critic_inputs` / `critic` 参数 | ✅ | 有 cluster 上下文时调 `TheCritic.call()` → `from_critic_output()` 入链 |
| PHYSICAL 证据 bypass 50-char 过滤 | ✅ | 拦截类（gate=false）也能入链，供 step_04 The Mapper 过滤（LC1/LC6 合规）|
| 多 cluster 同步入链 | ✅ | 每条 sniffer_cluster 一条 PHYSICAL evidence |
| Fallback / 异常容错 | ✅ | `critic.call()` 异常 / parse 失败均 log + skip，不阻塞主链 |
| 集成测试 | ✅ | `tests/deep_strike/test_evidence_builder.py` **+5 case**：gate=true / gate=false / 持久化到 DB / 多 cluster / 向后兼容；总 **14 passed** |

```bash
cd diting-src && PYTHONPATH=. python3 -m pytest tests/deep_strike/test_evidence_builder.py -q
# → 14 passed in 0.84s
```

### 3.2 A3：Architect schema 双归一化 + 3 只 fallback 重跑

| 项 | 状态 | 说明 |
|---|---|---|
| `_normalize_operator` 修 set 迭代序 bug | ✅ | 用有序 tuple + 首位最早匹配；`mom_pct_or_yoy_pct` → `mom_pct`（不再偶发 `yoy_pct`）|
| `_normalize_polling_frequency`（新） | ✅ | `weekly/hourly/realtime/intraday` → `daily`；`quarterly/annual` → `monthly_after_release`；防 Opus 自由风格输出被 Literal 拒 |
| Architect `max_tokens=4096` | ✅ | 默认 2048 会让 6 字段输出截断 → JSON 解析失败 → fallback；调高后 6 字段稳定输出 |
| 真 Opus 重跑 002837/300499/300502 | ✅ | 6 字段写入 Redis；预算消耗 ≈ ¥2.50（含一次 token 截断重试） |
| 6/6 watchlist 监控字典 0 fallback | ✅ | 600312:4 / 300308:3 / 300502:6 / 002837:6 / 300499:6 / 300602:5 共 **30 个 monitor 字段**（P5×7 / P6×11 / P7×12）|
| 单测覆盖 | ✅ | `tests/deep_strike/test_lighthouse.py` +2 case（`_normalize_polling_frequency` + `weekly→daily` 落库）；总 **21 passed** |

### 3.3 复验命令

```bash
cd diting-src
PYTHONPATH=. python3 -m pytest tests/deep_strike/ -q
# → 35 passed（14 evidence_builder + 21 lighthouse）

# 监控字典覆盖
PYTHONPATH=. python3 -c "import json, redis, os; from dotenv import load_dotenv; load_dotenv('.env')
r = redis.from_url(os.environ['SUPER_EVO_REDIS_URL'], decode_responses=True)
for s in ['600312','300308','300502','002837','300499','300602']:
    keys = [k for k in r.keys(f'monitor:{s}:dict:*') if not k.endswith(':_meta')]
    print(s, len(keys))"
# → 600312 4 / 300308 3 / 300502 6 / 002837 6 / 300499 6 / 300602 5
```

---

## 修订记录

| 日期 | 内容 |
|---|---|
| 2026-05-17 | 初稿：四段流水线 + 单测 |
| 2026-05-23 | **W3 Composer**：cryo 同步 + Makefile + 10 只 active 证据链 build 全绿 |
| 2026-05-23 | **no-mock 重验**：与 cryo 真库联动；`make deep-step03-all` → build 10/10 + 9 pytest passed ✅；evidence_records 总计 69 条；准出通过 |
| 2026-05-24 | **W3 补完 Session 2 · tier-2 闭环（A2+A3）**：①`EvidenceChainBuilder.build()` 新增 `critic_inputs/critic` 参数 + PHYSICAL bypass 50-char + 5 个集成测；②Architect schema 双归一化（operator set→tuple；新增 polling_frequency `weekly→daily`/`quarterly→monthly_after_release`）+ `max_tokens=4096`；③真 Opus 重跑 3 只 fallback（002837/300499/300502）→ **6/6 watchlist 0 fallback、30 个 monitor 字段**；deep_strike pytest **35 passed**（14+21）|
