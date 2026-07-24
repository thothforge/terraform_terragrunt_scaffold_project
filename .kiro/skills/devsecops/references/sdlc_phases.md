# SDLC Phase Reference

## Phase Execution Order

```
plan → develop → build → test → secure → deploy → monitor
```

## Composite Phases

| Composite | Expands To |
|-----------|-----------|
| `pre-deploy` | test → secure |
| `all` | plan → develop → build → test → secure → deploy → monitor |

---

## Phase Details

### 📋 Plan

**Objective:** Estimate costs and assess change impact before deployment.

**Prerequisites:** `tfplan.json` files must exist.

**ThothCTL Commands:**
```bash
thothctl check iac -type cost-analysis --recursive
thothctl check iac -type blast-radius --recursive
```

**MCP Tools:**
- `thothctl_cost_analysis` (recursive: true)
- `thothctl_check_iac` (check_type: blast-radius)

**Pass Criteria:** Commands execute without error. No gate — informational only.

**Skip Condition:** No `tfplan.json` found in project tree.

---

### 💻 Develop

**Objective:** Validate development environment and project structure.

**Prerequisites:** None.

**ThothCTL Commands:**
```bash
thothctl check environment
thothctl check project iac
thothctl document iac
```

**MCP Tools:**
- `thothctl_check_environment`
- `thothctl_check_project`
- `thothctl_document_iac`

**Pass Criteria:** Environment has required tools, project structure matches standards.

**Skip Condition:** Never skips.

---

### 🔨 Build

**Objective:** Create inventory, track dependencies, check versions.

**Prerequisites:** None (but works best with valid IaC files).

**ThothCTL Commands:**
```bash
thothctl inventory iac --check-versions --check-provider-versions
```

**MCP Tools:**
- `thothctl_inventory_iac` (check_versions: true)

**Pass Criteria:** Inventory generated. Warnings if outdated modules found.

**Skip Condition:** Never skips (may produce empty inventory for non-IaC dirs).

---

### ✅ Test

**Objective:** Validate Terraform plan for correctness and expected changes.

**Prerequisites:** `tfplan.json` files must exist.

**ThothCTL Commands:**
```bash
thothctl check iac -type tfplan --recursive
```

**MCP Tools:**
- `thothctl_check_iac` (check_type: tfplan)

**Pass Criteria:** Plan contains expected changes, no unexpected destroys.

**Skip Condition:** No `tfplan.json` found in project tree.

---

### 🔒 Secure

**Objective:** Run multi-tool security scanning and policy compliance.

**Prerequisites:** None.

**ThothCTL Commands:**
```bash
thothctl scan iac -t checkov -t trivy -t opa
thothctl scan iac -t checkov -t trivy -t opa --enforcement hard  # deploy phase
```

**MCP Tools:**
- `thothctl_scan_iac` (tools: ["checkov", "trivy", "opa"], enforcement: "soft"|"hard")

**Pass Criteria:** Zero CRITICAL/HIGH findings (soft mode warns, hard mode blocks).

**Skip Condition:** Never skips.

**Gate:** If `--enforcement hard` and findings > 0 → exit 1.

---

### 🚀 Deploy

**Objective:** Final security gate before deployment approval.

**Prerequisites:** None (runs scan internally).

**ThothCTL Commands:**
```bash
thothctl scan iac -t checkov -t trivy -t opa --enforcement hard
```

**MCP Tools:**
- `thothctl_scan_iac` (tools: ["checkov", "trivy", "opa"], enforcement: "hard")

**Pass Criteria:** Zero violations across all tools.

**Gate:** Always enforces hard — blocks pipeline on any violation.

---

### 📊 Monitor

**Objective:** Detect infrastructure drift between IaC and live resources.

**Prerequisites:** Cloud credentials (AWS) configured.

**ThothCTL Commands:**
```bash
thothctl check iac -type drift --tftool tofu --recursive
```

**MCP Tools:**
- `thothctl_drift_detection` (tftool: "tofu", recursive: true)

**Pass Criteria:** No drift detected.

**Skip Condition:** Cloud credentials unavailable or timeout (300s).
