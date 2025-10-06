#!/bin/bash
set -e
echo "🔄 Обновление Stage 6+7..."
systemctl stop thanks-backend
cd /opt/thanks/backend
source venv/bin/activate
pip install -r requirements.txt --upgrade
systemctl start thanks-backend
cd /opt/thanks/frontend
pnpm install
pnpm run build
systemctl reload nginx
echo "✅ Stage 6+7 обновлены!"
