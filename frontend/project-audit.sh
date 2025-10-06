#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🔍 ПОЛНЫЙ АУДИТ ПРОЕКТА THANKS"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. БАЗОВАЯ ИНФОРМАЦИЯ
echo -e "${BLUE}[1/12] 📋 СИСТЕМНАЯ ИНФОРМАЦИЯ${NC}"
echo "─────────────────────────────────────────────────────────────────"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo "IP Address: $(hostname -I | awk '{print $1}')"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 2. СТРУКТУРА ПРОЕКТА
echo -e "${BLUE}[2/12] 📁 СТРУКТУРА ПРОЕКТА${NC}"
echo "─────────────────────────────────────────────────────────────────"
if [ -d "/opt/thanks" ]; then
    cd /opt/thanks
    echo "Текущая директория: $(pwd)"
    echo ""
    echo "Основные директории:"
    ls -lah --color=never | grep "^d"
    echo ""
    echo "Файлы верхнего уровня:"
    ls -lh --color=never | grep "^-"
else
    echo "⚠️  Директория /opt/thanks не найдена"
fi
echo ""

# 3. BACKEND - СТРУКТУРА И КОНФИГ
echo -e "${BLUE}[3/12] 🔧 BACKEND - СТРУКТУРА${NC}"
echo "─────────────────────────────────────────────────────────────────"
if [ -d "/opt/thanks/backend" ]; then
    echo "Backend структура:"
    tree -L 3 -I '__pycache__|*.pyc|venv|node_modules' /opt/thanks/backend 2>/dev/null || find /opt/thanks/backend -maxdepth 3 -type f -name "*.py" | head -30
    echo ""
    
    echo "Python версия:"
    python3 --version 2>/dev/null || echo "Python не найден"
    echo ""
    
    if [ -f "/opt/thanks/backend/requirements.txt" ]; then
        echo "Установленные пакеты (requirements.txt):"
        cat /opt/thanks/backend/requirements.txt
    fi
    echo ""
    
    if [ -f "/opt/thanks/backend/.env" ]; then
        echo "ENV переменные (без секретов):"
        grep -v "PASSWORD\|SECRET\|KEY\|TOKEN" /opt/thanks/backend/.env 2>/dev/null || echo "Нет .env или все секреты"
    fi
else
    echo "⚠️  Backend директория не найдена"
fi
echo ""

# 4. БАЗА ДАННЫХ
echo -e "${BLUE}[4/12] 🗄️  БАЗА ДАННЫХ${NC}"
echo "─────────────────────────────────────────────────────────────────"
sudo systemctl status postgresql --no-pager -l 2>/dev/null | head -10
echo ""
echo "PostgreSQL версия:"
psql --version 2>/dev/null
echo ""

# Попытка подключиться к БД
if sudo -u postgres psql -c "\l" 2>/dev/null | grep -q "thanks"; then
    echo "База данных 'thanks' найдена!"
    echo ""
    echo "Таблицы в БД:"
    sudo -u postgres psql -d thanks -c "\dt" 2>/dev/null
    echo ""
    echo "Статистика по таблицам:"
    sudo -u postgres psql -d thanks -c "
    SELECT 
        schemaname,
        tablename,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
        n_tup_ins as inserts,
        n_tup_upd as updates,
        n_tup_del as deletes
    FROM pg_stat_user_tables 
    ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC 
    LIMIT 15;
    " 2>/dev/null
fi
echo ""

# 5. REDIS
echo -e "${BLUE}[5/12] 🔴 REDIS${NC}"
echo "─────────────────────────────────────────────────────────────────"
sudo systemctl status redis --no-pager -l 2>/dev/null | head -10
echo ""
redis-cli --version 2>/dev/null
echo ""
echo "Redis INFO:"
redis-cli info stats 2>/dev/null | head -15
echo ""

# 6. FRONTEND
echo -e "${BLUE}[6/12] 💻 FRONTEND${NC}"
echo "─────────────────────────────────────────────────────────────────"
if [ -d "/opt/thanks/frontend" ]; then
    echo "Frontend структура:"
    tree -L 2 -I 'node_modules|build|dist' /opt/thanks/frontend 2>/dev/null || ls -la /opt/thanks/frontend
    echo ""
    
    if [ -f "/opt/thanks/frontend/package.json" ]; then
        echo "Package.json:"
        cat /opt/thanks/frontend/package.json | head -50
    fi
    echo ""
    
    echo "Node.js версия:"
    node --version 2>/dev/null || echo "Node не найден"
    echo "npm версия:"
    npm --version 2>/dev/null || echo "npm не найден"
else
    echo "⚠️  Frontend директория не найдена"
fi
echo ""

