#!/bin/bash
BACKUP_DIR="/opt/thanks/backups/database"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_NAME="thanks_db"
KEEP_DAYS=30

sudo -u postgres pg_dump "$DB_NAME" | gzip > "$BACKUP_DIR/thanks_db_$TIMESTAMP.sql.gz"
find "$BACKUP_DIR" -name "thanks_db_*.sql.gz" -mtime +$KEEP_DAYS -delete

echo "$(date): Backup completed - thanks_db_$TIMESTAMP.sql.gz" >> /opt/thanks/logs/backup.log
