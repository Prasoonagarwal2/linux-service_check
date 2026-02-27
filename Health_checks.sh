#!/bin/bash
 
# Paths
SERVER_FILE="/home/a1qc054117/server_list.txt"
TIMESTAMP=$(date +%F_%H-%M-%S)
CSV_OUTPUT_FILE="/home/a1qc054117/linux_health_check_final_$TIMESTAMP.csv"
 
# SSH & timeout settings
SSH_USER="ssh_username_here"
SSH_PASS="user_password_here"
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"
SSH_TIMEOUT=60  # total allowed time in seconds
 
# Initialize CSV
echo "hostname,uptime,icinga2,falcon_sensor,sshd,sssd,centrifydc" > "$CSV_OUTPUT_FILE"
 
# Count total servers
total=$(grep -v -E '^#|^$' "$SERVER_FILE" | wc -l)
count=0
 
# Start checking servers
while IFS= read -r SERVER; do
    [[ -z "$SERVER" || "$SERVER" =~ ^# ]] && continue
 
    ((count++))
    echo "[...] Checking $SERVER ($count/$total)"
 
    # Use timeout + sshpass to connect with password and run health checks
    OUTPUT=$(timeout $SSH_TIMEOUT sshpass -p "$SSH_PASS" ssh $SSH_OPTS "$SSH_USER@$SERVER" bash << 'EOF'
hostname=$(hostname)
uptime=$(uptime)
 
# Function to check service status
check_service() {
    local svc="$1"
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo "OK"
    elif service "$svc" status >/dev/null 2>&1; then
        service "$svc" status 2>/dev/null | grep -qi "running" && echo "OK" || echo "NOT_RUNNING"
    else
        echo "UNKNOWN"
    fi
}
 
# Check all services
icinga2=$(check_service icinga2)
falcon_sensor=$(check_service falcon-sensor)
sshd=$(check_service sshd)
sssd=$(check_service sssd)
centrifydc=$(check_service centrifydc)
 
# Escape double quotes in uptime
uptime_clean=$(echo "$uptime" | sed 's/"/""/g')
 
# Output CSV row
echo "$hostname,\"$uptime_clean\",$icinga2,$falcon_sensor,$sshd,$sssd,$centrifydc"
EOF
)
 
    # If SSH/timeout failed or gave empty result
    if [[ $? -ne 0 || -z "$OUTPUT" ]]; then
        echo "$SERVER,\"Unable to connect\",N/A,N/A,N/A,N/A,N/A" >> "$CSV_OUTPUT_FILE"
        echo "[✖] Unable to connect to $SERVER ($count/$total)"
    else
        echo "$OUTPUT" >> "$CSV_OUTPUT_FILE"
        echo "[✔] Completed checks for $SERVER ($count/$total)"
    fi
 
done < "$SERVER_FILE"
 
echo -e "\n✅ All checks complete. Final CSV saved to: $CSV_OUTPUT_FILE"
