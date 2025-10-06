#!/bin/bash

# =====================================================
# THANKS PWA - STAGE 2: Проверка установки
# =====================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}THANKS PWA - ПРОВЕРКА STAGE 2${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}\n"

# Функция для проверки
check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
        ((ERRORS++))
    fi
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# =====================================================
# 1. Проверка сервисов
# =====================================================
echo -e "\n${BLUE}[1] Проверка сервисов${NC}"

systemctl is-active --quiet thanks-backend
check "Backend сервис запущен"

systemctl is-active --quiet nginx
check "Nginx запущен"

systemctl is-active --quiet postgresql
check "PostgreSQL запущен"

systemctl is-active --quiet redis
check "Redis запущен"

# =====================================================
# 2. Проверка API эндпоинтов
# =====================================================
echo -e "\n${BLUE}[2] Проверка API эндпоинтов${NC}"

# Health check
HEALTH=$(curl -s http://localhost:8000/health)
if echo "$HEALTH" | grep -q '"status":"healthy"'; then
    check "API health endpoint работает"
else
    echo -e "${RED}✗${NC} API health endpoint не работает"
    ((ERRORS++))
fi

# Проверка версии
if echo "$HEALTH" | grep -q '"stage":2'; then
    check "API версия Stage 2"
else
    warn "API версия не Stage 2"
fi

# Проверка через Nginx
NGINX_HEALTH=$(curl -s http://localhost/api/health)
if echo "$NGINX_HEALTH" | grep -q '"status":"healthy"'; then
    check "Nginx reverse proxy работает"
else
    echo -e "${RED}✗${NC} Nginx reverse proxy не работает"
    ((ERRORS++))
fi

# =====================================================
# 3. Проверка базы данных
# =====================================================
echo -e "\n${BLUE}[3] Проверка базы данных${NC}"

# Проверка подключения
sudo -u postgres psql -d thanks_db -c "SELECT 1" > /dev/null 2>&1
check "Подключение к БД работает"

# Проверка таблиц
TABLES=$(sudo -u postgres psql -d thanks_db -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'")
if [ "$TABLES" -ge 7 ]; then
    check "Таблицы созданы (найдено: $TABLES)"
else
    echo -e "${RED}✗${NC} Недостаточно таблиц (найдено: $TABLES, ожидается >= 7)"
    ((ERRORS++))
fi

# Проверка таблицы users
USERS_COLS=$(sudo -u postgres psql -d thanks_db -t -c "SELECT column_name FROM information_schema.columns WHERE table_name='users' AND column_name='restaurant_id'")
if [ -n "$USERS_COLS" ]; then
    check "Колонка restaurant_id в таблице users"
else
    echo -e "${RED}✗${NC} Колонка restaurant_id отсутствует"
    ((ERRORS++))
fi

# Проверка таблицы restaurants
REST_COUNT=$(sudo -u postgres psql -d thanks_db -t -c "SELECT COUNT(*) FROM restaurants")
if [ "$REST_COUNT" -gt 0 ]; then
    check "Заведения созданы (найдено: $REST_COUNT)"
else
    warn "Нет заведений в БД"
fi

# Проверка категорий
CAT_COUNT=$(sudo -u postgres psql -d thanks_db -t -c "SELECT COUNT(*) FROM categories")
if [ "$CAT_COUNT" -gt 0 ]; then
    check "Категории созданы (найдено: $CAT_COUNT)"
else
    warn "Нет категорий в БД"
fi

# Проверка блюд
DISH_COUNT=$(sudo -u postgres psql -d thanks_db -t -c "SELECT COUNT(*) FROM dishes")
if [ "$DISH_COUNT" -gt 0 ]; then
    check "Блюда созданы (найдено: $DISH_COUNT)"
else
    warn "Нет блюд в БД"
fi

# Проверка пользователей
ADMIN_EXISTS=$(sudo -u postgres psql -d thanks_db -t -c "SELECT COUNT(*) FROM users WHERE email='admin@thanks.kz'")
if [ "$ADMIN_EXISTS" -gt 0 ]; then
    check "Супер-админ существует"
else
    echo -e "${RED}✗${NC} Супер-админ не найден"
    ((ERRORS++))
fi

REST_ADMIN_EXISTS=$(sudo -u postgres psql -d thanks_db -t -c "SELECT COUNT(*) FROM users WHERE email='admin@restaurant.kz'")
if [ "$REST_ADMIN_EXISTS" -gt 0 ]; then
    check "Админ заведения существует"
else
    warn "Админ заведения не найден"
fi

# =====================================================
# 4. Проверка Frontend файлов
# =====================================================
echo -e "\n${BLUE}[4] Проверка Frontend${NC}"

if [ -f "/opt/thanks/frontend/dist/index.html" ]; then
    check "Frontend собран (dist/index.html)"
else
    echo -e "${RED}✗${NC} Frontend не собран"
    ((ERRORS++))
fi

if [ -d "/opt/thanks/frontend/src/pages/admin" ]; then
    check "Админ-панель создана"
else
    echo -e "${RED}✗${NC} Админ-панель не найдена"
    ((ERRORS++))
fi

# Проверка компонентов
if [ -f "/opt/thanks/frontend/src/pages/admin/Restaurants.jsx" ]; then
    check "Компонент Restaurants существует"
else
    warn "Компонент Restaurants не найден"
fi

if [ -f "/opt/thanks/frontend/src/pages/admin/Menu.jsx" ]; then
    check "Компонент Menu существует"
else
    warn "Компонент Menu не найден"
fi

# =====================================================
# 5. Проверка API функционала
# =====================================================
echo -e "\n${BLUE}[5] Проверка API функционала${NC}"

# Тест логина супер-админа
TOKEN=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin@thanks.kz&password=Bitcoin1" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
    check "Авторизация супер-админа работает"
    
    # Проверка получения списка заведений
    RESTAURANTS=$(curl -s http://localhost:8000/restaurants -H "Authorization: Bearer $TOKEN")
    if echo "$RESTAURANTS" | grep -q '\[' ; then
        check "API получения заведений работает"
    else
        warn "API получения заведений не вернул массив"
    fi
else
    echo -e "${RED}✗${NC} Авторизация не работает"
    ((ERRORS++))
fi

# Тест логина админа заведения
REST_TOKEN=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin@restaurant.kz&password=Bitcoin1" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -n "$REST_TOKEN" ]; then
    check "Авторизация админа заведения работает"
else
    warn "Админ заведения не может авторизоваться"
fi

# =====================================================
# 6. Проверка сети
# =====================================================
echo -e "\n${BLUE}[6] Проверка сетевого доступа${NC}"

# Проверка порта 8000 (backend)
if netstat -tuln | grep -q ':8000'; then
    check "Backend слушает порт 8000"
else
    echo -e "${RED}✗${NC} Backend не слушает порт 8000"
    ((ERRORS++))
fi

# Проверка порта 80 (nginx)
if netstat -tuln | grep -q ':80'; then
    check "Nginx слушает порт 80"
else
    echo -e "${RED}✗${NC} Nginx не слушает порт 80"
    ((ERRORS++))
fi

# Проверка доступа извне
EXTERNAL=$(curl -s -o /dev/null -w "%{http_code}" http://217.11.74.100)
if [ "$EXTERNAL" = "200" ]; then
    check "Внешний доступ работает (HTTP 200)"
else
    warn "Внешний доступ вернул код: $EXTERNAL"
fi

# =====================================================
# 7. Проверка логов
# =====================================================
echo -e "\n${BLUE}[7] Проверка логов на ошибки${NC}"

# Проверка логов backend за последние 100 строк
BACKEND_ERRORS=$(journalctl -u thanks-backend -n 100 --no-pager | grep -i error | wc -l)
if [ "$BACKEND_ERRORS" -eq 0 ]; then
    check "Нет ошибок в логах backend"
else
    warn "Найдено ошибок в логах backend: $BACKEND_ERRORS"
fi

# Проверка логов Nginx
if [ -f "/var/log/nginx/error.log" ]; then
    NGINX_ERRORS=$(tail -100 /var/log/nginx/error.log | grep -i error | wc -l)
    if [ "$NGINX_ERRORS" -eq 0 ]; then
        check "Нет ошибок в логах Nginx"
    else
        warn "Найдено ошибок в логах Nginx: $NGINX_ERRORS"
    fi
fi

# =====================================================
# 8. Проверка файловой структуры
# =====================================================
echo -e "\n${BLUE}[8] Проверка файловой структуры${NC}"

[ -f "/opt/thanks/backend/models.py" ] && check "models.py существует" || warn "models.py не найден"
[ -f "/opt/thanks/backend/main.py" ] && check "main.py существует" || warn "main.py не найден"
[ -f "/opt/thanks/scripts/update_stage2.sh" ] && check "update_stage2.sh существует" || warn "update_stage2.sh не найден"
[ -x "/opt/thanks/scripts/update_stage2.sh" ] && check "update_stage2.sh исполняемый" || warn "update_stage2.sh не исполняемый"

# =====================================================
# 9. Проверка прав доступа к БД
# =====================================================
echo -e "\n${BLUE}[9] Проверка прав доступа${NC}"

# Проверка прав на таблицы
sudo -u postgres psql -d thanks_db -c "SELECT * FROM users LIMIT 1" > /dev/null 2>&1
check "Права на чтение users"

sudo -u postgres psql -d thanks_db -c "SELECT * FROM restaurants LIMIT 1" > /dev/null 2>&1
check "Права на чтение restaurants"

sudo -u postgres psql -d thanks_db -c "SELECT * FROM categories LIMIT 1" > /dev/null 2>&1
check "Права на чтение categories"

sudo -u postgres psql -d thanks_db -c "SELECT * FROM dishes LIMIT 1" > /dev/null 2>&1
check "Права на чтение dishes"

# =====================================================
# 10. Дополнительные проверки
# =====================================================
echo -e "\n${BLUE}[10] Дополнительные проверки${NC}"

# Проверка Python зависимостей
cd /opt/thanks/backend
source venv/bin/activate
python3 -c "import fastapi, sqlalchemy, pydantic" 2>/dev/null
check "Python зависимости установлены"

# Проверка Node.js зависимостей
if [ -d "/opt/thanks/frontend/node_modules" ]; then
    check "Node.js зависимости установлены"
else
    warn "node_modules не найдены"
fi

# Проверка наличия placeholder изображений
PLACEHOLDER_COUNT=$(sudo -u postgres psql -d thanks_db -t -c "SELECT COUNT(*) FROM dishes WHERE image_url LIKE '%placehold%'")
if [ "$PLACEHOLDER_COUNT" -gt 0 ]; then
    check "Placeholder изображения используются ($PLACEHOLDER_COUNT блюд)"
else
    warn "Нет placeholder изображений"
fi

# =====================================================
# ИТОГИ
# =====================================================
echo -e "\n${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}РЕЗУЛЬТАТЫ ПРОВЕРКИ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}\n"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ УСПЕШНО!${NC}\n"
    echo -e "Stage 2 установлен корректно и готов к использованию.\n"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ ПРОВЕРКА ЗАВЕРШЕНА С ПРЕДУПРЕЖДЕНИЯМИ${NC}"
    echo -e "Критических ошибок: ${GREEN}0${NC}"
    echo -e "Предупреждений: ${YELLOW}$WARNINGS${NC}\n"
    echo -e "Stage 2 работает, но есть некритичные замечания.\n"
else
    echo -e "${RED}✗ ОБНАРУЖЕНЫ ОШИБКИ${NC}"
    echo -e "Критических ошибок: ${RED}$ERRORS${NC}"
    echo -e "Предупреждений: ${YELLOW}$WARNINGS${NC}\n"
    echo -e "Необходимо исправить ошибки для корректной работы.\n"
fi

echo -e "${BLUE}Доступ к приложению:${NC}"
echo -e "  URL: http://217.11.74.100"
echo -e "  Супер-админ: admin@thanks.kz / Bitcoin1"
echo -e "  Админ заведения: admin@restaurant.kz / Bitcoin1"

echo -e "\n${BLUE}════════════════════════════════════════════════${NC}"

exit $ERRORS
