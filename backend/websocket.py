import socketio
from typing import Set

# Создание Socket.IO сервера
sio = socketio.AsyncServer(
    async_mode='asgi',
    cors_allowed_origins='*'
)

# Хранилище подключенных клиентов по ролям
connected_clients = {
    'waiters': set(),
    'admins': set(),
    'users': set()
}

@sio.event
async def connect(sid, environ):
    print(f"Client connected: {sid}")

@sio.event
async def disconnect(sid):
    print(f"Client disconnected: {sid}")
    # Удалить из всех групп
    for group in connected_clients.values():
        group.discard(sid)

@sio.event
async def join_room(sid, data):
    """Клиент присоединяется к комнате по роли"""
    role = data.get('role', 'users')
    if role in connected_clients:
        connected_clients[role].add(sid)
        await sio.emit('joined', {'role': role}, room=sid)

@sio.event
async def new_order(sid, data):
    """Уведомление о новом заказе официантам"""
    for waiter_sid in connected_clients['waiters']:
        await sio.emit('order_created', data, room=waiter_sid)

@sio.event
async def order_status_changed(sid, data):
    """Уведомление об изменении статуса заказа"""
    # Отправить пользователю
    for user_sid in connected_clients['users']:
        await sio.emit('order_updated', data, room=user_sid)
    
    # Отправить официантам
    for waiter_sid in connected_clients['waiters']:
        await sio.emit('order_updated', data, room=waiter_sid)

@sio.event
async def waiter_called(sid, data):
    """Уведомление о вызове официанта"""
    for waiter_sid in connected_clients['waiters']:
        await sio.emit('call_received', data, room=waiter_sid)

async def notify_new_order(order_data):
    """Функция для уведомления о новом заказе"""
    for waiter_sid in connected_clients['waiters']:
        await sio.emit('order_created', order_data, room=waiter_sid)

async def notify_status_change(order_data):
    """Функция для уведомления об изменении статуса"""
    for user_sid in connected_clients['users']:
        await sio.emit('order_updated', order_data, room=user_sid)
    for waiter_sid in connected_clients['waiters']:
        await sio.emit('order_updated', order_data, room=waiter_sid)
