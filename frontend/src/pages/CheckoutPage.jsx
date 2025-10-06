import { useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import axios from 'axios'

const TIP_OPTIONS = [5, 10, 15, 20]

export default function CheckoutPage() {
  const location = useLocation()
  const navigate = useNavigate()
  const cart = location.state?.cart || []
  
  const [tipPercent, setTipPercent] = useState(null)
  const [customTip, setCustomTip] = useState('')
  const [loading, setLoading] = useState(false)

  const subtotal = cart.reduce((sum, item) => sum + (item.dish.price * item.quantity), 0)
  const tipAmount = tipPercent 
    ? (subtotal * tipPercent / 100) 
    : parseFloat(customTip) || 0
  const total = subtotal + tipAmount

  const handleCheckout = async () => {
    const tableData = JSON.parse(localStorage.getItem('currentTable') || '{}')
    
    if (!tableData.id) {
      alert('Ошибка: стол не определен')
      return
    }

    setLoading(true)
    
    try {
      const token = localStorage.getItem('token')
      
      // Создать заказ
      const orderResponse = await axios.post('/api/orders', {
        table_id: tableData.id,
        items: cart.map(item => ({
          dish_id: item.dish.id,
          quantity: item.quantity
        })),
        tips_amount: tipAmount
      }, {
        headers: { Authorization: `Bearer ${token}` }
      })

      // Имитация оплаты
      await axios.post(`/api/orders/${orderResponse.data.id}/pay`, {}, {
        headers: { Authorization: `Bearer ${token}` }
      })

      navigate('/order-success')
    } catch (error) {
      console.error('Error:', error)
      alert('Ошибка при оформлении заказа')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 p-4">
      <div className="max-w-2xl mx-auto">
        <div className="bg-white rounded-xl shadow-md p-6 mb-4">
          <h2 className="text-2xl font-bold mb-4">Ваш заказ</h2>
          
          {cart.map(item => (
            <div key={item.dish.id} className="flex justify-between py-2 border-b">
              <div>
                <div className="font-medium">{item.dish.name}</div>
                <div className="text-sm text-gray-600">{item.quantity} × {item.dish.price} ₸</div>
              </div>
              <div className="font-semibold">{item.dish.price * item.quantity} ₸</div>
            </div>
          ))}
          
          <div className="flex justify-between py-3 font-semibold text-lg">
            <span>Подитог:</span>
            <span>{subtotal} ₸</span>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-md p-6 mb-4">
          <h3 className="font-bold mb-3">Чаевые</h3>
          
          <div className="grid grid-cols-4 gap-2 mb-3">
            {TIP_OPTIONS.map(percent => (
              <button
                key={percent}
                onClick={() => { setTipPercent(percent); setCustomTip(''); }}
                className={`py-2 rounded-lg border-2 ${
                  tipPercent === percent
                    ? 'border-blue-600 bg-blue-50 text-blue-600'
                    : 'border-gray-200'
                }`}
              >
                {percent}%
              </button>
            ))}
          </div>
          
          <div>
            <input
              type="number"
              placeholder="Своя сумма"
              value={customTip}
              onChange={(e) => { setCustomTip(e.target.value); setTipPercent(null); }}
              className="w-full px-4 py-2 border rounded-lg"
            />
          </div>
          
          {tipAmount > 0 && (
            <div className="mt-2 text-sm text-gray-600">
              Чаевые: {tipAmount.toFixed(0)} ₸
            </div>
          )}
        </div>

        <div className="bg-white rounded-xl shadow-md p-6 mb-4">
          <div className="flex justify-between items-center text-xl font-bold">
            <span>Итого:</span>
            <span>{total.toFixed(0)} ₸</span>
          </div>
        </div>

        <button
          onClick={handleCheckout}
          disabled={loading}
          className="w-full bg-blue-600 text-white py-4 rounded-xl font-bold text-lg disabled:bg-gray-400"
        >
          {loading ? 'Обработка...' : 'Оплатить'}
        </button>
      </div>
    </div>
  )
}
