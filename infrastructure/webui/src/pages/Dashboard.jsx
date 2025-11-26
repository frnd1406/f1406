import { useEffect, useState } from "react";
import { authHeaders } from "../utils/auth";
import {
  Activity,
  HardDrive,
  ShieldCheck,
  ShieldAlert,
  Loader2,
  Cpu,
  MemoryStick,
  Clock,
  TrendingUp,
  Archive,
  ArrowRight,
} from "lucide-react";
import { Link } from "react-router-dom";

const API_BASE =
  import.meta.env.VITE_API_BASE_URL ||
  `${window.location.protocol}//${window.location.hostname}:8080`;

// Glass Card Component
const GlassCard = ({ children, className = "" }) => (
  <div className={`relative overflow-hidden rounded-2xl border border-white/10 bg-slate-900/40 backdrop-blur-xl shadow-2xl ${className}`}>
    <div className="absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-white/20 to-transparent opacity-50"></div>
    <div className="p-6 h-full flex flex-col">
      {children}
    </div>
  </div>
);

// Metric Card Component
const MetricCard = ({ icon: Icon, title, value, subtext, color = "blue", trend, loading }) => (
  <GlassCard className={`hover:bg-${color}-500/5 transition-colors`}>
    <div className="flex items-start justify-between">
      <div className={`p-3 rounded-xl bg-${color}-500/20 border border-${color}-500/30`}>
        <Icon size={24} className={`text-${color}-400`} />
      </div>
      {trend && (
        <div className="flex items-center gap-1 text-emerald-400 text-xs font-medium">
          <TrendingUp size={14} />
          <span>{trend}</span>
        </div>
      )}
    </div>
    <div className="mt-4 flex-1">
      <p className="text-slate-400 text-xs uppercase tracking-wider">{title}</p>
      {loading ? (
        <div className="mt-2 flex items-center gap-2">
          <Loader2 size={16} className="animate-spin text-slate-400" />
          <span className="text-slate-400 text-sm">Laden...</span>
        </div>
      ) : (
        <>
          <p className="text-2xl font-bold text-white mt-2">{value}</p>
          {subtext && <p className="text-slate-500 text-xs mt-1">{subtext}</p>}
        </>
      )}
    </div>
  </GlassCard>
);

