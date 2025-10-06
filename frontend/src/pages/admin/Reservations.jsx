import { useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import axios from 'axios'
import AdminHeader from '../../components/AdminHeader'

const STATUSES = {
  draft: { label: 'Черновик', color: 'bg-gray-500/20 border-gray-500/40 text-gray-400' },
  pending: { label: 'Ожидает', color: 'bg-yellow-500/20 border-yellow-500/40 text-yellow-400' },
  confirmed: { label: 'Подтверждено', color: 'bg-blue-500/20 border-blue-500/40 text-blue-400' },
  awaiting: { label: 'Ожидает прибытия', color: 'bg-cyan-500/20 border-cyan-500/40 text-cyan-400' },
  checked_in: { label: 'Прибыл', color: 'bg-green-500/20 border-green-500/40 text-green-400' },
  seated: { label: 'Посажен', color: 'bg-purple-500/20 border-purple-500/40 text-purple-400' },
  no_show: { label: 'Не пришёл', color: 'bg-red-500/20 border-red-500/40 text-red-400' },
  cancelled: { label: 'Отменено', color: 'bg-gray-500/20 border-gray-500/40 text-gray-400' },
  completed: { label: 'Завершено', color: 'bg-green-600/20 border-green-600/40 text-green-400' }
}

export default function Reservations() {
  const { restaurantId } = useParams()
  const [reservations, setReservations] = useState([])
  const [tables, setTables] = useState([])
  const [zones, setZones] = useState([])
  const [showForm, setShowForm] = useState(false)
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('all') // all, today, upcoming

  useEffect(() => {
    fetchReservations()
    fetchTables()
    fetchZones()
  }, [restaurantId])

  const fetchReservations = async () => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get(`/api/restaurants/${restaurantId}/reservations`, {
        headers: { Authorization: `Bearer ${token}` }
      })
      setReservations(response.data)
    } catch (error) {
      console.error('Error:', error)
    } finally {
      setLoading(false)
    }
  }

  const fetchTables = async () => {
    try {
      const token = localStorage.getItem('token')
      const hallsRes = await axios.get(`/api/restaurants/${restaurantId}/halls`, {
        headers: { Authorization: `Bearer ${token}` }
      })

      const allTables = []
      for (const hall of hallsRes.data) {
        const tablesRes = await axios.get(`/api/halls/${hall.id}/tables`, {
          headers: { Authorization: `Bearer ${token}` }
        })
        allTables.push(...tablesRes.data.map(t => ({ ...t, hall_name: hall.name })))
      }
      setTables(allTables)
    } catch (error) {
      console.error('Error:', error)
    }
  }

  const fetchZones = async () => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get(`/api/restaurants/${restaurantId}/zones`, {
        headers: { Authorization: `Bearer ${token}` }
      })
      setZones(response.data)
    } catch (error) {
      console.error('Error:', error)
    }
  }

  const createReservation = async (data) => {
    try {
      const token = localStorage.getItem('token')
      await axios.post('/api/reservations', {
        ...data,
        restaurant_id: parseInt(restaurantId)
      }, {
        headers: { Authorization: `Bearer ${token}` }
      })
      fetchReservations()
      setShowForm(false)
    } catch (error) {
      console.error('Error:', error)
      alert('Ошибка создания бронирования')
    }
  }

  const updateStatus = async (id, status) => {
    try {
      const token = localStorage.getItem('token')
      await axios.patch(`/api/reservations/${id}/status?status=${status}`, {}, {
        headers: { Authorization: `Bearer ${token}` }
      })
      fetchReservations()
    } catch (error) {
      console.error('Error:', error)
    }
  }

  const filteredReservations = reservations.filter(res => {
    if (filter === 'all') return true
    const resDate = new Date(res.reservation_date)
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    if (filter === 'today') {
      return resDate.toDateString() === today.toDateString()
    }
    if (filter === 'upcoming') {
      return resDate >= today
    }
    return true
  })

  if (loading) {
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
    <div className="min-h-screen bg-luxury-pattern">
      <AdminHeader title="Бронирования" />

      <div className="max-w-7xl mx-auto px-6 py-8">
        {/* Фильтры и кнопка создания */}
        <div className="flex flex-wrap justify-between items-center gap-4 mb-8">
          <div className="flex gap-2">
            <button
              onClick={() => setFilter('all')}
              className={`px-4 py-2 rounded-lg transition ${
                filter === 'all'
                  ? 'bg-luxury-gold/20 border border-luxury-gold/40 text-luxury-gold'
                  : 'glass-card text-luxury-cream/60 hover:text-luxury-cream'
              }`}
            >
              Все
            </button>
            <button
              onClick={() => setFilter('today')}
              className={`px-4 py-2 rounded-lg transition ${
                filter === 'today'
                  ? 'bg-luxury-gold/20 border border-luxury-gold/40 text-luxury-gold'
                  : 'glass-card text-luxury-cream/60 hover:text-luxury-cream'
              }`}
            >
              Сегодня
            </button>
            <button
              onClick={() => setFilter('upcoming')}
              className={`px-4 py-2 rounded-lg transition ${
                filter === 'upcoming'
                  ? 'bg-luxury-gold/20 border border-luxury-gold/40 text-luxury-gold'
                  : 'glass-card text-luxury-cream/60 hover:text-luxury-cream'
              }`}
            >
              Предстоящие
            </button>
          </div>

          <button
            onClick={() => setShowForm(true)}
            className="btn-luxury"
          >
            + Новое бронирование
          </button>
        </div>

        {/* Статистика */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          <div className="glass-card p-6">
            <div className="text-sm text-luxury-cream/60 mb-1">Всего</div>
            <div className="text-3xl font-bold text-luxury-gold">{reservations.length}</div>
          </div>
          <div className="glass-card p-6">
            <div className="text-sm text-luxury-cream/60 mb-1">Подтверждено</div>
            <div className="text-3xl font-bold text-blue-400">
              {reservations.filter(r => r.status === 'confirmed' || r.status === 'awaiting').length}
            </div>
          </div>
          <div className="glass-card p-6">
            <div className="text-sm text-luxury-cream/60 mb-1">Активных</div>
            <div className="text-3xl font-bold text-green-400">
              {reservations.filter(r => r.status === 'checked_in' || r.status === 'seated').length}
            </div>
          </div>
          <div className="glass-card p-6">
            <div className="text-sm text-luxury-cream/60 mb-1">Завершено</div>
            <div className="text-3xl font-bold text-luxury-cream/60">
              {reservations.filter(r => r.status === 'completed').length}
            </div>
          </div>
        </div>

        {/* Список бронирований */}
        <div className="space-y-4">
          {filteredReservations.map(res => (
            <div key={res.id} className="glass-card p-6 hover:border-luxury-gold/40 transition">
              <div className="flex flex-wrap justify-between items-start gap-4 mb-4">
                <div className="flex-1 min-w-[250px]">
                  <div className="flex items-start gap-3 mb-3">
                    <div className="w-12 h-12 rounded-lg bg-luxury-gold/20 border border-luxury-gold/30 flex items-center justify-center text-2xl">
                      👤
                    </div>
                    <div>
                      <h3 className="font-bold text-xl text-luxury-cream">{res.guest_name}</h3>
                      <p className="text-sm text-luxury-cream/60">{res.guest_phone}</p>
                      {res.guest_email && (
                        <p className="text-sm text-luxury-cream/60">{res.guest_email}</p>
                      )}
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-3 text-sm">
                    <div>
                      <span className="text-luxury-cream/60">📅 Дата:</span>
                      <span className="text-luxury-cream ml-2">
                        {new Date(res.reservation_date).toLocaleDateString('ru-RU')}
                      </span>
                    </div>
                    <div>
                      <span className="text-luxury-cream/60">⏰ Время:</span>
                      <span className="text-luxury-cream ml-2">
                        {new Date(res.reservation_time).toLocaleTimeString('ru-RU', {hour: '2-digit', minute: '2-digit'})}
                      </span>
                    </div>
                    <div>
                      <span className="text-luxury-cream/60">👥 Гостей:</span>
                      <span className="text-luxury-cream ml-2">{res.guest_count}</span>
                    </div>
                    {res.duration_minutes && (
                      <div>
                        <span className="text-luxury-cream/60">⏱️ Длительность:</span>
                        <span className="text-luxury-cream ml-2">{res.duration_minutes} мин</span>
                      </div>
                    )}
                  </div>

                  {res.booking_code && (
                    <div className="mt-3">
                      <span className="text-luxury-cream/60 text-sm">Код брони:</span>
                      <span className="ml-2 px-3 py-1 bg-luxury-gold/20 border border-luxury-gold/30 rounded text-luxury-gold font-mono text-sm">
                        {res.booking_code}
                      </span>
                    </div>
                  )}
                </div>

                <div className="flex flex-col items-end gap-3">
                  <span className={`px-4 py-2 rounded-lg text-sm font-medium border ${STATUSES[res.status]?.color || STATUSES.pending.color}`}>
                    {STATUSES[res.status]?.label || res.status}
                  </span>

                  {res.is_deposit_paid && (
                    <span className="px-3 py-1 bg-green-500/20 border border-green-500/40 text-green-400 rounded text-xs">
                      💰 Депозит оплачен
                    </span>
                  )}
                </div>
              </div>

              {res.special_requests && (
                <div className="glass-card p-4 mb-4">
                  <div className="text-sm text-luxury-cream/60 mb-1">Особые пожелания:</div>
                  <p className="text-luxury-cream">{res.special_requests}</p>
                </div>
              )}

              {/* Действия */}
              <div className="flex flex-wrap gap-2 pt-4 border-t border-luxury-cream/10">
                {res.status === 'pending' && (
                  <button
                    onClick={() => updateStatus(res.id, 'confirmed')}
                    className="px-4 py-2 bg-blue-500/20 border border-blue-500/40 text-blue-400 rounded-lg hover:bg-blue-500/30 transition text-sm"
                  >
                    ✓ Подтвердить
                  </button>
                )}
                {res.status === 'confirmed' && (
                  <button
                    onClick={() => updateStatus(res.id, 'awaiting')}
                    className="px-4 py-2 bg-cyan-500/20 border border-cyan-500/40 text-cyan-400 rounded-lg hover:bg-cyan-500/30 transition text-sm"
                  >
                    Ожидает прибытия
                  </button>
                )}
                {(res.status === 'confirmed' || res.status === 'awaiting') && (
                  <button
                    onClick={() => updateStatus(res.id, 'checked_in')}
                    className="px-4 py-2 bg-green-500/20 border border-green-500/40 text-green-400 rounded-lg hover:bg-green-500/30 transition text-sm"
                  >
                    ✓ Прибыл
                  </button>
                )}
                {res.status === 'checked_in' && (
                  <button
                    onClick={() => updateStatus(res.id, 'seated')}
                    className="px-4 py-2 bg-purple-500/20 border border-purple-500/40 text-purple-400 rounded-lg hover:bg-purple-500/30 transition text-sm"
                  >
                    🪑 Посадить за стол
                  </button>
                )}
                {res.status === 'seated' && (
                  <button
                    onClick={() => updateStatus(res.id, 'completed')}
                    className="px-4 py-2 bg-green-600/20 border border-green-600/40 text-green-400 rounded-lg hover:bg-green-600/30 transition text-sm"
                  >
                    ✓ Завершить
                  </button>
                )}
                {!['cancelled', 'completed', 'no_show'].includes(res.status) && (
                  <>
                    <button
                      onClick={() => updateStatus(res.id, 'no_show')}
                      className="px-4 py-2 bg-red-500/20 border border-red-500/40 text-red-400 rounded-lg hover:bg-red-500/30 transition text-sm"
                    >
                      ❌ Не пришёл
                    </button>
                    <button
                      onClick={() => updateStatus(res.id, 'cancelled')}
                      className="px-4 py-2 bg-gray-500/20 border border-gray-500/40 text-gray-400 rounded-lg hover:bg-gray-500/30 transition text-sm"
                    >
                      Отменить
                    </button>
                  </>
                )}
              </div>
            </div>
          ))}
        </div>

        {filteredReservations.length === 0 && (
          <div className="glass-card p-12 text-center">
            <p className="text-luxury-cream/50 mb-4">
              {filter === 'all' ? 'Нет бронирований' : `Нет бронирований для фильтра "${filter}"`}
            </p>
            <button
              onClick={() => setShowForm(true)}
              className="btn-outline-gold"
            >
              Создать первое бронирование
            </button>
          </div>
        )}

        {showForm && (
          <ReservationForm
            tables={tables}
            zones={zones}
            onSubmit={createReservation}
            onClose={() => setShowForm(false)}
          />
        )}
      </div>
    </div>
  )
}

