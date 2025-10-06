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
          <div className="bg-white/90 backdrop-blur-xl rounded-3xl shadow-2xl border border-white/30 p-8">
            <h1 className="text-3xl font-bold mb-2 text-gray-800">{data.restaurant.name}</h1>
            <p className="text-gray-600 mb-4">{data.restaurant.address}</p>
            
            <div className="bg-gradient-to-r from-blue-500 to-purple-600 rounded-2xl p-4 mb-6">
              <div className="flex justify-between items-center">
                <div>
                  <div className="text-sm text-white/80">Ваш стол</div>
                  <div className="text-3xl font-bold text-white">№ {data.table.table_number}</div>
                </div>
                <div className="text-right">
                  <div className="text-sm text-white/80">Вместимость</div>
                  <div className="text-xl font-semibold text-white">{data.table.capacity} чел.</div>
                </div>
              </div>
            </div>

            {!token ? (
              <div className="space-y-3">
                <button
                  onClick={() => navigate(`/menu/${data.restaurant.id}?guest=true`)}
                  className="w-full bg-gradient-to-r from-blue-500 to-purple-600 text-white py-3 rounded-xl font-semibold shadow-lg transition-all hover:shadow-xl"
                >
                  Посмотреть меню
                </button>
                
                <button
                  onClick={handleCallWaiter}
                  className="w-full bg-yellow-500 text-white py-3 rounded-xl font-semibold shadow-lg transition-all hover:bg-yellow-600"
                >
                  Позвать официанта
                </button>
                
                <button
                  onClick={() => navigate('/login')}
                  className="w-full bg-white text-purple-600 py-3 rounded-xl font-semibold border-2 border-purple-600 transition-all hover:bg-gray-50"
                >
                  Войти для заказа
                </button>
              </div>
            ) : (
              <div className="space-y-3">
                <button
                  onClick={() => navigate(`/menu/${data.restaurant.id}`)}
                  className="w-full bg-gradient-to-r from-blue-500 to-purple-600 text-white py-3 rounded-xl font-semibold shadow-lg"
                >
                  Открыть меню и заказать
                </button>
                
                <button
                  onClick={handleCallWaiter}
                  className="w-full bg-yellow-500 text-white py-3 rounded-xl font-semibold shadow-lg"
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
