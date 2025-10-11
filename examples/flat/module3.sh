#!/bin/bash

logger_register_module "module3" "$LOG_LEVEL_INF"

log_err "Error from module3"
log_wrn "Warning from module3"
log_inf "Info from module3"
log_dbg "Debug from module3"
