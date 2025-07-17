{
  description = "Development flake for logger library";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          # Set formatter for nix fmt
          formatter = pkgs.nixfmt-rfc-style;

          packages.logger = pkgs.callPackage ./package.nix { };
          packages.default = config.packages.logger;

          devShells.default = config.packages.default;
        };
    };
}
