# Testing Issues - Phase 1

## Datum: 2025-11-21

### Issue #1: ValidatePasswordStrength - Nicht vollständig implementiert
**Status:** TO FIX
**Priorität:** MEDIUM
**File:** `src/services/password_service.go:42`

**Problem:**
Die `ValidatePasswordStrength` Methode prüft nur die Mindestlänge (8 Zeichen), aber NICHT:
- Großbuchstaben (uppercase)
- Kleinbuchstaben (lowercase)
- Zahlen (numbers)
- Sonderzeichen (optional)

**Aktueller Code:**
```go
func (s *PasswordService) ValidatePasswordStrength(password string) error {
	if len(password) < 8 {
		return fmt.Errorf("password must be at least 8 characters")
	}
	// Additional strength checks could be added here
	// (uppercase, lowercase, numbers, special chars)
	// For now, just enforce minimum length
	return nil
}
```

**Tests die fehlschlagen:**
- TestPasswordService_ValidatePasswordStrength/no_uppercase
- TestPasswordService_ValidatePasswordStrength/no_lowercase
- TestPasswordService_ValidatePasswordStrength/no_number

**Fix benötigt:**
```go
func (s *PasswordService) ValidatePasswordStrength(password string) error {
	if len(password) < 8 {
		return fmt.Errorf("password must be at least 8 characters")
	}

	hasUpper := false
	hasLower := false
	hasNumber := false

	for _, char := range password {
		switch {
		case unicode.IsUpper(char):
			hasUpper = true
		case unicode.IsLower(char):
			hasLower = true
		case unicode.IsNumber(char):
			hasNumber = true
		}
	}

	if !hasUpper {
		return fmt.Errorf("password must contain at least one uppercase letter")
	}
	if !hasLower {
		return fmt.Errorf("password must contain at least one lowercase letter")
	}
	if !hasNumber {
		return fmt.Errorf("password must contain at least one number")
	}

	return nil
}
```

---

## Test Status Summary

### ✅ Passing Tests (2/3)
1. TestPasswordService_HashPassword - PASS (0.61s)
2. TestPasswordService_ComparePassword - PASS (2.41s)

### ❌ Failing Tests (1/3)
1. TestPasswordService_ValidatePasswordStrength - FAIL (panic on nil check)

### Coverage
- **PasswordService:** ~60% (2 von 3 Methoden vollständig getestet)

---

## Nächste Schritte

1. [ ] Fix ValidatePasswordStrength Implementation
2. [ ] Add JWT Service Tests
3. [ ] Add Token Service Tests
4. [ ] Add Email Service Tests (mit Mocks)
5. [ ] Add Integration Tests für Auth Flow
6. [ ] Add Middleware Tests
7. [ ] Measure Code Coverage (Ziel: 80%+)

### Issue #2: JWT Token Expiration Test - Timing Problem
**Status:** TO FIX  
**Priorität:** LOW
**File:** `src/services/jwt_service_test.go:137`

**Problem:**
Der Test `TestJWTService_TokenExpiration` schlägt fehl weil die Zeitdifferenz zu groß ist (2699 Sekunden statt 15 Minuten = 900 Sekunden).

**Vermutung:**
- Evtl. wird eine andere Zeiteinheit verwendet (Stunden statt Minuten?)
- Oder JWT Service generiert Token mit längerer Laufzeit

**Fix:** 
Prüfe jwt_service.go GenerateAccessToken Implementierung und korrigiere Expiration Time.

---

## Updated Test Status

### ✅ Password Service (2/3 passing)
1. TestPasswordService_HashPassword - PASS
2. TestPasswordService_ComparePassword - PASS  
3. TestPasswordService_ValidatePasswordStrength - FAIL

### ✅ JWT Service (5/6 passing)
1. TestJWTService_GenerateAccessToken - PASS
2. TestJWTService_GenerateRefreshToken - PASS
3. TestJWTService_ValidateToken - PASS (all 5 subtests)
4. TestJWTService_TokenExpiration - FAIL (timing issue)
5. TestJWTService_RefreshTokenExpiration - PASS
6. TestJWTService_ClaimsContent - PASS

### Total: 7/9 tests passing (77.8%)

---

### Issue #3: RateLimiter Test - Pointer Comparison Issue
**Status:** TO FIX
**Priorität:** LOW
**File:** `src/middleware/ratelimit_test.go:159`

**Problem:**
Der Test `TestRateLimiter_LimiterCreation` schlägt fehl weil assert.NotEqual nicht gut mit Pointer-Vergleichen funktioniert. Die beiden Limiter haben dieselbe Struktur.

**Fehler:**
```
Should not be: &rate.Limiter{...}
Messages: Different IPs should have different limiters
```

**Fix:**
Test sollte stattdessen prüfen ob die Limiters im Map unter verschiedenen Keys gespeichert sind, oder eine andere Vergleichsmethode verwenden (z.B. Vergleich der Adressen mit `!=` statt assert.NotEqual).

**Tests Ergebnis:**
- 6/7 Rate Limiter Tests passing
- Nur TestRateLimiter_LimiterCreation fails

---

## Aktueller Test Status - Gesamt

### ✅ Services Tests
- **Password Service:** 2/3 passing
- **JWT Service:** 5/6 passing
- **Token Service:** 8/8 passing ✅

### ✅ Middleware Tests
- **Auth Middleware:** 6/6 passing ✅
- **Rate Limiter:** 6/7 passing

### ✅ Integration Tests
- **Health Endpoint:** 2/2 passing ✅

### Total Progress: 29/32 tests passing (90.6%)

