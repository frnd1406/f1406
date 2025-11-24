import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { apiRequest } from '../lib/api'

function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()

  const handleLogin = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      const data = await apiRequest('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      })

      // Store tokens in localStorage
      if (data.access_token) {
        localStorage.setItem('accessToken', data.access_token)
        localStorage.setItem('refreshToken', data.refresh_token)
        localStorage.setItem('csrfToken', data.csrf_token)
      }

      // Login successful, redirect to success page
      navigate('/dashboard')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{ maxWidth: '400px', margin: '100px auto', padding: '20px', border: '1px solid #ccc' }}>
      <h1>NAS.AI Login</h1>
      <form onSubmit={handleLogin}>
        {error && (
          <div style={{ marginBottom: '10px', padding: '10px', background: '#ffebee', color: '#c62828', border: '1px solid #ef5350' }}>
            {error}
          </div>
        )}
        <div style={{ marginBottom: '10px' }}>
          <input
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            style={{ width: '100%', padding: '8px', boxSizing: 'border-box' }}
            required
          />
        </div>
        <div style={{ marginBottom: '10px' }}>
          <input
            type="password"
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            style={{ width: '100%', padding: '8px', boxSizing: 'border-box' }}
            required
          />
        </div>
        <button
          type="submit"
          disabled={loading}
          style={{ width: '100%', padding: '10px', background: loading ? '#ccc' : '#007bff', color: 'white', border: 'none', cursor: loading ? 'not-allowed' : 'pointer' }}
        >
          {loading ? 'Logging in...' : 'Login'}
        </button>
      </form>
      <div style={{ marginTop: '15px', textAlign: 'center' }}>
        <a href="/register" style={{ color: '#007bff', textDecoration: 'none' }}>
          Don't have an account? Register
        </a>
      </div>
    </div>
  )
}

export default Login
