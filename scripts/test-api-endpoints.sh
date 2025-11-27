#!/bin/bash
set -e

# Farben für Output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Konfiguration
API_URL="${API_URL:-https://felix-freund.com}"
VERBOSE="${VERBOSE:-false}"

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}     NAS.AI API Endpoint Testing Tool${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo ""
echo -e "${YELLOW}API URL: ${API_URL}${NC}"
echo ""

# Funktion zum Testen eines Endpoints
test_endpoint() {
    local method=$1
    local path=$2
    local expected_status=$3
    local description=$4
    local auth_required=$5
    local data=$6

    local full_url="${API_URL}${path}"

    # Build curl command
    local curl_cmd="curl -s -w '\n%{http_code}' -X ${method}"

    if [ "$auth_required" = "true" ] && [ -n "$JWT_TOKEN" ]; then
        curl_cmd="${curl_cmd} -H 'Authorization: Bearer ${JWT_TOKEN}'"
        curl_cmd="${curl_cmd} -H 'X-CSRF-Token: ${CSRF_TOKEN}'"
    fi

    if [ -n "$data" ]; then
        curl_cmd="${curl_cmd} -H 'Content-Type: application/json' -d '${data}'"
    fi

    curl_cmd="${curl_cmd} '${full_url}'"

    # Execute request
    if [ "$VERBOSE" = "true" ]; then
        echo -e "${BLUE}>>> ${method} ${path}${NC}"
        [ -n "$data" ] && echo -e "${BLUE}>>> Data: ${data}${NC}"
    fi

    response=$(eval $curl_cmd 2>/dev/null || echo "ERROR\n000")
    status_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')

    # Check status
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}✅ ${method} ${path} - ${description}${NC}"
        [ "$VERBOSE" = "true" ] && echo -e "${GREEN}   Status: ${status_code}${NC}"
    else
        echo -e "${RED}❌ ${method} ${path} - ${description}${NC}"
        echo -e "${RED}   Expected: ${expected_status}, Got: ${status_code}${NC}"
        [ "$VERBOSE" = "true" ] && echo -e "${RED}   Response: ${body}${NC}"
    fi
}

# ==================================================
# PUBLIC ENDPOINTS (No Auth Required)
# ==================================================
echo -e "${YELLOW}Testing Public Endpoints...${NC}"

test_endpoint "GET" "/health" "200" "Health Check" "false"
test_endpoint "GET" "/api/v1/system/metrics?limit=1" "200" "System Metrics (Latest)" "false"
test_endpoint "GET" "/api/v1/system/alerts" "200" "System Alerts List" "false"

echo ""

# ==================================================
# AUTH ENDPOINTS
# ==================================================
echo -e "${YELLOW}Testing Auth Endpoints...${NC}"

# Test invalid login (should return 400)
test_endpoint "POST" "/auth/login" "400" "Login (Invalid Request)" "false" '{"email":""}'

# Test CSRF Token
test_endpoint "GET" "/api/v1/auth/csrf" "200" "Get CSRF Token" "false"

echo ""

# ==================================================
# PROTECTED ENDPOINTS (Require Auth)
# ==================================================
echo -e "${YELLOW}Testing Protected Endpoints (without auth - should fail)...${NC}"

test_endpoint "GET" "/api/v1/system/settings" "401" "Get System Settings (Unauthorized)" "false"
test_endpoint "GET" "/api/v1/backups" "401" "Get Backups List (Unauthorized)" "false"
test_endpoint "GET" "/api/v1/storage/files?path=/" "401" "Get Files List (Unauthorized)" "false"
test_endpoint "GET" "/api/v1/storage/trash" "401" "Get Trash List (Unauthorized)" "false"

echo ""

# ==================================================
# OPTIONAL: TEST WITH AUTHENTICATION
# ==================================================
if [ -n "$JWT_TOKEN" ] && [ -n "$CSRF_TOKEN" ]; then
    echo -e "${YELLOW}Testing Protected Endpoints (with auth)...${NC}"

    test_endpoint "GET" "/api/v1/system/settings" "200" "Get System Settings" "true"
    test_endpoint "GET" "/api/v1/backups" "200" "Get Backups List" "true"
    test_endpoint "GET" "/api/v1/storage/files?path=/" "200" "Get Files List" "true"
    test_endpoint "GET" "/api/v1/storage/trash" "200" "Get Trash List" "true"

    echo ""
else
    echo -e "${BLUE}ℹ️  Skipping authenticated tests (JWT_TOKEN not set)${NC}"
    echo -e "${BLUE}   To test authenticated endpoints:${NC}"
    echo -e "${BLUE}   1. Login via WebUI and get JWT token from browser DevTools${NC}"
    echo -e "${BLUE}   2. Export JWT_TOKEN='your-token-here'${NC}"
    echo -e "${BLUE}   3. Export CSRF_TOKEN='your-csrf-token-here'${NC}"
    echo -e "${BLUE}   4. Run this script again${NC}"
    echo ""
fi

# ==================================================
# SUMMARY
# ==================================================
echo -e "${BLUE}=====================================================${NC}"
echo -e "${GREEN}✅ Testing Complete!${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo ""
echo -e "${YELLOW}Usage Examples:${NC}"
echo -e "  ${GREEN}# Basic test${NC}"
echo -e "  ./test-api-endpoints.sh"
echo ""
echo -e "  ${GREEN}# Verbose mode${NC}"
echo -e "  VERBOSE=true ./test-api-endpoints.sh"
echo ""
echo -e "  ${GREEN}# Test different API URL${NC}"
echo -e "  API_URL=http://localhost:8080 ./test-api-endpoints.sh"
echo ""
echo -e "  ${GREEN}# Test with authentication${NC}"
echo -e "  JWT_TOKEN='your-token' CSRF_TOKEN='your-csrf' ./test-api-endpoints.sh"
echo ""
