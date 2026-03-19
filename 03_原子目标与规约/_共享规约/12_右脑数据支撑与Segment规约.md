# L3 · 右脑数据支撑与细分规约

> [!NOTE] **[TRACEBACK] 原子规约锚点**
> - **顶层概念**: [一句话定义与核心价值](../../01_顶层概念/01_一句话定义与核心价值.md)
> - **战略维度**: [数据架构与分层存储维度](../../02_战略维度/产品设计/03_数据架构与分层存储维度.md)
> - **原子规约**: [11_数据采集与输入层规约](./11_数据采集与输入层规约.md)、[09_核心模块架构规约](./09_核心模块架构规约.md)
> - **对应 DNA**: `global_const.yaml#data_ingestion.right_brain_data`、`global_const.yaml#segment_registry`（若存在）；步骤级见 Stage2-02、Stage3-01、Stage3-04 DNA
> - **本文档**: L3 层级，定义 A 轨右脑（Module C）所需「标的主营业务构成 + 垂直细分一手信号」的数据分层、表结构、接口与按需拉取流程，确保 C 能做「利好与主营对齐」判断

## 一、目标与约束

### 1.1 目标

- **基础数据**：标的级「主营业务构成」可统一采集、统一结构写入 L2，供 Module A 扩展输出与 Module C 消费。
- **垂直一手信号**：按**细分领域**组织，接口多样、无法用一套通用模板覆盖；采用「细分注册 + 按需拉取」：仅对**当日左脑候选标的**所涉及的细分去重后拉取并缓存，供 C 消费。
- **C 右脑输入**：除 Tag、QuantSignal、知识库外，增加「标的 → 多组（细分标识、营收占比、是否主营）」与「各细分的垂直一手信号摘要」，使专家能做「利好是否直指该公司主营、主营市占与竞争力」等维度判断。

### 1.2 约束

- 不预拉「全市场所有标的」的「所有垂直领域一手信息」；候选集合每日动态，仅对当日涉及细分拉取。
- 新细分/新数据源通过「注册细分 + 挂接适配器」扩展，不改全量预拉逻辑。
- 开发期（27 标）与生产期（全 A 股）共用同一套表与流程，仅细分覆盖与适配器数量不同。

---

## 二、数据分层与存储契约

### 2.1 第一层：基础数据（可统一采集）

| 数据类型 | 用途 | 目标存储 | 采集方 | 消费方 |
|----------|------|----------|--------|--------|
| 标的列表、申万行业、营收占比 | Module A 现有输入 | L2 `industry_revenue_summary` 等 | 采集层（11_） | Module A |
| **主营业务构成** | 标的→多组（细分、占比）；A 扩展输出、C 与信号层解析细分 | L2 **标的主营构成表**（`symbol_business_profile`） | 采集层（本规约约定任务） | Module A、信号层、Module C |

**标的主营构成表 DDL（L2 PostgreSQL，表名 `symbol_business_profile`）**

```sql
-- 标的-主营业务构成（每标的多行：每行一个 segment + 占比）
CREATE TABLE IF NOT EXISTS symbol_business_profile (
  id           BIGSERIAL PRIMARY KEY,
  symbol       VARCHAR(32) NOT NULL,
  segment_id   VARCHAR(64) NOT NULL,
  revenue_share NUMERIC(5,4) NOT NULL CHECK (revenue_share >= 0 AND revenue_share <= 1),
  market_share_optional VARCHAR(128) DEFAULT NULL,
  is_primary   BOOLEAN NOT NULL DEFAULT FALSE,
  source       VARCHAR(32) NOT NULL DEFAULT 'akshare',
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(symbol, segment_id)
);

CREATE INDEX idx_symbol_business_profile_symbol ON symbol_business_profile(symbol);
CREATE INDEX idx_symbol_business_profile_segment ON symbol_business_profile(segment_id);
COMMENT ON TABLE symbol_business_profile IS '标的主营业务构成：细分标识须在细分注册表中已注册';
```

- **细分标识**（segment_id）：必须为细分注册表中已存在值；采集写入前校验，否则丢弃或写回退（见 2.2）。
- **是否主营**（is_primary）：同一标的下仅一条为 TRUE（营收占比最高的一条）。
- **营收占比**（revenue_share）：该细分营收占比，0~1；同一标的下各行之和可 ≤1（允许部分未映射）。

