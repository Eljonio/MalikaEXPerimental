#!/bin/bash

# =====================================================
# THANKS PWA - STAGE 1: Базовая инфраструктура
# =====================================================
# Установка: Python, Node.js, PostgreSQL, Redis, Nginx
# Настройка: fail2ban, UFW, базовая авторизация
# =====================================================

set -e  # Остановка при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Конфигурация
PROJECT_DIR="/opt/thanks"
APP_USER="thanks"
DB_NAME="thanks_db"
DB_USER="thanks_user"
DB_PASSWORD="Bitcoin1"
ADMIN_EMAIL="admin@thanks.kz"
ADMIN_PASSWORD="Bitcoin1"
TIMEZONE="Asia/Almaty"
SERVER_IP="217.11.74.100"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}THANKS PWA - Stage 1 Installation${NC}"
echo -e "${GREEN}================================${NC}\n"

# =====================================================
# 1. Проверка root прав
# =====================================================
if [ "$EUID" -ne 0 ]; then 
   echo -e "${RED}Запустите скрипт с правами root (sudo)${NC}"
   exit 1
fi

# =====================================================
# 2. Обновление системы
# =====================================================
echo -e "${YELLOW}[1/12] Обновление системы...${NC}"
apt update && apt upgrade -y

# =====================================================
# 3. Установка базовых утилит
# =====================================================
echo -e "${YELLOW}[2/12] Установка базовых утилит...${NC}"
apt install -y curl wget git vim software-properties-common \
    build-essential libssl-dev libffi-dev python3-dev \
    ca-certificates gnupg lsb-release ufw fail2ban

# =====================================================
# 4. Настройка часового пояса
# =====================================================
echo -e "${YELLOW}[3/12] Настройка часового пояса...${NC}"
timedatectl set-timezone $TIMEZONE

# =====================================================
# 5. Установка Python 3.11
# =====================================================
echo -e "${YELLOW}[4/12] Установка Python 3.11...${NC}"
add-apt-repository ppa:deadsnakes/ppa -y
apt update
apt install -y python3.11 python3.11-venv python3.11-dev python3-pip

# Установка Poetry для управления зависимостями
curl -sSL https://install.python-poetry.org | python3.11 -
export PATH="/root/.local/bin:$PATH"
echo 'export PATH="/root/.local/bin:$PATH"' >> ~/.bashrc

# =====================================================
# 6. Установка Node.js 20 LTS
# =====================================================
echo -e "${YELLOW}[5/12] Установка Node.js 20...${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Установка pnpm (быстрее npm)
npm install -g pnpm pm2

# =====================================================
# 7. Установка PostgreSQL 16
# =====================================================
echo -e "${YELLOW}[6/12] Установка PostgreSQL 16...${NC}"
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt update
apt install -y postgresql-16 postgresql-contrib-16

# Настройка PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Создание пользователя и БД
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# =====================================================
# 8. Установка Redis
# =====================================================
echo -e "${YELLOW}[7/12] Установка Redis...${NC}"
apt install -y redis-server
systemctl start redis-server
systemctl enable redis-server

# Настройка Redis (только localhost)
sed -i 's/^bind 127.0.0.1/bind 127.0.0.1/' /etc/redis/redis.conf
systemctl restart redis-server

# =====================================================
# 9. Установка Nginx
# =====================================================
echo -e "${YELLOW}[8/12] Установка Nginx...${NC}"
apt install -y nginx
systemctl start nginx
systemctl enable nginx

# =====================================================
# 10. Настройка UFW Firewall
# =====================================================
echo -e "${YELLOW}[9/12] Настройка firewall...${NC}"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw --force enable

# =====================================================
# 11. Настройка fail2ban
# =====================================================
echo -e "${YELLOW}[10/12] Настройка fail2ban...${NC}"

# SSH защита
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = root@localhost
sendername = Fail2Ban

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
EOF

systemctl restart fail2ban
systemctl enable fail2ban

# =====================================================
# 12. Создание структуры проекта
# =====================================================
echo -e "${YELLOW}[11/12] Создание структуры проекта...${NC}"

# Создание пользователя приложения
if ! id -u $APP_USER > /dev/null 2>&1; then
    useradd -r -m -s /bin/bash $APP_USER
fi

# Создание директорий
mkdir -p $PROJECT_DIR/{backend,frontend,scripts,logs,backups}
mkdir -p /var/log/thanks

# =====================================================
# Backend: FastAPI приложение
# =====================================================
echo -e "${YELLOW}Создание Backend (FastAPI)...${NC}"

