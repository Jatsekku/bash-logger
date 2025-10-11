#!/bin/bash

source ../../src/logger.sh

logger_set_log_format "%H %msg %%%% %cs %lvl %ce"
source ./module1.sh
source ./module2.sh
source ./module3.sh

logger_print_modules_info

log_dbg "test"

