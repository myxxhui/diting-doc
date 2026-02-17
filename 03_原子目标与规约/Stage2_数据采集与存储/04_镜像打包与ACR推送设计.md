# L3 · Stage2-04 镜像打包与 ACR 推送设计

> [!NOTE] **[TRACEBACK] 原子规约锚点**
> - **原子规约**: [开发与交付/02_基础设施与部署规约](../开发与交付/02_基础设施与部署规约.md)
> - **DNA**: [_System_DNA/Stage2_数据采集与存储/dna_stage2_04.yaml](../_System_DNA/Stage2_数据采集与存储/dna_stage2_04.yaml)
> - **L4 实践**: [04_阶段规划与实践/Stage2_数据采集与存储/04_镜像打包与ACR推送](../../04_阶段规划与实践/Stage2_数据采集与存储/04_镜像打包与ACR推送.md#l4-stage2-04-exit)
> - **L5 锚点**: [02_验收标准#l5-stage-stage2_04](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage2_04)

<a id="design-stage2-04-goal"></a>
## 本步目标

镜像打包与 ACR（或等价 Registry）推送；Makefile tag = 时间+分支+版本号；DoD 含版本信息（git SHA、镜像 digest）。

<a id="design-stage2-04-points"></a>
## 设计要点

- **镜像 tag**：Makefile tag = 时间+分支+版本号
- **DoD**：含版本/可复现信息（git SHA、镜像 digest、Chart 版本）

<a id="design-stage2-04-exit"></a>
## 准出

make build 成功；镜像可推送至 Registry；tag 符合约定。
