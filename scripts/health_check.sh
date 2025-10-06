#!/bin/bash
HEALTH_LOG="/opt/thanks/logs/health_check.log"

check_service() {
    local service=$1
    if ! systemctl is-active --quiet "$service"; then
        echo "$(date): ALERT - $service is down!" >> "$HEALTH_LOG"
        systemctl restart "$service"
        sleep 5
        if systemctl is-active --quiet "$service"; then
            echo "$(date): SUCCESS - $service restarted" >> "$HEALTH_LOG"
        else
            echo "$(date): CRITICAL - Failed to restart $service" >> "$HEALTH_LOG"
        fi
    fi
}

check_service "nginx"
check_service "postgresql"
check_service "redis-server"
check_service "thanks-backend"

if ! curl -s http://localhost:8000/health > /dev/null; then
    echo "$(date): ALERT - API not responding!" >> "$HEALTH_LOG"
    systemctl restart thanks-backend
fi

USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$USAGE" -gt 80 ]; then
    echo "$(date): WARNING - Disk usage at ${USAGE}%" >> "$HEALTH_LOG"
fi

echo "$(date): Health check completed" >> "$HEALTH_LOG"
