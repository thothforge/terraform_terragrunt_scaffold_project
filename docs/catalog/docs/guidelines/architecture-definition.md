# Infrastructure Architecture Definition

## Overview
This document defines the infrastructure architecture using stack groups based on Domain-Driven Design (DDD) principles and AWS service categories. Each stack represents an independent, complete unit of infrastructure resources.

## Stack Group Categories

### 1. Foundation Layer
**Purpose**: Core infrastructure components that other stacks depend on
**Dependencies**: None (base layer)

#### Network Stack Group
- **VPC Stack** (`stacks/foundation/network/vpc/`)
  - VPC, Subnets, Route Tables, Internet Gateway
  - CIDR planning and IP allocation
  - Multi-AZ configuration
- **Security Groups Stack** (`stacks/foundation/network/security-groups/`)
  - Application-specific security groups
  - Network ACLs
  - Security group rules and references

#### Identity & Access Stack Group
- **IAM Roles Stack** (`stacks/foundation/iam/roles/`)
  - Service roles, execution roles
  - Cross-account access roles
  - OIDC providers for GitOps
- **IAM Policies Stack** (`stacks/foundation/iam/policies/`)
  - Custom policies
  - Permission boundaries
  - Policy attachments

### 2. Platform Layer
**Purpose**: Shared services and platform components
**Dependencies**: Foundation Layer

#### Container Platform Stack Group
- **EKS Control Plane Stack** (`stacks/platform/containers/eks-control-plane/`)
  - EKS cluster configuration
  - Cluster addons (VPC CNI, CoreDNS, kube-proxy)
  - OIDC provider setup
- **EKS Node Groups Stack** (`stacks/platform/containers/eks-nodegroups/`)
  - Managed node groups
  - Fargate profiles
  - Auto-scaling configuration
- **Container Registry Stack** (`stacks/platform/containers/ecr/`)
  - ECR repositories
  - Image scanning policies
  - Lifecycle policies

#### Data Platform Stack Group
- **Database Stack** (`stacks/platform/data/rds/`)
  - RDS instances/clusters
  - Parameter groups
  - Subnet groups
- **Cache Stack** (`stacks/platform/data/elasticache/`)
  - Redis/Memcached clusters
  - Subnet groups
  - Parameter groups

### 3. Application Layer
**Purpose**: Application-specific infrastructure
**Dependencies**: Platform Layer

#### Compute Stack Group
- **Application Load Balancer Stack** (`stacks/application/compute/alb/`)
  - Application Load Balancers
  - Target groups
  - Listener rules
- **Auto Scaling Stack** (`stacks/application/compute/asg/`)
  - Auto Scaling Groups
  - Launch templates
  - Scaling policies

#### Storage Stack Group
- **S3 Buckets Stack** (`stacks/application/storage/s3/`)
  - Application data buckets
  - Static website buckets
  - Backup buckets
- **EFS Stack** (`stacks/application/storage/efs/`)
  - Elastic File Systems
  - Mount targets
  - Access points

### 4. Observability Layer
**Purpose**: Monitoring, logging, and observability
**Dependencies**: Application Layer

#### Monitoring Stack Group
- **CloudWatch Stack** (`stacks/observability/monitoring/cloudwatch/`)
  - Custom metrics
  - Alarms and notifications
  - Dashboards
- **Prometheus Stack** (`stacks/observability/monitoring/prometheus/`)
  - Prometheus server
  - Grafana dashboards
  - Alert manager

#### Logging Stack Group
- **Log Aggregation Stack** (`stacks/observability/logging/centralized/`)
  - CloudWatch Log Groups
  - Log retention policies
  - Log streaming

## Stack Naming Convention

```
stacks/{layer}/{domain}/{service}/{component}/
```

**Examples:**
- `stacks/foundation/network/vpc/`
- `stacks/platform/containers/eks-control-plane/`
- `stacks/application/compute/alb/`
- `stacks/observability/monitoring/cloudwatch/`

## Stack Dependencies Rules

