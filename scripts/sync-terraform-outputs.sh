#!/bin/bash
# Script to automatically update Ansible inventory with Terraform outputs

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "=========================================="
echo "Terraform → Ansible Output Sync"
echo "=========================================="

# Get AWS collector IP from Terraform
echo -e "\n${YELLOW}📡 Fetching AWS Collector IP from Terraform...${NC}"
cd "$PROJECT_ROOT/terraform/aws"
AWS_COLLECTOR_IP=$(terraform output -raw collector_public_ip 2>/dev/null)

if [ -z "$AWS_COLLECTOR_IP" ]; then
    echo -e "${RED}❌ Error: Could not fetch AWS collector IP from Terraform${NC}"
    echo "Please ensure Terraform has been applied successfully."
    exit 1
fi

echo -e "${GREEN}✅ AWS Collector IP: $AWS_COLLECTOR_IP${NC}"

# Update Ansible inventory
echo -e "\n${YELLOW}📝 Updating Ansible inventory...${NC}"
cd "$PROJECT_ROOT/ansible/inventory"

# Backup current hosts.yml
cp hosts.yml hosts.yml.backup

# Update aws-collector IP
sed -i.tmp "s/ansible_host: .*/ansible_host: $AWS_COLLECTOR_IP/" hosts.yml && rm hosts.yml.tmp

echo -e "${GREEN}✅ Updated ansible/inventory/hosts.yml${NC}"

# Update generator group_vars with AWS collector IP
echo -e "\n${YELLOW}📝 Updating generator group_vars...${NC}"
cd "$PROJECT_ROOT/ansible/inventory/group_vars"

# Backup current generator.yml
cp generator.yml generator.yml.backup

# Update rsyslog_server_ip
sed -i.tmp "s/rsyslog_server_ip: .*/rsyslog_server_ip: \"$AWS_COLLECTOR_IP\"/" generator.yml && rm generator.yml.tmp

echo -e "${GREEN}✅ Updated ansible/inventory/group_vars/generator.yml${NC}"

# Get Azure generator IP if available
echo -e "\n${YELLOW}📡 Checking for Azure Generator IP...${NC}"
cd "$PROJECT_ROOT/terraform/azure"

AZURE_GENERATOR_IP=$(terraform output -raw generator_public_ip 2>/dev/null) || true

if [ -n "$AZURE_GENERATOR_IP" ]; then
    echo -e "${GREEN}✅ Azure Generator IP: $AZURE_GENERATOR_IP${NC}"
    
    # Update Ansible inventory with Azure IP
    cd "$PROJECT_ROOT/ansible/inventory"
    sed -i.tmp "s/ansible_host: AZURE_PUBLIC_IP.*/ansible_host: $AZURE_GENERATOR_IP/" hosts.yml && rm hosts.yml.tmp
    
    echo -e "${GREEN}✅ Updated Azure generator IP in inventory${NC}"
else
    echo -e "${YELLOW}⚠️  Azure not deployed yet - skipping${NC}"
fi

# Display summary
echo -e "\n=========================================="
echo -e "${GREEN}✅ Sync Complete!${NC}"
echo "=========================================="
echo ""
echo "📋 Summary:"
echo "  AWS Collector IP: $AWS_COLLECTOR_IP"
[ -n "$AZURE_GENERATOR_IP" ] && echo "  Azure Generator IP: $AZURE_GENERATOR_IP"
echo ""
echo "📂 Updated files:"
echo "  - ansible/inventory/hosts.yml"
echo "  - ansible/inventory/group_vars/generator.yml"
echo ""
echo "💾 Backups created:"
echo "  - ansible/inventory/hosts.yml.backup"
echo "  - ansible/inventory/group_vars/generator.yml.backup"
echo ""
echo "🚀 Ready to run Ansible playbooks!"
echo ""
