import { useEffect, useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import axios from 'axios'

export default function Dashboard({ setToken }) {
  const [user, setUser] = useState(null)
  const [restaurant, setRestaurant] = useState(null)
  const [halls, setHalls] = useState([])
  const [tables, setTables] = useState([])
  const [selectedHall, setSelectedHall] = useState(null)
  const [showTableLinks, setShowTableLinks] = useState(false)
  const [generatedLinks, setGeneratedLinks] = useState({})
  const [generatingTable, setGeneratingTable] = useState(null)
  const navigate = useNavigate()

  useEffect(() => {
    const fetchUser = async () => {
      try {
        const token = localStorage.getItem('token')
        const response = await axios.get('/api/auth/me', {
          headers: { Authorization: `Bearer ${token}` }
        })
        setUser(response.data)

        if (response.data.role === 'waiter') {
          navigate('/waiter')
          return
        }

        if (response.data.restaurant_id) {
          const restResponse = await axios.get(`/api/restaurants/${response.data.restaurant_id}`, {
            headers: { Authorization: `Bearer ${token}` }
          })
          setRestaurant(restResponse.data)
          
          // Загрузить залы если админ
          if (response.data.role === 'admin') {
            fetchHalls(response.data.restaurant_id)
          }
        }
      } catch (error) {
        handleLogout()
      }
    }
    fetchUser()
  }, [])

  const fetchHalls = async (restaurantId) => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get(`/api/restaurants/${restaurantId}/halls`, {
        headers: { Authorization: `Bearer ${token}` }
      })
      setHalls(response.data)
      if (response.data.length > 0) {
        setSelectedHall(response.data[0].id)
        fetchTables(response.data[0].id)
      }
    } catch (err) {
      console.error('Error fetching halls:', err)
    }
  }

  const fetchTables = async (hallId) => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get(`/api/halls/${hallId}/tables`, {
        headers: { Authorization: `Bearer ${token}` }
      })
      setTables(response.data)
    } catch (err) {
      console.error('Error fetching tables:', err)
    }
  }

  const generateLink = async (tableId) => {
    setGeneratingTable(tableId)
    try {
      const token = localStorage.getItem('token')
      const response = await axios.post(
        `/api/restaurants/${user.restaurant_id}/halls/${selectedHall}/tables/${tableId}/generate-link`,
        {},
        { headers: { Authorization: `Bearer ${token}` } }
      )
      
      setGeneratedLinks({
        ...generatedLinks,
        [tableId]: response.data
      })
    } catch (err) {
      console.error('Error generating link:', err)
      alert('Ошибка генерации ссылки')
    } finally {
      setGeneratingTable(null)
    }
  }

  const copyLink = (link) => {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(link)
        .then(() => alert('Ссылка скопирована!'))
        .catch(() => {
          const textarea = document.createElement('textarea')
          textarea.value = link
          document.body.appendChild(textarea)
          textarea.select()
          document.execCommand('copy')
          document.body.removeChild(textarea)
          alert('Ссылка скопирована!')
        })
    } else {
      const textarea = document.createElement('textarea')
      textarea.value = link
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand('copy')
      document.body.removeChild(textarea)
      alert('Ссылка скопирована!')
    }
  }

  const handleLogout = () => {
    localStorage.removeItem('token')
    setToken(null)
    navigate('/login')
  }

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
    <div className="min-h-screen bg-luxury-pattern">
      {/* Animated background orbs */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-luxury-gold/5 rounded-full blur-3xl animate-float"></div>
        <div className="absolute bottom-1/3 right-1/3 w-96 h-96 bg-luxury-gold/5 rounded-full blur-3xl animate-float" style={{animationDelay: '3s'}}></div>
      </div>

      {/* Header */}
      <header className="relative glass-card rounded-none border-x-0 border-t-0">
        <div className="max-w-7xl mx-auto px-6 py-5">
          <div className="flex justify-between items-center">
            <div className="flex items-center gap-6">
              <div>
                <h1 className="text-3xl font-bold text-luxury-gold text-shadow-glow">Thanks</h1>
                {restaurant && (
                  <p className="text-luxury-cream/70 text-sm mt-1 tracking-wide">{restaurant.name}</p>
                )}
              </div>
            </div>
            <button
              onClick={handleLogout}
              className="btn-outline-gold px-6 py-2"
            >
              Выйти
            </button>
          </div>
        </div>
      </header>

      <main className="relative max-w-7xl mx-auto px-6 py-10">
        {/* User Profile Card */}
        <div className="glass-card p-8 mb-10 card-shimmer">
          <div className="flex items-center gap-6">
            <div className="w-20 h-20 rounded-2xl bg-luxury-gold/20 border border-luxury-gold/30 flex items-center justify-center">
              <span className="text-4xl">👤</span>
            </div>
            <div className="flex-1">
              <h2 className="text-2xl font-bold text-luxury-cream mb-1">{user.full_name || 'Пользователь'}</h2>
              <p className="text-luxury-cream/60 mb-3">{user.email}</p>
              <div className="inline-flex items-center gap-2 badge-glass border-luxury-gold/40">
                <div className="w-2 h-2 rounded-full bg-luxury-gold animate-pulse"></div>
                <span className="text-luxury-gold font-medium text-sm">{user.role.toUpperCase()}</span>
              </div>
            </div>
          </div>
        </div>

        {/* АДМИН - ГЕНЕРАЦИЯ ССЫЛОК */}
        {user.role === 'admin' && user.restaurant_id && (
          <div className="mb-8">
            <button
              onClick={() => setShowTableLinks(!showTableLinks)}
              className="w-full glass-card-hover p-8 text-left"
            >
              <div className="flex justify-between items-center">
                <div className="flex items-center gap-5">
                  <div className="w-16 h-16 rounded-xl bg-luxury-gold/20 border border-luxury-gold/30 flex items-center justify-center text-3xl">
                    🔗
                  </div>
                  <div>
                    <h3 className="text-2xl font-bold text-luxury-cream mb-1">Генерация ссылок для столов</h3>
                    <p className="text-luxury-cream/60">Создать QR-коды для гостей</p>
                  </div>
                </div>
                <svg
                  className={`w-7 h-7 text-luxury-gold transition-transform duration-300 ${showTableLinks ? 'rotate-180' : ''}`}
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                </svg>
              </div>
            </button>

            {showTableLinks && halls.length > 0 && (
              <div className="mt-6 glass-card p-8">
                <div className="mb-6">
                  <label className="block text-sm font-medium text-luxury-gold mb-3 tracking-wide">Выберите зал:</label>
                  <select
                    value={selectedHall || ''}
                    onChange={(e) => {
                      const hallId = Number(e.target.value)
                      setSelectedHall(hallId)
                      fetchTables(hallId)
                    }}
                    className="input-glass"
                  >
                    {halls.map(hall => (
                      <option key={hall.id} value={hall.id} className="bg-luxury-charcoal-light">{hall.name}</option>
                    ))}
                  </select>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  {tables.map(table => {
                    const link = generatedLinks[table.id]
                    const hasExistingLink = table.short_code
                    
                    return (
                      <div key={table.id} className="glass-card p-5 border-luxury-gold/20">
                        <div className="flex justify-between items-start mb-4">
                          <div>
                            <h4 className="font-bold text-lg text-luxury-cream">Стол #{table.table_number}</h4>
                            <p className="text-sm text-luxury-cream/60">Мест: {table.capacity}</p>
                          </div>
                          {hasExistingLink && (
                            <span className="badge-glass border-green-500/40">
                              <span className="text-green-400 text-xs">Активна</span>
                            </span>
                          )}
                        </div>

                        {link ? (
                          <div className="space-y-3">
                            <div className="p-3 glass-card text-xs break-all text-luxury-cream/80">
                              {link.link}
                            </div>
                            <button
                              onClick={() => copyLink(link.link)}
                              className="btn-luxury w-full py-2 text-sm"
                            >
                              📋 Скопировать
                            </button>
                            <p className="text-xs text-luxury-cream/50 text-center">Код: {link.short_code}</p>
                          </div>
                        ) : hasExistingLink ? (
                          <div className="space-y-3">
                            <div className="p-3 glass-card text-xs break-all text-luxury-cream/80">
                              http://217.11.74.100/t/{table.short_code}
                            </div>
                            <button
                              onClick={() => copyLink(`http://217.11.74.100/t/${table.short_code}`)}
                              className="btn-luxury w-full py-2 text-sm"
                            >
                              📋 Скопировать
                            </button>
                            <button
                              onClick={() => generateLink(table.id)}
                              disabled={generatingTable === table.id}
                              className="btn-glass w-full py-2 text-sm disabled:opacity-50"
                            >
                              {generatingTable === table.id ? '⏳ Генерация...' : '🔄 Перегенерировать'}
                            </button>
                          </div>
                        ) : (
                          <button
                            onClick={() => generateLink(table.id)}
                            disabled={generatingTable === table.id}
                            className="btn-outline-gold w-full py-3 disabled:opacity-50"
                          >
                            {generatingTable === table.id ? '⏳ Генерация...' : '✨ Сгенерировать ссылку'}
                          </button>
                        )}
                      </div>
                    )
                  })}
                </div>

                {tables.length === 0 && (
                  <p className="text-center text-luxury-cream/50 py-10">
                    В этом зале нет столов. Создайте столы в разделе "Залы".
                  </p>
                )}
              </div>
            )}

            {showTableLinks && halls.length === 0 && (
              <div className="mt-6 glass-card p-8 text-center">
                <p className="text-luxury-cream/60">У заведения нет залов. Создайте залы в разделе "Залы".</p>
              </div>
            )}
          </div>
        )}

        {/* КАРТОЧКИ ДЛЯ ПОЛЬЗОВАТЕЛЯ */}
        {user.role === 'user' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Link to="/my-orders" className="group block">
              <div className="glass-card-hover p-8">
                <div className="w-16 h-16 rounded-xl bg-luxury-gold/20 border border-luxury-gold/30 flex items-center justify-center text-4xl mb-5">
                  📋
                </div>
                <h3 className="text-2xl font-bold text-luxury-cream mb-2 group-hover:text-luxury-gold transition-colors">Мои заказы</h3>
                <p className="text-luxury-cream/60">История заказов</p>
              </div>
            </Link>
          </div>
        )}

        {/* КАРТОЧКИ ДЛЯ МОДЕРАТОРА */}
        {user.role === 'moderator' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Link to="/admin/restaurants" className="group block">
              <div className="glass-card-hover p-8">
                <div className="w-16 h-16 rounded-xl bg-luxury-gold/20 border border-luxury-gold/30 flex items-center justify-center text-4xl mb-5">
                  🏪
                </div>
                <h3 className="text-2xl font-bold text-luxury-cream mb-2 group-hover:text-luxury-gold transition-colors">Заведения</h3>
                <p className="text-luxury-cream/60">Управление ресторанами</p>
              </div>
            </Link>
          </div>
        )}

        {/* КАРТОЧКИ ДЛЯ АДМИНА/МОДЕРАТОРА/ВЛАДЕЛЬЦА */}
        {(user.role === 'admin' || user.role === 'moderator' || user.role === 'owner') && user.restaurant_id && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-6 mt-8">
            <Link to={`/admin/menu/${user.restaurant_id}`} className="group block">
              <div className="glass-card-hover p-6">
                <div className="w-14 h-14 rounded-xl bg-luxury-gold/20 border border-luxury-gold/30 flex items-center justify-center text-3xl mb-4">
                  📋
                </div>
                <h3 className="text-xl font-bold text-luxury-cream mb-1 group-hover:text-luxury-gold transition-colors">Меню</h3>
                <p className="text-luxury-cream/50 text-sm">Управление</p>
              </div>
            </Link>

            <Link to={`/admin/halls/${user.restaurant_id}`} className="group block">
              <div className="glass-card-hover p-6">
                <div className="w-14 h-14 rounded-xl bg-luxury-gold/20 border border-luxury-gold/30 flex items-center justify-center text-3xl mb-4">
                  🪑
                </div>
                <h3 className="text-xl font-bold text-luxury-cream mb-1 group-hover:text-luxury-gold transition-colors">Залы</h3>
                <p className="text-luxury-cream/50 text-sm">Столы и QR</p>
              </div>
            </Link>

            <Link to={`/admin/qr-generator/${user.restaurant_id}`} className="group block">
              <div className="glass-card-hover p-6">
                <div className="w-14 h-14 rounded-xl bg-luxury-gold/20 border border-luxury-gold/30 flex items-center justify-center text-3xl mb-4">
                  📱
                </div>
                <h3 className="text-xl font-bold text-luxury-cream mb-1 group-hover:text-luxury-gold transition-colors">QR-коды</h3>
                <p className="text-luxury-cream/50 text-sm">Генератор</p>
              </div>
            </Link>

            <Link to={`/admin/reservations/${user.restaurant_id}`} className="group block">
              <div className="glass-card-hover p-6">
                <div className="w-14 h-14 rounded-xl bg-luxury-gold/20 border border-luxury-gold/30 flex items-center justify-center text-3xl mb-4">
                  📅
                </div>
                <h3 className="text-xl font-bold text-luxury-cream mb-1 group-hover:text-luxury-gold transition-colors">Бронирования</h3>
                <p className="text-luxury-cream/50 text-sm">Управление</p>
              </div>
            </Link>

            <Link to={`/admin/analytics/${user.restaurant_id}`} className="group block">
              <div className="glass-card-hover p-6">
                <div className="w-14 h-14 rounded-xl bg-luxury-gold/20 border border-luxury-gold/30 flex items-center justify-center text-3xl mb-4">
                  📊
                </div>
                <h3 className="text-xl font-bold text-luxury-cream mb-1 group-hover:text-luxury-gold transition-colors">Аналитика</h3>
                <p className="text-luxury-cream/50 text-sm">Статистика</p>
              </div>
            </Link>
          </div>
        )}

        {/* STATUS CARD */}
        <div className="mt-10 glass-card p-8 border-luxury-gold/30 card-shimmer">
          <div className="flex items-center gap-4 mb-6">
            <div className="w-3 h-3 rounded-full bg-green-500 animate-pulse"></div>
            <h3 className="text-2xl font-bold text-luxury-gold">Система активна</h3>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="flex items-center gap-3">
              <span className="text-2xl">✓</span>
              <span className="text-luxury-cream/80">Все модули установлены</span>
            </div>
            <div className="flex items-center gap-3">
              <span className="text-2xl">✓</span>
              <span className="text-luxury-cream/80">WebSocket real-time</span>
            </div>
            <div className="flex items-center gap-3">
              <span className="text-2xl">✓</span>
              <span className="text-luxury-cream/80">Premium дизайн</span>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}
