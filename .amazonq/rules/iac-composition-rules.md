# Infrastructure as Code Composition Rules

## Rule Enforcement
These are mandatory rules enforced by Amazon Q for all Terraform/Terragrunt hybrid operations in this project.

## R001: Stack File Structure
**RULE**: Each stack must contain required files
**ENFORCEMENT**: Block incomplete stack structures

### Required Files:
- `main.tf` - Terraform module configurations
- `variables.tf` - Input variable definitions
- `outputs.tf` - Output value definitions
- `terragrunt.hcl` - Terragrunt orchestration with dependencies

**VIOLATION**: Missing any required file
**ACTION**: Require complete stack structure

## R002: Module Source Format
**RULE**: Use appropriate module source format
**ENFORCEMENT**: Validate source format against approved patterns

### Approved Formats:
- **Registry**: `namespace/name/provider` (e.g., `terraform-aws-modules/vpc/aws`)
- **Git**: `git::https://github.com/...`
- **Local**: `./path/to/module`

### Required Pattern:
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
}
```

**VIOLATION**: Using incorrect source format
**ACTION**: Reject and provide correct format

## R003: Version Pinning
**RULE**: All modules must specify exact versions
**ENFORCEMENT**: Block modules without version constraints

### Required Pattern:
```hcl
version = "5.0.0"
```

**VIOLATION**: Missing version specification
**ACTION**: Require exact version specification

## R004: Terragrunt Configuration Pattern
**RULE**: Follow standard terragrunt.hcl structure
**ENFORCEMENT**: Validate terragrunt configuration completeness

### Required Structure:
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


inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
  tags   = local.common_tags
}
```

**VIOLATION**: Missing include, dependency, locals, or inputs blocks
**ACTION**: Require complete terragrunt configuration

## R005: Dependency Management
**RULE**: Use `dependency` blocks with proper configuration
**ENFORCEMENT**: Block dependencies without required elements

### Required Elements:
- `config_path` with relative path
- `mock_outputs` with realistic values
- `mock_outputs_merge_strategy_with_state = "shallow"`

**VIOLATION**: Missing mock outputs or merge strategy
**ACTION**: Require complete dependency configuration

## R006: Mandatory Tags
**RULE**: All resources must include required tags
**ENFORCEMENT**: Block resources missing mandatory tags

### Required Tags:
```hcl
common_tags = {
  Environment = local.env
  Project     = "terraform-terragrunt-scaffold"
  ManagedBy   = "terragrunt"
}
```

**VIOLATION**: Missing Environment, Project, or ManagedBy tags
**ACTION**: Reject and specify missing tags

## R007: Environment Configuration
**RULE**: Use locals pattern for environment-specific config
**ENFORCEMENT**: Validate environment configuration structure

### Required Pattern:
```hcl
locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}
```

**VIOLATION**: Hardcoded environment values
**ACTION**: Require locals-based configuration with env.hcl

## R008: Security Requirements - IAM
**RULE**: Enforce IAM security best practices
**ENFORCEMENT**: Block insecure IAM configurations

### Mandatory Settings:
- Use least privilege principle
- Attach only necessary AWS managed policies
- Avoid inline policies unless required
- Enable MFA for sensitive roles

**VIOLATION**: Insecure IAM configurations
**ACTION**: Reject and require security compliance

## R009: Security Requirements - Network
**RULE**: Enforce network security best practices
**ENFORCEMENT**: Block insecure network configurations

### Mandatory Settings:
- Use security groups over NACLs
- Implement defense in depth
- Enable VPC Flow Logs
- Use private subnets for workloads

**VIOLATION**: Insecure network configurations
**ACTION**: Reject and require security compliance

## R010: Security Requirements - Data Protection
**RULE**: Enforce data protection best practices
**ENFORCEMENT**: Block unencrypted resources

### Mandatory Settings:
- Enable encryption at rest and in transit
- Use AWS KMS for key management
- Implement backup strategies
- Enable versioning for S3 buckets

**VIOLATION**: Unencrypted storage resources
**ACTION**: Reject and require encryption

## R011: Latest Version Usage
**RULE**: Use latest stable version for new stack components
**ENFORCEMENT**: Recommend latest versions for new stacks

### Implementation:
- Check terraform-aws-modules for latest version
- Suggest upgrade when creating new stacks
- Maintain compatibility with project requirements

**VIOLATION**: Using outdated versions for new stacks
**ACTION**: Recommend latest stable version

## R012: Output References
**RULE**: Reference dependency outputs correctly
**ENFORCEMENT**: Validate dependency output usage

### Required Pattern:
```hcl
inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
  tags   = local.common_tags
}
```

**VIOLATION**: Incorrect dependency output references
**ACTION**: Require proper `dependency.{name}.outputs.{output}` format

## Enforcement Actions

### BLOCK: Immediate rejection
- R001: Incomplete stack structure
- R002: Incorrect module source format
- R003: Missing version constraints
- R008-R010: Security violations

