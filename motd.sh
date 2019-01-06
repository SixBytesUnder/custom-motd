#!/bin/bash

clear

#
# Test whether bash supports arrays.
# (Support for arrays was only added recently.)
#
whotest[0]='test' || (echo 'Failure: arrays not supported in this version of bash. Must be at least version 4 to have associative arrays.' && exit 2)

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
    WEATHER
    CPUTEMP
    GPUTEMP
    SSHLOGINS
    MESSAGES
)

# Accuweather location codes: https://github.com/SixBytesUnder/custom-motd/blob/master/accuweather_location_codes.txt
weatherCode="EUR|UK|UK001|LONDON|"

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
    [header]=`tput setaf 6`
    [neutral]=`tput setaf 2`
    [info]=`tput setaf 4`
    [warning]=`tput setaf 1`
    [reset]=`tput sgr0`
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
        displayMessage 'System.............:' "`uname -snrmo`"
        ;;
    'DATE')
        displayMessage 'Date...............:' "`date +"%A, %e %B %Y, %r"`"
        ;;
    'UPTIME')
        let upSeconds="$(/usr/bin/cut -d. -f1 /proc/uptime)"
        let sec=$((${upSeconds}%60))
        let min=$((${upSeconds}/60%60))
        let hour=$((${upSeconds}/3600%24))
        let day=$((${upSeconds}/86400))
        displayMessage 'Uptime.............:' "`printf "%d days, %02dh %02dm %02ds" "$day" "$hour" "$min" "$sec"`"
        ;;
    'MEMORY')
        displayMessage 'Memory.............:' "`cat /proc/meminfo | grep MemFree | awk {'print $2'}`kB (Free) / `cat /proc/meminfo | grep MemTotal | awk {'print $2'}`kB (Total)"
        ;;
    'DISKS')
        disks="`df -hT -x tmpfs -x vfat | grep "^/dev/" | awk '{print $1" - "$5" (Free) / "$3" (Total)"}'`"
        displayMessage 'Disk...............:' "$disks"
        ;;
    'LOADAVERAGE')
        read one five fifteen rest < /proc/loadavg
        displayMessage 'Load Average.......:' "${one}, ${five}, ${fifteen} (1, 5, 15 min)"
        ;;
    'PROCESSES')
        displayMessage 'Running Processes..:' "`ps ax | wc -l | tr -d " "`"
        ;;
    'IP')
        lip=$(/sbin/ifconfig eth0 | /bin/grep "inet addr" | /usr/bin/cut -d ":" -f 2 | /usr/bin/cut -d " " -f 1)
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
        displayMessage 'IP Addresses.......:' "${localIP}${externalIP}"
        ;;
    'WEATHER')
        if [ "$degrees" == "F" ]; then
            metric=0
        else
            metric=1
        fi
        displayMessage 'Weather............:' "`curl -s "http://rss.accuweather.com/rss/liveweather_rss.asp?metric=$metric&locCode=$weatherCode" | sed -n '/Currently:/ s/.*: \(.*\): \([0-9]*\)\([CF]\).*/\2°\3, \1/p'`"
        ;;
    'CPUTEMP')
        cpu=$(</sys/class/thermal/thermal_zone0/temp)
        cpu=$(echo "${cpu} 100 0.1" | awk '{printf "%.2f\n", $1/$2*$3}')
        if [ "$degrees" == "F" ]; then
            cpu=$(echo "1.8 $cpu 32" | awk '{printf "%.2f\n", $1*$2+$3}')
        fi
        displayMessage 'CPU Temperature....:' "${cpu}°$degrees"
        ;;
    'GPUTEMP')
        gpu=$(/opt/vc/bin/vcgencmd measure_temp | awk -F "[=\']" '{print $2}')
        if [ "$degrees" == "F" ]; then
            gpu=$(echo "1.8 $gpu 32" | awk '{printf "%.2f\n", $1*$2+$3}')
        fi
        displayMessage 'GPU Temperature....:' "${gpu}°$degrees"
        ;;
    'SSHLOGINS')
        displayMessage 'SSH Logins.........:' "Currently `who -q | cut -c "9-11" | sed "1 d"` user(s) logged in."
        ;;
    'MESSAGES')
        displayMessage 'Last 3 messages....:' ""
        displayMessage '' "${colour[reset]}`tail -3 /var/log/messages`"
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
