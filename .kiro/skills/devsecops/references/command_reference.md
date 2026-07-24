# ThothCTL Command Reference for AI Agents

## Quick Reference

| Action | MCP Tool | Key Parameters |
|--------|----------|----------------|
| Check environment | `thothctl_check_environment` | — |
| Check project structure | `thothctl_check_project` | — |
| Check IaC (plan/blast/cost/drift) | `thothctl_check_iac` | — |
| Security scan | `thothctl_scan_iac` | tools, enforcement |
| Inventory | `thothctl_inventory_iac` | check_versions, project_name |
| Generate docs | `thothctl_document_iac` | — |
| Cost analysis | `thothctl_cost_analysis` | recursive |
| Drift detection | `thothctl_drift_detection` | tftool, recursive |
| Generate IaC from intent | `thothctl_generate_iac` | intent, project_type |

---

## Detailed Tool Parameters

### thothctl_scan_iac

Runs security scanning tools against IaC code.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `tools` | list[string] | ["checkov"] | Tools: checkov, trivy, kics, opa, terraform-compliance |
| `enforcement` | string | "soft" | "soft" (report) or "hard" (exit 1 on violations) |

**Example call:**
```json
{
  "tools": ["checkov", "trivy", "opa"],
  "enforcement": "soft"
}
```

---

### thothctl_inventory_iac

Creates infrastructure inventory with version analysis.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `check_versions` | boolean | false | Check for latest module versions |
| `project_name` | string | auto | Project name for report |

**Example call:**
```json
{
  "check_versions": true
}
```

---

### thothctl_cost_analysis

Estimates AWS costs from Terraform plans.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `recursive` | boolean | false | Search recursively for plan files |

**Example call:**
```json
{
  "recursive": true
}
```

---

### thothctl_drift_detection

Detects infrastructure drift between IaC and live resources.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `tftool` | string | "tofu" | terraform or tofu |
| `recursive` | boolean | false | Search recursively |
| `filter_tags` | string | — | Filter by tags (e.g., "env=prod") |

**Example call:**
```json
{
  "tftool": "tofu",
  "recursive": true
}
```

---

### thothctl_generate_iac

Generates IaC code from natural language intent.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `intent` | string | required | Natural language description |
| `project_type` | string | "auto" | terraform, terraform-terragrunt, cloudformation, cdkv2 |
| `apply` | boolean | false | Write files to disk (false = dry-run) |
| `self_correct` | boolean | true | Auto-fix validation violations |

**Example call:**
```json
{
  "intent": "Create a VPC with public and private subnets in us-east-1",
  "project_type": "terraform-terragrunt",
  "apply": false
}
```

---

## CLI Equivalents

When explaining commands to the user, use these CLI forms:

| MCP Tool Call | Equivalent CLI |
|---------------|----------------|
| `thothctl_check_environment` | `thothctl check environment` |
| `thothctl_check_project` | `thothctl check project iac` |
| `thothctl_scan_iac(tools=["checkov","trivy","opa"])` | `thothctl scan iac -t checkov -t trivy -t opa` |
| `thothctl_scan_iac(enforcement="hard")` | `thothctl scan iac --enforcement hard` |
| `thothctl_inventory_iac(check_versions=true)` | `thothctl inventory iac --check-versions` |
| `thothctl_cost_analysis(recursive=true)` | `thothctl check iac -type cost-analysis --recursive` |
| `thothctl_drift_detection(recursive=true)` | `thothctl check iac -type drift --recursive` |
| `thothctl_document_iac` | `thothctl document iac` |

## Workflow CLI (for user reference)

```bash
# The user can also run phases directly:
thothctl workflow devsecops --phase plan
thothctl workflow devsecops --phase develop
thothctl workflow devsecops --phase build
thothctl workflow devsecops --phase test
thothctl workflow devsecops --phase secure
thothctl workflow devsecops --phase deploy --enforcement hard
thothctl workflow devsecops --phase monitor
thothctl workflow devsecops --phase pre-deploy --enforcement hard
thothctl workflow devsecops --phase all
```
