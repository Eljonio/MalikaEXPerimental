#!/bin/bash

# =====================================================
# THANKS PWA - STAGE 2: Анкета заведения и меню
# =====================================================
# Добавление: Заведения, Меню, Категории, Блюда
# =====================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="/opt/thanks"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}THANKS PWA - Stage 2 Installation${NC}"
echo -e "${GREEN}Анкета заведения и меню${NC}"
echo -e "${GREEN}================================${NC}\n"

# =====================================================
# 1. Проверка root прав
# =====================================================
if [ "$EUID" -ne 0 ]; then 
   echo -e "${RED}Запустите скрипт с правами root (sudo)${NC}"
   exit 1
fi

# =====================================================
# 2. Остановка backend для обновления
# =====================================================
echo -e "${YELLOW}[1/6] Остановка backend...${NC}"
systemctl stop thanks-backend

# =====================================================
# 3. Обновление Backend моделей
# =====================================================
echo -e "${YELLOW}[2/6] Обновление Backend моделей...${NC}"

cat > $PROJECT_DIR/backend/models.py <<'EOF'
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, Text, ForeignKey, JSON, Enum
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime
import enum

Base = declarative_base()

class UserRole(str, enum.Enum):
    GUEST = "guest"
    USER = "user"
    WAITER = "waiter"
    ADMIN = "admin"
    OWNER = "owner"
    MODERATOR = "moderator"

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    role = Column(Enum(UserRole), default=UserRole.GUEST)
    is_active = Column(Boolean, default=True)
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    restaurant = relationship("Restaurant", back_populates="staff")

class Restaurant(Base):
    __tablename__ = "restaurants"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    slug = Column(String, unique=True, index=True)
    description = Column(Text, nullable=True)
    logo_url = Column(String, nullable=True)
    
    # Контакты
    address = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    email = Column(String, nullable=True)
    website = Column(String, nullable=True)
    
    # Часы работы (JSON: {"monday": "10:00-22:00", ...})
    working_hours = Column(JSON, default={})
    
    # Настройки
    currency = Column(String, default="KZT")
    timezone = Column(String, default="Asia/Almaty")
    service_fee_percent = Column(Float, default=0.0)
    
    # Политики чаевых
    tips_enabled = Column(Boolean, default=True)
    tips_options = Column(JSON, default=[5, 10, 15, 20])  # Проценты
    
    # Статус
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Отношения
    staff = relationship("User", back_populates="restaurant")
    categories = relationship("Category", back_populates="restaurant", cascade="all, delete-orphan")
    halls = relationship("Hall", back_populates="restaurant", cascade="all, delete-orphan")

class Category(Base):
    __tablename__ = "categories"
    
    id = Column(Integer, primary_key=True, index=True)
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), nullable=False)
    name = Column(String, nullable=False)
    name_kz = Column(String, nullable=True)
    description = Column(Text, nullable=True)
    sort_order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    restaurant = relationship("Restaurant", back_populates="categories")
    dishes = relationship("Dish", back_populates="category", cascade="all, delete-orphan")

class Dish(Base):
    __tablename__ = "dishes"
    
    id = Column(Integer, primary_key=True, index=True)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=False)
    name = Column(String, nullable=False)
    name_kz = Column(String, nullable=True)
    description = Column(Text, nullable=True)
    description_kz = Column(Text, nullable=True)
    
    # Цена и изображение
    price = Column(Float, nullable=False)
    image_url = Column(String, nullable=True)
    
    # Характеристики
    cooking_time = Column(Integer, default=15)  # минуты
    weight = Column(Integer, nullable=True)  # граммы
    calories = Column(Integer, nullable=True)
    allergens = Column(JSON, default=[])  # ["молоко", "глютен", ...]
    
    # Статус
    is_available = Column(Boolean, default=True)
    is_stop_list = Column(Boolean, default=False)
    sort_order = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    category = relationship("Category", back_populates="dishes")
    modifiers = relationship("Modifier", back_populates="dish", cascade="all, delete-orphan")

class Modifier(Base):
    __tablename__ = "modifiers"
    
    id = Column(Integer, primary_key=True, index=True)
    dish_id = Column(Integer, ForeignKey("dishes.id"), nullable=False)
    name = Column(String, nullable=False)
    name_kz = Column(String, nullable=True)
    price = Column(Float, default=0.0)
    is_required = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    dish = relationship("Dish", back_populates="modifiers")