### Dependency Hierarchy
1. **Foundation** → Platform → Application → Observability
2. **Within Layer**: Stacks can depend on other stacks in the same layer
3. **Cross-Layer**: Only depend on lower layers, never higher layers

### Dependency Declaration
Each stack must declare its dependencies in `terragrunt.hcl`:

```hcl
dependencies {
  paths = [
    "../../../foundation/network/vpc",
    "../../../foundation/iam/roles"
  ]
}
```

## Stack Structure Template

Each stack directory must contain:

```
stack-name/
├── terragrunt.hcl          # Terragrunt configuration
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── versions.tf             # Provider versions
└── README.md               # Stack documentation
```

## Environment Configuration

### Workspace Strategy
- Use Terraform workspaces for environment separation
- Workspace names: `dev`, `qa`, `stg`, `prod`
- Environment-specific variables in `common/common.hcl`

### Variable Precedence
1. Workspace-specific variables
2. Common variables (`common/common.hcl`)
3. Stack-specific variables
4. Default values

## GitOps Integration Rules

### Repository Structure
- **Infrastructure Repository**: Contains all Terragrunt stacks
- **Application Repositories**: Separate repos for application code
- **GitOps Repository**: ArgoCD applications and configurations

### Deployment Flow
1. **Infrastructure Changes**: Terragrunt → AWS
2. **Application Changes**: Git → ArgoCD → Kubernetes
3. **Configuration Changes**: Git → ArgoCD → ConfigMaps/Secrets

## Security Guidelines

### Access Control
- **Least Privilege**: Each stack has minimal required permissions
- **Role Separation**: Different roles for different layers
- **Cross-Account**: Use cross-account roles for production

### Secrets Management
- **AWS Secrets Manager**: For application secrets
- **Parameter Store**: For configuration values
- **External Secrets**: For Kubernetes secret injection

## Compliance Requirements

### Tagging Strategy
All resources must include:
```hcl
tags = {
  Project     = var.project_name
  Environment = var.environment
  Layer       = "foundation|platform|application|observability"
  Domain      = "network|compute|storage|security"
  ManagedBy   = "terragrunt"
  GitRepo     = var.git_repository
}
```

### Backup Requirements
- **RDS**: Automated backups enabled
- **S3**: Cross-region replication for critical data
- **EBS**: Snapshot lifecycle policies

## Agent Context Rules

### Stack Creation Guidelines
When creating new stacks, the agent should:

1. **Validate Layer**: Ensure stack is in correct layer
2. **Check Dependencies**: Verify all dependencies exist
3. **Follow Naming**: Use established naming conventions
4. **Include Required Files**: All template files present
5. **Add Documentation**: README.md with stack purpose
6. **Configure Tags**: Apply standard tagging strategy

### Modification Guidelines
When modifying existing stacks:

1. **Impact Analysis**: Check dependent stacks
2. **Backward Compatibility**: Ensure no breaking changes
3. **Version Constraints**: Update provider versions if needed
4. **Documentation Updates**: Keep README.md current

### Validation Rules
- All stacks must have valid `terragrunt.hcl`
- Dependencies must be explicitly declared
- No circular dependencies allowed
- All required tags must be present
- Security groups must follow least privilege principle

## Examples

### Foundation Layer Example
```hcl
# stacks/foundation/network/vpc/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  vpc_cidr = "10.0.0.0/16"
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}
```

### Platform Layer Example
```hcl
# stacks/platform/containers/eks-control-plane/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependencies {
  paths = [
    "../../../foundation/network/vpc",
    "../../../foundation/iam/roles"
  ]
}

inputs = {
  cluster_name = "gitops-${local.environment}"
  kubernetes_version = "1.28"
  endpoint_private_access = true
  endpoint_public_access = true
}
```

This architecture definition provides the agent with clear context about:
- How to organize infrastructure stacks
- Dependency relationships and rules
- Naming conventions and standards
- Security and compliance requirements
- Validation rules for stack creation and modification