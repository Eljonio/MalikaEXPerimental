#!/bin/bash

# =====================================================
# THANKS PWA - UI POLISH: Liquid Glass для всех страниц
# =====================================================

set -e

PROJECT_DIR="/opt/thanks/frontend"

echo "Применение Liquid Glass дизайна ко всем страницам..."

# =====================================================
# 1. Dashboard с улучшенным дизайном
# =====================================================
cat > $PROJECT_DIR/src/pages/Dashboard.jsx <<'EOF'
import { useEffect, useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import axios from 'axios'

export default function Dashboard({ setToken }) {
  const [user, setUser] = useState(null)
  const [restaurant, setRestaurant] = useState(null)
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
        }
      } catch (error) {
        handleLogout()
      }
    }
    fetchUser()
  }, [])

  const handleLogout = () => {
    localStorage.removeItem('token')
    setToken(null)
    navigate('/login')
  }

  if (!user) return <div className="min-h-screen flex items-center justify-center">Загрузка...</div>

  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 relative overflow-hidden">
      {/* Анимированный фон */}
      <div className="absolute inset-0">
        <div className="absolute top-40 left-20 w-96 h-96 bg-white/10 rounded-full blur-3xl animate-pulse"></div>
        <div className="absolute bottom-40 right-20 w-80 h-80 bg-white/10 rounded-full blur-3xl animate-pulse" style={{animationDelay: '1s'}}></div>
      </div>

      {/* Header */}
      <header className="relative bg-white/10 backdrop-blur-lg border-b border-white/20">
        <div className="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-white drop-shadow-lg">Thanks PWA</h1>
            {restaurant && <p className="text-sm text-white/80">{restaurant.name}</p>}
          </div>
          <button 
            onClick={handleLogout} 
            className="px-4 py-2 bg-white/20 hover:bg-white/30 backdrop-blur-sm text-white rounded-lg border border-white/30 transition-all"
          >
            Выйти
          </button>
        </div>
      </header>

      <main className="relative max-w-7xl mx-auto px-4 py-8">
        {/* User Card */}
        <div className="bg-white/20 backdrop-blur-xl rounded-3xl shadow-2xl border border-white/30 p-6 mb-8">
          <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-white/50 to-transparent"></div>
          <h2 className="text-xl font-semibold mb-2 text-white">{user.full_name || 'Пользователь'}</h2>
          <p className="text-white/80">{user.email}</p>
          <span className="inline-block mt-2 px-3 py-1 bg-white/20 backdrop-blur-sm text-white rounded-full text-sm border border-white/30">
            {user.role.toUpperCase()}
          </span>
        </div>

        {/* Cards Grid */}
        {user.role === 'user' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Link to="/my-orders" className="group">
              <div className="bg-white/20 backdrop-blur-xl rounded-2xl shadow-xl border border-white/30 p-6 transition-all duration-300 hover:bg-white/30 hover:scale-105">
                <div className="text-4xl mb-4">📋</div>
                <h3 className="text-xl font-semibold mb-2 text-white">Мои заказы</h3>
                <p className="text-white/70">История заказов</p>
              </div>
            </Link>
          </div>
        )}

        {user.role === 'moderator' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Link to="/admin/restaurants" className="group">
              <div className="bg-white/20 backdrop-blur-xl rounded-2xl shadow-xl border border-white/30 p-6 transition-all duration-300 hover:bg-white/30 hover:scale-105">
                <div className="text-4xl mb-4">🏪</div>
                <h3 className="text-xl font-semibold mb-2 text-white">Заведения</h3>
                <p className="text-white/70">Управление</p>
              </div>
            </Link>
          </div>
        )}

        {(user.role === 'admin' || user.role === 'moderator' || user.role === 'owner') && user.restaurant_id && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mt-6">
            <Link to={`/admin/menu/${user.restaurant_id}`} className="group">
              <div className="bg-white/20 backdrop-blur-xl rounded-2xl shadow-xl border border-white/30 p-6 transition-all duration-300 hover:bg-white/30 hover:scale-105">
                <div className="text-4xl mb-4">📋</div>
                <h3 className="text-xl font-semibold mb-2 text-white">Меню</h3>
                <p className="text-white/70">Управление</p>
              </div>
            </Link>
            
            <Link to={`/admin/halls/${user.restaurant_id}`} className="group">
              <div className="bg-white/20 backdrop-blur-xl rounded-2xl shadow-xl border border-white/30 p-6 transition-all duration-300 hover:bg-white/30 hover:scale-105">
                <div className="text-4xl mb-4">🪑</div>
                <h3 className="text-xl font-semibold mb-2 text-white">Залы</h3>
                <p className="text-white/70">Столы и QR</p>
              </div>
            </Link>

            <Link to={`/admin/reservations/${user.restaurant_id}`} className="group">
              <div className="bg-white/20 backdrop-blur-xl rounded-2xl shadow-xl border border-white/30 p-6 transition-all duration-300 hover:bg-white/30 hover:scale-105">
                <div className="text-4xl mb-4">📅</div>
                <h3 className="text-xl font-semibold mb-2 text-white">Бронирования</h3>
                <p className="text-white/70">Управление</p>
              </div>
            </Link>

            <Link to={`/admin/analytics/${user.restaurant_id}`} className="group">
              <div className="bg-white/20 backdrop-blur-xl rounded-2xl shadow-xl border border-white/30 p-6 transition-all duration-300 hover:bg-white/30 hover:scale-105">
                <div className="text-4xl mb-4">📊</div>
                <h3 className="text-xl font-semibold mb-2 text-white">Аналитика</h3>
                <p className="text-white/70">Статистика</p>
              </div>
            </Link>
          </div>
        )}

        {/* Info Banner */}
        <div className="mt-8 bg-gradient-to-r from-white/20 to-white/10 backdrop-blur-xl rounded-2xl shadow-xl border border-white/30 p-8">
          <h3 className="text-2xl font-bold mb-4 text-white">Система готова к работе</h3>
          <ul className="space-y-2 text-white/90">
            <li>✓ Все модули установлены</li>
            <li>✓ WebSocket real-time обновления</li>
            <li>✓ Современный Liquid Glass дизайн</li>
          </ul>
        </div>
      </main>
    </div>
  )
}
EOF

