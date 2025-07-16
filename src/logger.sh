#!/bin/bash

# Prevent multiple sourcing
if [ -n "${__LOGGER_SH_SOURCED:-}" ]; then
    return
fi
readonly __LOGGER_SH_SOURCED=1

#--------------------------- logger levels consts -----------------------------
readonly __LOG_LEVEL_UNKNOWN=-1
readonly LOG_LEVEL_NONE=0
readonly LOG_LEVEL_ERR=1
readonly LOG_LEVEL_WRN=2
readonly LOG_LEVEL_INF=3
readonly LOG_LEVEL_DBG=4
readonly LOG_LEVEL_ALL=5

#--------------------------- logger modules names -----------------------------
declare -A __logger_modules_names

__logger_set_module_name() {
    local -r registrant="$1"
    local -r module_name="$2"

    __logger_modules_names["$registrant"]="$module_name"
}

__logger_get_module_name() {
    local -r caller_file="$1"

    echo "${__logger_modules_names["${caller_file}"]:-unnamed}" 
}

#------------------------- logger modules log levels --------------------------
declare -A __logger_modules_log_levels

__logger_set_module_log_level() {
    local -r registrant="$1"
    local -r log_level="$2"

    __logger_modules_log_levels["$registrant"]="$log_level"
}

__logger_get_module_log_level() {
    local -r caller_file="$1"

    echo "${__logger_modules_log_levels["${caller_file}"]}"
}

__logger_is_valid_level() {
    local -r log_level="$1"

    (( LOG_LEVEL_NONE < log_level && log_level < LOG_LEVEL_ALL ))
}

__logger_has_log_sufficient_level() {
    local -r caller_file="$1"
    local -r log_level="$2"
    local -r module_log_level=$(__logger_get_module_log_level "$caller_file")

    (( log_level <= module_log_level ))
}

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

#----------------------------- logger log colors ------------------------------
declare -rA __LOGGER_LEVEL2COLOR=(
    ["$__LOG_LEVEL_UNKNOWN"]="\e[35m"
    ["$LOG_LEVEL_ERR"]="\e[31m"
    ["$LOG_LEVEL_WRN"]="\e[33m"
    ["$LOG_LEVEL_INF"]="\e[32m"
    ["$LOG_LEVEL_DBG"]="\e[90m"
)

__logger_start_log_color() {
    local -r log_level="$1"
 
    local -r color="${__LOGGER_LEVEL2COLOR[$log_level]}"
    echo -e "$color"
}

__logger_apply_log_color() {
    local -r modifier="$1"
    local -r log_level="$2"

    case "$modifier" in
        # Color start
        %cs) echo -e "$(__logger_start_log_color "$log_level")" ;;
        # Color end
        %ce) echo -e "\e[0m"
    esac
}

#------------------------------- logger utils ---------------------------------
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

__logger_internal_log() {
    local -r log_level="$1"
    local -r msg="$2"

    local -r level_text="$(__logger_level2text "$log_level")"
    local -r output="logger: [${level_text}] ${msg}"

    # Force log to stdout (prevent capture)
    echo "$output" >&1
}

#--------------------------- logger log formatting ----------------------------
declare -a __logger_global_tokens

