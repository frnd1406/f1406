import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import Login from './pages/Login'
import Register from './pages/Register'
import Success from './pages/Success'
import Dashboard from './pages/Dashboard'
import VerifyEmail from './pages/VerifyEmail'
import Metrics from './pages/Metrics'

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Metrics />} />
        <Route path="/metrics" element={<Metrics />} />
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/success" element={<Success />} />
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/verify-email" element={<VerifyEmail />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Router>
  )
}

export default App
