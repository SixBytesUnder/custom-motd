#!/bin/bash

clear

#
# Test whether bash supports arrays.
# (Support for arrays was only added recently.)
#
whotest[0]='test' || (echo 'Failure: arrays not supported in this version of bash. Must be at least version 4 to have associative arrays.' && exit 2)

# Settings
declare -A settings=(
    [SYSTEM]=yes
    [UPTIME]=yes
    [MEMORY]=yes
    [LOADAVERAGE]=yes
    [PROCESSES]=yes
    [IP]=yes
    [WEATHER]=yes
    [PROCTEMP]=yes
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

if [[ ${settings[SYSTEM]} == 'yes'  ]]; then
    # * display kernel version
    # uname=`uname -snrvm | cut -d ' ' -f '1 2 3 4 5'`
    uname=`uname -snrmo`
    SYSTEM="${colour[header]}System.............: ${colour[neutral]}"
    SYSTEM+="${uname}"
fi

if [[ ${settings[UPTIME]} == 'yes'  ]]; then
    let upSeconds="$(/usr/bin/cut -d. -f1 /proc/uptime)"
    let secs=$((${upSeconds}%60))
    let mins=$((${upSeconds}/60%60))
    let hours=$((${upSeconds}/3600%24))
    let days=$((${upSeconds}/86400))
    UPTIME=`printf "${colour[header]}Uptime.............: ${colour[neutral]}%d days, %02dh %02dm %02ds" "$days" "$hours" "$mins" "$secs"`
fi

if [[ ${settings[MEMORY]} == 'yes'  ]]; then
    MEMORY="${colour[header]}Memory.............: ${colour[neutral]}"
    MEMORY+="`cat /proc/meminfo | grep MemFree | awk {'print $2'}`kB (Free) / `cat /proc/meminfo | grep MemTotal | awk {'print $2'}`kB (Total)";
fi

if [[ ${settings[LOADAVERAGE]} == 'yes'  ]]; then
    # get the load averages
    read one five fifteen rest < /proc/loadavg
    
    LOADAVERAGE="${colour[header]}Load Average.......: ${colour[neutral]}"
    LOADAVERAGE+="${one}, ${five}, ${fifteen} (1, 5, 15 min)"
fi

if [[ ${settings[PROCESSES]} == 'yes'  ]]; then
    PROCESSES="${colour[header]}Running Processes..: ${colour[neutral]}"
    PROCESSES+="`ps ax | wc -l | tr -d " "`"
fi

if [[ ${settings[IP]} == 'yes'  ]]; then
    IP="${colour[header]}IP Addresses.......: ${colour[neutral]}"
    IP+="local: `/sbin/ifconfig eth0 | /bin/grep "inet addr" | /usr/bin/cut -d ":" -f 2 | /usr/bin/cut -d " " -f 1`, external: `wget -q -O - http://icanhazip.com/ | tail`"
fi

if [[ ${settings[WEATHER]} == 'yes'  ]]; then
    WEATHER="${colour[header]}Weather............: ${colour[neutral]}"
    WEATHER+="`curl -s "http://rss.accuweather.com/rss/liveweather_rss.asp?metric=1&locCode=EUR|UK|UK001|LONDON|" | sed -n '/Currently:/ s/.*: \(.*\): \([0-9]*\)\([CF]\).*/\2°\3, \1/p'`"
fi

if [[ ${settings[PROCTEMP]} == 'yes'  ]]; then
    # * display temperature
    tempoutput=`vcgencmd measure_temp | cut -c "6-20"`
    PROCTEMP="${colour[header]}Proc temperature...: ${colour[neutral]}"
    PROCTEMP+="${tempoutput}"
fi


# ------------------------------------------
# displaying message
# ------------------------------------------

echo "${colour[neutral]}
`date +"%A, %e %B %Y, %r"`
${colour[reset]}"

for K in "${!settings[@]}";
do
    if [[ ${settings[$K]} == 'yes'  ]]; then
        tempVar=$K
        if [ "${!tempVar}" != "" ]; then
            echo ${!tempVar};
        fi
    fi
done | sort -rn -k3

echo "${colour[reset]}"

