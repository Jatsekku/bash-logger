{
  config,
  lib,
  pkgs,
  ...
}:
let
  bash-logger-pkg = pkgs.callPackage ./package.nix;
in
{
  options.programs.bash-logger = {
    enable = lib.mkEnableOption "Enable bash-logger library";
  };

  config = lib.mkIf config.programs.bash-logger.enable {
    environment.systemPackages = [ bash-logger-pkg ];
  };
}
