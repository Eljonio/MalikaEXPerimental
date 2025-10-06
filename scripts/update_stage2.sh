#!/bin/bash
set -e

echo "🔄 Обновление Stage 2..."

# Backend
cd /opt/thanks/backend
source venv/bin/activate
pip install -r requirements.txt --upgrade
systemctl restart thanks-backend

# Frontend
cd /opt/thanks/frontend
pnpm install
pnpm run build
systemctl reload nginx

echo "✅ Stage 2 обновлен!"
