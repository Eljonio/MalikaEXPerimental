import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'
import io from 'socket.io-client'

const ORDER_STATUSES = {
  pending: { label: 'Ожидает', color: 'bg-gray-500', next: 'accepted', icon: '⏳' },
  accepted: { label: 'Принят', color: 'bg-blue-500', next: 'cooking', icon: '✓' },
  cooking: { label: 'На кухне', color: 'bg-yellow-500', next: 'ready', icon: '🔥' },
  ready: { label: 'Готов', color: 'bg-orange-500', next: 'serving', icon: '✨' },
  serving: { label: 'Несут', color: 'bg-purple-500', next: 'completed', icon: '🚶' },
  completed: { label: 'Подан', color: 'bg-green-500', next: null, icon: '✅' }
}

export default function WaiterDashboard() {
  const navigate = useNavigate()
  const [user, setUser] = useState(null)
  const [orders, setOrders] = useState([])
  const [calls, setCalls] = useState([])
  const [filter, setFilter] = useState('active')
  const [socket, setSocket] = useState(null)
  const [notification, setNotification] = useState(null)

  useEffect(() => {
    fetchUser()
  }, [])

  useEffect(() => {
    if (user) {
      fetchOrders()
      fetchCalls()

      // Подключение WebSocket
      const newSocket = io('/api', {
        path: '/api/socket.io',
        transports: ['websocket', 'polling']
      })

      newSocket.on('connect', () => {
        console.log('WebSocket connected')
        newSocket.emit('join_waiter', { user_id: user.id })
      })

      newSocket.on('waiter_call', (data) => {
        console.log('Waiter called:', data)
        showNotification(`🔔 Вызов со стола #${data.table_number || data.table_id}`)
        fetchCalls()
        playNotificationSound()
      })

      newSocket.on('new_order', (data) => {
        console.log('New order:', data)
        showNotification(`📋 Новый заказ на столе #${data.table_id}`)
        fetchOrders()
      })

      setSocket(newSocket)

      return () => {
        newSocket.disconnect()
      }
    }
  }, [user])

  const fetchUser = async () => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get('/api/auth/me', {
        headers: { Authorization: `Bearer ${token}` }
      })
      setUser(response.data)
    } catch (error) {
      console.error('Error:', error)
      navigate('/login')
    }
  }

  const fetchOrders = async () => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get('/api/waiter/orders', {
        headers: { Authorization: `Bearer ${token}` }
      })
      setOrders(response.data)
    } catch (error) {
      console.error('Error:', error)
    }
  }

  const fetchCalls = async () => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get('/api/waiter-calls', {
        headers: { Authorization: `Bearer ${token}` }
      })
      setCalls(response.data)
    } catch (error) {
      console.error('Error:', error)
    }
  }

  const updateOrderStatus = async (orderId, newStatus) => {
    try {
      const token = localStorage.getItem('token')
      await axios.patch(`/api/orders/${orderId}/status?status=${newStatus}`, {}, {
        headers: { Authorization: `Bearer ${token}` }
      })
      fetchOrders()
    } catch (error) {
      console.error('Error:', error)
    }
  }

  const resolveCall = async (callId) => {
    try {
      const token = localStorage.getItem('token')
      await axios.patch(`/api/waiter-calls/${callId}/resolve`, {}, {
        headers: { Authorization: `Bearer ${token}` }
      })
      fetchCalls()
    } catch (error) {
      console.error('Error:', error)
    }
  }

  const showNotification = (message) => {
    setNotification(message)
    setTimeout(() => setNotification(null), 5000)
  }

  const playNotificationSound = () => {
    // Можно добавить звук
    if ('vibrate' in navigator) {
      navigator.vibrate([200, 100, 200])
    }
  }

  const handleLogout = () => {
    localStorage.removeItem('token')
    navigate('/login')
  }

  const filteredOrders = orders.filter(order => {
    if (filter === 'active') {
      return ['pending', 'accepted', 'cooking', 'ready', 'serving'].includes(order.status)
    }
    return order.status === filter
  })

  const totalTips = orders
    .filter(o => o.is_paid)
    .reduce((sum, o) => sum + o.tips_amount, 0)

  if (!user) {
    return (
      <div className="min-h-screen bg-luxury-pattern flex items-center justify-center">
        <div className="glass-card p-8">
          <div className="flex items-center gap-3">
            <svg className="animate-spin h-8 w-8 text-luxury-gold" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            <span className="text-luxury-cream text-lg">Загрузка...</span>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-luxury-pattern pb-6">
      {/* Notification Toast */}
      {notification && (
        <div className="fixed top-6 left-1/2 transform -translate-x-1/2 z-50 animate-bounce">
          <div className="glass-card border-luxury-gold/40 px-6 py-4">
            <p className="text-luxury-gold font-semibold text-center">{notification}</p>
          </div>
        </div>
      )}

      {/* Header */}
      <header className="glass-card rounded-none border-x-0 border-t-0 sticky top-0 z-40">
        <div className="px-6 py-5">
          <div className="flex justify-between items-center mb-4">
            <div>
              <h1 className="text-2xl font-bold text-luxury-gold">Панель официанта</h1>
              <p className="text-luxury-cream/60 text-sm mt-1">{user.full_name}</p>
            </div>
            <button
              onClick={handleLogout}
              className="btn-outline-gold px-4 py-2 text-sm"
            >
              Выйти
            </button>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-3 gap-3">
            <div className="glass-card p-3">
              <p className="text-luxury-cream/60 text-xs mb-1">Заказов</p>
              <p className="text-2xl font-bold text-luxury-gold">{filteredOrders.length}</p>
            </div>
            <div className="glass-card p-3">
              <p className="text-luxury-cream/60 text-xs mb-1">Чаевые</p>
              <p className="text-2xl font-bold text-luxury-gold">{totalTips.toFixed(0)}₽</p>
            </div>
            <div className={`glass-card p-3 ${calls.length > 0 ? 'border-red-500/50 animate-pulse' : ''}`}>
              <p className="text-luxury-cream/60 text-xs mb-1">Вызовы</p>
              <p className="text-2xl font-bold text-luxury-gold">{calls.length}</p>
            </div>
          </div>
        </div>

        {/* Filters */}
        <div className="px-6 pb-4 overflow-x-auto luxury-scroll">
          <div className="flex gap-2">
            <button
              onClick={() => setFilter('active')}
              className={`px-4 py-2 rounded-xl font-medium whitespace-nowrap transition-all ${
                filter === 'active'
                  ? 'bg-luxury-gold text-luxury-charcoal'
                  : 'glass-card text-luxury-cream/70 hover:text-luxury-cream'
              }`}
            >
              Активные
            </button>
            {Object.entries(ORDER_STATUSES).map(([status, { label, icon }]) => (
              <button
                key={status}
                onClick={() => setFilter(status)}
                className={`px-4 py-2 rounded-xl font-medium whitespace-nowrap transition-all ${
                  filter === status
                    ? 'bg-luxury-gold text-luxury-charcoal'
                    : 'glass-card text-luxury-cream/70 hover:text-luxury-cream'
                }`}
              >
                {icon} {label}
              </button>
            ))}
          </div>
        </div>
      </header>

      {/* Calls Section */}
      {calls.length > 0 && (
        <div className="px-6 py-4">
          <h2 className="text-xl font-bold text-luxury-gold mb-4 flex items-center gap-2">
            <span className="animate-pulse">🔔</span>
            Вызовы гостей
          </h2>
          <div className="space-y-3">
            {calls.map(call => (
              <div key={call.id} className="glass-card p-4 border-luxury-gold/40 card-shimmer">
                <div className="flex justify-between items-center">
                  <div>
                    <div className="font-bold text-lg text-luxury-cream">Стол #{call.table_id}</div>
                    <div className="text-sm text-luxury-cream/60 mt-1">
                      {new Date(call.created_at).toLocaleTimeString('ru-RU')}
                    </div>
                    {call.message && (
                      <div className="text-sm text-luxury-gold mt-2">{call.message}</div>
                    )}
                  </div>
                  <button
                    onClick={() => resolveCall(call.id)}
                    className="btn-luxury px-6 py-2"
                  >
                    Обработано
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Orders */}
      <div className="px-6 py-4 space-y-4">
        {filteredOrders.length === 0 ? (
          <div className="glass-card p-12 text-center">
            <div className="text-5xl mb-4">📋</div>
            <p className="text-luxury-cream/60">
              {filter === 'active' ? 'Нет активных заказов' : 'Нет заказов с этим статусом'}
            </p>
          </div>
        ) : (
          filteredOrders.map(order => (
            <div key={order.id} className="glass-card p-5 card-shimmer">
              <div className="flex justify-between items-start mb-4">
                <div>
                  <div className="flex items-center gap-2 mb-2">
                    <span className="font-bold text-lg text-luxury-cream">Заказ #{order.id}</span>
                    <span className="badge-glass border-luxury-gold/40">
                      <span className="text-luxury-gold text-xs">
                        {ORDER_STATUSES[order.status]?.icon} {ORDER_STATUSES[order.status]?.label}
                      </span>
                    </span>
                  </div>
                  <div className="text-sm text-luxury-cream/60">
                    Стол #{order.table_id} • {new Date(order.created_at).toLocaleTimeString('ru-RU')}
                  </div>
                </div>
                <div className="text-right">
                  <div className="font-bold text-xl text-luxury-gold">{order.total_amount}₽</div>
                  {order.tips_amount > 0 && (
                    <div className="text-sm text-green-400 mt-1">+{order.tips_amount}₽ чаевые</div>
                  )}
                </div>
              </div>

              <div className="glass-card p-3 mb-4 space-y-2">
                {order.items?.map(item => (
                  <div key={item.id} className="flex justify-between text-sm">
                    <span className="text-luxury-cream/80">{item.quantity}x Блюдо #{item.dish_id}</span>
                    <span className="text-luxury-gold font-semibold">{item.total}₽</span>
                  </div>
                ))}
              </div>

              {ORDER_STATUSES[order.status]?.next ? (
                <button
                  onClick={() => updateOrderStatus(order.id, ORDER_STATUSES[order.status].next)}
                  className="btn-luxury w-full py-3"
                >
                  {ORDER_STATUSES[ORDER_STATUSES[order.status].next]?.icon} → {ORDER_STATUSES[ORDER_STATUSES[order.status].next]?.label}
                </button>
              ) : (
                <div className="text-center text-green-400 font-semibold py-3 glass-card">
                  ✓ Заказ завершён
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  )
}
