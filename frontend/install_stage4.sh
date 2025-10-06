#!/bin/bash

# =====================================================
# THANKS PWA - STAGE 4: Гостевой функционал и заказы
# =====================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="/opt/thanks"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}THANKS PWA - Stage 4 Installation${NC}"
echo -e "${GREEN}Гостевой функционал и заказы${NC}"
echo -e "${GREEN}================================${NC}\n"

if [ "$EUID" -ne 0 ]; then 
   echo -e "${RED}Запустите скрипт с правами root (sudo)${NC}"
   exit 1
fi

# =====================================================
# 1. Остановка backend
# =====================================================
echo -e "${YELLOW}[1/6] Остановка backend...${NC}"
systemctl stop thanks-backend

# =====================================================
# 2. Создание таблиц для заказов
# =====================================================
echo -e "${YELLOW}[2/6] Создание таблиц заказов...${NC}"

sudo -u postgres psql -d thanks_db <<'SQL'
-- Таблица заказов
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    table_id INTEGER REFERENCES tables(id),
    user_id INTEGER REFERENCES users(id),
    status VARCHAR DEFAULT 'pending',
    total_amount NUMERIC(10,2) DEFAULT 0,
    tips_amount NUMERIC(10,2) DEFAULT 0,
    service_fee NUMERIC(10,2) DEFAULT 0,
    is_paid BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица позиций заказа
CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    dish_id INTEGER REFERENCES dishes(id),
    quantity INTEGER DEFAULT 1,
    price NUMERIC(10,2),
    total NUMERIC(10,2),
    special_instructions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица вызовов официанта
CREATE TABLE IF NOT EXISTS waiter_calls (
    id SERIAL PRIMARY KEY,
    table_id INTEGER REFERENCES tables(id),
    user_id INTEGER REFERENCES users(id),
    status VARCHAR DEFAULT 'pending',
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);

-- Индексы
CREATE INDEX IF NOT EXISTS idx_orders_table ON orders(table_id);
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_waiter_calls_table ON waiter_calls(table_id);
CREATE INDEX IF NOT EXISTS idx_waiter_calls_status ON waiter_calls(status);

-- Права доступа
GRANT ALL PRIVILEGES ON TABLE orders TO thanks_user;
GRANT ALL PRIVILEGES ON TABLE order_items TO thanks_user;
GRANT ALL PRIVILEGES ON TABLE waiter_calls TO thanks_user;
GRANT USAGE, SELECT ON SEQUENCE orders_id_seq TO thanks_user;
GRANT USAGE, SELECT ON SEQUENCE order_items_id_seq TO thanks_user;
GRANT USAGE, SELECT ON SEQUENCE waiter_calls_id_seq TO thanks_user;
SQL

# =====================================================
# 3. Обновление models.py
# =====================================================
echo -e "${YELLOW}[3/6] Обновление моделей...${NC}"

cat >> $PROJECT_DIR/backend/models.py <<'EOF'

