from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, Text, ForeignKey, JSON, Enum, Table as SQLTable
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime
import enum

Base = declarative_base()

class UserRole(str, enum.Enum):
    GUEST = "guest"
    USER = "user"
    WAITER = "waiter"
    ADMIN = "admin"
    OWNER = "owner"
    MODERATOR = "moderator"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    role = Column(Enum(UserRole), default=UserRole.GUEST)
    is_active = Column(Boolean, default=True)

    # Привязка к заведению для персонала
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), nullable=True)

    # Для официантов - привязка к залам/зонам (JSON: [hall_id, ...])
    assigned_halls = Column(JSON, default=[])
    assigned_zones = Column(JSON, default=[])

    # 2FA и безопасность
    two_factor_enabled = Column(Boolean, default=False)
    two_factor_secret = Column(String, nullable=True)

    # Блокировка и причины
    is_blocked = Column(Boolean, default=False)
    blocked_reason = Column(Text, nullable=True)
    blocked_at = Column(DateTime, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login = Column(DateTime, nullable=True)

    restaurant = relationship("Restaurant", back_populates="staff")

class Restaurant(Base):
    __tablename__ = "restaurants"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    name_kz = Column(String, nullable=True)
    slug = Column(String, unique=True, index=True)
    description = Column(Text, nullable=True)
    description_kz = Column(Text, nullable=True)
    logo_url = Column(String, nullable=True)

    # Контакты
    address = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    email = Column(String, nullable=True)
    website = Column(String, nullable=True)
    social_links = Column(JSON, default={})  # {"instagram": "url", ...}

    # Часы работы (JSON: {"monday": "10:00-22:00", ...})
    working_hours = Column(JSON, default={})
    closed_message = Column(Text, nullable=True)

    # Настройки
    currency = Column(String, default="KZT")
    timezone = Column(String, default="Asia/Almaty")
    service_fee_percent = Column(Float, default=0.0)
    min_order_amount = Column(Float, default=0.0)

    # Политики чаевых
    tips_enabled = Column(Boolean, default=True)
    tips_options = Column(JSON, default=[5, 10, 15, 20])  # Проценты

    # Бронирования
    booking_enabled = Column(Boolean, default=False)
    booking_horizon_days = Column(Integer, default=30)
    booking_buffer_before = Column(Integer, default=15)  # минуты
    booking_buffer_after = Column(Integer, default=15)
    booking_max_duration = Column(Integer, default=180)  # минуты
    booking_max_party_size = Column(Integer, default=20)

    # VIP политики
    vip_deposit_amount = Column(Float, default=0.0)
    vip_min_check = Column(Float, default=0.0)

    # Платежные провайдеры (JSON)
    payment_providers = Column(JSON, default={})  # {"kaspi": {...}, "halyk": {...}}

    # Брендинг (JSON: цвета, градиенты)
    branding = Column(JSON, default={})

    # White-label настройки
    custom_domain = Column(String, nullable=True)
    is_white_label = Column(Boolean, default=False)

    # Статус и тарификация
    is_active = Column(Boolean, default=True)
    plan = Column(String, default="free")  # free, basic, premium
    tables_limit = Column(Integer, default=3)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Отношения
    staff = relationship("User", back_populates="restaurant")
    categories = relationship("Category", back_populates="restaurant", cascade="all, delete-orphan")
    halls = relationship("Hall", back_populates="restaurant", cascade="all, delete-orphan")
    zones = relationship("Zone", back_populates="restaurant", cascade="all, delete-orphan")

class Zone(Base):
    """Зоны внутри зала: курящая, некурящая, VIP, бар и т.д."""
    __tablename__ = "zones"

    id = Column(Integer, primary_key=True, index=True)
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), nullable=False)
    hall_id = Column(Integer, ForeignKey("halls.id"), nullable=True)

    name = Column(String, nullable=False)  # "VIP зона", "Курящая", "Терраса"
    name_kz = Column(String, nullable=True)
    zone_type = Column(String, default="main")  # main, smoking, non_smoking, vip, bar, terrace, custom
    color = Column(String, default="#D4AF37")  # Для визуализации на плане

    # VIP настройки
    is_vip = Column(Boolean, default=False)
    min_deposit = Column(Float, default=0.0)
    min_check = Column(Float, default=0.0)

    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    restaurant = relationship("Restaurant", back_populates="zones")
    hall = relationship("Hall", back_populates="zones")

class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), nullable=False)
    name = Column(String, nullable=False)
    name_kz = Column(String, nullable=True)
    description = Column(Text, nullable=True)
    sort_order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    restaurant = relationship("Restaurant", back_populates="categories")
    dishes = relationship("Dish", back_populates="category", cascade="all, delete-orphan")

