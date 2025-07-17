{ pkgs }:
pkgs.runCommandLocal "bash-logger" { } ''
  mkdir -p $out/bin/bash-logger
  cp ${./src/logger.sh} $out/bin/bash-logger/logger.sh
''
