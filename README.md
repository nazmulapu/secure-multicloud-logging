# Secure Multi-Cloud Logging

Short, reproducible demo of a centralized logging pipeline that ships logs from Azure into an ELK stack running on AWS. Terraform builds the cloud plumbing, Ansible configures the hosts, and a couple of helper scripts keep inventory and tests in sync.

## Architecture in Brief
- **AWS collector**: Ubuntu EC2 instance with Docker-based Elasticsearch, Logstash, Kibana, and a TLS-enabled rsyslog server.
- **Azure generator**: Ubuntu VM that forwards logs over TLS (6514) and runs a simple log generator.
- **Secure transport**: Only TLS-encrypted syslog traffic traverses clouds; SSH/Kibana access is locked down to caller-controlled CIDRs.

## Repository Layout
- `terraform/aws`, `terraform/azure` – IaC for the collector and generator.
- `ansible/` – Playbooks and roles for Docker ELK, rsyslog, and common host setup.
- `scripts/` – Convenience helpers (one-shot deploy, inventory sync, smoke tests, cleanup).
- `docs/` – Optional deep dives if you want more context.

## Requirements
- Terraform ≥ 1.5, Ansible ≥ 2.14
- AWS CLI + credentials with EC2/VPC access
- Azure CLI + subscription with VM/VNet access
- An SSH key pair you can upload to both clouds

## Quick Start
1. Clone the repo and review `terraform.tfvars.example` in both `terraform/aws` and `terraform/azure`.
2. Store the real variable values in Terraform Cloud workspaces (`secure-multicloud-logging`, `azure-log-generator`) or local `terraform.tfvars`.
3. Run `bash scripts/deploy-all.sh` to provision AWS + Azure and configure both hosts.
4. Visit `http://<collector-ip>:5601`, create the `syslog-*` index pattern, and watch logs arrive.

Need to rerun Ansible later? Use `scripts/sync-terraform-outputs.sh` after any Terraform apply to refresh inventory, then call the playbooks directly.

## Cleanup
Destroy each stack when you finish:
```bash
(cd terraform/azure && terraform destroy)
(cd terraform/aws && terraform destroy)
```

## More Detail
- Deployment checklists: `docs/aws-setup.md`, `docs/azure-setup.md`
- Architecture notes: `docs/architecture.md`
- Troubleshooting tips: `docs/troubleshooting.md`
