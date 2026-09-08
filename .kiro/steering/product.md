# Product Overview

This is a GitOps Infrastructure-as-Code (IaC) project that provides a scalable, enterprise-grade AWS infrastructure foundation using Terraform and Terragrunt. The project implements a layered architecture approach based on Domain-Driven Design (DDD) principles.

## Key Features

- **Multi-layered Architecture**: Foundation, Platform, Application, and Observability layers
- **GitOps Integration**: Designed for automated deployment pipelines with ArgoCD
- **Environment Management**: Support for dev, qa, stg, and prod environments using Terraform workspaces
- **Modular Design**: Independent, reusable infrastructure stacks
- **Enterprise Security**: Built-in compliance, tagging, and security best practices

## Target Use Cases

This scaffold can be adapted for any infrastructure deployment scenario:

- **Enterprise Infrastructure**: Large-scale cloud deployments across multiple environments
- **Application Platforms**: Multi-tier application hosting with compute, storage, and networking
- **Container Orchestration**: Kubernetes clusters, ECS services, and container registry management
- **Data Platforms**: Database clusters, caching layers, and data processing infrastructure
- **Networking Infrastructure**: VPCs, security groups, load balancers, and connectivity solutions
- **Storage Solutions**: Object storage, file systems, and backup infrastructure
- **Monitoring & Observability**: Logging, metrics, alerting, and dashboard systems
- **Security Infrastructure**: IAM roles, policies, encryption, and compliance frameworks
- **Development Environments**: Sandbox, testing, and CI/CD infrastructure
- **Hybrid Cloud**: Multi-cloud and on-premises integration scenarios

The project serves as a flexible scaffold that organizations can customize for their specific infrastructure needs while maintaining DevSecOps best practices and automation standards.

## Tooling & Workflow Authority

**ThothCTL is the authoritative framework and workflow for this scaffold.** All IaC lifecycle
activities — validation, security scanning, policy/compliance, cost, blast-radius, plan
validation, drift, inventory/SBOM, documentation, and intent-based generation — are performed
through ThothCTL tools, which wrap and govern the underlying tools (Checkov, Trivy, KICS,
OPA/Conftest, terraform-compliance, terraform-docs, cost, drift) with org policy, unified
reporting, and enforcement gates.

Do **not** call the wrapped tools directly (e.g. bare `checkov`, `tflint`, `terraform-docs`,
`infracost`) when a ThothCTL command exists. Raw `terraform`/`terragrunt` remain in use only for
state mechanics (`init`, `plan` artifact generation, `apply`, `fmt`).

Canonical flow: `generate → develop → build → plan → test → secure → deploy → monitor`
(run via `thothctl workflow devsecops --phase <phase>`).

See the `thothctl-framework` skill for the authoritative tool boundary and the `devsecops` skill
for phase execution detail.