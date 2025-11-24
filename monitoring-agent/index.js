const axios = require('axios');
const os = require('os');

const API_URL = process.env.API_URL || 'http://api:8080/monitoring/ingest';
const MONITORING_TOKEN = process.env.MONITORING_TOKEN || '';
const SOURCE = process.env.MONITORING_SOURCE || os.hostname();
const INTERVAL_MS = parseInt(process.env.MONITORING_INTERVAL_MS || '5000', 10);

if (!MONITORING_TOKEN) {
  console.error('MONITORING_TOKEN is required');
  process.exit(1);
}

function sampleCpuPercent() {
  const loads = os.loadavg();
  const cores = os.cpus().length || 1;
  const oneMinLoad = loads[0];
  return Math.min(100, Math.max(0, (oneMinLoad / cores) * 100));
}

function sampleRamPercent() {
  const total = os.totalmem();
  const free = os.freemem();
  if (!total) return 0;
  return Math.min(100, Math.max(0, ((total - free) / total) * 100));
}

async function sendSample() {
  const payload = {
    source: SOURCE,
    cpu_percent: Math.round(sampleCpuPercent() * 100) / 100,
    ram_percent: Math.round(sampleRamPercent() * 100) / 100,
  };

  try {
    await axios.post(API_URL, payload, {
      headers: {
        'Content-Type': 'application/json',
        'X-Monitoring-Token': MONITORING_TOKEN,
      },
      timeout: 4000,
    });
    console.log('[monitoring-agent] sent sample', payload);
  } catch (err) {
    console.error('[monitoring-agent] failed to send sample', err.message);
  }
}

setInterval(sendSample, INTERVAL_MS);
sendSample();