class Dish(Base):
    __tablename__ = "dishes"

    id = Column(Integer, primary_key=True, index=True)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=False)
    name = Column(String, nullable=False)
    name_kz = Column(String, nullable=True)
    description = Column(Text, nullable=True)
    description_kz = Column(Text, nullable=True)

    # Цена и изображение
    price = Column(Float, nullable=False)
    image_url = Column(String, nullable=True)

    # Характеристики
    cooking_time = Column(Integer, default=15)  # минуты (ETA)
    weight = Column(Integer, nullable=True)  # граммы
    calories = Column(Integer, nullable=True)
    allergens = Column(JSON, default=[])  # ["молоко", "глютен", ...]
    ingredients = Column(Text, nullable=True)  # Состав

    # Статус
    is_available = Column(Boolean, default=True)
    is_stop_list = Column(Boolean, default=False)
    sort_order = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    category = relationship("Category", back_populates="dishes")
    modifiers = relationship("Modifier", back_populates="dish", cascade="all, delete-orphan")

class Modifier(Base):
    __tablename__ = "modifiers"

    id = Column(Integer, primary_key=True, index=True)
    dish_id = Column(Integer, ForeignKey("dishes.id"), nullable=False)
    name = Column(String, nullable=False)
    name_kz = Column(String, nullable=True)
    price = Column(Float, default=0.0)
    is_required = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    dish = relationship("Dish", back_populates="modifiers")

class Hall(Base):
    __tablename__ = "halls"

    id = Column(Integer, primary_key=True, index=True)
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), nullable=False)
    name = Column(String, nullable=False)
    description = Column(Text, nullable=True)

    # План зала (JSON: координаты, размеры)
    layout_data = Column(JSON, default={})  # {"width": 800, "height": 600, "objects": [...]}

    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    restaurant = relationship("Restaurant", back_populates="halls")
    tables = relationship("Table", back_populates="hall", cascade="all, delete-orphan")
    zones = relationship("Zone", back_populates="hall", cascade="all, delete-orphan")

class TableStatus(str, enum.Enum):
    AVAILABLE = "available"
    RESERVED = "reserved"
    OCCUPIED = "occupied"
    HELD = "held"  # Временная блокировка официантом
    OUT_OF_SERVICE = "out_of_service"

class Table(Base):
    __tablename__ = "tables"

    id = Column(Integer, primary_key=True, index=True)
    hall_id = Column(Integer, ForeignKey("halls.id"), nullable=False)
    zone_id = Column(Integer, ForeignKey("zones.id"), nullable=True)

    table_number = Column(String, nullable=False)
    capacity = Column(Integer, default=2)

    # QR коды
    qr_code = Column(String, unique=True, index=True)
    short_code = Column(String, unique=True, index=True)

    # Позиция на плане зала
    position_x = Column(Integer, default=0)
    position_y = Column(Integer, default=0)

    # VIP
    is_vip = Column(Boolean, default=False)
    min_deposit = Column(Float, default=0.0)
    min_check = Column(Float, default=0.0)

    # Hold (временная блокировка)
    held_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    held_until = Column(DateTime, nullable=True)

    status = Column(Enum(TableStatus), default=TableStatus.AVAILABLE)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    hall = relationship("Hall", back_populates="tables")

