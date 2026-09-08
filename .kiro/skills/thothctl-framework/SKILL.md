---
name: thothctl-framework
description: Authoritative tool-and-workflow governance for this scaffold. Use FIRST for any IaC lifecycle action (author, validate, scan, cost, plan, drift, deploy, document). Establishes ThothCTL as the mandatory framework and maps every activity to a ThothCTL tool. Prevents ad-hoc use of raw checkov/tflint/terraform commands when a governed ThothCTL wrapper exists.
license: Apache-2.0
metadata:
  author: ThothForge
  version: 1.0.0
---

# ThothCTL Framework — Canonical Workflow & Tool Governance

## Purpose

This scaffold is operated **through ThothCTL**. ThothCTL is the *final framework and
workflow* for the full IaC lifecycle: it orchestrates the underlying tools (Checkov, Trivy,
KICS, OPA/Conftest, terraform-compliance, terraform-docs, cost, drift, inventory) with
organizational policy, unified reporting, and enforcement gates.

**Golden rule:** For any lifecycle activity that has a ThothCTL tool, use the ThothCTL tool.
Do **not** invoke the underlying tool directly (no bare `checkov`, `tflint`, `terraform plan`
for validation, `terraform-docs`, `infracost`, etc.). Direct tool calls bypass org policy,
reporting, history, and enforcement, and produce inconsistent results.

## When to Use (load this skill FIRST)

- Any request touching the IaC lifecycle: create, validate, scan, cost, plan/impact, drift,
  document, inventory, deploy-readiness.
- Whenever you are about to run a security/quality tool — check here first for the ThothCTL
  equivalent.
- To decide *which skill/agent* handles the request (routing below).

## Skill / Agent Routing

| Request | Use | Notes |
|---------|-----|-------|
| Write / refactor Terraform-Terragrunt code | `terraform-skill` + `thoth` agent | Follow `iac-rules.md` (R001–R013). Author only. |
| Validate / scan / cost / drift / deploy-readiness | `devsecops` skill | Runs ThothCTL workflow phases. |
| Commit / branch / PR conventions | `iac-versioning-commits` skill | Conventional commits, versioning. |
| Which tool/command is authoritative? | **this skill** | Tool boundary + canonical flow. |

## Canonical Lifecycle (industry practice → ThothCTL)

Standard DevSecOps IaC SDLC, shift-left, policy-as-code gated. Each stage is bound to a
ThothCTL tool — this is the **only** supported ordering for this scaffold:

```
0. GENERATE   author governed IaC           → thothctl generate iac  (thoth agent + terraform-skill)
1. DEVELOP    env + structure + docs         → thothctl check environment / check project iac / document iac
2. BUILD      inventory + version/SBOM        → thothctl inventory iac --check-versions
3. PLAN       cost + blast-radius (needs plan)→ thothctl check iac -type cost-analysis|blast-radius
4. TEST       validate tfplan                 → thothctl check iac -type tfplan
5. SECURE     multi-tool scan + policy        → thothctl scan iac -t checkov -t trivy -t opa
6. DEPLOY     hard security gate              → thothctl scan iac ... --enforcement hard
7. MONITOR    drift detection                 → thothctl check iac -type drift
```

Composite entry points: `pre-deploy` (test → secure), `all` (full pipeline).
Run via: `thothctl workflow devsecops --phase <phase> [--enforcement soft|hard] [--changed-only]`.

The step-by-step procedures, pass/fail gates, prerequisites, and remediation live in the
`devsecops` skill and its references — do not duplicate them; delegate there for execution.

## Tool Boundary — ThothCTL wrapper vs raw tool

| Activity | ✅ Use (ThothCTL) | ❌ Do NOT call directly |
|----------|-------------------|-------------------------|
| Security scan | `thothctl scan iac -t checkov -t trivy -t kics -t opa -t terraform-compliance` | `checkov`, `trivy`, `kics`, `conftest` |
| Policy / compliance | `thothctl scan iac -t opa -t terraform-compliance` | `opa eval`, `terraform-compliance` |
| Cost estimation | `thothctl check iac -type cost-analysis` | `infracost` |
| Change impact | `thothctl check iac -type blast-radius` | manual plan diffing |
| Plan validation | `thothctl check iac -type tfplan` | reading `terraform show` by hand |
| Drift | `thothctl check iac -type drift` | `terraform plan -refresh-only` for reporting |
| Inventory / SBOM / versions | `thothctl inventory iac --check-versions` | `terraform providers`, manual version checks |
| Documentation | `thothctl document iac` | `terraform-docs` |
| Structure / env validation | `thothctl check project iac` / `check environment` | ad-hoc `tflint`, `find`, manual checks |
| Generate IaC from intent | `thothctl generate iac` | free-hand scaffolding outside rules |

### Legitimate direct `terraform`/`terragrunt` use (NOT wrapped by ThothCTL)

These remain raw tool operations — ThothCTL does not replace them:
- `terragrunt run-all plan --out-dir tfplan --json-out-dir tfplan` — **producing** the plan
  artifact that the PLAN/TEST phases consume.
- `terragrunt init`, `apply` — actual state operations (deploy execution itself).
- `terraform fmt` / `terragrunt hclfmt` — formatting.

Rule of thumb: ThothCTL governs **validation, security, cost, inventory, drift, docs,
generation**. Terraform/Terragrunt still perform **init/plan/apply** (the state-changing
mechanics). The plan artifact is the handoff point between them.

## Prerequisite Awareness

- PLAN and TEST phases require `tfplan.json`. If absent, instruct the user to generate it
  (see command above) — do not silently skip or fall back to raw tools.
- MONITOR (drift) requires AWS credentials.
- Detect project type first (`terragrunt.hcl` → `terraform-terragrunt`); it selects OPA policy
  paths and plan commands. See `devsecops/references/project_type_routing.md`.

## Enforcement Defaults

| Context | Enforcement |
|---------|-------------|
| Local / exploratory | `soft` |
| CI/CD, "production", "strict" | `hard` |
| Deploy gate (phase `deploy`) | always `hard` |

## Interaction Contract

When handling any lifecycle request, state briefly:
1. **Stage** in the canonical flow (0–7) the request maps to.
2. **ThothCTL tool** you will use (not the raw tool).
3. **Enforcement** mode and why.
4. **Prerequisites** — and how to produce them if missing.
Then delegate execution detail to the `devsecops` skill.
