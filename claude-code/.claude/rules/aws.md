# AWS Standards

## Services in Use
- **Compute:** EC2, ECS, Lambda, Elastic Beanstalk
- **Storage:** S3, RDS
- **Security:** Secrets Manager, Parameter Store, IAM
- Core SDK: `boto3` (Python) — prefer over CLI wrappers in code

## IAM
- Least privilege: grant only what the task requires, nothing broader
- Roles over access keys for EC2/ECS/Lambda workloads
- Never hardcode credentials — use IAM roles, Secrets Manager, or Parameter Store
- Enforce MFA for production console access

## Secrets
- AWS Secrets Manager for application secrets (DB passwords, API keys)
- Parameter Store (SecureString) for config values that need rotation
- Never put secrets in environment variables committed to source — use secret references

## Networking
- Public/private subnet separation — no unnecessary public exposure
- Security groups: minimal ingress, explicit egress; default-deny
- Bastion host or SSM Session Manager for SSH access to private resources
- Enable VPC flow logs for production environments

## Observability
- CloudTrail enabled in all production accounts
- CloudWatch for logs and alarms; structured JSON logs
- Never log PII, passwords, or tokens

## Deployment
- Blue/green or rolling deployments — no direct prod cutover
- Always have a rollback plan before applying infrastructure changes
- Tag all resources: `environment`, `project`, `owner`, `managed-by`
