#!/bin/bash
LOGS_DIR="/opt/thanks/logs"
BACKUP_DIR="/opt/thanks/backups/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
KEEP_DAYS=14

mkdir -p "$BACKUP_DIR"

for log_file in "$LOGS_DIR"/*.log; do
    if [ -f "$log_file" ]; then
        filename=$(basename "$log_file")
        gzip -c "$log_file" > "$BACKUP_DIR/${filename}_${TIMESTAMP}.gz"
        truncate -s 0 "$log_file"
    fi
done

find "$BACKUP_DIR" -name "*.gz" -mtime +$KEEP_DAYS -delete
echo "$(date): Logs cleaned and archived" >> /opt/thanks/logs/maintenance.log
