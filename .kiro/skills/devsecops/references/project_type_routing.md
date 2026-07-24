# Project Type Routing

## Detection Logic

Check files in the project root to determine type:

| File Present | Project Type | Detection Priority |
|-------------|--------------|-------------------|
| `terragrunt.hcl` or `root.hcl` | `terraform-terragrunt` | 1 (highest) |
| `cdk.json` | `cdkv2` | 2 |
| `template.yaml` + `AWSTemplateFormatVersion` | `cloudformation` | 3 |
| `main.tf` | `terraform` | 4 (default) |

---

## Command Variations by Project Type

### Plan Generation

| Type | Command |
|------|---------|
| terraform-terragrunt | `terragrunt run-all plan --out-dir tfplan --json-out-dir tfplan` |
| terraform | `terraform plan -out=tfplan.binary && terraform show -json tfplan.binary > tfplan.json` |
| cdkv2 | `cdk synth --output cdk.out` (no plan needed — scan synth output) |
| cloudformation | N/A (scan templates directly) |

### Scan Tools

| Type | Default Tools | Policy Path |
|------|--------------|-------------|
| terraform-terragrunt | checkov, trivy, opa | `shared/policy/hcl/` |
| terraform | checkov, trivy, opa | `shared/policy/hcl/` |
| cdkv2 | checkov, trivy | `shared/policy/cloudformation/` |
| cloudformation | checkov, trivy | `shared/policy/cloudformation/` |

### Inventory Flags

| Type | Extra Flags |
|------|-------------|
| terraform-terragrunt | `--framework-type terragrunt` |
| terraform | (default) |
| cdkv2 | Not supported (use `cdk list` instead) |
| cloudformation | Not supported |

### Drift Detection

| Type | Supported | Notes |
|------|-----------|-------|
| terraform-terragrunt | ✅ | Uses `terragrunt run-all plan` internally |
| terraform | ✅ | Uses `terraform plan` internally |
| cdkv2 | ❌ | Use `cdk diff` instead |
| cloudformation | ❌ | Use CloudFormation drift detection API |

### Cost Analysis

| Type | Supported | Input |
|------|-----------|-------|
| terraform-terragrunt | ✅ | `tfplan/` directory (recursive) |
| terraform | ✅ | `tfplan.json` file |
| cdkv2 | ✅ | `cdk.out/*.template.json` |
| cloudformation | ✅ | Template YAML/JSON file |

---

## Policy Directory Structure

When using `--policy-dir` with a Git URL (org-iac-policies repo):

```
org-iac-policies/
├── shared/policy/
│   ├── hcl/              ← Terraform/OpenTofu/Terragrunt
│   │   ├── tagging.rego
│   │   ├── naming.rego
│   │   ├── regions.rego
│   │   └── config.yaml
│   └── cloudformation/   ← CloudFormation/SAM/CDK
│       ├── tagging.rego
│       ├── naming.rego
│       └── regions.rego
├── layers/
│   ├── security/policy/{hcl,cloudformation}/
│   └── networking/policy/{hcl,cloudformation}/
└── workloads/
    ├── containers/policy/{hcl,cloudformation}/
    └── databases/policy/{hcl,cloudformation}/
```

### Policy Selection Logic

```
IF project_type IN (terraform, terraform-terragrunt):
    policy_path = "<org-repo>/shared/policy/hcl"
ELSE IF project_type IN (cdkv2, cloudformation):
    policy_path = "<org-repo>/shared/policy/cloudformation"
```

The AI agent should pass the correct subdirectory when calling `thothctl_scan_iac` with a policy directory.