class OrderStatus(str, enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    COOKING = "cooking"
    READY = "ready"
    SERVING = "serving"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    table_id = Column(Integer, ForeignKey("tables.id"))
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    status = Column(Enum(OrderStatus), default=OrderStatus.PENDING)

    # Суммы
    subtotal = Column(Float, default=0.0)  # Сумма блюд
    service_fee = Column(Float, default=0.0)
    tips_amount = Column(Float, default=0.0)
    total_amount = Column(Float, default=0.0)

    # Оплата
    is_paid = Column(Boolean, default=False)
    payment_method = Column(String, nullable=True)  # kaspi, halyk, card, apple_pay, google_pay
    payment_id = Column(String, nullable=True)  # ID транзакции провайдера
    paid_at = Column(DateTime, nullable=True)

    # Комментарий
    comment = Column(Text, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class OrderItem(Base):
    __tablename__ = "order_items"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    dish_id = Column(Integer, ForeignKey("dishes.id"))

    quantity = Column(Integer, default=1)
    price = Column(Float)  # Цена на момент заказа
    modifiers = Column(JSON, default=[])  # Выбранные модификаторы
    total = Column(Float)

    special_instructions = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class WaiterCall(Base):
    __tablename__ = "waiter_calls"

    id = Column(Integer, primary_key=True, index=True)
    table_id = Column(Integer, ForeignKey("tables.id"))
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    status = Column(String, default="pending")  # pending, in_progress, resolved
    message = Column(Text, nullable=True)

    # Кто обработал
    resolved_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    resolved_at = Column(DateTime, nullable=True)

class ReservationStatus(str, enum.Enum):
    DRAFT = "draft"
    PENDING = "pending"
    CONFIRMED = "confirmed"
    AWAITING = "awaiting"  # Ожидает прибытия
    CHECKED_IN = "checked_in"  # Прибыл (отметка по QR или вручную)
    SEATED = "seated"  # Посажен за стол
    NO_SHOW = "no_show"
    CANCELLED = "cancelled"
    COMPLETED = "completed"

class Reservation(Base):
    __tablename__ = "reservations"

    id = Column(Integer, primary_key=True, index=True)
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), nullable=False)
    table_id = Column(Integer, ForeignKey("tables.id"), nullable=True)
    zone_id = Column(Integer, ForeignKey("zones.id"), nullable=True)  # Предпочтительная зона
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    # Данные гостя
    guest_name = Column(String, nullable=False)
    guest_phone = Column(String, nullable=False)
    guest_email = Column(String, nullable=True)
    guest_count = Column(Integer, default=2)

    # Дата и время
    reservation_date = Column(DateTime, nullable=False)
    reservation_time = Column(DateTime, nullable=False)
    duration_minutes = Column(Integer, default=120)

    # Статус
    status = Column(Enum(ReservationStatus), default=ReservationStatus.PENDING)

    # Особые запросы
    special_requests = Column(Text, nullable=True)

    # Депозит/предоплата
    deposit_amount = Column(Float, default=0.0)
    is_deposit_paid = Column(Boolean, default=False)

    # Код брони (для быстрого поиска)
    booking_code = Column(String, unique=True, index=True)

    # Уведомления
    reminder_sent = Column(Boolean, default=False)

    # Check-in
    checked_in_at = Column(DateTime, nullable=True)
    seated_at = Column(DateTime, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class ChatMessage(Base):
    """Сообщения между пользователем и официантом"""
    __tablename__ = "chat_messages"

    id = Column(Integer, primary_key=True, index=True)
    table_id = Column(Integer, ForeignKey("tables.id"), nullable=False)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    receiver_id = Column(Integer, ForeignKey("users.id"), nullable=True)  # Если известен конкретный официант

    message = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)

    created_at = Column(DateTime, default=datetime.utcnow)

class Payment(Base):
    """Платежи и транзакции"""
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    amount = Column(Float, nullable=False)
    currency = Column(String, default="KZT")

    # Провайдер
    provider = Column(String, nullable=False)  # kaspi, halyk, stripe, etc
    provider_transaction_id = Column(String, unique=True, index=True)

    # Статус
    status = Column(String, default="pending")  # pending, success, failed, refunded

    # Метаданные от провайдера
    provider_data = Column(JSON, default={})

    # Ошибки
    error_code = Column(String, nullable=True)
    error_message = Column(Text, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class AuditLog(Base):
    """Аудит всех действий (для модератора)"""
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    action = Column(String, nullable=False)  # create, update, delete, login, etc
    resource_type = Column(String, nullable=False)  # user, restaurant, order, etc
    resource_id = Column(Integer, nullable=True)

    # Данные до/после изменения
    old_data = Column(JSON, default={})
    new_data = Column(JSON, default={})

    # Причина (для критических операций)
    reason = Column(Text, nullable=True)

    ip_address = Column(String, nullable=True)
    user_agent = Column(String, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)

class Invite(Base):
    """Инвайт-ссылки с ролями"""
    __tablename__ = "invites"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, index=True, nullable=False)

    # Роль и заведение
    role = Column(Enum(UserRole), nullable=False)
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), nullable=True)

    # Создатель
    created_by_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    # Лимиты
    max_uses = Column(Integer, default=1)
    current_uses = Column(Integer, default=0)
    expires_at = Column(DateTime, nullable=True)

    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class FeatureFlag(Base):
    """Feature flags для управления функциональностью"""
    __tablename__ = "feature_flags"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True, nullable=False)
    description = Column(Text, nullable=True)

    # Включен глобально или по заведениям
    is_global = Column(Boolean, default=True)
    is_enabled = Column(Boolean, default=False)

    # Процентный rollout (0-100)
    rollout_percentage = Column(Integer, default=0)

    # Для каких заведений включен (JSON: [restaurant_id, ...])
    enabled_restaurants = Column(JSON, default=[])

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
