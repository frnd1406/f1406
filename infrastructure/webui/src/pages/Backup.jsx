import { useEffect, useState } from "react";
import { authHeaders } from "../utils/auth";

const API_BASE =
  import.meta.env.VITE_API_BASE_URL ||
  `${window.location.protocol}//${window.location.hostname}:8080`;

export default function Backup() {
  const [backups, setBackups] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const loadBackups = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await fetch(`${API_BASE}/api/v1/backups`, {
        credentials: "include",
        headers: authHeaders(),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      setBackups(data.items || []);
    } catch (err) {
      setError(err.message || "Fehler beim Laden");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadBackups();
  }, []);

  const createBackup = async () => {
    setBusy(true);
    setError("");
    try {
      const res = await fetch(`${API_BASE}/api/v1/backups`, {
        method: "POST",
        credentials: "include",
        headers: authHeaders(),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      await loadBackups();
    } catch (err) {
      setError(err.message || "Backup fehlgeschlagen");
    } finally {
      setBusy(false);
    }
  };

  const restoreBackup = async (id) => {
    if (!window.confirm("Wiederherstellen überschreibt bestehende Daten. Fortfahren?")) return;
    setBusy(true);
    setError("");
    try {
      const res = await fetch(`${API_BASE}/api/v1/backups/${encodeURIComponent(id)}/restore`, {
        method: "POST",
        credentials: "include",
        headers: authHeaders(),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      await loadBackups();
    } catch (err) {
      setError(err.message || "Restore fehlgeschlagen");
    } finally {
      setBusy(false);
    }
  };

  const deleteBackup = async (id) => {
    if (!window.confirm("Backup wirklich löschen?")) return;
    setBusy(true);
    setError("");
    try {
      const res = await fetch(`${API_BASE}/api/v1/backups/${encodeURIComponent(id)}`, {
        method: "DELETE",
        credentials: "include",
        headers: authHeaders(),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      await loadBackups();
    } catch (err) {
      setError(err.message || "Löschen fehlgeschlagen");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div style={{ padding: "1rem", fontFamily: "sans-serif" }}>
      <h1>Backups</h1>
      <div style={{ marginBottom: "1rem" }}>
        <button onClick={createBackup} disabled={busy}>
          {busy ? "Bitte warten..." : "Backup jetzt erstellen"}
        </button>
      </div>
      {error && <div style={{ color: "red", marginBottom: "1rem" }}>{error}</div>}
      {loading ? (
        <div>Loading...</div>
      ) : (
        <table border="1" cellPadding="6" cellSpacing="0" width="100%">
          <thead>
            <tr>
              <th align="left">Name</th>
              <th align="left">Größe</th>
              <th align="left">Datum</th>
              <th align="left">Aktionen</th>
            </tr>
          </thead>
          <tbody>
            {backups.map((b) => (
              <tr key={b.id}>
                <td>{b.name || b.id}</td>
                <td>{b.size} bytes</td>
                <td>{new Date(b.modTime).toLocaleString()}</td>
                <td>
                  <button onClick={() => restoreBackup(b.id)} disabled={busy} style={{ marginRight: "0.5rem" }}>
                    Wiederherstellen
                  </button>
                  <button onClick={() => deleteBackup(b.id)} disabled={busy}>
                    Löschen
                  </button>
                </td>
              </tr>
            ))}
            {backups.length === 0 && (
              <tr>
                <td colSpan="4">Keine Backups vorhanden</td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}
