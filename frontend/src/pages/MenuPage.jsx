import { useEffect, useState } from 'react'
import { useParams, useSearchParams, useNavigate } from 'react-router-dom'
import axios from 'axios'

export default function MenuPage() {
  const { restaurantId } = useParams()
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const isGuest = searchParams.get('guest') === 'true'
  
  const [menu, setMenu] = useState([])
  const [cart, setCart] = useState([])
  const [selectedCategory, setSelectedCategory] = useState(null)

  useEffect(() => {
    fetchMenu()
  }, [restaurantId])

  const fetchMenu = async () => {
    try {
      const response = await axios.get(`/api/restaurants/${restaurantId}/menu`)
      setMenu(response.data)
      if (response.data.length > 0) {
        setSelectedCategory(response.data[0])
      }
    } catch (error) {
      console.error('Error:', error)
    }
  }

  const addToCart = (dish) => {
    if (isGuest) {
      alert('Войдите для оформления заказа')
      return
    }
    
    const existing = cart.find(item => item.dish.id === dish.id)
    if (existing) {
      setCart(cart.map(item => 
        item.dish.id === dish.id 
          ? { ...item, quantity: item.quantity + 1 }
          : item
      ))
    } else {
      setCart([...cart, { dish, quantity: 1 }])
    }
  }

  const removeFromCart = (dishId) => {
    setCart(cart.filter(item => item.dish.id !== dishId))
  }

  const updateQuantity = (dishId, delta) => {
    setCart(cart.map(item => {
      if (item.dish.id === dishId) {
        const newQty = item.quantity + delta
        return newQty > 0 ? { ...item, quantity: newQty } : item
      }
      return item
    }).filter(item => item.quantity > 0))
  }

  const getTotalAmount = () => {
    return cart.reduce((sum, item) => sum + (item.dish.price * item.quantity), 0)
  }

  return (
    <div className="flex flex-col h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm p-4 flex justify-between items-center">
        <button onClick={() => navigate(-1)} className="text-2xl">←</button>
        <h1 className="text-xl font-bold">Меню</h1>
        <div className="w-8"></div>
      </header>

      {/* Categories */}
      <div className="bg-white border-b px-4 py-2 overflow-x-auto">
        <div className="flex gap-2">
          {menu.map(cat => (
            <button
              key={cat.id}
              onClick={() => setSelectedCategory(cat)}
              className={`px-4 py-2 rounded-full whitespace-nowrap ${
                selectedCategory?.id === cat.id
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100'
              }`}
            >
              {cat.name}
            </button>
          ))}
        </div>
      </div>

      {/* Dishes */}
      <div className="flex-1 overflow-y-auto p-4 pb-24">
        <div className="grid gap-4">
          {selectedCategory?.dishes.map(dish => (
            <div key={dish.id} className="bg-white rounded-lg shadow-md flex overflow-hidden">
              <img 
                src={dish.image_url} 
                alt={dish.name}
                className="w-24 h-24 object-cover"
              />
              <div className="flex-1 p-3">
                <h3 className="font-semibold">{dish.name}</h3>
                <p className="text-sm text-gray-600 line-clamp-2">{dish.description}</p>
                <div className="flex justify-between items-center mt-2">
                  <span className="text-lg font-bold text-blue-600">{dish.price} ₸</span>
                  <button
                    onClick={() => addToCart(dish)}
                    className="px-4 py-1 bg-blue-600 text-white rounded-lg text-sm"
                    disabled={isGuest}
                  >
                    {isGuest ? 'Войдите' : '+'}
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Cart */}
      {!isGuest && cart.length > 0 && (
        <div className="fixed bottom-0 left-0 right-0 bg-white border-t p-4">
          <div className="max-w-4xl mx-auto">
            <div className="flex justify-between items-center mb-2">
              <span className="font-semibold">Корзина ({cart.length})</span>
              <span className="text-xl font-bold">{getTotalAmount()} ₸</span>
            </div>
            <button
              onClick={() => navigate('/checkout', { state: { cart } })}
              className="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold"
            >
              Оформить заказ
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
