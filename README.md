# Thanks PWA - Stage 1

## 🚀 Установленные компоненты

- ✅ Backend: FastAPI (Python 3.11) на порту 8000
- ✅ Frontend: React + Vite + PWA
- ✅ Database: PostgreSQL 16
- ✅ Cache: Redis 7
- ✅ Web Server: Nginx
- ✅ Security: fail2ban + UFW firewall

## 🔐 Доступ

**URL:** http://217.11.74.100

**Супер-админ:**
- Email: admin@thanks.kz
- Password: Bitcoin1

## 📝 Полезные команды

### Проверка статуса
systemctl status thanks-backend
systemctl status nginx
systemctl status postgresql
systemctl status redis

### Логи
tail -f /var/log/thanks/backend.log
tail -f /var/log/nginx/error.log

### Перезапуск
systemctl restart thanks-backend
systemctl reload nginx

### Обновление проекта
/opt/thanks/scripts/update_stage1.sh

## 🗂️ Структура проекта

/opt/thanks/
├── backend/          # FastAPI приложение
├── frontend/         # React PWA
├── scripts/          # Скрипты обновления
├── logs/            # Логи
└── backups/         # Бэкапы БД

## 📊 База данных

**Подключение к PostgreSQL:**
psql -U thanks_user -d thanks_db

**Пароль:** Bitcoin1
