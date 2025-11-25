import { useEffect, useMemo, useState } from "react";

const API_BASE = import.meta.env.VITE_API_BASE_URL || "http://localhost:8080";
const POLL_MS = 5000;

export default function Metrics() {
  const [alerts, setAlerts] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const banner = useMemo(() => {
    const hasCritical = alerts.some((a) => a.severity === "CRITICAL");
    const hasWarning = alerts.some((a) => a.severity === "WARNING");

    if (hasCritical) {
      return { color: "#f8d7da", border: "#dc3545", text: "Critical Alerts aktiv" };
    }
    if (hasWarning) {
      return { color: "#fff3cd", border: "#ffc107", text: "Warnungen aktiv" };
    }
    return { color: "#d1e7dd", border: "#198754", text: "System Healthy" };
  }, [alerts]);

  const fetchAlerts = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await fetch(`${API_BASE}/api/v1/system/alerts`, { credentials: "include" });
      if (!res.ok) {
        throw new Error(`HTTP ${res.status}`);
      }
      const data = await res.json();
      setAlerts(data.items || []);
    } catch (err) {
      setError(err.message || "Failed to load alerts");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAlerts();
    const id = setInterval(fetchAlerts, POLL_MS);
    return () => clearInterval(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div style={{ display: "grid", gap: "1rem" }}>
      <div
        style={{
          padding: "1rem",
          border: `1px solid ${banner.border}`,
          background: banner.color,
          borderRadius: "6px",
        }}
      >
        <strong>{banner.text}</strong>
        {error && <div style={{ color: "#dc3545" }}>Error: {error}</div>}
        {loading && <div>Loading...</div>}
      </div>

      <div>
        <h2>Aktive Alerts</h2>
        <table border="1" cellPadding="6" cellSpacing="0" width="100%">
          <thead>
            <tr>
              <th align="left">Severity</th>
              <th align="left">Message</th>
              <th align="left">Created</th>
            </tr>
          </thead>
          <tbody>
            {alerts.map((a) => (
              <tr key={a.id}>
                <td>{a.severity}</td>
                <td>{a.message}</td>
                <td>{new Date(a.created_at || a.createdAt).toLocaleString()}</td>
              </tr>
            ))}
            {alerts.length === 0 && (
              <tr>
                <td colSpan="3">Keine offenen Alerts</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
