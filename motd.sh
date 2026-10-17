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
    [header]=$(tput setaf 6)
    [neutral]=$(tput setaf 2)
    [info]=$(tput setaf 4)
    [warning]=$(tput setaf 1)
    [reset]=$(tput sgr0)
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
        while read line; do
            echo "${colour[header]}$1 ${colour[neutral]}$line";
        done <<< "$2"
    fi
}

function metrics {
    case "$1" in
    'LOGOSMALL')
        logo="${colour[neutral]}
         \\\ // ${colour[warning]}
         ◖ ● ◗
        ◖ ● ● ◗ ${colour[neutral]}Raspberry Pi${colour[warning]}
         ◖ ● ◗
           •
        "
        displayMessage '' "$logo"
        ;;
    'LOGOBIG')
        logo="${colour[neutral]}
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
        let upSeconds="$(/usr/bin/cut -d. -f1 /proc/uptime)"
        let sec=$((${upSeconds}%60))
        let min=$((${upSeconds}/60%60))
        let hour=$((${upSeconds}/3600%24))
        let day=$((${upSeconds}/86400))
        displayMessage 'Uptime.............:' "$(printf "%d days, %02dh %02dm %02ds" "$day" "$hour" "$min" "$sec")"
        ;;
    'MEMORY')
        displayMessage 'Memory.............:' "$(cat /proc/meminfo | grep MemAvailable | awk '{print $2}')kB (Available) / $(cat /proc/meminfo | grep MemTotal | awk '{print $2}')kB (Total)"
        ;;
    'DISKS')
        displayMessage 'Disk...............:' "$(df -hT -x tmpfs -x vfat | grep "^/dev/" | awk '{print $1" - "$5" (Free) / "$3" (Total)"}')"
        ;;
    'LOADAVERAGE')
        read one five fifteen rest < /proc/loadavg
        displayMessage 'Load average.......:' "${one}, ${five}, ${fifteen} (1, 5, 15 min)"
        ;;
    'PROCESSES')
        displayMessage 'Running processes..:' "$(ps -e --no-headers | wc -l)"
        ;;
    'IP')
        lip=$(hostname -I 2>/dev/null | awk '{print $1}')
        eip=$(wget -q -O - http://icanhazip.com/ | tail)
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
        updates=$(apt-get -s dist-upgrade | grep -Po '^\d+(?= upgraded)')
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
        unit="m"
        [[ "$degrees" == "F" ]] && unit="u"
        weather=$(curl -sf --max-time 2 "https://wttr.in/${weatherCode}?${unit}&format=%t,+%C")
        displayMessage 'Weather............:' "${weather:-Unavailable}"
        ;;
    'CPUTEMP')
        cpu=$(</sys/class/thermal/thermal_zone0/temp)
        cpu=$(echo "${cpu} 100 0.1" | awk '{printf "%.2f\n", $1/$2*$3}')
        if [ "$degrees" == "F" ]; then
            cpu=$(echo "1.8 $cpu 32" | awk '{printf "%.2f\n", $1*$2+$3}')
        fi
        displayMessage 'CPU temperature....:' "${cpu}°$degrees"
        ;;
    'GPUTEMP')
        gpu=$(/usr/bin/vcgencmd measure_temp | awk -F "[=']" '{print $2}')
        if [ "$degrees" == "F" ]; then
            gpu=$(echo "1.8 $gpu 32" | awk '{printf "%.2f\n", $1*$2+$3}')
        fi
        displayMessage 'GPU temperature....:' "${gpu}°$degrees"
        ;;
    'SSHLOGINS')
        displayMessage 'SSH logins.........:' "Currently $(who | wc -l) user(s) logged in."
        ;;
    'LASTLOGIN')
        displayMessage 'Last login.........:' "$(last -2 -a -F | awk 'NR==2 {print $1, "on", $3, $4, $5, $6, $7, "from", $NF}')"
        ;;
    'MESSAGES')
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


for K in "${!settings[@]}";
do
    metrics "${settings[$K]}"
done

echo "${colour[reset]}"
