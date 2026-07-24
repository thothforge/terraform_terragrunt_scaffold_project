# CI/CD Pipeline Templates

## GitHub Actions

### Full DevSecOps Pipeline

```yaml
name: DevSecOps Pipeline

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

env:
  THOTH_ORG_POLICY: ${{ secrets.ORG_POLICY_REPO }}

jobs:
  devsecops:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install ThothCTL
        run: pip install thothctl

      - name: Install Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Generate Plans
        run: |
          terraform init
          terraform plan -out=tfplan.binary
          terraform show -json tfplan.binary > tfplan.json

      - name: DevSecOps Validation
        run: thothctl workflow devsecops --phase pre-deploy --enforcement hard

      - name: Upload Reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: devsecops-reports
          path: Reports/
```

### Security Scan Only (PR Check)

```yaml
name: Security Gate

on: [pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install thothctl
      - name: Security Scan
        run: thothctl workflow devsecops --phase secure --enforcement hard
```

### With SARIF Upload to GitHub Code Scanning

```yaml
name: Security Scan + Code Scanning

on: [push]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install thothctl

      - name: Run Scan
        run: thothctl scan iac -t checkov -t trivy --output sarif

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: Reports/scan_report.sarif
```

---

## Azure Pipelines

### Full Pipeline

```yaml
trigger:
  branches:
    include:
      - main
      - feature/*

pr:
  branches:
    include:
      - main

pool:
  vmImage: ubuntu-latest

variables:
  THOTH_ORG_POLICY: "https://$(POLICY_PAT)@dev.azure.com/$(System.CollectionUri)/$(System.TeamProject)/_git/org-iac-policies@main"

stages:
  - stage: Validate
    displayName: DevSecOps Validation
    jobs:
      - job: devsecops
        displayName: Run DevSecOps Pipeline
        steps:
          - checkout: self
            persistCredentials: true

          - task: UsePythonVersion@0
            inputs:
              versionSpec: "3.12"

          - script: pip install thothctl
            displayName: Install ThothCTL

          - script: |
              terragrunt run-all plan \
                --out-dir infrastructure/tfplan \
                --json-out-dir infrastructure/tfplan
            displayName: Generate Plans
            continueOnError: true

          - script: |
              thothctl workflow devsecops \
                --phase pre-deploy \
                --enforcement hard
            displayName: DevSecOps Gate

          - task: PublishPipelineArtifact@1
            condition: always()
            inputs:
              targetPath: Reports
              artifactName: devsecops-reports
```

### Security Scan with PR Comments

```yaml
trigger: none

pr:
  branches:
    include:
      - main

pool:
  vmImage: ubuntu-latest

steps:
  - checkout: self
  - script: pip install thothctl
    displayName: Install ThothCTL

  - script: |
      thothctl scan iac -t checkov -t trivy -t opa \
        --enforcement soft \
        --post-to-pr \
        --vcs-provider azure_repos \
        --space my-azure-space
    displayName: Security Scan + PR Comment
```

---

## GitLab CI

### Full Pipeline

```yaml
stages:
  - validate
  - plan
  - security
  - deploy

variables:
  THOTH_ORG_POLICY: ${ORG_POLICY_REPO_URL}

.thothctl:
  image: python:3.12
  before_script:
    - pip install thothctl

validate:
  extends: .thothctl
  stage: validate
  script:
    - thothctl workflow devsecops --phase develop
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'

plan:
  extends: .thothctl
  stage: plan
  script:
    - terraform init
    - terraform plan -out=tfplan.binary
    - terraform show -json tfplan.binary > tfplan.json
    - thothctl workflow devsecops --phase plan
  artifacts:
    paths:
      - tfplan.json
      - Reports/
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'

security:
  extends: .thothctl
  stage: security
  script:
    - thothctl workflow devsecops --phase secure --enforcement hard
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'

deploy:
  extends: .thothctl
  stage: deploy
  script:
    - thothctl workflow devsecops --phase deploy --enforcement hard
    - terraform apply tfplan.binary
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
  when: manual
```

---

## Pre-commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: thothctl-secure
        name: ThothCTL Security Scan
        entry: thothctl workflow devsecops --phase secure --enforcement soft
        language: system
        pass_filenames: false
        always_run: true
```

---

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `THOTH_ORG_POLICY` | Organization policy repo URL | `https://github.com/myorg/policies.git@main` |
| `THOTH_POLICY_REPO` | Local path to policy repo | `/opt/policies` |
| `THOTHCTL_DEBUG` | Enable debug logging | `true` |
