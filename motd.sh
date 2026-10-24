#!/bin/bash

# Ensure Bash 4.0+ is used (required for associative arrays via 'declare -A')
if (( BASH_VERSINFO[0] < 4 )); then
  echo 'Failure: arrays not supported in your version of bash. Must be at least version 4 to have associative arrays.' >&2
  exit 2
fi

#############################################################################
#                                SETTINGS                                   #
# Comment with a # messages you don't want displayed                        #
# Change order of items in array to change order of displayed messages      #
#############################################################################

settings=(
    LOGOSMALL
#    LOGOBIG
    MODEL
    SYSTEM
    DATE
    UPTIME
    MEMORY
    DISKS
    LOADAVERAGE
    PROCESSES
    IP
    # Note: External IP, UPDATES, and WEATHER are cached for $cacheTTL seconds to keep logins fast.
    UPDATES
    WEATHER
    CPUTEMP
    GPUTEMP
    THROTTLED
    SERVICES
    DOCKER
    SSHLOGINS
    LASTLOGIN
    MESSAGES
)

# Clear terminal screen before displaying MOTD:
#   "interactive" - clear only in an interactive terminal (safe for update-motd.d/scp)
#   "always"      - always run clear
#   "never"       - never clear the screen (keeps pre-login SSH/PAM messages visible)
clearScreen="interactive"

# Location for wttr.in weather service (e.g. "London", "New+York", or leave empty for auto-detection)
weatherCode="London"

# Show temperatures in "C" for Celsius or "F" for Fahrenheit
degrees=C

# Cache TTL in seconds for slow checks (IP, UPDATES, WEATHER). Set to 0 to disable.
cacheTTL=3600

# Warning thresholds for highlighting metrics in red
tempWarnC=70
memWarnPct=85
diskWarnPct=85

# ANSI colour reference
#    Colour    Code
#    black     $'\e[30m'
#    red       $'\e[31m'
#    green     $'\e[32m'
#    yellow    $'\e[33m'
#    blue      $'\e[34m'
#    magenta   $'\e[35m'
#    cyan      $'\e[36m'
#    white     $'\e[37m'
#    reset     $'\e[0m'
declare -A colour=(
    [header]=$'\e[36m'
    [neutral]=$'\e[32m'
    [info]=$'\e[34m'
    [warning]=$'\e[31m'
    [reset]=$'\e[0m'
)


#############################################################################
#                                                                           #
# DO NOT TOUCH ANYTHING BELOW THIS POINT, UNLESS YOU KNOW WHAT YOU'RE DOING #
#                                                                           #
#############################################################################

# Expects two arguments:
# $1 is the header
# $2 is the message
function displayMessage {
    if [ -z "$1" ]; then
        echo "${colour[neutral]}$2"
    else
        local line
        while IFS= read -r line; do
            echo "${colour[header]}$1 ${colour[neutral]}$line";
        done <<< "$2"
    fi
}

# Caches output of slow commands in /tmp for $cacheTTL seconds
# Usage: getCached <cache_key> <command...>
function getCached {
    local key="$1"
    shift
    local cacheFile="/tmp/motd_cache_${UID}_${key}"
    if (( cacheTTL > 0 )) && [[ -f "$cacheFile" ]]; then
        local now mtime
        now=$(date +%s)
        mtime=$(stat -c %Y "$cacheFile" 2>/dev/null || echo 0)
        if (( now - mtime < cacheTTL )); then
            cat "$cacheFile"
            return 0
        fi
    fi
    local output
    output=$("$@")
    if [[ -n "$output" ]] && (( cacheTTL > 0 )); then
        (umask 077 && printf '%s\n' "$output" > "$cacheFile" 2>/dev/null)
    fi
    printf '%s\n' "$output"
}

