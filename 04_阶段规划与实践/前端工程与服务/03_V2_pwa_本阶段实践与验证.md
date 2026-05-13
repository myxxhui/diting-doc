# L4 · 前端工程与服务 · 03 V2 PWA + 协同 本阶段实践与验证

> [!NOTE] **[TRACEBACK]**
> - **L3 设计**：[前端工程与服务/05_实施推演_设计.md#四v2生产稳态](../../03_原子目标与规约/前端工程与服务/05_实施推演_设计.md#四v2生产稳态)
> - **DNA**：[`dna_frontend_v2.yaml`](../../03_原子目标与规约/_System_DNA/frontend/dna_frontend_v2.yaml)
> - **L5 准出**：[`02_验收标准.md#l5-frontend-v2-pwa`](../../05_成功标识与验证/02_验收标准.md#l5-frontend-v2-pwa)

<a id="l4-frontend-v2-pwa-goal"></a>
## 一、本阶段目标
- **stage_id**: `frontend_v2_pwa`
- **工作目录**: `diting-src/web/`
- **依赖**: `frontend_v1_full`
- **里程碑**: PWA + 离线 + 多端（移动 / 桌面 Tauri）+ 实时协作 + 多 BFF 集群 + Edge BFF

## 二、本步骤落实的 DNA 键
- `pwa_offline`：缓存策略 + 安装 + 推送
- `mobile_pwa_capacitor_or_native_shell`
- `desktop_tauri`
- `realtime_collaboration_yjs`
- `bff_multi_cluster_with_edge`

## 三、实施内容（5D）
1. PWA 配置（manifest + sw + 离线缓存）
2. 移动壳（Capacitor 或纯 PWA）+ 桌面壳（Tauri）
3. Yjs / CRDT 协作（议会同看、看板共编）
4. BFF 多集群 + Edge BFF（按区域路由）
5. 离线提交 → 上线对账（与 server 时序合并）

## 四、可执行验证清单
| 命令 | 工作目录 | 期望 |
|------|---------|------|
| `pnpm pwa:audit` | diting-src/web | Lighthouse PWA 100 |
| `pnpm e2e:offline` | diting-src/web | 离线下浏览 + 提交后对账成功 |
| `pnpm collab:bench` | diting-src/web | 多人编辑无冲突 |
| `pnpm edge-bff:smoke` | diting-src/web | 多区域延迟达标 |

## 五、准出检查清单
- [ ] PWA 评分达标
- [ ] 离线提交对账无丢失
- [ ] 协作无冲突
- [ ] **已更新 [`02_验收标准.md#l5-frontend-v2-pwa`](../../05_成功标识与验证/02_验收标准.md#l5-frontend-v2-pwa)**

<a id="l4-frontend-v2-pwa-exit"></a>
## 六、L5 准出锚点
`l5-frontend-v2-pwa`

## 七、本步骤失败时
- 离线对账冲突 → 提示用户人工合并 + 不丢失数据
- 同 [极寒防御/01_MVP §七](../极寒防御/01_MVP_本阶段实践与验证.md#七本步骤失败时)

## 八、上一步 / 下一步
- **上一步**：[02_V1_full](./02_V1_full_本阶段实践与验证.md)
- **下一步**：本模块完结
