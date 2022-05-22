#!/usr/bin/env bash

# Setup terminal colors and functions
term_colors() {
    # Styles
    RESET=$(printf '\033[0m')
    BOLD=$(printf '\033[1m')
    ULINE=$(printf '\033[4m')
    BLINK=$(printf '\033[5m')
    REVERSE=$(printf '\033[7m')
    TRIM=$(printf '\33[K')
    # Symbols
    TICK=$(printf '\xe2\x9c\x94')
    CROSS=$(printf '\xe2\x9c\x98')
    # Foreground Colors
    BLACK=$(printf '\033[30m')
    RED=$(printf '\033[31m')
    GREEN=$(printf '\033[32m')
    YELLOW=$(printf '\033[33m')
    BLUE=$(printf '\033[34m')
    MAGENTA=$(printf '\033[35m')
    CYAN=$(printf '\033[36m')
    WHITE=$(printf '\033[37m')
    # Background Colors
    BG_BLACK=$(printf '\033[40m')
    BG_RED=$(printf '\033[41m')
    BG_GREEN=$(printf '\033[42m')
    BG_YELLOW=$(printf '\033[43m')
    BG_BLUE=$(printf '\033[44m')
    BG_MAGENTA=$(printf '\033[45m')
    BG_CYAN=$(printf '\033[46m')   
    BG_WHITE=$(printf '\033[47m')
    clear_screen() {
        printf '\33[2J'
        printf '\033c'
    }
    show_cursor() {
        printf '\33[?25h'
    }
    hide_cursor() {
        printf '\33[?25l'
    }
    trap show_cursor EXIT
    move_cursor() {
        local direction=${1}
        local amount=${2}
        case "${direction}" in
            up) printf "\033[${amount}A"
            ;;
            down) printf "\033[${amount}B"
            ;;
            forward) printf "\033[${amount}C"
            ;;
            back) printf "\033[${amount}D"
            ;;
        esac
    }
    next_line() {
        move_cursor down 1
    }
    prev_line() {
        move_cursor up 1
    }
    TAB=$(move_cursor forward 4)
}


# output_result function
# Usage 1: output_result "result text" "result title"
# Usage 2: output_result "result text"
# No dots will be printed in Usage 2, can used for additional lines etc.
function output_result() {
    max_title_len=17
    max_dot_len="18"
    max_result_len="60"
    result=${1:0:${max_result_len}}
    title=${2:0:${max_title_len}}
    print_line(){
        if [[ -z ${1} ]]; then
            char=" "
        else
            char="${1}"
        fi
	    for ((i=1; i<=${max_dot_len}; i++)); do echo -ne "${char}"; done
        echo -n ": ${result}"
    }
    if [[ ! -z ${result} ]]; then
        if [[ ! -z ${title} ]]; then
            print_line "."
            echo -e "\r${title}"
        else
            print_line
        fi
    fi
    if [[ -z ${result} ]]; then
        if [[ ! -z ${title} ]]; then
            print_line "."
            echo -e "\r${title}"
        else
            print_line
        fi
    fi
}


function get_ip_info(){
    if [[ $(command -v wget) ]] >/dev/null 2>&1; then
        json_data=$(timeout 3s wget -qO- ipinfo.io)

        # Sub-function to get JSON value
        function get_json_value() {
            json_key=${1}
            result=$(echo "${json_data}" \
                    | awk -F=":" -v RS="," '$1~/"'${json_key}'"/ {print}' \
                    | sed 's/\"//g; s/'${json_key}'://; s/[\{\}]//' \
                    | awk '{$1=$1};1' \
                    | awk NF)

            if [ "${result}" = "" ]; then
                echo ""
            else
                echo "${result}"
            fi
        }

        # Assign variables based on JSON value returned.
        ip=$(get_json_value ip)
        hostname=$(get_json_value hostname)
        city=$(get_json_value city)
        region=$(get_json_value region)
        country=$(get_json_value country)
        org=$(get_json_value org)

        # Display variables use xargs to strip variable whitespace
        if [[ ! -z "${ip}" ]]; then
            output_result "${GREEN}${ip}${RESET}" "Ext. IP Address"
        fi
        if [[ ! -z "${city}" ]]; then
            output_result "${city} ${region} ${country}" "Ext. IP Location"
        fi
        if [[ ! -z "${org}" ]]; then
            output_result "${org}" "Ext. IP ORG/ISP"
        fi
    fi
}


