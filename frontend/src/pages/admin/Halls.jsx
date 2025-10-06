import { useState, useEffect } from 'react'
import { useParams } from 'react-router-dom'
import axios from 'axios'
import AdminHeader from '../../components/AdminHeader'

export default function Halls() {
  const { restaurantId } = useParams()
  const [halls, setHalls] = useState([])
  const [tables, setTables] = useState([])
  const [selectedHall, setSelectedHall] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchHalls()
  }, [restaurantId])

  const fetchHalls = async () => {
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
      console.error('Error:', err)
    } finally {
      setLoading(false)
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
      console.error('Error:', err)
    }
  }

  const copyLink = (shortCode) => {
    const link = `http://217.11.74.100/t/${shortCode}`
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
  }

  if (loading) return <div className="min-h-screen flex items-center justify-center">Загрузка...</div>

  return (
    <div className="min-h-screen bg-gray-50">
      <AdminHeader title="Управление залами" />
      
      <div className="max-w-7xl mx-auto px-4 py-6">
        {/* Выбор зала */}
        <div className="bg-white rounded-lg shadow p-6 mb-6">
          <label className="block text-sm font-medium mb-2">Выберите зал:</label>
          <select
            value={selectedHall || ''}
            onChange={(e) => {
              const hallId = Number(e.target.value)
              setSelectedHall(hallId)
              fetchTables(hallId)
            }}
            className="w-full px-4 py-2 border rounded-lg"
          >
            {halls.map(hall => (
              <option key={hall.id} value={hall.id}>{hall.name}</option>
            ))}
          </select>
        </div>

        {/* Список столов */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {tables.map(table => (
            <div key={table.id} className="bg-white rounded-lg shadow p-6">
              <div className="flex justify-between items-start mb-4">
                <div>
                  <h3 className="text-xl font-bold">Стол #{table.table_number}</h3>
                  <p className="text-sm text-gray-600">Мест: {table.capacity}</p>
                </div>
                {table.short_code && (
                  <span className="px-2 py-1 bg-green-100 text-green-800 rounded text-xs">
                    Активен
                  </span>
                )}
              </div>

              {table.short_code && (
                <div className="space-y-2">
                  <div className="p-3 bg-gray-50 rounded text-xs break-all border">
                    http://217.11.74.100/t/{table.short_code}
                  </div>
                  <button
                    onClick={() => copyLink(table.short_code)}
                    className="w-full py-2 bg-blue-600 text-white text-sm rounded hover:bg-blue-700 transition"
                  >
                    Скопировать ссылку
                  </button>
                  <p className="text-xs text-gray-500 text-center">
                    Код: {table.short_code}
                  </p>
                </div>
              )}
            </div>
          ))}
        </div>

        {tables.length === 0 && (
          <div className="bg-white rounded-lg shadow p-12 text-center">
            <p className="text-gray-500">В этом зале нет столов</p>
          </div>
        )}
      </div>
    </div>
  )
}
