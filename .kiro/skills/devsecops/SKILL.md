# ThothCTL DevSecOps Workflow Skill

## Purpose

Guide developers through the complete DevSecOps SDLC for Infrastructure as Code using ThothCTL. Orchestrate phases intelligently based on project context, provide remediation guidance on failures, and enforce organizational security policies.

## When to Use

- User wants to validate, secure, or prepare IaC for deployment
- User asks about security posture, compliance, or vulnerabilities
- User mentions cost estimation, blast radius, drift, or change impact
- User says "prepare for production", "run the pipeline", "audit my code"
- User asks "is my infrastructure safe to deploy?"
- User wants to know what changed or detect drift

## When NOT to Use

- Writing new Terraform/Terragrunt code (use the thoth IaC agent instead)
- AWS service configuration questions (use aws-knowledge)
- General coding questions unrelated to IaC security/compliance

## MCP Tools Required

| Tool | Used For |
|------|----------|
| `thothctl_scan_iac` | Security scanning (checkov, trivy, opa) |
| `thothctl_check_project` | Project structure validation |
| `thothctl_check_environment` | Environment tool verification |
| `thothctl_check_iac` | Plan validation, blast-radius, cost, drift |
| `thothctl_inventory_iac` | Module/provider inventory and versions |
| `thothctl_document_iac` | Documentation generation |
| `thothctl_cost_analysis` | AWS cost estimation from tfplan |
| `thothctl_drift_detection` | Infrastructure drift detection |

---

## Decision Logic

### Intent → Phase Routing

When the user's intent is ambiguous, route to the most appropriate phase:

| User Intent Pattern | Phase | Rationale |
|---------------------|-------|-----------|
| "check my project" / "validate" / "is this correct?" | `develop` | Structure and environment first |
| "security scan" / "vulnerabilities" / "is it secure?" | `secure` | Direct security focus |
| "ready for production?" / "can I deploy?" / "pre-deploy" | `pre-deploy` | Combined test + secure gate |
| "how much will this cost?" / "cost estimate" | `plan` | Requires tfplan.json |
| "what changed?" / "blast radius" / "impact" | `plan` | Requires tfplan.json |
| "full audit" / "run everything" / "complete check" | `all` | Full pipeline |
| "drift" / "is prod in sync?" / "state mismatch" | `monitor` | Requires cloud credentials |
| "dependencies" / "outdated modules" / "versions" | `build` | Inventory analysis |
| "documentation" / "generate docs" | `develop` | Includes doc generation |

### Project Type Detection

Before executing, detect the project type to adapt commands:

```
Has terragrunt.hcl      → terraform-terragrunt (use hcl/ policies)
Has main.tf only        → terraform (use hcl/ policies)
Has cdk.json            → cdkv2 (use cloudformation/ policies)
Has *.template.json/yaml → cloudformation (use cloudformation/ policies)
```

This affects:
- OPA policy path selection (`shared/policy/hcl/` vs `shared/policy/cloudformation/`)
- Plan generation commands (terragrunt vs terraform)
- Inventory framework flag (`--framework-type terragrunt`)

### Enforcement Decision

| Context | Enforcement | Why |
|---------|-------------|-----|
| Local development / exploratory | `soft` | Don't block developer flow |
| User says "strict" / "production" / "hard" | `hard` | Explicit request |
| CI/CD pipeline context | `hard` | Pipeline should gate |
| User says "just show me" / "report" | `soft` | Information only |

---

## Workflow Procedures

### Procedure: Full DevSecOps Pipeline

Execute when user asks for a complete audit or "run everything".

```
1. Detect project type (terragrunt.hcl → terraform-terragrunt, main.tf → terraform, cdk.json → cdkv2)

2. PHASE: Develop
   → Run: thothctl_check_environment
   → Run: thothctl_check_project
   → If failures: report issues, suggest fixes, continue

3. PHASE: Build
   → Run: thothctl_inventory_iac (with --check-versions)
   → If outdated modules found: list them with latest versions

4. PHASE: Plan (only if tfplan/ or tfplan.json exists)
   → Run: thothctl_cost_analysis (--recursive)
   → Run: thothctl_check_iac -type blast-radius
   → If no plan files: inform user how to generate them

5. PHASE: Secure
   → Run: thothctl_scan_iac (tools: checkov, trivy, opa)
   → Analyze findings by severity (CRITICAL > HIGH > MEDIUM > LOW)
   → For CRITICAL/HIGH: show specific remediation

6. Summarize:
   → Total findings by severity
   → Top 3 priority fixes with file:line references
   → Overall readiness verdict
```

### Procedure: Security Audit

Execute when user asks specifically about security.

```
1. Run: thothctl_scan_iac (tools: checkov, trivy, opa, enforcement: soft)

2. Parse results:
   → Group by severity
   → Group by category (encryption, networking, IAM, tagging)

3. For each CRITICAL finding:
   → Explain the risk in plain language
   → Provide the specific HCL/YAML fix
   → Reference the CIS/AWS benchmark

4. For HIGH findings:
   → List them with resource and file location
   → Provide fix pattern (reference remediation_patterns.md)

5. Summary:
   → "X critical, Y high, Z medium findings"
   → Compliance score: passed / (passed + failed) %
   → Recommendation: fix critical issues before deployment
```

### Procedure: Pre-Deployment Validation

Execute when user wants to know if code is ready to deploy.

