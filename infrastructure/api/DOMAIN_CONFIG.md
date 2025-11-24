# Domain Configuration

## Domain Setup

**Main Domain:** `felix-freund.com`

### Subdomains

- **API:** `api.felix-freund.com`
- **Frontend:** `felix-freund.com` (root domain)

## Cloudflare Tunnel Configuration

### DNS Records

```
Type: CNAME
Name: api
Content: <TUNNEL-ID>.cfargotunnel.com
Proxy: Proxied (Orange Cloud ☁️)
TTL: Auto
```

### Tunnel Config (`~/.cloudflared/config.yml`)

```yaml
tunnel: nas-api
credentials-file: /home/user/.cloudflared/<TUNNEL-ID>.json

ingress:
  # API Endpoint
  - hostname: api.felix-freund.com
    service: http://localhost:8080
    originRequest:
      noTLSVerify: true
      connectTimeout: 30s

  # Frontend (optional)
  - hostname: felix-freund.com
    service: http://localhost:5173

  # Catchall (required)
  - service: http_status:404
```

## Environment Variables

### Production

```bash
# Server
export PORT=8080
export ENV=production
export LOG_LEVEL=info

# CORS
export CORS_ORIGINS=https://felix-freund.com,https://api.felix-freund.com

# Frontend
export FRONTEND_URL=https://felix-freund.com

# Email
export EMAIL_FROM="NAS.AI <noreply@felix-freund.com>"

# Security
export JWT_SECRET="<your-secure-secret-min-32-chars>"
```

### Development

```bash
# Server
export PORT=8080
export ENV=development
export LOG_LEVEL=debug

# CORS (allows localhost)
export CORS_ORIGINS=http://localhost:5173,http://localhost:3000

# Frontend
export FRONTEND_URL=http://localhost:5173

# Email
export EMAIL_FROM="NAS.AI Dev <noreply@felix-freund.com>"
```

## API Endpoints

### Base URLs

- **Production:** `https://api.felix-freund.com`
- **Development:** `http://localhost:8080`

### Example Endpoints

```
GET  https://api.felix-freund.com/health
POST https://api.felix-freund.com/auth/register
POST https://api.felix-freund.com/auth/login
GET  https://api.felix-freund.com/docs/swagger/index.html
```

## Email Configuration

### Sender Addresses

- **Production:** `noreply@felix-freund.com`
- **Support:** `support@felix-freund.com`

### Email Templates

All email templates reference:
- Verification links: `https://felix-freund.com/verify?token=...`
- Password reset: `https://felix-freund.com/reset-password?token=...`

## SSL/TLS

**Managed by:** Cloudflare (automatic)

**Certificate:** Cloudflare Universal SSL
**Encryption Mode:** Full (or Full Strict)
**TLS Version:** 1.2+ (TLS 1.3 enabled)
**HSTS:** Enabled (max-age: 31536000)

## Verification

### Test HTTPS Setup

```bash
# Run verification script
./scripts/verify-https.sh

# Or test specific URL
./scripts/verify-https.sh https://api.felix-freund.com
```

### Manual Tests

```bash
# Check API health
curl https://api.felix-freund.com/health

# Check SSL certificate
echo | openssl s_client -servername api.felix-freund.com -connect api.felix-freund.com:443

# Check headers
curl -I https://api.felix-freund.com/health
```

## Updated Files

All references to `nas.felix-freund.com` have been updated to `felix-freund.com`:

- ✅ `src/config/config.go` - Email and Frontend URL defaults
- ✅ `src/main.go` - Swagger documentation
- ✅ `docs/swagger.yaml` - API documentation
- ✅ `docs/swagger.json` - API documentation
- ✅ `docs/docs.go` - Generated swagger docs
- ✅ `scripts/verify-https.sh` - HTTPS verification script
- ✅ `status/APIAgent/phase1/*.md` - Documentation files

## Service Status

### Check Services

```bash
# Cloudflare Tunnel
systemctl status cloudflared

# API Service (if using systemd)
systemctl status nas-api

# Check tunnel logs
journalctl -u cloudflared -f
```

### Restart Services

```bash
# Restart tunnel
sudo systemctl restart cloudflared

# Restart API
sudo systemctl restart nas-api

# Or manually
cd /home/freun/Agent/infrastructure/api
./bin/api
```

## Monitoring

### Cloudflare Dashboard

- Analytics: https://dash.cloudflare.com → Analytics
- Tunnel Status: https://dash.cloudflare.com → Zero Trust → Access → Tunnels
- SSL/TLS Settings: https://dash.cloudflare.com → SSL/TLS

### External Tools

- **SSL Test:** https://www.ssllabs.com/ssltest/analyze.html?d=api.felix-freund.com
- **Security Headers:** https://securityheaders.com/?q=api.felix-freund.com
- **DNS Check:** https://dnschecker.org/#A/api.felix-freund.com