### 2.2 细分注册表（L2 或配置）

**细分注册表 DDL（L2 PostgreSQL，表名 `segment_registry`）**

```sql
CREATE TABLE IF NOT EXISTS segment_registry (
  segment_id             VARCHAR(64) PRIMARY KEY,
  domain                 VARCHAR(16) NOT NULL,  -- 农业 | 科技 | 宏观
  sub_domain             VARCHAR(64) DEFAULT NULL,
  name_cn                VARCHAR(128) NOT NULL,
  signal_adapter_id      VARCHAR(64) DEFAULT NULL,
  signal_refresh_ttl_sec INT DEFAULT 3600,
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE segment_registry IS '细分领域注册表；标的主营构成表.细分标识 外键逻辑依赖此表';
```

- **信号适配器标识**（signal_adapter_id）：为空表示该细分暂无一手信号源；C 侧按 4.4 降级。
- **领域**（domain）：与现有领域标签一致，取值为**农业/科技/宏观**（与 L2 primary_tag、代码存储一致，以中文为主便于过滤）。

**segment_id 分层约定（做在 segment 设计里，不推翻按细分拉取）**

- **层级定义（共三层，满足 B 轨生产要求；设计上可扩展）**：每一层在 segment_registry 中**各建一行**（含 domain、sub_domain），并挂 signal_adapter_id。**B 轨生产最低要求**为以下**三层**；实现与配置应显式支持此三层，并预留扩展（如可选 tier 字段、层级枚举），以便未来增加第四层（如子业务/产品线）时仅扩展枚举与适配器即可。
  - **第 1 层 · domain 级（大盘/大方向）**：如 `tech`、`agri`、`geo`；对应大盘/指数/宏观类数据源。
  - **第 2 层 · 板块级**：如 `tech_ai`、`tech_semiconductor`；对应板块指数、板块新闻。
  - **第 3 层 · 具体业务级**：如 `tech_ai_factory`、`tech_ai_compute`；对应垂直政策/研报/产品等。
- **命名**：segment_id 建议用「domain[_板块][_业务]」形式，便于从 ID 推断层级；示例见下表。
- **标的主营构成**：symbol_business_profile 中**同一标的可挂多个层级的 segment_id**（例如既有 tech 也有 tech_ai 也有 tech_ai_factory），一次 refresh 会自然拉取「大方向 + 板块 + 具体业务」三层信号。
- **补写 domain/板块级**：若希望「即使没有具体业务也拉大盘+板块」，在 **ingest_business_profile** 或符号-细分映射规则里，按申万/行业标签为标的**补写**其第 1 层、第 2 层 segment_id（如科技股自动挂 tech、tech_ai）；见 Stage2-01_B轨 实践与 3.1 采集层。
- **适配器侧**：第 1 层 segment_id → 大盘/指数/宏观数据源；第 2 层 → 板块指数、板块新闻；第 3 层 → 垂直政策/研报/产品；仍为一个 segment_id 一个或一组数据源，人写适配器，不 AI 写抓取。
- **超出生产的扩展**：segment_registry 可预留或扩展「层级标识」（如 tier 或 segment_tier：1=domain/2=sector/3=business），实现时按层级枚举选数据源与适配器，便于后续新增第 4 层等而不改核心流程。

**初始/示例 细分标识 枚举（与领域、层级对应）**

