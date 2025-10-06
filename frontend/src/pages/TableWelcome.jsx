import { useEffect, useState } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import axios from 'axios'

export default function TableWelcome() {
  const { shortCode } = useParams()
  const [tableInfo, setTableInfo] = useState(null)
  const [restaurant, setRestaurant] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const navigate = useNavigate()

  useEffect(() => {
    const fetchTableInfo = async () => {
      try {
        const response = await axios.get(`/api/t/${shortCode}`)
        setTableInfo(response.data)
        
        // Сохранить в localStorage
        localStorage.setItem('current_table', JSON.stringify(response.data))
        
        // Получить информацию о ресторане
        const restResponse = await axios.get(`/api/restaurants/${response.data.restaurant_id}`)
        setRestaurant(restResponse.data)
      } catch (err) {
        console.error('Error:', err)
        setError('Неверная ссылка или стол не найден')
      } finally {
        setLoading(false)
      }
    }

    fetchTableInfo()
  }, [shortCode])

  const handleGuestMode = () => {
    localStorage.setItem('guest_mode', 'true')
    navigate(`/guest-menu/${tableInfo.restaurant_id}`)
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 flex items-center justify-center">
        <div className="text-white text-2xl animate-pulse">Загрузка...</div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-red-500 to-pink-500 flex items-center justify-center p-4">
        <div className="bg-white/10 backdrop-blur-xl rounded-3xl p-8 text-center max-w-md">
          <div className="text-6xl mb-4">❌</div>
          <h1 className="text-2xl font-bold text-white mb-4">{error}</h1>
          <Link to="/" className="text-white underline hover:no-underline">
            На главную
          </Link>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-luxury-pattern relative overflow-hidden">
      {/* Animated Background Orbs */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-luxury-gold/10 rounded-full blur-3xl animate-float"></div>
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-luxury-gold/10 rounded-full blur-3xl animate-float-delayed"></div>
      </div>

      <div className="relative min-h-screen flex flex-col items-center justify-center p-6">
        {/* Restaurant Logo */}
        {restaurant?.logo_url && (
          <div className="mb-8">
            <img src={restaurant.logo_url} alt={restaurant.name} className="w-24 h-24 object-contain" />
          </div>
        )}

        <div className="glass-card card-shimmer p-10 max-w-md w-full">
          <div className="text-center mb-8">
            <div className="text-6xl mb-4">🍽️</div>
            <h1 className="section-title mb-2">
              {restaurant?.name || 'Добро пожаловать!'}
            </h1>

            {/* Table Info Badge */}
            <div className="mt-6 glass-card p-5">
              <p className="text-luxury-gold text-2xl font-bold mb-1">
                Стол #{tableInfo?.table_number}
              </p>
              <div className="flex items-center justify-center gap-4 mt-3 text-luxury-cream/70 text-sm">
                <div className="flex items-center gap-1">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                  </svg>
                  <span>Мест: {tableInfo?.capacity}</span>
                </div>
                {tableInfo?.is_vip && (
                  <span className="badge-glass border-luxury-gold/40">
                    <span className="text-luxury-gold text-xs">⭐ VIP</span>
                  </span>
                )}
              </div>
            </div>
          </div>

          {/* Reservation Warning */}
          {tableInfo?.status === 'reserved' && (
            <div className="mb-6 glass-card p-4 border-orange-500/30">
              <div className="flex items-center gap-2 text-orange-400">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
                <span className="text-sm font-medium">Стол зарезервирован</span>
              </div>
            </div>
          )}

          <div className="space-y-3">
            {/* Guest Mode */}
            <button
              onClick={handleGuestMode}
              className="btn-luxury w-full py-4 text-base"
            >
              Продолжить как гость
            </button>

            {/* Login */}
            <Link
              to="/login"
              state={{ from: `/t/${shortCode}` }}
              className="btn-outline-gold w-full py-4 text-base block text-center"
            >
              Войти в аккаунт
            </Link>

            {/* Register */}
            <Link
              to="/register"
              state={{ from: `/t/${shortCode}` }}
              className="block w-full py-4 glass-card text-luxury-cream text-center rounded-xl font-medium hover:bg-white/10 transition-all"
            >
              Зарегистрироваться
            </Link>
          </div>

          {/* Info Box */}
          <div className="mt-8 glass-card p-4">
            <p className="text-luxury-cream/60 text-xs text-center leading-relaxed">
              <span className="text-luxury-gold">💡</span> Гости могут просматривать меню и вызывать официанта.<br />
              <span className="font-semibold text-luxury-cream/80">Войдите</span> для заказов, оплаты и бонусов.
            </p>
          </div>
        </div>

        {/* Restaurant Info Footer */}
        {restaurant && (
          <div className="mt-6 text-center text-luxury-cream/50 text-sm">
            {restaurant.address && <p>{restaurant.address}</p>}
            {restaurant.phone && <p className="mt-1">{restaurant.phone}</p>}
          </div>
        )}
      </div>
    </div>
  )
}
