import { useEffect, useState } from "react";
import { authHeaders } from "../utils/auth";
import {
  FolderOpen,
  File,
  Upload,
  Download,
  Trash2,
  ArrowUp,
  Loader2,
  Grid3x3,
  List,
  Image as ImageIcon,
  FileText,
  FileArchive,
  FileCode,
  FileVideo,
  FileAudio,
  FilePlus,
  Edit3,
  Check,
  X,
  Eye,
  RefreshCw,
  Trash,
} from "lucide-react";

const API_BASE =
  import.meta.env.VITE_API_BASE_URL ||
  window.location.origin;

function joinPath(base, name) {
  if (!base || base === "/") {
    return `/${name}`;
  }
  return `${base.replace(/\/+$/, "")}/${name}`;
}

// Glass Card Component
const GlassCard = ({ children, className = "" }) => (
  <div className={`relative overflow-hidden rounded-2xl border border-white/10 bg-slate-900/40 backdrop-blur-xl shadow-2xl ${className}`}>
    <div className="absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-white/20 to-transparent opacity-50"></div>
    <div className="p-6 h-full flex flex-col">
      {children}
    </div>
  </div>
);

// Get file icon based on extension
const getFileIcon = (name, isDir) => {
  if (isDir) return FolderOpen;

  const ext = name.split('.').pop()?.toLowerCase();

  // Images
  if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp'].includes(ext)) {
    return ImageIcon;
  }
  // Text
  if (['txt', 'md', 'log', 'json', 'xml', 'yaml', 'yml', 'csv'].includes(ext)) {
    return FileText;
  }
  // Code
  if (['js', 'jsx', 'ts', 'tsx', 'py', 'go', 'rs', 'java', 'cpp', 'c', 'h', 'css', 'html', 'sh'].includes(ext)) {
    return FileCode;
  }
  // Archive
  if (['zip', 'tar', 'gz', 'rar', '7z', 'bz2'].includes(ext)) {
    return FileArchive;
  }
  // Video
  if (['mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv', 'webm'].includes(ext)) {
    return FileVideo;
  }
  // Audio
  if (['mp3', 'wav', 'flac', 'ogg', 'aac', 'm4a'].includes(ext)) {
    return FileAudio;
  }

  return File;
};

// Check if file is image
const isImage = (name) => {
  const ext = name.split('.').pop()?.toLowerCase();
  return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].includes(ext);
};

// Check if file is text
const isText = (name) => {
  const ext = name.split('.').pop()?.toLowerCase();
  return ['txt', 'md', 'log', 'json', 'xml', 'yaml', 'yml', 'csv', 'js', 'jsx', 'ts', 'tsx', 'py', 'go', 'rs', 'java', 'cpp', 'c', 'h', 'css', 'html', 'sh'].includes(ext);
};