cat > $PROJECT_DIR/backend/pyproject.toml <<EOF
[tool.poetry]
name = "thanks-backend"
version = "0.1.0"
description = "Thanks PWA Backend"

[tool.poetry.dependencies]
python = "^3.11"
fastapi = "^0.109.0"
uvicorn = {extras = ["standard"], version = "^0.27.0"}
sqlalchemy = "^2.0.25"
alembic = "^1.13.1"
psycopg2-binary = "^2.9.9"
redis = "^5.0.1"
python-jose = {extras = ["cryptography"], version = "^3.3.0"}
passlib = {extras = ["bcrypt"], version = "^1.7.4"}
python-multipart = "^0.0.6"
pydantic = {extras = ["email"], version = "^2.5.3"}
pydantic-settings = "^2.1.0"
python-socketio = "^5.11.0"
websockets = "^12.0"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
EOF

# Основной файл приложения
cat > $PROJECT_DIR/backend/main.py <<'EOF'
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy import create_engine, Column, Integer, String, Boolean, DateTime, Enum
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from pydantic import BaseModel, EmailStr
from typing import Optional
import enum
import os

# =====================================================
# Конфигурация
# =====================================================
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://thanks_user:Bitcoin1@localhost/thanks_db")
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# =====================================================
# База данных
# =====================================================
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# =====================================================
# Модели
# =====================================================
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
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Создание таблиц
Base.metadata.create_all(bind=engine)

# =====================================================
# Безопасность
# =====================================================
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

# =====================================================
# Зависимости
# =====================================================
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

# =====================================================
# Pydantic схемы
# =====================================================
class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: Optional[str] = None
    phone: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: int
    email: str
    full_name: Optional[str]
    phone: Optional[str]
    role: UserRole
    is_active: bool
    
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

# =====================================================
# FastAPI приложение
# =====================================================
app = FastAPI(title="Thanks PWA API", version="1.0.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # В продакшене указать конкретные домены
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =====================================================
# Эндпоинты
# =====================================================
@app.get("/")
def read_root():
    return {"message": "Thanks PWA API", "version": "1.0.0", "status": "running"}

@app.post("/auth/register", response_model=UserResponse)
def register(user: UserCreate, db: Session = Depends(get_db)):
    # Проверка существующего пользователя
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Создание пользователя
    hashed_password = get_password_hash(user.password)
    db_user = User(
        email=user.email,
        hashed_password=hashed_password,
        full_name=user.full_name,
        phone=user.phone,
        role=UserRole.USER
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.post("/auth/login", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }

@app.get("/auth/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user

@app.get("/health")
def health_check():
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

# =====================================================
# Инициализация супер-админа
# =====================================================
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
            print("✅ Super admin created: admin@thanks.kz / Bitcoin1")
    finally:
        db.close()
EOF

# requirements.txt для pip (альтернатива Poetry)
cat > $PROJECT_DIR/backend/requirements.txt <<EOF
fastapi==0.109.0
uvicorn[standard]==0.27.0
sqlalchemy==2.0.25
alembic==1.13.1
psycopg2-binary==2.9.9
redis==5.0.1
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
pydantic[email]==2.5.3
pydantic-settings==2.1.0
python-socketio==5.11.0
websockets==12.0
EOF

# Установка зависимостей
cd $PROJECT_DIR/backend
python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# =====================================================
# Frontend: React + Vite PWA
# =====================================================
echo -e "${YELLOW}Создание Frontend (React + Vite)...${NC}"

cd $PROJECT_DIR/frontend

# Инициализация React проекта
pnpm create vite . --template react

# Установка зависимостей
cat > package.json <<'EOF'
{
  "name": "thanks-frontend",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite --host 0.0.0.0",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.21.3",
    "axios": "^1.6.5",
    "zustand": "^4.5.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.48",
    "@types/react-dom": "^18.2.18",
    "@vitejs/plugin-react": "^4.2.1",
    "vite": "^5.0.11",
    "vite-plugin-pwa": "^0.17.4",
    "autoprefixer": "^10.4.17",
    "postcss": "^8.4.33",
    "tailwindcss": "^3.4.1"
  }
}
EOF

pnpm install

# Vite конфигурация
cat > vite.config.js <<'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.ico', 'robots.txt', 'apple-touch-icon.png'],
      manifest: {
        name: 'Thanks PWA',
        short_name: 'Thanks',
        description: 'Restaurant service platform',
        theme_color: '#ffffff',
        icons: [
          {
            src: 'pwa-192x192.png',
            sizes: '192x192',
            type: 'image/png'
          },
          {
            src: 'pwa-512x512.png',
            sizes: '512x512',
            type: 'image/png'
          }
        ]
      }
    })
  ],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, '')
      }
    }
  }
})
EOF

