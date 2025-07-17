{
  description = "Logger library for bash";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          bash-logger-pkg = pkgs.callPackage ./package.nix {};
        in
        {
          bash-logger = bash-logger-pkg; 
          default = bash-logger-pkg;
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      nixosModules.bash-logger = ./module.nix;
      nixosModules.default = self.nixosModules.bash-logger;
    };
}
