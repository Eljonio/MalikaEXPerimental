import { useNavigate } from 'react-router-dom'

export default function ProfilePage() {
  const navigate = useNavigate()

  return (
    <div className="min-h-screen bg-luxury-pattern pb-24">
      {/* Header */}
      <header className="glass-card rounded-none border-x-0 border-t-0">
        <div className="px-6 py-5">
          <div className="flex items-center gap-4">
            <button
              onClick={() => navigate(-1)}
              className="w-10 h-10 rounded-xl glass-card flex items-center justify-center"
            >
              <svg className="w-6 h-6 text-luxury-gold" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </button>
            <h1 className="text-2xl font-bold text-luxury-gold">Профиль</h1>
          </div>
        </div>
      </header>

      <div className="px-6 py-8">
        {/* Guest Profile */}
        <div className="glass-card p-8 text-center mb-6">
          <div className="w-24 h-24 rounded-full bg-luxury-gold/20 border-2 border-luxury-gold/40 flex items-center justify-center mx-auto mb-4">
            <svg className="w-12 h-12 text-luxury-gold" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
          </div>
          <h3 className="text-xl font-bold text-luxury-cream mb-2">Гость</h3>
          <p className="text-luxury-cream/60 mb-6">Войдите для доступа ко всем функциям</p>

          <button
            onClick={() => navigate('/login')}
            className="btn-luxury w-full py-3 mb-3"
          >
            Войти в аккаунт
          </button>

          <button
            onClick={() => navigate('/register')}
            className="btn-outline-gold w-full py-3"
          >
            Создать аккаунт
          </button>
        </div>

        {/* Features List */}
        <div className="glass-card p-6">
          <h4 className="font-bold text-luxury-cream mb-4">Возможности аккаунта:</h4>
          <div className="space-y-3">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-luxury-gold/20 flex items-center justify-center flex-shrink-0">
                <span className="text-luxury-gold">✓</span>
              </div>
              <span className="text-luxury-cream/80">Оформление и оплата заказов</span>
            </div>
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-luxury-gold/20 flex items-center justify-center flex-shrink-0">
                <span className="text-luxury-gold">✓</span>
              </div>
              <span className="text-luxury-cream/80">История заказов</span>
            </div>
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-luxury-gold/20 flex items-center justify-center flex-shrink-0">
                <span className="text-luxury-gold">✓</span>
              </div>
              <span className="text-luxury-cream/80">Программа лояльности</span>
            </div>
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-luxury-gold/20 flex items-center justify-center flex-shrink-0">
                <span className="text-luxury-gold">✓</span>
              </div>
              <span className="text-luxury-cream/80">Сохраненные адреса и карты</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
