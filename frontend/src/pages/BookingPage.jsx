import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import axios from 'axios'

export default function BookingPage() {
  const navigate = useNavigate()
  const { restaurantId } = useParams()
  const [restaurant, setRestaurant] = useState(null)
  const [zones, setZones] = useState([])
  const [loading, setLoading] = useState(true)

  const [formData, setFormData] = useState({
    guest_name: '',
    guest_phone: '',
    guest_email: '',
    guest_count: 2,
    reservation_date: '',
    reservation_time: '',
    zone_id: null,
    special_requests: ''
  })

  const [errors, setErrors] = useState({})
  const [submitting, setSubmitting] = useState(false)

  useEffect(() => {
    fetchRestaurantData()
  }, [restaurantId])

  const fetchRestaurantData = async () => {
    try {
      const restResponse = await axios.get(`/api/restaurants/${restaurantId}`)
      setRestaurant(restResponse.data)

      // Fetch zones
      const zonesResponse = await axios.get(`/api/restaurants/${restaurantId}/zones`)
      setZones(zonesResponse.data || [])
    } catch (error) {
      console.error('Error fetching data:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setSubmitting(true)
    setErrors({})

    try {
      const token = localStorage.getItem('token')
      const response = await axios.post(`/api/reservations`, {
        restaurant_id: parseInt(restaurantId),
        ...formData,
        guest_count: parseInt(formData.guest_count)
      }, {
        headers: token ? { Authorization: `Bearer ${token}` } : {}
      })

      // Success
      alert(`✅ Бронь создана! Код брони: ${response.data.booking_code}`)
      navigate(-1)
    } catch (error) {
      console.error('Error creating reservation:', error)
      if (error.response?.data?.detail) {
        setErrors({ form: error.response.data.detail })
      } else {
        setErrors({ form: 'Ошибка при создании брони' })
      }
    } finally {
      setSubmitting(false)
    }
  }

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData(prev => ({ ...prev, [name]: value }))
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
            <span className="text-luxury-cream text-lg">Загрузка...</span>
          </div>
        </div>
      </div>
    )
  }

  if (!restaurant?.booking_enabled) {
    return (
      <div className="min-h-screen bg-luxury-pattern flex items-center justify-center p-6">
        <div className="glass-card p-8 max-w-md text-center">
          <div className="text-5xl mb-4">📅</div>
          <h2 className="text-2xl font-bold text-luxury-cream mb-2">Бронирование недоступно</h2>
          <p className="text-luxury-cream/60 mb-6">
            В данном заведении онлайн-бронирование временно отключено
          </p>
          <button onClick={() => navigate(-1)} className="btn-luxury px-8 py-3">
            Назад
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-luxury-pattern pb-24">
      {/* Header */}
      <header className="glass-card rounded-none border-x-0 border-t-0 sticky top-0 z-20">
        <div className="px-6 py-5">
          <div className="flex items-center gap-4">
            <button
              onClick={() => navigate(-1)}
              className="w-10 h-10 rounded-xl glass-card flex items-center justify-center"
            >
              <svg className="w-6 h-6 text-luxury-gold" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </button>
            <div>
              <h1 className="text-2xl font-bold text-luxury-gold">Бронирование</h1>
              <p className="text-luxury-cream/60 text-sm">{restaurant?.name}</p>
            </div>
          </div>
        </div>
      </header>

      <div className="px-6 py-8 max-w-2xl mx-auto">
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Guest Info */}
          <div className="glass-card p-6">
            <h3 className="text-lg font-bold text-luxury-cream mb-4">Контактные данные</h3>

            <div className="space-y-4">
              <div>
                <label className="block text-luxury-cream/80 text-sm mb-2">Ваше имя *</label>
                <input
                  type="text"
                  name="guest_name"
                  value={formData.guest_name}
                  onChange={handleChange}
                  required
                  className="input-glass w-full"
                  placeholder="Иван Иванов"
                />
              </div>

              <div>
                <label className="block text-luxury-cream/80 text-sm mb-2">Телефон *</label>
                <input
                  type="tel"
                  name="guest_phone"
                  value={formData.guest_phone}
                  onChange={handleChange}
                  required
                  className="input-glass w-full"
                  placeholder="+7 (777) 123-45-67"
                />
              </div>

              <div>
                <label className="block text-luxury-cream/80 text-sm mb-2">Email (опционально)</label>
                <input
                  type="email"
                  name="guest_email"
                  value={formData.guest_email}
                  onChange={handleChange}
                  className="input-glass w-full"
                  placeholder="example@mail.com"
                />
              </div>
            </div>
          </div>

          {/* Date & Time */}
          <div className="glass-card p-6">
            <h3 className="text-lg font-bold text-luxury-cream mb-4">Дата и время</h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-luxury-cream/80 text-sm mb-2">Дата *</label>
                <input
                  type="date"
                  name="reservation_date"
                  value={formData.reservation_date}
                  onChange={handleChange}
                  required
                  min={new Date().toISOString().split('T')[0]}
                  max={new Date(Date.now() + (restaurant.booking_horizon_days || 30) * 24 * 60 * 60 * 1000).toISOString().split('T')[0]}
                  className="input-glass w-full"
                />
              </div>

              <div>
                <label className="block text-luxury-cream/80 text-sm mb-2">Время *</label>
                <input
                  type="time"
                  name="reservation_time"
                  value={formData.reservation_time}
                  onChange={handleChange}
                  required
                  className="input-glass w-full"
                />
              </div>
            </div>

            <div className="mt-4">
              <label className="block text-luxury-cream/80 text-sm mb-2">Количество гостей *</label>
              <input
                type="number"
                name="guest_count"
                value={formData.guest_count}
                onChange={handleChange}
                required
                min="1"
                max={restaurant.booking_max_party_size || 20}
                className="input-glass w-full"
              />
            </div>
          </div>

          {/* Zone Selection */}
          {zones.length > 0 && (
            <div className="glass-card p-6">
              <h3 className="text-lg font-bold text-luxury-cream mb-4">Предпочтительная зона</h3>

              <div className="grid grid-cols-2 gap-3">
                {zones.map(zone => (
                  <button
                    key={zone.id}
                    type="button"
                    onClick={() => setFormData(prev => ({ ...prev, zone_id: zone.id }))}
                    className={`glass-card p-4 text-left transition-all ${
                      formData.zone_id === zone.id
                        ? 'border-luxury-gold/50 bg-luxury-gold/10'
                        : 'hover:border-luxury-gold/30'
                    }`}
                  >
                    <div className="flex items-center gap-2 mb-1">
                      <div
                        className="w-3 h-3 rounded-full"
                        style={{ backgroundColor: zone.color || '#D4AF37' }}
                      ></div>
                      <span className="font-semibold text-luxury-cream">{zone.name}</span>
                    </div>
                    {zone.is_vip && (
                      <span className="text-xs text-luxury-gold">⭐ VIP</span>
                    )}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Special Requests */}
          <div className="glass-card p-6">
            <h3 className="text-lg font-bold text-luxury-cream mb-4">Особые пожелания</h3>
            <textarea
              name="special_requests"
              value={formData.special_requests}
              onChange={handleChange}
              rows={3}
              className="input-glass w-full"
              placeholder="Детский стульчик, аллергии, предпочтения..."
            ></textarea>
          </div>

          {/* Error */}
          {errors.form && (
            <div className="glass-card p-4 border-red-500/30">
              <p className="text-red-400 text-sm">{errors.form}</p>
            </div>
          )}

          {/* Submit */}
          <button
            type="submit"
            disabled={submitting}
            className="btn-luxury w-full py-4 text-lg disabled:opacity-50"
          >
            {submitting ? 'Создание брони...' : 'Забронировать стол'}
          </button>

          {/* Info */}
          <div className="glass-card p-4">
            <p className="text-luxury-cream/60 text-xs text-center">
              После создания брони вам придет SMS с кодом подтверждения
            </p>
          </div>
        </form>
      </div>
    </div>
  )
}
