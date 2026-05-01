---
name: iac-versioning-commits
description: Write contextual commits and manage semantic versioning for Infrastructure as Code projects. Use when committing IaC changes, tagging releases, bumping versions, or preparing infrastructure deployments. Combines Conventional Commits with IaC-specific action lines and MAJOR.MINOR.PATCH versioning tailored for Terraform/Terragrunt projects.
---

# IaC Versioning & Contextual Commits

You write commits that carry infrastructure reasoning in the body and manage version tags following IaC-specific semantic versioning. Every commit captures WHY infrastructure was changed, and every version tag reflects the impact scope.

## Commit Format

Subject line follows Conventional Commits. Body contains **action lines** — typed, scoped entries capturing infrastructure reasoning.

```
type(scope): subject line

action-type(scope): description of reasoning or context
```

### Subject Line Types for IaC

| Type | Use for |
|------|---------|
| `feat` | New stack, module, resource, or environment |
| `fix` | Bug fixes in resource configs, variable corrections |
| `refactor` | Restructuring stacks, moving resources, changing patterns |
| `chore` | Dependency updates, version bumps, tooling changes |
| `docs` | Documentation, README, comments |
| `style` | Formatting, HCL style fixes |
| `ci` | Pipeline, GitOps, pre-commit changes |
| `security` | IAM policies, encryption, security group changes |

### Scope Convention

Scopes follow the project's layer/domain/service path:

- `foundation/network/vpc` → scope: `vpc` or `network`
- `platform/containers/eks` → scope: `eks` or `containers`
- `application/compute/alb` → scope: `alb` or `compute`
- `observability/monitoring/cloudwatch` → scope: `cloudwatch`
- Cross-cutting changes → scope: `infra`, `deps`, or the affected domain

## Action Types

Use only types that apply. Most IaC commits need 1-3 action lines.

### `intent(scope): ...`

What infrastructure goal the user wanted to achieve.
- `intent(vpc): isolate workloads with private subnets per AZ`
- `intent(eks): provide managed Kubernetes for microservices platform`

### `decision(scope): ...`

What approach was chosen when alternatives existed.
- `decision(vpc): terraform-aws-modules/vpc over custom module for maintainability`
- `decision(rds): multi-az over read-replicas for HA requirements`

### `rejected(scope): ...`

What was considered and discarded. Always include the reason.
- `rejected(eks): self-managed nodes — operational overhead too high for team size`
- `rejected(rds): Aurora Serverless v1 — incompatible with required PostgreSQL extensions`

### `constraint(scope): ...`

Hard limits that shaped the infrastructure design.
- `constraint(vpc): CIDR must not overlap with on-prem 10.0.0.0/8 range`
- `constraint(eks): cluster version 1.28+ required for pod identity`

### `learned(scope): ...`

Discoveries that save time in future sessions.
- `learned(terragrunt): mock_outputs_merge_strategy must be shallow for nested outputs`
- `learned(alb): internal ALB requires explicit security group for cross-VPC access`

### `impact(scope): ...` *(IaC-specific)*

Blast radius and dependency effects of the change.
- `impact(vpc): all platform and application stacks depend on this — requires full run-all plan`
- `impact(iam): role change affects EKS, Lambda, and CI/CD pipeline assume-role`

## Before You Commit

1. **Check staged changes**: `git diff --cached --stat`
2. **Identify the layer(s) affected**: foundation, platform, application, observability
3. **Assess blast radius**: which downstream stacks depend on changed resources?
4. **Write action lines** from session context — never fabricate reasoning you don't have
5. **Determine version impact** using the rules below

## Version Tagging Code (MAJOR.MINOR.PATCH)

Format: `vMAJOR.MINOR.PATCH` (e.g., `v1.2.3`)

Current project version: check with `git tag --sort=-v:refname | head -1`

### MAJOR — Breaking infrastructure changes

Increment MAJOR when the change is **not backward-compatible across environments** or alters the framework itself:

- Adding or removing an **environment** (dev, qa, stg, prd)
- Changes to `root.hcl`, `common.hcl`, or the Terragrunt framework structure
- Modifying remote state backend configuration
- Changing the layer architecture (adding/removing layers)
- Provider major version upgrades that require state migration
- Changes to the project scaffolding or directory convention

### MINOR — Module and resource changes with compatibility

Increment MINOR when you **add or remove capability** while maintaining compatibility with existing environments:

- Adding a new **stack** (e.g., `stacks/platform/data/elasticache/`)
- Removing a stack that other stacks don't depend on
- Adding or removing a **module** within a stack
- Adding new **resources** to existing stacks
- Adding new **outputs** or **variables** (non-breaking)
- New dependency declarations between stacks
- Adding a new layer domain (e.g., `stacks/platform/messaging/`)

### PATCH — Fixes, settings, and documentation

Increment PATCH for changes that are **compatible with all environments** and don't alter capability:

- Bug fixes in resource configurations
- Corrections to module parameters or variable defaults
- Environment-specific `.tfvars` value changes
- Documentation or README updates
- HCL formatting or style fixes
- Updating module version pins (patch/minor bumps)
- Fixing terragrunt dependency paths or mock outputs
- Adding or updating tags
- Pre-commit hook or linting config changes

### Tagging Workflow

```bash
# 1. Determine current version
git tag --sort=-v:refname | head -1

# 2. Commit with contextual message
git commit

# 3. Tag with the new version
git tag -a vX.Y.Z -m "type(scope): brief description of version changes"

# 4. Push with tags
git push && git push --tags
```

### Tag Message Format

Tag annotations follow the same contextual format:

```
vX.Y.Z - type(scope): summary

action-type(scope): key reasoning for this release
```

## Rules

1. **Subject line is a Conventional Commit.** Never break existing conventions.
2. **Action lines go in the body only.** Never in the subject line.
3. **Only write action lines that carry signal.** If the diff explains it, don't repeat it.
4. **Use consistent scopes.** Match the project's stack naming: `vpc`, `eks`, `alb`, not `networking`, `kubernetes`, `load-balancer`.
5. **Capture the user's intent in their words.** For `intent` lines, reflect what the human asked for.
6. **Always explain why for `rejected` lines.** A rejection without a reason is useless.
7. **Don't fabricate context you don't have.** See the contextual-commit rules for unknown changes.
8. **Assess blast radius for every IaC commit.** Use `impact` lines when changes affect downstream stacks.
9. **Version tags require a clean commit history.** Tag only after all related commits are complete.
10. **Never skip version assessment.** Every commit should be evaluated for version impact, even if no tag is created immediately.

## When You Lack Context

For changes you didn't produce in this session, only write action lines evidenced by the diff. A clean conventional commit subject with no action lines is better than fabricated context. You CAN infer `decision` from visible technical choices in the diff. You CANNOT infer `intent`, `rejected`, `constraint`, or `learned`.

## Reference Files

- `references/versioning-guide.md` — Detailed version decision matrix with examples
- `references/commit-examples.md` — IaC-specific commit message examples
