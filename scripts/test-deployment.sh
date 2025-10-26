#!/bin/bash

###############################################################################
# Testing and Validation Script
# Run this script on your local machine to validate the deployment
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration (update these after deployment)
AWS_COLLECTOR_IP="${1:-YOUR_AWS_ELASTIC_IP}"
AZURE_GENERATOR_IP="${2:-YOUR_AZURE_PUBLIC_IP}"
SSH_KEY_AWS="${3:-~/.ssh/your-aws-key.pem}"
SSH_KEY_AZURE="${4:-~/.ssh/id_rsa}"

print_header() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Check if IPs are provided
if [ "$AWS_COLLECTOR_IP" == "YOUR_AWS_ELASTIC_IP" ] || [ "$AZURE_GENERATOR_IP" == "YOUR_AZURE_PUBLIC_IP" ]; then
    echo "Usage: $0 <AWS_COLLECTOR_IP> <AZURE_GENERATOR_IP> [AWS_SSH_KEY] [AZURE_SSH_KEY]"
    echo "Example: $0 54.123.45.67 20.98.76.54"
    exit 1
fi

print_header "Testing Secure Multi-Cloud Logging Infrastructure"

# Test 1: AWS Collector SSH Connectivity
print_header "Test 1: AWS Collector SSH Connectivity"
if ssh -i "$SSH_KEY_AWS" -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@"$AWS_COLLECTOR_IP" "echo 'SSH OK'" &>/dev/null; then
    print_success "AWS collector is accessible via SSH"
else
    print_error "Cannot connect to AWS collector via SSH"
    exit 1
fi

# Test 2: Docker Containers Status
print_header "Test 2: Docker Containers Status"
DOCKER_RUNNING=$(ssh -i "$SSH_KEY_AWS" ubuntu@"$AWS_COLLECTOR_IP" "docker ps --filter name=elasticsearch --filter name=kibana --filter name=logstash --format '{{.Names}}' | wc -l")
if [ "$DOCKER_RUNNING" -ge 3 ]; then
    print_success "All ELK containers are running ($DOCKER_RUNNING/3)"
else
    print_error "Not all ELK containers are running ($DOCKER_RUNNING/3)"
fi

# Test 3: Elasticsearch Status
print_header "Test 3: Elasticsearch Status"
ES_STATUS=$(ssh -i "$SSH_KEY_AWS" ubuntu@"$AWS_COLLECTOR_IP" "curl -s -o /dev/null -w '%{http_code}' http://localhost:9200/_cluster/health")
if [ "$ES_STATUS" == "200" ]; then
    print_success "Elasticsearch is running and responsive"
    ES_HEALTH=$(ssh -i "$SSH_KEY_AWS" ubuntu@"$AWS_COLLECTOR_IP" "curl -s http://localhost:9200/_cluster/health | grep -o '\"status\":\"[^\"]*\"' | cut -d'\"' -f4")
    print_info "Cluster health: $ES_HEALTH"
else
    print_error "Elasticsearch is not responding (HTTP $ES_STATUS)"
fi

# Test 4: Kibana Status
print_header "Test 4: Kibana Status"
KIBANA_STATUS=$(curl -s -o /dev/null -w '%{http_code}' "http://$AWS_COLLECTOR_IP:5601/api/status")
if [ "$KIBANA_STATUS" == "200" ]; then
    print_success "Kibana is accessible from external network"
    print_info "Access Kibana at: http://$AWS_COLLECTOR_IP:5601"
else
    print_error "Kibana is not accessible (HTTP $KIBANA_STATUS)"
fi

# Test 4: Rsyslog TLS Port
print_header "Test 4: Rsyslog TLS Port (6514)"
if nc -zv -w 5 "$AWS_COLLECTOR_IP" 6514 2>&1 | grep -q "succeeded"; then
    print_success "Rsyslog TLS port 6514 is open and listening"
else
    print_error "Rsyslog TLS port 6514 is not accessible"
fi