# 7. NGINX КОНФИГУРАЦИЯ
echo -e "${BLUE}[7/12] 🌐 NGINX${NC}"
echo "─────────────────────────────────────────────────────────────────"
sudo systemctl status nginx --no-pager -l 2>/dev/null | head -10
echo ""
nginx -v 2>&1
echo ""
echo "Конфиги Nginx:"
ls -la /etc/nginx/sites-enabled/ 2>/dev/null
echo ""
if [ -f "/etc/nginx/sites-enabled/thanks" ]; then
    echo "Thanks конфиг:"
    cat /etc/nginx/sites-enabled/thanks
fi
echo ""

# 8. SYSTEMD СЕРВИСЫ
echo -e "${BLUE}[8/12] 🔄 SYSTEMD СЕРВИСЫ${NC}"
echo "─────────────────────────────────────────────────────────────────"
echo "Сервисы Thanks:"
systemctl list-units --type=service --all | grep thanks
echo ""
if systemctl list-units --type=service | grep -q "thanks-api"; then
    echo "Thanks API статус:"
    sudo systemctl status thanks-api --no-pager -l | head -20
    echo ""
fi
if systemctl list-units --type=service | grep -q "thanks-ws"; then
    echo "Thanks WebSocket статус:"
    sudo systemctl status thanks-ws --no-pager -l | head -20
fi
echo ""

# 9. АКТИВНЫЕ ПРОЦЕССЫ
echo -e "${BLUE}[9/12] ⚙️  АКТИВНЫЕ ПРОЦЕССЫ${NC}"
echo "─────────────────────────────────────────────────────────────────"
echo "Python процессы:"
ps aux | grep -E "python|uvicorn|fastapi" | grep -v grep
echo ""
echo "Node процессы:"
ps aux | grep node | grep -v grep
echo ""

# 10. СЕТЕВЫЕ ПОРТЫ
echo -e "${BLUE}[10/12] 🔌 ОТКРЫТЫЕ ПОРТЫ${NC}"
echo "─────────────────────────────────────────────────────────────────"
sudo netstat -tulpn | grep LISTEN | grep -E "80|443|8000|5432|6379|3000"
echo ""

# 11. ЛОГИ (последние записи)
echo -e "${BLUE}[11/12] 📝 ЛОГИ${NC}"
echo "─────────────────────────────────────────────────────────────────"
if [ -d "/opt/thanks/logs" ]; then
    echo "Файлы логов:"
    ls -lah /opt/thanks/logs/
    echo ""
    echo "Последние 10 строк из основного лога:"
    tail -10 /opt/thanks/logs/*.log 2>/dev/null | head -50
fi
echo ""
echo "Nginx error log (последние 5 строк):"
sudo tail -5 /var/log/nginx/error.log 2>/dev/null
echo ""

# 12. API ENDPOINTS
echo -e "${BLUE}[12/12] 🔗 API ENDPOINTS (тест)${NC}"
echo "─────────────────────────────────────────────────────────────────"
echo "Проверка здоровья API:"
curl -s http://localhost:8000/health 2>/dev/null || echo "API недоступен"
echo ""
echo ""
echo "Проверка docs:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8000/docs 2>/dev/null
echo ""

# ИТОГОВАЯ СВОДКА
echo "════════════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ АНАЛИЗ ЗАВЕРШЕН!${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📊 Быстрая сводка:"
echo "─────────────────────────────────────────────────────────────────"

# Проверка сервисов
services_ok=0
services_total=5

systemctl is-active --quiet postgresql && echo -e "${GREEN}✓${NC} PostgreSQL: работает" || echo -e "${RED}✗${NC} PostgreSQL: не работает"
systemctl is-active --quiet postgresql && ((services_ok++))

systemctl is-active --quiet redis && echo -e "${GREEN}✓${NC} Redis: работает" || echo -e "${RED}✗${NC} Redis: не работает"
systemctl is-active --quiet redis && ((services_ok++))

systemctl is-active --quiet nginx && echo -e "${GREEN}✓${NC} Nginx: работает" || echo -e "${RED}✗${NC} Nginx: не работает"
systemctl is-active --quiet nginx && ((services_ok++))

systemctl is-active --quiet thanks-api && echo -e "${GREEN}✓${NC} Thanks API: работает" || echo -e "${RED}✗${NC} Thanks API: не работает"
systemctl is-active --quiet thanks-api && ((services_ok++))

systemctl is-active --quiet thanks-ws && echo -e "${GREEN}✓${NC} Thanks WebSocket: работает" || echo -e "${RED}✗${NC} Thanks WebSocket: не работает"
systemctl is-active --quiet thanks-ws && ((services_ok++))

echo ""
echo "Работает сервисов: $services_ok/$services_total"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "💡 Отчет сохранен. Отправьте вывод для анализа!"
echo "════════════════════════════════════════════════════════════════"
