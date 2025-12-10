# Infrastructure as Code Composition Rules

These are **mandatory rules** that must be followed for all Terraform/Terragrunt operations in this project.

## Stack File Structure (R001)

Each stack **MUST** contain these required files:
- `main.tf` - Terraform module configurations
- `variables.tf` - Input variable definitions  
- `outputs.tf` - Output value definitions
- `terragrunt.hcl` - Terragrunt orchestration with dependencies

## Module Source Standards (R002-R003)

### Approved Module Sources (in order of preference):
1. **terraform-aws-modules** (official AWS modules) - `terraform-aws-modules/vpc/aws`
2. **Git repositories** - `git::https://github.com/...`
3. **Local modules** - `./modules/module-name` (last resort only)

### Version Pinning Required:
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"  # Exact version required
}
```

## Terragrunt Configuration Pattern (R004)

**Required terragrunt.hcl structure:**
```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../../../foundation/network/vpc"
  mock_outputs = {
    vpc_id = "vpc-mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
  tags   = local.common_tags
}
```

## Dependency Management (R005)

All dependencies **MUST** include:
- `config_path` with relative path
- `mock_outputs` with realistic values
- `mock_outputs_merge_strategy_with_state = "shallow"`

## Mandatory Tagging (R006)

**Required tags for ALL resources:**
```hcl
common_tags = {
  Environment = local.env
  Project     = "terraform-terragrunt-scaffold"
  ManagedBy   = "terragrunt"
}
```

## Security Requirements (R008-R010)

### IAM Security:
- Use least privilege principle
- Attach only necessary AWS managed policies
- Avoid inline policies unless required
- Enable MFA for sensitive roles

### Network Security:
- Use security groups over NACLs
- Implement defense in depth
- Enable VPC Flow Logs
- Use private subnets for workloads

### Data Protection:
- Enable encryption at rest and in transit
- Use AWS KMS for key management
- Implement backup strategies
- Enable versioning for S3 buckets

## Local Module Standards (R013)

When terraform-aws-modules cannot fulfill requirements:

**Required local module structure:**
```
modules/
├── {module-name}/
│   ├── main.tf          # Resource definitions
│   ├── variables.tf     # Input variable definitions  
│   ├── outputs.tf       # Output value definitions
│   ├── versions.tf      # Provider version constraints
│   └── README.md        # Module documentation
```

**Local module requirements:**
- Complete file structure
- Provider version constraints
- All variables documented with descriptions and types
- Tags variable with default empty map
- Comprehensive README.md with examples

## Prohibited Practices

### ❌ Never Do:
- Use unverified community modules
- Hardcode values instead of variables
- Skip version constraints
- Create inline IAM policies
- Put workloads in public subnets
- Use unencrypted storage
- Skip mandatory tags

### ✅ Always Do:
- Use terraform-aws-modules first
- Pin exact versions
- Include complete stack structure
- Follow terragrunt patterns
- Apply comprehensive tagging
- Declare dependencies with mocks
- Implement security-first configurations

## Enforcement Actions

- **BLOCK**: Incomplete structure, security violations, missing versions
- **REQUIRE**: Proper terragrunt config, dependency mocks, mandatory tags
- **WARN**: Outdated versions, missing documentation

## Module Selection Priority

1. **First**: terraform-aws-modules (official AWS modules)
2. **Second**: Well-maintained community modules  
3. **Last**: Local modules (justify why terraform-aws-modules insufficient)

These rules ensure consistent, secure, and maintainable infrastructure code.