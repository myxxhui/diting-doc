# ADR-001: 采用 ${PROJECT_KEY} 动态命名

## 状态
Accepted

## Context (背景)

项目需要在多个环境（dev/staging/prod）和多个实例中运行，需要统一的命名规范来避免资源冲突和管理混乱。

**问题**：
- 多环境部署时，资源命名冲突
- 无法快速识别资源所属环境和用途
- 成本追踪困难

## Decision (决策)

采用 `${PROJECT_KEY}` 动态命名策略：

- **项目代号**：`diting`
- **命名格式**：`${PROJECT_KEY}-${component}-${environment}`
- **示例**：
  - `diting-scanner-prod`
  - `diting-moe-staging`
  - `diting-infra-dev`

## Consequences (后果)

**[+] 正面影响**：
- 统一命名规范，避免资源冲突
- 支持多环境部署（dev/staging/prod）
- 便于资源管理和成本追踪
- 支持资源标签管理

**[-] 负面影响**：
- 需要维护命名规范文档
- 命名长度可能较长

**[!] 风险与注意事项**：
- 命名规范变更需要同步更新所有资源
- 需要 CI/CD 自动化命名检查

## Alternatives Considered (考虑的替代方案)

1. **固定命名**：
   - 优点：简单
   - 缺点：无法支持多环境，容易冲突
   - 结论：❌ 不采用

2. **UUID 命名**：
   - 优点：唯一性保证
   - 缺点：不可读，难以管理
   - 结论：❌ 不采用

3. **动态命名（${PROJECT_KEY}）**：
   - 优点：可读 + 唯一 + 支持多环境
   - 缺点：需要维护规范
   - 结论：✅ **采用**

## Compliance Check (合规检查)

- ✅ 符合云资源命名规范
- ✅ 支持资源标签管理
- ✅ 符合成本治理要求（便于成本追踪）

## Traceability (追溯性)

- **L1 价值点**: [核心价值：可追溯性](../01_顶层概念/01_一句话定义与核心价值.md)
- **L2 维度**: [技术栈与架构维度](../02_战略维度/产品设计/02_技术栈与架构维度.md)
- **L3 规约**: [三位一体仓库规约](../03_原子目标与规约/_共享规约/02_三位一体仓库规约.md)
- **相关 ADR**：无

## Implementation Notes (实施说明)

### Terraform 变量定义

```hcl
variable "project_key" {
  description = "项目代号"
  type        = string
  default     = "diting"
}

variable "environment" {
  description = "环境名称（dev/staging/prod）"
  type        = string
}

# 资源命名示例
resource "alicloud_ecs_instance" "scanner" {
  name = "${var.project_key}-scanner-${var.environment}"
  
  tags = {
    project     = var.project_key
    environment = var.environment
    component   = "scanner"
  }
}
```

### K8s 命名空间

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: diting-${ENVIRONMENT}
  labels:
    project: diting
    environment: ${ENVIRONMENT}
```

### 资源标签规范

```yaml
tags:
  project: diting
  environment: prod
  component: scanner
  managed_by: terraform
  cost_center: trading
```

## Review History (审查历史)

- 2026-02-11: 初始创建
- 2026-02-11: 状态变更（Accepted）
