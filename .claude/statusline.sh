#!/bin/bash
set -f

input=$(cat)

if [ -z "$input" ]; then
    printf "Claude"
    exit 0
fi

# Colors
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
DIM='\033[2m'
RESET='\033[0m'

# ===== Extract data from JSON input =====
MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# Context bar color
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"
fi

FILLED=$((PCT / 10))
EMPTY=$((10 - FILLED))
BAR=$(printf "%${FILLED}s" | sed 's/ /█/g')$(printf "%${EMPTY}s" | sed 's/ /░/g')

MINS=$((DURATION_MS / 60000))
SECS=$(((DURATION_MS % 60000) / 1000))
COST_FMT=$(printf '$%.2f' "$COST")

BRANCH=""
git rev-parse --git-dir > /dev/null 2>&1 && BRANCH=" | 🌿 $(git branch --show-current 2>/dev/null)"

# ===== LINE 1: Model, dir, branch, duration =====
printf "${CYAN}[$MODEL]${RESET} 📁 ${DIR##*/}$BRANCH | ⏱️ ${MINS}m ${SECS}s\n"

# ===== 5-hour usage (cached) =====
FIVE_HOUR_TEXT=""
cache_file="/tmp/claude/statusline-usage-cache.json"
cache_max_age=60
mkdir -p /tmp/claude

needs_refresh=true
usage_data=""

if [ -f "$cache_file" ]; then
    cache_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)
    now=$(date +%s)
    cache_age=$(( now - cache_mtime ))
    if [ "$cache_age" -lt "$cache_max_age" ]; then
        needs_refresh=false
        usage_data=$(cat "$cache_file" 2>/dev/null)
    fi
fi

if $needs_refresh; then
    token=""
    # macOS Keychain
    if command -v security >/dev/null 2>&1; then
        blob=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
        if [ -n "$blob" ]; then
            token=$(echo "$blob" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
        fi
    fi
    # Linux credentials file fallback
    if [ -z "$token" ] || [ "$token" = "null" ]; then
        creds_file="${HOME}/.claude/.credentials.json"
        if [ -f "$creds_file" ]; then
            token=$(jq -r '.claudeAiOauth.accessToken // empty' "$creds_file" 2>/dev/null)
        fi
    fi

    if [ -n "$token" ] && [ "$token" != "null" ]; then
        response=$(curl -s --max-time 5 \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" \
            -H "anthropic-beta: oauth-2025-04-20" \
            -H "User-Agent: claude-code/2.1.34" \
            "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
        if [ -n "$response" ] && echo "$response" | jq . >/dev/null 2>&1; then
            usage_data="$response"
            echo "$response" > "$cache_file"
        fi
    fi
    # Fall back to stale cache
    if [ -z "$usage_data" ] && [ -f "$cache_file" ]; then
        usage_data=$(cat "$cache_file" 2>/dev/null)
    fi
fi

if [ -n "$usage_data" ] && echo "$usage_data" | jq -e . >/dev/null 2>&1; then
    five_pct=$(echo "$usage_data" | jq -r '.five_hour.utilization // 0' | awk '{printf "%.0f", $1}')
    five_reset_iso=$(echo "$usage_data" | jq -r '.five_hour.resets_at // empty')

    # Format reset time
    five_reset=""
    if [ -n "$five_reset_iso" ] && [ "$five_reset_iso" != "null" ]; then
        stripped="${five_reset_iso%%.*}"
        stripped="${stripped%%Z}"
        stripped="${stripped%%+*}"
        is_utc=false
        [[ "$five_reset_iso" == *"Z"* ]] || [[ "$five_reset_iso" == *"+00:00"* ]] && is_utc=true

        if $is_utc; then
            epoch=$(env TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
        else
            epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
        fi
        # GNU date fallback
        if [ -z "$epoch" ]; then
            epoch=$(date -d "$five_reset_iso" +%s 2>/dev/null)
        fi

        if [ -n "$epoch" ]; then
            five_reset=$(date -j -r "$epoch" +"%l:%M%p" 2>/dev/null | sed 's/^ //' | tr '[:upper:]' '[:lower:]')
            if [ -z "$five_reset" ]; then
                five_reset=$(date -d "@$epoch" +"%l:%M%P" 2>/dev/null | sed 's/^ //')
            fi
        fi
    fi

    # Color based on usage level
    if [ "$five_pct" -ge 90 ]; then FIVE_COLOR="$RED"
    elif [ "$five_pct" -ge 70 ]; then FIVE_COLOR="$YELLOW"
    else FIVE_COLOR="$GREEN"
    fi

    FIVE_HOUR_TEXT="${FIVE_COLOR}5h ${five_pct}%%${RESET}"
    if [ -n "$five_reset" ]; then
        FIVE_HOUR_TEXT+=" ${DIM}(${five_reset})${RESET}"
    fi
fi

# ===== LINE 2: Context bar, cost, 5h usage =====
printf "${BAR_COLOR}${BAR}${RESET} ${PCT}%% | ${YELLOW}${COST_FMT}${RESET}"
if [ -n "$FIVE_HOUR_TEXT" ]; then
    printf " | ${FIVE_HOUR_TEXT}"
fi
printf "\n"

exit 0
