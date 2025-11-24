#!/bin/bash

# Cloudflare Error 1000 Diagnostic Tool
# DNS resolution failure diagnosis

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}=== Cloudflare Error 1000 Diagnostics ===${NC}\n"
echo -e "${YELLOW}Error 1000 = DNS points to forbidden IP${NC}\n"

DOMAIN="${1:-api.felix-freund.com}"

echo -e "${BLUE}Checking domain:${NC} $DOMAIN\n"

# Check 1: DNS Resolution
echo -e "${YELLOW}[1/7]${NC} DNS Resolution Check..."
if DNS_RESULT=$(dig +short "$DOMAIN" 2>/dev/null); then
    if [ -n "$DNS_RESULT" ]; then
        echo -e "  ${GREEN}✓${NC} DNS resolves to:"
        echo "$DNS_RESULT" | while read -r ip; do
            echo -e "    ${BLUE}→${NC} $ip"

            # Check if IP is Cloudflare
            if [[ "$ip" =~ ^104\. ]] || [[ "$ip" =~ ^172\. ]] || [[ "$ip" =~ ^2606:4700 ]]; then
                echo -e "      ${GREEN}(Cloudflare IP)${NC}"
            elif [[ "$ip" =~ \.cfargotunnel\.com$ ]]; then
                echo -e "      ${GREEN}(Cloudflare Tunnel CNAME)${NC}"
            elif [[ "$ip" =~ ^192\.168\. ]] || [[ "$ip" =~ ^10\. ]]; then
                echo -e "      ${RED}⚠ PROBLEM: Private IP detected!${NC}"
                echo -e "      ${RED}This is the issue! Cloudflare cannot proxy to private IPs${NC}"
            elif [[ "$ip" =~ ^127\. ]]; then
                echo -e "      ${RED}⚠ PROBLEM: Localhost IP detected!${NC}"
            else
                echo -e "      ${YELLOW}(Public IP)${NC}"
            fi
        done
    else
        echo -e "  ${RED}✗${NC} DNS does not resolve"
        echo -e "  ${YELLOW}→ Check if DNS record exists in Cloudflare${NC}"
    fi
else
    echo -e "  ${RED}✗${NC} dig command failed"
fi

# Check 2: DNS Record Type
echo -e "\n${YELLOW}[2/7]${NC} DNS Record Type Check..."
RECORD_TYPE=$(dig +short "$DOMAIN" | tail -1)
if echo "$RECORD_TYPE" | grep -q "cfargotunnel.com"; then
    echo -e "  ${GREEN}✓${NC} CNAME pointing to Cloudflare Tunnel (correct!)"
elif echo "$RECORD_TYPE" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo -e "  ${YELLOW}⚠${NC} A record detected"
    if [[ "$RECORD_TYPE" =~ ^192\.168\. ]] || [[ "$RECORD_TYPE" =~ ^10\. ]] || [[ "$RECORD_TYPE" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]]; then
        echo -e "  ${RED}✗ PROBLEM: A record points to PRIVATE IP!${NC}"
        echo -e "  ${RED}Solution: Change to CNAME pointing to Tunnel${NC}"
    fi
else
    echo -e "  ${BLUE}ℹ${NC} Record type: $RECORD_TYPE"
fi

# Check 3: Cloudflare Proxy Status
echo -e "\n${YELLOW}[3/7]${NC} Checking Cloudflare Proxy Status..."
if dig +short "$DOMAIN" | grep -qE '^(104\.|172\.|2606:4700)'; then
    echo -e "  ${GREEN}✓${NC} Domain is proxied through Cloudflare (Orange Cloud)"
else
    echo -e "  ${YELLOW}⚠${NC} Domain might not be proxied (DNS only mode)"
    echo -e "  ${YELLOW}→ Enable Orange Cloud in Cloudflare DNS settings${NC}"
fi

# Check 4: Cloudflare Tunnel Status
echo -e "\n${YELLOW}[4/7]${NC} Cloudflare Tunnel Service Status..."
if systemctl is-active --quiet cloudflared 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Cloudflare Tunnel is running"

    # Show tunnel info
    TUNNEL_STATUS=$(systemctl status cloudflared 2>/dev/null | grep -A 2 "Active:" | head -3)
    echo "$TUNNEL_STATUS" | while IFS= read -r line; do
        echo -e "    ${BLUE}→${NC} $line"
    done
