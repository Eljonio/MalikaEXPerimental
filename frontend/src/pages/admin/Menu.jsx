import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import axios from 'axios'
import AdminHeader from '../../components/AdminHeader'

export default function Menu() {
  const { restaurantId } = useParams()
  const navigate = useNavigate()
  const [categories, setCategories] = useState([])
  const [dishes, setDishes] = useState([])
  const [selectedCategory, setSelectedCategory] = useState(null)
  const [showCategoryForm, setShowCategoryForm] = useState(false)
  const [showDishForm, setShowDishForm] = useState(false)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (restaurantId) {
      fetchCategories()
    }
  }, [restaurantId])

  useEffect(() => {
    if (selectedCategory) {
      fetchDishes(selectedCategory.id)
    }
  }, [selectedCategory])

  const fetchCategories = async () => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get(`/api/restaurants/${restaurantId}/categories`, {
        headers: { Authorization: `Bearer ${token}` }
      })
      setCategories(response.data)
      if (response.data.length > 0) {
        setSelectedCategory(response.data[0])
      }
    } catch (error) {
      console.error('Error:', error)
    } finally {
      setLoading(false)
    }
  }

  const fetchDishes = async (categoryId) => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get(`/api/categories/${categoryId}/dishes`, {
        headers: { Authorization: `Bearer ${token}` }
      })
      setDishes(response.data)
    } catch (error) {
      console.error('Error:', error)
    }
  }

  const createCategory = async (name, name_kz) => {
    try {
      const token = localStorage.getItem('token')
      await axios.post(`/api/restaurants/${restaurantId}/categories`,
        { name, name_kz },
        { headers: { Authorization: `Bearer ${token}` }}
      )
      fetchCategories()
      setShowCategoryForm(false)
    } catch (error) {
      console.error('Error:', error)
      alert('Ошибка создания категории')
    }
  }

  const createDish = async (data) => {
    try {
      const token = localStorage.getItem('token')
      await axios.post('/api/dishes',
        { ...data, category_id: selectedCategory.id },
        { headers: { Authorization: `Bearer ${token}` }}
      )
      fetchDishes(selectedCategory.id)
      setShowDishForm(false)
    } catch (error) {
      console.error('Error:', error)
      alert('Ошибка создания блюда')
    }
  }

  const toggleStopList = async (dishId, isStopList) => {
    try {
      const token = localStorage.getItem('token')
      await axios.patch(`/api/dishes/${dishId}/stop-list?stop_list=${!isStopList}`, {}, {
        headers: { Authorization: `Bearer ${token}` }
      })
      fetchDishes(selectedCategory.id)
    } catch (error) {
      console.error('Error:', error)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-luxury-pattern flex items-center justify-center">
        <div className="glass-card p-8">
          <div className="flex items-center gap-3">
            <svg className="animate-spin h-8 w-8 text-luxury-gold" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            <span className="text-luxury-cream text-lg">Загрузка...</span>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-luxury-pattern">
      <AdminHeader title="Управление меню" />

      <div className="flex h-[calc(100vh-88px)]">
        {/* Sidebar - Категории */}
        <div className="w-80 glass-card rounded-none border-y-0 border-l-0 p-6">
          <div className="flex justify-between items-center mb-6">
            <h3 className="font-bold text-luxury-gold text-lg">Категории</h3>
            <button
              onClick={() => setShowCategoryForm(true)}
              className="w-10 h-10 rounded-lg bg-luxury-gold/20 border border-luxury-gold/30 text-luxury-gold text-2xl hover:bg-luxury-gold/30 transition flex items-center justify-center"
            >+</button>
          </div>
          <div className="space-y-2">
            {categories.map(cat => (
              <button
                key={cat.id}
                onClick={() => setSelectedCategory(cat)}
                className={`w-full text-left px-4 py-3 rounded-lg transition ${
                  selectedCategory?.id === cat.id
                    ? 'bg-luxury-gold/20 border border-luxury-gold/40 text-luxury-gold'
                    : 'glass-card-hover text-luxury-cream/80'
                }`}
              >
                <div className="font-medium">{cat.name}</div>
                {cat.name_kz && <div className="text-xs opacity-60 mt-1">{cat.name_kz}</div>}
              </button>
            ))}
          </div>
        </div>

        {/* Блюда */}
        <div className="flex-1 p-8 overflow-y-auto">
          <div className="max-w-7xl mx-auto">
            <div className="flex justify-between items-center mb-8">
              <div>
                <h2 className="text-3xl font-bold text-luxury-cream">
                  {selectedCategory?.name || 'Выберите категорию'}
                </h2>
                {selectedCategory?.name_kz && (
                  <p className="text-luxury-cream/60 mt-1">{selectedCategory.name_kz}</p>
                )}
              </div>
              {selectedCategory && (
                <button
                  onClick={() => setShowDishForm(true)}
                  className="btn-luxury px-6 py-3"
                >
                  + Добавить блюдо
                </button>
              )}
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {dishes.map(dish => (
                <div key={dish.id} className="glass-card overflow-hidden group">
                  {dish.image_url && (
                    <div className="relative h-48 overflow-hidden">
                      <img
                        src={dish.image_url}
                        alt={dish.name}
                        className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                      />
                      <div className="absolute inset-0 bg-gradient-to-t from-luxury-charcoal/80 to-transparent"></div>
                    </div>
                  )}
                  <div className="p-5">
                    <h3 className="font-semibold text-lg text-luxury-cream mb-1">{dish.name}</h3>
                    {dish.name_kz && (
                      <p className="text-sm text-luxury-cream/60 mb-2">{dish.name_kz}</p>
                    )}
                    <p className="text-luxury-cream/70 text-sm mb-3 line-clamp-2">{dish.description}</p>

                    <div className="flex items-center gap-2 text-xs text-luxury-cream/50 mb-4">
                      {dish.cooking_time && <span>⏱️ {dish.cooking_time} мин</span>}
                      {dish.weight && <span>⚖️ {dish.weight}г</span>}
                      {dish.calories && <span>🔥 {dish.calories} ккал</span>}
                    </div>

                    <div className="flex justify-between items-center">
                      <span className="text-2xl font-bold text-luxury-gold">{dish.price} ₸</span>
                      <button
                        onClick={() => toggleStopList(dish.id, dish.is_stop_list)}
                        className={`px-4 py-2 rounded-lg text-sm font-medium transition ${
                          dish.is_stop_list
                            ? 'bg-red-500/20 border border-red-500/40 text-red-400 hover:bg-red-500/30'
                            : 'bg-green-500/20 border border-green-500/40 text-green-400 hover:bg-green-500/30'
                        }`}
                      >
                        {dish.is_stop_list ? '❌ Стоп-лист' : '✓ Доступно'}
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {dishes.length === 0 && selectedCategory && (
              <div className="glass-card p-12 text-center">
                <p className="text-luxury-cream/50">В этой категории пока нет блюд</p>
                <button
                  onClick={() => setShowDishForm(true)}
                  className="btn-outline-gold mt-4"
                >
                  Добавить первое блюдо
                </button>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Модалки */}
      {showCategoryForm && (
        <CategoryForm
          onSubmit={createCategory}
          onClose={() => setShowCategoryForm(false)}
        />
      )}

      {showDishForm && (
        <DishForm
          onSubmit={createDish}
          onClose={() => setShowDishForm(false)}
        />
      )}
    </div>
  )
}

function CategoryForm({ onSubmit, onClose }) {
  const [name, setName] = useState('')
  const [nameKz, setNameKz] = useState('')

  return (
    <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4 z-50">
      <div className="glass-card p-8 w-full max-w-md">
        <h3 className="text-2xl font-bold text-luxury-gold mb-6">Новая категория</h3>
        <form onSubmit={(e) => { e.preventDefault(); onSubmit(name, nameKz); }} className="space-y-4">
          <div>
            <label className="block text-sm text-luxury-cream/60 mb-2">Название (RU)</label>
            <input
              type="text"
              placeholder="Горячие блюда"
              value={name}
              onChange={e => setName(e.target.value)}
              className="input-glass"
              required
            />
          </div>
          <div>
            <label className="block text-sm text-luxury-cream/60 mb-2">Название (KZ)</label>
            <input
              type="text"
              placeholder="Ыстық тағамдар"
              value={nameKz}
              onChange={e => setNameKz(e.target.value)}
              className="input-glass"
            />
          </div>
          <div className="flex gap-3 pt-4">
            <button type="submit" className="btn-luxury flex-1">
              Создать
            </button>
            <button type="button" onClick={onClose} className="btn-glass">
              Отмена
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function DishForm({ onSubmit, onClose }) {
  const [formData, setFormData] = useState({
    name: '',
    name_kz: '',
    description: '',
    description_kz: '',
    price: '',
    cooking_time: 15,
    weight: '',
    calories: '',
    image_url: ''
  })

  return (
    <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4 z-50 overflow-y-auto">
      <div className="glass-card p-8 w-full max-w-2xl my-8">
        <h3 className="text-2xl font-bold text-luxury-gold mb-6">Новое блюдо</h3>
        <form onSubmit={(e) => {
          e.preventDefault();
          onSubmit({
            ...formData,
            price: parseFloat(formData.price),
            weight: formData.weight ? parseInt(formData.weight) : null,
            calories: formData.calories ? parseInt(formData.calories) : null
          });
        }} className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-luxury-cream/60 mb-2">Название (RU) *</label>
              <input
                type="text"
                placeholder="Цезарь с курицей"
                value={formData.name}
                onChange={e => setFormData({...formData, name: e.target.value})}
                className="input-glass"
                required
              />
            </div>
            <div>
              <label className="block text-sm text-luxury-cream/60 mb-2">Название (KZ)</label>
              <input
                type="text"
                placeholder="Тауықты Цезарь"
                value={formData.name_kz}
                onChange={e => setFormData({...formData, name_kz: e.target.value})}
                className="input-glass"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm text-luxury-cream/60 mb-2">Описание (RU)</label>
            <textarea
              placeholder="Состав и описание блюда"
              value={formData.description}
              onChange={e => setFormData({...formData, description: e.target.value})}
              className="input-glass"
              rows="2"
            />
          </div>

          <div>
            <label className="block text-sm text-luxury-cream/60 mb-2">Описание (KZ)</label>
            <textarea
              placeholder="Құрамы мен сипаттамасы"
              value={formData.description_kz}
              onChange={e => setFormData({...formData, description_kz: e.target.value})}
              className="input-glass"
              rows="2"
            />
          </div>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div>
              <label className="block text-sm text-luxury-cream/60 mb-2">Цена (₸) *</label>
              <input
                type="number"
                placeholder="2500"
                value={formData.price}
                onChange={e => setFormData({...formData, price: e.target.value})}
                className="input-glass"
                required
              />
            </div>
            <div>
              <label className="block text-sm text-luxury-cream/60 mb-2">Время (мин)</label>
              <input
                type="number"
                placeholder="15"
                value={formData.cooking_time}
                onChange={e => setFormData({...formData, cooking_time: parseInt(e.target.value)})}
                className="input-glass"
              />
            </div>
            <div>
              <label className="block text-sm text-luxury-cream/60 mb-2">Вес (г)</label>
              <input
                type="number"
                placeholder="350"
                value={formData.weight}
                onChange={e => setFormData({...formData, weight: e.target.value})}
                className="input-glass"
              />
            </div>
            <div>
              <label className="block text-sm text-luxury-cream/60 mb-2">Ккал</label>
              <input
                type="number"
                placeholder="450"
                value={formData.calories}
                onChange={e => setFormData({...formData, calories: e.target.value})}
                className="input-glass"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm text-luxury-cream/60 mb-2">URL изображения</label>
            <input
              type="url"
              placeholder="https://example.com/image.jpg"
              value={formData.image_url}
              onChange={e => setFormData({...formData, image_url: e.target.value})}
              className="input-glass"
            />
          </div>

          <div className="flex gap-3 pt-4">
            <button type="submit" className="btn-luxury flex-1">
              Создать блюдо
            </button>
            <button type="button" onClick={onClose} className="btn-glass">
              Отмена
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
