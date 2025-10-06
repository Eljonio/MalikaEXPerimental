import { useState, useEffect } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'

export default function CheckPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const [tableInfo, setTableInfo] = useState(null)

  // Get cart from navigation state or localStorage fallback
  const [cart, setCart] = useState(location.state?.cart || JSON.parse(localStorage.getItem('cart') || '[]'))

  useEffect(() => {
    const savedTable = localStorage.getItem('current_table')
    if (savedTable) {
      setTableInfo(JSON.parse(savedTable))
    }
  }, [])

  // Save cart to localStorage whenever it changes
  useEffect(() => {
    localStorage.setItem('cart', JSON.stringify(cart))
    if (location.state?.setCart) {
      location.state.setCart(cart)
    }
  }, [cart, location.state])

  const removeFromCart = (index) => {
    const newCart = [...cart]
    newCart.splice(index, 1)
    setCart(newCart)
  }

  const updateQuantity = (index, delta) => {
    const newCart = [...cart]
    const item = newCart[index]
    item.quantity = (item.quantity || 1) + delta
    if (item.quantity <= 0) {
      newCart.splice(index, 1)
    }
    setCart(newCart)
  }

  const totalAmount = cart.reduce((sum, item) => sum + (item.price * (item.quantity || 1)), 0)
  const servicePercent = 10
  const serviceFee = totalAmount * (servicePercent / 100)
  const finalTotal = totalAmount + serviceFee

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
              <h1 className="text-2xl font-bold text-luxury-gold">Мой чек</h1>
              {tableInfo && (
                <p className="text-luxury-cream/60 text-sm">Стол #{tableInfo.table_number}</p>
              )}
            </div>
          </div>
        </div>
      </header>

      <div className="px-6 py-6">
        {cart.length === 0 ? (
          <div className="glass-card p-12 text-center">
            <div className="text-6xl mb-4">🛒</div>
            <h3 className="text-xl font-bold text-luxury-cream mb-2">Корзина пуста</h3>
            <p className="text-luxury-cream/60 mb-6">Добавьте блюда из меню</p>
            <button
              onClick={() => navigate(-1)}
              className="btn-luxury px-8 py-3"
            >
              Вернуться к меню
            </button>
          </div>
        ) : (
          <>
            {/* Cart Items */}
            <div className="space-y-4 mb-6">
              {cart.map((item, index) => (
                <div key={index} className="glass-card p-4">
                  <div className="flex gap-4">
                    <div className="w-20 h-20 rounded-xl overflow-hidden bg-luxury-charcoal-light flex-shrink-0">
                      {item.image_url && (
                        <img src={item.image_url} alt={item.name} className="w-full h-full object-cover" />
                      )}
                    </div>
                    <div className="flex-1">
                      <h4 className="font-bold text-luxury-cream mb-1">{item.name}</h4>
                      <p className="text-luxury-gold font-semibold">{item.price}₽</p>

                      <div className="flex items-center gap-3 mt-3">
                        <button
                          onClick={() => updateQuantity(index, -1)}
                          className="w-8 h-8 rounded-lg glass-card flex items-center justify-center text-luxury-gold"
                        >
                          −
                        </button>
                        <span className="text-luxury-cream font-semibold w-8 text-center">
                          {item.quantity || 1}
                        </span>
                        <button
                          onClick={() => updateQuantity(index, 1)}
                          className="w-8 h-8 rounded-lg glass-card flex items-center justify-center text-luxury-gold"
                        >
                          +
                        </button>
                        <button
                          onClick={() => removeFromCart(index)}
                          className="ml-auto text-red-400 hover:text-red-300"
                        >
                          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                          </svg>
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* Summary */}
            <div className="glass-card p-6 space-y-4">
              <h3 className="text-xl font-bold text-luxury-cream mb-4">Итого</h3>

              <div className="flex justify-between text-luxury-cream/70">
                <span>Сумма заказа:</span>
                <span>{totalAmount}₽</span>
              </div>

              <div className="flex justify-between text-luxury-cream/70">
                <span>Сервисный сбор ({servicePercent}%):</span>
                <span>{serviceFee.toFixed(0)}₽</span>
              </div>

              <div className="glass-divider"></div>

              <div className="flex justify-between text-xl font-bold text-luxury-gold">
                <span>К оплате:</span>
                <span>{finalTotal.toFixed(0)}₽</span>
              </div>

              <button
                onClick={() => navigate('/login')}
                className="btn-luxury w-full py-4 mt-4"
              >
                Войти для оформления заказа
              </button>

              <p className="text-center text-luxury-cream/50 text-xs mt-4">
                Для оформления заказа необходимо войти в аккаунт
              </p>
            </div>
          </>
        )}
      </div>
    </div>
  )
}