# Evaluates and displays a single MOTD module
# $1 is the module name from the settings array
function metrics {
    case "$1" in
    'LOGOSMALL')
        local logo="${colour[neutral]}
         \\\ // ${colour[warning]}
         ◖ ● ◗
        ◖ ● ● ◗ ${colour[neutral]}Raspberry Pi${colour[warning]}
         ◖ ● ◗
           •
        "
        displayMessage '' "$logo"
        ;;
    'LOGOBIG')
        local logo="${colour[neutral]}
          .~~.   .~~.
         '. \ ' ' / .'${colour[warning]}
          .~ .~~~..~.                      _                          _ 
         : .~.'~'.~. :     ___ ___ ___ ___| |_ ___ ___ ___ _ _    ___|_|
        ~ (   ) (   ) ~   |  _| .'|_ -| . | . | -_|  _|  _| | |  | . | |
       ( : '~'.~.'~' : )  |_| |__,|___|  _|___|___|_| |_| |_  |  |  _|_|
        ~ .~ (   ) ~. ~               |_|                 |___|  |_|    
         (  : '~' :  )
          '~ .~~~. ~'
              '~'"
        displayMessage '' "$logo"
        ;;
    'MODEL')
        if [[ -r /proc/device-tree/model ]]; then
            local model
            model=$(tr -d '\0' < /proc/device-tree/model)
            displayMessage 'Model..............:' "$model"
        fi
        ;;
    'SYSTEM')
        displayMessage 'System.............:' "$(uname -snrmo)"
        ;;
    'DATE')
        displayMessage 'Date...............:' "$(date +"%A, %e %B %Y, %r")"
        ;;
    'UPTIME')
        local upSeconds rest sec min hour day
        IFS=. read -r upSeconds rest < /proc/uptime
        sec=$(( upSeconds % 60 ))
        min=$(( upSeconds / 60 % 60 ))
        hour=$(( upSeconds / 3600 % 24 ))
        day=$(( upSeconds / 86400 ))
        displayMessage 'Uptime.............:' "$(printf "%d days, %02dh %02dm %02ds" "$day" "$hour" "$min" "$sec")"
        ;;
    'MEMORY')
        local mem
        mem=$(awk -v warn="$memWarnPct" -v cWarn="${colour[warning]}" -v cNorm="${colour[neutral]}" '
            /^MemTotal:/     { total = $2 / 1024 }
            /^MemAvailable:/ { avail = $2 / 1024 }
            END {
                usedPct = (total - avail) / total * 100
                col = (usedPct >= warn) ? cWarn : cNorm
                printf "%s%.0f MiB (Available) / %.0f MiB (Total) [%.0f%% used]", col, avail, total, usedPct
            }
        ' /proc/meminfo)
        displayMessage 'Memory.............:' "$mem"
        ;;
    'DISKS')
        local disks
        disks=$(df -hT -x tmpfs -x devtmpfs -x vfat | awk -v warn="$diskWarnPct" -v cWarn="${colour[warning]}" -v cNorm="${colour[neutral]}" '
            /^\/dev\// {
                usedPct = $6
                sub(/%/, "", usedPct)
                col = (usedPct + 0 >= warn) ? cWarn : cNorm
                print col $1 " - " $5 " (Free) / " $3 " (Total) [" $6 " used]"
            }
        ')
        displayMessage 'Disk...............:' "$disks"
        ;;
    'LOADAVERAGE')
        local one five fifteen rest
        read one five fifteen rest < /proc/loadavg
        displayMessage 'Load average.......:' "${one}, ${five}, ${fifteen} (1, 5, 15 min)"
        ;;
    'PROCESSES')
        displayMessage 'Running processes..:' "$(ps -e --no-headers | wc -l)"
        ;;
    'IP')
        local lip eip localIP externalIP
        lip=$(hostname -I 2>/dev/null | awk '{print $1}')
        eip=$(getCached "ext_ip" curl -sf --max-time 2 https://icanhazip.com/)
        if [ "$lip" ]; then
            localIP="local: ${lip}"
        else
            localIP=""
        fi
        if [ "$eip" ]; then
            if [ "$lip" ]; then
                externalIP=", external: ${eip}"
            else
                externalIP="external: ${eip}"
            fi
        else
            externalIP=""
        fi
        displayMessage 'IP addresses.......:' "${localIP}${externalIP}"
        ;;
    'UPDATES')
        local updates
        updates=$(getCached "updates" bash -c "LC_ALL=C apt-get -s dist-upgrade 2>/dev/null | grep -Po '^\d+(?= upgraded)' || echo 0")
        if [ -z "$updates" ]; then
            updates=0
        fi
        if [ "$updates" -eq 0 ]; then
            displayMessage 'Available updates..:' "System is up to date."
        elif [ "$updates" -eq 1 ]; then
            displayMessage 'Available updates..:' "${colour[warning]}1 package can be updated."
        else
            displayMessage 'Available updates..:' "${colour[warning]}$updates packages can be updated."
        fi
        ;;
    'WEATHER')
        local unit="m" weather safeLoc
        [[ "$degrees" == "F" ]] && unit="u"
        safeLoc="${weatherCode//[^a-zA-Z0-9_-]/_}"
        weather=$(getCached "weather_${safeLoc}_${unit}" curl -sf --max-time 2 "https://wttr.in/${weatherCode}?${unit}&format=%t,+%C")
        displayMessage 'Weather............:' "${weather:-Unavailable}"
        ;;
    'CPUTEMP')
        if [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
            local cpu
            cpu=$(awk -v deg="$degrees" -v warn="$tempWarnC" -v cWarn="${colour[warning]}" -v cNorm="${colour[neutral]}" '{
                c = $1 / 1000
                col = (c >= warn) ? cWarn : cNorm
                printf "%s%.2f", col, (deg == "F" ? c * 1.8 + 32 : c)
            }' /sys/class/thermal/thermal_zone0/temp)
            displayMessage 'CPU temperature....:' "${cpu}°$degrees"
        fi
        ;;
    'GPUTEMP')
        if command -v vcgencmd >/dev/null 2>&1; then
            local gpu
            gpu=$(vcgencmd measure_temp 2>/dev/null | awk -F "[=']" -v deg="$degrees" -v warn="$tempWarnC" -v cWarn="${colour[warning]}" -v cNorm="${colour[neutral]}" '{
                c = $2 + 0
                col = (c >= warn) ? cWarn : cNorm
                printf "%s%.2f", col, (deg == "F" ? c * 1.8 + 32 : c)
            }')
            [[ -n "$gpu" ]] && displayMessage 'GPU temperature....:' "${gpu}°$degrees"
        fi
        ;;
    'THROTTLED')
        if command -v vcgencmd >/dev/null 2>&1; then
            local throttledHex throttledVal flags=()
            throttledHex=$(vcgencmd get_throttled 2>/dev/null | cut -d= -f2)
            if [[ -n "$throttledHex" ]]; then
                throttledVal=$(( throttledHex ))
                if (( throttledVal == 0 )); then
                    displayMessage 'Throttling.........:' "OK (${throttledHex})"
                else
                    (( throttledVal & 0x1 ))     && flags+=("under-voltage active")
                    (( throttledVal & 0x2 ))     && flags+=("freq capped")
                    (( throttledVal & 0x4 ))     && flags+=("throttled")
                    (( throttledVal & 0x8 ))     && flags+=("soft temp limit")
                    (( throttledVal & 0x10000 )) && flags+=("past under-voltage")
                    (( throttledVal & 0x20000 )) && flags+=("past freq cap")
                    (( throttledVal & 0x40000 )) && flags+=("past throttling")
                    (( throttledVal & 0x80000 )) && flags+=("past temp limit")
                    local IFS=", "
                    displayMessage 'Throttling.........:' "${colour[warning]}WARNING (${throttledHex}): ${flags[*]}"
                fi
            fi
        fi
        ;;
    'SERVICES')
        if command -v systemctl >/dev/null 2>&1; then
            local failedUnits failedCount
            failedUnits=$(systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}')
            if [[ -z "$failedUnits" ]]; then
                displayMessage 'Systemd services...:' "All services healthy."
            else
                failedCount=$(printf '%s\n' "$failedUnits" | wc -l)
                displayMessage 'Systemd services...:' "${colour[warning]}${failedCount} failed: $(echo "$failedUnits" | tr '\n' ' ')"
            fi
        fi
        ;;
    'DOCKER')
        if command -v docker >/dev/null 2>&1; then
            local running total
            running=$(docker ps -q 2>/dev/null | wc -l)
            total=$(docker ps -aq 2>/dev/null | wc -l)
            if (( total > 0 )); then
                displayMessage 'Docker containers..:' "${running} running / ${total} total"
            fi
        fi
        ;;
    'SSHLOGINS')
        displayMessage 'SSH logins.........:' "Currently $(who | wc -l) user(s) logged in."
        ;;
    'LASTLOGIN')
      local lastLogin=""
      if command -v last >/dev/null 2>&1; then
        lastLogin=$(last -2 -a -F 2>/dev/null | awk 'NR==2 {print $1, "on", $3, $4, $5, $6, $7, "from", $NF}')
      elif command -v wtmpdb >/dev/null 2>&1; then
        lastLogin=$(wtmpdb last -2 -a -F 2>/dev/null | awk 'NR==2 {print $1, "on", $3, $4, $5, $6, $7, "from", $NF}')
      elif command -v journalctl >/dev/null 2>&1; then
        local sshLogs
        sshLogs=$(journalctl _COMM=sshd --no-pager -q -n 20 2>/dev/null | grep -E 'Accepted (publickey|password)')
        if [[ -n "$sshLogs" ]]; then
          local lineCount
          lineCount=$(printf '%s\n' "$sshLogs" | grep -c .)
          local targetLine
          if (( lineCount > 1 )); then
            targetLine=$(printf '%s\n' "$sshLogs" | tail -n 2 | head -n 1)
          else
            targetLine=$(printf '%s\n' "$sshLogs" | tail -n 1)
          fi
          lastLogin=$(printf '%s\n' "$targetLine" | awk '{
            u = ""; ip = ""
            for (i = 1; i <= NF; i++) {
              if ($i == "for") u = $(i+1)
              if ($i == "from") ip = $(i+1)
            }
            if (u != "") print u, "on", $1, $2, $3, "from", ip
          }')
        else
          local logindLogs
          logindLogs=$(journalctl -u systemd-logind --no-pager -q -n 20 2>/dev/null | grep 'New session')
          if [[ -n "$logindLogs" ]]; then
            local lineCount
            lineCount=$(printf '%s\n' "$logindLogs" | grep -c .)
            local targetLine
            if (( lineCount > 1 )); then
              targetLine=$(printf '%s\n' "$logindLogs" | tail -n 2 | head -n 1)
            else
              targetLine=$(printf '%s\n' "$logindLogs" | tail -n 1)
            fi
            lastLogin=$(printf '%s\n' "$targetLine" | awk '{
              u = ""
              for (i = 1; i <= NF; i++) {
                if ($i == "user") u = $(i+1)
              }
              sub(/\.$/, "", u)
              if (u != "") print u, "on", $1, $2, $3, "from local"
            }')
          fi
        fi
      elif command -v lastlog2 >/dev/null 2>&1; then
        lastLogin=$(lastlog2 -u "$USER" 2>/dev/null | awk 'NR==2 && $2 !~ /\*\*Never/ {print $1, "on", $2, "from", $3, "at", $4, $5, $6, $7}')
      elif command -v lastlog >/dev/null 2>&1; then
        lastLogin=$(lastlog -u "$USER" 2>/dev/null | awk 'NR==2 && $2 !~ /\*\*Never/ {print $1, "on", $2, "from", $3, "at", $4, $5, $6, $7}')
      fi
      displayMessage 'Last login.........:' "${lastLogin:-None}"
      ;;
    'MESSAGES')
        local logs
        if [[ -r /var/log/messages ]]; then
            logs=$(tail -n 3 /var/log/messages)
        elif command -v journalctl >/dev/null 2>&1; then
            logs=$(journalctl -n 3 --no-pager -q 2>/dev/null)
        fi
        displayMessage 'Last 3 messages....:' ""
        displayMessage '' "${colour[reset]}${logs}"
        ;;
    *)
        # default, do nothing
        ;;
    esac
}


case "$clearScreen" in
    always|true|1)
        clear
        ;;
    interactive|auto)
        [[ -t 1 && -n "$TERM" ]] && clear
        ;;
    never|false|0|*)
        # Do not clear screen
        ;;
esac

for item in "${settings[@]}"; do
    metrics "$item"
done

echo "${colour[reset]}"
