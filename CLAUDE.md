# GitOps IaC at Scale — Terraform + Terragrunt Scaffold

## Product Overview

Enterprise-grade AWS infrastructure scaffold using Terraform and Terragrunt. Implements a layered architecture based on Domain-Driven Design (DDD) principles with GitOps deployment via ArgoCD.

**Key capabilities:** Multi-environment management (dev/qa/stg/prod), modular infrastructure stacks, built-in compliance and security, automated deployment pipelines.

## Architecture

Four layers, deployed in dependency order:

1. **Foundation** — Core infrastructure: VPC, IAM, Security Groups
2. **Platform** — Shared services: EKS, RDS, ElastiCache, ECR
3. **Application** — Workload resources: ALB, ASG, S3, EFS
4. **Observability** — Monitoring: CloudWatch, Prometheus

Dependencies flow downward only. Stacks may depend on peers in the same layer but never on higher layers.

## Project Structure

```
stacks/{layer}/{domain}/{service}/   # Each stack has: terragrunt.hcl, main.tf, variables.tf, outputs.tf
common/                              # Shared config: common.hcl, common.tfvars, variables.tf
environments/{env}/                  # Per-env tfvars: foundations, platform, applications, observability
root.hcl                             # Root Terragrunt config (remote state, provider generation)
```

## Technology Stack

| Tool | Purpose |
|------|---------|
| Terraform | Infrastructure provisioning |
| Terragrunt | DRY config, remote state, dependency orchestration |
| AWS | Primary cloud provider |
| TFLint | Linting and validation |
| Pre-commit | Git hooks for code quality |
| ThothCTL | Security scanning, inventory, AI review |

## Common Commands

```bash
# Stack operations
terragrunt init && terragrunt plan && terragrunt apply

# Multi-stack
terragrunt run --all plan
terragrunt run --all apply

# Validation
tflint --recursive
pre-commit run --all-files
terragrunt validate

# Security scanning
thothctl scan iac -t checkov -t trivy
thothctl inventory iac --check-versions
```

## Configuration Hierarchy

Variable precedence (highest → lowest):
1. `environments/{env}/*.tfvars`
2. `common/common.tfvars`
3. Stack-specific variables
4. Defaults in `variables.tf`

Remote state: S3 backend with DynamoDB locking, configured in `root.hcl`.

## Key Conventions

- **Module sources**: Prefer `terraform-aws-modules` → `aws-ia` → git repos → local (last resort)
- **Version pinning**: Exact versions required for all modules and providers
- **Mandatory tags**: `Environment`, `Project`, `ManagedBy` on all resources
- **Dependencies**: Always include `mock_outputs` with `mock_outputs_merge_strategy_with_state = "shallow"`
- **Security**: Least privilege IAM, encryption at rest/transit, private subnets for workloads

## Rules

Detailed IaC composition rules (R001–R013) are in `.claude/rules/iac-rules.md`. These cover stack structure, module standards, terragrunt patterns, dependency management, tagging, security, and prohibited practices.

## MCP Servers

This project includes MCP server configuration (`.mcp.json`) for:
- **thothctl** — Security scanning, inventory, AI review
- **aws-knowledge** — AWS documentation and best practices
- **git** — Git operations
- **terraform** — Terraform registry and provider docs
- **aws-diagrams** — AWS architecture diagram generation
