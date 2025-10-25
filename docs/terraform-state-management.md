# Multi-Cloud Terraform State Management Guide

This project uses **separate Terraform Cloud workspaces** for AWS and Azure infrastructure, ensuring isolated state management for each cloud provider.

## 📋 Workspace Architecture

```
Terraform Cloud Organization: nazmulapu-labs
│
├── Workspace: secure-multicloud-logging (AWS)
│   ├── Working Directory: terraform/aws
│   ├── State File: AWS infrastructure
│   ├── Variables: AWS-specific (10 Terraform + 3 Environment)
│   └── Resources: VPC, EC2, Security Groups, EIP, SSH Key
│
└── Workspace: azure-log-generator (Azure)
    ├── Working Directory: terraform/azure
    ├── State File: Azure infrastructure
    ├── Variables: Azure-specific (7 Terraform + 4 Environment)
    └── Resources: VNet, VM, NSG, Public IP, SSH Key
```

## 🚀 Setup Instructions

### Step 1: Configure AWS Workspace (Already Created)

**Workspace Name:** `secure-multicloud-logging`

**Settings:**
1. Go to: https://app.terraform.io/app/nazmulapu-labs/workspaces/secure-multicloud-logging/settings/general
2. Set **Terraform Working Directory**: `terraform/aws`
3. Set **Execution Mode**: Remote
4. Save settings

**Variables:** See `terraform/aws/terraform.tfvars.example`
- 10 Terraform variables
- 3 Environment variables (AWS credentials)

### Step 2: Create Azure Workspace

**Option A: Via Terraform Cloud UI**

1. Go to: https://app.terraform.io/app/nazmulapu-labs/workspaces
2. Click **"New workspace"**
3. Select **"Version control workflow"**
4. Choose your repository: `nazmulapu/secure-multicloud-logging`
5. Set **Workspace Name**: `azure-log-generator`
6. Click **"Advanced options"**
7. Set **Terraform Working Directory**: `terraform/azure`
8. Click **"Create workspace"**

**Option B: Via Terraform CLI**

```bash
cd terraform/azure
terraform login
terraform init
```

This will automatically create the workspace on first init.

### Step 3: Configure Azure Workspace

1. Go to: https://app.terraform.io/app/nazmulapu-labs/workspaces/azure-log-generator/variables

2. Add **Terraform Variables** (7 required):
   - `azure_region` = `westeurope`
   - `ssh_public_key` = `<your public key>` (Sensitive ✓)
   - `aws_collector_ip` = `<AWS Elastic IP>` (get after AWS deployment)
   - `project_name` = `secure-logging`
   - `environment` = `production`
   - `vnet_cidr` = `10.1.0.0/16`
   - `subnet_cidr` = `10.1.1.0/24`
   - `vm_size` = `Standard_B2s`

3. Add **Environment Variables** (4 required):
   - `ARM_CLIENT_ID` (Sensitive ✓)
   - `ARM_CLIENT_SECRET` (Sensitive ✓)
   - `ARM_SUBSCRIPTION_ID` (Sensitive ✓)
   - `ARM_TENANT_ID` (Sensitive ✓)

**Get Azure credentials:**
```bash
# Login to Azure
az login

# Get subscription ID
az account show --query id -o tsv

# Create service principal
az ad sp create-for-rbac --name "secure-logging-sp" --role="Contributor"

# Output shows:
# appId       → ARM_CLIENT_ID
# password    → ARM_CLIENT_SECRET
# tenant      → ARM_TENANT_ID
```

## 🔄 Deployment Workflow

### Phase 1: Deploy AWS Infrastructure

```bash
# Option 1: Via Terraform Cloud UI
1. Go to: https://app.terraform.io/app/nazmulapu-labs/workspaces/secure-multicloud-logging
2. Click "Actions" → "Start new run"
3. Review plan (9 resources)
4. Click "Confirm & Apply"

# Option 2: Via CLI (if VCS disconnected)
cd terraform/aws
terraform apply
```

**Get AWS Elastic IP:**
```bash
terraform output collector_public_ip
# Output: 3.123.45.67
```

### Phase 2: Update Azure Configuration

```bash
# Update Azure workspace variable with AWS Elastic IP
# Go to: https://app.terraform.io/app/nazmulapu-labs/workspaces/azure-log-generator/variables
# Update: aws_collector_ip = "3.123.45.67"
```

### Phase 3: Deploy Azure Infrastructure

```bash
# Via Terraform Cloud UI
1. Go to: https://app.terraform.io/app/nazmulapu-labs/workspaces/azure-log-generator
2. Click "Actions" → "Start new run"
3. Review plan (7 resources)
4. Click "Confirm & Apply"
```

## 📊 State Management Benefits

### Isolated States
- ✅ AWS state changes don't affect Azure
- ✅ Azure state changes don't affect AWS
- ✅ Can destroy one cloud without affecting the other
- ✅ Different team members can work on different clouds

### Independent Variables
- ✅ AWS uses AWS-specific credentials
- ✅ Azure uses Azure-specific credentials
- ✅ No credential conflicts
- ✅ Different regions, settings per cloud

### Organized Outputs
```bash
# AWS outputs (from secure-multicloud-logging workspace)
terraform output collector_public_ip
terraform output kibana_url
terraform output ssh_command

# Azure outputs (from azure-log-generator workspace)
terraform output generator_public_ip
terraform output vm_id
```

## 🔍 Verify State Isolation

**Check AWS state:**
```bash
cd terraform/aws
terraform show
# Shows only AWS resources
```

**Check Azure state:**
```bash
cd terraform/azure
terraform show
# Shows only Azure resources
```

## 🛠️ Common Operations

### View AWS Resources
```bash
cd terraform/aws
terraform state list
```

### View Azure Resources
```bash
cd terraform/azure
terraform state list
```

### Destroy AWS (keeps Azure intact)
```bash
cd terraform/aws
terraform destroy
```

### Destroy Azure (keeps AWS intact)
```bash
cd terraform/azure
terraform destroy
```

### Destroy Everything
```bash
# Destroy in reverse order
cd terraform/azure
terraform destroy

cd ../aws
terraform destroy
```

## 📝 Workspace Links

- **AWS Workspace**: https://app.terraform.io/app/nazmulapu-labs/workspaces/secure-multicloud-logging
- **Azure Workspace**: https://app.terraform.io/app/nazmulapu-labs/workspaces/azure-log-generator

## ⚠️ Important Notes

1. **Deploy AWS first**: Azure needs AWS Elastic IP for NSG rules
2. **Separate credentials**: AWS and Azure use different environment variables
3. **Working directories**: Must be set correctly in workspace settings
4. **VCS connection**: If using GitHub integration, set working directory for each workspace
5. **State locking**: Terraform Cloud handles this automatically

## 🎯 Summary

```
┌──────────────────────────────────────────────────────────────┐
│                     AWS Deployment                            │
│  Workspace: secure-multicloud-logging                         │
│  Directory: terraform/aws                                     │
│  State: Manages VPC, EC2, EIP, Security Groups               │
└──────────────────────────────────────────────────────────────┘
                            ↓
                   Get Elastic IP
                            ↓
┌──────────────────────────────────────────────────────────────┐
│                    Azure Deployment                           │
│  Workspace: azure-log-generator                               │
│  Directory: terraform/azure                                   │
│  State: Manages VNet, VM, NSG, Public IP                     │
│  Depends on: AWS Elastic IP (for NSG rule)                   │
└──────────────────────────────────────────────────────────────┘
```

This architecture ensures clean separation of concerns and makes it easy to manage each cloud provider independently! 🎉