| 细分标识 | 层级（第几层） | 领域 | 子领域 | 中文名 | 信号适配器标识 |
|----------|----------------|------|--------|--------|----------------|
| tech | 第 1 层（domain） | 科技 | — | 科技大盘 | 可选 |
| tech_ai | 第 2 层（板块） | 科技 | AI | AI 板块 | 可选 |
| tech_ai_factory | 第 3 层（具体业务） | 科技 | AI | AI 工厂 | 可选 |
| tech_ai_compute | 具体业务级 | 科技 | AI | AI 算力 | 可选 |
| tech_semiconductor | 第 2 层（板块） | 科技 | 半导体 | 半导体板块 | 可选 |
| tech_semiconductor_fab | 第 3 层（具体业务） | 科技 | 半导体制造 | 半导体制造 | 可选 |
| tech_semiconductor_design | 第 3 层（具体业务） | 科技 | 半导体设计 | 半导体设计 | 可选 |
| agri | 第 1 层（domain） | 农业 | — | 农业大盘 | 可选 |
| agri_pork_cycle | 第 3 层（具体业务） | 农业 | 生猪 | 猪周期 | 可选 |
| agri_grain | 第 3 层（具体业务） | 农业 | 粮食 | 粮食种植 | 可选 |
| geo | 第 1 层（domain） | 宏观 | — | 宏观 | 可选 |
| geo_copper | 第 3 层（具体业务） | 宏观 | 铜 | 铜/有色金属 | 可选 |
| geo_crude | 第 3 层（具体业务） | 宏观 | 原油 | 原油 | 可选 |

实现时由采集或初始化脚本插入；新增细分先写入本表再写入标的主营构成表。

### 2.3 第二层：垂直一手信号（按细分、按需拉取）

| 数据类型 | 用途 | 目标存储 | 拉取方 | 消费方 |
|----------|------|----------|--------|--------|
| **细分级一手信号** | 政策/价格/大单/研发等摘要，按细分组织 | L2 **细分信号缓存表**（`segment_signal_cache`）或 Redis | **信号层**（见 3.2） | Module C |

**细分信号缓存表 DDL（L2 PostgreSQL，表名 `segment_signal_cache`）**

```sql
CREATE TABLE IF NOT EXISTS segment_signal_cache (
  segment_id     VARCHAR(64) PRIMARY KEY,
  signal_summary TEXT NOT NULL,
  signal_at      TIMESTAMPTZ,
  fetched_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ttl_sec        INT NOT NULL DEFAULT 3600
);
CREATE INDEX idx_segment_signal_cache_fetched ON segment_signal_cache(fetched_at);
```

- **信号摘要**（signal_summary）：文本或 JSON 摘要，供 C 与 AI 消费；具体结构由各适配器约定，实现时可为 JSONB。
- **过期秒数**（ttl_sec）：拉取逻辑根据细分注册表的刷新 TTL 判断是否刷新。

**信号适配器注册表（可选 L2 表或 YAML 配置）**

若用表存储：

