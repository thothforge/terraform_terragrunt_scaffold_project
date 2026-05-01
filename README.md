# Terraform Terragrunt Scaffold

Enterprise-grade AWS infrastructure scaffold using Terraform and Terragrunt with a layered architecture based on Domain-Driven Design (DDD) principles.

## Architecture

The project implements four infrastructure layers with strict dependency ordering:

```
Foundation → Platform → Application → Observability
```

### Stacks

```
stacks/
├── foundation/
│   ├── network/
│   │   ├── vpc/                  # VPC, subnets, NAT gateways
│   │   └── security-groups/      # Security group definitions
│   └── iam/
│       ├── roles/                # IAM roles
│       └── policies/             # IAM policies
├── platform/
│   ├── containers/
│   │   ├── eks/                  # EKS cluster and node groups
│   │   └── ecr/                  # Container registry
│   └── data/
│       ├── rds/                  # RDS PostgreSQL/MySQL
│       └── elasticache/          # ElastiCache Redis/Memcached
├── application/
│   ├── compute/
│   │   ├── alb/                  # Application Load Balancer
│   │   └── asg/                  # Auto Scaling Groups
│   └── storage/
│       ├── s3/                   # S3 buckets
│       └── efs/                  # Elastic File System
└── observability/
    └── monitoring/
        ├── cloudwatch/           # CloudWatch dashboards and alarms
        └── prometheus/           # Prometheus monitoring
```

## Prerequisites

- Terraform >= 1.0
- Terragrunt >= 0.50
- AWS CLI configured with appropriate profiles
- TFLint (optional, for linting)

## Quick Start

```bash
# 1. Clone and configure
git clone <repository-url>
cd terraform_terragrunt_scaffold_project

# 2. Set environment
export TF_VAR_ENVIRONMENT=dev  # dev | qa | prd

# 3. Initialize and plan a stack
cd stacks/foundation/network/vpc
terragrunt init
terragrunt plan

# 4. Apply
terragrunt apply
```

## Multi-Stack Operations

```bash
# Plan all stacks (respects dependency order)
terragrunt run --all plan

# Apply a specific layer
terragrunt run --all --working-dir stacks/foundation -- apply

# Destroy (reverse dependency order)
terragrunt run --all destroy
```

## Project Structure

```
.
├── root.hcl                    # Root Terragrunt config (remote state, providers)
├── common/
│   ├── common.hcl              # Shared locals and provider generation
│   ├── common.tfvars           # Common variable values
│   └── variables.tf            # Shared variable definitions
├── environments/
│   ├── dev/                    # Dev environment overrides
│   ├── qa/                     # QA environment overrides
│   └── prd/                    # Production environment overrides
├── stacks/                     # Infrastructure stacks (see Architecture)
├── docs/                       # Documentation and catalog
└── .kiro/
    ├── steering/               # AI agent steering rules
    ├── skills/                 # AI agent skills
    │   └── iac-versioning-commits/  # Commit and versioning standards
    ├── agents/                 # Agent configurations
    └── settings/               # MCP settings
```

## Environments

Configuration follows a hierarchical precedence (highest to lowest):

1. `environments/{env}/*.tfvars` — Environment-specific overrides
2. `common/common.tfvars` — Shared values
3. Stack-level `variables.tf` defaults

Each environment directory contains layer-specific tfvars:

```
environments/dev/
├── foundations.tfvars
├── platform.tfvars
├── applications.tfvars
└── observability.tfvars
```

## Stack Convention

Every stack contains:

| File | Purpose |
|------|---------|
| `terragrunt.hcl` | Dependencies, includes, inputs |
| `main.tf` | Resource/module definitions |
| `variables.tf` | Input variables |
| `outputs.tf` | Output values |

## Versioning

This project uses **IaC Tagging Code** (MAJOR.MINOR.PATCH):

- **MAJOR** — Environment additions/removals, framework changes
- **MINOR** — New stacks, modules, or resources (backward compatible)
- **PATCH** — Bug fixes, config tuning, documentation

Commits follow [Conventional Commits](https://www.conventionalcommits.org/) extended with contextual action lines. See `.kiro/skills/iac-versioning-commits/` for the full specification.

## Validation

```bash
# Lint
tflint --recursive

# Pre-commit hooks
pre-commit run --all-files

# Validate syntax
terragrunt validate
```

## License

See [LICENSE](LICENSE) for details.