class Hall(Base):
    __tablename__ = "halls"
    
    id = Column(Integer, primary_key=True, index=True)
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), nullable=False)
    name = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    restaurant = relationship("Restaurant", back_populates="halls")
    tables = relationship("Table", back_populates="hall", cascade="all, delete-orphan")

class Table(Base):
    __tablename__ = "tables"
    
    id = Column(Integer, primary_key=True, index=True)
    hall_id = Column(Integer, ForeignKey("halls.id"), nullable=False)
    table_number = Column(String, nullable=False)
    capacity = Column(Integer, default=2)
    qr_code = Column(String, unique=True, index=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    hall = relationship("Hall", back_populates="tables")
EOF

# =====================================================
# 4. Обновление main.py с новыми эндпоинтами
# =====================================================
echo -e "${YELLOW}[3/6] Обновление API эндпоинтов...${NC}"

cat > $PROJECT_DIR/backend/main.py <<'EOF'
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from pydantic import BaseModel, EmailStr
from typing import Optional, List
import os

from models import Base, User, UserRole, Restaurant, Category, Dish, Modifier

# Конфигурация
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://thanks_user:Bitcoin1@localhost/thanks_db")
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# База данных
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Создание таблиц
Base.metadata.create_all(bind=engine)

# Безопасность
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# Зависимости
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise credentials_exception
    return user

# Pydantic схемы
class UserResponse(BaseModel):
    id: int
    email: str
    full_name: Optional[str]
    role: UserRole
    restaurant_id: Optional[int]
    
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

class RestaurantCreate(BaseModel):
    name: str
    description: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None

class RestaurantUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    working_hours: Optional[dict] = None
    service_fee_percent: Optional[float] = None
    tips_enabled: Optional[bool] = None

class RestaurantResponse(BaseModel):
    id: int
    name: str
    slug: str
    description: Optional[str]
    address: Optional[str]
    phone: Optional[str]
    currency: str
    working_hours: dict
    service_fee_percent: float
    tips_enabled: bool
    is_active: bool
    
    class Config:
        from_attributes = True

class CategoryCreate(BaseModel):
    name: str
    name_kz: Optional[str] = None
    description: Optional[str] = None

class CategoryResponse(BaseModel):
    id: int
    name: str
    name_kz: Optional[str]
    description: Optional[str]
    sort_order: int
    is_active: bool
    
    class Config:
        from_attributes = True

class ModifierCreate(BaseModel):
    name: str
    name_kz: Optional[str] = None
    price: float = 0.0
    is_required: bool = False

class ModifierResponse(BaseModel):
    id: int
    name: str
    name_kz: Optional[str]
    price: float
    is_required: bool
    
    class Config:
        from_attributes = True

class DishCreate(BaseModel):
    category_id: int
    name: str
    name_kz: Optional[str] = None
    description: Optional[str] = None
    price: float
    cooking_time: int = 15
    modifiers: List[ModifierCreate] = []

class DishResponse(BaseModel):
    id: int
    name: str
    name_kz: Optional[str]
    description: Optional[str]
    price: float
    image_url: Optional[str]
    cooking_time: int
    is_available: bool
    is_stop_list: bool
    modifiers: List[ModifierResponse] = []
    
    class Config:
        from_attributes = True

# FastAPI приложение
app = FastAPI(title="Thanks PWA API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =====================================================
# Авторизация
# =====================================================
@app.post("/auth/login", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    
    access_token = create_access_token(data={"sub": user.email}, expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    return {"access_token": access_token, "token_type": "bearer", "user": user}

@app.get("/auth/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user

# =====================================================
# Заведения (Модератор)
# =====================================================
@app.post("/restaurants", response_model=RestaurantResponse)
def create_restaurant(data: RestaurantCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role != UserRole.MODERATOR:
        raise HTTPException(status_code=403, detail="Only moderators can create restaurants")
    
    slug = data.name.lower().replace(" ", "-").replace("\"", "")
    restaurant = Restaurant(
        name=data.name,
        slug=slug,
        description=data.description,
        address=data.address,
        phone=data.phone
    )
    db.add(restaurant)
    db.commit()
    db.refresh(restaurant)
    return restaurant

@app.get("/restaurants", response_model=List[RestaurantResponse])
def list_restaurants(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role == UserRole.MODERATOR:
        return db.query(Restaurant).all()
    elif current_user.restaurant_id:
        return db.query(Restaurant).filter(Restaurant.id == current_user.restaurant_id).all()
    return []

@app.get("/restaurants/{restaurant_id}", response_model=RestaurantResponse)
def get_restaurant(restaurant_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    restaurant = db.query(Restaurant).filter(Restaurant.id == restaurant_id).first()
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")
    
    if current_user.role not in [UserRole.MODERATOR, UserRole.ADMIN, UserRole.OWNER] and current_user.restaurant_id != restaurant_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    return restaurant

@app.patch("/restaurants/{restaurant_id}", response_model=RestaurantResponse)
def update_restaurant(restaurant_id: int, data: RestaurantUpdate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    restaurant = db.query(Restaurant).filter(Restaurant.id == restaurant_id).first()
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")
    
    if current_user.role not in [UserRole.MODERATOR, UserRole.ADMIN] and current_user.restaurant_id != restaurant_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    for key, value in data.dict(exclude_unset=True).items():
        setattr(restaurant, key, value)
    
    restaurant.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(restaurant)
    return restaurant

# =====================================================
# Категории
# =====================================================
@app.post("/restaurants/{restaurant_id}/categories", response_model=CategoryResponse)
def create_category(restaurant_id: int, data: CategoryCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role not in [UserRole.MODERATOR, UserRole.ADMIN] and current_user.restaurant_id != restaurant_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    category = Category(restaurant_id=restaurant_id, **data.dict())
    db.add(category)
    db.commit()
    db.refresh(category)
    return category

@app.get("/restaurants/{restaurant_id}/categories", response_model=List[CategoryResponse])
def list_categories(restaurant_id: int, db: Session = Depends(get_db)):
    return db.query(Category).filter(Category.restaurant_id == restaurant_id, Category.is_active == True).order_by(Category.sort_order).all()

@app.delete("/categories/{category_id}")
def delete_category(category_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    if current_user.role not in [UserRole.MODERATOR, UserRole.ADMIN]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    db.delete(category)
    db.commit()
    return {"message": "Category deleted"}

# =====================================================
# Блюда
# =====================================================
@app.post("/dishes", response_model=DishResponse)
def create_dish(data: DishCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    category = db.query(Category).filter(Category.id == data.category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    if current_user.role not in [UserRole.MODERATOR, UserRole.ADMIN]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Генерация placeholder изображения
    image_url = f"https://placehold.co/400x300/4F46E5/white/png?text={data.name[:20]}"
    
    dish = Dish(
        category_id=data.category_id,
        name=data.name,
        name_kz=data.name_kz,
        description=data.description,
        price=data.price,
        cooking_time=data.cooking_time,
        image_url=image_url
    )
    db.add(dish)
    db.flush()
    
    # Добавление модификаторов
    for mod_data in data.modifiers:
        modifier = Modifier(dish_id=dish.id, **mod_data.dict())
        db.add(modifier)
    
    db.commit()
    db.refresh(dish)
    return dish

@app.get("/categories/{category_id}/dishes", response_model=List[DishResponse])
def list_dishes(category_id: int, db: Session = Depends(get_db)):
    return db.query(Dish).filter(Dish.category_id == category_id, Dish.is_available == True).order_by(Dish.sort_order).all()

@app.get("/restaurants/{restaurant_id}/menu", response_model=List[dict])
def get_menu(restaurant_id: int, db: Session = Depends(get_db)):
    categories = db.query(Category).filter(Category.restaurant_id == restaurant_id, Category.is_active == True).order_by(Category.sort_order).all()
    
    menu = []
    for category in categories:
        dishes = db.query(Dish).filter(Dish.category_id == category.id, Dish.is_available == True, Dish.is_stop_list == False).order_by(Dish.sort_order).all()
        menu.append({
            "id": category.id,
            "name": category.name,
            "name_kz": category.name_kz,
            "dishes": [DishResponse.from_orm(d) for d in dishes]
        })
    
    return menu

@app.patch("/dishes/{dish_id}/stop-list")
def toggle_stop_list(dish_id: int, stop_list: bool, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role not in [UserRole.MODERATOR, UserRole.ADMIN, UserRole.WAITER]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    dish = db.query(Dish).filter(Dish.id == dish_id).first()
    if not dish:
        raise HTTPException(status_code=404, detail="Dish not found")
    
    dish.is_stop_list = stop_list
    dish.updated_at = datetime.utcnow()
    db.commit()
    return {"message": f"Dish {'added to' if stop_list else 'removed from'} stop list"}

@app.get("/health")
def health_check():
    return {"status": "healthy", "version": "2.0.0", "stage": 2}

# Инициализация супер-админа
@app.on_event("startup")
async def startup_event():
    db = SessionLocal()
    try:
        admin = db.query(User).filter(User.email == "admin@thanks.kz").first()
        if not admin:
            admin = User(
                email="admin@thanks.kz",
                hashed_password=get_password_hash("Bitcoin1"),
                full_name="Super Admin",
                role=UserRole.MODERATOR,
                is_active=True
            )
            db.add(admin)
            db.commit()
            print("✅ Super admin created")
    finally:
        db.close()
EOF

# =====================================================
# 5. Перезапуск backend
# =====================================================
echo -e "${YELLOW}[4/6] Перезапуск backend...${NC}"
systemctl start thanks-backend
sleep 2

# =====================================================
# 6. Обновление Frontend
# =====================================================
echo -e "${YELLOW}[5/6] Обновление Frontend...${NC}"

# Страница управления заведениями (модератор)
mkdir -p $PROJECT_DIR/frontend/src/pages/admin

cat > $PROJECT_DIR/frontend/src/pages/admin/Restaurants.jsx <<'EOF'
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
EOF

# Страница управления меню
cat > $PROJECT_DIR/frontend/src/pages/admin/Menu.jsx <<'EOF'
import { useState, useEffect } from 'react'
import { useParams } from 'react-router-dom'
import axios from 'axios'

export default function Menu() {
  const { restaurantId } = useParams()
  const [categories, setCategories] = useState([])
  const [dishes, setDishes] = useState([])
  const [selectedCategory, setSelectedCategory] = useState(null)
  const [showCategoryForm, setShowCategoryForm] = useState(false)
  const [showDishForm, setShowDishForm] = useState(false)

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

  const createCategory = async (name) => {
    try {
      const token = localStorage.getItem('token')
      await axios.post(`/api/restaurants/${restaurantId}/categories`, 
        { name },
        { headers: { Authorization: `Bearer ${token}` }}
      )
      fetchCategories()
      setShowCategoryForm(false)
    } catch (error) {
      console.error('Error:', error)
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

  return (
    <div className="flex h-screen">
      {/* Sidebar - Категории */}
      <div className="w-64 bg-white border-r p-4">
        <div className="flex justify-between items-center mb-4">
          <h3 className="font-bold">Категории</h3>
          <button 
            onClick={() => setShowCategoryForm(true)}
            className="text-blue-600 text-2xl"
          >+</button>
        </div>
        <div className="space-y-2">
          {categories.map(cat => (
            <button
              key={cat.id}
              onClick={() => setSelectedCategory(cat)}
              className={`w-full text-left px-3 py-2 rounded-lg ${
                selectedCategory?.id === cat.id ? 'bg-blue-100 text-blue-700' : 'hover:bg-gray-100'
              }`}
            >
              {cat.name}
            </button>
          ))}
        </div>
      </div>

      {/* Блюда */}
      <div className="flex-1 p-6 overflow-y-auto">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-2xl font-bold">
            {selectedCategory?.name || 'Выберите категорию'}
          </h2>
          {selectedCategory && (
            <button
              onClick={() => setShowDishForm(true)}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg"
            >
              + Добавить блюдо
            </button>
          )}
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {dishes.map(dish => (
            <div key={dish.id} className="bg-white rounded-lg shadow-md overflow-hidden">
              <img 
                src={dish.image_url} 
                alt={dish.name}
                className="w-full h-48 object-cover"
              />
              <div className="p-4">
                <h3 className="font-semibold text-lg mb-2">{dish.name}</h3>
                <p className="text-gray-600 text-sm mb-3">{dish.description}</p>
                <div className="flex justify-between items-center">
                  <span className="text-xl font-bold text-blue-600">{dish.price} ₸</span>
                  <button
                    onClick={() => toggleStopList(dish.id, dish.is_stop_list)}
                    className={`px-3 py-1 rounded-full text-sm ${
                      dish.is_stop_list 
                        ? 'bg-red-100 text-red-700' 
                        : 'bg-green-100 text-green-700'
                    }`}
                  >
                    {dish.is_stop_list ? 'Стоп-лист' : 'Доступно'}
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Модалка создания категории */}
      {showCategoryForm && (
        <CategoryForm 
          onSubmit={createCategory}
          onClose={() => setShowCategoryForm(false)}
        />
      )}

      {/* Модалка создания блюда */}
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

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl p-6 w-full max-w-md">
        <h3 className="text-xl font-bold mb-4">Новая категория</h3>
        <form onSubmit={(e) => { e.preventDefault(); onSubmit(name); }}>
          <input
            type="text"
            placeholder="Название категории"
            value={name}
            onChange={e => setName(e.target.value)}
            className="w-full px-4 py-2 border rounded-lg mb-4"
            required
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

function DishForm({ onSubmit, onClose }) {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    price: '',
    cooking_time: 15
  })

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl p-6 w-full max-w-md">
        <h3 className="text-xl font-bold mb-4">Новое блюдо</h3>
        <form onSubmit={(e) => { 
          e.preventDefault(); 
          onSubmit({ ...formData, price: parseFloat(formData.price) }); 
        }}>
          <div className="space-y-4">
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
              type="number"
              placeholder="Цена (₸)"
              value={formData.price}
              onChange={e => setFormData({...formData, price: e.target.value})}
              className="w-full px-4 py-2 border rounded-lg"
              required
            />
            <input
              type="number"
              placeholder="Время приготовления (мин)"
              value={formData.cooking_time}
              onChange={e => setFormData({...formData, cooking_time: parseInt(e.target.value)})}
              className="w-full px-4 py-2 border rounded-lg"
            />
          </div>
          <div className="flex gap-2 mt-4">
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

# Обновление Dashboard с навигацией
cat > $PROJECT_DIR/frontend/src/pages/Dashboard.jsx <<'EOF'
import { useEffect, useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import axios from 'axios'

export default function Dashboard({ setToken }) {
  const [user, setUser] = useState(null)
  const navigate = useNavigate()

  useEffect(() => {
    const fetchUser = async () => {
      try {
        const token = localStorage.getItem('token')
        const response = await axios.get('/api/auth/me', {
          headers: { Authorization: `Bearer ${token}` }
        })
        setUser(response.data)
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
          <h1 className="text-2xl font-bold">Thanks PWA</h1>
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
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-6">
            <Link to={`/admin/menu/${user.restaurant_id}`} className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition">
              <div className="text-4xl mb-4">📋</div>
              <h3 className="text-xl font-semibold mb-2">Меню</h3>
              <p className="text-gray-600">Управление меню и блюдами</p>
            </Link>
          </div>
        )}

        <div className="bg-gradient-to-r from-blue-500 to-purple-600 rounded-2xl shadow-lg p-8 mt-8 text-white">
          <h3 className="text-2xl font-bold mb-4">✅ Stage 2 установлен!</h3>
          <ul className="space-y-2">
            <li>✓ Управление заведениями (модератор)</li>
            <li>✓ CRUD категорий и блюд</li>
            <li>✓ Стоп-лист</li>
            <li>✓ Placeholder изображения</li>
          </ul>
        </div>
      </main>
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

function App() {
  const [token, setToken] = useState(localStorage.getItem('token'))

  const ProtectedRoute = ({ children }) => {
    return token ? children : <Navigate to="/login" />
  }

  return (
    <Router>
      <Routes>
        <Route path="/login" element={<Login setToken={setToken} />} />
        <Route 
          path="/dashboard" 
          element={
            <ProtectedRoute>
              <Dashboard setToken={setToken} />
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
        <Route path="/" element={<Navigate to="/dashboard" />} />
      </Routes>
    </Router>
  )
}

export default App
EOF

# Пересборка frontend
echo -e "${YELLOW}[6/6] Сборка frontend...${NC}"
cd $PROJECT_DIR/frontend
pnpm run build
systemctl reload nginx

# Создать тестовые данные
echo -e "${YELLOW}Создание тестовых данных...${NC}"

cat > /tmp/seed_stage2.py <<'EOF'
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import sys
sys.path.append('/opt/thanks/backend')

from models import Restaurant, Category, Dish, User, UserRole
from passlib.context import CryptContext

DATABASE_URL = "postgresql://thanks_user:Bitcoin1@localhost/thanks_db"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Создать тестовое заведение
restaurant = Restaurant(
    name="Вкусная Кухня",
    slug="vkusnaya-kuhnya",
    description="Семейный ресторан с домашней кухней",
    address="Алматы, пр. Абая 150",
    phone="+7 777 123 4567",
    currency="KZT",
    working_hours={"monday": "10:00-22:00", "tuesday": "10:00-22:00"}
)
db.add(restaurant)
db.flush()

# Создать админа заведения
admin = User(
    email="admin@restaurant.kz",
    hashed_password=pwd_context.hash("Bitcoin1"),
    full_name="Админ Ресторана",
    role=UserRole.ADMIN,
    restaurant_id=restaurant.id
)
db.add(admin)

# Создать категории
categories_data = [
    {"name": "Салаты", "description": "Свежие салаты"},
    {"name": "Горячие блюда", "description": "Основные блюда"},
    {"name": "Десерты", "description": "Сладкие десерты"}
]

categories = []
for i, cat_data in enumerate(categories_data):
    cat = Category(
        restaurant_id=restaurant.id,
        name=cat_data["name"],
        description=cat_data["description"],
        sort_order=i
    )
    db.add(cat)
    db.flush()
    categories.append(cat)

# Создать блюда
dishes_data = [
    {"category": 0, "name": "Цезарь", "price": 2500, "description": "Классический салат Цезарь с курицей"},
    {"category": 0, "name": "Греческий салат", "price": 2000, "description": "Свежие овощи с сыром фета"},
    {"category": 1, "name": "Стейк из говядины", "price": 5500, "description": "Сочный стейк medium rare"},
    {"category": 1, "name": "Лосось на гриле", "price": 4800, "description": "Филе лосося с овощами"},
    {"category": 2, "name": "Тирамису", "price": 1800, "description": "Итальянский десерт"},
    {"category": 2, "name": "Чизкейк", "price": 1600, "description": "Нежный чизкейк"},
]

for dish_data in dishes_data:
    cat = categories[dish_data["category"]]
    dish = Dish(
        category_id=cat.id,
        name=dish_data["name"],
        description=dish_data["description"],
        price=dish_data["price"],
        image_url=f"https://placehold.co/400x300/4F46E5/white/png?text={dish_data['name'][:15]}",
        cooking_time=20
    )
    db.add(dish)

db.commit()
print("✅ Тестовые данные созданы")
print("📧 Админ заведения: admin@restaurant.kz / Bitcoin1")
EOF

cd /opt/thanks/backend
source venv/bin/activate
python3 /tmp/seed_stage2.py

# Обновление скрипта обновления
cat > /opt/thanks/scripts/update_stage2.sh <<'EOF'
#!/bin/bash
set -e

echo "🔄 Обновление Stage 2..."

cd /opt/thanks/backend
source venv/bin/activate
pip install -r requirements.txt --upgrade
systemctl restart thanks-backend

cd /opt/thanks/frontend
pnpm install
pnpm run build
systemctl reload nginx

echo "✅ Stage 2 обновлен!"
EOF

chmod +x /opt/thanks/scripts/update_stage2.sh

# Итоговая информация
echo ""
echo "════════════════════════════════════════════════"
echo "✅ THANKS PWA - STAGE 2 УСТАНОВЛЕН УСПЕШНО!"
echo "════════════════════════════════════════════════"
echo ""
echo "🌐 URL: http://217.11.74.100"
echo ""
echo "👥 Аккаунты:"
echo "  Супер-админ: admin@thanks.kz / Bitcoin1"
echo "  Админ заведения: admin@restaurant.kz / Bitcoin1"
echo ""
echo "✨ Новые возможности:"
echo "  ✅ Управление заведениями (модератор)"
echo "  ✅ Управление меню и категориями"
echo "  ✅ CRUD блюд с placeholder изображениями"
echo "  ✅ Стоп-лист для блюд"
echo "  ✅ Тестовое заведение 'Вкусная Кухня'"
echo ""
echo "📚 Следующий этап: Stage 3 - Конструктор залов + QR"
echo "════════════════════════════════════════════════"