__logger_prepare_format() {
    local format_string="$1"
    local tokens=()

    while [[ $format_string =~ (%[a-zA-Z_]+) ]]; do
        local token="${BASH_REMATCH[0]}"
        local prefix="${format_string%%"$token"*}"

        # Store token prefix (literal - L) in array
        [[ -n $prefix ]] && tokens+=( "L:$prefix" )

        # Check matched token
        case "$token" in
            # %lvl - log level
            # %msg - user message
            # %mod_name - module name
            # %file - caller file
            # %line - caller line
            # %pid - process id
            %lvl|%msg|%mod_name|%file|%line|%pid)
                # Store variable token (V) in array
                tokens+=( "V:$token" )
                ;;
            # %Y - year (4 digits) <0000;9999>
            # %y - yeer (last 2 digits) <00;99>
            # %m - month <01;12>
            # %d - day <01;31>
            # %H - hour <00;23>
            # %M - minute <00;59>
            # %S - secod <00;59>
            # %N - nanoseconds <000000000;999999999>
            # %T - same as %H:%M:%S
            # %F - same as %Y-%m-%d
            %Y|%y|%m|%d|%H|%M|%S|%N|%T|%F)
                # Store datetime token (T) in array
                tokens+=( "T:$token" )
                ;;
            # %cs - color start
            # %ce - color end
            %cs|%ce)
                # Store color modifier token (CM) in array
                tokens+=( "CM:$token" )
                ;;
            %%)
                # Store '%' literal token (L) in array
                tokens+=( "L:%")
                ;;
            *)
                __logger_internal_log "$LOG_LEVEL_WRN" \
                "Invalid format token: [$token]"
                ;;
            esac

        # Removed processed text
        format_string="${format_string#"$prefix$token"}"
    done

    # Store potental literal leftover 
    [[ -n $format_string ]] && tokens+=( "L:$format_string" )

    printf '%s\n' "${tokens[@]}"
}

__logger_update_format_tokens() {
    local -r format_string=$(__logger_get_log_format)

    # Fill __logger_global_tokens array with tokens
    mapfile -t __logger_global_tokens < <(
        __logger_prepare_format "$format_string"
    )
}


__logger_format_output() {
    local -rn token_list="$1"

    local -r log_level="$2"
    local -r message="$3"
    local -r caller_file="$4"
    local -r caller_line="$5"
    local -r module_name="$6"
    local -r timestamp="$7"
    local -r pid="$8"

    declare -rA vars=(
        [%lvl]=$(__logger_level2text "$log_level")
        [%msg]="$message"
        [%mod_name]="$module_name"
        [%file]="$caller_file"
        [%line]="$caller_line"
        [%pid]="$pid"
    )

    local output=""

    for token in "${token_list[@]}"; do
        local type="${token%%:*}"
        local value="${token#*:}"

        case "$type" in
            # Literal tokens
            L) output+="$value" ;;
            # Variable tokens
            V) output+="${vars[$value]}" ;;
            # Data time tokens
            T) output+="$(printf "%($value)T" "$timestamp")" ;;
            # Color modifier tokens
            CM) output+="$(__logger_apply_log_color "$value" "$log_level")" ;;
        esac
    done

    echo "$output"
}

#-------------------------- logger globals settings ---------------------------
declare -A __logger_global_settings=(
    # Path to file where logs will be stored
    ["log_file"]="/var/log/bash-logger-default.log"
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

    # Formatting string
    ["log_format"]="%F %T (%mod_name) {%pid} %file:%line [%lvl] %msg"
)

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

    # Create parent directory if does not exist
    local -r log_dir=$(dirname "$log_file")
    mkdir -p "$log_dir" 2>/dev/null || true

    __logger_global_settings["log_file"]="$log_file"
}

__logger_get_log_file() {
    local -r log_file="${__logger_global_settings["log_file"]}"
    if __logger_is_arg_empty "$log_file"; then
        return 1
    fi

    echo "$log_file"
}

__logger_enable_file_logging() {
    local -r enable_file_logging="$1"
 
    __logger_global_settings["en_file_log"]="$enable_file_logging"
}

__logger_enable_console_logging() {
    local -r enable_console_logging="$1"

    __logger_global_settings["en_cons_log"]="$enable_console_logging"
}

__logger_set_log_format() {
    local -r log_format="$1"
    if __logger_is_arg_empty "$log_format"; then
        __logger_internal_log "$LOG_LEVEL_ERR" "Formating string is empty"
        return 1
    fi
    
    __logger_global_settings["log_format"]="$log_format"
    __logger_update_format_tokens
}

