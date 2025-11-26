# APIAgent Status Log #006

**Datum:** 2025-11-21
**Agent:** APIAgent (Backend Core)
**Aufgabe:** Epic 3 - Email & External Services Integration
**Status:** 🔄 IN PROGRESS

**Dependencies:** Epic 2 ✅ COMPLETE (Authentication operational)

---

## 1. ZIEL

Implementierung von **Email Services** (Resend) und **Cloudflare Integration** für:

**Email Features:**
- Email verification flow (confirm email after registration)
- Password reset flow (forgot password)
- Welcome emails
- Email templates (HTML + Text fallback)

**Cloudflare Features:**
- CDN integration (optional, preparation)
- R2 storage preparation (for future file uploads)

**Deliverables:**
- ✅ Resend email service integration
- ✅ Email verification endpoint (`POST /auth/verify-email`)
- ✅ Password reset request endpoint (`POST /auth/forgot-password`)
- ✅ Password reset confirmation endpoint (`POST /auth/reset-password`)
- ✅ Email templates (HTML + plain text)
- ✅ Verification tokens (Redis storage, 24h expiry)
- ⏳ Cloudflare R2 preparation (Phase 4)

**Security Goals:**
- ✅ Email verification tokens (32-byte random, single-use)
- ✅ Password reset tokens (32-byte random, 1-hour expiry, single-use)
- ✅ Rate limiting on email endpoints (prevent spam)
- ✅ No email enumeration (same response for existing/non-existing users)
- ✅ Audit logging for all email operations

---

## 2. DEPENDENCIES

### 2.1 External Services

**Resend API:**
- API Token: `re_AEhvFZrx_KRjdCcvcVHLcnPNY66ekBBFy`
- Documentation: https://resend.com/docs
- Rate Limits: 100 emails/day (free tier)

**Cloudflare API:**
- API Token: `GjKJMQiS998conpswEJhOwQ5b-fKSGjVmmFsofJf`
- Documentation: https://developers.cloudflare.com/api/
- Features: R2 Storage (S3-compatible), CDN, Workers

### 2.2 Go Packages

```bash
# Resend SDK (if available) or HTTP client
go get github.com/resend/resend-go
# OR use net/http directly

# HTML template rendering (built-in)
# html/template (already in stdlib)
```

---

## 3. IMPLEMENTATION PLAN

### Phase A: Email Service Setup (1 hour)

**A1: Resend Service**
- [ ] Create `src/services/email_service.go`
- [ ] Resend API client wrapper
- [ ] SendEmail() method
- [ ] SendVerificationEmail() helper
- [ ] SendPasswordResetEmail() helper
- [ ] SendWelcomeEmail() helper
- [ ] Error handling + retries

**A2: Email Templates**
- [ ] Create `src/templates/email/` directory
- [ ] `verification.html` - Email verification template
- [ ] `verification.txt` - Plain text fallback
- [ ] `password_reset.html` - Password reset template
- [ ] `password_reset.txt` - Plain text fallback
- [ ] `welcome.html` - Welcome email template
- [ ] `welcome.txt` - Plain text fallback

**A3: Configuration**
- [ ] Add Resend API token to config
- [ ] Add sender email (`from` address)
- [ ] Add frontend URL (for verification links)

---

### Phase B: Email Verification (1.5 hours)

**B1: Update Registration**
- [ ] Modify registration handler to send verification email
- [ ] Generate verification token (32-byte random)
- [ ] Store token in Redis (24h expiry, user_id mapping)
- [ ] User starts as `email_verified: false`
- [ ] Update users table (add `email_verified` column)

**B2: Verification Endpoint**
- [ ] `POST /auth/verify-email` handler
- [ ] Request body: `{"token": "..."}`
- [ ] Validate token from Redis
- [ ] Mark user as verified in database
- [ ] Delete token from Redis (single-use)
- [ ] Return success message
- [ ] Audit log

**B3: Resend Verification**
- [ ] `POST /auth/resend-verification` handler
- [ ] Require authentication (JWT)
- [ ] Check if already verified
- [ ] Rate limit: 1 email per 5 minutes per user
- [ ] Generate new token
- [ ] Send new verification email

---

### Phase C: Password Reset (1.5 hours)

**C1: Forgot Password Endpoint**
- [ ] `POST /auth/forgot-password` handler
- [ ] Request body: `{"email": "..."}`
- [ ] Find user by email
- [ ] **IMPORTANT:** Always return 200 OK (no user enumeration)
- [ ] If user exists: generate reset token (32-byte random)
- [ ] Store token in Redis (1h expiry, user_id mapping)
- [ ] Send password reset email
- [ ] Rate limit: 3 requests per hour per IP
- [ ] Audit log (including failed attempts)

**C2: Reset Password Endpoint**
- [ ] `POST /auth/reset-password` handler
- [ ] Request body: `{"token": "...", "new_password": "..."}`
- [ ] Validate token from Redis
- [ ] Validate password strength
- [ ] Hash new password (bcrypt cost 12)
- [ ] Update user password in database
- [ ] Delete token from Redis (single-use)
- [ ] Invalidate all existing tokens (logout all sessions)
- [ ] Send confirmation email ("Your password was changed")
- [ ] Return success message
- [ ] Audit log

---

### Phase D: Database Schema Updates (30 min)

**D1: Users Table Migration**
```sql
ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN verified_at TIMESTAMP WITH TIME ZONE;
```

