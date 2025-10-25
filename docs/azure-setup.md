# Azure Deployment Notes

Quick checklist for provisioning the generator VM.

## Prereqs
- Azure CLI logged in (`az login`) and subscription selected (`az account show`).
- Terraform ≥ 1.5 installed.
- Service principal creds ready if you’re using Terraform Cloud workspaces.
- SSH key pair available (`ssh-keygen` if you need a fresh one).

## Terraform Steps
- Using Terraform Cloud: set the workspace variables listed in `docs/terraform-cloud-setup.md`.
- Running locally: copy the example vars and edit them.

  ```bash
  cd terraform/azure
  cp terraform.tfvars.example terraform.tfvars   # optional if using workspace vars
  terraform init
  terraform plan
  terraform apply
  ```

Remember to fill in `aws_collector_ip` (from the AWS apply) before running the Azure plan.

## Outputs Worth Saving
```bash
terraform output -raw generator_public_ip
terraform output -json > azure-outputs.json
```

## What Terraform Creates
- Resource group in your chosen region.
- Virtual network `10.1.0.0/16`, subnet `10.1.1.0/24`.
- Static Public IP and NIC with NSG allowing SSH from your CIDR and outbound TLS 6514 to the collector.
- Ubuntu 22.04 VM (`Standard_B1ms` by default) with Premium SSD OS disk.

## After Apply
- SSH test: `ssh -i <key> azureuser@$(terraform output -raw generator_public_ip)`.
- Run `scripts/sync-terraform-outputs.sh` so Ansible picks up the fresh IP and TLS CA.

Ansible takes it from there—installing rsyslog, copying the CA, and enabling the log generator timer.***
