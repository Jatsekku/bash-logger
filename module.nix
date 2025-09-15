{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.bash-logger;
  bash-logger-pkg = pkgs.callPackage ./package.nix { };
in
{
  options.programs.bash-logger = {
    enable = lib.mkEnableOption "Enable bash-logger library";
    createEtcSymlink = lib.mkEnableOption "Create symlink under etc";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ bash-logger-pkg ];

    environment.etc = lib.mkIf cfg.createEtcSymlink {
      "bash-logger.sh".source = "${bash-logger-pkg.passthru.scriptPath}";
    };
  };
}
