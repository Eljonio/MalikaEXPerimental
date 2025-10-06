import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import axios from 'axios'

export default function Login({ setToken }) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()

  const demoAccounts = [
    { email: 'demo.user@thanks.kz', role: 'Пользователь', icon: '👤' },
    { email: 'demo.waiter@thanks.kz', role: 'Официант', icon: '🍽️' },
    { email: 'demo.admin@thanks.kz', role: 'Администратор', icon: '⚙️' },
    { email: 'demo.owner@thanks.kz', role: 'Владелец', icon: '👔' },
    { email: 'demo.moderator@thanks.kz', role: 'Модератор', icon: '🛡️' }
  ]

  const handleLogin = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      const params = new URLSearchParams()
      params.append('username', email)
      params.append('password', password)

      const response = await axios.post('/api/auth/login', params, {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      })

      localStorage.setItem('token', response.data.access_token)
      localStorage.setItem('user', JSON.stringify(response.data.user))
      setToken(response.data.access_token)

      navigate('/dashboard')
    } catch (err) {
      console.error('Login error:', err)
      setError(err.response?.data?.detail || 'Неверный email или пароль')
    } finally {
      setLoading(false)
    }
  }

  const handleDemoLogin = (demoEmail) => {
    setEmail(demoEmail)
    setPassword('demo123')
  }

  return (
    <div className="min-h-screen bg-luxury-pattern flex items-center justify-center p-4">
      {/* Animated background orbs */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-luxury-gold/5 rounded-full blur-3xl animate-float"></div>
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-luxury-gold/5 rounded-full blur-3xl animate-float" style={{animationDelay: '3s'}}></div>
      </div>

      <div className="relative w-full max-w-5xl">
        {/* Logo/Brand */}
        <div className="text-center mb-8">
          <h1 className="section-title text-5xl mb-3 animate-glow">Thanks</h1>
          <p className="text-luxury-cream/60 text-sm tracking-wider uppercase">Premium Restaurant Experience</p>
        </div>

        <div className="grid md:grid-cols-2 gap-8">
          {/* Login Form */}
          <div className="glass-card p-10 card-shimmer">
            <div className="text-center mb-8">
              <h2 className="text-3xl font-bold text-luxury-cream mb-2">Вход в систему</h2>
              <div className="glass-divider"></div>
              <p className="text-luxury-cream/60 text-sm mt-4">Добро пожаловать</p>
            </div>

            {error && (
              <div className="mb-6 p-4 glass-card border-red-500/50 bg-red-500/10">
                <p className="text-red-300 text-sm text-center">{error}</p>
              </div>
            )}

            <form onSubmit={handleLogin} className="space-y-6">
              <div>
                <label className="block text-sm font-medium text-luxury-gold mb-2 tracking-wide">Email адрес</label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="input-glass"
                  placeholder="your@email.com"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-luxury-gold mb-2 tracking-wide">Пароль</label>
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="input-glass"
                  placeholder="••••••••"
                  required
                />
              </div>

              <button
                type="submit"
                disabled={loading}
                className="btn-luxury w-full py-4 text-lg disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {loading ? (
                  <span className="flex items-center justify-center gap-2">
                    <svg className="animate-spin h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Вход...
                  </span>
                ) : 'Войти'}
              </button>
            </form>

            <div class="glass-divider"></div>

            <div className="text-center">
              <p className="text-luxury-cream/60 text-sm">
                Нет аккаунта?{' '}
                <Link to="/register" className="text-luxury-gold font-semibold hover:text-luxury-gold-light transition-colors">
                  Создать аккаунт
                </Link>
              </p>
            </div>
          </div>

          {/* Demo Accounts */}
          <div className="glass-card p-10">
            <div className="text-center mb-6">
              <h3 className="text-2xl font-bold text-luxury-cream mb-2">Демо доступ</h3>
              <div className="glass-divider"></div>
              <p className="text-luxury-cream/60 text-sm mt-4">Быстрый вход для тестирования</p>
              <div className="inline-block mt-3 px-4 py-1 badge-glass">
                <span className="text-xs text-luxury-gold">Пароль: demo123</span>
              </div>
            </div>

            <div className="space-y-3 luxury-scroll max-h-96 overflow-y-auto pr-2">
              {demoAccounts.map((account) => (
                <button
                  key={account.email}
                  onClick={() => handleDemoLogin(account.email)}
                  className="glass-card-hover w-full p-4 text-left group"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-12 rounded-xl bg-luxury-gold/10 flex items-center justify-center text-2xl border border-luxury-gold/20 group-hover:bg-luxury-gold/20 transition-all">
                        {account.icon}
                      </div>
                      <div>
                        <p className="text-luxury-cream font-semibold group-hover:text-luxury-gold transition-colors">
                          {account.role}
                        </p>
                        <p className="text-luxury-cream/50 text-xs mt-0.5">{account.email}</p>
                      </div>
                    </div>
                    <svg
                      className="w-5 h-5 text-luxury-gold/50 group-hover:text-luxury-gold group-hover:translate-x-1 transition-all"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                    </svg>
                  </div>
                </button>
              ))}
            </div>

            <div className="mt-6 glass-card bg-luxury-gold/5 border-luxury-gold/30 p-4">
              <div className="flex items-center gap-3">
                <svg className="w-5 h-5 text-luxury-gold flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
                </svg>
                <p className="text-luxury-gold/80 text-xs">
                  Демо-аккаунты предназначены только для ознакомления с системой
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Footer accent */}
        <div className="mt-8 text-center">
          <p className="text-luxury-cream/30 text-xs tracking-wider">PREMIUM DINING MANAGEMENT SYSTEM</p>
        </div>
      </div>
    </div>
  )
}
