#!/bin/bash

# Prevent multiple sourcing
if [ -n "$__LOGGER_SH_SOURCED" ]; then
    return
fi
readonly __LOGGER_SH_SOURCED=1

readonly __LOG_LEVEL_UNKNOWN=-1
readonly LOG_LEVEL_NONE=0
readonly LOG_LEVEL_ERR=1
readonly LOG_LEVEL_WRN=2
readonly LOG_LEVEL_INF=3
readonly LOG_LEVEL_DBG=4
readonly LOG_LEVEL_ALL=5

declare -rA __LOGGER_LEVEL2TEXT=(
    ["$__LOG_LEVEL_UNKNOWN"]="UNKNOWN"
    ["$LOG_LEVEL_NONE"]="NONE"
    ["$LOG_LEVEL_ERR"]="ERROR"
    ["$LOG_LEVEL_WRN"]="WARNING"
    ["$LOG_LEVEL_INF"]="INFO"
    ["$LOG_LEVEL_DBG"]="DEBUG"
    ["$LOG_LEVEL_ALL"]="ALL"
)

__logger_level2text() {
    local -r log_level=$1

    echo "${__LOGGER_LEVEL2TEXT[$log_level]}"
}

declare -rA __LOGGER_LEVEL2COLOR=(
    ["$__LOG_LEVEL_UNKNOWN"]="\e[35m"
    ["$LOG_LEVEL_ERR"]="\e[31m"
    ["$LOG_LEVEL_WRN"]="\e[33m"
    ["$LOG_LEVEL_INF"]="\e[32m"
    ["$LOG_LEVEL_DBG"]="\e[90m"
)

__logger_color_log() {
    local -r log_level="$1"
    local -r log_msg="$2"
    
    local -r color="${__LOGGER_LEVEL2COLOR[$log_level]}"
    echo -e "$color$log_msg\e[0m"
}

declare -A __logger_modules_log_levels
declare -A __logger_modules_names

#### logger global settings ####
declare -A __logger_global_settings=(
    # Path to file where logs will be stored
    ["log_file"]="/tmp/test.log"
    # Enable file logging
    ["en_file_log"]=1
    # Enable color support for file logging
    ["en_file_color"]=0

    # Enable console logging
    ["en_cons_log"]=1
    # Enable color support for console logging
    ["en_cons_color"]=1

    # Enable custom logging backend
    ["en_custom_log"]=0
    # Name of custom logging backend
    ["custom_logger"]=""
)

__logger_is_integer() {
    [[ "$1" =~ ^-?[0-9]+$ ]]
}

__logger_is_arg_empty() {
    [[ -z "$1" ]]
}

__logger_is_path_dir() {
    local -r path_string="$1"

    [[ "$path_string" == */ ]]
}

__logger_is_valid_level() {
    local -r log_level="$1"
    (( LOG_LEVEL_NONE < log_level && log_level < LOG_LEVEL_ALL ))
}

__logger_has_log_sufficient_level() {
    local -r caller_file="$1"
    local -r log_level="$2"
    local -r module_log_level="${__logger_modules_log_levels["${caller_file}"]}"

    (( log_level <= module_log_level ))
}

__logger_internal_log() {
    local -r log_level="$1"
    local -r msg="$2"

    local -r level_text="$(__logger_level2text "$log_level")"
    local -r output="logger: [${level_text}] ${msg}"

    # Force log to stdout (prevent capture)
    echo "$output" >&1
}

__logger_get_log_file() {
    local -r log_file=__logger_global_settings["log_file"]
    if __logger_is_arg_empty "$log_file"; then
        return 1
    fi

    echo "$log_file"
}

__logger_set_log_file() {
    local -r log_file="$1"

    # log_file string can not be empty
    if __logger_is_arg_empty "$log_file"; then
        __logger_internal_log "$LOG_LEVEL_ERR" "Log file path is empty"
        return 1
    fi

    # log_file path has to point to file
    if __logger_is_path_dir "$log_file"; then
        __logger_internal_log "$LOG_LEVEL_ERR" "Log file path is dir, not file"
    fi

    __logger_global_settings["log_file"]="$log_file"
}

