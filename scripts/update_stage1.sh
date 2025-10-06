#!/bin/bash
set -e

echo "🔄 Обновление Thanks PWA..."

# Backend
echo "📦 Обновление Backend..."
cd /opt/thanks/backend
source venv/bin/activate
git pull 2>/dev/null || echo "Git не настроен, пропуск..."
pip install -r requirements.txt --upgrade
systemctl restart thanks-backend
echo "✅ Backend обновлен"

# Frontend
echo "🎨 Обновление Frontend..."
cd /opt/thanks/frontend
pnpm install
pnpm run build
echo "✅ Frontend обновлен"

# Перезагрузка Nginx
systemctl reload nginx

echo "✅ Обновление завершено!"
echo "🌐 Приложение доступно: http://217.11.74.100"
