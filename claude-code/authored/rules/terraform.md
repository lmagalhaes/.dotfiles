---
paths:
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/*.tfvars.example"
---

# Terraform Standards

## Structure
- Modular design — reusable modules in modules/; environments in envs/ or environments/
- Remote state: S3 backend with DynamoDB locking
- Encrypt state files; never commit .terraform/ or *.tfstate locally

## Naming
- Resources: <provider>_<resource>_<purpose> (e.g., aws_s3_bucket_uploads)
- Variables: snake_case, descriptive
- Outputs: expose only what downstream modules need

## Best Practices
- Immutable infrastructure — replace, don't patch in place
- `terraform plan` before every apply; review output carefully
- Pin provider versions in required_providers
- Use data sources over hardcoded ARNs/IDs
- Tag all resources: environment, project, owner, managed-by=terraform

## Security
- IAM: least privilege; roles over access keys
- Secrets: AWS Secrets Manager or Parameter Store — never in tfvars
- Security groups: minimal ingress; explicit egress rules
- Enable CloudTrail, VPC flow logs for production environments

## Before Applying
1. `terraform fmt -recursive` — format
2. `terraform validate` — syntax check
3. `terraform plan` — review changes
4. For production: require peer review of plan output
