package config

import (
	"fmt"
	"os"
	"strings"
)

const minJWTSecretLength = 32

func readSecretFromFile(path string) (string, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return "", fmt.Errorf("CRITICAL: failed to read JWT secret file '%s': %w", path, err)
	}

	secret := strings.TrimSpace(string(data))
	if secret == "" {
		return "", fmt.Errorf("CRITICAL: JWT secret file '%s' is empty", path)
	}

	return secret, nil
}

// ValidateJWTSecret enforces basic strength rules for JWT secrets.
func ValidateJWTSecret(secret string) error {
	trimmed := strings.TrimSpace(secret)
	if trimmed == "" {
		return fmt.Errorf("CRITICAL: JWT_SECRET is required for token signing")
	}

	if len(trimmed) < minJWTSecretLength {
		return fmt.Errorf("CRITICAL: JWT_SECRET must be at least %d characters (got %d)", minJWTSecretLength, len(trimmed))
	}

	return nil
}
