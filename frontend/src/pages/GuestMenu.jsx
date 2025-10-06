import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import axios from 'axios'

export default function GuestMenu() {
  const { restaurantId } = useParams()
  const navigate = useNavigate()
  const [menu, setMenu] = useState([])
  const [restaurant, setRestaurant] = useState(null)
  const [tableInfo, setTableInfo] = useState(null)
  const [loading, setLoading] = useState(true)
  const [callingWaiter, setCallingWaiter] = useState(false)
  const [selectedCategory, setSelectedCategory] = useState(null)
  const [cart, setCart] = useState(() => {
    const savedCart = localStorage.getItem('cart')
    return savedCart ? JSON.parse(savedCart) : []
  })
  const [activeTab, setActiveTab] = useState('menu')

  // Проверка гостевого режима vs авторизованный пользователь
  const [isGuest, setIsGuest] = useState(true)
  const [user, setUser] = useState(null)

  useEffect(() => {
    const savedTable = localStorage.getItem('current_table')
    if (savedTable) {
      setTableInfo(JSON.parse(savedTable))
    }

    // Проверяем авторизацию
    const token = localStorage.getItem('token')
    if (token) {
      fetchUser()
    } else {
      const guestMode = localStorage.getItem('guest_mode')
      setIsGuest(guestMode === 'true')
    }

    fetchRestaurantAndMenu()
  }, [restaurantId])

  // Save cart to localStorage whenever it changes
  useEffect(() => {
    localStorage.setItem('cart', JSON.stringify(cart))
  }, [cart])

  const fetchUser = async () => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get('/api/auth/me', {
        headers: { Authorization: `Bearer ${token}` }
      })
      setUser(response.data)
      setIsGuest(false)
    } catch (error) {
      console.error('Error fetching user:', error)
      setIsGuest(true)
    }
  }

  const fetchRestaurantAndMenu = async () => {
    try {
      const restResponse = await axios.get(`/api/restaurants/${restaurantId}`)
      setRestaurant(restResponse.data)

      const menuResponse = await axios.get(`/api/restaurants/${restaurantId}/menu`)
      setMenu(menuResponse.data)

      if (menuResponse.data.length > 0) {
        setSelectedCategory(menuResponse.data[0].id)
      }
    } catch (err) {
      console.error('Error:', err)
    } finally {
      setLoading(false)
    }
  }

  const callWaiter = async () => {
    if (!tableInfo) {
      alert('Информация о столе не найдена')
      return
    }

    setCallingWaiter(true)
    try {
      await axios.post(`/api/tables/${tableInfo.table_id}/call-waiter`)
      alert('✅ Официант вызван!')
    } catch (err) {
      console.error('Error calling waiter:', err)
      alert('Ошибка вызова официанта')
    } finally {
      setCallingWaiter(false)
    }
  }

  const addToCart = (dish) => {
    setCart([...cart, { ...dish, quantity: 1 }])
  }

  const totalAmount = cart.reduce((sum, item) => sum + (item.price * (item.quantity || 1)), 0)

  if (loading) {
    return (
      <div className="min-h-screen bg-luxury-pattern flex items-center justify-center">
        <div className="glass-card p-8">
          <div className="flex items-center gap-3">
            <svg className="animate-spin h-8 w-8 text-luxury-gold" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            <span className="text-luxury-cream text-lg">Загрузка меню...</span>
          </div>
        </div>
      </div>
    )
  }

  const currentCategory = menu.find(cat => cat.id === selectedCategory)

  return (
    <div className="min-h-screen bg-luxury-pattern pb-24">
      {/* Premium Header */}
      <header className="glass-card rounded-none border-x-0 border-t-0 sticky top-0 z-20">
        <div className="px-6 py-5">
          <div className="flex justify-between items-start mb-4">
            <div>
              <h1 className="text-2xl font-bold text-luxury-gold mb-1">{restaurant?.name || 'Ресторан'}</h1>
              <div className="flex items-center gap-3 mt-2">
                <div className="flex items-center gap-1">
                  <span className="text-luxury-gold text-lg">⭐</span>
                  <span className="text-luxury-cream font-semibold">4.8</span>
                </div>
                {tableInfo && (
                  <>
                    <div className="w-1 h-1 rounded-full bg-luxury-gold/40"></div>
                    <div className="badge-glass border-luxury-gold/40">
                      <span className="text-luxury-gold text-xs">Стол #{tableInfo.table_number}</span>
                    </div>
                  </>
                )}
              </div>
            </div>
            <div className="text-right">
              <p className="text-luxury-cream/60 text-xs mb-1">Сумма чека</p>
              <p className="text-2xl font-bold text-luxury-gold">{totalAmount}₽</p>
            </div>
          </div>

          {/* Categories Scroll */}
          <div className="flex gap-3 overflow-x-auto luxury-scroll pb-2 -mx-2 px-2">
            {menu.map(category => (
              <button
                key={category.id}
                onClick={() => setSelectedCategory(category.id)}
                className={`px-5 py-2 rounded-xl font-medium whitespace-nowrap transition-all ${
                  selectedCategory === category.id
                    ? 'bg-luxury-gold text-luxury-charcoal'
                    : 'glass-card text-luxury-cream/70 hover:text-luxury-cream'
                }`}
              >
                {category.name}
              </button>
            ))}
          </div>
        </div>
      </header>

      {/* Dishes List */}
      <div className="px-4 py-6 space-y-4">
        {currentCategory?.dishes.map(dish => (
          <div key={dish.id} className="glass-card p-4 card-shimmer">
            <div className="flex gap-4">
              {/* Image */}
              <div className="w-24 h-24 rounded-xl overflow-hidden flex-shrink-0 bg-luxury-charcoal-light">
                {dish.image_url && (
                  <img
                    src={dish.image_url}
                    alt={dish.name}
                    className="w-full h-full object-cover"
                  />
                )}
              </div>

              {/* Info */}
              <div className="flex-1 min-w-0">
                <h3 className="font-bold text-lg text-luxury-cream mb-1">{dish.name}</h3>
                <p className="text-sm text-luxury-cream/60 mb-3 line-clamp-2">
                  {dish.description || 'Вкусное блюдо от шеф-повара'}
                </p>

                <div className="flex items-center justify-between">
                  <span className="text-xl font-bold text-luxury-gold">{dish.price}₽</span>
                  {isGuest ? (
                    <button
                      onClick={() => navigate('/login', { state: { from: `/guest-menu/${restaurantId}` }})}
                      disabled={!dish.is_available}
                      className="btn-outline-gold px-5 py-2 text-sm disabled:opacity-40"
                    >
                      Войти
                    </button>
                  ) : (
                    <button
                      onClick={() => addToCart(dish)}
                      disabled={!dish.is_available}
                      className="btn-luxury px-5 py-2 text-sm disabled:opacity-40"
                    >
                      Добавить
                    </button>
                  )}
                </div>
              </div>
            </div>
          </div>
        ))}

        {!currentCategory?.dishes?.length && (
          <div className="glass-card p-12 text-center">
            <div className="text-5xl mb-4">🍽️</div>
            <p className="text-luxury-cream/60">В этой категории пока нет блюд</p>
          </div>
        )}
      </div>

      {/* Bottom Navigation */}
      <nav className="fixed bottom-0 left-0 right-0 glass-card rounded-none border-x-0 border-b-0 z-30">
        <div className={`flex ${isGuest ? 'justify-around' : 'justify-around'} items-center px-4 py-4`}>
          {/* Waiter Call - Available for everyone */}
          <button
            onClick={() => {
              setActiveTab('waiter')
              callWaiter()
            }}
            disabled={callingWaiter}
            className={`flex flex-col items-center gap-1 transition-colors ${
              callingWaiter ? 'opacity-50' : 'hover:text-luxury-gold'
            } ${activeTab === 'waiter' ? 'text-luxury-gold' : 'text-luxury-cream/60'}`}
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
            <span className="text-xs font-medium">Официант</span>
          </button>

          {/* Menu - Available for everyone */}
          <button
            onClick={() => setActiveTab('menu')}
            className={`flex flex-col items-center gap-1 transition-colors hover:text-luxury-gold ${
              activeTab === 'menu' ? 'text-luxury-gold' : 'text-luxury-cream/60'
            }`}
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
            <span className="text-xs font-medium">Меню</span>
          </button>

          {/* Check - Only for authenticated users */}
          {!isGuest && (
            <button
              onClick={() => {
                setActiveTab('check')
                navigate('/check', { state: { cart, setCart } })
              }}
              className={`flex flex-col items-center gap-1 transition-colors hover:text-luxury-gold relative ${
                activeTab === 'check' ? 'text-luxury-gold' : 'text-luxury-cream/60'
              }`}
            >
              {cart.length > 0 && (
                <div className="absolute -top-1 -right-1 w-5 h-5 rounded-full bg-luxury-gold text-luxury-charcoal text-xs font-bold flex items-center justify-center">
                  {cart.length}
                </div>
              )}
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
              <span className="text-xs font-medium">Мой чек</span>
            </button>
          )}

          {/* Profile / Login */}
          <button
            onClick={() => {
              setActiveTab('profile')
              if (isGuest) {
                navigate('/login', { state: { from: `/guest-menu/${restaurantId}` }})
              } else {
                navigate('/profile')
              }
            }}
            className={`flex flex-col items-center gap-1 transition-colors hover:text-luxury-gold ${
              activeTab === 'profile' ? 'text-luxury-gold' : 'text-luxury-cream/60'
            }`}
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5.121 17.804A13.937 13.937 0 0112 16c2.5 0 4.847.655 6.879 1.804M15 10a3 3 0 11-6 0 3 3 0 016 0zm6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span className="text-xs font-medium">{isGuest ? 'Войти' : 'Профиль'}</span>
          </button>
        </div>
      </nav>
    </div>
  )
}