else
    echo -e "  ${RED}✗${NC} Cloudflare Tunnel is NOT running"
    echo -e "  ${YELLOW}→ Start with: sudo systemctl start cloudflared${NC}"
fi

# Check 5: Local API Status
echo -e "\n${YELLOW}[5/7]${NC} Local API Status (localhost:8080)..."
if timeout 2 curl -s -o /dev/null http://localhost:8080/health 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} API is running on localhost:8080"
else
    echo -e "  ${RED}✗${NC} API is NOT responding on localhost:8080"
    echo -e "  ${YELLOW}→ Start API: cd /home/freun/Agent/infrastructure/api && ./bin/api${NC}"
fi

# Check 6: Cloudflare Tunnel Config
echo -e "\n${YELLOW}[6/7]${NC} Cloudflare Tunnel Configuration..."
if [ -f ~/.cloudflared/config.yml ]; then
    echo -e "  ${GREEN}✓${NC} Config file exists: ~/.cloudflared/config.yml"

    # Check hostname in config
    if grep -q "hostname: $DOMAIN" ~/.cloudflared/config.yml; then
        echo -e "  ${GREEN}✓${NC} Hostname configured correctly"
    else
        echo -e "  ${YELLOW}⚠${NC} Hostname might be different"
        echo -e "  ${BLUE}Current config:${NC}"
        grep "hostname:" ~/.cloudflared/config.yml | while read -r line; do
            echo -e "    ${BLUE}→${NC} $line"
        done
    fi
else
    echo -e "  ${RED}✗${NC} Config file not found"
fi

# Check 7: Tunnel Logs
echo -e "\n${YELLOW}[7/7]${NC} Recent Tunnel Logs (last 5 lines)..."
if journalctl -u cloudflared -n 5 --no-pager 2>/dev/null | grep -q .; then
    journalctl -u cloudflared -n 5 --no-pager 2>/dev/null | while IFS= read -r line; do
        echo -e "  ${BLUE}→${NC} $line"
    done
else
    echo -e "  ${YELLOW}ℹ${NC} No recent logs available"
fi

# Summary and Solutions
echo -e "\n${RED}=== Common Causes of Error 1000 ===${NC}\n"

echo -e "${YELLOW}1. DNS A Record points to Private/Local IP${NC}"
echo -e "   Problem: A record → 192.168.x.x or 127.0.0.1"
echo -e "   ${GREEN}Solution:${NC}"
echo -e "   - Go to Cloudflare Dashboard → DNS"
echo -e "   - Delete A record"
echo -e "   - Add CNAME record: api → <TUNNEL-ID>.cfargotunnel.com"
echo -e "   - Enable Proxy (Orange Cloud)"

echo -e "\n${YELLOW}2. Cloudflare Tunnel Not Running${NC}"
echo -e "   ${GREEN}Solution:${NC}"
echo -e "   sudo systemctl start cloudflared"
echo -e "   sudo systemctl enable cloudflared"

echo -e "\n${YELLOW}3. DNS Not Pointed to Tunnel${NC}"
echo -e "   ${GREEN}Solution:${NC}"
echo -e "   cloudflared tunnel route dns <TUNNEL-NAME> $DOMAIN"

echo -e "\n${YELLOW}4. API Not Running${NC}"
echo -e "   ${GREEN}Solution:${NC}"
echo -e "   cd /home/freun/Agent/infrastructure/api"
echo -e "   ./bin/api"

echo -e "\n${YELLOW}5. Wrong Tunnel Configuration${NC}"
echo -e "   ${GREEN}Solution:${NC}"
echo -e "   Edit ~/.cloudflared/config.yml"
echo -e "   Ensure hostname matches: $DOMAIN"

echo -e "\n${BLUE}=== Quick Fix Steps ===${NC}\n"
echo -e "1. Check Cloudflare DNS settings"
echo -e "2. Ensure DNS record is CNAME to tunnel (not A record to private IP)"
echo -e "3. Enable Orange Cloud (Proxy)"
echo -e "4. Start Cloudflare Tunnel: sudo systemctl start cloudflared"
echo -e "5. Start API: ./bin/api"
echo -e "6. Wait 1-2 minutes for DNS propagation"
echo -e "7. Test: curl https://$DOMAIN/health"

echo -e "\n${BLUE}For detailed tunnel info:${NC}"
echo -e "  cloudflared tunnel list"
echo -e "  cloudflared tunnel info <TUNNEL-NAME>"
echo -e "  journalctl -u cloudflared -f"

echo ""
