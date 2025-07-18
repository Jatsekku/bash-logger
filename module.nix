{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.programs.bash-logger = {
    enable = lib.mkEnableOption "Enable bash-logger library";
  };

  config = lib.mkIf config.prorgrams.bash-logger.enable {
    environment.systemPackages = [ pkgs.bash-logger ];
  };
}