__logger_log() {
    local -r log_level="$1"
    local -r message="$2"
    local -r caller_file="$3"
    local -r caller_line="$4"
    local -r timestamp="$5"

    local -r time_formatted=$(date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S")

    local -r log_level_text=$(__logger_level2text "$log_level")
    local -r log_level_text_colored=$(__logger_color_log "$log_level" "$log_level_text")

    local -r output="${time_formatted} (${module_name}) ${caller_file}:${caller_line} [${log_level_text_colored}] ${message} "

    # Console logging
    if (( __logger_global_settings["en_cons_log"] )); then 
        echo "${output}" >&1
    fi

    # File logging
    if (( __logger_global_settings["en_file_log"] )); then 
        local -r log_file="${__logger_global_settings["log_file"]}"
        echo "${output}" >> "$log_file"
    fi

}


# API
logger_register_module() {
    local -r module_name="$1"
    local -r module_log_level="$2"

    local -r registrant="${BASH_SOURCE[1]}"

    __logger_modules_log_levels["$registrant"]="$module_log_level"
    __logger_modules_names["$registrant"]="$module_name"
}

# TODO - fix after changes
logger_print_modules_info() {
    for registrant in "${!__logger_modules_info[@]}"; do
        local module_name="${__logger_modules_info[$registrant]}"
        local module_identifier="__logger_module_${module_name}"
        local -n module="$module_identifier"

        echo "$registrant | $module_name | ${module["log_level"]}"
    done
}

log() {
    local log_level="$1"

    # log_level has to be integer
    if ! __logger_is_integer "$log_level"; then
        local -r internal_message="Log level value is not integer.
        Setting log_level as UNKNOWN"
        __logger_internal_log "$LOG_LEVEL_WRN" "$internal_message"
        log_level="$__LOG_LEVEL_UNKNOWN"
    else
        # log_level has to have valid value
        if ! __logger_is_valid_level "$log_level"; then
            local -r internal_message="Log level value has invalid value.
            Setting log_level as UNKNOWN"
            __logger_internal_log "$LOG_LEVEL_WRN" "$internal_message"
            log_level="$__LOG_LEVEL_UNKNOWN"
        fi
    fi

    local -r caller_file="${BASH_SOURCE[1]}"

    if ! __logger_has_log_sufficient_level "$caller_file" "$log_level"; then
        return 0
    fi

    local -r message="$2"
    local -r caller_line="${BASH_LINENO[0]}"
    local -r timestamp="$(date +%s)"

    __logger_log "$log_level" \
                 "$message" \
                 "$caller_file" \
                 "$caller_line" \
                 "$timestamp"
}

log_err() {
    local -r caller_file="${BASH_SOURCE[1]}"

    if ! __logger_has_log_sufficient_level "$caller_file" "${LOG_LEVEL_ERR}"; then
        return 0
    fi

    local -r message="$1"
    local -r caller_line="${BASH_LINENO[0]}"
    local -r timestamp="$(date +%s)"

    __logger_log "${LOG_LEVEL_ERR}" \
                 "$message" \
                 "$caller_file" \
                 "$caller_line" \
                 "$timestamp"
}

log_wrn() {
    local -r caller_file="${BASH_SOURCE[1]}"

    if ! __logger_has_log_sufficient_level "$caller_file" "${LOG_LEVEL_WRN}"; then
        return 0
    fi

    local -r message="$1"
    local -r caller_line="${BASH_LINENO[0]}"
    local -r timestamp="$(date +%s)"

    __logger_log "${LOG_LEVEL_WRN}" \
                 "$message" \
                 "$caller_file" \
                 "$caller_line" \
                 "$timestamp"
}

log_inf() {
    local -r caller_file="${BASH_SOURCE[1]}"

    if ! __logger_has_log_sufficient_level "$caller_file" "${LOG_LEVEL_INF}"; then
        return 0
    fi

    local -r message="$1"
    local -r caller_line="${BASH_LINENO[0]}"
    local -r timestamp="$(date +%s)"

    __logger_log "${LOG_LEVEL_INF}" \
                 "$message" \
                 "$caller_file" \
                 "$caller_line" \
                 "$timestamp"
}

log_dbg() {
    local -r caller_file="${BASH_SOURCE[1]}"

    if ! __logger_has_log_sufficient_level "$caller_file" "${LOG_LEVEL_DBG}"; then
        return 0
    fi

    local -r message="$1"
    local -r caller_line="${BASH_LINENO[0]}"
    local -r timestamp="$(date +%s)"

    __logger_log "${LOG_LEVEL_DBG}" \
                 "$message" \
                 "$caller_file" \
                 "$caller_line" \
                 "$timestamp"
}