```
1. Check prerequisites:
   → Does tfplan.json exist? If not:
     "I need a Terraform plan to validate deployment readiness.
      Generate one with:
      terragrunt run-all plan --out-dir tfplan --json-out-dir tfplan"
     STOP and wait for user.

2. Run: thothctl_check_iac -type blast-radius
   → If blast radius > 10 resources: WARN user about broad impact
   → If blast radius includes destructive actions (delete/replace): ALERT

3. Run: thothctl_scan_iac (tools: checkov, trivy, opa, enforcement: hard)
   → If CRITICAL violations: BLOCK — "Cannot deploy. Fix these first:"
   → If HIGH violations only: WARN — "Deploy at risk. Consider fixing:"
   → If clean: APPROVE — "✅ All gates passed. Safe to deploy."

4. Run: thothctl_cost_analysis
   → Show monthly cost projection
   → Flag unexpected cost increases > 20%
```

### Procedure: Cost Analysis

Execute when user asks about costs.

```
1. Check if tfplan.json exists. If not:
   "Cost analysis requires a Terraform plan. Generate with:
    terraform plan -out=tfplan.binary
    terraform show -json tfplan.binary > tfplan.json"

2. Run: thothctl_cost_analysis (--recursive if multiple stacks)

3. Present results:
   → Monthly/annual projection
   → Per-service breakdown
   → Optimization recommendations
   → Compare with previous estimate if available
```

### Procedure: Drift Detection

Execute when user asks about drift or state sync.

```
1. Confirm cloud credentials are available
   → If not: "Drift detection requires AWS credentials configured."

2. Run: thothctl_drift_detection (--tftool tofu, --recursive)

3. Present results:
   → Resources with drift (added, changed, deleted)
   → Risk assessment per drift item
   → Remediation options:
     a) Update IaC to match current state (adopt drift)
     b) Run apply to revert cloud to IaC state
     c) Investigate why drift occurred (manual change? another pipeline?)
```

---

## Response Patterns

### On Success (All Phases Pass)

```
✅ DevSecOps validation complete — all {N} checks passed.

Summary:
- Security: {passed} checks passed across {tools}
- Structure: Project follows organizational standards
- Dependencies: All modules at latest versions

Your infrastructure code is ready for deployment.
Reports saved to: Reports/
```

### On Failure (Soft Enforcement)

```
⚠️ Found {N} issues ({critical} critical, {high} high, {medium} medium).

Priority fixes:
1. [CRITICAL] {check_id}: {description}
   File: {file}:{line}
   Fix: {specific remediation}

2. [HIGH] {check_id}: {description}
   File: {file}:{line}
   Fix: {specific remediation}

Run with --enforcement hard to block deployments until resolved.
Full report: Reports/scan_report.html
```

### On Failure (Hard Enforcement)

```
⛔ Pipeline blocked — {N} violations must be resolved before deployment.

Blocking issues:
1. {check_id} — {resource} — {description}
   → Fix: {specific HCL/YAML change}

2. {check_id} — {resource} — {description}
   → Fix: {specific HCL/YAML change}

After fixing, re-run: thothctl workflow devsecops --phase secure --enforcement hard
```

### On Missing Prerequisites

```
ℹ️ The {phase} phase requires {prerequisite}.

To generate it:
  {command to generate prerequisite}

Once ready, I'll continue with the analysis.
```

---

## Remediation Knowledge

### Common Checkov Findings

| Check ID | Issue | Fix |
|----------|-------|-----|
| CKV_AWS_145 | S3 bucket not encrypted | Add `server_side_encryption_configuration` block |
| CKV_AWS_18 | S3 bucket logging disabled | Add `logging` block pointing to log bucket |
| CKV_AWS_19 | S3 bucket not private | Add `block_public_acls = true` + all 4 public access settings |
| CKV_AWS_130 | RDS not encrypted | Set `storage_encrypted = true` |
| CKV_AWS_16 | RDS not multi-AZ | Set `multi_az = true` (production only) |
| CKV_AWS_23 | Security group allows 0.0.0.0/0 | Restrict `cidr_blocks` to specific ranges |
| CKV_AWS_24 | Security group allows all ports | Specify exact `from_port` and `to_port` |
| CKV2_AWS_5 | Security group not attached | Attach to resource or remove |
| CKV_AWS_79 | Instance metadata v1 enabled | Set `http_tokens = "required"` in metadata options |
| CKV_AWS_126 | EKS control plane logging | Enable all log types in `enabled_cluster_log_types` |

### Common OPA Policy Violations

| Policy | Issue | Fix |
|--------|-------|-----|
| tagging.rego | Missing required tags | Add tags: Environment, Owner, CostCenter, ManagedBy |
| naming.rego | Invalid resource name | Follow pattern: `{env}-{service}-{name}` |
| regions.rego | Unapproved region | Use allowed regions: us-east-1, us-east-2, us-west-2, eu-west-1 |
| encryption.rego | Missing encryption | Enable encryption at rest for all storage resources |
| iam.rego | Wildcard IAM actions | Replace `*` with specific actions |

---

## Project Type Adaptations

### Terraform + Terragrunt

```bash
# Plan generation
terragrunt run-all plan --out-dir tfplan --json-out-dir tfplan

# Scan command
thothctl scan iac -t checkov -t trivy -t opa

# Inventory
thothctl inventory iac --check-versions --framework-type terragrunt
```

### Standalone Terraform

```bash
# Plan generation
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# Scan command
thothctl scan iac -t checkov -t trivy -t opa

# Inventory
thothctl inventory iac --check-versions
```

### AWS CDK

```bash
# Synthesize
cdk synth --output cdk.out

# Scan synthesized templates
thothctl scan iac -t checkov -t trivy --policy-dir shared/policy/cloudformation

# Cost analysis
thothctl check iac -type cost-analysis --template cdk.out/MyStack.template.json
```

### CloudFormation / SAM

```bash
# Scan templates directly
thothctl scan iac -t checkov -t trivy --policy-dir shared/policy/cloudformation

# No plan needed — scan the template files directly
```