```sql
CREATE TABLE IF NOT EXISTS signal_adapter_registry (
  adapter_id       VARCHAR(64) PRIMARY KEY,
  segment_id       VARCHAR(64) NOT NULL REFERENCES segment_registry(segment_id),
  adapter_type    VARCHAR(32) NOT NULL,
  config_schema   JSONB DEFAULT '{}',
  pull_mode       VARCHAR(16) NOT NULL DEFAULT 'on_demand',
  last_success_at TIMESTAMPTZ,
  last_error      TEXT,
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

- **拉取模式**（pull_mode）：`on_demand` 表示仅在被请求时拉取；不预拉全量。

---

## 三、流程与接口（可执行逻辑）

### 3.1 采集层：主营业务构成写入

- **任务名**：`ingest_business_profile`（可与行业/营收采集合并为同一任务的不同步骤，或独立任务）。
- **输入**：当前全 A 股标的池（或本批标的列表）。
- **逻辑**：
  1. 从 AkShare 或约定数据源拉取「标的 → 主营业务/产品营收占比」等（具体接口见 Stage2-02 设计）。
  2. 将「产品/行业」映射为已注册的**细分标识**（查细分注册表）；无法映射的用回退（如申万二级代码或未知细分，若允许则注册 unknown）。
  3. **可选：按申万/行业标签为标的补写 domain 级、板块级 segment_id**（如科技股自动挂 tech、tech_ai），使无具体业务映射的标的也能在一次 refresh 时拉取「大盘+板块」信号；见 2.2 segment_id 分层约定。
  4. 对每个标的写入**标的主营构成表**：每行（标的、细分标识、营收占比、是否主营、来源、更新时间）；同一标的可多行（含多层级 segment_id）；同一标的下营收占比最高的一行设为主营。
- **输出**：L2 标的主营构成表已更新；更新时间可用来做新鲜度检查。
- **校验**：写入前细分标识须在细分注册表中存在；否则跳过该行或写回退并记日志。

### 3.2 信号层：按候选标的解析细分并按需拉取

- **触发时机**：当日左脑（A+B）产出**候选标的列表**之后（如技术分>70 且 Tag≠UNKNOWN 的标的列表）。
- **输入**：候选标的列表（及可选：A 扩展输出的细分列表，若已计算则直接用）。
- **步骤**：
  1. **解析细分集合**：对每个候选标的查 L2 标的主营构成表得到其细分标识列表；合并去重得 **S = {s1, s2, ...}**。
  2. **按细分拉取**：对 S 中每个细分标识：
     - 查细分注册表得信号适配器标识；
     - 若为空，跳过该细分（C 侧按 4.4 降级）；
     - 若存在，查信号适配器注册表取适配器，执行一次拉取（或若细分信号缓存中该细分未过期则跳过）；
     - 将结果写入**细分信号缓存表**（细分标识、信号摘要、信号时间、拉取时间、过期秒数）。
  3. **输出**：缓存表/Redis 中具备候选标的所涉全部细分的当前信号摘要。
- **实现归属**：在 **Stage2 [06_B轨_信号层生产级数据采集_实践](../../04_阶段规划与实践/Stage2_数据采集与存储/06_B轨_信号层生产级数据采集_实践.md)** 实现与验收，设计见 [06_B轨_信号层生产级数据采集_设计](../Stage2_数据采集与存储/06_B轨_信号层生产级数据采集_设计.md)；可在 diting-core 内实现。接口约定见下。

**接口约定（信号层）**

- **输入**：候选标的列表。
- **输出**：无直接返回值；副作用为更新细分信号缓存表。
- **方法名建议**：`refresh_segment_signals_for_symbols(symbols)`；内部实现：解析细分集合 → 去重 → 按细分拉取并写缓存。

### 3.3 Module A 扩展输出

- **读取**：L2 标的主营构成表（按标的查，得该标的所有细分行）。
- **输出扩展**：ClassifierOutput 除 Domain Tag、置信度外，增加**主营占比列表**（segment_shares）：`repeated { 细分标识、营收占比、是否主营 }`；与 [04_全链路通信协议矩阵](./04_全链路通信协议矩阵.md) ClassifierOutput 扩展一致（见 5.1）。
- **规则**：仅输出已在细分注册表中注册的细分标识；未命中主营构成的标的主营占比列表可为空。

### 3.4 Module C 消费

- **输入**（在现有基础上增加）：
  - **(a)** 标的的细分列表：来自 A 的 ClassifierOutput.segment_shares 或直接查 L2 标的主营构成表（按标的）。
  - **(b)** 各细分的一手信号：按 (a) 中的细分标识列表从**细分信号缓存表**读取；缺失的细分按 4.4 降级。
- **专家逻辑**（必须实现的判断维度）：
  - **利好与主营对齐**：将知识库/新闻中的利好与 (a)(b) 匹配；仅当利好明确落在该标的主营细分上时提高 is_supported/confidence。
  - **多细分聚合**：规约固定一种策略，例如「主营细分一票否决」或「按营收占比加权置信度，任一细分风险达阈值则整体否决」；见 dna_module_c 或 09_。
- **多维度打分**（建议）：行业泛利好强度、标的在该细分市占/竞争力、利好与垂直业务匹配度、风险因素；每维注明数据来源（主营构成表 / 细分信号缓存 / 知识库）。
- **理由摘要与结构化维度**：C 在理由摘要中须含可解析的「对齐得分、景气强度、风险等级、利好强度」；风险等级高/中/低对应确信度降权。详见 [04_A轨_MoE议会_设计#C 模块设计要求](../Stage3_模块实践/04_A轨_MoE议会_设计.md#design-stage3-04-requirements)。

---

## 四、降级与校验

### 4.1 基础数据缺失

- **标的主营构成表无该标的**：A 仍输出 Domain Tag；主营占比列表为空；C 仅用 Tag + 知识库 + QuantSignal 做判断，并记日志「无主营构成」。
- **细分标识未在细分注册表**：采集写入时丢弃该行或写回退（若项目允许未知细分）；A 输出时仅输出已注册细分。

### 4.2 信号缺失

- **某细分无信号适配器标识**：信号层不拉取；C 读细分信号缓存时该细分无行，按 4.4 处理。
- **拉取失败**：记录最近错误；不阻塞 C；C 对该细分按 4.4 降级。

### 4.3 细分信号缺失时 C 的行为（R-S4）

- 当某标的的某主营细分在**细分信号缓存表**中无有效行（或已过期）时：
  - **选项 A**：该细分不参与打分；仅用有信号的细分 + 基础数据 + 知识库做判断；若全部无信号则降置信度并记日志。
  - **选项 B**：该细分仍参与打分，但信号摘要用「无」或占位文本，专家逻辑中视为「无垂直信号支撑」并可能降权。
- 项目在 DNA 或 09_ Module C 中固定选用一种；推荐**选项 A**。

### 4.4 数据新鲜度

- **标的主营构成表.更新时间**：采集任务按日或按批更新；C 可读该字段判断是否使用；若过期可记日志并降权。
- **细分信号缓存表.拉取时间 / 过期秒数**：拉取前若未过期可跳过拉取，直接读缓存。

---

## 五、与现有规约的衔接

- **11_ 数据采集与输入层规约**：新增数据类型「主营业务构成」→ 目标存储 L2 标的主营构成表；新增任务 ingest_business_profile（或合并入行业/营收采集）；消费方为 Module A（扩展）、信号层、Module C。C 所需细分级一手信号由**信号层**按需拉取，不纳入 11_ 全量预拉。
- **09_ Module A**：输入增加 L2 标的主营构成表（或由上游写入后传入）；输出增加 ClassifierOutput.segment_shares（主营占比列表，见 04_）。
- **09_ Module C**：输入明确增加「标的细分列表 + 各细分垂直一手信号」；专家逻辑增加「利好与主营对齐」「多细分聚合」引用本规约。
- **04_ 全链路通信协议矩阵**：ClassifierOutput 增加可选字段 repeated SegmentShare segment_shares（主营占比列表，见下 5.1）。

### 5.1 ClassifierOutput 扩展（Proto）

在现有 ClassifierOutput 中增加（若尚未存在）；字段含义：细分标识、营收占比、是否主营。

```protobuf
message SegmentShare {
  string segment_id = 1;   // 细分标识
  double revenue_share = 2;  // 营收占比
  bool is_primary = 3;    // 是否主营
}
// 在 ClassifierOutput 中增加：
repeated SegmentShare segment_shares = N;  // N 为当前未占用的字段号
```

- 与 L2 标的主营构成表一行对应一个 SegmentShare；同一标的多条即 repeated。

---

## 六、可执行验收（设计层）

| 验收项 | 说明 | 可执行证明 |
|--------|------|------------|
| 表存在 | L2 中存在标的主营构成表、细分注册表、细分信号缓存表 | psql \dt 或 schema-init 脚本执行成功 |
| 采集写入 | ingest_business_profile 或等价步骤能写入标的主营构成表，且细分标识均在细分注册表中 | 写入后 SELECT 有行；细分标识外键逻辑满足 |
| 信号层 | refresh_segment_signals_for_symbols 能解析细分并更新细分信号缓存表 | 调用后对应细分行存在且拉取时间更新 |
| A 输出 | ClassifierOutput 含 segment_shares（主营占比列表），与标的主营构成表一致 | 单测或集成测断言 segment_shares 非空（当主营构成有数据时） |
| C 输入 | C 能读取 (a) 细分列表 (b) 细分信号缓存表；专家逻辑中能引用「利好与主营对齐」 | 单测或集成测 Mock 主营构成 + 缓存，断言 C 输出推理摘要或置信度与输入一致 |

---

## 七、准出

- 本规约与 11_、09_、04_、Stage2-02、Stage3-01、Stage3-04 设计/实践一致；表结构、接口、降级策略已固定，可供 AI 或实现者按文档完成实现逻辑。
- 新增 L3 文档须在 03_ README 的「L3 文档 ↔ DNA 子树」表中登记；本规约对应 global_const#data_ingestion 与相关步骤级 DNA（Stage2-02、Stage3-01、Stage3-04）。
