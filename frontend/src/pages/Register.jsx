import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import axios from 'axios'

export default function Register({ setToken }) {
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    name: '',
    phone: ''
  })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    })
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      // Регистрация
      const registerResponse = await axios.post('/api/auth/register', {
        email: formData.email,
        password: formData.password,
        name: formData.name,
        phone: formData.phone || null
      })

      // Сохранить токен
      localStorage.setItem('token', registerResponse.data.access_token)
      localStorage.setItem('user', JSON.stringify(registerResponse.data.user))
      setToken(registerResponse.data.access_token)

      // Перенаправить на dashboard
      navigate('/dashboard')
    } catch (err) {
      console.error('Registration error:', err)
      setError(err.response?.data?.detail || 'Ошибка регистрации')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-luxury-pattern flex items-center justify-center p-4">
      {/* Animated background */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 right-1/4 w-96 h-96 bg-luxury-gold/5 rounded-full blur-3xl animate-float"></div>
        <div className="absolute bottom-1/3 left-1/3 w-96 h-96 bg-luxury-gold/5 rounded-full blur-3xl animate-float" style={{animationDelay: '2s'}}></div>
      </div>

      <div className="relative w-full max-w-lg">
        {/* Brand */}
        <div className="text-center mb-8">
          <Link to="/login" className="inline-block">
            <h1 className="section-title text-4xl mb-2 hover:scale-105 transition-transform">Thanks</h1>
          </Link>
          <p className="text-luxury-cream/50 text-sm tracking-wider">СОЗДАНИЕ АККАУНТА</p>
        </div>

        <div className="glass-card p-10 card-shimmer">
          <div className="text-center mb-8">
            <h2 className="text-3xl font-bold text-luxury-cream mb-3">Регистрация</h2>
            <div className="glass-divider"></div>
            <p className="text-luxury-cream/60 text-sm mt-4">Присоединяйтесь к премиум сервису</p>
          </div>

          {error && (
            <div className="mb-6 p-4 glass-card border-red-500/50 bg-red-500/10">
              <p className="text-red-300 text-sm text-center">{error}</p>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label className="block text-sm font-medium text-luxury-gold mb-2 tracking-wide">
                Email адрес <span className="text-red-400">*</span>
              </label>
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleChange}
                className="input-glass"
                placeholder="your@email.com"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-luxury-gold mb-2 tracking-wide">
                Полное имя <span className="text-red-400">*</span>
              </label>
              <input
                type="text"
                name="name"
                value={formData.name}
                onChange={handleChange}
                className="input-glass"
                placeholder="Иван Иванов"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-luxury-gold mb-2 tracking-wide">
                Телефон <span className="text-luxury-cream/40 text-xs">(опционально)</span>
              </label>
              <input
                type="tel"
                name="phone"
                value={formData.phone}
                onChange={handleChange}
                className="input-glass"
                placeholder="+7 (777) 123-45-67"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-luxury-gold mb-2 tracking-wide">
                Пароль <span className="text-red-400">*</span>
              </label>
              <input
                type="password"
                name="password"
                value={formData.password}
                onChange={handleChange}
                className="input-glass"
                placeholder="Минимум 6 символов"
                required
                minLength="6"
              />
              <p className="mt-2 text-xs text-luxury-cream/40">Минимум 6 символов</p>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="btn-luxury w-full py-4 text-lg mt-6 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <svg className="animate-spin h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Создание аккаунта...
                </span>
              ) : 'Создать аккаунт'}
            </button>
          </form>

          <div className="glass-divider my-6"></div>

          <div className="text-center">
            <p className="text-luxury-cream/60 text-sm">
              Уже есть аккаунт?{' '}
              <Link to="/login" className="text-luxury-gold font-semibold hover:text-luxury-gold-light transition-colors">
                Войти в систему
              </Link>
            </p>
          </div>
        </div>

        {/* Footer note */}
        <div className="mt-6 text-center">
          <p className="text-luxury-cream/30 text-xs">
            Создавая аккаунт, вы соглашаетесь с нашими условиями использования
          </p>
        </div>
      </div>
    </div>
  )
}