export default function Files() {
  const [path, setPath] = useState("/");
  const [files, setFiles] = useState([]);
  const [trashedFiles, setTrashedFiles] = useState([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [selectedFile, setSelectedFile] = useState(null);

  // View modes
  const [viewMode, setViewMode] = useState("list"); // "list" or "grid"
  const [showTrash, setShowTrash] = useState(false);

  // Rename state
  const [renamingItem, setRenamingItem] = useState(null);
  const [newName, setNewName] = useState("");

  // Preview state
  const [previewItem, setPreviewItem] = useState(null);
  const [previewContent, setPreviewContent] = useState(null);
  const [previewLoading, setPreviewLoading] = useState(false);

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
        {
          credentials: "include",
          headers: authHeaders()
        }
      );
      if (res.status === 401) {
        setError("Authentifizierung fehlgeschlagen. Bitte neu einloggen.");
        return;
      }
      if (!res.ok) {
        throw new Error(`HTTP ${res.status}: Failed to load files`);
      }
      const data = await res.json();

      // Filter out .trash directory from the list
      const filteredFiles = (data.items || []).filter(item => item.name !== ".trash");
      setFiles(filteredFiles);
    } catch (err) {
      setError(err.message || "Unknown error");
    } finally {
      setLoading(false);
    }
  };

  const loadTrash = async () => {
    try {
      const res = await fetch(
        `${API_BASE}/api/v1/storage/trash`,
        {
          credentials: "include",
          headers: authHeaders()
        }
      );
      if (res.ok) {
        const data = await res.json();
        setTrashedFiles(data.items || []);
      }
    } catch (err) {
      console.error("Failed to load trash:", err);
    }
  };

  useEffect(() => {
    loadFiles("/");
    loadTrash();
  }, []);

  const handleUpload = async () => {
    if (!selectedFile) return;
    setUploading(true);
    setError("");
    const form = new FormData();
    form.append("file", selectedFile);
    form.append("path", path);

    try {
      // WICHTIG: Für FormData NICHT Content-Type Header setzen!
      // Browser setzt automatisch multipart/form-data mit boundary
      const headers = authHeaders();
      delete headers['Content-Type']; // Falls vorhanden, entfernen

      const res = await fetch(`${API_BASE}/api/v1/storage/upload`, {
        method: "POST",
        body: form,
        credentials: "include",
        headers: headers,
      });
      if (res.status === 401) {
        setError("Authentifizierung fehlgeschlagen.");
        return;
      }
      if (!res.ok) {
        throw new Error(`Upload failed: HTTP ${res.status}`);
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
    try {
      const res = await fetch(
        `${API_BASE}/api/v1/storage/download?path=${encodeURIComponent(target)}`,
        {
          credentials: "include",
          headers: authHeaders(),
        }
      );
      if (!res.ok) {
        setError(`Download failed: HTTP ${res.status}`);
        return;
      }
      const blob = await res.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = item.name;
      a.click();
      window.URL.revokeObjectURL(url);
    } catch (err) {
      setError(err.message);
    }
  };

  const handleDelete = async (item) => {
    // Prevent deletion of .trash directory
    if (item.name === ".trash") {
      setError("Der Papierkorb kann nicht gelöscht werden");
      return;
    }

    if (!window.confirm(`"${item.name}" wirklich löschen?`)) return;

    const target = joinPath(path, item.name);
    try {
      const res = await fetch(
        `${API_BASE}/api/v1/storage/delete?path=${encodeURIComponent(target)}`,
        {
          method: "DELETE",
          credentials: "include",
          headers: authHeaders(),
        }
      );
      if (!res.ok) {
        setError(`Delete failed: HTTP ${res.status}`);
        return;
      }
      await loadFiles(path);
      await loadTrash();
    } catch (err) {
      setError(err.message);
    }
  };

  const handleRestore = async (item) => {
    try {
      const res = await fetch(
        `${API_BASE}/api/v1/storage/restore?path=${encodeURIComponent(item.originalPath || item.name)}`,
        {
          method: "POST",
          credentials: "include",
          headers: authHeaders(),
        }
      );
      if (!res.ok) {
        setError(`Restore failed: HTTP ${res.status}`);
        return;
      }
      await loadTrash();
      await loadFiles(path);
    } catch (err) {
      setError(err.message);
    }
  };

  const handleRename = async () => {
    if (!renamingItem || !newName || newName === renamingItem.name) {
      setRenamingItem(null);
      setNewName("");
      return;
    }

    const oldPath = joinPath(path, renamingItem.name);
    const newPath = joinPath(path, newName);

    try {
      const res = await fetch(
        `${API_BASE}/api/v1/storage/rename`,
        {
          method: "POST",
          credentials: "include",
          headers: {
            ...authHeaders(),
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            oldPath,
            newPath,
          }),
        }
      );
      if (!res.ok) {
        throw new Error(`Rename failed: HTTP ${res.status}`);
      }
      setRenamingItem(null);
      setNewName("");
      await loadFiles(path);
    } catch (err) {
      setError(err.message);
    }
  };

  const handlePreview = async (item) => {
    if (item.isDir) return;

    setPreviewItem(item);
    setPreviewLoading(true);
    setPreviewContent(null);

    const target = joinPath(path, item.name);

    try {
      if (isImage(item.name)) {
        // For images, create blob URL
        const res = await fetch(
          `${API_BASE}/api/v1/storage/download?path=${encodeURIComponent(target)}`,
          {
            credentials: "include",
            headers: authHeaders(),
          }
        );
        if (res.ok) {
          const blob = await res.blob();
          const url = window.URL.createObjectURL(blob);
          setPreviewContent({ type: 'image', url });
        }
      } else if (isText(item.name)) {
        // For text, fetch content
        const res = await fetch(
          `${API_BASE}/api/v1/storage/download?path=${encodeURIComponent(target)}`,
          {
            credentials: "include",
            headers: authHeaders(),
          }
        );
        if (res.ok) {
          const text = await res.text();
          setPreviewContent({ type: 'text', content: text });
        }
      }
    } catch (err) {
      setError("Preview failed: " + err.message);
    } finally {
      setPreviewLoading(false);
    }
  };

  const closePreview = () => {
    if (previewContent?.type === 'image' && previewContent.url) {
      window.URL.revokeObjectURL(previewContent.url);
    }
    setPreviewItem(null);
    setPreviewContent(null);
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

  // File/Folder Card Component for Grid View
  const FileCard = ({ item }) => {
    const Icon = getFileIcon(item.name, item.isDir);
    const isRenaming = renamingItem?.name === item.name;

    return (
      <div
        className="group relative overflow-hidden rounded-xl border border-white/10 bg-slate-900/40 backdrop-blur-xl hover:bg-white/5 transition-all cursor-pointer"
        onClick={() => item.isDir && handleNavigate(item)}
      >
        <div className="p-4 flex flex-col items-center text-center">
          {/* Icon */}
          <div className={`p-4 rounded-xl mb-3 ${item.isDir ? 'bg-blue-500/20 text-blue-400' : 'bg-slate-800/50 text-slate-400'} group-hover:scale-110 transition-transform`}>
            <Icon size={32} />
          </div>

          {/* Name */}
          {isRenaming ? (
            <div className="w-full flex items-center gap-1" onClick={(e) => e.stopPropagation()}>
              <input
                type="text"
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') handleRename();
                  if (e.key === 'Escape') {
                    setRenamingItem(null);
                    setNewName("");
                  }
                }}
                className="flex-1 px-2 py-1 text-xs bg-slate-800 border border-white/10 rounded text-white focus:outline-none focus:border-blue-500"
                autoFocus
              />
              <button onClick={handleRename} className="p-1 rounded bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30">
                <Check size={14} />
              </button>
              <button onClick={() => { setRenamingItem(null); setNewName(""); }} className="p-1 rounded bg-rose-500/20 text-rose-400 hover:bg-rose-500/30">
                <X size={14} />
              </button>
            </div>
          ) : (
            <p className="text-sm font-medium text-white truncate w-full px-2 group-hover:text-blue-400 transition-colors">
              {item.name}
            </p>
          )}

          {/* Size */}
          {!item.isDir && (
            <p className="text-xs text-slate-500 mt-1">{formatFileSize(item.size)}</p>
          )}

          {/* Actions */}
          <div className="flex items-center gap-1 mt-3 opacity-0 group-hover:opacity-100 transition-opacity" onClick={(e) => e.stopPropagation()}>
            {!item.isDir && (isImage(item.name) || isText(item.name)) && (
              <button
                onClick={() => handlePreview(item)}
                className="p-1.5 rounded-lg bg-violet-500/10 hover:bg-violet-500/20 text-violet-400 border border-violet-500/20 transition-all"
                title="Preview"
              >
                <Eye size={12} />
              </button>
            )}
            <button
              onClick={() => { setRenamingItem(item); setNewName(item.name); }}
              className="p-1.5 rounded-lg bg-blue-500/10 hover:bg-blue-500/20 text-blue-400 border border-blue-500/20 transition-all"
              title="Rename"
            >
              <Edit3 size={12} />
            </button>
            {!item.isDir && (
              <button
                onClick={() => handleDownload(item)}
                className="p-1.5 rounded-lg bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 transition-all"
                title="Download"
              >
                <Download size={12} />
              </button>
            )}
            <button
              onClick={() => handleDelete(item)}
              className="p-1.5 rounded-lg bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/20 transition-all"
              title="Delete"
            >
              <Trash2 size={12} />
            </button>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="space-y-6">

      {/* Path Navigation & View Toggle */}
      <GlassCard>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <FolderOpen className="text-blue-400" size={24} />
            <div>
              <p className="text-xs text-slate-400 uppercase tracking-wider mb-1">Current Path</p>
              <p className="text-lg font-semibold text-white font-mono">{path}</p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {/* Trash Button */}
            <button
              onClick={() => { setShowTrash(!showTrash); if (!showTrash) loadTrash(); }}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg ${showTrash ? 'bg-rose-500/20 text-rose-400 border-rose-500/30' : 'bg-white/5 text-slate-300 border-white/10'} hover:bg-white/10 hover:text-white border transition-all`}
            >
              <Trash size={18} />
              <span className="text-sm font-medium">Papierkorb</span>
              {trashedFiles.length > 0 && (
                <span className="px-2 py-0.5 rounded-full bg-rose-500 text-white text-xs font-bold">
                  {trashedFiles.length}
                </span>
              )}
            </button>

            {/* View Mode Toggle */}
            <div className="flex items-center gap-1 p-1 rounded-lg bg-white/5 border border-white/10">
              <button
                onClick={() => setViewMode("list")}
                className={`p-2 rounded ${viewMode === "list" ? 'bg-blue-500/20 text-blue-400' : 'text-slate-400 hover:text-white'} transition-all`}
                title="List View"
              >
                <List size={18} />
              </button>
              <button
                onClick={() => setViewMode("grid")}
                className={`p-2 rounded ${viewMode === "grid" ? 'bg-blue-500/20 text-blue-400' : 'text-slate-400 hover:text-white'} transition-all`}
                title="Grid View"
              >
                <Grid3x3 size={18} />
              </button>
            </div>

            {/* Go Up Button */}
            {!showTrash && path !== "/" && (
              <button
                onClick={goUp}
                className="flex items-center gap-2 px-4 py-2 rounded-lg bg-white/5 hover:bg-white/10 text-slate-300 hover:text-white border border-white/10 transition-all"
              >
                <ArrowUp size={18} />
                <span className="text-sm font-medium">Go Up</span>
              </button>
            )}
          </div>
        </div>
      </GlassCard>

      {/* Upload Section */}
      {!showTrash && (
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
      )}

      {/* Error Display */}
      {error && (
        <div className="rounded-xl border border-rose-500/30 bg-rose-500/10 p-4">
          <p className="text-rose-400 text-sm font-medium">{error}</p>
        </div>
      )}

      {/* Files Display */}
      {showTrash ? (
        /* Trash Bin View */
        <GlassCard>
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-white font-semibold text-lg tracking-tight flex items-center gap-2">
                <Trash className="text-rose-400" size={20} />
                Papierkorb
              </h3>
              <p className="text-slate-400 text-xs mt-1">{trashedFiles.length} gelöschte Dateien</p>
            </div>
            <button
              onClick={() => loadTrash()}
              className="p-2 rounded-lg bg-white/5 hover:bg-white/10 text-slate-400 hover:text-white transition-all"
              title="Refresh"
            >
              <RefreshCw size={18} />
            </button>
          </div>

          {trashedFiles.length === 0 ? (
            <div className="py-12 text-center text-slate-400">
              <Trash size={48} className="mx-auto mb-3 opacity-30" />
              <p className="text-sm">Papierkorb ist leer</p>
            </div>
          ) : (
            <div className="space-y-2">
              {trashedFiles.map((item, idx) => {
                const Icon = getFileIcon(item.name, item.isDir);
                return (
                  <div
                    key={idx}
                    className="flex items-center justify-between p-3 rounded-lg bg-white/5 border border-white/5 hover:bg-white/10 transition-all"
                  >
                    <div className="flex items-center gap-3">
                      <div className="p-2 rounded-lg bg-slate-800/50 text-slate-400">
                        <Icon size={16} />
                      </div>
                      <div>
                        <p className="text-white font-medium text-sm">{item.name}</p>
                        <p className="text-slate-500 text-xs">{item.originalPath || 'Unknown path'}</p>
                      </div>
                    </div>
                    <button
                      onClick={() => handleRestore(item)}
                      className="flex items-center gap-2 px-4 py-2 rounded-lg bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 transition-all"
                    >
                      <RefreshCw size={14} />
                      <span className="text-sm font-medium">Wiederherstellen</span>
                    </button>
                  </div>
                );
              })}
            </div>
          )}
        </GlassCard>
      ) : (
        /* Files View */
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
          ) : viewMode === "grid" ? (
            /* Grid View */
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4">
              {files.map((item) => (
                <FileCard key={item.name} item={item} />
              ))}
              {files.length === 0 && (
                <div className="col-span-full py-12 text-center text-slate-400">
                  <FolderOpen size={48} className="mx-auto mb-3 opacity-30" />
                  <p className="text-sm">No files or folders</p>
                </div>
              )}
            </div>
          ) : (
            /* List View */
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
                  {files.map((item) => {
                    const Icon = getFileIcon(item.name, item.isDir);
                    const isRenaming = renamingItem?.name === item.name;

                    return (
                      <tr
                        key={item.name}
                        className="group border-b border-white/5 last:border-0 hover:bg-white/5 transition-colors cursor-pointer"
                        onClick={() => item.isDir && handleNavigate(item)}
                      >
                        <td className="py-4 px-2 font-medium text-white">
                          {isRenaming ? (
                            <div className="flex items-center gap-2" onClick={(e) => e.stopPropagation()}>
                              <div className={`p-2 rounded-lg ${item.isDir ? 'bg-blue-500/20 text-blue-400' : 'bg-slate-800 text-slate-400'}`}>
                                <Icon size={16} />
                              </div>
                              <input
                                type="text"
                                value={newName}
                                onChange={(e) => setNewName(e.target.value)}
                                onKeyDown={(e) => {
                                  if (e.key === 'Enter') handleRename();
                                  if (e.key === 'Escape') {
                                    setRenamingItem(null);
                                    setNewName("");
                                  }
                                }}
                                className="flex-1 px-3 py-1.5 bg-slate-800 border border-white/10 rounded-lg text-white focus:outline-none focus:border-blue-500"
                                autoFocus
                              />
                              <button onClick={handleRename} className="p-2 rounded-lg bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30">
                                <Check size={14} />
                              </button>
                              <button onClick={() => { setRenamingItem(null); setNewName(""); }} className="p-2 rounded-lg bg-rose-500/20 text-rose-400 hover:bg-rose-500/30">
                                <X size={14} />
                              </button>
                            </div>
                          ) : (
                            <div className="flex items-center gap-3">
                              <div className={`p-2 rounded-lg ${item.isDir ? 'bg-blue-500/20 text-blue-400' : 'bg-slate-800 text-slate-400'}`}>
                                <Icon size={16} />
                              </div>
                              <span className={item.isDir ? "hover:text-blue-400 transition-colors" : ""}>
                                {item.name}
                              </span>
                            </div>
                          )}
                        </td>
                        <td className="py-4 px-2 text-slate-400 font-mono text-xs">
                          {item.isDir ? "-" : formatFileSize(item.size)}
                        </td>
                        <td className="py-4 px-2 text-slate-400 text-xs">
                          {new Date(item.modTime).toLocaleString()}
                        </td>
                        <td className="py-4 px-2 text-right">
                          <div className="flex items-center justify-end gap-2" onClick={(e) => e.stopPropagation()}>
                            {!item.isDir && (isImage(item.name) || isText(item.name)) && (
                              <button
                                onClick={() => handlePreview(item)}
                                className="p-2 rounded-lg bg-violet-500/10 hover:bg-violet-500/20 text-violet-400 border border-violet-500/20 transition-all"
                                title="Preview"
                              >
                                <Eye size={14} />
                              </button>
                            )}
                            <button
                              onClick={() => { setRenamingItem(item); setNewName(item.name); }}
                              className="p-2 rounded-lg bg-blue-500/10 hover:bg-blue-500/20 text-blue-400 border border-blue-500/20 transition-all"
                              title="Rename"
                            >
                              <Edit3 size={14} />
                            </button>
                            {!item.isDir && (
                              <button
                                onClick={() => handleDownload(item)}
                                className="p-2 rounded-lg bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 transition-all"
                                title="Download"
                              >
                                <Download size={14} />
                              </button>
                            )}
                            <button
                              onClick={() => handleDelete(item)}
                              className="p-2 rounded-lg bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/20 transition-all"
                              title="Delete"
                            >
                              <Trash2 size={14} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
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
      )}

      {/* Preview Modal */}
      {previewItem && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-md p-4 animate-in fade-in duration-200">
          <div className="w-full max-w-4xl max-h-[90vh] animate-in zoom-in-95 duration-200">
            <GlassCard>
              <div className="p-6">
                {/* Modal Header */}
                <div className="flex items-start justify-between mb-4">
                  <div>
                    <h2 className="text-xl font-bold text-white tracking-tight">{previewItem.name}</h2>
                    <p className="text-slate-400 text-sm mt-1">{formatFileSize(previewItem.size)}</p>
                  </div>
                  <button
                    onClick={closePreview}
                    className="p-2 rounded-lg bg-slate-800/50 hover:bg-rose-500/20 text-slate-400 hover:text-rose-400 border border-white/10 hover:border-rose-500/30 transition-all"
                  >
                    <X size={20} />
                  </button>
                </div>

                {/* Preview Content */}
                {previewLoading ? (
                  <div className="flex items-center justify-center py-12">
                    <Loader2 size={32} className="text-blue-400 animate-spin" />
                  </div>
                ) : previewContent?.type === 'image' ? (
                  <div className="max-h-[60vh] overflow-auto rounded-lg bg-black/50 p-4">
                    <img
                      src={previewContent.url}
                      alt={previewItem.name}
                      className="max-w-full mx-auto rounded"
                    />
                  </div>
                ) : previewContent?.type === 'text' ? (
                  <div className="max-h-[60vh] overflow-auto rounded-lg bg-slate-900 p-4 border border-white/10">
                    <pre className="text-slate-300 text-sm font-mono whitespace-pre-wrap">
                      {previewContent.content}
                    </pre>
                  </div>
                ) : (
                  <div className="py-12 text-center text-slate-400">
                    <p>Preview not available</p>
                  </div>
                )}

                {/* Actions */}
                <div className="flex items-center justify-end gap-3 mt-4 pt-4 border-t border-white/5">
                  <button
                    onClick={() => handleDownload(previewItem)}
                    className="flex items-center gap-2 px-4 py-2 rounded-lg bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 transition-all"
                  >
                    <Download size={16} />
                    <span>Download</span>
                  </button>
                  <button
                    onClick={closePreview}
                    className="px-4 py-2 rounded-lg bg-slate-800/50 hover:bg-slate-800 text-slate-300 hover:text-white border border-white/10 transition-all"
                  >
                    Close
                  </button>
                </div>
              </div>
            </GlassCard>
          </div>
        </div>
      )}
    </div>
  );
}
