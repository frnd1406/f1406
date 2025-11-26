import { useEffect, useState } from "react";
import { authHeaders } from "../utils/auth";
import { FolderOpen, File, Upload, Download, Trash2, ArrowUp, Loader2 } from "lucide-react";

const API_BASE =
  import.meta.env.VITE_API_BASE_URL ||
  `${window.location.protocol}//${window.location.hostname}:8080`;

function joinPath(base, name) {
  if (!base || base === "/") {
    return `/${name}`;
  }
  return `${base.replace(/\/+$/, "")}/${name}`;
}

// Glass Card Component
const GlassCard = ({ children, className = "" }) => (
  <div className={`relative overflow-hidden rounded-2xl border border-white/10 bg-slate-900/40 backdrop-blur-xl shadow-2xl ${className}`}>
    {/* Internal "Shimmer" Reflection */}
    <div className="absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-white/20 to-transparent opacity-50"></div>
    <div className="p-6 h-full flex flex-col">
      {children}
    </div>
  </div>
);

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

  const formatFileSize = (bytes) => {
    if (!bytes || bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  return (
    <div className="space-y-6">

      {/* Path Navigation Card */}
      <GlassCard>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <FolderOpen className="text-blue-400" size={24} />
            <div>
              <p className="text-xs text-slate-400 uppercase tracking-wider mb-1">Current Path</p>
              <p className="text-lg font-semibold text-white font-mono">{path}</p>
            </div>
          </div>
          {path !== "/" && (
            <button
              onClick={goUp}
              className="flex items-center gap-2 px-4 py-2 rounded-lg bg-white/5 hover:bg-white/10 text-slate-300 hover:text-white border border-white/10 transition-all"
            >
              <ArrowUp size={18} />
              <span className="text-sm font-medium">Go Up</span>
            </button>
          )}
        </div>
      </GlassCard>

      {/* Upload Section */}
      <GlassCard>
        <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4">
          <div className="flex-1 w-full">
            <label className="block text-sm font-medium text-slate-300 mb-2">
              Upload File
            </label>
            <div className="relative">
              <input
                type="file"
                onChange={(e) => setSelectedFile(e.target.files?.[0] || null)}
                className="block w-full text-sm text-slate-400
                  file:mr-4 file:py-2 file:px-4
                  file:rounded-lg file:border-0
                  file:text-sm file:font-medium
                  file:bg-blue-500/20 file:text-blue-400
                  hover:file:bg-blue-500/30
                  file:cursor-pointer file:transition-all
                  cursor-pointer"
              />
            </div>
            {selectedFile && (
              <p className="mt-2 text-xs text-slate-400">
                Selected: <span className="text-white font-medium">{selectedFile.name}</span> ({formatFileSize(selectedFile.size)})
              </p>
            )}
          </div>
          <button
            onClick={handleUpload}
            disabled={uploading || !selectedFile}
            className="flex items-center gap-2 px-6 py-2.5 rounded-lg bg-blue-500/20 hover:bg-blue-500/30 text-blue-400 border border-blue-500/30 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-[0_0_15px_rgba(59,130,246,0.3)] hover:shadow-[0_0_20px_rgba(59,130,246,0.4)] mt-auto"
          >
            {uploading ? (
              <>
                <Loader2 size={18} className="animate-spin" />
                <span className="text-sm font-medium">Uploading...</span>
              </>
            ) : (
              <>
                <Upload size={18} />
                <span className="text-sm font-medium">Upload</span>
              </>
            )}
          </button>
        </div>
      </GlassCard>

      {/* Error Display */}
      {error && (
        <div className="rounded-xl border border-rose-500/30 bg-rose-500/10 p-4">
          <p className="text-rose-400 text-sm font-medium">{error}</p>
        </div>
      )}

      {/* Files Table */}
      <GlassCard>
        <div className="flex items-center justify-between mb-6">
          <div>
            <h3 className="text-white font-semibold text-lg tracking-tight">Files & Folders</h3>
            <p className="text-slate-400 text-xs mt-1">{files.length} items</p>
          </div>
        </div>

        {loading ? (
          <div className="flex flex-col items-center justify-center py-12">
            <Loader2 size={32} className="text-blue-400 animate-spin mb-3" />
            <p className="text-slate-400 text-sm">Loading files...</p>
          </div>
        ) : (
          <div className="overflow-x-auto -mx-6 px-6">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="text-xs text-slate-500 border-b border-white/5">
                  <th className="py-3 px-2 font-medium uppercase tracking-wider">Name</th>
                  <th className="py-3 px-2 font-medium uppercase tracking-wider">Size</th>
                  <th className="py-3 px-2 font-medium uppercase tracking-wider">Modified</th>
                  <th className="py-3 px-2 font-medium uppercase tracking-wider text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="text-sm">
                {files.map((item) => (
                  <tr
                    key={item.name}
                    className="group border-b border-white/5 last:border-0 hover:bg-white/5 transition-colors cursor-pointer"
                    onClick={() => item.isDir && handleNavigate(item)}
                  >
                    <td className="py-4 px-2 font-medium text-white">
                      <div className="flex items-center gap-3">
                        <div className={`p-2 rounded-lg ${item.isDir ? 'bg-blue-500/20 text-blue-400' : 'bg-slate-800 text-slate-400'}`}>
                          {item.isDir ? <FolderOpen size={16} /> : <File size={16} />}
                        </div>
                        <span className={item.isDir ? "hover:text-blue-400 transition-colors" : ""}>
                          {item.name}
                        </span>
                      </div>
                    </td>
                    <td className="py-4 px-2 text-slate-400 font-mono text-xs">
                      {item.isDir ? "-" : formatFileSize(item.size)}
                    </td>
                    <td className="py-4 px-2 text-slate-400 text-xs">
                      {new Date(item.modTime).toLocaleString()}
                    </td>
                    <td className="py-4 px-2 text-right">
                      <div className="flex items-center justify-end gap-2">
                        {!item.isDir && (
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              handleDownload(item);
                            }}
                            className="p-2 rounded-lg bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 transition-all"
                            title="Download"
                          >
                            <Download size={14} />
                          </button>
                        )}
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            handleDelete(item);
                          }}
                          className="p-2 rounded-lg bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/20 transition-all"
                          title="Delete"
                        >
                          <Trash2 size={14} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {files.length === 0 && (
                  <tr>
                    <td colSpan="4" className="py-12 text-center text-slate-400">
                      <FolderOpen size={48} className="mx-auto mb-3 opacity-30" />
                      <p className="text-sm">No files or folders</p>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </GlassCard>
    </div>
  );
}
