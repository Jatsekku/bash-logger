#!/bin/bash

logger_register_module "module2" "$LOG_LEVEL_DBG"

log_err "Error from module2"
log_wrn "Warning from module2"
log_inf "Info from module2"
log_dbg "Debug from module2"

