# Terraform Cloud Setup Guide

## Why Terraform Cloud?

**Free Tier Benefits:**
- ✅ Remote state storage (no S3/Azure Storage needed)
- ✅ State locking built-in
- ✅ Version control integration
- ✅ Collaborative runs
- ✅ Private registry
- ✅ Up to 500 resources per month (plenty for this project)
- ✅ Secure variable storage

## Setup Steps

### 1. Create Terraform Cloud Account

1. Go to https://app.terraform.io/signup
2. Sign up with your email or GitHub
3. Verify your email

### 2. Create Organization

1. Click "Create Organization"
2. Name: `secure-multicloud-logging` (or your preferred name)
3. Email: Your email address

### 3. Generate API Token

1. Go to https://app.terraform.io/app/settings/tokens
2. Click "Create an API token"
3. Description: "CLI Access"
4. Copy the token (you'll need it soon)

### 4. Run Setup Script

```bash
cd secure-multicloud-logging
chmod +x scripts/setup-terraform-cloud.sh
./scripts/setup-terraform-cloud.sh
```

When prompted:
- Enter your organization name
- Paste your API token when `terraform login` asks

### 5. Configure AWS Credentials in Terraform Cloud

1. Go to https://app.terraform.io/app/YOUR_ORG/workspaces/aws-log-collector
2. Click "Variables"
3. Add Environment Variables:
   - `AWS_ACCESS_KEY_ID` = `<your-key>` ✓ Sensitive
   - `AWS_SECRET_ACCESS_KEY` = `<your-secret>` ✓ Sensitive
   - `AWS_DEFAULT_REGION` = `us-east-1`

### 6. Configure Azure Credentials in Terraform Cloud

First, create a Service Principal:
```bash
az login
az ad sp create-for-rbac \
  --name "terraform-cloud" \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID
```

This outputs:
```json
{
  "appId": "xxxx",
  "displayName": "terraform-cloud",
  "password": "xxxx",
  "tenant": "xxxx"
}
```

Then add to Terraform Cloud workspace `azure-log-generator`:
1. Go to https://app.terraform.io/app/YOUR_ORG/workspaces/azure-log-generator
2. Click "Variables"
3. Add Environment Variables:
   - `ARM_CLIENT_ID` = `<appId>` ✓ Sensitive
   - `ARM_CLIENT_SECRET` = `<password>` ✓ Sensitive
   - `ARM_SUBSCRIPTION_ID` = `<your-subscription-id>`
   - `ARM_TENANT_ID` = `<tenant>`

### 7. Configure Terraform Variables

Create `terraform.tfvars` files:

**AWS (`terraform/aws/terraform.tfvars`):**
```hcl
aws_region          = "us-east-1"
project_name        = "secure-logging"
environment         = "production"
instance_type       = "t3.medium"
key_name            = "your-key-name"
allowed_ssh_cidr    = ["YOUR_IP/32"]
allowed_kibana_cidr = ["YOUR_IP/32"]
```

**Azure (`terraform/azure/terraform.tfvars`):**
```hcl
azure_region         = "East US"
project_name         = "secure-logging"
environment          = "production"
vm_size              = "Standard_B2s"
admin_username       = "azureuser"
ssh_public_key_path  = "~/.ssh/id_rsa.pub"
aws_collector_ip     = "WILL_BE_SET_AFTER_AWS_DEPLOY"
```

### 8. Deploy Infrastructure

**Deploy AWS first:**
```bash
cd terraform/aws
terraform plan
terraform apply
```

**Get AWS Elastic IP:**
```bash
terraform output collector_public_ip
```

**Update Azure variables:**
```bash
# Edit terraform/azure/terraform.tfvars
# Set: aws_collector_ip = "X.X.X.X"
```

**Deploy Azure:**
```bash
cd ../azure
terraform plan
terraform apply
```

## Workspace Configuration

### AWS Workspace Settings
- **Name**: `aws-log-collector`
- **Execution Mode**: Remote
- **Terraform Version**: Latest 1.5.x
- **Working Directory**: `terraform/aws`

### Azure Workspace Settings
- **Name**: `azure-log-generator`
- **Execution Mode**: Remote
- **Terraform Version**: Latest 1.5.x
- **Working Directory**: `terraform/azure`

## Using Terraform Cloud UI

### Run Plan from UI
1. Go to workspace
2. Click "Actions" → "Start new plan"
3. Optional: Add message
4. Review plan output
5. Click "Confirm & Apply" if looks good

### View State
1. Go to workspace
2. Click "States" tab
3. View current state
4. Can rollback to previous versions if needed

### View Runs History
1. Go to workspace
2. Click "Runs" tab
3. See all terraform applies
4. View logs for each run

## Security Best Practices

1. ✅ **Never commit credentials** - Use Terraform Cloud variables
2. ✅ **Mark sensitive variables** - Check "Sensitive" box
3. ✅ **Use RBAC** - Limit workspace access to team members
4. ✅ **Enable 2FA** - On your Terraform Cloud account
5. ✅ **Rotate credentials** - Regularly update cloud credentials

## Cost

**Terraform Cloud Free Tier:**
- Up to 500 resources/month: **$0**
- State storage: **$0**
- Runs: **$0**

This project uses ~15-20 resources, well within the free tier!

## Troubleshooting

### Token Issues
```bash
# Clear cached token
rm ~/.terraform.d/credentials.tfrc.json
# Login again
terraform login
```

### Workspace Not Found
```bash
# Re-initialize
terraform init -reconfigure
```

### Plan Failures
- Check environment variables are set correctly
- Verify cloud credentials are valid
- Check variable values in terraform.tfvars

### State Locking
- Terraform Cloud handles this automatically
- No action needed from you

## Migration from Local State

If you already have local state:
```bash
# Terraform will prompt to migrate
terraform init
# Answer "yes" to copy existing state
```

## Additional Resources

- [Terraform Cloud Docs](https://developer.hashicorp.com/terraform/cloud-docs)
- [Free Tier Details](https://www.hashicorp.com/products/terraform/pricing)
- [Variable Management](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/variables)