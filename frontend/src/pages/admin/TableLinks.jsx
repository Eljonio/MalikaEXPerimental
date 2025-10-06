import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useParams } from 'react-router-dom'
import axios from 'axios'

export default function TableLinks() {
  const { restaurantId } = useParams()
  const [halls, setHalls] = useState([])
  const [tables, setTables] = useState([])
  const [selectedHall, setSelectedHall] = useState(null)
  const [loading, setLoading] = useState(true)
  const [generatedLinks, setGeneratedLinks] = useState({})
  const navigate = useNavigate()

  const handleLogout = () => {
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    navigate('/login')
  }

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
      console.error('Error fetching halls:', err)
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
      console.error('Error fetching tables:', err)
    }
  }

  const generateLink = async (tableId) => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.post(
        `/api/restaurants/${restaurantId}/halls/${selectedHall}/tables/${tableId}/generate-link`,
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
    }
  }

  const copyLink = (link) => {
    navigator.clipboard.writeText(link)
    alert('Ссылка скопирована!')
  }

  if (loading) return <div className="p-8">Загрузка...</div>

  return (
    <div className="min-h-screen bg-gray-50">
      <AdminHeader title="Генерация ссылок для столов" />
      <div className="p-8">
      <header className="bg-white rounded-lg shadow mb-6 p-4 flex justify-between items-center">
        <h1 className="text-2xl font-bold">Thanks PWA</h1>
        <button
          onClick={handleLogout}
          className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition"
        >
          Выйти
        </button>
      </header>
      <div className="max-w-6xl mx-auto">
        <h1 className="text-3xl font-bold mb-6">Генерация ссылок для столов</h1>

        <div className="bg-white rounded-lg shadow p-6 mb-6">
          <label className="block text-sm font-medium mb-2">Выберите зал:</label>
          <select
            value={selectedHall || ''}
            onChange={(e) => {
              setSelectedHall(Number(e.target.value))
              fetchTables(Number(e.target.value))
            }}
            className="w-full px-4 py-2 border rounded-lg"
          >
            {halls.map(hall => (
              <option key={hall.id} value={hall.id}>{hall.name}</option>
            ))}
          </select>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {tables.map(table => {
            const link = generatedLinks[table.id]
            return (
              <div key={table.id} className="bg-white rounded-lg shadow p-6">
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h3 className="text-xl font-bold">Стол #{table.number}</h3>
                    <p className="text-gray-600 text-sm">Мест: {table.capacity}</p>
                  </div>
                  {table.short_code && (
                    <span className="px-2 py-1 bg-green-100 text-green-800 rounded text-xs">
                      Активна
                    </span>
                  )}
                </div>

                {link ? (
                  <div className="space-y-2">
                    <div className="p-3 bg-gray-50 rounded text-sm break-all">
                      {link.link}
                    </div>
                    <button
                      onClick={() => copyLink(link.link)}
                      className="w-full py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                    >
                      Скопировать ссылку
                    </button>
                    <p className="text-xs text-gray-500 text-center">
                      Код: {link.short_code}
                    </p>
                  </div>
                ) : (
                  <button
                    onClick={() => generateLink(table.id)}
                    className="w-full py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 font-semibold"
                  >
                    Сгенерировать ссылку
                  </button>
                )}
              </div>
            )
          })}
        </div>
      </div>
    </div>
    </div>
  )
}
