{
  pkgs ? import <nixpkgs> { },
}:
pkgs.stdenv.mkDerivation {
  pname = "bash-logger";
  version = "0.0.1";
  src = ./.;

  installPhase = ''
    mkdir -p $out/share/bash-logger
    cp src/logger.sh $out/share/bash-logger/logger.sh
  '';
}
