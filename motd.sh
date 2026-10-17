#!/bin/bash

clear

#
# Test whether bash supports arrays.
# (Support for arrays was only added recently.)
#
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
    SYSTEM
    DATE
    UPTIME
    MEMORY
    DISKS
    LOADAVERAGE
    PROCESSES
    IP
    # Please be aware UPDATES command may take a few seconds to run
    # If you don't like waiting, just comment it out
    UPDATES
    WEATHER
    CPUTEMP
    GPUTEMP
    SSHLOGINS
    LASTLOGIN
    MESSAGES
)

# Location for wttr.in weather service (e.g. "London", "New+York", or leave empty for auto-detection)
weatherCode="London"

# Show temperatures in "C" for Celsius or "F" for Fahrenheit
degrees=C

# Colour reference
#    Colour    Value
#    black       0
#    red         1
#    green       2
#    yellow      3
#    blue        4
#    magenta     5
#    cyan        6
#    white       7
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
        mem=$(awk '
            /^MemTotal:/     { total = $2 / 1024 }
            /^MemAvailable:/ { avail = $2 / 1024 }
            END { printf "%.0f MiB (Available) / %.0f MiB (Total) [%.0f%% used]", avail, total, (total - avail) / total * 100 }
        ' /proc/meminfo)
        displayMessage 'Memory.............:' "$mem"
        ;;
    'DISKS')
        displayMessage 'Disk...............:' "$(df -hT -x tmpfs -x devtmpfs -x vfat | awk '/^\/dev\// {print $1" - "$5" (Free) / "$3" (Total)"}')"
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
        eip=$(curl -sf --max-time 2 https://icanhazip.com/)
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
        updates=$(LC_ALL=C apt-get -s dist-upgrade | grep -Po '^\d+(?= upgraded)')
        if [ -z "$updates" ]; then
            updates=0
        fi
        if [ "$updates" -eq 0 ]; then
            displayMessage 'Available updates..:' "System is up to date."
        elif [ "$updates" -eq 1 ]; then
            displayMessage 'Available updates..:' "1 package can be updated."
        else
            displayMessage 'Available updates..:' "$updates packages can be updated."
        fi
        ;;
    'WEATHER')
        local unit="m" weather
        [[ "$degrees" == "F" ]] && unit="u"
        weather=$(curl -sf --max-time 2 "https://wttr.in/${weatherCode}?${unit}&format=%t,+%C")
        displayMessage 'Weather............:' "${weather:-Unavailable}"
        ;;
    'CPUTEMP')
        if [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
            local cpu
            cpu=$(awk -v deg="$degrees" '{
                c = $1 / 1000
                printf "%.2f", (deg == "F" ? c * 1.8 + 32 : c)
            }' /sys/class/thermal/thermal_zone0/temp)
            displayMessage 'CPU temperature....:' "${cpu}°$degrees"
        fi
        ;;
    'GPUTEMP')
        if command -v vcgencmd >/dev/null 2>&1; then
            local gpu
            gpu=$(vcgencmd measure_temp 2>/dev/null | awk -F "[=']" -v deg="$degrees" '{
                printf "%.2f", (deg == "F" ? $2 * 1.8 + 32 : $2)
            }')
            [[ -n "$gpu" ]] && displayMessage 'GPU temperature....:' "${gpu}°$degrees"
        fi
        ;;
    'SSHLOGINS')
        displayMessage 'SSH logins.........:' "Currently $(who | wc -l) user(s) logged in."
        ;;
    'LASTLOGIN')
        displayMessage 'Last login.........:' "$(last -2 -a -F | awk 'NR==2 {print $1, "on", $3, $4, $5, $6, $7, "from", $NF}')"
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


for item in "${settings[@]}"; do
    metrics "$item"
done

echo "${colour[reset]}"
