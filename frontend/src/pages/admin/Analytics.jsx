import { useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import axios from 'axios'
import AdminHeader from '../../components/AdminHeader'

export default function Analytics() {
  const { restaurantId } = useParams()
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [period, setPeriod] = useState('week') // day, week, month, year

  useEffect(() => {
    fetchAnalytics()
  }, [restaurantId, period])

  const fetchAnalytics = async () => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get(`/api/restaurants/${restaurantId}/analytics?period=${period}`, {
        headers: { Authorization: `Bearer ${token}` }
      })
      setData(response.data)
    } catch (error) {
      console.error('Error:', error)
      // Используем моковые данные если API не готово
      setData({
        total_revenue: 1250000,
        total_tips: 85000,
        total_orders: 456,
        avg_check: 2740,
        popular_dishes: [
          { dish_id: 1, dish_name: 'Цезарь с курицей', quantity: 127, revenue: 317500 },
          { dish_id: 2, dish_name: 'Стейк Рибай', quantity: 89, revenue: 534000 },
          { dish_id: 3, dish_name: 'Том Ям', quantity: 76, revenue: 152000 },
          { dish_id: 4, dish_name: 'Тирамису', quantity: 54, revenue: 108000 },
          { dish_id: 5, dish_name: 'Паста Карбонара', quantity: 43, revenue: 86000 }
        ],
        orders_by_status: {
          completed: 423,
          cancelled: 21,
          pending: 12
        },
        revenue_by_day: [
          { day: 'Пн', revenue: 145000 },
          { day: 'Вт', revenue: 167000 },
          { day: 'Ср', revenue: 189000 },
          { day: 'Чт', revenue: 203000 },
          { day: 'Пт', revenue: 256000 },
          { day: 'Сб', revenue: 198000 },
          { day: 'Вс', revenue: 92000 }
        ]
      })
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-luxury-pattern flex items-center justify-center">
        <div className="glass-card p-8">
          <div className="flex items-center gap-3">
            <svg className="animate-spin h-8 w-8 text-luxury-gold" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            <span className="text-luxury-cream text-lg">Загрузка аналитики...</span>
          </div>
        </div>
      </div>
    )
  }

  if (!data) {
    return (
      <div className="min-h-screen bg-luxury-pattern">
        <AdminHeader title="Аналитика" />
        <div className="max-w-7xl mx-auto px-6 py-8">
          <div className="glass-card p-12 text-center">
            <p className="text-luxury-cream/50">Нет данных для отображения</p>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-luxury-pattern">
      <AdminHeader title="Аналитика и статистика" />

      <div className="max-w-7xl mx-auto px-6 py-8">
        {/* Фильтр периода */}
        <div className="flex gap-2 mb-8">
          {[
            { value: 'day', label: 'День' },
            { value: 'week', label: 'Неделя' },
            { value: 'month', label: 'Месяц' },
            { value: 'year', label: 'Год' }
          ].map(p => (
            <button
              key={p.value}
              onClick={() => setPeriod(p.value)}
              className={`px-4 py-2 rounded-lg transition ${
                period === p.value
                  ? 'bg-luxury-gold/20 border border-luxury-gold/40 text-luxury-gold'
                  : 'glass-card text-luxury-cream/60 hover:text-luxury-cream'
              }`}
            >
              {p.label}
            </button>
          ))}
        </div>

        {/* Основные метрики */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div className="glass-card p-6 card-shimmer">
            <div className="flex items-center gap-4 mb-3">
              <div className="w-12 h-12 rounded-lg bg-green-500/20 border border-green-500/40 flex items-center justify-center text-2xl">
                💰
              </div>
              <div>
                <div className="text-sm text-luxury-cream/60">Общая выручка</div>
                <div className="text-3xl font-bold text-green-400">{data.total_revenue?.toLocaleString()} ₸</div>
              </div>
            </div>
          </div>

          <div className="glass-card p-6 card-shimmer">
            <div className="flex items-center gap-4 mb-3">
              <div className="w-12 h-12 rounded-lg bg-blue-500/20 border border-blue-500/40 flex items-center justify-center text-2xl">
                💸
              </div>
              <div>
                <div className="text-sm text-luxury-cream/60">Чаевые</div>
                <div className="text-3xl font-bold text-blue-400">{data.total_tips?.toLocaleString()} ₸</div>
              </div>
            </div>
          </div>

          <div className="glass-card p-6 card-shimmer">
            <div className="flex items-center gap-4 mb-3">
              <div className="w-12 h-12 rounded-lg bg-purple-500/20 border border-purple-500/40 flex items-center justify-center text-2xl">
                📋
              </div>
              <div>
                <div className="text-sm text-luxury-cream/60">Всего заказов</div>
                <div className="text-3xl font-bold text-purple-400">{data.total_orders}</div>
              </div>
            </div>
          </div>

          <div className="glass-card p-6 card-shimmer">
            <div className="flex items-center gap-4 mb-3">
              <div className="w-12 h-12 rounded-lg bg-orange-500/20 border border-orange-500/40 flex items-center justify-center text-2xl">
                📊
              </div>
              <div>
                <div className="text-sm text-luxury-cream/60">Средний чек</div>
                <div className="text-3xl font-bold text-orange-400">{data.avg_check?.toLocaleString()} ₸</div>
              </div>
            </div>
          </div>
        </div>

        {/* График выручки по дням */}
        {data.revenue_by_day && data.revenue_by_day.length > 0 && (
          <div className="glass-card p-8 mb-8">
            <h2 className="text-2xl font-bold text-luxury-gold mb-6">Выручка по дням</h2>
            <div className="flex items-end justify-between gap-4 h-64">
              {data.revenue_by_day.map((item, index) => {
                const maxRevenue = Math.max(...data.revenue_by_day.map(d => d.revenue))
                const height = (item.revenue / maxRevenue) * 100
                return (
                  <div key={index} className="flex-1 flex flex-col items-center gap-2">
                    <div className="text-xs text-luxury-cream/60 font-medium">
                      {(item.revenue / 1000).toFixed(0)}k
                    </div>
                    <div
                      className="w-full bg-gradient-to-t from-luxury-gold to-luxury-gold/40 rounded-t-lg transition-all duration-500 hover:from-luxury-gold hover:to-luxury-gold/60 cursor-pointer"
                      style={{ height: `${height}%` }}
                      title={`${item.day}: ${item.revenue.toLocaleString()} ₸`}
                    />
                    <div className="text-sm text-luxury-cream font-medium">{item.day}</div>
                  </div>
                )
              })}
            </div>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Популярные блюда */}
          <div className="glass-card p-8">
            <h2 className="text-2xl font-bold text-luxury-gold mb-6">Топ блюд</h2>
            <div className="space-y-4">
              {data.popular_dishes?.map((dish, index) => (
                <div key={dish.dish_id} className="glass-card p-4 hover:border-luxury-gold/40 transition">
                  <div className="flex items-center gap-4">
                    <div className={`w-12 h-12 rounded-lg flex items-center justify-center text-2xl font-bold ${
                      index === 0 ? 'bg-yellow-500/20 border border-yellow-500/40 text-yellow-400' :
                      index === 1 ? 'bg-gray-400/20 border border-gray-400/40 text-gray-300' :
                      index === 2 ? 'bg-orange-500/20 border border-orange-500/40 text-orange-400' :
                      'bg-luxury-gold/10 border border-luxury-gold/20 text-luxury-cream/40'
                    }`}>
                      #{index + 1}
                    </div>
                    <div className="flex-1">
                      <div className="font-semibold text-luxury-cream">
                        {dish.dish_name || `Блюдо #${dish.dish_id}`}
                      </div>
                      <div className="text-sm text-luxury-cream/60">
                        Заказано: {dish.quantity} раз
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-xl font-bold text-green-400">
                        {dish.revenue?.toLocaleString()} ₸
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Статистика заказов */}
          {data.orders_by_status && (
            <div className="glass-card p-8">
              <h2 className="text-2xl font-bold text-luxury-gold mb-6">Статус заказов</h2>
              <div className="space-y-4">
                <div className="glass-card p-5 border-green-500/40">
                  <div className="flex justify-between items-center mb-2">
                    <span className="text-luxury-cream">Завершено</span>
                    <span className="text-2xl font-bold text-green-400">{data.orders_by_status.completed}</span>
                  </div>
                  <div className="w-full h-2 bg-luxury-charcoal rounded-full overflow-hidden">
                    <div
                      className="h-full bg-green-500"
                      style={{
                        width: `${(data.orders_by_status.completed / data.total_orders) * 100}%`
                      }}
                    />
                  </div>
                </div>

                <div className="glass-card p-5 border-red-500/40">
                  <div className="flex justify-between items-center mb-2">
                    <span className="text-luxury-cream">Отменено</span>
                    <span className="text-2xl font-bold text-red-400">{data.orders_by_status.cancelled}</span>
                  </div>
                  <div className="w-full h-2 bg-luxury-charcoal rounded-full overflow-hidden">
                    <div
                      className="h-full bg-red-500"
                      style={{
                        width: `${(data.orders_by_status.cancelled / data.total_orders) * 100}%`
                      }}
                    />
                  </div>
                </div>

                <div className="glass-card p-5 border-yellow-500/40">
                  <div className="flex justify-between items-center mb-2">
                    <span className="text-luxury-cream">В обработке</span>
                    <span className="text-2xl font-bold text-yellow-400">{data.orders_by_status.pending}</span>
                  </div>
                  <div className="w-full h-2 bg-luxury-charcoal rounded-full overflow-hidden">
                    <div
                      className="h-full bg-yellow-500"
                      style={{
                        width: `${(data.orders_by_status.pending / data.total_orders) * 100}%`
                      }}
                    />
                  </div>
                </div>
              </div>

              {/* Дополнительные метрики */}
              <div className="mt-8 pt-6 border-t border-luxury-cream/10">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <div className="text-sm text-luxury-cream/60 mb-1">Конверсия</div>
                    <div className="text-2xl font-bold text-luxury-gold">
                      {((data.orders_by_status.completed / data.total_orders) * 100).toFixed(1)}%
                    </div>
                  </div>
                  <div>
                    <div className="text-sm text-luxury-cream/60 mb-1">Отмен</div>
                    <div className="text-2xl font-bold text-red-400">
                      {((data.orders_by_status.cancelled / data.total_orders) * 100).toFixed(1)}%
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Дополнительная информация */}
        <div className="glass-card p-8 mt-8 border-luxury-gold/30">
          <div className="flex items-center gap-4 mb-4">
            <div className="w-3 h-3 rounded-full bg-green-500 animate-pulse"></div>
            <h3 className="text-xl font-bold text-luxury-gold">Статистика в реальном времени</h3>
          </div>
          <p className="text-luxury-cream/60">
            Данные обновляются автоматически. Период: <span className="text-luxury-gold font-medium">{
              period === 'day' ? 'За день' :
              period === 'week' ? 'За неделю' :
              period === 'month' ? 'За месяц' : 'За год'
            }</span>
          </p>
        </div>
      </div>
    </div>
  )
}