class OrderStatus(str, enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    COOKING = "cooking"
    READY = "ready"
    SERVING = "serving"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class Order(Base):
    __tablename__ = "orders"
    
    id = Column(Integer, primary_key=True, index=True)
    table_id = Column(Integer, ForeignKey("tables.id"))
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    status = Column(Enum(OrderStatus), default=OrderStatus.PENDING)
    total_amount = Column(Float, default=0.0)
    tips_amount = Column(Float, default=0.0)
    service_fee = Column(Float, default=0.0)
    is_paid = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class OrderItem(Base):
    __tablename__ = "order_items"
    
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    dish_id = Column(Integer, ForeignKey("dishes.id"))
    quantity = Column(Integer, default=1)
    price = Column(Float)
    total = Column(Float)
    special_instructions = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class WaiterCall(Base):
    __tablename__ = "waiter_calls"
    
    id = Column(Integer, primary_key=True, index=True)
    table_id = Column(Integer, ForeignKey("tables.id"))
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    status = Column(String, default="pending")
    message = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    resolved_at = Column(DateTime, nullable=True)
EOF

# =====================================================
# 4. Обновление Backend API
# =====================================================
echo -e "${YELLOW}[4/6] Обновление API...${NC}"

cat >> $PROJECT_DIR/backend/main.py <<'EOF'

# =====================================================
# Заказы (Stage 4)
# =====================================================
from models import Order, OrderItem, OrderStatus, WaiterCall

class OrderItemCreate(BaseModel):
    dish_id: int
    quantity: int = 1
    special_instructions: Optional[str] = None

class OrderCreate(BaseModel):
    table_id: int
    items: List[OrderItemCreate]
    tips_amount: float = 0.0

class OrderItemResponse(BaseModel):
    id: int
    dish_id: int
    quantity: int
    price: float
    total: float
    special_instructions: Optional[str]
    
    class Config:
        from_attributes = True

class OrderResponse(BaseModel):
    id: int
    table_id: int
    user_id: Optional[int]
    status: str
    total_amount: float
    tips_amount: float
    service_fee: float
    is_paid: bool
    created_at: datetime
    items: List[OrderItemResponse] = []
    
    class Config:
        from_attributes = True

class WaiterCallCreate(BaseModel):
    table_id: int
    message: Optional[str] = None

class WaiterCallResponse(BaseModel):
    id: int
    table_id: int
    status: str
    message: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True

# Создание заказа
@app.post("/orders", response_model=OrderResponse)
def create_order(data: OrderCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Получить ресторан через стол
    table = db.query(Table).filter(Table.id == data.table_id).first()
    if not table:
        raise HTTPException(status_code=404, detail="Table not found")
    
    hall = db.query(Hall).filter(Hall.id == table.hall_id).first()
    restaurant = db.query(Restaurant).filter(Restaurant.id == hall.restaurant_id).first()
    
    # Подсчет суммы
    total_amount = 0.0
    order_items = []
    
    for item_data in data.items:
        dish = db.query(Dish).filter(Dish.id == item_data.dish_id).first()
        if not dish:
            continue
        
        item_total = dish.price * item_data.quantity
        total_amount += item_total
        order_items.append({
            "dish": dish,
            "quantity": item_data.quantity,
            "price": dish.price,
            "total": item_total,
            "special_instructions": item_data.special_instructions
        })
    
    # Сервисный сбор
    service_fee = total_amount * (restaurant.service_fee_percent / 100)
    
    # Создание заказа
    order = Order(
        table_id=data.table_id,
        user_id=current_user.id,
        status=OrderStatus.PENDING,
        total_amount=total_amount,
        tips_amount=data.tips_amount,
        service_fee=service_fee,
        is_paid=False
    )
    db.add(order)
    db.flush()
    
    # Добавление позиций
    for item in order_items:
        order_item = OrderItem(
            order_id=order.id,
            dish_id=item["dish"].id,
            quantity=item["quantity"],
            price=item["price"],
            total=item["total"],
            special_instructions=item["special_instructions"]
        )
        db.add(order_item)
    
    db.commit()
    db.refresh(order)
    
    # Получить все items для ответа
    order.items = db.query(OrderItem).filter(OrderItem.order_id == order.id).all()
    
    return order

# Получение заказов пользователя
@app.get("/my-orders", response_model=List[OrderResponse])
def get_my_orders(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    orders = db.query(Order).filter(Order.user_id == current_user.id).order_by(Order.created_at.desc()).all()
    
    for order in orders:
        order.items = db.query(OrderItem).filter(OrderItem.order_id == order.id).all()
    
    return orders

# Получение текущего заказа на столе
@app.get("/tables/{table_id}/current-order", response_model=Optional[OrderResponse])
def get_current_order(table_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    order = db.query(Order).filter(
        Order.table_id == table_id,
        Order.user_id == current_user.id,
        Order.is_paid == False
    ).order_by(Order.created_at.desc()).first()
    
    if order:
        order.items = db.query(OrderItem).filter(OrderItem.order_id == order.id).all()
    
    return order

# Обновление статуса заказа (официант/админ)
@app.patch("/orders/{order_id}/status")
def update_order_status(order_id: int, status: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role not in [UserRole.MODERATOR, UserRole.ADMIN, UserRole.WAITER]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    try:
        order.status = OrderStatus[status.upper()]
        order.updated_at = datetime.utcnow()
        db.commit()
    except KeyError:
        raise HTTPException(status_code=400, detail="Invalid status")
    
    return {"message": f"Order status updated to {status}"}

# Имитация оплаты
@app.post("/orders/{order_id}/pay")
def pay_order(order_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    order = db.query(Order).filter(Order.id == order_id, Order.user_id == current_user.id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    if order.is_paid:
        raise HTTPException(status_code=400, detail="Order already paid")
    
    # Имитация успешной оплаты
    order.is_paid = True
    order.status = OrderStatus.ACCEPTED
    order.updated_at = datetime.utcnow()
    db.commit()
    
    return {
        "success": True,
        "message": "Payment successful",
        "total": order.total_amount + order.tips_amount + order.service_fee
    }

# Вызов официанта
@app.post("/waiter-call", response_model=WaiterCallResponse)
def call_waiter(data: WaiterCallCreate, db: Session = Depends(get_db)):
    waiter_call = WaiterCall(
        table_id=data.table_id,
        message=data.message,
        status="pending"
    )
    db.add(waiter_call)
    db.commit()
    db.refresh(waiter_call)
    return waiter_call

# Получение вызовов (для официантов)
@app.get("/waiter-calls", response_model=List[WaiterCallResponse])
def get_waiter_calls(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role not in [UserRole.MODERATOR, UserRole.ADMIN, UserRole.WAITER]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    return db.query(WaiterCall).filter(WaiterCall.status == "pending").order_by(WaiterCall.created_at.desc()).all()

# Закрыть вызов
@app.patch("/waiter-calls/{call_id}/resolve")
def resolve_waiter_call(call_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role not in [UserRole.MODERATOR, UserRole.ADMIN, UserRole.WAITER]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    call = db.query(WaiterCall).filter(WaiterCall.id == call_id).first()
    if not call:
        raise HTTPException(status_code=404, detail="Call not found")
    
    call.status = "resolved"
    call.resolved_at = datetime.utcnow()
    db.commit()
    
    return {"message": "Call resolved"}
EOF

# =====================================================
# 5. Создание Frontend страниц
# =====================================================
echo -e "${YELLOW}[5/6] Создание Frontend...${NC}"

# Страница QR (для гостей)
cat > $PROJECT_DIR/frontend/src/pages/QRPage.jsx <<'EOF'
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
      
      // Сохранить контекст стола
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
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-xl">Загрузка...</div>
      </div>
    )
  }

  if (!data) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-xl text-red-500">Стол не найден</div>
      </div>
    )
  }

  const token = localStorage.getItem('token')

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-500 to-purple-600 p-4">
      <div className="max-w-md mx-auto pt-8">
        <div className="bg-white/90 backdrop-blur-lg rounded-2xl shadow-2xl p-8 mb-6">
          <h1 className="text-3xl font-bold mb-2">{data.restaurant.name}</h1>
          <p className="text-gray-600 mb-4">{data.restaurant.address}</p>
          
          <div className="bg-blue-50 rounded-lg p-4 mb-6">
            <div className="flex justify-between items-center">
              <div>
                <div className="text-sm text-gray-600">Ваш стол</div>
                <div className="text-2xl font-bold text-blue-600">№ {data.table.table_number}</div>
              </div>
              <div className="text-right">
                <div className="text-sm text-gray-600">Вместимость</div>
                <div className="text-xl font-semibold">{data.table.capacity} чел.</div>
              </div>
            </div>
          </div>

          {!token ? (
            <div className="space-y-3">
              <button
                onClick={() => navigate(`/menu/${data.restaurant.id}?guest=true`)}
                className="w-full bg-gradient-to-r from-blue-500 to-purple-600 text-white py-3 rounded-lg font-semibold"
              >
                Посмотреть меню
              </button>
              
              <button
                onClick={handleCallWaiter}
                className="w-full bg-yellow-500 text-white py-3 rounded-lg font-semibold"
              >
                Позвать официанта
              </button>
              
              <button
                onClick={() => navigate('/login')}
                className="w-full border-2 border-blue-500 text-blue-600 py-3 rounded-lg font-semibold"
              >
                Войти для заказа
              </button>
            </div>
          ) : (
            <div className="space-y-3">
              <button
                onClick={() => navigate(`/menu/${data.restaurant.id}`)}
                className="w-full bg-gradient-to-r from-blue-500 to-purple-600 text-white py-3 rounded-lg font-semibold"
              >
                Открыть меню и заказать
              </button>
              
              <button
                onClick={handleCallWaiter}
                className="w-full bg-yellow-500 text-white py-3 rounded-lg font-semibold"
              >
                Позвать официанта
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
EOF

# Страница меню для гостей/пользователей
cat > $PROJECT_DIR/frontend/src/pages/MenuPage.jsx <<'EOF'
import { useEffect, useState } from 'react'
import { useParams, useSearchParams, useNavigate } from 'react-router-dom'
import axios from 'axios'

export default function MenuPage() {
  const { restaurantId } = useParams()
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const isGuest = searchParams.get('guest') === 'true'
  
  const [menu, setMenu] = useState([])
  const [cart, setCart] = useState([])
  const [selectedCategory, setSelectedCategory] = useState(null)

  useEffect(() => {
    fetchMenu()
  }, [restaurantId])

  const fetchMenu = async () => {
    try {
      const response = await axios.get(`/api/restaurants/${restaurantId}/menu`)
      setMenu(response.data)
      if (response.data.length > 0) {
        setSelectedCategory(response.data[0])
      }
    } catch (error) {
      console.error('Error:', error)
    }
  }

  const addToCart = (dish) => {
    if (isGuest) {
      alert('Войдите для оформления заказа')
      return
    }
    
    const existing = cart.find(item => item.dish.id === dish.id)
    if (existing) {
      setCart(cart.map(item => 
        item.dish.id === dish.id 
          ? { ...item, quantity: item.quantity + 1 }
          : item
      ))
    } else {
      setCart([...cart, { dish, quantity: 1 }])
    }
  }

  const removeFromCart = (dishId) => {
    setCart(cart.filter(item => item.dish.id !== dishId))
  }

  const updateQuantity = (dishId, delta) => {
    setCart(cart.map(item => {
      if (item.dish.id === dishId) {
        const newQty = item.quantity + delta
        return newQty > 0 ? { ...item, quantity: newQty } : item
      }
      return item
    }).filter(item => item.quantity > 0))
  }

  const getTotalAmount = () => {
    return cart.reduce((sum, item) => sum + (item.dish.price * item.quantity), 0)
  }

  return (
    <div className="flex flex-col h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm p-4 flex justify-between items-center">
        <button onClick={() => navigate(-1)} className="text-2xl">←</button>
        <h1 className="text-xl font-bold">Меню</h1>
        <div className="w-8"></div>
      </header>

      {/* Categories */}
      <div className="bg-white border-b px-4 py-2 overflow-x-auto">
        <div className="flex gap-2">
          {menu.map(cat => (
            <button
              key={cat.id}
              onClick={() => setSelectedCategory(cat)}
              className={`px-4 py-2 rounded-full whitespace-nowrap ${
                selectedCategory?.id === cat.id
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100'
              }`}
            >
              {cat.name}
            </button>
          ))}
        </div>
      </div>

      {/* Dishes */}
      <div className="flex-1 overflow-y-auto p-4 pb-24">
        <div className="grid gap-4">
          {selectedCategory?.dishes.map(dish => (
            <div key={dish.id} className="bg-white rounded-lg shadow-md flex overflow-hidden">
              <img 
                src={dish.image_url} 
                alt={dish.name}
                className="w-24 h-24 object-cover"
              />
              <div className="flex-1 p-3">
                <h3 className="font-semibold">{dish.name}</h3>
                <p className="text-sm text-gray-600 line-clamp-2">{dish.description}</p>
                <div className="flex justify-between items-center mt-2">
                  <span className="text-lg font-bold text-blue-600">{dish.price} ₸</span>
                  <button
                    onClick={() => addToCart(dish)}
                    className="px-4 py-1 bg-blue-600 text-white rounded-lg text-sm"
                    disabled={isGuest}
                  >
                    {isGuest ? 'Войдите' : '+'}
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Cart */}
      {!isGuest && cart.length > 0 && (
        <div className="fixed bottom-0 left-0 right-0 bg-white border-t p-4">
          <div className="max-w-4xl mx-auto">
            <div className="flex justify-between items-center mb-2">
              <span className="font-semibold">Корзина ({cart.length})</span>
              <span className="text-xl font-bold">{getTotalAmount()} ₸</span>
            </div>
            <button
              onClick={() => navigate('/checkout', { state: { cart } })}
              className="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold"
            >
              Оформить заказ
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
EOF

# Страница оформления заказа
cat > $PROJECT_DIR/frontend/src/pages/CheckoutPage.jsx <<'EOF'
import { useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import axios from 'axios'

const TIP_OPTIONS = [5, 10, 15, 20]

export default function CheckoutPage() {
  const location = useLocation()
  const navigate = useNavigate()
  const cart = location.state?.cart || []
  
  const [tipPercent, setTipPercent] = useState(null)
  const [customTip, setCustomTip] = useState('')
  const [loading, setLoading] = useState(false)

  const subtotal = cart.reduce((sum, item) => sum + (item.dish.price * item.quantity), 0)
  const tipAmount = tipPercent 
    ? (subtotal * tipPercent / 100) 
    : parseFloat(customTip) || 0
  const total = subtotal + tipAmount

  const handleCheckout = async () => {
    const tableData = JSON.parse(localStorage.getItem('currentTable') || '{}')
    
    if (!tableData.id) {
      alert('Ошибка: стол не определен')
      return
    }

    setLoading(true)
    
    try {
      const token = localStorage.getItem('token')
      
      // Создать заказ
      const orderResponse = await axios.post('/api/orders', {
        table_id: tableData.id,
        items: cart.map(item => ({
          dish_id: item.dish.id,
          quantity: item.quantity
        })),
        tips_amount: tipAmount
      }, {
        headers: { Authorization: `Bearer ${token}` }
      })

      // Имитация оплаты
      await axios.post(`/api/orders/${orderResponse.data.id}/pay`, {}, {
        headers: { Authorization: `Bearer ${token}` }
      })

      navigate('/order-success')
    } catch (error) {
      console.error('Error:', error)
      alert('Ошибка при оформлении заказа')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 p-4">
      <div className="max-w-2xl mx-auto">
        <div className="bg-white rounded-xl shadow-md p-6 mb-4">
          <h2 className="text-2xl font-bold mb-4">Ваш заказ</h2>
          
          {cart.map(item => (
            <div key={item.dish.id} className="flex justify-between py-2 border-b">
              <div>
                <div className="font-medium">{item.dish.name}</div>
                <div className="text-sm text-gray-600">{item.quantity} × {item.dish.price} ₸</div>
              </div>
              <div className="font-semibold">{item.dish.price * item.quantity} ₸</div>
            </div>
          ))}
          
          <div className="flex justify-between py-3 font-semibold text-lg">
            <span>Подитог:</span>
            <span>{subtotal} ₸</span>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-md p-6 mb-4">
          <h3 className="font-bold mb-3">Чаевые</h3>
          
          <div className="grid grid-cols-4 gap-2 mb-3">
            {TIP_OPTIONS.map(percent => (
              <button
                key={percent}
                onClick={() => { setTipPercent(percent); setCustomTip(''); }}
                className={`py-2 rounded-lg border-2 ${
                  tipPercent === percent
                    ? 'border-blue-600 bg-blue-50 text-blue-600'
                    : 'border-gray-200'
                }`}
              >
                {percent}%
              </button>
            ))}
          </div>
          
          <div>
            <input
              type="number"
              placeholder="Своя сумма"
              value={customTip}
              onChange={(e) => { setCustomTip(e.target.value); setTipPercent(null); }}
              className="w-full px-4 py-2 border rounded-lg"
            />
          </div>
          
          {tipAmount > 0 && (
            <div className="mt-2 text-sm text-gray-600">
              Чаевые: {tipAmount.toFixed(0)} ₸
            </div>
          )}
        </div>

        <div className="bg-white rounded-xl shadow-md p-6 mb-4">
          <div className="flex justify-between items-center text-xl font-bold">
            <span>Итого:</span>
            <span>{total.toFixed(0)} ₸</span>
          </div>
        </div>

        <button
          onClick={handleCheckout}
          disabled={loading}
          className="w-full bg-blue-600 text-white py-4 rounded-xl font-bold text-lg disabled:bg-gray-400"
        >
          {loading ? 'Обработка...' : 'Оплатить'}
        </button>
      </div>
    </div>
  )
}
EOF

# Страница успешного заказа
cat > $PROJECT_DIR/frontend/src/pages/OrderSuccess.jsx <<'EOF'
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
EOF

# Страница "Мои заказы"
cat > $PROJECT_DIR/frontend/src/pages/MyOrders.jsx <<'EOF'
import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'

const ORDER_STATUSES = {
  pending: { label: 'Ожидает', color: 'bg-gray-500' },
  accepted: { label: 'Принят', color: 'bg-blue-500' },
  cooking: { label: 'Готовится', color: 'bg-yellow-500' },
  ready: { label: 'Готов', color: 'bg-orange-500' },
  serving: { label: 'Несут', color: 'bg-purple-500' },
  completed: { label: 'Подан', color: 'bg-green-500' },
  cancelled: { label: 'Отменен', color: 'bg-red-500' }
}

export default function MyOrders() {
  const navigate = useNavigate()
  const [orders, setOrders] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchOrders()
  }, [])

  const fetchOrders = async () => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get('/api/my-orders', {
        headers: { Authorization: `Bearer ${token}` }
      })
      setOrders(response.data)
      setLoading(false)
    } catch (error) {
      console.error('Error:', error)
      setLoading(false)
    }
  }

  if (loading) {
    return <div className="min-h-screen flex items-center justify-center">Загрузка...</div>
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow-sm p-4 flex items-center gap-4">
        <button onClick={() => navigate(-1)} className="text-2xl">←</button>
        <h1 className="text-xl font-bold">Мои заказы</h1>
      </header>

      <div className="p-4 space-y-4">
        {orders.length === 0 ? (
          <div className="text-center py-12 text-gray-500">
            У вас пока нет заказов
          </div>
        ) : (
          orders.map(order => (
            <div key={order.id} className="bg-white rounded-xl shadow-md p-4">
              <div className="flex justify-between items-start mb-3">
                <div>
                  <div className="text-sm text-gray-500">
                    {new Date(order.created_at).toLocaleString('ru-RU')}
                  </div>
                  <div className="font-bold text-lg">
                    Заказ #{order.id}
                  </div>
                </div>
                <span className={`px-3 py-1 rounded-full text-white text-sm ${ORDER_STATUSES[order.status]?.color}`}>
                  {ORDER_STATUSES[order.status]?.label}
                </span>
              </div>

              <div className="space-y-2 mb-3">
                {order.items?.map(item => (
                  <div key={item.id} className="flex justify-between text-sm">
                    <span>{item.quantity}x Блюдо #{item.dish_id}</span>
                    <span>{item.total} ₸</span>
                  </div>
                ))}
              </div>

              <div className="border-t pt-3 flex justify-between font-bold">
                <span>Итого:</span>
                <span>{(order.total_amount + order.tips_amount + order.service_fee).toFixed(0)} ₸</span>
              </div>

              {order.is_paid && (
                <div className="mt-2 text-sm text-green-600">✓ Оплачено</div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  )
}
EOF

# Обновление роутинга
cat > $PROJECT_DIR/frontend/src/App.jsx <<'EOF'
import { useState } from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Restaurants from './pages/admin/Restaurants'
import Menu from './pages/admin/Menu'
import Halls from './pages/admin/Halls'
import QRPage from './pages/QRPage'
import MenuPage from './pages/MenuPage'
import CheckoutPage from './pages/CheckoutPage'
import OrderSuccess from './pages/OrderSuccess'
import MyOrders from './pages/MyOrders'

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
        
        <Route 
          path="/dashboard" 
          element={
            <ProtectedRoute>
              <Dashboard setToken={setToken} />
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/checkout" 
          element={
            <ProtectedRoute>
              <CheckoutPage />
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/order-success" 
          element={
            <ProtectedRoute>
              <OrderSuccess />
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/my-orders" 
          element={
            <ProtectedRoute>
              <MyOrders />
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/admin/restaurants" 
          element={
            <ProtectedRoute>
              <Restaurants />
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/admin/menu/:restaurantId" 
          element={
            <ProtectedRoute>
              <Menu />
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/admin/halls/:restaurantId" 
          element={
            <ProtectedRoute>
              <Halls />
            </ProtectedRoute>
          } 
        />
        <Route path="/" element={<Navigate to="/dashboard" />} />
      </Routes>
    </Router>
  )
}

export default App
EOF

# Обновление Dashboard
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
    localStorage.removeItem('user')
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
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
            <Link to="/my-orders" className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition">
              <div className="text-4xl mb-4">📋</div>
              <h3 className="text-xl font-semibold mb-2">Мои заказы</h3>
              <p className="text-gray-600">История и статусы заказов</p>
            </Link>
          </div>
        )}

        {user.role === 'moderator' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Link to="/admin/restaurants" className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition">
              <div className="text-4xl mb-4">🏪</div>
              <h3 className="text-xl font-semibold mb-2">Заведения</h3>
              <p className="text-gray-600">Управление ресторанами</p>
            </Link>
          </div>
        )}

        {(user.role === 'admin' || user.role === 'moderator') && user.restaurant_id && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-6">
            <Link to={`/admin/menu/${user.restaurant_id}`} className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition">
              <div className="text-4xl mb-4">📋</div>
              <h3 className="text-xl font-semibold mb-2">Меню</h3>
              <p className="text-gray-600">Управление меню</p>
            </Link>
            
            <Link to={`/admin/halls/${user.restaurant_id}`} className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition">
              <div className="text-4xl mb-4">🪑</div>
              <h3 className="text-xl font-semibold mb-2">Залы и столы</h3>
              <p className="text-gray-600">Конструктор залов, QR-коды</p>
            </Link>
          </div>
        )}

        <div className="bg-gradient-to-r from-blue-500 to-purple-600 rounded-2xl shadow-lg p-8 mt-8 text-white">
          <h3 className="text-2xl font-bold mb-4">✅ Stage 4 установлен!</h3>
          <ul className="space-y-2">
            <li>✓ QR-сканирование и контекст стола</li>
            <li>✓ Гостевой просмотр меню</li>
            <li>✓ Вызов официанта</li>
            <li>✓ Корзина и заказы для пользователей</li>
            <li>✓ Чаевые (проценты + своя сумма)</li>
            <li>✓ Статусы заказа (5 этапов)</li>
            <li>✓ Имитация оплаты</li>
          </ul>
        </div>
      </main>
    </div>
  )
}
EOF

# =====================================================
# 6. Сборка и запуск
# =====================================================
echo -e "${YELLOW}[6/6] Сборка Frontend...${NC}"
cd $PROJECT_DIR/frontend
pnpm run build
systemctl reload nginx

systemctl start thanks-backend
sleep 3

# Создание скрипта обновления
cat > /opt/thanks/scripts/update_stage4.sh <<'EOF'
#!/bin/bash
set -e
echo "🔄 Обновление Stage 4..."
systemctl stop thanks-backend
cd /opt/thanks/backend
source venv/bin/activate
pip install -r requirements.txt --upgrade
systemctl start thanks-backend
cd /opt/thanks/frontend
pnpm install
pnpm run build
systemctl reload nginx
echo "✅ Stage 4 обновлен!"
EOF

chmod +x /opt/thanks/scripts/update_stage4.sh

# Итоговая информация
echo ""
echo "════════════════════════════════════════════════"
echo "✅ THANKS PWA - STAGE 4 УСТАНОВЛЕН УСПЕШНО!"
echo "════════════════════════════════════════════════"
echo ""
echo "🌐 Как тестировать:"
echo ""
echo "1. Зайдите в 'Залы и столы' как админ"
echo "2. Откройте любой стол и скопируйте QR-код (short_code)"
echo "3. Откройте в браузере: http://217.11.74.100/qr/{SHORT_CODE}"
echo ""
echo "✨ Новые возможности:"
echo "  ✅ QR-сканирование (контекст стола)"
echo "  ✅ Гостевой просмотр меню"
echo "  ✅ Вызов официанта (для всех)"
echo "  ✅ Корзина и оформление заказа"
echo "  ✅ Чаевые (5%, 10%, 15%, 20% + своя сумма)"
echo "  ✅ Имитация оплаты"
echo "  ✅ Статусы: Принят → На кухне → Готов → Несут → Подан"
echo "  ✅ История заказов"
echo ""
echo "📚 Следующий этап: Stage 5 - Панель официанта"
echo "════════════════════════════════════════════════"
