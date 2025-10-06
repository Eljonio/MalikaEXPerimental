#!/usr/bin/env python3
"""
Скрипт миграции БД для Thanks v1.5
Добавляет новые таблицы и поля согласно ТЗ
"""

from sqlalchemy import create_engine, text
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://thanks_user:Bitcoin1@localhost/thanks_db")

engine = create_engine(DATABASE_URL)

migrations = [
    # 1. Добавляем поля в users
    """
    ALTER TABLE users
    ADD COLUMN IF NOT EXISTS assigned_halls JSON DEFAULT '[]',
    ADD COLUMN IF NOT EXISTS assigned_zones JSON DEFAULT '[]',
    ADD COLUMN IF NOT EXISTS two_factor_enabled BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS two_factor_secret VARCHAR,
    ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS blocked_reason TEXT,
    ADD COLUMN IF NOT EXISTS blocked_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS last_login TIMESTAMP;
    """,

    # 2. Добавляем поля в restaurants
    """
    ALTER TABLE restaurants
    ADD COLUMN IF NOT EXISTS name_kz VARCHAR,
    ADD COLUMN IF NOT EXISTS description_kz TEXT,
    ADD COLUMN IF NOT EXISTS social_links JSON DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS closed_message TEXT,
    ADD COLUMN IF NOT EXISTS min_order_amount FLOAT DEFAULT 0.0,
    ADD COLUMN IF NOT EXISTS booking_enabled BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS booking_horizon_days INTEGER DEFAULT 30,
    ADD COLUMN IF NOT EXISTS booking_buffer_before INTEGER DEFAULT 15,
    ADD COLUMN IF NOT EXISTS booking_buffer_after INTEGER DEFAULT 15,
    ADD COLUMN IF NOT EXISTS booking_max_duration INTEGER DEFAULT 180,
    ADD COLUMN IF NOT EXISTS booking_max_party_size INTEGER DEFAULT 20,
    ADD COLUMN IF NOT EXISTS vip_deposit_amount FLOAT DEFAULT 0.0,
    ADD COLUMN IF NOT EXISTS vip_min_check FLOAT DEFAULT 0.0,
    ADD COLUMN IF NOT EXISTS payment_providers JSON DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS branding JSON DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS custom_domain VARCHAR,
    ADD COLUMN IF NOT EXISTS is_white_label BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS plan VARCHAR DEFAULT 'free',
    ADD COLUMN IF NOT EXISTS tables_limit INTEGER DEFAULT 3;
    """,

    # 3. Создаем таблицу zones
    """
    CREATE TABLE IF NOT EXISTS zones (
        id SERIAL PRIMARY KEY,
        restaurant_id INTEGER REFERENCES restaurants(id) ON DELETE CASCADE,
        hall_id INTEGER REFERENCES halls(id) ON DELETE CASCADE,
        name VARCHAR NOT NULL,
        name_kz VARCHAR,
        zone_type VARCHAR DEFAULT 'main',
        color VARCHAR DEFAULT '#D4AF37',
        is_vip BOOLEAN DEFAULT FALSE,
        min_deposit FLOAT DEFAULT 0.0,
        min_check FLOAT DEFAULT 0.0,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT NOW()
    );
    """,

    # 4. Добавляем поля в halls
    """
    ALTER TABLE halls
    ADD COLUMN IF NOT EXISTS layout_data JSON DEFAULT '{}';
    """,

    # 5. Добавляем поля в tables
    """
    ALTER TABLE tables
    ADD COLUMN IF NOT EXISTS zone_id INTEGER REFERENCES zones(id),
    ADD COLUMN IF NOT EXISTS position_x INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS position_y INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS min_deposit FLOAT DEFAULT 0.0,
    ADD COLUMN IF NOT EXISTS min_check FLOAT DEFAULT 0.0,
    ADD COLUMN IF NOT EXISTS held_by_user_id INTEGER REFERENCES users(id),
    ADD COLUMN IF NOT EXISTS held_until TIMESTAMP;
    """,

    # 6. Обновляем статус стола если нужно
    """
    DO $$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tablestatus') THEN
            CREATE TYPE tablestatus AS ENUM ('available', 'reserved', 'occupied', 'held', 'out_of_service');
        END IF;
    END$$;
    """,

    # 7. Добавляем поля в orders
    """
    ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS subtotal FLOAT DEFAULT 0.0,
    ADD COLUMN IF NOT EXISTS payment_method VARCHAR,
    ADD COLUMN IF NOT EXISTS payment_id VARCHAR,
    ADD COLUMN IF NOT EXISTS paid_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS comment TEXT;
    """,

    # 8. Добавляем поля в order_items
    """
    ALTER TABLE order_items
    ADD COLUMN IF NOT EXISTS modifiers JSON DEFAULT '[]';
    """,

    # 9. Добавляем поля в waiter_calls
    """
    ALTER TABLE waiter_calls
    ADD COLUMN IF NOT EXISTS resolved_by_id INTEGER REFERENCES users(id);
    """,

    # 10. Обновляем резервации
    """
    DO $$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'reservationstatus') THEN
            CREATE TYPE reservationstatus AS ENUM ('draft', 'pending', 'confirmed', 'awaiting', 'checked_in', 'seated', 'no_show', 'cancelled', 'completed');
        END IF;
    END$$;
    """,

    """
    ALTER TABLE reservations
    ADD COLUMN IF NOT EXISTS restaurant_id INTEGER REFERENCES restaurants(id),
    ADD COLUMN IF NOT EXISTS zone_id INTEGER REFERENCES zones(id),
    ADD COLUMN IF NOT EXISTS guest_email VARCHAR,
    ADD COLUMN IF NOT EXISTS is_deposit_paid BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS booking_code VARCHAR UNIQUE,
    ADD COLUMN IF NOT EXISTS reminder_sent BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS checked_in_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS seated_at TIMESTAMP;
    """,

    # 11. Создаем таблицу chat_messages
    """
    CREATE TABLE IF NOT EXISTS chat_messages (
        id SERIAL PRIMARY KEY,
        table_id INTEGER REFERENCES tables(id) ON DELETE CASCADE,
        sender_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        receiver_id INTEGER REFERENCES users(id),
        message TEXT NOT NULL,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT NOW()
    );
    """,

    # 12. Создаем таблицу payments
    """
    CREATE TABLE IF NOT EXISTS payments (
        id SERIAL PRIMARY KEY,
        order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
        user_id INTEGER REFERENCES users(id),
        amount FLOAT NOT NULL,
        currency VARCHAR DEFAULT 'KZT',
        provider VARCHAR NOT NULL,
        provider_transaction_id VARCHAR UNIQUE,
        status VARCHAR DEFAULT 'pending',
        provider_data JSON DEFAULT '{}',
        error_code VARCHAR,
        error_message TEXT,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
    );
    """,

    # 13. Создаем таблицу audit_logs
    """
    CREATE TABLE IF NOT EXISTS audit_logs (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        action VARCHAR NOT NULL,
        resource_type VARCHAR NOT NULL,
        resource_id INTEGER,
        old_data JSON DEFAULT '{}',
        new_data JSON DEFAULT '{}',
        reason TEXT,
        ip_address VARCHAR,
        user_agent VARCHAR,
        created_at TIMESTAMP DEFAULT NOW()
    );
    """,

    # 14. Создаем таблицу invites
    """
    CREATE TABLE IF NOT EXISTS invites (
        id SERIAL PRIMARY KEY,
        code VARCHAR UNIQUE NOT NULL,
        role VARCHAR NOT NULL,
        restaurant_id INTEGER REFERENCES restaurants(id),
        created_by_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        max_uses INTEGER DEFAULT 1,
        current_uses INTEGER DEFAULT 0,
        expires_at TIMESTAMP,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT NOW()
    );
    """,

    # 15. Создаем таблицу feature_flags
    """
    CREATE TABLE IF NOT EXISTS feature_flags (
        id SERIAL PRIMARY KEY,
        name VARCHAR UNIQUE NOT NULL,
        description TEXT,
        is_global BOOLEAN DEFAULT TRUE,
        is_enabled BOOLEAN DEFAULT FALSE,
        rollout_percentage INTEGER DEFAULT 0,
        enabled_restaurants JSON DEFAULT '[]',
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
    );
    """,

    # 16. Создаем индексы для производительности
    """
    CREATE INDEX IF NOT EXISTS idx_zones_restaurant ON zones(restaurant_id);
    CREATE INDEX IF NOT EXISTS idx_zones_hall ON zones(hall_id);
    CREATE INDEX IF NOT EXISTS idx_tables_zone ON tables(zone_id);
    CREATE INDEX IF NOT EXISTS idx_reservations_restaurant ON reservations(restaurant_id);
    CREATE INDEX IF NOT EXISTS idx_reservations_zone ON reservations(zone_id);
    CREATE INDEX IF NOT EXISTS idx_reservations_booking_code ON reservations(booking_code);
    CREATE INDEX IF NOT EXISTS idx_chat_messages_table ON chat_messages(table_id);
    CREATE INDEX IF NOT EXISTS idx_payments_order ON payments(order_id);
    CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id);
    CREATE INDEX IF NOT EXISTS idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
    CREATE INDEX IF NOT EXISTS idx_invites_code ON invites(code);
    """
]

def run_migrations():
    print("🚀 Запуск миграций Thanks v1.5...")

    with engine.connect() as conn:
        for i, migration in enumerate(migrations, 1):
            try:
                print(f"  [{i}/{len(migrations)}] Выполнение миграции...")
                conn.execute(text(migration))
                conn.commit()
                print(f"  ✅ Миграция {i} успешна")
            except Exception as e:
                print(f"  ⚠️  Миграция {i}: {str(e)}")
                # Продолжаем выполнение (некоторые поля могут уже существовать)

    print("\n✨ Миграции завершены!")
    print("\nТеперь можно скопировать новые модели:")
    print("  sudo cp ~/models_enhanced.py /opt/thanks/backend/models.py")

if __name__ == "__main__":
    run_migrations()
