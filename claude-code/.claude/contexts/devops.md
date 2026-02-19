# DevOps & Infrastructure Context

This context is loaded when working on infrastructure, cloud platforms, and DevOps tasks.

---

## Cloud Platforms

### AWS (Primary)
- **Core Services:** EC2, S3, ECS, RDS, Lambda, Elastic Beanstalk, Secrets Manager
- **Preference:** Use boto3 library over CLI wrappers when possible
- **IAM:** Follow principle of least privilege
- **Secrets:** Always use AWS Secrets Manager or Parameter Store

### GCP (Secondary)
- Occasional use for specific projects

---

## Infrastructure as Code

### Terraform
- Primary IaC tool
- State management: S3 backend with DynamoDB locking
- Modular structure preferred
- Document state file locations and backends

### Best Practices
- **Immutable infrastructure** - Replace, don't modify
- **Version control** - All IaC in git
- **State security** - Encrypt state files, use remote backends
- **Plan before apply** - Always review terraform plan

---

## Container & Orchestration

### Docker
- Containerization preferred for consistent environments
- Multi-stage builds for optimization
- Never include secrets in images

### Docker Compose
- Local development and simple deployments
- Document service dependencies clearly

---

## Security in Infrastructure

### Secrets Management
- **Never commit secrets** - Use secret managers
- **AWS Secrets Manager / Parameter Store** - Primary secret storage
- **Environment variables** - For local development only
- **Rotation** - Automate credential rotation where possible

### Network Security
- **Principle of least access** - Minimal security group rules
- **Bastion hosts** - For SSH access to private resources
- **VPC design** - Public/private subnet separation

### IAM & Access
- **Least privilege** - Minimal permissions required
- **Role-based access** - Use IAM roles over access keys
- **MFA** - Enforce for production access
- **Audit** - CloudTrail logging enabled

---

## Monitoring & Observability

### Logging
- Centralized logging (CloudWatch, ELK, etc.)
- Structured logs (JSON format)
- Log retention policies
- Never log secrets or PII

### Metrics & Alerting
- Resource utilization monitoring
- Application health checks
- Alert on anomalies, not noise
- Clear escalation paths

---

## Deployment Strategies

### Best Practices
- **Blue/green deployments** - Zero-downtime releases
- **Rolling updates** - Gradual rollout
- **Rollback plan** - Always have a rollback strategy
- **Health checks** - Automated health verification

### CI/CD
- Automated testing before deployment
- Infrastructure testing (terraform validate, plan)
- Deployment approval gates for production

---

## Quick Reference

### Do:
✅ Use IaC for all infrastructure
✅ Store secrets in secret managers
✅ Follow least privilege principle
✅ Document infrastructure decisions
✅ Automate deployments
✅ Plan terraform changes before applying
✅ Use remote state with locking

### Don't:
❌ Commit secrets to version control
❌ Hardcode credentials
❌ Skip terraform plan
❌ Manually modify infrastructure
❌ Use root credentials
❌ Expose unnecessary ports/services
❌ Skip backups

---

**Context Version:** 1.0
**Last Updated:** 2025-11-27