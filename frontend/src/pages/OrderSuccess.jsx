import { useNavigate } from 'react-router-dom'

export default function OrderSuccess() {
  const navigate = useNavigate()

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-400 to-blue-500 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl p-8 max-w-md text-center">
        <div className="text-6xl mb-4">✅</div>
        <h1 className="text-3xl font-bold mb-4">Заказ принят!</h1>
        <p className="text-gray-600 mb-6">
          Ваш заказ передан на кухню. Следите за статусом в личном кабинете.
        </p>
        
        <div className="space-y-3">
          <button
            onClick={() => navigate('/my-orders')}
            className="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold"
          >
            Мои заказы
          </button>
          
          <button
            onClick={() => navigate('/dashboard')}
            className="w-full border-2 border-gray-300 py-3 rounded-lg font-semibold"
          >
            На главную
          </button>
        </div>
      </div>
    </div>
  )
}
