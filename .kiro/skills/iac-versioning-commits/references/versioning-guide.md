# IaC Versioning Guide — Tagging Code Specification

## Version Format

```
vMAJOR.MINOR.PATCH
```

All tags MUST be annotated (`git tag -a`) and prefixed with `v`.

## Decision Matrix

Use this matrix to determine which version component to increment.

### MAJOR (Breaking / Framework)

| Change | Example | Why MAJOR |
|--------|---------|-----------|
| Add environment | Add `stg` environment alongside dev/qa/prd | New environment changes deployment matrix |
| Remove environment | Remove `qa` from pipeline | Reduces deployment targets |
| Modify root.hcl | Change remote state backend from S3 to GCS | All stacks affected |
| Modify common.hcl | Change provider generation logic | All stacks re-generate providers |
| Change layer architecture | Add `security` as a new layer between foundation and platform | Dependency chain restructured |
| Provider major upgrade | AWS provider 5.x → 6.x requiring state migration | Potential resource recreation |
| Change directory convention | Rename `stacks/` to `infrastructure/` | All paths and references break |
| Remote state restructure | Change state key pattern or bucket | State migration required |

**Rule**: If the change requires coordinated updates across ALL environments or alters how Terragrunt/Terraform operates project-wide, it's MAJOR.

### MINOR (Capability / Modules)

| Change | Example | Why MINOR |
|--------|---------|-----------|
| Add new stack | Create `stacks/platform/data/elasticache/` | New infrastructure capability |
| Remove unused stack | Delete `stacks/application/storage/efs/` (no dependents) | Capability removed |
| Add module to stack | Add WAF module to ALB stack | New resource type in existing stack |
| Remove module from stack | Remove unused CloudWatch dashboard module | Capability reduced |
| Add new resources | Add NAT Gateway to VPC stack | New infrastructure component |
| New outputs | Export additional values from a stack | Downstream stacks can consume new data |
| New variables | Add configurable parameters to a stack | More flexibility without breaking |
| New dependency | EKS stack now depends on new KMS stack | Dependency graph expanded |
| Add domain | Create `stacks/platform/messaging/` directory with first stack | New infrastructure domain |

**Rule**: If the change adds or removes a deployable capability while existing environments continue working unchanged, it's MINOR.

### PATCH (Fixes / Settings / Docs)

| Change | Example | Why PATCH |
|--------|---------|-----------|
| Fix resource config | Correct security group ingress CIDR | Bug fix |
| Fix variable default | Change default instance type from t3.micro to t3.small | Configuration correction |
| Update .tfvars | Change dev VPC CIDR in `environments/dev/foundations.tfvars` | Environment-specific tuning |
| Module version bump | Update `terraform-aws-modules/vpc/aws` from 5.0.0 to 5.1.2 | Patch/minor dependency update |
| Fix dependency path | Correct relative path in terragrunt.hcl dependency block | Bug fix |
| Fix mock outputs | Add missing mock output field | Terragrunt plan fix |
| Update tags | Add missing `CostCenter` tag to all stacks | Compliance fix |
| Documentation | Update README, add architecture diagram | No infrastructure change |
| Formatting | Run `terraform fmt` across stacks | No functional change |
| Pre-commit config | Update `.pre-commit-config.yaml` hooks | Tooling change |
| Linting rules | Modify `.tflint.hcl` configuration | Tooling change |

**Rule**: If the change fixes behavior, adjusts settings, or improves documentation without adding/removing capability, it's PATCH.

## Edge Cases

### Multiple changes in one release

When a release contains changes spanning multiple levels, use the **highest** level:

- PATCH fix + MINOR new stack = **MINOR**
- MINOR new module + MAJOR new environment = **MAJOR**

### Module version pins

| Module version change | Version impact |
|-----------------------|---------------|
| Patch bump (5.0.0 → 5.0.1) | PATCH |
| Minor bump (5.0.0 → 5.1.0) | PATCH |
| Major bump (5.0.0 → 6.0.0) | Evaluate: MINOR if no state migration, MAJOR if state migration required |

### Terragrunt dependency changes

| Dependency change | Version impact |
|-------------------|---------------|
| Fix existing dependency path | PATCH |
| Add new dependency to existing stack | MINOR |
| Remove dependency from stack | MINOR |
| Change mock_outputs structure | PATCH |

## Tagging Workflow

```bash
# 1. Check current version
CURRENT=$(git tag --sort=-v:refname | head -1)
echo "Current: $CURRENT"

# 2. Determine new version based on changes since last tag
git log $CURRENT..HEAD --oneline

# 3. Apply decision matrix to determine MAJOR/MINOR/PATCH

# 4. Create annotated tag
git tag -a v1.2.0 -m "feat(platform): add ElastiCache stack for session caching

intent(elasticache): application team needs distributed session store
decision(elasticache): ElastiCache Redis over Memcached for persistence support"

# 5. Push
git push --tags
```

## Version History Convention

Maintain a clear tag history that maps to infrastructure evolution:

```
v1.0.0 — Initial scaffold with foundation layer (VPC, IAM)
v1.1.0 — Add EKS platform stack
v1.1.1 — Fix EKS node group instance types
v1.2.0 — Add RDS PostgreSQL stack
v1.2.1 — Update VPC module to 5.1.2
v2.0.0 — Add staging environment, restructure common.hcl
```
