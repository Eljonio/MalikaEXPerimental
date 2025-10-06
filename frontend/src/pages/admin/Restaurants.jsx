import { useState, useEffect } from 'react'
import axios from 'axios'

export default function Restaurants() {
  const [restaurants, setRestaurants] = useState([])
  const [showCreate, setShowCreate] = useState(false)
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    address: '',
    phone: ''
  })

  useEffect(() => {
    fetchRestaurants()
  }, [])

  const fetchRestaurants = async () => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get('/api/restaurants', {
        headers: { Authorization: `Bearer ${token}` }
      })
      setRestaurants(response.data)
    } catch (error) {
      console.error('Error fetching restaurants:', error)
    }
  }

  const handleCreate = async (e) => {
    e.preventDefault()
    try {
      const token = localStorage.getItem('token')
      await axios.post('/api/restaurants', formData, {
        headers: { Authorization: `Bearer ${token}` }
      })
      setShowCreate(false)
      setFormData({ name: '', description: '', address: '', phone: '' })
      fetchRestaurants()
    } catch (error) {
      console.error('Error creating restaurant:', error)
    }
  }

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">Заведения</h2>
        <button
          onClick={() => setShowCreate(true)}
          className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
        >
          + Создать заведение
        </button>
      </div>

      <div className="grid gap-4">
        {restaurants.map(rest => (
          <div key={rest.id} className="bg-white rounded-lg shadow-md p-6">
            <h3 className="text-xl font-semibold mb-2">{rest.name}</h3>
            <p className="text-gray-600 mb-2">{rest.description}</p>
            <div className="flex gap-4 text-sm text-gray-500">
              <span>📍 {rest.address}</span>
              <span>📞 {rest.phone}</span>
            </div>
          </div>
        ))}
      </div>

      {showCreate && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl p-6 w-full max-w-md">
            <h3 className="text-xl font-bold mb-4">Создать заведение</h3>
            <form onSubmit={handleCreate} className="space-y-4">
              <input
                type="text"
                placeholder="Название"
                value={formData.name}
                onChange={e => setFormData({...formData, name: e.target.value})}
                className="w-full px-4 py-2 border rounded-lg"
                required
              />
              <textarea
                placeholder="Описание"
                value={formData.description}
                onChange={e => setFormData({...formData, description: e.target.value})}
                className="w-full px-4 py-2 border rounded-lg"
                rows="3"
              />
              <input
                type="text"
                placeholder="Адрес"
                value={formData.address}
                onChange={e => setFormData({...formData, address: e.target.value})}
                className="w-full px-4 py-2 border rounded-lg"
              />
              <input
                type="tel"
                placeholder="Телефон"
                value={formData.phone}
                onChange={e => setFormData({...formData, phone: e.target.value})}
                className="w-full px-4 py-2 border rounded-lg"
              />
              <div className="flex gap-2">
                <button type="submit" className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg">
                  Создать
                </button>
                <button type="button" onClick={() => setShowCreate(false)} className="px-4 py-2 border rounded-lg">
                  Отмена
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