function ReservationForm({ tables, zones, onSubmit, onClose }) {
  const [formData, setFormData] = useState({
    table_id: '',
    zone_id: '',
    guest_name: '',
    guest_phone: '',
    guest_email: '',
    guest_count: 2,
    reservation_date: new Date().toISOString().split('T')[0],
    reservation_time: '19:00',
    duration_minutes: 120,
    special_requests: '',
    deposit_amount: 0
  })

  return (
    <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4 z-50 overflow-y-auto">
      <div className="glass-card p-8 w-full max-w-2xl my-8">
        <h3 className="text-2xl font-bold text-luxury-gold mb-6">Новое бронирование</h3>
        <form onSubmit={(e) => {
          e.preventDefault()
          onSubmit({
            ...formData,
            table_id: formData.table_id ? parseInt(formData.table_id) : null,
            zone_id: formData.zone_id ? parseInt(formData.zone_id) : null,
            guest_count: parseInt(formData.guest_count),
            duration_minutes: parseInt(formData.duration_minutes),
            deposit_amount: parseFloat(formData.deposit_amount) || 0
          })
        }} className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-luxury-cream/60 mb-2">Имя гостя *</label>
              <input
                type="text"
                placeholder="Иван Иванов"
                value={formData.guest_name}
                onChange={e => setFormData({...formData, guest_name: e.target.value})}
                className="input-glass"
                required
              />
            </div>

            <div>
              <label className="block text-sm text-luxury-cream/60 mb-2">Телефон *</label>
              <input
                type="tel"
                placeholder="+7 777 123 4567"
                value={formData.guest_phone}
                onChange={e => setFormData({...formData, guest_phone: e.target.value})}
                className="input-glass"
                required
              />
            </div>
          </div>

          <div>
            <label className="block text-sm text-luxury-cream/60 mb-2">Email</label>
            <input
              type="email"
              placeholder="guest@example.com"
              value={formData.guest_email}
              onChange={e => setFormData({...formData, guest_email: e.target.value})}
              className="input-glass"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-luxury-cream/60 mb-2">Дата *</label>
              <input
                type="date"
                value={formData.reservation_date}
                onChange={e => setFormData({...formData, reservation_date: e.target.value})}
                className="input-glass"
                required
              />
            </div>

            <div>
              <label className="block text-sm text-luxury-cream/60 mb-2">Время *</label>
              <input
                type="time"
                value={formData.reservation_time}
                onChange={e => setFormData({...formData, reservation_time: e.target.value})}
                className="input-glass"
                required
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-luxury-cream/60 mb-2">Количество гостей *</label>
              <input
                type="number"
                placeholder="2"
                value={formData.guest_count}
                onChange={e => setFormData({...formData, guest_count: e.target.value})}
                className="input-glass"
                min="1"
                required
              />
            </div>

            <div>
              <label className="block text-sm text-luxury-cream/60 mb-2">Длительность (мин)</label>
              <input
                type="number"
                placeholder="120"
                value={formData.duration_minutes}
                onChange={e => setFormData({...formData, duration_minutes: e.target.value})}
                className="input-glass"
                min="30"
              />
            </div>
          </div>

          {zones.length > 0 && (
            <div>
              <label className="block text-sm text-luxury-cream/60 mb-2">Зона (опционально)</label>
              <select
                value={formData.zone_id}
                onChange={e => setFormData({...formData, zone_id: e.target.value})}
                className="input-glass"
              >
                <option value="">Без предпочтений</option>
                {zones.map(zone => (
                  <option key={zone.id} value={zone.id} className="bg-luxury-charcoal-light">
                    {zone.name} {zone.is_vip ? '⭐ VIP' : ''}
                  </option>
                ))}
              </select>
            </div>
          )}

          <div>
            <label className="block text-sm text-luxury-cream/60 mb-2">Стол (опционально)</label>
            <select
              value={formData.table_id}
              onChange={e => setFormData({...formData, table_id: e.target.value})}
              className="input-glass"
            >
              <option value="">Автоматический выбор</option>
              {tables.map(table => (
                <option key={table.id} value={table.id} className="bg-luxury-charcoal-light">
                  {table.hall_name} - Стол {table.table_number} ({table.capacity} мест)
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm text-luxury-cream/60 mb-2">Депозит (₸)</label>
            <input
              type="number"
              placeholder="0"
              value={formData.deposit_amount}
              onChange={e => setFormData({...formData, deposit_amount: e.target.value})}
              className="input-glass"
              min="0"
            />
          </div>

          <div>
            <label className="block text-sm text-luxury-cream/60 mb-2">Особые пожелания</label>
            <textarea
              placeholder="Аллергии, предпочтения по расположению и т.д."
              value={formData.special_requests}
              onChange={e => setFormData({...formData, special_requests: e.target.value})}
              className="input-glass"
              rows="3"
            />
          </div>

          <div className="flex gap-3 pt-4">
            <button type="submit" className="btn-luxury flex-1">
              Создать бронирование
            </button>
            <button type="button" onClick={onClose} className="btn-glass">
              Отмена
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
