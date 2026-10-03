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
2. **terraform-aws-ia-modules** (official AWS IA modules) - aws-ia/
3. **Git repositories** - `git::https://github.com/...`
4. **Local modules** - `./modules/module-name` (last resort only)

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
  # Anchor dependency paths to the Terragrunt root with get_parent_terragrunt_dir()
  # — NOT hand-counted relative "../" paths (see R005).
  config_path = "${get_parent_terragrunt_dir()}/stacks/foundation/network/vpc"
  mock_outputs = {
    vpc_id = "vpc-mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
  tags   = var.required_tags
}
```

### Dependency path anchoring (R004.2)

Dependency `config_path` values **MUST** be anchored to the Terragrunt root with
`get_parent_terragrunt_dir()` and **MUST NOT** use hand-counted relative paths
(`../../../...`). Relative paths are depth-fragile: a stack moving one level, or a
cross-tree reference (e.g. `application` → `platform`), silently breaks the path
and produces confusing "folder does not contain a terragrunt.hcl" errors.

```hcl
# ✅ Correct — depth-independent, consistent with root.hcl's own source/var-file paths
config_path = "${get_parent_terragrunt_dir()}/stacks/platform/containers/ecs"

# ❌ Wrong — hand-counted, breaks when the stack moves or references another tree
config_path = "../../../platform/containers/ecs"
```

`get_parent_terragrunt_dir()` resolves to the directory of the parent config found
by the `include` block (where `root.hcl` lives). Prefer it over `get_repo_root()`,
which keys off the `.git` directory and breaks in monorepos or `.git`-less checkouts.

## Terraform Configuration Pattern Values for each Environment (R004.1)

All values for each environment must be defined in the respectively .`tfvars` file in `environment` folder and layer
```bash
environments/
├── dev
│   ├── applications.tfvars
│   ├── foundations.tfvars
│   ├── observability.tfvars
│   └── platform.tfvars
├── prd
│   ├── applications.tfvars
│   ├── foundations.tfvars
│   ├── observability.tfvars
│   └── platform.tfvars
└── qa
    ├── applications.tfvars
    ├── foundations.tfvars
    ├── observability.tfvars
    └── platform.tfvars


```
## Dependency Management (R005)

All dependencies **MUST** include:
- `config_path` anchored with `get_parent_terragrunt_dir()` (R004.2) — never a
  hand-counted relative `../` path
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

## Reserved / Auto-Generated Variables (R007)

Terragrunt auto-generates a `provider.tf` file in **every stack** at runtime from the
`generate "provider"` block in `common/common.hcl`. That generated file **already declares**
the following variables:

- `variable "project"`
- `variable "profile"`
- `variable "required_tags"`

### ❌ Never re-declare these in a stack's `variables.tf`
Doing so causes Terraform to fail with:
```
Error: Duplicate variable declaration
A variable named "project" (or "profile"/"required_tags") was already declared.
```

### ✅ Rules for the generated variables
- **Do NOT** declare `project`, `profile`, or `required_tags` in any stack `variables.tf`
  (or in `common/variables.tf`, or in local modules that are used as the stack root).
- **Do** reference them freely (e.g. `var.project`, `var.required_tags`) — they exist at plan/apply
  time because `provider.tf` is generated before Terraform runs.
- Their **values** come from `common/common.tfvars` and the `environments/<env>/*.tfvars` files,
  wired in by `root.hcl`. Do not add default values for them anywhere.
- Only declare stack-specific variables in `variables.tf` (e.g. `vpc_cidr`, `instance_type`).
- Tags: use `var.required_tags` for the provider `default_tags`; only add a stack-local tags
  variable if you need tags **beyond** the required set, and give it a distinct name (e.g.
  `additional_tags`).

If a module input needs `project`/`profile`/`required_tags`, pass `var.<name>` through
`inputs` in `terragrunt.hcl` or directly in `main.tf` — never by re-declaring the variable.

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

## Security Group Ownership & Connectivity (R014)

Security groups **MUST** follow a distributed-ownership model. There is **no**
shared/foundation security-groups stack.

### ✅ Rules
- **Each component owns the SG it needs, in its own stack.** The stack that
  creates a resource also creates its security group and outputs the id
  (e.g. `platform/containers/ecs` → `control_plane_security_group_id`,
  `platform/data/efs` → `efs_security_group_id`, `platform/data/rds` →
  `rds_security_group_id`, `application/compute/alb` → `alb_security_group_id`,
  `application/devsecops/jenkins` → `build_agent_security_group_id`). New DevOps
  tools own their SG in their own stack.
- **Component SGs set `enable_exclusive_rules = false`** (security-group module
  v6+) so cross-component rules added elsewhere are not revoked on the next apply.
- **Self-contained ingress** (e.g. the public ALB HTTPS/HTTP from CIDRs) stays on
  the owning SG. **Cross-component SG-to-SG rules** live ONLY in the dedicated
  `application/connectivity` stack.
- The **connectivity stack** takes each SG id via Terragrunt `dependency` blocks
  (anchored per R004.2) and creates the `aws_vpc_security_group_ingress_rule`
  resources between components.

### ❌ Never do
- Create a single shared stack that owns every SG with inline cross-references
  (causes module cycles and poor scaling).
- Put a mutual SG-to-SG reference inline in two component stacks (Terraform
  rejects the module cycle). Use the connectivity stack instead.

### Adding a new tool
1. Create the tool's SG in its own stack (`enable_exclusive_rules = false`),
   output its id.
2. Add a `dependency` block + input and the ingress rule(s) in
   `application/connectivity`.

## Prohibited Practices

### ❌ Never Do:
- Use unverified community modules
- Hardcode values instead of variables
- Skip version constraints
- Create inline IAM policies
- Put workloads in public subnets
- Use unencrypted storage
- Skip mandatory tags
- Use hand-counted relative `../` dependency `config_path`s (R004.2)
- Create a shared security-groups stack with inline cross-references (R014)

### ✅ Always Do:
- Use terraform-aws-modules first
- Pin exact versions
- Include complete stack structure
- Follow terragrunt patterns
- Apply comprehensive tagging
- Declare dependencies with mocks
- Anchor dependency `config_path`s with `get_parent_terragrunt_dir()` (R004.2)
- Let each component own its SG; wire cross-SG rules in `application/connectivity` (R014)
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