__logger_get_log_format() {
    local -r log_format="${__logger_global_settings["log_format"]}"
    if __logger_is_arg_empty "$log_format"; then
        return 1
    fi

    echo "$log_format"
}

__logger_log() {
    local -r log_level="$1"
    local -r message="$2"
    local -r caller_file="$3"
    local -r caller_line="$4"
    local -r timestamp="$5"

    local -r module_name=$(__logger_get_module_name "$caller_file")
    local -r pid=$$

    local -r output=$(
        __logger_format_output __logger_global_tokens \
                               "$log_level" \
                               "$message" \
                               "$caller_file" \
                               "$caller_line" \
                               "$module_name" \
                               "$timestamp" \
                               "$pid"
    )

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

__logger_on_source() {
    __logger_update_format_tokens
}

##################################### API #####################################
logger_register_module() {
    local -r module_name="$1"
    local -r log_level="$2"

    local -r registrant="${BASH_SOURCE[1]:-bash}"

    __logger_set_module_name "$registrant" "$module_name"
    __logger_set_module_log_level "$registrant" "$log_level"
}

logger_set_log_file() {
    local -r log_file="$1"

    __logger_set_log_file "$log_file"
}

logger_set_log_format() {
    local -r log_format="$1"

    __logger_set_log_format "$log_format"
}

logger_print_modules_info() {
    echo "Register modules:"
    for registrant in "${!__logger_modules_names[@]}"; do
        local module_name="${__logger_modules_names[$registrant]}"
        local module_log_level="${__logger_modules_log_levels["$registrant"]}"

        echo "$registrant | $module_name | $(__logger_level2text "${module_log_level}")"
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
    local -r timestamp="$EPOCHSECONDS"

    __logger_log "$log_level" \
                 "$message" \
                 "$caller_file" \
                 "$caller_line" \
                 "$timestamp" 
}

log_err() {
    local -r caller_file="${BASH_SOURCE[1]:-bash}"

    if ! __logger_has_log_sufficient_level "$caller_file" "${LOG_LEVEL_ERR}"; then
        return 0
    fi

    local -r message="$1"
    local -r caller_line="${BASH_LINENO[0]}"
    local -r timestamp="$EPOCHSECONDS"

    __logger_log "${LOG_LEVEL_ERR}" \
                 "$message" \
                 "$caller_file" \
                 "$caller_line" \
                 "$timestamp" 
}

log_wrn() {
    local -r caller_file="${BASH_SOURCE[1]:-bash}"

    if ! __logger_has_log_sufficient_level "$caller_file" "${LOG_LEVEL_WRN}"; then
        return 0
    fi

    local -r message="$1"
    local -r caller_line="${BASH_LINENO[0]}"
    local -r timestamp="$EPOCHSECONDS"

    __logger_log "${LOG_LEVEL_WRN}" \
                 "$message" \
                 "$caller_file" \
                 "$caller_line" \
                 "$timestamp" 
}

log_inf() {
    local -r caller_file="${BASH_SOURCE[1]:-bash}"

    if ! __logger_has_log_sufficient_level "$caller_file" "${LOG_LEVEL_INF}"; then
        return 0
    fi

    local -r message="$1"
    local -r caller_line="${BASH_LINENO[0]}"
    local -r timestamp="$EPOCHSECONDS"

    __logger_log "${LOG_LEVEL_INF}" \
                 "$message" \
                 "$caller_file" \
                 "$caller_line" \
                 "$timestamp" 
}

log_dbg() {
    local -r caller_file="${BASH_SOURCE[1]:-bash}"

    if ! __logger_has_log_sufficient_level "$caller_file" "${LOG_LEVEL_DBG}"; then
        return 0
    fi

    local -r message="$1"
    local -r caller_line="${BASH_LINENO[0]}"
    local -r timestamp="$EPOCHSECONDS"

    __logger_log "${LOG_LEVEL_DBG}" \
                 "$message" \
                 "$caller_file" \
                 "$caller_line" \
                 "$timestamp" 
}

__logger_on_source