### WARN: Require confirmation
- R006: Missing mandatory tags
- R007: Environment configuration issues
- R011: Outdated versions for new stacks

### REQUIRE: Must fix before proceeding
- R004: Invalid terragrunt configuration
- R005: Missing mock outputs
- R012: Incorrect dependency references
- R013: Local Module Structure and Usage when the module is not public available in approval official registries sources

## Agent Behavior Rules

### When Creating New Stacks:
1. Generate complete file structure (main.tf, variables.tf, outputs.tf, terragrunt.hcl)
2. Use terraform-aws-modules as primary source
3. Use latest stable version unless specified
4. Include all mandatory tags in locals
5. Configure proper dependency blocks with mocks
6. Follow terragrunt configuration pattern with env.hcl

### When Modifying Existing Stacks:
1. Preserve existing file structure
2. Validate all changes against security rules
3. Update dependency references if needed
4. Maintain terragrunt configuration consistency

### When Researching Modules:
1. Search terraform-aws-modules first
2. Verify module compatibility with Terraform version
3. Use latest stable version for new components
4. Select appropriate submodules when available

### When creating a local module 

1. Purpose: Use for organization-specific patterns not available in terraform-official certificate modules
2. Naming: Use kebab-case for module directories
3. Documentation: Include comprehensive README.md with examples
4. Testing: Include example usage in examples/ subdirectory
5. Versioning: Use Git tags for version management

## Validation Checklist

- [ ] Module source uses appropriate format (registry/git/local)
- [ ] Version is pinned to specific release
- [ ] All required inputs are provided
- [ ] Naming follows project conventions
- [ ] Tags include all mandatory fields (Environment, Project, ManagedBy)
- [ ] Dependencies use `dependency` blocks with mock outputs
- [ ] Mock outputs include `mock_outputs_merge_strategy_with_state = "shallow"`
- [ ] Environment-specific configuration uses locals with env.hcl
- [ ] Security best practices are followed
- [ ] Latest version available for new stack components


**VIOLATION CONDITIONS**:
- Missing required files (main.tf, variables.tf, outputs.tf, versions.tf, README.md)
- Incorrect module source path format
- Missing provider version constraints
- Undocumented variables or outputs
- Missing tags variable with default empty map

**ENFORCEMENT ACTIONS**:
- **BLOCK**: Incomplete module structure
- **REQUIRE**: Proper documentation before usage
- **WARN**: Using local modules when terraform-aws-modules alternative exists

### Module Creation Checklist:
- [ ] Complete file structure (main.tf, variables.tf, outputs.tf, versions.tf, README.md)
- [ ] Provider version constraints defined
- [ ] All variables documented with descriptions and types
- [ ] Tags variable included with default empty map
- [ ] All outputs documented with descriptions
- [ ] README.md includes usage examples and requirements table
- [ ] Module follows organization naming conventions
- [ ] Example usage provided in documentation

### Preferred Module Hierarchy:
1. **First Choice**: terraform-aws-modules (official AWS modules)
2. **Second Choice**: Well-maintained community modules
3. **Last Resort**: Local modules for organization-specific patterns

**NOTE**: Always justify why terraform-aws-modules cannot fulfill the requirement before creating local modules.

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
- Official AWS modules (terraform-aws-modules) only
- Version pinning for all modules
- Complete stack file structure
- Standard terragrunt configuration pattern
- Comprehensive tagging strategy
- Explicit dependency declarations with mocks
- Security-first configurations
- Latest versions for new components

## Module Approval Process
1. **Research**: Identify terraform-aws-modules for use case
2. **Validation**: Verify module meets security requirements
3. **Testing**: Test in development environment
4. **Documentation**: Update guidelines if new module approved
5. **Implementation**: Deploy following established patterns

These rules ensure consistent, secure, and maintainable infrastructure code in the Terraform/Terragrunt hybrid approach while enabling Amazon Q to provide automated enforcement and guidance.

## Stacks terrafrom + terragrunt structure example

```bash
stacks/application/
├── compute
│   ├── alb
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── terragrunt.hcl
│   │   └── variables.tf
│   └── asg
│       ├── main.tf
│       ├── outputs.tf
│       ├── terragrunt.hcl
│       └── variables.tf
└── storage
    ├── efs
    │   ├── main.tf
    │   ├── outputs.tf
    │   ├── terragrunt.hcl
    │   └── variables.tf
    └── s3
        ├── main.tf
        ├── outputs.tf
        ├── terragrunt.hcl
        └── variables.tf

7 directories, 16 files

```


RULE: Local modules must follow standardized structure and usage patterns
ENFORCEMENT: Block non-compliant local module implementations

Required Local Module Structure:
```bash 
modules/
├── {module-name}/
│   ├── main.tf          # Resource definitions
│   ├── variables.tf     # Input variable definitions  
│   ├── outputs.tf       # Output value definitions
│   ├── versions.tf      # Provider version constraints
│   └── README.md        # Module documentation

```


