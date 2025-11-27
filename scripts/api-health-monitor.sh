#!/bin/bash
set -euo pipefail

# Farben
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Konfiguration
API_URL="${API_URL:-https://felix-freund.com}"
CHECK_INTERVAL="${CHECK_INTERVAL:-30}"
ALERT_THRESHOLD="${ALERT_THRESHOLD:-3}"
LOG_FILE="${LOG_FILE:-/tmp/api-health.log}"
ENABLE_NOTIFICATIONS="${ENABLE_NOTIFICATIONS:-false}"

# Counters
CONSECUTIVE_FAILURES=0
TOTAL_CHECKS=0
TOTAL_FAILURES=0
START_TIME=$(date +%s)

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        NAS.AI API Health Monitor${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}API URL:${NC}          $API_URL"
echo -e "${CYAN}Interval:${NC}         ${CHECK_INTERVAL}s"
echo -e "${CYAN}Alert Threshold:${NC}  $ALERT_THRESHOLD consecutive failures"
echo -e "${CYAN}Log File:${NC}         $LOG_FILE"
echo ""

# Initialize log file
echo "=== API Health Monitor Started: $(date) ===" >> "$LOG_FILE"

# Health check function
check_health() {
    local endpoint=$1
    local expected_status=${2:-200}
    local timeout=${3:-5}

    response=$(curl -s -w '\n%{http_code}\n%{time_total}' \
        -m "$timeout" \
        "${API_URL}${endpoint}" 2>/dev/null || echo -e "\nERROR\n0")

    status_code=$(echo "$response" | tail -n 2 | head -n 1)
    response_time=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | head -n -2)

    if [ "$status_code" = "$expected_status" ]; then
        return 0
    else
        return 1
    fi
}

# Send alert (extensible for email, slack, etc.)
send_alert() {
    local message=$1
    local severity=${2:-WARNING}

    echo "[$(date)] [$severity] $message" >> "$LOG_FILE"

    if [ "$ENABLE_NOTIFICATIONS" = "true" ]; then
        # Hier könnten Email, Slack, Discord Notifications implementiert werden
        # Beispiel: curl -X POST -d "{\"text\":\"$message\"}" $SLACK_WEBHOOK_URL
        echo -e "${YELLOW}📧 Alert: $message${NC}"
    fi
}

# Monitoring loop
monitor() {
    echo -e "${CYAN}Starting continuous monitoring... (Press Ctrl+C to stop)${NC}"
    echo ""

    while true; do
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')

        # Check main health endpoint
        if check_health "/health" 200 5; then
            response_time=$(echo "$response" | tail -n 1)
            CONSECUTIVE_FAILURES=0

            # Calculate response time in ms
            response_ms=$(echo "$response_time * 1000" | bc)

            # Color code based on response time
            if (( $(echo "$response_time < 0.5" | bc -l) )); then
                color=$GREEN
                status="EXCELLENT"
            elif (( $(echo "$response_time < 1.0" | bc -l) )); then
                color=$CYAN
                status="GOOD"
            elif (( $(echo "$response_time < 2.0" | bc -l) )); then
                color=$YELLOW
                status="SLOW"
            else
                color=$RED
                status="VERY SLOW"
            fi

            printf "${color}✓${NC} [%s] Health OK - %s (%.0fms)\n" \
                "$timestamp" "$status" "$response_ms"

        else
            CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
            TOTAL_FAILURES=$((TOTAL_FAILURES + 1))

            echo -e "${RED}✗${NC} [${timestamp}] Health FAILED (${CONSECUTIVE_FAILURES}/${ALERT_THRESHOLD})"

            # Log failure
            echo "[$(date)] Health check failed - Status: $status_code" >> "$LOG_FILE"

            # Send alert if threshold reached
            if [ $CONSECUTIVE_FAILURES -ge $ALERT_THRESHOLD ]; then
                send_alert "API health check failed $CONSECUTIVE_FAILURES times consecutively!" "CRITICAL"
            fi
        fi

        # Show statistics every 10 checks
        if [ $((TOTAL_CHECKS % 10)) -eq 0 ]; then
            uptime=$(($(date +%s) - START_TIME))
            uptime_formatted=$(printf '%02d:%02d:%02d' $((uptime/3600)) $((uptime%3600/60)) $((uptime%60)))
            success_rate=$(echo "scale=2; (($TOTAL_CHECKS - $TOTAL_FAILURES) / $TOTAL_CHECKS) * 100" | bc)

            echo ""
            echo -e "${BLUE}📊 Statistics:${NC}"
            echo -e "   Uptime:        ${uptime_formatted}"
            echo -e "   Total Checks:  ${TOTAL_CHECKS}"
            echo -e "   Failures:      ${TOTAL_FAILURES}"
            echo -e "   Success Rate:  ${success_rate}%"
            echo ""
        fi

        sleep "$CHECK_INTERVAL"
    done
}

# Single check mode
single_check() {
    echo -e "${YELLOW}Running single health check...${NC}"
    echo ""

    declare -A endpoints=(
        ["/health"]="200"
        ["/api/v1/system/metrics?limit=1"]="200"
        ["/api/v1/system/alerts"]="200"
    )

    for endpoint in "${!endpoints[@]}"; do
        expected=${endpoints[$endpoint]}

        if check_health "$endpoint" "$expected" 10; then
            response_time=$(echo "$response" | tail -n 1)
            response_ms=$(echo "$response_time * 1000" | bc)
            echo -e "${GREEN}✓${NC} ${endpoint} - OK ($(printf '%.0f' $response_ms)ms)"
        else
            echo -e "${RED}✗${NC} ${endpoint} - FAILED (Status: $status_code)"
        fi
    done
}

# Usage
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

OPTIONS:
    -m, --monitor       Continuous monitoring mode (default)
    -s, --single        Single check mode
    -i, --interval N    Check interval in seconds (default: 30)
    -t, --threshold N   Alert after N consecutive failures (default: 3)
    -n, --notify        Enable notifications
    -h, --help          Show this help message

EXAMPLES:
    # Continuous monitoring with 10s interval
    $0 --monitor --interval 10

    # Single check
    $0 --single

    # Monitor with alerts enabled
    $0 --monitor --notify --threshold 2

    # Monitor with custom API URL
    API_URL=http://localhost:8080 $0 --monitor
EOF
}

# Parse arguments
MODE="monitor"

while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--monitor)
            MODE="monitor"
            shift
            ;;
        -s|--single)
            MODE="single"
            shift
            ;;
        -i|--interval)
            CHECK_INTERVAL="$2"
            shift 2
            ;;
        -t|--threshold)
            ALERT_THRESHOLD="$2"
            shift 2
            ;;
        -n|--notify)
            ENABLE_NOTIFICATIONS="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Execute
if [ "$MODE" = "monitor" ]; then
    monitor
else
    single_check
fi
