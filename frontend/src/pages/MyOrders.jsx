import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'

const ORDER_STATUSES = {
  pending: { label: 'Ожидает', color: 'bg-gray-500' },
  accepted: { label: 'Принят', color: 'bg-blue-500' },
  cooking: { label: 'Готовится', color: 'bg-yellow-500' },
  ready: { label: 'Готов', color: 'bg-orange-500' },
  serving: { label: 'Несут', color: 'bg-purple-500' },
  completed: { label: 'Подан', color: 'bg-green-500' },
  cancelled: { label: 'Отменен', color: 'bg-red-500' }
}

export default function MyOrders() {
  const navigate = useNavigate()
  const [orders, setOrders] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchOrders()
  }, [])

  const fetchOrders = async () => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get('/api/my-orders', {
        headers: { Authorization: `Bearer ${token}` }
      })
      setOrders(response.data)
      setLoading(false)
    } catch (error) {
      console.error('Error:', error)
      setLoading(false)
    }
  }

  if (loading) {
    return <div className="min-h-screen flex items-center justify-center">Загрузка...</div>
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow-sm p-4 flex items-center gap-4">
        <button onClick={() => navigate(-1)} className="text-2xl">←</button>
        <h1 className="text-xl font-bold">Мои заказы</h1>
      </header>

      <div className="p-4 space-y-4">
        {orders.length === 0 ? (
          <div className="text-center py-12 text-gray-500">
            У вас пока нет заказов
          </div>
        ) : (
          orders.map(order => (
            <div key={order.id} className="bg-white rounded-xl shadow-md p-4">
              <div className="flex justify-between items-start mb-3">
                <div>
                  <div className="text-sm text-gray-500">
                    {new Date(order.created_at).toLocaleString('ru-RU')}
                  </div>
                  <div className="font-bold text-lg">
                    Заказ #{order.id}
                  </div>
                </div>
                <span className={`px-3 py-1 rounded-full text-white text-sm ${ORDER_STATUSES[order.status]?.color}`}>
                  {ORDER_STATUSES[order.status]?.label}
                </span>
              </div>

              <div className="space-y-2 mb-3">
                {order.items?.map(item => (
                  <div key={item.id} className="flex justify-between text-sm">
                    <span>{item.quantity}x Блюдо #{item.dish_id}</span>
                    <span>{item.total} ₸</span>
                  </div>
                ))}
              </div>

              <div className="border-t pt-3 flex justify-between font-bold">
                <span>Итого:</span>
                <span>{(order.total_amount + order.tips_amount + order.service_fee).toFixed(0)} ₸</span>
              </div>

              {order.is_paid && (
                <div className="mt-2 text-sm text-green-600">✓ Оплачено</div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  )
}
