# linux-service_check
Bash script to generate Linux service check report

This script collects:

- hostname
- fqdn
- uptime
- icinga2
- falcon_sensor
- qualys_cloud_agent
- sshd
- sssd
- centrifydc

Output: CSV report generated in the user directory.

OUTPUT_CSV="linux_health_check_final_$TIMESTAMP.csv"
