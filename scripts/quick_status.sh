#!/bin/bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚡ THANKS PROJECT - QUICK STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$(date '+%Y-%m-%d %H:%M:%S')"
echo ""

echo "🔧 SERVICES:"
for service in nginx postgresql redis-server thanks-backend; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "   ✅ $service"
    else
        echo "   ❌ $service"
    fi
done
echo ""

echo "🌐 API:"
if curl -s http://localhost:8000/health | grep -q "healthy"; then
    echo "   ✅ /health endpoint working"
else
    echo "   ❌ API not responding"
fi
echo ""

echo "💾 DATABASE:"
DB_SIZE=$(sudo -u postgres psql -d thanks_db -t -c "SELECT pg_size_pretty(pg_database_size('thanks_db'));" 2>/dev/null | xargs)
echo "   Size: $DB_SIZE"
echo ""

echo "💾 BACKUPS:"
BACKUP_COUNT=$(ls -1 /opt/thanks/backups/database/*.sql.gz 2>/dev/null | wc -l)
echo "   Total: $BACKUP_COUNT"
echo ""

echo "📁 DISK:"
df -h / | tail -1 | awk '{printf "   Usage: %s / %s (%s)\n", $3, $2, $5}'
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
