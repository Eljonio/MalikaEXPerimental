#!/bin/bash

# =====================================================
# THANKS PWA - STAGE 6+7: Бронирования и Аналитика
# =====================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="/opt/thanks"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}THANKS PWA - Stage 6+7 Installation${NC}"
echo -e "${GREEN}Бронирования и Аналитика${NC}"
echo -e "${GREEN}================================${NC}\n"

if [ "$EUID" -ne 0 ]; then 
   echo -e "${RED}Запустите скрипт с правами root (sudo)${NC}"
   exit 1
fi

# =====================================================
# 1. Создание таблицы бронирований
# =====================================================
echo -e "${YELLOW}[1/8] Создание таблиц...${NC}"

sudo -u postgres psql -d thanks_db <<'SQL'
-- Таблица бронирований
CREATE TABLE IF NOT EXISTS reservations (
    id SERIAL PRIMARY KEY,
    table_id INTEGER REFERENCES tables(id),
    user_id INTEGER REFERENCES users(id),
    guest_name VARCHAR,
    guest_phone VARCHAR,
    guest_count INTEGER DEFAULT 2,
    reservation_date DATE NOT NULL,
    reservation_time TIME NOT NULL,
    duration_minutes INTEGER DEFAULT 120,
    status VARCHAR DEFAULT 'confirmed',
    special_requests TEXT,
    deposit_amount NUMERIC(10,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_reservations_table ON reservations(table_id);
CREATE INDEX IF NOT EXISTS idx_reservations_date ON reservations(reservation_date);
CREATE INDEX IF NOT EXISTS idx_reservations_status ON reservations(status);

GRANT ALL PRIVILEGES ON TABLE reservations TO thanks_user;
GRANT USAGE, SELECT ON SEQUENCE reservations_id_seq TO thanks_user;
SQL

systemctl stop thanks-backend

# =====================================================
# 2. Обновление моделей
# =====================================================
echo -e "${YELLOW}[2/8] Обновление моделей...${NC}"

cat >> $PROJECT_DIR/backend/models.py <<'EOF'

class ReservationStatus(str, enum.Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    ARRIVED = "arrived"
    SEATED = "seated"
    NO_SHOW = "no_show"
    CANCELLED = "cancelled"
    COMPLETED = "completed"

class Reservation(Base):
    __tablename__ = "reservations"
    
    id = Column(Integer, primary_key=True, index=True)
    table_id = Column(Integer, ForeignKey("tables.id"))
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    guest_name = Column(String)
    guest_phone = Column(String)
    guest_count = Column(Integer, default=2)
    reservation_date = Column(DateTime, nullable=False)
    reservation_time = Column(DateTime, nullable=False)
    duration_minutes = Column(Integer, default=120)
    status = Column(String, default="confirmed")
    special_requests = Column(Text, nullable=True)
    deposit_amount = Column(Float, default=0.0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
EOF

# =====================================================
# 3. Backend API для бронирований
# =====================================================
echo -e "${YELLOW}[3/8] Добавление API бронирований...${NC}"

cat >> $PROJECT_DIR/backend/main.py <<'EOF'

# =====================================================
# Бронирования (Stage 6)
# =====================================================
from models import Reservation

class ReservationCreate(BaseModel):
    table_id: int
    guest_name: str
    guest_phone: str
    guest_count: int = 2
    reservation_date: str
    reservation_time: str
    special_requests: Optional[str] = None

class ReservationResponse(BaseModel):
    id: int
    table_id: int
    guest_name: str
    guest_phone: str
    guest_count: int
    reservation_date: datetime
    reservation_time: datetime
    status: str
    special_requests: Optional[str]
    
    class Config:
        from_attributes = True

@app.post("/reservations", response_model=ReservationResponse)
def create_reservation(data: ReservationCreate, db: Session = Depends(get_db)):
    from datetime import datetime as dt
    
    res_datetime = dt.fromisoformat(f"{data.reservation_date}T{data.reservation_time}")
    
    reservation = Reservation(
        table_id=data.table_id,
        guest_name=data.guest_name,
        guest_phone=data.guest_phone,
        guest_count=data.guest_count,
        reservation_date=res_datetime,
        reservation_time=res_datetime,
        status="confirmed",
        special_requests=data.special_requests
    )
    db.add(reservation)
    db.commit()
    db.refresh(reservation)
    return reservation

@app.get("/reservations", response_model=List[ReservationResponse])
def list_reservations(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role not in [UserRole.MODERATOR, UserRole.ADMIN, UserRole.WAITER]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    return db.query(Reservation).order_by(Reservation.reservation_date.desc()).all()

@app.patch("/reservations/{reservation_id}/status")
def update_reservation_status(reservation_id: int, status: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role not in [UserRole.MODERATOR, UserRole.ADMIN, UserRole.WAITER]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    reservation = db.query(Reservation).filter(Reservation.id == reservation_id).first()
    if not reservation:
        raise HTTPException(status_code=404, detail="Reservation not found")
    
    reservation.status = status
    reservation.updated_at = datetime.utcnow()
    db.commit()
    return {"message": f"Reservation status updated to {status}"}

# =====================================================
# Аналитика (Stage 7)
# =====================================================
@app.get("/analytics/overview")
def get_analytics_overview(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role not in [UserRole.MODERATOR, UserRole.ADMIN, UserRole.OWNER]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Получить заказы заведения
    if current_user.restaurant_id:
        halls = db.query(Hall).filter(Hall.restaurant_id == current_user.restaurant_id).all()
        hall_ids = [hall.id for hall in halls]
        tables = db.query(Table).filter(Table.hall_id.in_(hall_ids)).all()
        table_ids = [table.id for table in tables]
        
        orders = db.query(Order).filter(Order.table_id.in_(table_ids)).all()
        
        total_revenue = sum(o.total_amount + o.tips_amount + o.service_fee for o in orders if o.is_paid)
        total_tips = sum(o.tips_amount for o in orders if o.is_paid)
        total_orders = len(orders)
        paid_orders = len([o for o in orders if o.is_paid])
        avg_check = total_revenue / paid_orders if paid_orders > 0 else 0
        
        # Популярные блюда
        from sqlalchemy import func
        popular_dishes = db.query(
            OrderItem.dish_id,
            func.sum(OrderItem.quantity).label('total_quantity'),
            func.sum(OrderItem.total).label('total_revenue')
        ).join(Order).filter(
            Order.table_id.in_(table_ids),
            Order.is_paid == True
        ).group_by(OrderItem.dish_id).order_by(func.sum(OrderItem.quantity).desc()).limit(5).all()
        
        return {
            "total_revenue": round(total_revenue, 2),
            "total_tips": round(total_tips, 2),
            "total_orders": total_orders,
            "paid_orders": paid_orders,
            "avg_check": round(avg_check, 2),
            "popular_dishes": [
                {
                    "dish_id": d[0],
                    "quantity": d[1],
                    "revenue": float(d[2])
                } for d in popular_dishes
            ]
        }
    
    return {}
EOF

# =====================================================
# 4. Frontend - Страница бронирований
# =====================================================
echo -e "${YELLOW}[4/8] Создание страницы бронирований...${NC}"

mkdir -p $PROJECT_DIR/frontend/src/pages/admin

cat > $PROJECT_DIR/frontend/src/pages/admin/Reservations.jsx <<'EOF'
import { useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import axios from 'axios'

const STATUSES = {
  confirmed: { label: 'Подтверждено', color: 'bg-blue-500' },
  arrived: { label: 'Прибыл', color: 'bg-green-500' },
  seated: { label: 'Посажен', color: 'bg-purple-500' },
  no_show: { label: 'Не пришёл', color: 'bg-red-500' },
  cancelled: { label: 'Отменено', color: 'bg-gray-500' },
  completed: { label: 'Завершено', color: 'bg-green-600' }
}

export default function Reservations() {
  const { restaurantId } = useParams()
  const [reservations, setReservations] = useState([])
  const [tables, setTables] = useState([])
  const [showForm, setShowForm] = useState(false)

  useEffect(() => {
    fetchReservations()
    fetchTables()
  }, [])

  const fetchReservations = async () => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get('/api/reservations', {
        headers: { Authorization: `Bearer ${token}` }
      })
      setReservations(response.data)
    } catch (error) {
      console.error('Error:', error)
    }
  }

  const fetchTables = async () => {
    try {
      const token = localStorage.getItem('token')
      const hallsRes = await axios.get(`/api/restaurants/${restaurantId}/halls`, {
        headers: { Authorization: `Bearer ${token}` }
      })
      
      const allTables = []
      for (const hall of hallsRes.data) {
        const tablesRes = await axios.get(`/api/halls/${hall.id}/tables`, {
          headers: { Authorization: `Bearer ${token}` }
        })
        allTables.push(...tablesRes.data)
      }
      setTables(allTables)
    } catch (error) {
      console.error('Error:', error)
    }
  }

  const createReservation = async (data) => {
    try {
      const token = localStorage.getItem('token')
      await axios.post('/api/reservations', data, {
        headers: { Authorization: `Bearer ${token}` }
      })
      fetchReservations()
      setShowForm(false)
    } catch (error) {
      console.error('Error:', error)
    }
  }

  const updateStatus = async (id, status) => {
    try {
      const token = localStorage.getItem('token')
      await axios.patch(`/api/reservations/${id}/status?status=${status}`, {}, {
        headers: { Authorization: `Bearer ${token}` }
      })
      fetchReservations()
    } catch (error) {
      console.error('Error:', error)
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 p-4">
      <div className="max-w-7xl mx-auto">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold">Бронирования</h1>
          <button
            onClick={() => setShowForm(true)}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg"
          >
            + Новое бронирование
          </button>
        </div>

        <div className="space-y-4">
          {reservations.map(res => (
            <div key={res.id} className="bg-white rounded-lg shadow-md p-4">
              <div className="flex justify-between items-start mb-3">
                <div>
                  <h3 className="font-bold text-lg">{res.guest_name}</h3>
                  <p className="text-sm text-gray-600">{res.guest_phone}</p>
                  <p className="text-sm mt-1">
                    {new Date(res.reservation_date).toLocaleDateString('ru-RU')} в {new Date(res.reservation_time).toLocaleTimeString('ru-RU', {hour: '2-digit', minute: '2-digit'})}
                  </p>
                  <p className="text-sm">Гостей: {res.guest_count}</p>
                </div>
                <span className={`px-3 py-1 rounded-full text-white text-sm ${STATUSES[res.status]?.color}`}>
                  {STATUSES[res.status]?.label}
                </span>
              </div>

              {res.special_requests && (
                <p className="text-sm bg-gray-50 p-2 rounded mb-3">{res.special_requests}</p>
              )}

              <div className="flex gap-2">
                {res.status === 'confirmed' && (
                  <button
                    onClick={() => updateStatus(res.id, 'arrived')}
                    className="px-3 py-1 bg-green-500 text-white rounded text-sm"
                  >
                    Прибыл
                  </button>
                )}
                {res.status === 'arrived' && (
                  <button
                    onClick={() => updateStatus(res.id, 'seated')}
                    className="px-3 py-1 bg-purple-500 text-white rounded text-sm"
                  >
                    Посадить
                  </button>
                )}
                {res.status === 'seated' && (
                  <button
                    onClick={() => updateStatus(res.id, 'completed')}
                    className="px-3 py-1 bg-green-600 text-white rounded text-sm"
                  >
                    Завершить
                  </button>
                )}
                <button
                  onClick={() => updateStatus(res.id, 'cancelled')}
                  className="px-3 py-1 bg-red-500 text-white rounded text-sm"
                >
                  Отменить
                </button>
              </div>
            </div>
          ))}
        </div>

        {showForm && (
          <ReservationForm
            tables={tables}
            onSubmit={createReservation}
            onClose={() => setShowForm(false)}
          />
        )}
      </div>
    </div>
  )
}

function ReservationForm({ tables, onSubmit, onClose }) {
  const [formData, setFormData] = useState({
    table_id: '',
    guest_name: '',
    guest_phone: '',
    guest_count: 2,
    reservation_date: new Date().toISOString().split('T')[0],
    reservation_time: '19:00',
    special_requests: ''
  })

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-xl p-6 w-full max-w-md">
        <h3 className="text-xl font-bold mb-4">Новое бронирование</h3>
        <form onSubmit={(e) => { e.preventDefault(); onSubmit(formData); }} className="space-y-4">
          <select
            value={formData.table_id}
            onChange={e => setFormData({...formData, table_id: parseInt(e.target.value)})}
            className="w-full px-4 py-2 border rounded-lg"
            required
          >
            <option value="">Выберите стол</option>
            {tables.map(table => (
              <option key={table.id} value={table.id}>
                Стол {table.table_number} ({table.capacity} мест)
              </option>
            ))}
          </select>

          <input
            type="text"
            placeholder="Имя гостя"
            value={formData.guest_name}
            onChange={e => setFormData({...formData, guest_name: e.target.value})}
            className="w-full px-4 py-2 border rounded-lg"
            required
          />

          <input
            type="tel"
            placeholder="Телефон"
            value={formData.guest_phone}
            onChange={e => setFormData({...formData, guest_phone: e.target.value})}
            className="w-full px-4 py-2 border rounded-lg"
            required
          />

          <input
            type="number"
            placeholder="Количество гостей"
            value={formData.guest_count}
            onChange={e => setFormData({...formData, guest_count: parseInt(e.target.value)})}
            className="w-full px-4 py-2 border rounded-lg"
            min="1"
          />

          <input
            type="date"
            value={formData.reservation_date}
            onChange={e => setFormData({...formData, reservation_date: e.target.value})}
            className="w-full px-4 py-2 border rounded-lg"
            required
          />

          <input
            type="time"
            value={formData.reservation_time}
            onChange={e => setFormData({...formData, reservation_time: e.target.value})}
            className="w-full px-4 py-2 border rounded-lg"
            required
          />

          <textarea
            placeholder="Особые пожелания"
            value={formData.special_requests}
            onChange={e => setFormData({...formData, special_requests: e.target.value})}
            className="w-full px-4 py-2 border rounded-lg"
            rows="2"
          />

          <div className="flex gap-2">
            <button type="submit" className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg">
              Создать
            </button>
            <button type="button" onClick={onClose} className="px-4 py-2 border rounded-lg">
              Отмена
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
EOF

# =====================================================
# 5. Frontend - Страница аналитики
# =====================================================
echo -e "${YELLOW}[5/8] Создание страницы аналитики...${NC}"

cat > $PROJECT_DIR/frontend/src/pages/admin/Analytics.jsx <<'EOF'
import { useEffect, useState } from 'react'
import axios from 'axios'

export default function Analytics() {
  const [data, setData] = useState(null)

  useEffect(() => {
    fetchAnalytics()
  }, [])

  const fetchAnalytics = async () => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get('/api/analytics/overview', {
        headers: { Authorization: `Bearer ${token}` }
      })
      setData(response.data)
    } catch (error) {
      console.error('Error:', error)
    }
  }

  if (!data) return <div className="min-h-screen flex items-center justify-center">Загрузка...</div>

  return (
    <div className="min-h-screen bg-gray-50 p-4">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-2xl font-bold mb-6">Аналитика</h1>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          <div className="bg-white rounded-xl shadow-md p-6">
            <div className="text-sm text-gray-600 mb-1">Общая выручка</div>
            <div className="text-3xl font-bold text-green-600">{data.total_revenue?.toLocaleString()} ₸</div>
          </div>

          <div className="bg-white rounded-xl shadow-md p-6">
            <div className="text-sm text-gray-600 mb-1">Чаевые</div>
            <div className="text-3xl font-bold text-blue-600">{data.total_tips?.toLocaleString()} ₸</div>
          </div>

          <div className="bg-white rounded-xl shadow-md p-6">
            <div className="text-sm text-gray-600 mb-1">Всего заказов</div>
            <div className="text-3xl font-bold text-purple-600">{data.total_orders}</div>
          </div>

          <div className="bg-white rounded-xl shadow-md p-6">
            <div className="text-sm text-gray-600 mb-1">Средний чек</div>
            <div className="text-3xl font-bold text-orange-600">{data.avg_check?.toLocaleString()} ₸</div>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-md p-6">
          <h2 className="text-xl font-bold mb-4">Популярные блюда</h2>
          <div className="space-y-3">
            {data.popular_dishes?.map((dish, index) => (
              <div key={dish.dish_id} className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center gap-3">
                  <span className="text-2xl font-bold text-gray-400">#{index + 1}</span>
                  <div>
                    <div className="font-semibold">Блюдо #{dish.dish_id}</div>
                    <div className="text-sm text-gray-600">Заказано: {dish.quantity} раз</div>
                  </div>
                </div>
                <div className="text-lg font-bold text-green-600">{dish.revenue?.toLocaleString()} ₸</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
EOF

# =====================================================
# 6. Обновление роутинга и Dashboard
# =====================================================
echo -e "${YELLOW}[6/8] Обновление роутинга...${NC}"

cat > $PROJECT_DIR/frontend/src/App.jsx <<'EOF'
import { useState } from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Restaurants from './pages/admin/Restaurants'
import Menu from './pages/admin/Menu'
import Halls from './pages/admin/Halls'
import Reservations from './pages/admin/Reservations'
import Analytics from './pages/admin/Analytics'
import QRPage from './pages/QRPage'
import MenuPage from './pages/MenuPage'
import CheckoutPage from './pages/CheckoutPage'
import OrderSuccess from './pages/OrderSuccess'
import MyOrders from './pages/MyOrders'
import WaiterDashboard from './pages/waiter/WaiterDashboard'

function App() {
  const [token, setToken] = useState(localStorage.getItem('token'))

  const ProtectedRoute = ({ children }) => {
    return token ? children : <Navigate to="/login" />
  }

  return (
    <Router>
      <Routes>
        <Route path="/login" element={<Login setToken={setToken} />} />
        <Route path="/qr/:shortCode" element={<QRPage />} />
        <Route path="/menu/:restaurantId" element={<MenuPage />} />
        
        <Route path="/dashboard" element={<ProtectedRoute><Dashboard setToken={setToken} /></ProtectedRoute>} />
        <Route path="/waiter" element={<ProtectedRoute><WaiterDashboard /></ProtectedRoute>} />
        <Route path="/checkout" element={<ProtectedRoute><CheckoutPage /></ProtectedRoute>} />
        <Route path="/order-success" element={<ProtectedRoute><OrderSuccess /></ProtectedRoute>} />
        <Route path="/my-orders" element={<ProtectedRoute><MyOrders /></ProtectedRoute>} />
        <Route path="/admin/restaurants" element={<ProtectedRoute><Restaurants /></ProtectedRoute>} />
        <Route path="/admin/menu/:restaurantId" element={<ProtectedRoute><Menu /></ProtectedRoute>} />
        <Route path="/admin/halls/:restaurantId" element={<ProtectedRoute><Halls /></ProtectedRoute>} />
        <Route path="/admin/reservations/:restaurantId" element={<ProtectedRoute><Reservations /></ProtectedRoute>} />
        <Route path="/admin/analytics/:restaurantId" element={<ProtectedRoute><Analytics /></ProtectedRoute>} />
        <Route path="/" element={<Navigate to="/dashboard" />} />
      </Routes>
    </Router>
  )
}

export default App
EOF

# Обновление Dashboard с новыми ссылками
cat > $PROJECT_DIR/frontend/src/pages/Dashboard.jsx <<'EOF'
import { useEffect, useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import axios from 'axios'

export default function Dashboard({ setToken }) {
  const [user, setUser] = useState(null)
  const [restaurant, setRestaurant] = useState(null)
  const navigate = useNavigate()

  useEffect(() => {
    const fetchUser = async () => {
      try {
        const token = localStorage.getItem('token')
        const response = await axios.get('/api/auth/me', {
          headers: { Authorization: `Bearer ${token}` }
        })
        setUser(response.data)
        
        if (response.data.role === 'waiter') {
          navigate('/waiter')
          return
        }
        
        if (response.data.restaurant_id) {
          const restResponse = await axios.get(`/api/restaurants/${response.data.restaurant_id}`, {
            headers: { Authorization: `Bearer ${token}` }
          })
          setRestaurant(restResponse.data)
        }
      } catch (error) {
        handleLogout()
      }
    }
    fetchUser()
  }, [])

  const handleLogout = () => {
    localStorage.removeItem('token')
    setToken(null)
    navigate('/login')
  }

  if (!user) return <div className="min-h-screen flex items-center justify-center">Загрузка...</div>

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
      <header className="bg-white/80 backdrop-blur-lg shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold">Thanks PWA</h1>
            {restaurant && <p className="text-sm text-gray-600">{restaurant.name}</p>}
          </div>
          <button onClick={handleLogout} className="px-4 py-2 bg-red-500 text-white rounded-lg">
            Выйти
          </button>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8">
        <div className="bg-white/90 backdrop-blur-lg rounded-2xl shadow-lg p-6 mb-8">
          <h2 className="text-xl font-semibold mb-2">{user.full_name || 'Пользователь'}</h2>
          <p className="text-gray-600">{user.email}</p>
          <span className="inline-block mt-2 px-3 py-1 bg-purple-100 text-purple-800 rounded-full text-sm">
            {user.role.toUpperCase()}
          </span>
        </div>

        {user.role === 'user' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Link to="/my-orders" className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition">
              <div className="text-4xl mb-4">📋</div>
              <h3 className="text-xl font-semibold mb-2">Мои заказы</h3>
              <p className="text-gray-600">История заказов</p>
            </Link>
          </div>
        )}

        {user.role === 'moderator' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Link to="/admin/restaurants" className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition">
              <div className="text-4xl mb-4">🏪</div>
              <h3 className="text-xl font-semibold mb-2">Заведения</h3>
              <p className="text-gray-600">Управление</p>
            </Link>
          </div>
        )}

        {(user.role === 'admin' || user.role === 'moderator' || user.role === 'owner') && user.restaurant_id && (
          <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-6 mt-6">
            <Link to={`/admin/menu/${user.restaurant_id}`} className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition">
              <div className="text-4xl mb-4">📋</div>
              <h3 className="text-xl font-semibold mb-2">Меню</h3>
              <p className="text-gray-600">Управление меню</p>
            </Link>
            
            <Link to={`/admin/halls/${user.restaurant_id}`} className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition">
              <div className="text-4xl mb-4">🪑</div>
              <h3 className="text-xl font-semibold mb-2">Залы</h3>
              <p className="text-gray-600">Столы и QR-коды</p>
            </Link>

            <Link to={`/admin/reservations/${user.restaurant_id}`} className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition">
              <div className="text-4xl mb-4">📅</div>
              <h3 className="text-xl font-semibold mb-2">Бронирования</h3>
              <p className="text-gray-600">Управление бронями</p>
            </Link>

            <Link to={`/admin/analytics/${user.restaurant_id}`} className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition">
              <div className="text-4xl mb-4">📊</div>
              <h3 className="text-xl font-semibold mb-2">Аналитика</h3>
              <p className="text-gray-600">Отчёты и статистика</p>
            </Link>
          </div>
        )}

        <div className="bg-gradient-to-r from-blue-500 to-purple-600 rounded-2xl shadow-lg p-8 mt-8 text-white">
          <h3 className="text-2xl font-bold mb-4">✅ Stage 6+7 установлены!</h3>
          <ul className="space-y-2">
            <li>✓ Бронирования столов</li>
            <li>✓ Управление статусами броней</li>
            <li>✓ Аналитика продаж</li>
            <li>✓ Статистика чаевых</li>
            <li>✓ Популярные блюда</li>
          </ul>
        </div>
      </main>
    </div>
  )
}
EOF

# =====================================================
# 7. Сборка Frontend
# =====================================================
echo -e "${YELLOW}[7/8] Сборка Frontend...${NC}"
cd $PROJECT_DIR/frontend
pnpm run build
systemctl reload nginx

# =====================================================
# 8. Запуск Backend
# =====================================================
echo -e "${YELLOW}[8/8] Запуск Backend...${NC}"
systemctl start thanks-backend
sleep 3

# Создание скрипта обновления
cat > /opt/thanks/scripts/update_stage6_7.sh <<'EOF'
#!/bin/bash
set -e
echo "🔄 Обновление Stage 6+7..."
systemctl stop thanks-backend
cd /opt/thanks/backend
source venv/bin/activate
pip install -r requirements.txt --upgrade
systemctl start thanks-backend
cd /opt/thanks/frontend
pnpm install
pnpm run build
systemctl reload nginx
echo "✅ Stage 6+7 обновлены!"
EOF

chmod +x /opt/thanks/scripts/update_stage6_7.sh

# Итоговая информация
echo ""
echo "════════════════════════════════════════════════"
echo "✅ THANKS PWA - STAGE 6+7 УСТАНОВЛЕНЫ УСПЕШНО!"
echo "════════════════════════════════════════════════"
echo ""
echo "✨ Новые возможности:"
echo ""
echo "📅 БРОНИРОВАНИЯ:"
echo "  ✅ Создание броней для столов"
echo "  ✅ Календарь бронирований"
echo "  ✅ Статусы: подтверждено → прибыл → посажен → завершено"
echo "  ✅ Особые пожелания гостей"
echo ""
echo "📊 АНАЛИТИКА:"
echo "  ✅ Общая выручка"
echo "  ✅ Чаевые официантам"
echo "  ✅ Количество заказов"
echo "  ✅ Средний чек"
echo "  ✅ ТОП-5 популярных блюд"
echo ""
echo "🔗 Доступ:"
echo "  Админ: admin@restaurant.kz / Bitcoin1"
echo "  URL: http://217.11.74.100"
echo ""
echo "📚 Следующий этап: Stage 8+9 - UI/UX и WebSocket"
echo "════════════════════════════════════════════════"
