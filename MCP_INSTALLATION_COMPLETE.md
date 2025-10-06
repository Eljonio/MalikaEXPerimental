# ✅ MCP Серверы установлены для Thanks v1.5

**Дата установки:** 2025-10-06

---

## 📦 Установленные MCP серверы

### 1. ✅ PostgreSQL Server
**Пакет:** `@modelcontextprotocol/server-postgres@0.6.2`
**Статус:** ⚠️ Deprecated (но работает)
**Connection:** `postgresql://thanks_user:Bitcoin1@localhost:5432/thanks_db`

**Возможности:**
- Прямые SQL запросы к БД Thanks
- Анализ структуры таблиц
- Быстрый доступ к данным (users, restaurants, orders, reservations)

**Примеры запросов:**
```sql
SELECT * FROM users WHERE role='admin';
SELECT COUNT(*) FROM reservations WHERE status='confirmed';
SELECT * FROM dishes WHERE is_stop_list=true;
```

---

### 2. ✅ Filesystem Server
**Пакет:** `@modelcontextprotocol/server-filesystem@2025.8.21`
**Статус:** ✅ Актуален

**Доступные пути:**
- `/opt/thanks/` - основной проект
- `/home/malika/` - домашняя директория

**Возможности:**
- Чтение/запись файлов
- Поиск по файловой системе
- Работа с uploads (QR-коды, фото меню)

---

### 3. ✅ GitHub Server
**Пакет:** `@modelcontextprotocol/server-github@2025.4.8`
**Статус:** ⚠️ Deprecated (но работает)

**Настройка:**
- GitHub Token: НЕ НАСТРОЕН (пустой)
- Для использования: добавьте токен в `~/.config/claude/claude_desktop_config.json`

**Как получить токен:**
1. GitHub → Settings → Developer settings
2. Personal access tokens → Tokens (classic)
3. Generate new token (classic)
4. Выберите scopes: `repo`, `workflow`, `write:packages`
5. Скопируйте токен

**Где вставить:**
```json
"github": {
  "env": {
    "GITHUB_TOKEN": "ghp_YOUR_TOKEN_HERE"
  }
}
```

---

### 4. ✅ Redis Server
**Пакет:** `@modelcontextprotocol/server-redis@2025.4.25`
**Статус:** ⚠️ Deprecated (но работает)
**Connection:** `redis://localhost:6379`

**Возможности:**
- Кэширование
- Сессии пользователей
- Real-time данные (если используется)

---

## 📁 Структура директорий

Создана структура в `~/thanks/`:
```
~/thanks/
├── backend/       # Дополнительные backend файлы
├── frontend/      # Дополнительные frontend файлы
├── docs/          # Документация
└── uploads/       # Файлы загрузок
    ├── restaurants/
    ├── menu/
    └── qr-codes/
```

**Примечание:** Основной проект находится в `/opt/thanks/`

---

## ⚙️ Конфигурация

**Файл:** `~/.config/claude/claude_desktop_config.json`

**npm prefix:** `~/.npm-global`
**PATH:** Обновлен в `~/.bashrc`

---

## 🚀 Как использовать

### После перезапуска Claude Code:

MCP серверы будут доступны автоматически. Вы сможете:

**PostgreSQL запросы:**
```
Покажи всех администраторов из БД
SELECT * FROM users WHERE role='admin';

Сколько активных бронирований?
SELECT COUNT(*) FROM reservations WHERE status IN ('confirmed', 'awaiting');
```

**Filesystem операции:**
```
Найди все компоненты с glass-card классом в /opt/thanks/frontend

Прочитай конфиг из /opt/thanks/backend/config.py
```

**GitHub (после добавления токена):**
```
Создай issue для Thanks проекта

Покажи последние commits
```

**Redis (если запущен):**
```
Покажи активные сессии

Очисти кэш заказов
```

---

## ⚠️ Важные заметки

### 1. Deprecated пакеты
Некоторые MCP серверы помечены как deprecated:
- `@modelcontextprotocol/server-postgres`
- `@modelcontextprotocol/server-github`
- `@modelcontextprotocol/server-redis`

**Что это значит:**
- Они работают, но не получают обновлений
- В будущем могут появиться новые версии
- Пока можно использовать без проблем

### 2. GitHub Token
**НЕ ЗАБУДЬТЕ** добавить GitHub token для работы с GitHub!

### 3. PostgreSQL auth
Connection string использует `-h localhost` для password authentication (не peer auth)

### 4. PATH
Если PATH не работает после перезапуска терминала:
```bash
source ~/.bashrc
```

---

## 🔧 Устранение проблем

### npx не найден:
```bash
export PATH=~/.npm-global/bin:$PATH
source ~/.bashrc
```

### PostgreSQL connection failed:
Проверьте, что БД запущена:
```bash
sudo systemctl status postgresql
```

Проверьте пароль:
```bash
PGPASSWORD=Bitcoin1 psql -h localhost -U thanks_user -d thanks_db -c "SELECT 1;"
```

### Redis не подключается:
```bash
sudo systemctl start redis
sudo systemctl status redis
```

---

## 📊 Проверка установки

Выполните в терминале:
```bash
# Проверить MCP серверы
npm list -g --depth=0 | grep modelcontextprotocol

# Проверить конфиг
cat ~/.config/claude/claude_desktop_config.json

# Проверить PostgreSQL
PGPASSWORD=Bitcoin1 psql -h localhost -U thanks_user -d thanks_db -c "SELECT current_database();"
```

---

## ✅ Готово!

Все MCP серверы установлены и настроены.

**Следующие шаги:**
1. Перезапустите Claude Code (если запущен)
2. Добавьте GitHub token (опционально)
3. Начните использовать MCP возможности!

**Документация MCP:**
https://modelcontextprotocol.io/

**Примеры использования:**
- Анализ БД Thanks
- Автоматизация работы с кодом
- GitHub интеграция для задач
- Работа с файлами проекта

---

**Установка завершена успешно! 🎉**
