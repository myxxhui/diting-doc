# _System_DNA / core_modules

> 跨模块共享元数据（核心公式、四大模块元定义、共用枚举/词表等）。
> 与 03_/_共享规约/ 对齐；任何变更须按系统规则 §4.5 同步。

## 当前状态（2026-05-13 第 3 批完成）

| 文件 | 用途 | 状态 |
|------|------|------|
| `dna_pillar_definitions.yaml` | 四大模块 + 前端 + shared_platform 元定义（cn/en/role/scope/exit/color），是 `../global_const.yaml#vision.pillars` 的真相源 | ✅ |
| `dna_core_formulas.yaml` | 议会一致性、预期差、状态机迁移、四大退出模型、风控约束、推理成本预算等共用公式 | ✅ |
| `dna_subject_taxonomy.yaml` | 标的 / 行业 / segment / 证据类型枚举 | ✅ |
| `dna_severity_taxonomy.yaml` | 全局严重度 / 通知通道矩阵 / 风险事件严重度映射 | ✅ |

## 引用建议

- 跨模块共用的常量优先放此目录；模块独有的常量放各模块 DNA 子目录
- 严禁与 `../global_const.yaml` 顶层键重复定义；如需细化，使用引用而非拷贝
- 各 pillar DNA 引用本目录建议格式：
  ```yaml
  refs:
    severities: ../../core_modules/dna_severity_taxonomy.yaml#severities
    formulas:   ../../core_modules/dna_core_formulas.yaml#exit_models
  ```

## 维护

- 新增 pillar 须先更新 `dna_pillar_definitions.yaml` 再修改 `../global_const.yaml`
- 公式或枚举变更须按 §4.5 同步至本协议（00_系统规则）相应章节
