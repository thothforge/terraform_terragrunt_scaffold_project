# Remediation Patterns

## Checkov — AWS Best Practices

### Encryption

| Check | Resource | Fix |
|-------|----------|-----|
| CKV_AWS_145 | `aws_s3_bucket` | Add `server_side_encryption_configuration { rule { apply_server_side_encryption_by_default { sse_algorithm = "aws:kms" } } }` |
| CKV_AWS_130 | `aws_rds_cluster` | Set `storage_encrypted = true` and `kms_key_id = aws_kms_key.rds.arn` |
| CKV_AWS_17 | `aws_rds_instance` | Set `storage_encrypted = true` |
| CKV_AWS_3 | `aws_ebs_volume` | Set `encrypted = true` |
| CKV_AWS_174 | `aws_sqs_queue` | Set `kms_master_key_id = aws_kms_key.sqs.arn` |

### Public Access

| Check | Resource | Fix |
|-------|----------|-----|
| CKV_AWS_19 | `aws_s3_bucket` | Add `aws_s3_bucket_public_access_block` with all 4 settings `= true` |
| CKV_AWS_20 | `aws_s3_bucket` | Remove `acl = "public-read"`, set `acl = "private"` |
| CKV_AWS_57 | `aws_s3_bucket` | Disable static website hosting or add CloudFront |
| CKV_AWS_23 | `aws_security_group` | Remove `cidr_blocks = ["0.0.0.0/0"]`, use specific CIDRs |
| CKV_AWS_260 | `aws_security_group_rule` | Remove ingress rule allowing 0.0.0.0/0 on all ports |

### Logging & Monitoring

| Check | Resource | Fix |
|-------|----------|-----|
| CKV_AWS_18 | `aws_s3_bucket` | Add `aws_s3_bucket_logging { target_bucket = aws_s3_bucket.logs.id }` |
| CKV_AWS_126 | `aws_eks_cluster` | Set `enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]` |
| CKV_AWS_84 | `aws_cloudwatch_log_group` | Set `retention_in_days = 365` and `kms_key_id` |
| CKV2_AWS_38 | `aws_cloudtrail` | Ensure CloudTrail is enabled in all regions |

### IAM

| Check | Resource | Fix |
|-------|----------|-----|
| CKV_AWS_1 | `aws_iam_policy` | Replace `"Action": "*"` with specific actions |
| CKV_AWS_49 | `aws_iam_policy` | Replace `"Resource": "*"` with specific ARNs |
| CKV_AWS_61 | `aws_iam_role` | Remove `"Principal": "*"` from trust policy, use specific accounts |
| CKV_AWS_111 | `aws_iam_policy` | Avoid `"Effect": "Allow"` with wildcards on write actions |

### Networking

| Check | Resource | Fix |
|-------|----------|-----|
| CKV_AWS_24 | `aws_security_group` | Specify exact ports: `from_port = 443, to_port = 443` |
| CKV2_AWS_5 | `aws_security_group` | Attach to a resource or delete if unused |
| CKV_AWS_150 | `aws_subnet` | Set `map_public_ip_on_launch = false` for private subnets |
| CKV2_AWS_11 | `aws_vpc` | Enable VPC flow logs |

### Compute

| Check | Resource | Fix |
|-------|----------|-----|
| CKV_AWS_79 | `aws_instance` | Add `metadata_options { http_tokens = "required" }` (IMDSv2) |
| CKV_AWS_135 | `aws_instance` | Set `monitoring = true` (detailed monitoring) |
| CKV_AWS_88 | `aws_instance` | Set `associate_public_ip_address = false` |
| CKV_AWS_341 | `aws_launch_template` | Set `http_tokens = "required"` in metadata_options |

### Database

| Check | Resource | Fix |
|-------|----------|-----|
| CKV_AWS_16 | `aws_rds_instance` | Set `multi_az = true` (production) |
| CKV_AWS_129 | `aws_rds_instance` | Set `backup_retention_period = 7` (minimum) |
| CKV_AWS_118 | `aws_rds_instance` | Set `monitoring_interval = 60` (enhanced monitoring) |
| CKV_AWS_157 | `aws_rds_instance` | Set `publicly_accessible = false` |

---

## OPA / Organization Policies

### Tagging Violations

**Finding:** `aws_instance.web is missing required tags: {Environment, Owner, CostCenter}`

**Fix:**
```hcl
resource "aws_instance" "web" {
  # ... existing config ...

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    CostCenter  = "CC-1234"
    ManagedBy   = "terraform"
  }
}
```

### Naming Convention Violations

**Finding:** `aws_s3_bucket.my_bucket does not follow naming convention '{env}-{service}-{name}'`

**Fix:** Rename resource to follow pattern:
```hcl
resource "aws_s3_bucket" "prd-storage-artifacts" {
  bucket = "prd-storage-artifacts-${data.aws_caller_identity.current.account_id}"
}
```

### Region Restriction Violations

**Finding:** `Region 'ap-southeast-1' is not allowed. Approved: {us-east-1, us-east-2, us-west-2, eu-west-1}`

**Fix:** Change provider region to an approved one:
```hcl
provider "aws" {
  region = "us-east-1"  # Use approved region
}
```

### IAM Wildcard Violations

**Finding:** `aws_iam_policy.admin has wildcard actions`

**Fix:**
```hcl
resource "aws_iam_policy" "app" {
  policy = jsonencode({
    Statement = [{
      Effect   = "Allow"
      Action   = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.app.arn,
        "${aws_s3_bucket.app.arn}/*"
      ]
    }]
  })
}
```

---

## Trivy — Vulnerability Fixes

### Outdated Provider Versions

**Finding:** `Provider hashicorp/aws v4.x has known vulnerabilities`

**Fix:** Upgrade to latest:
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### Misconfigured Resources

Trivy findings typically overlap with Checkov. Apply the same fixes listed above.

---

## Fix Priority Order

When multiple findings exist, fix in this order:

1. **CRITICAL** — IAM wildcards, public S3 buckets, unencrypted secrets
2. **HIGH** — Missing encryption, open security groups, no logging
3. **MEDIUM** — Missing tags, naming violations, monitoring gaps
4. **LOW** — Documentation, optional best practices
