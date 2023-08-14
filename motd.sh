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
	    for ((i=1; i<=${max_dot_len}; i++)); do echo -ne "${RESET}${char}"; done
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
    # Check for the OS type
    if [[ "$(uname)" == "FreeBSD" ]]; then
        # FreeBSD memory statistics
        total_mem=$(sysctl hw.realmem | awk '{print $2/1024/1024}')  # Convert bytes to MB
        free_mem=$(sysctl vm.stats.vm.v_free_count | awk '{print $2 * 4 / 1024}')  # Convert pages to MB
        used_mem=$(echo "${total_mem} - ${free_mem}" | bc)
        mem_perc=$((used_mem * 100 / total_mem))
    else
        # Debian-based (and other Linux) memory statistics
        total_mem=$(free -m | awk 'FNR == 2 {print $2}')
        used_mem=$(free -m | awk 'FNR == 2 {print $3}')
        mem_perc=$((used_mem * 100 / total_mem))
    fi

    result=$(percentage_color ${mem_perc})
    output_result "${used_mem}MB/${total_mem}MB (${result})" "Memory Usage"
}


get_unit() {
    local size=$1
    local unit=${size: -1}  # Get the last character (unit)
    local value=${size:0:${#size}-1}  # Get the value without the unit
    case $unit in
        G)
            echo $((value * 1024 * 1024 * 1024))
            ;;
        M)
            echo $((value * 1024 * 1024))
            ;;
        *)
            echo $value
            ;;
    esac
}

convert_bytes() {
    local bytes=$1
    if (( bytes >= 1024*1024*1024 )); then
        echo "$((bytes / 1024 / 1024 / 1024))GB"
    elif (( bytes >= 1024*1024 )); then
        echo "$((bytes / 1024 / 1024))MB"
    else
        echo "$((bytes / 1024))KB"
    fi
}

show_storage() {
    if [[ $(command -v df) ]] >/dev/null 2>&1; then
        # Run the df command, filter for /dev filesystem, and store the output
        disk_info=$(df -H | grep "^/dev/")

        # Loop through each line of the output and process the information
        while IFS= read -r line; do
            total_size=$(echo "$line" | awk '{print $2}')
            total_size_bytes=$(get_unit "$total_size")
            total_space=$(convert_bytes $total_size_bytes)
            available_space=$(echo "$line" | awk '{print $4}')
            available_space_bytes=$(get_unit "$available_space")
            use_percentage=$(echo "$line" | awk '{print $5}')
            use_space_bytes=$((total_size_bytes - available_space_bytes))
            use_space=$(convert_bytes $use_space_bytes)
            mount_point=$(echo "$line" | awk '{print $6}')
            use_percentage_color=$(percentage_color ${use_percentage})  # Assuming this function is defined

            output_string="$use_space/$total_space ($use_percentage_color)"
            output_result "$output_string" "Storage $mount_point"
        done <<< "$disk_info"
    fi
}


function show_interfaces() {
    if [[ $(command -v ifconfig) ]] >/dev/null 2>&1; then
        local iface_active=()

        # Check OS type and get list of interface names accordingly
        if [[ "$(uname)" == "FreeBSD" ]]; then
            iface_list=$(ifconfig -l)
        else
            iface_list=$(ifconfig | grep -o '^[a-z0-9]*' | tr '\n' ' ')
        fi

        for iface in $iface_list; do
            iface_status=$(ifconfig $iface | grep "status:" | awk '{print $2}')
            iface_v4=$(ifconfig $iface | grep "inet " | awk '{print $2}')

            if [[ -n "$iface_status" && "$iface_status" != "active" ]]; then
                continue
            fi

            if [[ -n "$iface_v4" ]]; then
                iface_active+=("$(printf "${iface} ${CYAN}${iface_v4}${RESET}")")
            else
                iface_active+=("$(printf "${iface} Unconfigured")")
            fi
        done

        # Print active interfaces
        for i in "${iface_active[@]}"; do
            output_result "$(echo ${i} | awk '{print $2}')" "Network $(echo ${i} | awk '{print $1}')"
        done
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


function sys_info() {
    echo
    show_hostname
    show_date
    show_uptime
    show_os_info
    show_cpu
    show_mem
    show_storage
    show_interfaces
    show_ext_ip
    echo
}

function sys_banner() {
    echo -e "
${RED}╔═════════════════════════════════════════════╗${RESET}
${RED}║     YOU HAVE ACCESSED A PRIVATE SYSTEM      ║${RESET}
${RED}║         AUTHORISED USER ACCESS ONLY         ║${RESET}
${RED}║                                             ║${RESET}
${RED}║ Unauthorised use of this system is strictly ║${RESET}
${RED}║ prohibited and may be subject to criminal   ║${RESET}
${RED}║ prosecution.                                ║${RESET}
${RED}║                                             ║${RESET}
${RED}║  ALL ACTIVITIES ON THIS SYSTEM ARE LOGGED.  ║${RESET}
${RED}╚═════════════════════════════════════════════╝${RESET}"
}

function main() {
    clear
    term_colors
    sys_banner
    sys_info
}

main
