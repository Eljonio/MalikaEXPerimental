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

from models import Base, User, UserRole, Restaurant, Category, Dish, Modifier, Hall, Table, WaiterCall

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


class UserRegister(BaseModel):
    email: EmailStr
    password: str
    name: str
    phone: Optional[str] = None

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
@app.post("/auth/register", response_model=Token)
def register(data: UserRegister, db: Session = Depends(get_db)):
    """Регистрация нового пользователя"""
    existing_user = db.query(User).filter(User.email == data.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_password = get_password_hash(data.password)
    new_user = User(
        email=data.email,
        hashed_password=hashed_password,
        full_name=data.name,
        phone=data.phone,
        role=UserRole.USER
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    access_token = create_access_token(
        data={"sub": new_user.email}, 
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    return {"access_token": access_token, "token_type": "bearer", "user": new_user}

@app.post("/auth/register", response_model=Token)
def register(data: UserRegister, db: Session = Depends(get_db)):
    """Регистрация нового пользователя"""
    existing_user = db.query(User).filter(User.email == data.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_password = get_password_hash(data.password)
    new_user = User(
        email=data.email,
        hashed_password=hashed_password,
        full_name=data.name,
        phone=data.phone,
        role=UserRole.USER
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    access_token = create_access_token(
        data={"sub": new_user.email}, 
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    return {"access_token": access_token, "token_type": "bearer", "user": new_user}

@app.post("/auth/login", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    print(f"DEBUG: form_data.username={form_data.username}, password length={len(form_data.password)}")
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
        full_name=data.name,
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
def get_restaurant(restaurant_id: int, db: Session = Depends(get_db)):
    restaurant = db.query(Restaurant).filter(Restaurant.id == restaurant_id).first()
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")
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
        full_name=data.name,
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

# =====================================================
# Залы и Столы (Stage 3)
# =====================================================
import secrets
import string

class HallCreate(BaseModel):
    name: str
    description: Optional[str] = None
    zone_type: str = "main"

class HallResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    zone_type: str
    is_active: bool
    
    class Config:
        from_attributes = True

class TableCreate(BaseModel):
    hall_id: int
    table_number: str
    capacity: int = 2
    zone_type: str = "main"
    is_vip: bool = False

class TableResponse(BaseModel):
    id: int
    hall_id: int
    table_number: str
    capacity: int
    zone_type: str
    is_vip: bool
    status: str
    qr_code: Optional[str]
    short_code: Optional[str]
    
    class Config:
        from_attributes = True

def generate_short_code():
    """Генерация уникального короткого кода для QR"""
    chars = string.ascii_uppercase + string.digits
    return ''.join(secrets.choice(chars) for _ in range(6))

# CRUD Залов
@app.post("/restaurants/{restaurant_id}/halls", response_model=HallResponse)
def create_hall(restaurant_id: int, data: HallCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role not in [UserRole.MODERATOR, UserRole.ADMIN]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    from models import Hall
    hall = Hall(restaurant_id=restaurant_id, **data.dict())
    db.add(hall)
    db.commit()
    db.refresh(hall)
    return hall

@app.get("/restaurants/{restaurant_id}/halls", response_model=List[HallResponse])
def list_halls(restaurant_id: int, db: Session = Depends(get_db)):
    from models import Hall
    return db.query(Hall).filter(Hall.restaurant_id == restaurant_id, Hall.is_active == True).all()

@app.delete("/halls/{hall_id}")
def delete_hall(hall_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role not in [UserRole.MODERATOR, UserRole.ADMIN]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    from models import Hall
    hall = db.query(Hall).filter(Hall.id == hall_id).first()
    if not hall:
        raise HTTPException(status_code=404, detail="Hall not found")
    
    db.delete(hall)
    db.commit()
    return {"message": "Hall deleted"}

# CRUD Столов
@app.post("/halls/{hall_id}/tables", response_model=TableResponse)
def create_table(hall_id: int, data: TableCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role not in [UserRole.MODERATOR, UserRole.ADMIN]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    from models import Table
    
    # Генерация уникального short_code
    short_code = generate_short_code()
    while db.query(Table).filter(Table.short_code == short_code).first():
        short_code = generate_short_code()
    
    qr_code = f"http://217.11.74.100/qr/{short_code}"
    
    table = Table(
        hall_id=hall_id,
        table_number=data.table_number,
        capacity=data.capacity,
        zone_type=data.zone_type,
        is_vip=data.is_vip,
        qr_code=qr_code,
        short_code=short_code,
        status="available"
    )
    db.add(table)
    db.commit()
    db.refresh(table)
    return table

@app.get("/halls/{hall_id}/tables", response_model=List[TableResponse])
def list_tables(hall_id: int, db: Session = Depends(get_db)):
    from models import Table
    return db.query(Table).filter(Table.hall_id == hall_id, Table.is_active == True).all()

@app.delete("/tables/{table_id}")
def delete_table(table_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role not in [UserRole.MODERATOR, UserRole.ADMIN]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    from models import Table
    table = db.query(Table).filter(Table.id == table_id).first()
    if not table:
        raise HTTPException(status_code=404, detail="Table not found")
    
    db.delete(table)
    db.commit()
    return {"message": "Table deleted"}

# Получение информации по QR коду
@app.get("/qr/{short_code}")
def get_by_qr(short_code: str, db: Session = Depends(get_db)):
    from models import Table
    table = db.query(Table).filter(Table.short_code == short_code).first()
    if not table:
        raise HTTPException(status_code=404, detail="Table not found")
    
    hall = db.query(table.hall).first()
    restaurant = db.query(hall.restaurant).first()
    
    return {
        "table": TableResponse.from_orm(table),
        "hall": HallResponse.from_orm(hall),
        "restaurant": RestaurantResponse.from_orm(restaurant)
    }


# =====================================================
# Генерация ссылок для столов
# =====================================================

@app.post("/restaurants/{restaurant_id}/halls/{hall_id}/tables/{table_id}/generate-link")
def generate_table_link(
    restaurant_id: int,
    hall_id: int, 
    table_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Генерация короткой ссылки для стола"""
    # Проверка прав (только админ/владелец заведения)
    if current_user.role not in [UserRole.ADMIN, UserRole.OWNER, UserRole.MODERATOR]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Проверка существования стола
    table = db.query(Table).filter(
        Table.id == table_id,
        Table.hall_id == hall_id
    ).first()
    
    if not table:
        raise HTTPException(status_code=404, detail="Table not found")
    
    # Генерация короткого кода (6 символов)
    import random
    import string
    short_code = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
    
    # Сохранение в таблице tables (поле short_code)
    table.short_code = short_code
    db.commit()
    
    # Возвращаем ссылку
    base_url = "http://217.11.74.100"  # Изменить на домен
    link = f"{base_url}/t/{short_code}"
    
    return {
        "table_id": table_id,
        "table_number": table.table_number,
        "short_code": short_code,
        "link": link,
        "qr_data": link
    }

@app.get("/t/{short_code}")
def table_redirect(short_code: str, db: Session = Depends(get_db)):
    """Редирект по короткой ссылке стола"""
    # Найти стол по short_code
    table = db.query(Table).filter(Table.short_code == short_code).first()
    
    if not table:
        raise HTTPException(status_code=404, detail="Invalid table link")
    
    # Получить информацию о зале и заведении
    hall = db.query(Hall).filter(Hall.id == table.hall_id).first()
    
    return {
        "restaurant_id": hall.restaurant_id,
        "hall_id": table.hall_id,
        "table_id": table.id,
        "table_number": table.table_number,
        "capacity": table.capacity,
        "short_code": short_code
    }

@app.post("/tables/{table_id}/call-waiter")
def call_waiter_for_table(
    table_id: int,
    db: Session = Depends(get_db)
):
    """Вызов официанта для стола (доступно гостям)"""
    # Найти стол
    table = db.query(Table).filter(Table.id == table_id).first()
    if not table:
        raise HTTPException(status_code=404, detail="Table not found")
    
    # Найти зал
    hall = db.query(Hall).filter(Hall.id == table.hall_id).first()
    
    # Создать вызов официанта
    call = WaiterCall(
        restaurant_id=hall.restaurant_id,
        table_id=table_id,
        status="pending",
        created_at=datetime.utcnow()
    )
    db.add(call)
    db.commit()
    db.refresh(call)
    
    # TODO: Отправить WebSocket уведомление официантам этого заведения
    
    return {
        "message": "Официант вызван",
        "call_id": call.id,
        "table_number": table.number
    }
# Обновление статуса стола
@app.patch("/tables/{table_id}/status")
def update_table_status(table_id: int, status: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role not in [UserRole.MODERATOR, UserRole.ADMIN, UserRole.WAITER]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    from models import Table
    table = db.query(Table).filter(Table.id == table_id).first()
    if not table:
        raise HTTPException(status_code=404, detail="Table not found")
    
    valid_statuses = ["available", "occupied", "reserved", "unavailable"]
    if status not in valid_statuses:
        raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of: {', '.join(valid_statuses)}")
        
    table.status = status
    db.commit()
    return {"message": f"Table status updated to {status}"}

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

# =====================================================
# API для официантов (Stage 5)
# =====================================================
@app.get("/waiter/orders")
def get_waiter_orders(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role not in [UserRole.MODERATOR, UserRole.ADMIN, UserRole.WAITER]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Получить заказы из заведения официанта
    if current_user.restaurant_id:
        # Получить все столы заведения
        halls = db.query(Hall).filter(Hall.restaurant_id == current_user.restaurant_id).all()
        hall_ids = [hall.id for hall in halls]
        tables = db.query(Table).filter(Table.hall_id.in_(hall_ids)).all()
        table_ids = [table.id for table in tables]
        
        # Получить заказы этих столов
        orders = db.query(Order).filter(
            Order.table_id.in_(table_ids),
            Order.status != OrderStatus.CANCELLED
        ).order_by(Order.created_at.desc()).all()
        
        # Добавить items к каждому заказу
        for order in orders:
            order.items = db.query(OrderItem).filter(OrderItem.order_id == order.id).all()
        
        return orders
    
    return []

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

# =====================================================
# WebSocket интеграция (Stage 9)
# =====================================================
from websocket import sio
import socketio

# Создать ASGI приложение с Socket.IO
socket_app = socketio.ASGIApp(sio, app)