function percentage_color() {
    input_percent="${1//%}"
    if [ "${input_percent}" -lt "50" ]; then
        echo -ne "${GREEN}${input_percent}%${RESET}"
    elif [ "${input_percent}" -le "85" ]; then
        echo -ne "${YELLOW}${input_percent}%${RESET}"
    else
        echo -ne "${RED}${input_percent}%${RESET}"
    fi
}


function show_mem() {
    if [[ $(command -v free -t) ]] >/dev/null 2>&1; then
        mem_perc=$(free -t | awk 'FNR == 2 { printf "%d", $3/$2*100 }')
        result=$(percentage_color ${mem_perc})
        output_result "${result}" "Memory Usage"
    fi
}


function show_storage() {
    if [[ $(command -v lsblk) ]] >/dev/null 2>&1; then
        raw_storage="$(lsblk -f -r -n | grep % | grep -v "loop" | sort | awk 'FNR { printf "%s Used: %s Free: %sB\n\t\t    ", $1,$(NF-1),$(NF-2); }')"
        IFS=', ' read -r -a array <<< $(lsblk -f -r -n | tr ' ' '\n' | grep '%$' | xargs)
        for element in "${array[@]}"
            do
                colored_val=$(percentage_color ${element})
                raw_storage=${raw_storage/${element}/$colored_val}
            done
        echo "${raw_storage}" | while read -r line; 
            do 
                if [[ ! -z "${line}" ]]; then
                    dev_name=$(printf ${line} | awk '{print $1}')
                    output_result "$(echo ${line} | awk '{ print $2" "$3" "$4" "$5 }')" "Storage ${dev_name}"
                fi
            done
    fi
}


function show_interfaces() {
    if [[ $(command -v /sbin/ifconfig) ]] >/dev/null 2>&1; then
        local iface_active=()
        for iface in $(/sbin/ifconfig | expand | cut -c1-8 | sort | uniq -u | awk -F: '{print $1}')
            do
                iface_v4=""
                if [[ $(/sbin/ifconfig $iface | grep "status: active") ]] || \
                    [[ $(/sbin/ifconfig $iface | grep "inet.*broadcast") ]] >/dev/null 2>&1; then
                    iface_v4=$(/sbin/ifconfig $iface | grep -w inet | awk '{print $2}' | awk 'NR==1')
                    if [[ ! -z ${iface_v4} ]]; then
                        iface_active+=("$(printf "${iface} ${CYAN}${iface_v4}${RESET}")")
                    fi
                fi
            done
        for i in "${iface_active[@]}"; 
            do 
                output_result "$(echo ${i} | awk '{print $2}')" "Network $(echo ${i} | awk '{print $1}')"
            done
    fi
}


function show_processes() {
    if [[ $(ps ax | wc -l | tr -d " ") -gt "0" ]] >/dev/null 2>&1; then
        result=$(ps ax | wc -l | tr -d " ")
        output_result "${result}" "Processes"
    fi    
}


function show_cpu() {
    if [[ $(cat /proc/cpuinfo) ]] >/dev/null 2>&1; then
        check_cpu=$(cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d':' -f2 | xargs) || true
        check_model=$(cat /proc/cpuinfo | grep Model | head -1 | cut -d':' -f2 | xargs) || true
        if [[ -z "${check_cpu}" ]]; then
            result="${check_model}"
        else
            result="${check_cpu}"
        fi
        if [[ ! -z "${result}" ]]; then
            output_result "${result}" "System Proc"
        fi
    elif [[ $(sysctl -a) ]] >/dev/null 2>&1; then
        result=$(sysctl -a | egrep -i 'hw.model' | sed 's/[^ ]* //')
        if [[ ! -z "${result}" ]]; then
            output_result "${result}" "System Proc"
        fi
    fi
}


