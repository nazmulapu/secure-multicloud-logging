# AWS Deployment Notes

Quick checklist for bringing up the collector stack.

## Prereqs
- AWS CLI configured (`aws sts get-caller-identity` should return your account).
- Terraform ≥ 1.5 installed.
- SSH key pair available (import with `aws ec2 import-key-pair` if needed).

## Terraform Steps
- Using Terraform Cloud: set the same values as workspace variables (see `docs/terraform-cloud-setup.md`) and run the commands below without a local `terraform.tfvars`.
- Running locally: copy the example file and edit it.

  ```bash
  cd terraform/aws
  cp terraform.tfvars.example terraform.tfvars   # optional if using workspace vars
  terraform init
  terraform plan
  terraform apply
  ```

Useful outputs afterwards:
```bash
terraform output -raw collector_public_ip      # Elastic IP
terraform output -json > aws-outputs.json      # full set for reference
```

## What Terraform Creates
- VPC `10.0.0.0/16` with a public subnet `10.0.1.0/24`, Internet Gateway, and route table.
- Security group allowing:
  - SSH 22 and Kibana 5601 from your `allowed_*_cidr`
  - TLS syslog 6514 (adjust to Azure public IP if you prefer)
  - All outbound traffic
- EC2 instance `m7i-flex.large` (Ubuntu 22.04) with 50 GB encrypted gp3 root volume.
- Elastic IP attached to the instance.

## After Apply
- SSH test: `ssh -i <key> ubuntu@$(terraform output -raw collector_public_ip)`.
- Run the Terraform output sync script (`scripts/sync-terraform-outputs.sh`) before launching Ansible.

That’s it—everything else (Docker ELK, rsyslog server, certs) is handled by the Ansible playbook.***
