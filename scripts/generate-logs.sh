#!/bin/bash

###############################################################################
# Log Generation Script
# Generates various types of logs for testing the logging infrastructure
###############################################################################

LOG_DIR="/var/log/generated"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE=$(date '+%d/%b/%Y:%H:%M:%S %z')

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to generate random IP
random_ip() {
    echo "$((RANDOM % 256)).$((RANDOM % 256)).$((RANDOM % 256)).$((RANDOM % 256))"
}

# Function to generate random user agent
random_user_agent() {
    agents=(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
        "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)"
    )
    echo "${agents[$RANDOM % ${#agents[@]}]}"
}

# Function to generate random URL
random_url() {
    urls=(
        "/api/users"
        "/api/products"
        "/api/orders"
        "/dashboard"
        "/login"
        "/admin"
        "/health"
        "/metrics"
    )
    echo "${urls[$RANDOM % ${#urls[@]}]}"
}

# Function to generate Apache-style access log
generate_apache_logs() {
    local ip=$(random_ip)
    local url=$(random_url)
    local status=$((RANDOM % 2 == 0 ? 200 : (RANDOM % 2 == 0 ? 404 : 500)))
    local size=$((RANDOM % 10000 + 100))
    local user_agent=$(random_user_agent)
    
    echo "$ip - - [$DATE] \"GET $url HTTP/1.1\" $status $size \"-\" \"$user_agent\"" | logger -t apache -p local0.info
}

# Function to generate authentication logs
generate_auth_logs() {
    local users=("admin" "user1" "user2" "dbadmin" "developer")
    local user="${users[$RANDOM % ${#users[@]}]}"
    local ip=$(random_ip)
    
    if [ $((RANDOM % 5)) -eq 0 ]; then
        # Failed login
        echo "Failed password for $user from $ip port $((RANDOM % 60000 + 1024)) ssh2" | logger -t sshd -p auth.warning
    else
        # Successful login
        echo "Accepted password for $user from $ip port $((RANDOM % 60000 + 1024)) ssh2" | logger -t sshd -p auth.info
    fi
}

# Function to generate application logs
generate_application_logs() {
    local levels=("INFO" "WARN" "ERROR" "DEBUG")
    local level="${levels[$RANDOM % ${#levels[@]}]}"
    local messages=(
        "Database connection pool size: $((RANDOM % 100))"
        "Processing transaction ID: TXN-$RANDOM"
        "Cache hit ratio: $((RANDOM % 100))%"
        "API response time: $((RANDOM % 1000))ms"
        "User session created: SESSION-$RANDOM"
        "Background job completed successfully"
        "Configuration reloaded"
    )
    local message="${messages[$RANDOM % ${#messages[@]}]}"
    
    if [ "$level" == "ERROR" ]; then
        message="Failed to process request: Connection timeout"
    fi
    
    echo "[$level] $message" | logger -t application -p local1.info
}

# Function to generate system logs
generate_system_logs() {
    local services=("nginx" "mysql" "redis" "mongodb")
    local service="${services[$RANDOM % ${#services[@]}]}"
    local messages=(
        "$service: Service started successfully"
        "$service: Health check passed"
        "$service: Configuration validated"
        "$service: Connection pool initialized"
    )
    local message="${messages[$RANDOM % ${#messages[@]}]}"
    
    echo "$message" | logger -t "$service" -p daemon.info
}

# Function to generate security logs
generate_security_logs() {
    local events=(
        "Firewall: Blocked connection attempt from $(random_ip)"
        "Security: Suspicious activity detected from $(random_ip)"
        "IDS: Port scan detected from $(random_ip)"
        "Security: File integrity check passed"
        "Security: SSL certificate verified"
    )
    local event="${events[$RANDOM % ${#events[@]}]}"
    
    echo "$event" | logger -t security -p local2.warning
}

# Main execution
echo "Generating logs at $TIMESTAMP"

# Generate different types of logs
for i in {1..5}; do
    generate_apache_logs
done

for i in {1..3}; do
    generate_auth_logs
done

for i in {1..4}; do
    generate_application_logs
done

for i in {1..2}; do
    generate_system_logs
done

for i in {1..2}; do
    generate_security_logs
done

echo "Log generation complete. Generated logs sent to syslog."
