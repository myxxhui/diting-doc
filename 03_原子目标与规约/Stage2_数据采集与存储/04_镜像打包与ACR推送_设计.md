# L3 · Stage2-04 镜像打包与 ACR 推送设计

> [!NOTE] **[TRACEBACK] 原子规约锚点**
> - **原子规约**: [开发与交付/02_基础设施与部署规约](../开发与交付/02_基础设施与部署规约.md)
> - **DNA**: [_System_DNA/Stage2_数据采集与存储/dna_stage2_04_镜像打包与ACR推送.yaml](../_System_DNA/Stage2_数据采集与存储/dna_stage2_04_镜像打包与ACR推送.yaml)
> - **L4 实践**: [04_阶段规划与实践/Stage2_数据采集与存储/04_镜像打包与ACR推送实践](../../04_阶段规划与实践/Stage2_数据采集与存储/04_镜像打包与ACR推送实践.md#l4-stage2-04-exit)
> - **L5 锚点**: [02_验收标准#l5-stage-stage2_04](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage2_04)

<a id="design-stage2-04-goal"></a>
## 本步目标

镜像打包与 ACR（或等价 Registry）推送；Makefile tag = 时间+分支+版本号；DoD 含版本信息（git SHA、镜像 digest）。

<a id="design-stage2-04-points"></a>
## 设计要点

- **镜像 tag**：Makefile tag = 时间+分支+版本号；采集镜像推送至项目 ACR 时使用 **tag: latest**，供 Chart 默认拉取（见 [06_生产级数据要求_设计#design-stage2-06-ingest-image](06_生产级数据要求_设计.md#design-stage2-06-ingest-image)）。
- **ACR 与推送**：项目约定采集镜像推送到 **ACR**（阿里云容器镜像服务个人版）；**diting-core** 提供 **`make push-images`**（依赖 `make build-images`，打 ACR 全路径 tag 并 push）。ACR 地址、凭证配置见 [06_ 实践#镜像仓库（ACR）与本地构建推送](../../../04_阶段规划与实践/Stage2_数据采集与存储/06_生产级数据要求_实践.md#l4-stage2-06-acr-and-push)。
- **Chart 使用最新镜像**：**diting-infra** 的 **config/diting-prod.yaml** 中 **`stack.ingest.image`** 已配置为 ACR 全路径且 **tag: latest**、**pullPolicy: Always**，部署即使用本次推送的镜像。
- **DoD**：含版本/可复现信息（git SHA、镜像 digest、Chart 版本）；镜像可推送至 Registry（ACR）；可选执行 **`make push-images`** 完成推送以便 Stage2-05/06 在 K3s 使用。

<a id="design-stage2-04-exit"></a>
## 准出

make build 成功；镜像可推送至 Registry（**make push-images** 可推送到项目 ACR）；tag 符合约定；与 06_ 设计/实践中的 ACR、Chart 配置一致。
