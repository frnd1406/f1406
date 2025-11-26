import { useEffect, useState } from "react";
import { authHeaders } from "../utils/auth";

const API_BASE =
  import.meta.env.VITE_API_BASE_URL ||
  `${window.location.protocol}//${window.location.hostname}:8080`;

function joinPath(base, name) {
  if (!base || base === "/") {
    return `/${name}`;
  }
  return `${base.replace(/\/+$/, "")}/${name}`;
}

export default function Files() {
  const [path, setPath] = useState("/");
  const [files, setFiles] = useState([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [selectedFile, setSelectedFile] = useState(null);

  const loadFiles = async (target = path) => {
    if (!authHeaders().Authorization) {
      setError("Bitte zuerst einloggen.");
      return;
    }
    setLoading(true);
    setError("");
    try {
      const res = await fetch(
        `${API_BASE}/api/v1/storage/files?path=${encodeURIComponent(target)}`,
        { credentials: "include", headers: authHeaders() }
      );
      if (!res.ok) {
        throw new Error("Failed to load files");
      }
      const data = await res.json();
      setFiles(data.items || []);
    } catch (err) {
      setError(err.message || "Unknown error");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadFiles("/");
  }, []);

  const handleUpload = async () => {
    if (!selectedFile) return;
    setUploading(true);
    setError("");
    const form = new FormData();
    form.append("file", selectedFile);
    form.append("path", path);

    try {
      const res = await fetch(`${API_BASE}/api/v1/storage/upload`, {
        method: "POST",
        body: form,
        credentials: "include",
        headers: authHeaders(),
      });
      if (!res.ok) {
        throw new Error("Upload failed");
      }
      setSelectedFile(null);
      await loadFiles(path);
    } catch (err) {
      setError(err.message || "Unknown error");
    } finally {
      setUploading(false);
    }
  };

  const handleDownload = async (item) => {
    const target = joinPath(path, item.name);
    const res = await fetch(
      `${API_BASE}/api/v1/storage/download?path=${encodeURIComponent(target)}`,
      {
        credentials: "include",
        headers: authHeaders(),
      }
    );
    if (!res.ok) {
      setError("Download failed");
      return;
    }
    const blob = await res.blob();
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = item.name;
    a.click();
    window.URL.revokeObjectURL(url);
  };

  const handleDelete = async (item) => {
    const target = joinPath(path, item.name);
    const res = await fetch(
      `${API_BASE}/api/v1/storage/delete?path=${encodeURIComponent(target)}`,
      {
        method: "DELETE",
        credentials: "include",
        headers: authHeaders(),
      }
    );
    if (!res.ok) {
      setError("Delete failed");
      return;
    }
    await loadFiles(path);
  };

  const handleNavigate = (item) => {
    if (!item.isDir) return;
    const nextPath = joinPath(path, item.name);
    setPath(nextPath);
    loadFiles(nextPath);
  };

  const goUp = () => {
    if (path === "/") return;
    const parts = path.split("/").filter(Boolean);
    parts.pop();
    const parent = parts.length ? `/${parts.join("/")}` : "/";
    setPath(parent);
    loadFiles(parent);
  };

  return (
    <div style={{ padding: "1rem", fontFamily: "sans-serif" }}>
      <h1>Files</h1>
      <div style={{ marginBottom: "0.5rem" }}>
        <strong>Path:</strong> {path}
        {path !== "/" && (
          <button style={{ marginLeft: "0.5rem" }} onClick={goUp}>
            Up
          </button>
        )}
      </div>

      <div style={{ marginBottom: "1rem" }}>
        <input
          type="file"
          onChange={(e) => setSelectedFile(e.target.files?.[0] || null)}
        />
        <button onClick={handleUpload} disabled={uploading || !selectedFile}>
          {uploading ? "Uploading..." : "Upload"}
        </button>
      </div>

      {error && (
        <div style={{ color: "red", marginBottom: "1rem" }}>{error}</div>
      )}

      {loading ? (
        <div>Loading...</div>
      ) : (
        <table border="1" cellPadding="6" cellSpacing="0" width="100%">
          <thead>
            <tr>
              <th align="left">Name</th>
              <th align="left">Size</th>
              <th align="left">Modified</th>
              <th align="left">Actions</th>
            </tr>
          </thead>
          <tbody>
            {files.map((item) => (
              <tr key={item.name}>
                <td>
                  <button onClick={() => handleNavigate(item)} style={{ marginRight: "0.5rem" }}>
                    {item.isDir ? "📁" : "📄"}
                  </button>
                  <span
                    style={{ cursor: item.isDir ? "pointer" : "default" }}
                    onClick={() => handleNavigate(item)}
                  >
                    {item.name}
                  </span>
                </td>
                <td>{item.isDir ? "-" : `${item.size} bytes`}</td>
                <td>{new Date(item.modTime).toLocaleString()}</td>
                <td>
                  {!item.isDir && (
                    <button onClick={() => handleDownload(item)}>Download</button>
                  )}
                  <button onClick={() => handleDelete(item)} style={{ marginLeft: "0.5rem" }}>
                    X
                  </button>
                </td>
              </tr>
            ))}
            {files.length === 0 && (
              <tr>
                <td colSpan="4">No files</td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}