export default function Dashboard() {
  const [loading, setLoading] = useState(true);
  const [backupStatus, setBackupStatus] = useState(null);
  const [lastBackup, setLastBackup] = useState(null);
  const [settings, setSettings] = useState(null);

  // Load Backup Info
  const loadBackupStatus = async () => {
    try {
      // Load Settings (Schedule, Auto-Backup Status)
      const settingsRes = await fetch(`${API_BASE}/api/v1/system/settings`, {
        credentials: "include",
        headers: authHeaders(),
      });
      if (settingsRes.ok) {
        const settingsData = await settingsRes.json();
        setSettings(settingsData);
      }

      // Load Last Backup
      const backupsRes = await fetch(`${API_BASE}/api/v1/backups`, {
        credentials: "include",
        headers: authHeaders(),
      });
      if (backupsRes.ok) {
        const backupsData = await backupsRes.json();
        const backups = backupsData.items || [];
        if (backups.length > 0) {
          // Sort by date and get the most recent
          const sorted = backups.sort((a, b) =>
            new Date(b.modTime || b.created_at) - new Date(a.modTime || a.created_at)
          );
          setLastBackup(sorted[0]);
        }
      }
    } catch (err) {
      console.error("Fehler beim Laden der Backup-Infos:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadBackupStatus();
    // Refresh every 30 seconds
    const interval = setInterval(loadBackupStatus, 30000);
    return () => clearInterval(interval);
  }, []);

  // Calculate next backup time
  const getNextBackupTime = () => {
    if (!settings?.backup_schedule) return "Nicht geplant";

    const now = new Date();
    const [hours, minutes] = settings.backup_schedule.split(':');
    const nextRun = new Date();
    nextRun.setHours(parseInt(hours), parseInt(minutes), 0, 0);

    // If the time has passed today, set it to tomorrow
    if (nextRun < now) {
      nextRun.setDate(nextRun.getDate() + 1);
    }

    // Check if it's today or tomorrow
    const isToday = nextRun.toDateString() === now.toDateString();
    const timeStr = settings.backup_schedule;

    return isToday ? `Heute, ${timeStr} Uhr` : `Morgen, ${timeStr} Uhr`;
  };

  const formatLastBackupTime = () => {
    if (!lastBackup) return "Kein Backup vorhanden";

    const date = new Date(lastBackup.modTime || lastBackup.created_at);
    const now = new Date();
    const diffMs = now - date;
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
    const diffDays = Math.floor(diffHours / 24);

    if (diffDays > 0) {
      return `vor ${diffDays} Tag${diffDays > 1 ? 'en' : ''}`;
    } else if (diffHours > 0) {
      return `vor ${diffHours} Stunde${diffHours > 1 ? 'n' : ''}`;
    } else {
      return "Kürzlich";
    }
  };

  const isBackupActive = settings?.auto_backup_enabled ?? true;

  return (
    <div className="space-y-6">

      {/* Welcome Header */}
      <div>
        <h1 className="text-3xl font-bold text-white tracking-tight">
          Dashboard Übersicht
        </h1>
        <p className="text-slate-400 mt-2 text-sm">
          Willkommen zurück. Hier ist der aktuelle Status Ihres Systems.
        </p>
      </div>

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">

        {/* Data Security Card */}
        <GlassCard className={`${isBackupActive ? 'hover:bg-emerald-500/5' : 'hover:bg-slate-500/5'} transition-colors`}>
          <div className="flex items-start justify-between">
            <div className={`p-3 rounded-xl ${isBackupActive ? 'bg-emerald-500/20 border-emerald-500/30' : 'bg-slate-700/50 border-slate-500/30'} border`}>
              {isBackupActive ? (
                <ShieldCheck size={24} className="text-emerald-400" />
              ) : (
                <ShieldAlert size={24} className="text-slate-400" />
              )}
            </div>
            {loading && (
              <Loader2 size={16} className="animate-spin text-slate-400" />
            )}
          </div>

          <div className="mt-4 flex-1">
            <p className="text-slate-400 text-xs uppercase tracking-wider">Datensicherheit</p>
            <p className={`text-2xl font-bold mt-2 ${isBackupActive ? 'text-emerald-400' : 'text-slate-400'}`}>
              {isBackupActive ? 'Auto-Backup' : 'Manuell'}
            </p>

            <div className="mt-3 space-y-2">
              <div className="flex items-center gap-2 text-xs">
                <Clock size={12} className={isBackupActive ? 'text-emerald-400' : 'text-slate-500'} />
                <span className="text-slate-300">
                  Nächster Lauf: <span className={isBackupActive ? 'text-emerald-400 font-medium' : 'text-slate-400'}>{getNextBackupTime()}</span>
                </span>
              </div>

              <div className="flex items-center gap-2 text-xs">
                <Archive size={12} className="text-blue-400" />
                <span className="text-slate-300">
                  Letzter Snapshot: <span className="text-blue-400 font-medium">{formatLastBackupTime()}</span>
                </span>
              </div>
            </div>
          </div>

          {/* Quick Link to Backup Page */}
          <Link
            to="/backups"
            className="mt-4 flex items-center justify-between p-2 rounded-lg bg-white/5 hover:bg-white/10 transition-colors group"
          >
            <span className="text-xs text-slate-400 group-hover:text-white">Backup verwalten</span>
            <ArrowRight size={14} className="text-slate-400 group-hover:text-white group-hover:translate-x-1 transition-all" />
          </Link>
        </GlassCard>

        {/* CPU Usage Card (Placeholder) */}
        <MetricCard
          icon={Cpu}
          title="CPU Auslastung"
          value="—"
          subtext="Keine Daten verfügbar"
          color="blue"
          loading={false}
        />

        {/* Memory Usage Card (Placeholder) */}
        <MetricCard
          icon={MemoryStick}
          title="Arbeitsspeicher"
          value="—"
          subtext="Keine Daten verfügbar"
          color="violet"
          loading={false}
        />

        {/* Storage Card (Placeholder) */}
        <MetricCard
          icon={HardDrive}
          title="Speicher"
          value="—"
          subtext="Keine Daten verfügbar"
          color="cyan"
          loading={false}
        />

        {/* System Health Card (Placeholder) */}
        <MetricCard
          icon={Activity}
          title="System Status"
          value="Online"
          subtext="Alle Dienste laufen"
          color="emerald"
          loading={false}
        />

        {/* Backup Count Card */}
        <GlassCard className="hover:bg-blue-500/5 transition-colors">
          <div className="flex items-start justify-between">
            <div className="p-3 rounded-xl bg-blue-500/20 border border-blue-500/30">
              <Archive size={24} className="text-blue-400" />
            </div>
          </div>

          <div className="mt-4 flex-1">
            <p className="text-slate-400 text-xs uppercase tracking-wider">Snapshots</p>
            {loading ? (
              <div className="mt-2 flex items-center gap-2">
                <Loader2 size={16} className="animate-spin text-slate-400" />
                <span className="text-slate-400 text-sm">Laden...</span>
              </div>
            ) : (
              <>
                <p className="text-2xl font-bold text-white mt-2">
                  {lastBackup ? '1+' : '0'}
                </p>
                <p className="text-slate-500 text-xs mt-1">
                  {settings?.backup_retention ? `${settings.backup_retention} Tage Aufbewahrung` : 'Keine Retention konfiguriert'}
                </p>
              </>
            )}
          </div>

          <Link
            to="/backups"
            className="mt-4 flex items-center justify-between p-2 rounded-lg bg-white/5 hover:bg-white/10 transition-colors group"
          >
            <span className="text-xs text-slate-400 group-hover:text-white">Details anzeigen</span>
            <ArrowRight size={14} className="text-slate-400 group-hover:text-white group-hover:translate-x-1 transition-all" />
          </Link>
        </GlassCard>

      </div>

      {/* Quick Actions */}
      <GlassCard>
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="text-white font-semibold text-lg tracking-tight">Schnellzugriff</h3>
            <p className="text-slate-400 text-xs mt-1">Häufig verwendete Funktionen</p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Link
            to="/files"
            className="p-4 rounded-xl bg-white/5 hover:bg-white/10 border border-white/5 hover:border-blue-500/30 transition-all group"
          >
            <HardDrive size={20} className="text-blue-400 mb-2" />
            <p className="text-white font-medium text-sm">Dateien verwalten</p>
            <p className="text-slate-400 text-xs mt-1">Upload, Download & Organisation</p>
          </Link>

          <Link
            to="/backups"
            className="p-4 rounded-xl bg-white/5 hover:bg-white/10 border border-white/5 hover:border-emerald-500/30 transition-all group"
          >
            <Archive size={20} className="text-emerald-400 mb-2" />
            <p className="text-white font-medium text-sm">Backups erstellen</p>
            <p className="text-slate-400 text-xs mt-1">System-Snapshots & Recovery</p>
          </Link>

          <Link
            to="/metrics"
            className="p-4 rounded-xl bg-white/5 hover:bg-white/10 border border-white/5 hover:border-violet-500/30 transition-all group"
          >
            <Activity size={20} className="text-violet-400 mb-2" />
            <p className="text-white font-medium text-sm">System-Metriken</p>
            <p className="text-slate-400 text-xs mt-1">Alerts & Monitoring</p>
          </Link>
        </div>
      </GlassCard>

      {/* System Info Footer */}
      <div className="flex items-center justify-between p-4 rounded-xl bg-blue-500/5 border border-blue-500/10">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-blue-500/20 rounded-lg">
            <Activity size={16} className="text-blue-400" />
          </div>
          <div>
            <p className="text-sm font-medium text-white">System läuft stabil</p>
            <p className="text-xs text-slate-400 mt-0.5">
              {isBackupActive
                ? `Automatische Backups aktiv · Nächster Lauf: ${getNextBackupTime()}`
                : 'Automatische Backups deaktiviert · Manueller Modus aktiv'}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
