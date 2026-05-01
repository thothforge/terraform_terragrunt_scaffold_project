# IaC Commit Examples

Real-world examples for Terraform/Terragrunt projects using contextual commits with IaC versioning.

## Foundation Layer

### New VPC stack (MINOR)

```
feat(vpc): add VPC stack with public and private subnets

intent(vpc): isolate workloads across 3 AZs with private subnets for compute
decision(vpc): terraform-aws-modules/vpc v5.0.0 over custom module for community support
rejected(vpc): single-AZ design — does not meet HA requirements
constraint(vpc): CIDR 10.1.0.0/16 allocated by network team, no overlap with on-prem
impact(vpc): all platform and application stacks will depend on this
```

### Fix security group rule (PATCH)

```
fix(vpc): correct egress rule allowing all traffic on port 443

learned(sg): default egress rule must specify protocol, not just port
```

## Platform Layer

### Add EKS cluster (MINOR)

```
feat(eks): add EKS cluster stack with managed node groups

intent(eks): provide Kubernetes platform for microservices deployment
decision(eks): managed node groups over Fargate for GPU workload support
decision(eks): terraform-aws-modules/eks v20.8.0 for official module stability
rejected(eks): self-managed nodes — operational overhead exceeds team capacity
rejected(eks): ECS — team has existing Kubernetes expertise
constraint(eks): cluster version 1.29 required for pod identity feature
constraint(eks): node groups must use private subnets only
impact(eks): application stacks will depend on cluster endpoint and OIDC provider
```

### Update module version (PATCH)

```
chore(eks): bump EKS module from 20.8.0 to 20.8.5

decision(deps): patch update addresses node group scaling bug
```

## Application Layer

### Add ALB stack (MINOR)

```
feat(alb): add application load balancer for public-facing services

intent(alb): expose application services through a single managed entry point
decision(alb): ALB over NLB for HTTP/HTTPS routing and path-based rules
constraint(alb): must use public subnets with WAF association
impact(alb): application services will reference ALB target group ARNs
```

### Fix target group health check (PATCH)

```
fix(alb): correct health check path from / to /healthz

learned(alb): default health check path causes 404 on API containers
```

## Observability Layer

### Add CloudWatch monitoring (MINOR)

```
feat(cloudwatch): add CloudWatch dashboards and alarms for platform services

intent(monitoring): centralized visibility into EKS, RDS, and ALB metrics
decision(cloudwatch): CloudWatch over Datadog for cost and AWS-native integration
rejected(monitoring): Prometheus-only — lacks built-in alerting without AlertManager setup
```

## Cross-Cutting Changes

### Add new environment (MAJOR)

```
feat(infra): add staging environment

intent(environments): staging needed for pre-production validation
decision(environments): stg environment mirrors prd configuration with smaller instance sizes
impact(infra): all stacks now deploy to dev, qa, stg, prd — pipeline update required
```

### Update common tags (PATCH)

```
fix(tags): add missing CostCenter tag to common_tags

constraint(tags): finance team requires CostCenter on all resources by Q2
```

### Modify root.hcl framework (MAJOR)

```
refactor(infra): migrate remote state to use workspace-based key pattern

intent(state): isolate state files per environment to prevent cross-env conflicts
decision(state): workspace prefix in S3 key over separate buckets per environment
rejected(state): separate S3 buckets — increases operational overhead for state management
impact(infra): all stacks require re-init, state migration script provided in docs/
```

### Environment-specific tfvars change (PATCH)

```
fix(vpc): update dev VPC CIDR to avoid overlap with new office network

constraint(network): IT allocated 10.2.0.0/16 for office, conflicts with dev 10.2.0.0/16
```

## Trivial Changes — No Action Lines Needed

```
style(vpc): run terraform fmt on all foundation stacks
```

```
docs(eks): update README with node group scaling instructions
```

```
chore(deps): update pre-commit hooks to latest versions
```

## Tag Annotation Examples

### MAJOR release

```bash
git tag -a v2.0.0 -m "feat(infra): add staging environment and restructure state backend

intent(environments): staging required for pre-production validation pipeline
impact(infra): all stacks require re-init with new state key pattern"
```

### MINOR release

```bash
git tag -a v1.3.0 -m "feat(platform): add RDS PostgreSQL and ElastiCache stacks

intent(data): application team needs managed database and session caching
decision(rds): multi-az PostgreSQL for HA, ElastiCache Redis for session persistence"
```

### PATCH release

```bash
git tag -a v1.3.1 -m "fix(rds): correct parameter group family and backup window

learned(rds): parameter group family must match engine major version exactly"
```
