# Административные страницы Thanks v1.5

Все страницы восстановлены с премиум дизайном (luxury theme).

## 📋 Основные страницы админа

### 1. **Dashboard** (`/dashboard`)
- Главная страница с профилем пользователя
- Навигационные карточки для всех модулей
- Встроенная генерация QR-ссылок для столов (раскрывающаяся секция)
- Системный статус

**Роли:** admin, owner, moderator, waiter, user

---

### 2. **Menu** (`/admin/menu/:restaurantId`)
**Управление меню ресторана**

#### Функции:
- ✅ Создание категорий (RU/KZ)
- ✅ Добавление блюд с полями:
  - Название (RU/KZ)
  - Описание (RU/KZ)
  - Цена, вес, калории
  - Время приготовления
  - URL изображения
- ✅ Стоп-лист (переключатель доступности)
- ✅ Боковая панель с категориями
- ✅ Карточки блюд с превью изображений

**Роль:** admin, owner

**Путь:** `/admin/menu/:restaurantId`

---

### 3. **Reservations** (`/admin/reservations/:restaurantId`)
**Управление бронированиями**

#### Функции:
- ✅ Создание бронирований с полями:
  - Данные гостя (имя, телефон, email)
  - Дата и время
  - Количество гостей
  - Длительность
  - Выбор зоны/стола
  - Депозит
  - Особые пожелания
- ✅ Статусы бронирования:
  - draft → pending → confirmed → awaiting → checked_in → seated → completed
  - cancelled, no_show
- ✅ Фильтры: все/сегодня/предстоящие
- ✅ Статистика по статусам
- ✅ Переходы между статусами одним кликом
- ✅ Отображение кода брони

**Роль:** admin, owner

**Путь:** `/admin/reservations/:restaurantId`

---

### 4. **Analytics** (`/admin/analytics/:restaurantId`)
**Аналитика и статистика**

#### Метрики:
- 💰 Общая выручка
- 💸 Чаевые
- 📋 Всего заказов
- 📊 Средний чек

#### Визуализация:
- ✅ График выручки по дням (столбчатая диаграмма)
- ✅ Топ-5 популярных блюд
- ✅ Статус заказов (прогресс-бары)
- ✅ Конверсия и процент отмен
- ✅ Фильтры периода: день/неделя/месяц/год

**Роль:** admin, owner

**Путь:** `/admin/analytics/:restaurantId`

---

### 5. **QR Generator** (`/admin/qr-generator/:restaurantId`) ⭐ НОВИНКА
**Генератор QR-кодов для гостевых ссылок**

#### Функции:
- ✅ Выбор зала
- ✅ Генерация уникальных ссылок для столов
- ✅ Превью QR-кода в карточке
- ✅ Действия для каждого стола:
  - 📋 Скопировать ссылку
  - 💾 Скачать QR (PNG 500x500)
  - 🖨️ Печать QR
  - 🔄 Перегенерировать ссылку
- ✅ Массовые действия:
  - Режим выбора нескольких столов
  - Генерация ссылок для всех выбранных
  - Скачивание всех QR разом
- ✅ Использует публичный API: `api.qrserver.com`

**Формат ссылки:** `http://217.11.74.100/t/{short_code}`

**Роль:** admin, owner

**Путь:** `/admin/qr-generator/:restaurantId`

---

### 6. **Halls** (`/admin/halls/:restaurantId`)
**Управление залами и столами**

#### Функции:
- ✅ Выбор зала
- ✅ Список столов с информацией:
  - Номер стола
  - Вместимость
  - Статус (активен/неактивен)
  - Короткая ссылка
- ✅ Копирование ссылок для столов

**Роль:** admin, owner

**Путь:** `/admin/halls/:restaurantId`

---

### 7. **Restaurants** (`/admin/restaurants`)
**Управление заведениями (для модератора)**

#### Функции:
- ✅ Список всех ресторанов
- ✅ Создание нового заведения
- ✅ Отображение: название, описание, адрес, телефон

**Роль:** moderator

**Путь:** `/admin/restaurants`

---

## 🎨 Дизайн

Все страницы используют **luxury theme**:
- 🌑 Темный фон (`bg-luxury-pattern`)
- ✨ Glass-эффекты (`glass-card`)
- 🏆 Золотые акценты (`#D4AF37`)
- 💎 Анимации (shimmer, float, transitions)
- 🔲 Кастомные инпуты (`input-glass`)
- 🔘 Премиум кнопки (`btn-luxury`, `btn-outline-gold`, `btn-glass`)

---

## 🚀 Маршруты в App.jsx

```javascript
// Admin routes
<Route path="/admin/restaurants" element={<ProtectedRoute><Restaurants /></ProtectedRoute>} />
<Route path="/admin/halls/:restaurantId" element={<ProtectedRoute><Halls /></ProtectedRoute>} />
<Route path="/admin/menu/:restaurantId" element={<ProtectedRoute><Menu /></ProtectedRoute>} />
<Route path="/admin/reservations/:restaurantId" element={<ProtectedRoute><Reservations /></ProtectedRoute>} />
<Route path="/admin/analytics/:restaurantId" element={<ProtectedRoute><Analytics /></ProtectedRoute>} />
<Route path="/admin/qr-generator/:restaurantId" element={<ProtectedRoute><QRGenerator /></ProtectedRoute>} />
<Route path="/admin/table-links/:restaurantId" element={<ProtectedRoute><TableLinks /></ProtectedRoute>} />
```

---

## 📱 Навигация в Dashboard

Для ролей `admin`, `owner`, `moderator` доступны карточки:

1. 📋 **Меню** → `/admin/menu/:restaurantId`
2. 🪑 **Залы** → `/admin/halls/:restaurantId`
3. 📱 **QR-коды** → `/admin/qr-generator/:restaurantId` ⭐
4. 📅 **Бронирования** → `/admin/reservations/:restaurantId`
5. 📊 **Аналитика** → `/admin/analytics/:restaurantId`

---

## 🔧 API Endpoints (используются)

### Menu:
- `GET /api/restaurants/:id/categories`
- `POST /api/restaurants/:id/categories`
- `GET /api/categories/:id/dishes`
- `POST /api/dishes`
- `PATCH /api/dishes/:id/stop-list?stop_list=true|false`

### Reservations:
- `GET /api/restaurants/:id/reservations`
- `POST /api/reservations`
- `PATCH /api/reservations/:id/status?status=:status`
- `GET /api/restaurants/:id/zones`

### Analytics:
- `GET /api/restaurants/:id/analytics?period=day|week|month|year`

### QR Generator:
- `GET /api/restaurants/:id/halls`
- `GET /api/halls/:id/tables`
- `POST /api/restaurants/:id/halls/:hallId/tables/:tableId/generate-link`

### Halls:
- `GET /api/restaurants/:id/halls`
- `GET /api/halls/:id/tables`

---

## ✅ Готово к использованию

Все страницы полностью функциональны и интегрированы в систему маршрутизации.