**D2: Update User Model**
- [ ] Add `EmailVerified bool` field
- [ ] Add `VerifiedAt *time.Time` field
- [ ] Update repository methods

---

### Phase E: Cloudflare Preparation (30 min)

**E1: Cloudflare Service (Stub)**
- [ ] Create `src/services/cloudflare_service.go`
- [ ] R2 client setup (for Phase 4)
- [ ] Configuration placeholders
- [ ] Basic connectivity test

**E2: Configuration**
- [ ] Add Cloudflare API token to config
- [ ] Add R2 bucket name (placeholder)
- [ ] Add CDN URL (placeholder)

---

### Phase F: Testing (1 hour)

**F1: Manual Testing**
- [ ] Register new user → receive verification email
- [ ] Verify email with token → user marked as verified
- [ ] Request password reset → receive reset email
- [ ] Reset password with token → password changed
- [ ] Try to reuse tokens → rejected (single-use)
- [ ] Try expired tokens → rejected
- [ ] Test rate limiting on email endpoints

**F2: Edge Cases**
- [ ] Verify email for non-existent user
- [ ] Reset password for non-existent user (no enumeration)
- [ ] Multiple verification requests (rate limit)
- [ ] Expired tokens

---

## 4. SECURITY REQUIREMENTS CHECKLIST

### Email Security

- [ ] **Verification tokens**
  - 32-byte random generation
  - Stored in Redis (not database)
  - 24-hour expiry
  - Single-use (deleted after verification)
  - No user enumeration

- [ ] **Password reset tokens**
  - 32-byte random generation
  - Stored in Redis (not database)
  - 1-hour expiry
  - Single-use (deleted after reset)
  - No user enumeration
  - Invalidate all sessions on reset

- [ ] **Rate limiting**
  - Verification resend: 1 per 5 minutes per user
  - Password reset request: 3 per hour per IP
  - Registration email: handled by existing rate limit

- [ ] **Audit logging**
  - All email send attempts
  - All verification attempts
  - All password reset attempts
  - Include IP address + user agent

- [ ] **Email content security**
  - No sensitive data in emails
  - Use HTTPS links only
  - Tokens in URL, not email body text
  - Clear expiry time in email

---

## 5. API ENDPOINTS

### New Endpoints

```
POST /auth/verify-email
Body: {"token": "abc123..."}
Response: 200 OK {"message": "Email verified successfully"}

POST /auth/resend-verification
Headers: Authorization: Bearer <jwt>
Response: 200 OK {"message": "Verification email sent"}

POST /auth/forgot-password
Body: {"email": "user@example.com"}
Response: 200 OK {"message": "If the email exists, a reset link has been sent"}

POST /auth/reset-password
Body: {"token": "xyz789...", "new_password": "newpass123"}
Response: 200 OK {"message": "Password reset successfully"}
```

### Modified Endpoints

```
POST /auth/register
- Now sends verification email
- Returns: user + tokens + "email_verified: false"

POST /auth/login
- Check if email verified (optional enforcement)
- Returns: user info including "email_verified" status
```

---

## 6. EMAIL TEMPLATES

### Verification Email

**Subject:** Verify your NAS.AI email address

**Body (HTML):**
```html
<h1>Welcome to NAS.AI!</h1>
<p>Please verify your email address by clicking the link below:</p>
<a href="{{.VerifyURL}}">Verify Email</a>
<p>This link expires in 24 hours.</p>
<p>If you didn't create this account, please ignore this email.</p>
```

**Verify URL Format:**
```
https://nas.ai/verify-email?token=<verification_token>
```

### Password Reset Email

**Subject:** Reset your NAS.AI password

**Body (HTML):**
```html
<h1>Password Reset Request</h1>
<p>You requested to reset your password. Click the link below:</p>
<a href="{{.ResetURL}}">Reset Password</a>
<p>This link expires in 1 hour.</p>
<p>If you didn't request this, please ignore this email and your password will remain unchanged.</p>
```

**Reset URL Format:**
```
https://nas.ai/reset-password?token=<reset_token>
```

---

## 7. TIMELINE

| Phase | Tasks | Estimated Time | Status |
|-------|-------|----------------|--------|
| **A: Email Service** | Resend integration + templates | 1h | ⏳ NEXT |
| **B: Email Verification** | Verify flow + resend | 1.5h | ⏳ |
| **C: Password Reset** | Forgot + reset flow | 1.5h | ⏳ |
| **D: Database Updates** | Schema migration | 30min | ⏳ |
| **E: Cloudflare Prep** | R2 stub setup | 30min | ⏳ |
| **F: Testing** | Manual + edge cases | 1h | ⏳ |
| **TOTAL** | A-F | **6 hours** | **~1 day** |

**Target Completion:** 2025-11-22 (1 day from now)

---

## 8. NEXT IMMEDIATE ACTIONS

1. ⏳ Install Resend Go SDK (if available) or prepare HTTP client
2. ⏳ Create email service with Resend API integration
3. ⏳ Create email templates (HTML + text)
4. ⏳ Update database schema (add email_verified column)
5. ⏳ Implement email verification flow

**Starting with Phase A1: Resend Service Setup...**

---

**Status:** 🔄 STARTING Phase A (Email Service Setup)
**Letzte Aktualisierung:** 2025-11-21 18:35 UTC

Terminal freigegeben.
