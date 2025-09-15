{ pkgs }:

let
  bash-logger-script = builtins.readFile ./src/logger.sh;
in
pkgs.writeShellApplication {
  name = "bash-logger";
  text = bash-logger-script;
  runtimeInputs = [
    pkgs.bash
  ];
}