# Tailwind конфигурация
cat > tailwind.config.js <<'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF

cat > postcss.config.js <<'EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

# Базовый CSS с Tailwind
cat > src/index.css <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
EOF

# Главный компонент приложения
cat > src/App.jsx <<'EOF'
import { useState } from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'

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
        <Route path="/" element={<Navigate to="/dashboard" />} />
      </Routes>
    </Router>
  )
}

export default App
EOF

# Страница логина
mkdir -p src/pages
cat > src/pages/Login.jsx <<'EOF'
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'

export default function Login({ setToken }) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const navigate = useNavigate()

  const handleLogin = async (e) => {
    e.preventDefault()
    setError('')
    
    try {
      const formData = new FormData()
      formData.append('username', email)
      formData.append('password', password)
      
      const response = await axios.post('/api/auth/login', formData)
      localStorage.setItem('token', response.data.access_token)
      localStorage.setItem('user', JSON.stringify(response.data.user))
      setToken(response.data.access_token)
      navigate('/dashboard')
    } catch (err) {
      setError(err.response?.data?.detail || 'Ошибка входа')
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center p-4">
      <div className="bg-white/90 backdrop-blur-lg rounded-2xl shadow-2xl p-8 w-full max-w-md">
        <h1 className="text-3xl font-bold text-center mb-2 text-gray-800">Thanks PWA</h1>
        <p className="text-center text-gray-600 mb-8">Войдите в систему</p>
        
        <form onSubmit={handleLogin} className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
              placeholder="admin@thanks.kz"
              required
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Пароль</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
              placeholder="••••••••"
              required
            />
          </div>

          {error && (
            <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg text-sm">
              {error}
            </div>
          )}

          <button
            type="submit"
            className="w-full bg-gradient-to-r from-blue-500 to-purple-600 text-white py-3 rounded-lg font-semibold hover:shadow-lg transition transform hover:scale-105"
          >
            Войти
          </button>
        </form>

        <div className="mt-6 text-center text-sm text-gray-600">
          <p>Тестовый аккаунт:</p>
          <p className="font-mono">admin@thanks.kz / Bitcoin1</p>
        </div>
      </div>
    </div>
  )
}
EOF

# Страница Dashboard
cat > src/pages/Dashboard.jsx <<'EOF'
import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
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
        console.error('Error fetching user:', error)
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

  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-xl">Загрузка...</div>
      </div>
    )
  }

  const getRoleBadge = (role) => {
    const badges = {
      moderator: 'bg-purple-100 text-purple-800',
      admin: 'bg-blue-100 text-blue-800',
      owner: 'bg-green-100 text-green-800',
      waiter: 'bg-yellow-100 text-yellow-800',
      user: 'bg-gray-100 text-gray-800',
      guest: 'bg-gray-100 text-gray-600'
    }
    return badges[role] || badges.guest
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
      {/* Header */}
      <header className="bg-white/80 backdrop-blur-lg shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 py-4 sm:px-6 lg:px-8 flex justify-between items-center">
          <h1 className="text-2xl font-bold text-gray-900">Thanks PWA</h1>
          <button
            onClick={handleLogout}
            className="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition"
          >
            Выйти
          </button>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
        {/* User Card */}
        <div className="bg-white/90 backdrop-blur-lg rounded-2xl shadow-lg p-6 mb-8">
          <div className="flex items-center space-x-4">
            <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white text-2xl font-bold">
              {user.email[0].toUpperCase()}
            </div>
            <div className="flex-1">
              <h2 className="text-xl font-semibold text-gray-900">
                {user.full_name || 'Пользователь'}
              </h2>
              <p className="text-gray-600">{user.email}</p>
            </div>
            <span className={`px-3 py-1 rounded-full text-sm font-medium ${getRoleBadge(user.role)}`}>
              {user.role.toUpperCase()}
            </span>
          </div>
        </div>

        {/* Info Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-white/90 backdrop-blur-lg rounded-xl shadow-md p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Версия</h3>
            <p className="text-3xl font-bold text-blue-600">1.0.0</p>
            <p className="text-sm text-gray-500 mt-2">Stage 1: Базовая инфраструктура</p>
          </div>

          <div className="bg-white/90 backdrop-blur-lg rounded-xl shadow-md p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Статус</h3>
            <p className="text-3xl font-bold text-green-600">✓ Активен</p>
            <p className="text-sm text-gray-500 mt-2">Все системы работают</p>
          </div>

          <div className="bg-white/90 backdrop-blur-lg rounded-xl shadow-md p-6">
            <h