function show_date() {
    result=$(date +"%a, %e %B %Y, %r")
    output_result "${result}" "System Date/Time"
}


function show_uptime() {
    if [[ $(uptime -p) ]] >/dev/null 2>&1; then
        result=$(uptime -p | sed 's/[^ ]* //')
        output_result "${result}" "System Uptime"
    elif [[ $(ps -o etime= -p 1) ]] >/dev/null 2>&1; then
        # Ref uptime source: https://github.com/dylanaraps/neofetch
        t=$(ps -o etime= -p 1)

        [[ $t == *-*   ]] && { d=${t%%-*}; t=${t#*-}; }
        [[ $t == *:*:* ]] && { h=${t%%:*}; t=${t#*:}; }

        h=${h#0}
        t=${t#0}

        s=$((${d:-0}*86400 + ${h:-0}*3600 + ${t%%:*}*60 + ${t#*:}))
        d="$((s / 60 / 60 / 24)) days"
        h="$((s / 60 / 60 % 24)) hours"
        m="$((s / 60 % 60)) minutes"

        # Remove plural if < 2.
        ((${d/ *} == 1)) && d=${d/s}
        ((${h/ *} == 1)) && h=${h/s}
        ((${m/ *} == 1)) && m=${m/s}

        # Hide empty fields.
        ((${d/ *} == 0)) && unset d
        ((${h/ *} == 0)) && unset h
        ((${m/ *} == 0)) && unset m

        uptime=${d:+$d, }${h:+$h, }$m
        uptime=${uptime%', '}
        uptime=${uptime:-$s seconds}

        output_result "${uptime}" "System Uptime"
    fi
}


function show_hostname() {
    result=$(hostname)
    output_result "${CYAN}${result}${RESET}" "System Hostname"
}


function show_os_info() {
    if [[ $(command -v lsb_release) ]] >/dev/null 2>&1; then
        local dist=$(lsb_release -d --short)
        output_result "${dist}" "System OS"    
    fi
     if [[ $(command -v uname) ]] >/dev/null 2>&1; then
        local arch=$(uname -m)
        local kernel=$(uname -r)
        local kname=$(uname -s)
        if [[ -z ${dist} ]]; then
            output_result "${kname}" "System OS"
        fi
        output_result "${kernel}" "System Kernel"
        output_result "${arch}" "System Arch"
    fi
}


function show_ext_ip() {
    get_ip_info || \
    output_result "${RED}Offline - Unable to get IP information. ${RESET}" "External IP Info"
}


function sys_warning() {
    echo -ne "

${BG_RED}${WHITE}╔═════════════════════════════════════════════╗${RESET}
${BG_RED}${WHITE}║     YOU HAVE ACCESSED A PRIVATE SYSTEM      ║${RESET}
${BG_RED}${WHITE}║         AUTHORISED USER ACCESS ONLY         ║${RESET}
${BG_RED}${WHITE}║                                             ║${RESET}
${BG_RED}${WHITE}║ Unauthorised use of this system is strictly ║${RESET}
${BG_RED}${WHITE}║ prohibited and may be subject to criminal   ║${RESET}
${BG_RED}${WHITE}║ prosecution.                                ║${RESET}
${BG_RED}${WHITE}║                                             ║${RESET}
${BG_RED}${WHITE}║  ALL ACTIVITIES ON THIS SYSTEM ARE LOGGED.  ║${RESET}
${BG_RED}${WHITE}╚═════════════════════════════════════════════╝${RESET}

"
}


function sys_info() {
    echo
    show_date
    show_uptime
    show_hostname
    show_os_info
    show_cpu
    show_processes
    show_mem
    show_storage
    show_interfaces
    show_ext_ip
    echo
}


function main() {
    clear
    term_colors
    sys_warning
    sys_info
}

main