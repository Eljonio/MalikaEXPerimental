import { useState } from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import Login from './pages/Login'
import Register from './pages/Register'
import TableWelcome from './pages/TableWelcome'
import GuestMenu from './pages/GuestMenu'
import TableLinks from './pages/admin/TableLinks'
import Dashboard from './pages/Dashboard'
import Restaurants from './pages/admin/Restaurants'
import Halls from './pages/admin/Halls'
import Menu from './pages/admin/Menu'
import Reservations from './pages/admin/Reservations'
import Analytics from './pages/admin/Analytics'
import QRGenerator from './pages/admin/QRGenerator'
import QRPage from './pages/QRPage'
import MenuPage from './pages/MenuPage'
import CheckoutPage from './pages/CheckoutPage'
import OrderSuccess from './pages/OrderSuccess'
import MyOrders from './pages/MyOrders'
import WaiterDashboard from './pages/waiter/WaiterDashboard'
import CheckPage from './pages/CheckPage'
import ProfilePage from './pages/ProfilePage'
import BookingPage from './pages/BookingPage'

function App() {
  const [token, setToken] = useState(localStorage.getItem('token'))

  const ProtectedRoute = ({ children }) => {
    return token ? children : <Navigate to="/login" />
  }

  return (
    <Router>
      <Routes>
        <Route path="/login" element={<Login setToken={setToken} />} />
        <Route path="/register" element={<Register setToken={setToken} />} />
        <Route path="/qr/:shortCode" element={<QRPage />} />
        <Route path="/t/:shortCode" element={<TableWelcome />} />
        <Route path="/guest-menu/:restaurantId" element={<GuestMenu />} />
        <Route path="/check" element={<CheckPage />} />
        <Route path="/profile" element={<ProfilePage />} />
        <Route path="/booking/:restaurantId" element={<BookingPage />} />
        <Route path="/menu/:restaurantId" element={<MenuPage />} />
        
        <Route path="/dashboard" element={<ProtectedRoute><Dashboard setToken={setToken} /></ProtectedRoute>} />
        <Route path="/waiter" element={<ProtectedRoute><WaiterDashboard /></ProtectedRoute>} />
        <Route path="/checkout" element={<ProtectedRoute><CheckoutPage /></ProtectedRoute>} />
        <Route path="/order-success" element={<ProtectedRoute><OrderSuccess /></ProtectedRoute>} />
        <Route path="/my-orders" element={<ProtectedRoute><MyOrders /></ProtectedRoute>} />

        {/* Admin routes */}
        <Route path="/admin/restaurants" element={<ProtectedRoute><Restaurants /></ProtectedRoute>} />
        <Route path="/admin/halls/:restaurantId" element={<ProtectedRoute><Halls /></ProtectedRoute>} />
        <Route path="/admin/menu/:restaurantId" element={<ProtectedRoute><Menu /></ProtectedRoute>} />
        <Route path="/admin/reservations/:restaurantId" element={<ProtectedRoute><Reservations /></ProtectedRoute>} />
        <Route path="/admin/analytics/:restaurantId" element={<ProtectedRoute><Analytics /></ProtectedRoute>} />
        <Route path="/admin/qr-generator/:restaurantId" element={<ProtectedRoute><QRGenerator /></ProtectedRoute>} />
        <Route path="/admin/table-links/:restaurantId" element={<ProtectedRoute><TableLinks /></ProtectedRoute>} />

        <Route path="/" element={<Navigate to="/dashboard" />} />
      </Routes>
    </Router>
  )
}

export default App