# =====================================================
# 2. QR Page с улучшенным дизайном
# =====================================================
cat > $PROJECT_DIR/src/pages/QRPage.jsx <<'EOF'
import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import axios from 'axios'

export default function QRPage() {
  const { shortCode } = useParams()
  const navigate = useNavigate()
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchTableData()
  }, [shortCode])

  const fetchTableData = async () => {
    try {
      const response = await axios.get(`/api/qr/${shortCode}`)
      setData(response.data)
      setLoading(false)
      
      localStorage.setItem('currentTable', JSON.stringify(response.data.table))
      localStorage.setItem('currentRestaurant', JSON.stringify(response.data.restaurant))
    } catch (error) {
      console.error('Error:', error)
      setLoading(false)
    }
  }

  const handleCallWaiter = async () => {
    try {
      await axios.post('/api/waiter-call', {
        table_id: data.table.id
      })
      alert('Официант вызван!')
    } catch (error) {
      console.error('Error:', error)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
        <div className="text-xl text-white">Загрузка...</div>
      </div>
    )
  }

  if (!data) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
        <div className="text-xl text-white">Стол не найден</div>
      </div>
    )
  }

  const token = localStorage.getItem('token')

  return (
    <div className="min-h-screen relative overflow-hidden bg-gradient-to-br from-blue-500 via-purple-500 to-pink-500">
      <div className="absolute inset-0">
        <div className="absolute top-20 left-20 w-72 h-72 bg-white/10 rounded-full blur-3xl animate-pulse"></div>
        <div className="absolute bottom-20 right-20 w-96 h-96 bg-white/10 rounded-full blur-3xl animate-pulse" style={{animationDelay: '1s'}}></div>
      </div>

      <div className="relative min-h-screen flex items-center justify-center p-4">
        <div className="w-full max-w-md">
          <div className="bg-white/20 backdrop-blur-xl rounded-3xl shadow-2xl border border-white/30 p-8">
            <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-white/50 to-transparent"></div>
            
            <h1 className="text-3xl font-bold mb-2 text-white drop-shadow-lg">{data.restaurant.name}</h1>
            <p className="text-white/80 mb-4">{data.restaurant.address}</p>
            
            <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-4 mb-6 border border-white/30">
              <div className="flex justify-between items-center">
                <div>
                  <div className="text-sm text-white/70">Ваш стол</div>
                  <div className="text-3xl font-bold text-white">№ {data.table.table_number}</div>
                </div>
                <div className="text-right">
                  <div className="text-sm text-white/70">Вместимость</div>
                  <div className="text-xl font-semibold text-white">{data.table.capacity} чел.</div>
                </div>
              </div>
            </div>

            {!token ? (
              <div className="space-y-3">
                <button
                  onClick={() => navigate(`/menu/${data.restaurant.id}?guest=true`)}
                  className="w-full bg-white/30 backdrop-blur-sm hover:bg-white/40 text-white py-3 rounded-xl font-semibold border border-white/30 transition-all"
                >
                  Посмотреть меню
                </button>
                
                <button
                  onClick={handleCallWaiter}
                  className="w-full bg-yellow-500/80 backdrop-blur-sm hover:bg-yellow-500 text-white py-3 rounded-xl font-semibold border border-yellow-400/30 transition-all"
                >
                  Позвать официанта
                </button>
                
                <button
                  onClick={() => navigate('/login')}
                  className="w-full bg-white/20 backdrop-blur-sm hover:bg-white/30 text-white py-3 rounded-xl font-semibold border border-white/30 transition-all"
                >
                  Войти для заказа
                </button>
              </div>
            ) : (
              <div className="space-y-3">
                <button
                  onClick={() => navigate(`/menu/${data.restaurant.id}`)}
                  className="w-full bg-white/30 backdrop-blur-sm hover:bg-white/40 text-white py-3 rounded-xl font-semibold border border-white/30 transition-all"
                >
                  Открыть меню и заказать
                </button>
                
                <button
                  onClick={handleCallWaiter}
                  className="w-full bg-yellow-500/80 backdrop-blur-sm hover:bg-yellow-500 text-white py-3 rounded-xl font-semibold border border-yellow-400/30 transition-all"
                >
                  Позвать официанта
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
EOF

# =====================================================
# 3. Сборка
# =====================================================
cd $PROJECT_DIR
pnpm run build
systemctl reload nginx

echo ""
echo "✅ Дизайн обновлён для всех основных страниц!"
echo "Liquid Glass применён к:"
echo "  - Dashboard"
echo "  - QR страница"
echo ""
echo "Откройте http://217.11.74.100 и обновите страницу (Ctrl+Shift+R)"
