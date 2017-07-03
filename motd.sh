#!/bin/bash

clear

#
# Test whether bash supports arrays.
# (Support for arrays was only added recently.)
#
whotest[0]='test' || (echo 'Failure: arrays not supported in this version of bash. Must be at least version 4 to have associative arrays.' && exit 2)

# Settings
declare -A settings=(
    [0]=SYSTEM
    [1]=DATE
    [2]=UPTIME
    [3]=MEMORY
    [4]=LOADAVERAGE
    [5]=PROCESSES
    [6]=IP
    [7]=WEATHER
    [8]=CPUTEMP
)

# do not touch below unles you know what you're doing

# 1-red, 2-green, 3-, 4-blue
declare -A colour=(
    [header]=`tput setaf 6`
    [neutral]=`tput setaf 2`
    [info]=`tput setaf 4`
    [warning]=`tput setaf 1`
    [reset]=`tput sgr0`
)

function displayMessage {
    # $1 is the header
    # $2 is the value
    echo "${colour[header]}$1 ${colour[neutral]}$2"
}

function metrics {
    switch "$1" in
    'logoBig')
        displayMessage 'logo big'
        ;;
    'logoSmall')
        displayMessage 'logo small'
        ;;
    'SYSTEM')
        # uname=`uname -snrvm | cut -d ' ' -f '1 2 3 4 5'`
        uname=`uname -snrmo`
        displayMessage 'System.............:' ${uname}
        ;;
    'DATE')
        displayMessage 'Date...............:' "`date +"%A, %e %B %Y, %r"`"
        ;;
    'UPTIME')
        let upSeconds="$(/usr/bin/cut -d. -f1 /proc/uptime)"
        let secs=$((${upSeconds}%60))
        let mins=$((${upSeconds}/60%60))
        let hours=$((${upSeconds}/3600%24))
        let days=$((${upSeconds}/86400))
        displayMessage 'Uptime.............:' `printf "%d days, %02dh %02dm %02ds" "$days" "$hours" "$mins" "$secs"`
        ;;
    'MEMORY')
        displayMessage 'Memory.............:' "`cat /proc/meminfo | grep MemFree | awk {'print $2'}`kB (Free) / `cat /proc/meminfo | grep MemTotal | awk {'print $2'}`kB (Total)"
        ;;
    'LOADAVERAGE')
        read one five fifteen rest < /proc/loadavg
        displayMessage 'Load Average.......:' "${one}, ${five}, ${fifteen} (1, 5, 15 min)"
        ;;
    'PROCESSES')
        displayMessage 'Running Processes..:' "`ps ax | wc -l | tr -d " "`"
        ;;
    'IP')
        displayMessage 'IP Addresses.......:' "local: `/sbin/ifconfig eth0 | /bin/grep "inet addr" | /usr/bin/cut -d ":" -f 2 | /usr/bin/cut -d " " -f 1`, external: `wget -q -O - http://icanhazip.com/ | tail`"
        ;;
    'WEATHER')
        displayMessage 'Weather............:' "`curl -s "http://rss.accuweather.com/rss/liveweather_rss.asp?metric=1&locCode=EUR|UK|UK001|LONDON|" | sed -n '/Currently:/ s/.*: \(.*\): \([0-9]*\)\([CF]\).*/\2°\3, \1/p'`"
        ;;
    'CPUTEMP')
        displayMessage 'CPU temperature....:' "`vcgencmd measure_temp | cut -c "6-20"`"
        ;;
    *)
        # default, do nothing
        ;;
    esac
}


# ------------------------------------------
# displaying messages
# ------------------------------------------

for K in "${!settings[@]}";
do
    metrics "${settings[$K]}"
done | sort -rn -k3

echo "${colour[reset]}"