# Test 5: Azure Generator SSH Connectivity
print_header "Test 5: Azure Generator SSH Connectivity"
if ssh -i "$SSH_KEY_AZURE" -o ConnectTimeout=10 -o StrictHostKeyChecking=no azureuser@"$AZURE_GENERATOR_IP" "echo 'SSH OK'" &>/dev/null; then
    print_success "Azure generator is accessible via SSH"
else
    print_error "Cannot connect to Azure generator via SSH"
    exit 1
fi

# Test 6: Rsyslog Client Configuration
print_header "Test 6: Rsyslog Client Configuration on Azure"
if ssh -i "$SSH_KEY_AZURE" azureuser@"$AZURE_GENERATOR_IP" "sudo grep -q '$AWS_COLLECTOR_IP' /etc/rsyslog.d/10-tls-client.conf" 2>/dev/null; then
    print_success "Rsyslog client is configured to forward to AWS collector"
else
    print_error "Rsyslog client configuration not found"
fi

# Test 7: Log Generation Service
print_header "Test 7: Log Generation Service on Azure"
LOG_GEN_STATUS=$(ssh -i "$SSH_KEY_AZURE" azureuser@"$AZURE_GENERATOR_IP" "systemctl is-active log-generator.timer" 2>/dev/null || echo "inactive")
if [ "$LOG_GEN_STATUS" == "active" ]; then
    print_success "Log generator timer is active"
else
    print_error "Log generator timer is not active"
fi

# Test 8: Remote Logs on Collector
print_header "Test 8: Remote Logs Received on Collector"
sleep 5
REMOTE_LOGS=$(ssh -i "$SSH_KEY_AWS" ubuntu@"$AWS_COLLECTOR_IP" "sudo find /var/log/remote -type f -name '*.log' 2>/dev/null | wc -l")
if [ "$REMOTE_LOGS" -gt 0 ]; then
    print_success "Remote logs are being received ($REMOTE_LOGS log files found)"
    print_info "Recent log entries:"
    ssh -i "$SSH_KEY_AWS" ubuntu@"$AWS_COLLECTOR_IP" "sudo tail -5 /var/log/remote/*/*.log 2>/dev/null | head -10"
else
    print_error "No remote logs found on collector"
fi

# Test 9: Elasticsearch Indices
print_header "Test 9: Elasticsearch Indices"
INDICES=$(ssh -i "$SSH_KEY_AWS" ubuntu@"$AWS_COLLECTOR_IP" "curl -s 'http://localhost:9200/_cat/indices/syslog-*?v' 2>/dev/null")
if [ -n "$INDICES" ]; then
    print_success "Syslog indices created in Elasticsearch"
    echo "$INDICES"
else
    print_error "No syslog indices found in Elasticsearch"
fi

# Test 10: TLS Certificate Verification
print_header "Test 10: TLS Certificate Verification"
if ssh -i "$SSH_KEY_AWS" ubuntu@"$AWS_COLLECTOR_IP" "sudo test -f /etc/rsyslog.d/tls/ca-cert.pem" 2>/dev/null; then
    print_success "TLS certificates are present on collector"
    CERT_EXPIRY=$(ssh -i "$SSH_KEY_AWS" ubuntu@"$AWS_COLLECTOR_IP" "sudo openssl x509 -in /etc/rsyslog.d/tls/server-cert.pem -noout -enddate | cut -d= -f2")
    print_info "Server certificate expires: $CERT_EXPIRY"
else
    print_error "TLS certificates not found on collector"
fi

# Summary
print_header "Test Summary"
echo "Testing completed. Please review the results above."
echo ""
echo "Useful commands:"
echo "  - View Kibana: http://$AWS_COLLECTOR_IP:5601"
echo "  - Check logs: ssh -i $SSH_KEY_AWS ubuntu@$AWS_COLLECTOR_IP 'sudo tail -f /var/log/remote/*/*.log'"
echo "  - Check ES: ssh -i $SSH_KEY_AWS ubuntu@$AWS_COLLECTOR_IP 'curl localhost:9200/_cat/indices'"
echo ""
