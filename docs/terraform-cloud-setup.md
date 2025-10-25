# Terraform Cloud Notes

I use Terraform Cloud (free tier) purely for remote state and locking, so there’s no need to stand up S3 buckets or DynamoDB tables. Runs still happen locally; the backend just keeps the state safe and shared.

If you prefer to stick with local state you can, but here’s what the Terraform Cloud workspaces expect:

## Workspaces
- `secure-multicloud-logging` → `terraform/aws`
- `azure-log-generator` → `terraform/azure`

## Variables to Configure
| Workspace | Name | Type | Sensitive | Example |
|-----------|------|------|-----------|---------|
| AWS | `aws_region` | Terraform | No | `us-east-1` |
| AWS | `project_name` | Terraform | No | `secure-logging` |
| AWS | `environment` | Terraform | No | `demo` |
| AWS | `instance_type` | Terraform | No | `t3.medium` |
| AWS | `allowed_ssh_cidr` | Terraform (HCL) | No | `["203.0.113.10/32"]` |
| AWS | `allowed_kibana_cidr` | Terraform (HCL) | No | `["203.0.113.10/32"]` |
| AWS | `ssh_public_key` | Terraform | ✔ | contents of your public key |
| AWS | `AWS_ACCESS_KEY_ID` | Environment | ✔ | your key |
| AWS | `AWS_SECRET_ACCESS_KEY` | Environment | ✔ | your secret |
| AWS | `AWS_DEFAULT_REGION` | Environment | No | `us-east-1` |
| Azure | `azure_region` | Terraform | No | `East US` |
| Azure | `project_name` | Terraform | No | `secure-logging` |
| Azure | `environment` | Terraform | No | `demo` |
| Azure | `vm_size` | Terraform | No | `Standard_B1ms` |
| Azure | `admin_username` | Terraform | No | `azureuser` |
| Azure | `ssh_public_key_path` | Terraform | No | `~/.ssh/id_rsa.pub` (or paste key text if running remotely) |
| Azure | `aws_collector_ip` | Terraform | No | set after AWS deploy |
| Azure | `ARM_CLIENT_ID` | Environment | ✔ | service principal appId |
| Azure | `ARM_CLIENT_SECRET` | Environment | ✔ | service principal password |
| Azure | `ARM_SUBSCRIPTION_ID` | Environment | No | your subscription ID |
| Azure | `ARM_TENANT_ID` | Environment | No | tenant ID |

That’s it—the rest mirrors the example `terraform.tfvars` files. Once those values are in place you can run `terraform init/plan/apply` locally and the backend takes care of state storage.***
