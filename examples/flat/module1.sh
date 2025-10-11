#!/bin/bash

logger_register_module "module1" "$LOG_LEVEL_ERR"
logger_set_log_file "/tmp/test.log"

log_err "Error from module1"
log_wrn "Warning from module1"
log_inf "Info from module1"
log_dbg "Debug from module1"

log "THIS_IS_WRONG_ARGUMENT" "So it will result in unknown level of log"
log "$LOG_LEVEL_ERR" "This one is correct and will result in error message" 
