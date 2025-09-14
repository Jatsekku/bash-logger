# bash-logger

Feature-rich, flexible logger utility for bash.

## Motivation
I had to write some bash scripts handlig various task on my machines.
When scripts are run from some sybsystems (i.e. udev) it's hard to get logs produced by them.

There are bash loggers already but I felt they were too limited for me so...
I decided to write my own.

## Features
- Registering sourced bash modules under user-provided name.
- Allowing for logging with standard levels like: ERROR, WARNING, INFO, DEBUG.
- Controling printed logs by levels per each moddule.
- Printing to console and to file as well.
- Coloring logs
- Customizing logs format
- Wrapped as Nix pakcage

## Provided information
- Log level
- User-specified module name
- Name of file that emitted log
- Line number where log funcion has been called
- ID of process that emitted log
- Date/Time of log

## Formatting
| Specifier | Output Description                      | Example        |
|:---------:|:---------------------------------------:|:--------------:|
| %lvl      | Log level in textual form               | ERROR, DEBUG   |
| %msg      | User-provided message                   | System ready   |
| %mod_name | Module name                             | bash-logger    |
| %file     | File that called log function           | bash_logger.sh |
| %line     | Line number that called log function    | 42             |
| %pid      | PID of process that called log function | 2137           |
|           |                                         |                |
| %Y        | Year (4 digits)                         | 2025           |
| %y        | Year (last 2 digits)                    | 25             |
| %m        | Month (01–12)                           | 09             |
| %d        | Day of month (01–31)                    | 14             |
| %H        | Hour (00–23)                            | 15             |
| %M        | Minute (00–59)                          | 45             |
| %S        | Second (00–59)                          | 07             |
| %N        | Nanoseconds (000000000–999999999)       | 123456789      |
| %T        | Time shortcut (%H:%M:%S)                | 15:45:07       |
| %F        | Date shortcut (%Y-%m-%d)                | 2025-09-14     |

