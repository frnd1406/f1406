import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { setAuth } from "../utils/auth";

const API_BASE =
  import.meta.env.VITE_API_BASE_URL ||
  `${window.location.protocol}//${window.location.hostname}:8080`;

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    setMessage("");
    try {
      const res = await fetch(`${API_BASE}/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data?.error?.message || `HTTP ${res.status}`);
      }
      const data = await res.json();
      setAuth({
        accessToken: data.access_token || "",
        refreshToken: data.refresh_token || "",
        csrfToken: data.csrf_token || "",
      });
      setMessage("Login erfolgreich. Weiterleitung zum Dashboard ...");
      navigate("/dashboard", { replace: true });
    } catch (err) {
      setError(err.message || "Login fehlgeschlagen");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ padding: "2rem", fontFamily: "sans-serif", maxWidth: "360px", margin: "0 auto" }}>
      <h1>Login</h1>
      <form onSubmit={handleSubmit} style={{ display: "grid", gap: "0.75rem" }}>
        <div>
          <label>Email</label>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            style={{ width: "100%", padding: "0.5rem" }}
          />
        </div>
        <div>
          <label>Passwort</label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            style={{ width: "100%", padding: "0.5rem" }}
          />
        </div>
        <button type="submit" disabled={loading}>
          {loading ? "Logging in..." : "Login"}
        </button>
      </form>
      {error && <div style={{ color: "red", marginTop: "1rem" }}>{error}</div>}
      {message && <div style={{ color: "green", marginTop: "1rem" }}>{message}</div>}
      <div style={{ marginTop: "1rem" }}>
        <a href="/dashboard">Zurück</a>
      </div>
    </div>
  );
}
