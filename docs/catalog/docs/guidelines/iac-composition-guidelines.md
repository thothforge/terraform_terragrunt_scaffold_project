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
    mock_outputs_merge_strategy_with_state = "shallow"

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
- [ ] Use latest version available for new stacks components

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



### 3. Security Requirements

#### IAM Roles
- Use least privilege principle
- Attach only necessary AWS managed policies
- Avoid inline policies unless required
- Enable MFA for sensitive roles

#### Network Security
- Use security groups over NACLs
- Implement defense in depth
- Enable VPC Flow Logs
- Use private subnets for workloads

#### Data Protection
- Enable encryption at rest and in transit
- Use AWS KMS for key management
- Implement backup strategies
- Enable versioning for S3 buckets

## Agent Guidelines

### Stack Creation Rules
When creating new stacks, the agent must:

1. **Validate Module Source**: Ensure using approved modules from the list above
2. **Check Version Compatibility**: Use latest stable version unless specified
3. **Apply Naming Convention**: Follow project-environment-resource pattern
4. **Include Required Tags**: All mandatory tags must be present
5. **Configure Dependencies**: Explicitly declare all dependencies
6. **Add Documentation**: Include README.md with module purpose and usage

### Module Research Process
1. **Search Official Modules**: Always start with `terraform-aws-modules`
2. **Verify Module Compatibility**: Check Terraform and provider version requirements
3. **Review Module Documentation**: Understand inputs, outputs, and examples
4. **Select Appropriate Submodule**: Use specific submodules when available
5. **Use latest Version for new stack components**: Use the latest or more recent version published for each module

### Dependency Management Rules
1. **Use `dependency` blocks**: Never use `dependencies` for cross-stack references
2. **Include Mock Outputs**: Always provide mock outputs for safe planning
3. **Set Mock Strategy**: Use `mock_outputs_merge_strategy_with_state = "shallow"`
4. **Relative Paths**: Use relative paths from current stack location
5. **Output References**: Reference dependency outputs as `dependency.{name}.outputs.{output}`


## Prohibited Practices

### ❌ Avoid These Patterns
- Using unverified community modules
- Hardcoded values instead of variables
- Missing version constraints
- Inline policies for IAM roles
- Public subnets for workloads
- Unencrypted storage resources
- Missing or incomplete tags

### ✅ Required Practices
- Official AWS modules only
- Version pinning for all modules
- Consistent naming conventions
- Comprehensive tagging strategy
- Explicit dependency declarations
- Security-first configurations
- Complete documentation

## Compliance & Governance

### Module Approval Process
1. **Research**: Identify official module for use case
2. **Validation**: Verify module meets security requirements
3. **Testing**: Test in development environment
4. **Documentation**: Update this guideline if new module approved
5. **Implementation**: Deploy following established patterns

### Regular Reviews
- **Monthly**: Review for new module versions
- **Quarterly**: Security and compliance audit
- **Annually**: Architecture and pattern review

This guideline ensures consistent, secure, and maintainable infrastructure code across all environments and teams.
