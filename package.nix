{ pkgs }:

let
  bash-logger-scriptPath = ./src/logger.sh;
  bash-logger-scriptContent = builtins.readFile bash-logger-scriptPath;
in
pkgs.writeShellApplication {
  name = "bash-logger";
  text = bash-logger-scriptContent;
  runtimeInputs = [
    pkgs.bash
  ];
  passthru = {
    scriptPath = bash-logger-scriptPath;
  };
}
