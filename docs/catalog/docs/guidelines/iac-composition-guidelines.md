# Infrastructure as Code Composition Guidelines

## Terraform + Terragrunt Project Structure

This project uses a hybrid approach combining Terraform modules with Terragrunt orchestration.

### Stack File Structure

Each stack contains:
- `main.tf` - Terraform module configurations using `tfr://` format
- `variables.tf` - Input variable definitions
- `outputs.tf` - Output value definitions  
- `terragrunt.hcl` - Terragrunt orchestration with dependencies

### Module Usage Pattern

```hcl
# main.tf example
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
  
  name = var.vpc_name
  cidr = var.vpc_cidr
  
  tags = local.common_tags
}
```

### Terragrunt Configuration Pattern

```hcl
# terragrunt.hcl example
include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../../../foundation/network/vpc"
  mock_outputs = {
    vpc_id = "vpc-mock"
  }
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  
  common_tags = {
    Environment = local.env
    Project     = "terraform-terragrunt-scaffold"
    ManagedBy   = "terragrunt"
  }
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
  tags   = local.common_tags
}
```

### Validation Checklist

- [ ] Module source uses appropriate format (registry: `namespace/name/provider`, git: `git::https://`, local: `./path`)
- [ ] Version is pinned to specific release
- [ ] All required inputs are provided
- [ ] Naming follows project conventions
- [ ] Tags include all mandatory fields
- [ ] Dependencies are explicitly declared with `dependency` blocks
- [ ] Mock outputs are provided for all dependencies
- [ ] Environment-specific configuration uses locals pattern
- [ ] Security best practices are followed

### Mandatory Tags

All resources must include:
- `Environment` - dev/staging/prod
- `Project` - project identifier
- `ManagedBy` - "terragrunt"

### Security Requirements

- Use least privilege IAM policies
- Enable encryption at rest and in transit
- Implement proper network segmentation
- Follow AWS security best practices
