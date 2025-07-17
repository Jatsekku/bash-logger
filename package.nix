{ pkgs }:
pkgs.runCommandLocal "bash-logger" { } ''
  mkdir -p $out/share/bash-logger
  cp ${./src/logger.sh} $out/share/bash-logger/logger.sh
''
