# Stage2-04 镜像打包与 ACR 推送

> [!NOTE] **[TRACEBACK] 步骤锚点**
> - **DNA stage_id**: `stage2_04`
> - **本步设计文档**: [04_镜像打包与ACR推送设计](../../03_原子目标与规约/Stage2_数据采集与存储/04_镜像打包与ACR推送设计.md#design-stage2-04-exit)
> - **本步 DNA 文件**: [dna_stage2_04.yaml](../../03_原子目标与规约/_System_DNA/Stage2_数据采集与存储/dna_stage2_04.yaml)

<a id="l4-step-nav"></a>
## 步骤导航
- **上一步**：[03_本地测试与K3s连调](03_本地测试与K3s连调.md#l4-stage2-03-goal)
- **下一步**：[05_采集模块部署与验收](05_采集模块部署与验收.md#l4-stage2-05-goal)

## 工作目录

**diting-core**

<a id="l4-stage2-04-goal"></a>
## 本步目标

镜像 tag = 时间+分支+版本号；DoD 含 git SHA、镜像 digest。

## 核心指令

```
你是在 diting-core 中执行 Stage2-04（镜像打包与 ACR 推送）的实践者。

任务：
1. make build 成功；镜像可推送至 Registry（ACR 或等价）。
2. Makefile 中 tag 规则：时间+分支+版本号。
3. DoD 含版本/可复现信息（git SHA、镜像 digest）。
```

<a id="l4-stage2-04-exit"></a>
## 验证与准出

| 命令 | 期望结果 |
|------|----------|
| `make build` | 退出码 0 |

**准出**：make build 成功；镜像可推送。**已更新 L5 [02_验收标准 对应行](../../05_成功标识与验证/02_验收标准.md#l5-stage-stage2_04)**。
