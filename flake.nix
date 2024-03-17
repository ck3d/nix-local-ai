{
  description = "Nix package of LocalAI";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    rec {
      overlays.default = import ./overlay.nix;

      packages = forAllSystems
        (system:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = builtins.attrValues overlays;
              config = { allowUnfree = true; };
            };
          in
          pkgs.nix-local-ai
          // { default = pkgs.nix-local-ai.local-ai; }
        );

      legacyPackages = forAllSystems
        (system:
          let
            pkgs = import nixpkgs-unstable {
              inherit system;
              overlays = builtins.attrValues overlays;
              config = { allowUnfree = true; };
            };
          in
          { unstable = pkgs.nix-local-ai; }
        );
    };
}
